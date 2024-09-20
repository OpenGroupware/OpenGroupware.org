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

#include "PPRecordDatabase.h"
#include "PPSyncContext.h"
#include "PPClassDescription.h"
#include "PPRecordFaultHandler.h"
#include "common.h"

#include "PPTransaction.h"

static EONull *null = nil;

@implementation PPRecordDatabase

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

- (id)init {
  if ((self = [super init])) {
    self->oidToRecord = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                         NSObjectMapValueCallBacks,
                                         119);
    self->recordToOid = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                         NSObjectMapValueCallBacks,
                                         119);
  }
  return self;
}

- (void)dealloc {
  int i;
  for (i = 0; i < 15; i++)
    RELEASE(self->categories[i]);
  
  if (self->oidToRecord)
    NSFreeMapTable(self->oidToRecord);
  if (self->recordToOid)
    NSFreeMapTable(self->recordToOid);
  [super dealloc];
}

/* accessors */

- (unsigned char)indexOfCategoryWithID:(unsigned char)_cid {
  int i;
  for (i = 0; i < 15; i++) {
    if (self->categoryIDs[i] == _cid)
      return i;
  }
  return 0;
}
- (NSString *)categoryForID:(unsigned char)_cid {
  int i;
  for (i = 0; i < 15; i++) {
    if (self->categoryIDs[i] == _cid)
      return [self categoryAtIndex:i];
  }
  return nil;
}
- (unsigned char)categoryIDAtIndex:(int)_idx {
  return (_idx >= 0 && _idx < 15)
    ? self->categoryIDs[_idx]
    : 0;
}

- (NSString *)categoryAtIndex:(int)_idx {
  return (_idx >= 0 && _idx < 15)
    ? self->categories[_idx]
    : nil;
}
- (int)indexOfCategory:(NSString *)_category {
  int i;
  
  for (i = 0; i < 15; i++) {
    NSString *s;

    s = self->categories[i];
    
    if ([s isEqualToString:_category])
      return i;
  }
  
  return NSNotFound;
}

- (NSArray *)categories {
  NSMutableArray *a;
  int i;
  
  a = [NSMutableArray arrayWithCapacity:16];
  
  for (i = 0; i < 15; i++) {
    id c = self->categories[i];
    
    if ([c length] > 0)
      [a addObject:c];
  }
  
  return a;
}

/* notifications */

- (EOClassDescription *)classDescriptionNeededForEntityName:(NSString *)_name {
  return nil;
}
- (EOClassDescription *)classDescriptionNeededForClass:(Class)_class {
  PPClassDescription *pp;

  pp = nil;
  
  if ([_class isKindOfClass:[PPRecord class]]) {
    long _c, _t;

    _c = [_class respondsToSelector:@selector(palmCreator)]
      ? [_class palmCreator]
      : 0;
    _t    = [_class respondsToSelector:@selector(palmType)]
      ? [_class palmType]
      : 'DATA';
    
    pp = [[PPClassDescription alloc] initWithClass:_class creator:_c type:_t];
  }
  
  return AUTORELEASE(pp);
}

- (int)decodeAppBlock:(NSData *)_block {
  const unsigned char *record;
  int                 len, i;
  const unsigned char *start;
  struct CategoryAppInfo category;
  
  record = start = [_block bytes];
  len    = [_block length];
  
  i = unpack_CategoryAppInfo(&category, (char*)record, len);
  
  if (!record) {
    NSLog(@"APPINFO DECODING ERROR: buffer=NULL, len=%i", i + 4);
    return 0;
  }
  if (i == 0) {
    NSLog(@"APPINFO DECODING ERROR: i==0");
    return 0;
  }
  record += i;
  len    -= i;

  for (i = 0; i < 15; i++) {
    RELEASE(self->categories[i]);
    self->categories[i]  = [[NSString alloc] initWithCString:category.name[i]];
    self->categoryIDs[i] = category.ID[i];
  }
  
  return record - start;
}

- (void)syncContext:(PPSyncContext *)_ctx openedDatabaseWithHandle:(int)_dh {
  NSEnumerator *oids;
  EOGlobalID *oid;
  
  [super syncContext:_ctx openedDatabaseWithHandle:_dh];

  /* make objects/faults for database */
  
  oids = [[_ctx readRecordIDsOfDatabase:self] objectEnumerator];
  while ((oid = [oids nextObject])) {
#if 0
    NSLog(@"oid=%@, fault=%@", oid,
          [self faultForGlobalID:oid]);
#endif
    [self faultForGlobalID:oid];
  }
}

