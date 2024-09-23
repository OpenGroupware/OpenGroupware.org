/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include "PPTransaction.h"
#include <EOControl/EOControl.h>

typedef struct _EOObjectInfo {
  BOOL       releaseEO;
  EOGlobalID *oid;
  id         eo;
  id         snapshot;
  id         eventSnapshot;
} EOObjectInfo;

static void     mapValRetain(NSMapTable *self, const void *_value);
static void     mapValRelease(NSMapTable *self, void *_value);
static NSString *mapDescribe(NSMapTable *self, const void *_value);

const NSMapTableValueCallBacks EOObjectInfoMapValueCallBacks = {
  (void (*)(NSMapTable *, const void *))mapValRetain,
  (void (*)(NSMapTable *, void *))mapValRelease,
  (NSString *(*)(NSMapTable *, const void *))mapDescribe
};

@interface PPTransaction(PrivateMethods)
- (BOOL)retainsRegisteredObjects;
@end

@implementation PPTransaction

// THREAD
static PPDataStore *defaultParentObjectStore = nil;
static NSMapTable  *idToTx = NULL;
static Class EOObserverCenterClass = Nil;

+ (void)initialize {
  if (idToTx == NULL) {
    idToTx = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                          NSNonOwnedPointerMapValueCallBacks,
                                          512);
  }
}

+ (void)setDefaultParentObjectStore:(PPDataStore *)_store {
  ASSIGN(defaultParentObjectStore, _store);
}
+ (PPDataStore *)defaultParentObjectStore {
  return defaultParentObjectStore;
}

+ (BOOL)instancesRetainRegisteredObjects {
  return YES;
}

- (id)initWithParentObjectStore:(PPDataStore *)_objectStore {
  if ((self = [super init])) {
    NSNotificationCenter *nc;

    if (EOObserverCenterClass == Nil)
      EOObserverCenterClass = [EOObserverCenter class];
    
    self->store = [_objectStore retain];

    nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(_objectsChangedInStore:)
        name:@"EOObjectsChangedInStore" object:self->store];
    [nc addObserver:self selector:@selector(_globalIDsChangedInStore:)
        name:@"EOGlobalIDChanged" object:self->store];
    
    // THREADING
    self->lock = nil;

    self->retainsRegisteredObjects =
      [[self class] instancesRetainRegisteredObjects];
    self->idToInfo = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                      EOObjectInfoMapValueCallBacks,
                                      100);
    self->oidToInfo = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                       EOObjectInfoMapValueCallBacks,
                                       100);
    
    self->inserted  = NSCreateHashTable(NSObjectHashCallBacks, 32);
    self->updated   = NSCreateHashTable(NSObjectHashCallBacks, 100);
    self->deleted   = NSCreateHashTable(NSObjectHashCallBacks, 32);
    self->uInserted = NSCreateHashTable(NSObjectHashCallBacks, 32);
    self->uUpdated  = NSCreateHashTable(NSObjectHashCallBacks, 100);
    self->uDeleted  = NSCreateHashTable(NSObjectHashCallBacks, 32);
  }
  return self;
}

- (id)init {
  return [self initWithParentObjectStore:
                 [[self class] defaultParentObjectStore]];
}

- (void)dealloc {
  while (([self->pools count] > 0))
    [self->pools removeObjectAtIndex:([self->pools count] - 1)];
  [self->pools release];

  [self reset];
  
  [self->editors release];
  
  if (self->idToInfo)  NSFreeMapTable(self->idToInfo);  self->idToInfo  = NULL;
  if (self->oidToInfo) NSFreeMapTable(self->oidToInfo); self->oidToInfo = NULL;
  
  if (self->uInserted) NSFreeHashTable(self->uInserted); self->uInserted = NULL;
  if (self->uDeleted)  NSFreeHashTable(self->uDeleted);  self->uDeleted = NULL;
  if (self->uUpdated)  NSFreeHashTable(self->uUpdated);  self->uUpdated = NULL;
  if (self->inserted)  NSFreeHashTable(self->inserted);  self->inserted = NULL;
  if (self->deleted)   NSFreeHashTable(self->deleted);   self->deleted = NULL;
  if (self->updated)   NSFreeHashTable(self->updated);   self->updated = NULL;

  [self->store release];
  [self->lock  release];
  [self->registeredPostSyncs release];
  [super dealloc];
}

