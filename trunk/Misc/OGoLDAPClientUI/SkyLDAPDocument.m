
#include <NGLdap/NGLdap.h>
#include "common.h"
#include "SkyLDAPDocument.h"
#include "SkyLDAPDataSource.h"

@interface SkyLDAPDocument(Internals)

- (void)setGlobalID:(EOGlobalID *)_gid;
- (void)setValues;
- (NSDictionary *)newAttrs;
- (NSDictionary *)removedAttrs;
- (NSDictionary *)updatedAttrs;
- (NSString *)uniqueId;

@end // SkyLDAPDocument(Internals).


@implementation SkyLDAPDocument

+ (int)version {
  return [super version] + 0;
}

- (SkyDocumentType *)documentType {
  return [self subclassResponsibility:_cmd];
}

- (BOOL)isComplete {
  [self subclassResponsibility:_cmd];
  return NO;
}

#if 0
+ (id)documentWithDN:(NSString *)_dn newDocument:(BOOL)_new {
  //SkyLDAPDataSource *ds  = nil;
  //SkyLDAPDocument   *doc = nil;

  if (! [_dn length]) {
    NSLog(@"%s missing dn", __PRETTY_FUNCTION__);
    return nil;
  }

  ds = [[self dataSourceClass] alloc];
  if (ds) {

  }

  doc =  initWithDN:_dn newDocument:_new];
  return AUTORELEASE();

  return nil;
}

- (id)initWithDN:(NSString *)_dn newDocument:(BOOL)_new {
  if (![_dn length]) {
    NSLog(@"%s missing dn", __PRETTY_FUNCTION__);
    return nil;
  }

  if ((self = [super init])) {
    ASSIGN(self->dn, _dn);

    self->record       = nil;
    self->newAttrs     = [[NSMutableDictionary alloc] initWithCapacity:0];
    self->updatedAttrs = [[NSMutableDictionary alloc] initWithCapacity:0];
    self->removedAttrs = [[NSMutableDictionary alloc] initWithCapacity:0];

    if (! _new)
      [self load];
  }
  return self;
}
#endif /* 0 */

- (id)initWithGlobalID:(EOGlobalID *)_gid record:(NSDictionary *)_record
  dataSource:(SkyLDAPDataSource *)_ds 
{
  if ((self = [super init])) {
    NSAssert(_ds, @"missing datasource");

    self->record     = [_record retain];
    self->globalID   = [_gid    retain];
    self->dataSource = [_ds     retain];

    self->newAttrs     = [[NSMutableDictionary alloc] initWithCapacity:16];
    self->updatedAttrs = [[NSMutableDictionary alloc] initWithCapacity:16];
    self->removedAttrs = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  return self;
}


- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->record);
  RELEASE(self->newAttrs);
  RELEASE(self->updatedAttrs);
  RELEASE(self->removedAttrs);
  RELEASE(self->dn);
  RELEASE(self->globalID);
  [super dealloc];
}

/* accessors */

- (EOGlobalID *)globalID {
  return self->globalID;
}

+ (Class)dataSourceClass {
  [self notImplemented:_cmd];
  return Nil;
}

- (SkyLDAPDataSource *)dataSource {
  return self->dataSource;
}

- (void)setDN:(NSString *)_dn {
  ASSIGN(self->dn, _dn);

  if (![_dn length]) {
    NSLog(@"%s missing dn", __PRETTY_FUNCTION__);
  }

  [self load];
}

- (NSString *)dn {
  return self->dn;
}

- (void)invalidate {
  RELEASE(self->record);       self->record       = nil;
  RELEASE(self->newAttrs);     self->newAttrs     = nil;
  RELEASE(self->updatedAttrs); self->updatedAttrs = nil;
  RELEASE(self->removedAttrs); self->removedAttrs = nil;
  RELEASE(self->globalID);     self->globalID     = nil;
  // dn and dataSource needed for reload. Do not clean them.
}

- (BOOL)isEqual:(id)_obj {
  if (_obj == self)
    return YES;

  if ([_obj isKindOfClass:[self class]])
    return [self isEqualToLDAPDocument:(SkyLDAPDocument *)_obj];

  return NO;
}

- (BOOL)isEqualToLDAPDocument:(SkyLDAPDocument *)_doc {
  return [[_doc globalID] isEqual:[self globalID]];
}

- (NSDictionary *)record {
  return self->record;
}

- (id)valueForKey:(id)_key {
  id value;

  if ([_key isEqualToString:@"globalID"])
    return [self globalID];

  if ([self->removedAttrs objectForKey:_key])
    return nil;

  if ((value = [self->updatedAttrs objectForKey:_key]))
    return value;

  if ((value = [self->newAttrs objectForKey:_key]))
    return value;

  return [self->record objectForKey:_key];
}

- (void)takeValue:(id)_value forKey:(id)_key {
  //NSLog(@"%s v = %@, k = %@", __PRETTY_FUNCTION__, _value, _key);

  if ([self->record objectForKey:_key]) {
    if ([_value isNotNull]) {
      [self->updatedAttrs setObject:_value forKey:_key];
    }
    else {
      [self->removedAttrs setObject:[EONull null] forKey:_key];
    }
  }
  else {
    if ([_value isNotNull]) {
      [self->newAttrs setObject:_value forKey:_key];
    }
  }
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ record: %@",
                   [super description], self->record];
}

// Protocol: SkyDocumentEditing.

- (BOOL)isReadable { // TODO

  return YES;
}

- (BOOL)isWriteable { // TODO

  return NO;
}

- (BOOL)isRemovable { // TODO

  return NO;
}

- (BOOL)isNew {
  return !self->record;
}

- (BOOL)isEdited {
  if ([self->newAttrs count] || [self->updatedAttrs count] ||
                                [self->removedAttrs count])
    return YES;
  return NO;
}

- (BOOL)load { // doesn't belong to this protocol ... perhaps it should?
  // TODO

  return YES;
}

- (BOOL)save {
  NSLog(@"%s isnew=%d what=%@", __PRETTY_FUNCTION__, [self isNew], self);

  if ([self isNew])
    [self->dataSource insertObject:self];
  else
    [self->dataSource updateObject:self];

  [self setValues]; // update our loaded attributes.

  return YES;
}

- (BOOL)delete {
  [self->dataSource deleteObject:self];
  return YES;
}

- (BOOL)reload {
  [self invalidate];

  return [self load];
}

/* internals */

// Cleans up the different dictionaries. Called AFTER saving.
// Caution if called from other points because the isEdited
// and isNew methods need the uncleaned data to make their
// decisions.

- (void)setValues {
  NSMutableDictionary *dict;

  if (self->record)
    dict = [self->record mutableCopy];
  else
    dict = [[NSMutableDictionary alloc] initWithCapacity:0];

  [dict removeObjectsForKeys:[self->removedAttrs allKeys]];
  [dict takeValuesFromDictionary:self->updatedAttrs];
  [dict takeValuesFromDictionary:self->newAttrs];

  [self->updatedAttrs removeAllObjects];
  [self->newAttrs     removeAllObjects];
  [self->removedAttrs removeAllObjects];
  
  RELEASE(self->record);
  self->record = [dict copy];
  RELEASE(dict);
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  ASSIGN(self->globalID, _gid);
}

- (NSDictionary *)newAttrs {
  return self->newAttrs;
}

- (NSDictionary *)updatedAttrs {
  return self->updatedAttrs;
}

- (NSDictionary *)removedAttrs {
  return self->removedAttrs;
}

- (NSString *)uniqueId {
  return [self notImplemented:_cmd];
}

@end /* SkyLDAPDocument */