- (void)syncContextClosedDatabase:(PPSyncContext *)_ctx {
  [super syncContextClosedDatabase:_ctx];
}

/* records */

- (Class)databaseRecordClassForGlobalID:(EOGlobalID *)_oid {
  return [EOGenericRecord class];
}

- (id)objectForGlobalID:(EOGlobalID *)_oid {
  return NSMapGet(self->oidToRecord, _oid);
}
- (EOGlobalID *)globalIDForObject:(id)_object {
  return NSMapGet(self->recordToOid, _object);
}

- (void)recordObject:(id)_object globalID:(EOGlobalID *)_oid {
  EOGlobalID *old;
  
  NSAssert(_oid,    @"missing oid ..");
  NSAssert(_object, @"missing object ..");
  
  old = NSMapGet(self->recordToOid, _object);
  NSMapInsert(self->oidToRecord, _oid, _object);
  NSMapInsert(self->recordToOid, _object, _oid);
  if (old) NSMapRemove(self->oidToRecord, old);
}

- (id)faultForGlobalID:(EOGlobalID *)_oid {
  PPRecordFaultHandler *handler;
  id o;

  NSAssert(_oid, @"missing oid ..");
  
  if ((o = [self objectForGlobalID:_oid])) {
    /* already registered */
    return o;
  }
  
  /* make a fault */

  //NSLog(@"make fault for oid %@", _oid);
  
  o = [[[self databaseRecordClassForGlobalID:_oid] alloc] init];
  
  handler = [[PPRecordFaultHandler alloc] initWithDatabase:self oid:_oid];
  [EOFault makeObjectIntoFault:o withHandler:handler];
  [handler release]; handler = nil;
  
  /* record fault */
  
  [self recordObject:o globalID:_oid];
  
  return AUTORELEASE(o);
}

- (NSArray *)registeredObjects {
  return NSAllMapTableValues(self->oidToRecord);
}

/* store operations */

- (NSData *)packRecord:(id)_eo {
  return nil;
}

- (BOOL)insertRecord:(id)_eo {
  NSData        *data;
  int           category;
  unsigned char categoryID;
  EOGlobalID    *oid, *old;
  
  old = NSMapGet(self->recordToOid, _eo);
  
#if DEBUG
  NSAssert1((old == nil) || [old isTemporary],
            @"old oid %@ is not temporary !", old);
#endif
  
  if ((category = [self indexOfCategory:[_eo storedValueForKey:@"category"]])
      != NSNotFound)
    categoryID = [self categoryIDAtIndex:category];
  else {
    NSLog(@"WARNING: did not find category '%@' !",
          [_eo storedValueForKey:@"category"]);
    categoryID = 0;
  }
  
  data = [self packRecord:_eo];
  if (data == nil) {
    NSLog(@"couldn't pack record %@", _eo);
    return NO;
  }
  
  oid = [[self syncContext] insertRecord:data
                            intoDatabase:self
                            isPrivate:[[_eo valueForKey:@"isPrivate"] boolValue]
                            categoryID:categoryID];
  if (oid == nil)
    return NO;
  
  [self recordObject:_eo globalID:oid];
  return YES;
}

- (BOOL)storeRecord:(id)_eo {
  NSData        *data;
  int           category;
  unsigned char categoryID;
  EOGlobalID    *oid;
  int           flags;
  
  oid = NSMapGet(self->recordToOid, _eo);
  
#if DEBUG
  NSAssert1(![oid isTemporary], @"oid %@ is temporary !", oid);
#endif
  
  if ((category = [self indexOfCategory:[_eo storedValueForKey:@"category"]]))
    categoryID = [self categoryIDAtIndex:category];
  else
    categoryID = 0;
  
  data = [self packRecord:_eo];
  if (data == nil) {
    NSLog(@"couldn't pack record %@", _eo);
    return NO;
  }
  
  flags = 0;
  if ([[_eo storedValueForKey:@"isPrivate"] boolValue])
    flags |= dlpRecAttrSecret;
  if ([[_eo storedValueForKey:@"isDeleted"] boolValue])
    flags |= dlpRecAttrDeleted;
  if ([[_eo storedValueForKey:@"isDirty"] boolValue])
    flags |= dlpRecAttrDirty;
  
  if (![[self syncContext] updateRecord:data
                           inDatabase:self
                           flags:flags
                           categoryID:category /* id or index ?, idx for todo */
                           oid:oid])
    return NO;
  
  return YES;
}
- (BOOL)deleteRecord:(id)_eo {
  EOGlobalID *oid;
  
  oid = NSMapGet(self->recordToOid, _eo);
  
  [_eo takeStoredValue:[NSNumber numberWithBool:YES] forKey:@"isDeleted"];
  return [[self syncContext] deleteRecord:oid inDatabase:self];
}