/* notifications */

- (void)_objectsChangedInStore:(NSNotification *)_notification {
}

- (void)_globalIDsChangedInStore:(NSNotification *)_notification {
  /* temporary IDs were replaced by permanent ones */
  NSDictionary *mappings;
  NSEnumerator *keys;
  EOGlobalID   *old;
  
  /* contains mapping from temporary-id to permanent-id */
  mappings = [_notification userInfo];
  keys     = [mappings keyEnumerator];
  
  while ((old = [keys nextObject])) {
    EOObjectInfo *info;

#if DEBUG
    NSAssert1([old isTemporary], @"old key %@ is not temporary !", old);
#endif
    
    if ((info = NSMapGet(self->oidToInfo, old))) {
      EOGlobalID *new;
      
      new = [mappings objectForKey:old];
#if DEBUG
      NSAssert2(![new isTemporary], @"new key %@ for old %@ is temporary !",
                new, old);
#endif
      
      ASSIGN(info->oid, new);
      NSMapInsert(self->oidToInfo, new, info);
      NSMapRemove(self->oidToInfo, old);
      
      /* should update relations !!! */
    }
  }
}

/* accessors */

- (void)setDelegate:(id)_delegate {
  self->delegate = _delegate;
}
- (id)delegate {
  return self->delegate;
}

- (void)setMessageHandler:(id)_delegate {
  self->messageHandler = _delegate;
}
- (id)messageHandler {
  return self->messageHandler;
}

- (PPDataStore *)parentObjectStore {
  return self->store;
}
- (PPDataStore *)rootObjectStore {
  PPDataStore *parent;
  
  parent = [self parentObjectStore];
  if ([parent isKindOfClass:[PPTransaction class]])
    parent = [(PPTransaction *)parent rootObjectStore];
  
  return parent;
}

- (BOOL)stopsValidationAfterFirstError {
  return YES;
}
- (BOOL)propagatesDeletesAtEndOfEvent {
  return YES;
}
- (BOOL)retainsRegisteredObjects {
  return self->retainsRegisteredObjects;
}

/* faults */

- (void)refaultObjects {
  [self notImplemented:_cmd];
}
- (void)invalidateAllObjects {
  [self notImplemented:_cmd];
}

/* snapshots */

- (NSDictionary *)committedSnapshotForObject:(id)_eo {
  EOObjectInfo *info;
  return ((info = NSMapGet(self->idToInfo, _eo))) ? info->snapshot : nil;
}
- (NSDictionary *)currentEventSnapshotForObject:(id)_eo {
  EOObjectInfo *info;
  return ((info = NSMapGet(self->idToInfo, _eo))) ? info->eventSnapshot : nil;
}

/* object graph */

- (BOOL)hasChanges {
#if DEBUG
  NSAssert(self->updated,  @"updated object table is missing");
  NSAssert(self->inserted, @"inserted object table is missing");
  NSAssert(self->deleted,  @"deleted object table is missing");
  NSAssert(self->uUpdated,  @"updated object table is missing");
  NSAssert(self->uInserted, @"inserted object table is missing");
  NSAssert(self->uDeleted,  @"deleted object table is missing");
#endif
  if (NSCountHashTable(self->uUpdated) > 0)  return YES;
  if (NSCountHashTable(self->uInserted) > 0) return YES;
  if (NSCountHashTable(self->uDeleted) > 0)  return YES;
  if (NSCountHashTable(self->updated) > 0)  return YES;
  if (NSCountHashTable(self->inserted) > 0) return YES;
  if (NSCountHashTable(self->deleted) > 0)  return YES;
  return NO;
}

static NSArray *_arrayFrom2Tables(NSHashTable *t1, NSHashTable *t2) {
  NSHashEnumerator e;
  id               eo;
  NSMutableSet     *result;

  result = nil;
  e = NSEnumerateHashTable(t1);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    if (result == nil) result = [NSMutableSet setWithCapacity:16];
    [result addObject:eo];
  }
  e = NSEnumerateHashTable(t2);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    if (result == nil) result = [NSMutableSet setWithCapacity:16];
    [result addObject:eo];
  }
  return result ? [result allObjects] : [NSArray array];
}

- (NSArray *)deletedObjects {
  return _arrayFrom2Tables(self->uDeleted, self->deleted);
}
- (NSArray *)updatedObjects {
  return _arrayFrom2Tables(self->uUpdated, self->updated);
}
- (NSArray *)insertedObjects {
  return _arrayFrom2Tables(self->uInserted, self->inserted);
}

- (NSArray *)registeredObjects {
  return NSAllMapTableKeys(self->idToInfo);
}

- (void)insertObject:(id)_object withGlobalID:(EOGlobalID *)_oid {
  NSAssert([_oid isTemporary], @"object id is not temporary !");
  
  [self recordObject:_object globalID:_oid];
  NSHashInsert(self->uInserted, _object);
  NSHashRemove(self->uDeleted,  _object);

  [_object awakeFromInsertionInEditingContext:self];
}

- (void)insertObject:(id)_object {
  EOGlobalID *tid;
  
  tid = [[EOTemporaryGlobalID alloc] init];
  [self insertObject:_object withGlobalID:tid];
  RELEASE(tid);
}

- (void)deleteObject:(id)_object {
  if (NSHashGet(self->uInserted, _object) == NULL) {
    /* object wasn't inserted recently, mark as deleted */
    NSHashInsert(self->uDeleted,  _object);
  }
  else {
    /* remove recently inserted object, no need to mark as 'deleted' */
    NSHashRemove(self->uInserted, _object);
  }
  NSHashRemove(self->uUpdated,  _object);
}

- (void)objectWillChange:(id)_object {
  if ([self locksObjectsBeforeFirstModification])
    [self lockObject:_object];
  
  NSHashInsert(self->uUpdated, _object);
}

- (void)revert {
  NSHashEnumerator e;
  id eo;
  
  NSResetHashTable(self->uInserted);
  NSResetHashTable(self->uDeleted);
  NSResetHashTable(self->inserted);
  NSResetHashTable(self->deleted);

  e = NSEnumerateHashTable(self->uUpdated);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    EOObjectInfo *info;

    if ((info = NSMapGet(self->idToInfo, eo))) {
      [eo updateFromSnapshot:info->snapshot];
      ASSIGN(info->eventSnapshot, info->snapshot);
    }
  }
  e = NSEnumerateHashTable(self->updated);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    EOObjectInfo *info;

    if ((info = NSMapGet(self->idToInfo, eo))) {
      [eo updateFromSnapshot:info->snapshot];
      ASSIGN(info->eventSnapshot, info->snapshot);
    }
  }
}

/* object registry */

- (EOGlobalID *)globalIDForObject:(id)_object {
  EOObjectInfo *info;
  info = NSMapGet(self->idToInfo, _object);
  return info ? info->oid : nil;
}
- (id)objectForGlobalID:(EOGlobalID *)_oid {
  EOObjectInfo *info;
  info = NSMapGet(self->oidToInfo, _oid);
  return info ? info->eo : nil;
}

- (void)recordObject:(id)_object globalID:(EOGlobalID *)_oid {
  EOObjectInfo *info;

#if DEBUG
  NSAssert(_oid,     @"missing oid ..");
  NSAssert1(_object, @"missing object for oid %@ ..", _oid);
#endif
  
  if ((info = NSMapGet(self->idToInfo, _object))) {
    /* object is already registered */
    NSLog(@"WARNING(%s): reregistering object %@ under "
          @"different oid %@ (old=%@, same=%s)",
          __PRETTY_FUNCTION__, _object, _oid, info->oid,
          [_oid isEqual:info->oid] ? "yes" : "no");
    NSMapRemove(self->oidToInfo, info->oid);
    ASSIGN(info->oid, _oid);
  }
  else {
#if NeXT_RUNTIME
    info = malloc(sizeof(EOObjectInfo));
#else
    info = objc_malloc(sizeof(EOObjectInfo));
#endif
    info->releaseEO     = [self retainsRegisteredObjects];
    info->oid           = RETAIN(_oid);
    info->eo            = _object;
    info->snapshot      = [_object snapshot];
    info->eventSnapshot = RETAIN(info->snapshot);
    info->snapshot      = RETAIN(info->snapshot);
    
    if (info->releaseEO)
      _object = RETAIN(_object);
  }
  
  NSMapInsert(self->idToInfo,     _object, info);
  NSMapInsert(self->oidToInfo,    _oid,    info);
  NSMapInsert(idToTx, _object, self);

  if (![_oid isTemporary])
    [EOObserverCenterClass addObserver:self forObject:_object];
}