@end /* PPRecordDatabase */

@implementation EOGenericRecord(PPAwake)

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data
{
  [self takeValue:_data forKey:@"data"];
  [self takeValue:_oid  forKey:@"oid"];
  [self takeValue:[NSNumber numberWithInt:_category] forKey:@"category"];
}

@end

@implementation PPRecord

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

- (void)setDatabase:(PPRecordDatabase *)_db {
  self->db = _db;
}

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data
{
  self->db         = _db;
  self->category   = [[_db categoryAtIndex:_category] copy];
  self->isDirty    = _attrs & dlpRecAttrDirty    ? YES : NO;
  self->isDeleted  = _attrs & dlpRecAttrDeleted  ? YES : NO;
  self->isPrivate  = _attrs & dlpRecAttrSecret   ? YES : NO;
  self->isArchived = _attrs & dlpRecAttrArchived ? YES : NO;

#if 0
  NSLog(@"category is %@ (arg=%i)", self->category, _category);
#endif
}

- (void)dealloc {
  RELEASE(self->category);
  [super dealloc];
}

/* accessors */

- (void)setIsPrivate:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (_flag != self->isPrivate) {
    [self willChange];
    self->isPrivate = _flag;
  }
}
- (BOOL)isPrivate {
  return self->isPrivate;
}

- (void)setIsDeleted:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (!_flag != self->isDeleted) {
    self->isDeleted = _flag;
  }
}
- (BOOL)isDeleted {
  return self->isDeleted;
}

- (void)setIsArchived:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (_flag != self->isArchived) {
    [self willChange];
    self->isArchived = _flag;
  }
}
- (BOOL)isArchived {
  return self->isArchived;
}

- (void)setIsDirty:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (_flag != self->isDirty) {
    [self willChange];
    self->isDirty = _flag;
  }
}
- (BOOL)isDirty {
  return self->isDirty;
}

- (NSException *)validateCategory:(NSString *)_category {
  NSUInteger idx;
  
  if ((idx = [self->db indexOfCategory:_category]) == NSNotFound) {
    NSString     *r;
    NSDictionary *ui;
    
    r = [NSString stringWithFormat:
                    @"category '%@' is not available in Palm",
                    _category];
    
    ui = [NSDictionary dictionaryWithObjectsAndKeys:
                         _category ? _category : @"", @"category",
                         self,     @"record",
                         self->db, @"database",
                         [self->db categories], @"categories",
                         nil];
    
    return [NSException exceptionWithName:@"EOValidationException"
                        reason:r
                        userInfo:ui];
  }
#if 0
  NSLog(@"category is valid (idx=%i, categories=%@)",
        idx, [self->db categories]);
#endif
  return nil;
}
- (void)setCategory:(NSString *)_category {
  if (_category == (id)null) _category = nil;
  
  if (_category != self->category) {
    [self willChange];
    ASSIGN(self->category, _category);
  }
}
- (NSString *)category {
  return self->category;
}

/* ec */

- (EOGlobalID *)globalID {
  PPTransaction *tx;
  
  tx = [self ppTransaction];
  if (tx == nil) NSLog(@"WARNING: object %@ has no transaction !", tx);
  return [tx globalIDForObject:self];
}

/* description */

- (NSString *)propertyDescription {
  return @"";
}

- (NSString *)description {
  NSMutableString *s;

  s = [NSMutableString stringWithCapacity:100];
  [s appendFormat:@"<%@[0x%p]:", NSStringFromClass([self class]), self];

  [s appendString:[self propertyDescription]];

  if ([self category])
    [s appendFormat:@" category=%@", [self category]];
  
  if ([self isDeleted])
    [s appendString:@" deleted"];
  if ([self isDirty])
    [s appendString:@" dirty"];
  if ([self isArchived])
    [s appendString:@" archived"];
  if ([self isPrivate])
    [s appendString:@" private"];
  
  //[s appendFormat:@" db=0x%p", self->db];
  [s appendString:@">"];
  return s;
}

/* EnterpriseObject */

- (NSArray *)attributeKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
                              @"isArchived", @"category", @"isPrivate",
                              @"isDirty",
                              nil];
  }
  return keys;
}
- (NSArray *)allPropertyKeys {
  return [self attributeKeys];
}

@end /* PPRecord */