- (void)forgetObject:(id)_object {
  EOObjectInfo *info;
  
  if (EOObserverCenterClass == Nil)
    EOObserverCenterClass = [EOObserverCenter class];
  
  [EOObserverCenterClass removeObserver:self forObject:_object];

  if ((info = NSMapGet(self->idToInfo, _object))) {
    NSMapRemove(self->idToInfo, _object);
    NSMapRemove(self->oidToInfo, info->oid);
    NSMapRemove(idToTx, _object);
    
    NSHashRemove(self->inserted,  _object);
    NSHashRemove(self->deleted,   _object);
    NSHashRemove(self->updated,   _object);
    NSHashRemove(self->uInserted, _object);
    NSHashRemove(self->uDeleted,  _object);
    NSHashRemove(self->uUpdated,  _object);
    
    if (info->releaseEO)
      RELEASE(info->eo);
    
    RELEASE(info->oid);
    RELEASE(info->snapshot);
    RELEASE(info->eventSnapshot);
#if NeXT_RUNTIME
    free(info);
#else    
    objc_free(info);
#endif
  }
}

- (void)reset {
  NSMapEnumerator e;
  id              eo;
  EOObjectInfo    *info;
  
  e = NSEnumerateMapTable(self->idToInfo);
  while ((NSNextMapEnumeratorPair(&e, (void*)&eo, (void*)&info))) {
    NSMapRemove(idToTx, eo);
    
    if (info->releaseEO)
      [info->eo release];
    
    [info->oid           release];
    [info->snapshot      release];
    [info->eventSnapshot release];
    
#if NeXT_RUNTIME
    free(info);
#else    
    objc_free(info);
#endif
  }
  NSResetMapTable(self->oidToInfo);
  NSResetMapTable(self->idToInfo);
  
  NSResetHashTable(self->inserted);
  NSResetHashTable(self->deleted);
  NSResetHashTable(self->updated);
  NSResetHashTable(self->uInserted);
  NSResetHashTable(self->uDeleted);
  NSResetHashTable(self->uUpdated);
}

/* object locking */

- (BOOL)locksObjectsBeforeFirstModification {
  return NO;
}

- (void)lockObject:(id)_object {
  EOGlobalID *oid;

  oid = [self globalIDForObject:_object];
  if (oid == nil) {
    [NSException raise:@"NSInvalidArgumentException"
                 format:@"ec %@ couldn't find oid for object %@", self, _object];
  }
  [self lockObjectWithGlobalID:oid ppTransaction:self];
}

/* fetching */

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec {
  NSArray *objects;

  objects = [[self parentObjectStore]
                   objectsWithFetchSpecification:_fspec
                   ppTransaction:self];

  return objects ? objects : [NSArray array];
}

/* processing */

- (void)_updateSnapshotsOfObjectsInTable:(NSHashTable *)_table {
  NSHashEnumerator e;
  id eo;
  
  e = NSEnumerateHashTable(_table);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    EOObjectInfo *info;
    
    info = NSMapGet(self->idToInfo, eo);
#if DEBUG
    NSAssert1(info, @"missing info for EO %@", eo);
#endif

    RELEASE(info->snapshot);
    RELEASE(info->eventSnapshot);
    
    info->snapshot      = [eo snapshot];
    info->eventSnapshot = RETAIN(info->snapshot);
    info->snapshot      = RETAIN(info->snapshot);
    
    [EOObserverCenterClass addObserver:self forObject:eo];
  }
}

- (BOOL)validateTable:(NSHashTable *)_table withSelector:(SEL)_selector
  exceptionArray:(NSMutableArray *)_exceptions
  continueAfterFailure:(BOOL)_flag
{
  NSHashEnumerator e;
  NSException      *exception;
  BOOL             didFail;
  id               eo;

  didFail = NO;
  e = NSEnumerateHashTable(_table);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    if ((exception = [eo performSelector:_selector])) {
      if (_flag) [exception raise];
      [_exceptions addObject:exception];
      didFail = YES;
    }
  }
  return didFail;
}

- (void)validateChangesForSave {
  NSMutableArray *exceptions;
  BOOL           stopOnError, didFail;
  
  exceptions = [NSMutableArray arrayWithCapacity:4];
  stopOnError = [self stopsValidationAfterFirstError];
  
  [self validateTable:self->inserted
        withSelector:@selector(validateForInsert)
        exceptionArray:exceptions
        continueAfterFailure:stopOnError];
  
  [self validateTable:self->updated
        withSelector:@selector(validateForUpdate)
        exceptionArray:exceptions
        continueAfterFailure:stopOnError];
  
  [self validateTable:self->deleted
        withSelector:@selector(validateForDelete)
        exceptionArray:exceptions
        continueAfterFailure:stopOnError];
  
  didFail = [exceptions count] > 0 ? YES : NO;

  if (didFail) {
    if ([exceptions count] == 1)
      [[exceptions lastObject] raise];
    else {
      NSException *e;

      e = [NSException aggregateExceptionWithExceptions:exceptions];
      [e raise];
    }
  }
}

- (BOOL)_propagateDeletes {
  NSHashEnumerator e;
  id               eo;
  BOOL didSomething;

  didSomething = NO;
  e = NSEnumerateHashTable(self->uDeleted);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    [eo propagateDeleteWithEditingContext:self];
    didSomething = YES;
  }
  return didSomething;
}

- (void)_validateDeletes {
  NSMutableArray *exceptions;

  exceptions = [NSMutableArray arrayWithCapacity:4];

  [self validateTable:self->deleted
        withSelector:@selector(validateForDelete)
        exceptionArray:exceptions
        continueAfterFailure:[self stopsValidationAfterFirstError]];
  if ([exceptions count] == 1)
    [[exceptions lastObject] raise];
  else if ([exceptions count] > 1) {
    NSException *e;

    e = [NSException aggregateExceptionWithExceptions:exceptions];
    [e raise];
  }
}

- (void)processRecentChanges {
  NSAutoreleasePool *pool;
  NSHashEnumerator e;
  id               eo;
  BOOL             callAgain;

  pool = [[NSAutoreleasePool alloc] init];
  callAgain = NO;
  
  /* propagate deletes */
  
  if ([self propagatesDeletesAtEndOfEvent])
    callAgain = [self _propagateDeletes];
  
  /* process deletes */

  e = NSEnumerateHashTable(self->uDeleted);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    NSHashInsert(self->deleted,  eo);
    NSHashRemove(self->updated,  eo);
    NSHashRemove(self->inserted, eo);
    NSHashRemove(self->uUpdated,  eo);
    NSHashRemove(self->uInserted, eo);
  }
  NSResetHashTable(self->uDeleted);
  
  /* process inserts */
  
  e = NSEnumerateHashTable(self->uInserted);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    NSHashInsert(self->inserted, eo);
    NSHashRemove(self->deleted,  eo);

    NSLog(@"ERROR[%s]: would have 'registerUndoWithTarget: ...'. abort!'");
    abort();
    //[um registerUndoWithTarget:self
    //    selector:@selector(deleteObject:)
    //    object:eo];
  }
  NSResetHashTable(self->uInserted);
  
  /* process updates */

  e = NSEnumerateHashTable(self->uUpdated);
  while ((eo = NSNextHashEnumeratorItem(&e))) {
    EOObjectInfo *info;
    
    info = NSMapGet(self->idToInfo, eo);
    NSAssert1(info, @"missing info for EO %@", eo);

    NSLog(@"ERROR[%s]: would have 'registerUndoWithTarget: ...'. abort!'");
    abort();
    //[um registerUndoWithTarget:eo
    //    selector:@selector(updateFromSnapshot:)
    //    object:info->eventSnapshot];
    
    /* compare against committed snapshot */
    
    if ([[eo changesFromSnapshot:info->snapshot] count] > 0) {
      NSHashInsert(self->updated, eo);
      RELEASE(info->eventSnapshot);
      info->eventSnapshot = [eo snapshot];
      info->eventSnapshot = RETAIN(info->eventSnapshot);
    }
    else {
      /* EO has reached it's original state, so remove from changed objects */
      NSHashRemove(self->updated, eo);
    }
  }
  NSResetHashTable(self->uUpdated);

  RELEASE(pool); pool = nil;
  
  if (callAgain)
    [self processRecentChanges];
}

- (void)saveChanges {
  NSAutoreleasePool *pool;
  
  if (![self hasChanges])
    /* no changes to be saved .. */
    return;

  pool = [[NSAutoreleasePool alloc] init];
  
  /* notify delegates */
  [self->editors
       makeObjectsPerformSelector:@selector(ppTransactionWillSaveChanges:)
       withObject:self];
  if ([self->delegate
           respondsToSelector:@selector(ppTransactionWillSaveChanges:)])
    [self->delegate ppTransactionWillSaveChanges:self];
  
  /* process changes since last event */
  [self processRecentChanges];
  
  /* propagate deletes */
  if (([self _propagateDeletes]))
    [self processRecentChanges];

  /* validate deletes */
  [self _validateDeletes];
  
  /* process changes since last event */
  [self processRecentChanges];
  
  /* validate changes */
  [self validateChangesForSave];
  
  /* save in store */
  [[self parentObjectStore] saveChangesInTransaction:self];
  
  /* update snapshots */
  
  [self _updateSnapshotsOfObjectsInTable:self->inserted];
  [self _updateSnapshotsOfObjectsInTable:self->updated];
  
  /* changes were successfully stored */
  NSResetHashTable(self->inserted);
  NSResetHashTable(self->deleted);
  NSResetHashTable(self->updated);

  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"EOObjectsChangedInStore"
                         object:self];

  RELEASE(pool);
}

- (NSException *)tryToSaveChanges {
  NSException *e;

  *(&e) = nil;
  NS_DURING
    [self saveChanges];
  NS_HANDLER
    e = RETAIN(localException);
  NS_ENDHANDLER;
  
  return AUTORELEASE(e);
}

/* editors */

- (void)addEditor:(id)_editor {
  if (self->editors) {
    id tmp;
    
    tmp = [self->editors mutableCopy];
    RELEASE(self->editors);
    
    [tmp addObject:_editor];
    self->editors = [tmp copy];
    RELEASE(tmp);
  }
  else
    self->editors = [[NSArray alloc] initWithObjects:&_editor count:1];
}
- (void)removeEditor:(id)_editor {
  id tmp;
    
  tmp = [self->editors mutableCopy];
  RELEASE(self->editors);
    
  [tmp removeObjectIdenticalTo:_editor];
  self->editors = [tmp copy];
  RELEASE(tmp);
}

- (NSArray *)editors {
  return self->editors ? self->editors : [NSArray array];
}

/* NSLocking */

- (void)lock {
  NSAutoreleasePool *pool;
  [self->lock lock];
  if (self->pools == nil) self->pools = [[NSMutableArray alloc] init];
  pool = [[NSAutoreleasePool alloc] init];
  [self->pools addObject:pool];
  RELEASE(pool);
}
- (void)unlock {
  [self->pools removeObjectAtIndex:([self->pools count] - 1)];
  [self->lock unlock];
}
- (BOOL)tryLock {
  if ([self->lock tryLock]) {
    NSAutoreleasePool *pool;

    if (self->pools == nil) self->pools = [[NSMutableArray alloc] init];
    pool = [[NSAutoreleasePool alloc] init];
    [self->pools addObject:pool];
    RELEASE(pool);
    return YES;
  }
  else
    return NO;
}

- (void)registerPostSync:(PPPostSync *)_postSync {
  if (self->registeredPostSyncs == nil) {
    self->registeredPostSyncs = [[NSMutableArray alloc] initWithCapacity:4];
  }
  [self->registeredPostSyncs addObject:_postSync];
}
- (NSArray *)registeredPostSyncs {
  return (self->registeredPostSyncs == nil)
    ? [NSArray array]
    : self->registeredPostSyncs;
}


/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@[%p]: parent=%@ hasChanges=%s>",
                     NSStringFromClass([self class]), self,
                     [self parentObjectStore],
                     [self hasChanges] ? "yes" : "no"];
}

@end /* PPTransaction */

@implementation PPTransaction(ObjectStore)

/*
  PPDataStore methods, used in nested-transaction setup's.

    in nested transactions's: self=parent, _ec=child,
    need to copy changes from _ec to this ec
*/

/* initialization */

- (void)initializeObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
}

/* faults */

- (id)faultForGlobalID:(EOGlobalID *)_oid ppTransaction:(PPTransaction *)_ec{
  id eo;

  if ((eo = [_ec objectForGlobalID:_oid]))
    return eo;

  /* should check inserted objects here */
  
  return [[self parentObjectStore] faultForGlobalID:_oid ppTransaction:_ec];
}

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)_oid
  relationshipName:(NSString *)_name
  ppTransaction:(PPTransaction *)_ec
{
  /* should check inserted objects here ?? */
  
  return [[self parentObjectStore]
                arrayFaultWithSourceGlobalID:_oid
                relationshipName:_name
                ppTransaction:_ec];
}

- (id)faultForRow:(id)_row
  entityNamed:(NSString *)_entityName
  ppTransaction:(PPTransaction *)_ec
{
  return [self notImplemented:_cmd];
}

- (void)refaultObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  [self notImplemented:_cmd];
}

/* object registry */

- (void)invalidateAllObjects {
  [self notImplemented:_cmd];
}
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)_oids {
  [self notImplemented:_cmd];
}

/* fetching */

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)_oid
  relationshipName:(NSString *)_relName
  ppTransaction:(PPTransaction *)_ec
{
  /* should check inserted objects here ?? */
  
  return [[self parentObjectStore]
                arrayFaultWithSourceGlobalID:_oid
                relationshipName:_relName
                ppTransaction:self];
}  

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec
  ppTransaction:(PPTransaction *)_ec
{
  NSArray *objects;

  objects = nil;
  if ([self->delegate respondsToSelector:
   @selector(ppTransaction:shouldFetchObjectsDescribedByFetchSpecification:)])
    objects = [self->delegate ppTransaction:self
                   shouldFetchObjectsDescribedByFetchSpecification:_fspec];

  if (objects)
    /* delegate provided result set */
    return objects;
  
  return [self->store objectsWithFetchSpecification:_fspec ppTransaction:_ec];
}

/* locking */

- (void)lockObjectWithGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  [self->store lockObjectWithGlobalID:_oid ppTransaction:_ec];
}

- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  return [self->store isObjectLockedWithGlobalID:_oid ppTransaction:_ec];
}

/* saving */

- (void)saveChangesInTransaction:(PPTransaction *)_ec {
  id i, u, d;

  i = [[_ec insertedObjects] objectEnumerator];
  u = [[_ec updatedObjects]  objectEnumerator];
  d = [[_ec deletedObjects]  objectEnumerator];
  
  [self notImplemented:_cmd];
}

@end

@implementation NSObject(PPTransaction)

- (PPTransaction *)ppTransaction {
  return NSMapGet(idToTx, self);
}

@end /* NSObject(PPTransaction) */

/* value functions for mapping table */

static void mapValRetain(NSMapTable *self, const void *_value) {
  /* do nothing */
}

static void mapValRelease(NSMapTable *self, void *_value) {
  /* do nothing */
}

static NSString *mapDescribe(NSMapTable *self, const void *_value) {
  return [NSString stringWithFormat:
                     @"<oid=%@ object=%@ snapshot=%@ eventSnapshot=%@>",
                     ((EOObjectInfo *)_value)->oid,
                     ((EOObjectInfo *)_value)->eo,
                     ((EOObjectInfo *)_value)->snapshot,
                     ((EOObjectInfo *)_value)->eventSnapshot];
}
