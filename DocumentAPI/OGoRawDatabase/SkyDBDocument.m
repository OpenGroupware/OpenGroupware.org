/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include <OGoRawDatabase/SkyDBDocument.h>
#include <OGoRawDatabase/SkyDBDataSource.h>
#include "SkyDBDocumentType.h"
#include "common.h"

@interface SkyDocument(Internals)

- (void)_setGlobalID:(EOGlobalID *)_gid;
- (NSMutableDictionary *)_keyValues;
- (void)_setKeyValues:(NSMutableDictionary *)_dict;

@end /* SkyDocumentType(Internals) */

@implementation SkyDBDocument

- (id)initWithDataSource:(SkyDBDataSource *)_ds
  dictionary:(NSDictionary *)_dict globalID:(EOGlobalID *)_gid
  entityName:(NSString *)_eName
{
  if ((self = [super init])) {
    self->dataSource = RETAIN(_ds);
    
    self->dict       = [_dict   mutableCopy];
    self->gid        = [_gid    copy];
    self->entityName = [_eName  copy];
    self->hasChanged = NO;
    self->isValid    = YES;
    self->docType    = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->dict);
  RELEASE(self->gid);
  RELEASE(self->entityName);
  RELEASE(self->docType);
  RELEASE(self->supportedKeys);
  [super dealloc];
}
#endif

- (BOOL)isDeletable {
  EOGlobalID *lgid;
  
  if (self->dataSource == nil) {
#if DEBUG
    NSLog(@"%s: missing datasource ..", __PRETTY_FUNCTION__);
#endif
    return NO;
  }
  
  lgid = [self globalID];
  if ((lgid == nil) || [lgid isTemporary])
    return NO;
  
  return YES;
}

- (void)invalidate {
  self->isValid = NO;
}

- (BOOL)isValid {
  return self->isValid;
}

- (SkyDocumentType *)documentType {
  if (self->docType == nil) {
    self->docType = [[SkyDBDocumentType alloc] init];
    [self->docType setEntityName:self->entityName];
  }
  return self->docType;
}

- (BOOL)isComplete {
  return YES;
}
- (BOOL)isEdited {
  return self->hasChanged;
}

- (EOGlobalID *)globalID {
  return self->gid;
}

- (BOOL)isNew {
  EOGlobalID *lgid;
  
  if ((lgid = [self globalID]) == nil)
    return YES;
  if ([lgid isTemporary])
    return YES;
  return NO;
}

- (id)context {
  if (self->dataSource)
    return [(id)self->dataSource context];
  
#if DEBUG
  NSLog(@"WARNING(%s): document %@ has no datasource/context !!",
        __PRETTY_FUNCTION__, self);
#endif
  return nil;
}

- (NSString *)entityName {
  return self->entityName;
}

- (NSArray *)supportedKeys {
  if (self->supportedKeys == nil) {
    id tmp;
    tmp = [[self->dict allKeys] mutableCopy];
    [tmp removeObject:@"globalID"];
    self->supportedKeys = [tmp copy];
    RELEASE(tmp); tmp = nil;
  }
  return self->supportedKeys;;
}

/* actions */

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched: %@", __PRETTY_FUNCTION__, _exception);
}

- (BOOL)delete {
  BOOL result = YES;
  
  if (![self isDeletable])
    return NO;
  
  NS_DURING {
    [self->dataSource deleteObject:self];
    RELEASE(self->gid);
    self->gid = nil;
  }
  NS_HANDLER {
#if DEBUG
    [self logException:localException];
#endif
    result = NO;
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)save {
  BOOL result;
  
  if (self->dataSource == nil) {
#if DEBUG
    NSLog(@"%s: missing datasource ..", __PRETTY_FUNCTION__);
#endif
    return NO;
  }
  
  result = YES;
  
  if (![self isNew]) {
    /* update object */
    
    NS_DURING
      [self->dataSource updateObject:self];
    NS_HANDLER
#if DEBUG
      [self logException:localException];
#endif
      result = NO;
    NS_ENDHANDLER;
  }
  else {
    /* insert object */

    NS_DURING
      [self->dataSource insertObject:self];
    NS_HANDLER
#if DEBUG
      [self logException:localException];
#endif
      result = NO;
    NS_ENDHANDLER;
  }
  
#if DEBUG
  if (!result)
    NSLog(@"%s: %s failed", __PRETTY_FUNCTION__,
          [self isNew] ? "update" : "insert");
#endif
  
  return result;
}
- (BOOL)revert {
  return NO;
}

/* key-value coding */

- (id)valueForKey:(NSString *)_k {
  if ([_k isEqualToString:@"isNew"])
    return [NSNumber numberWithBool:[self isNew]];
  if ([_k isEqualToString:@"isEdited"])
    return [NSNumber numberWithBool:[self isEdited]];
  
  if (![[self supportedKeys] containsObject:_k])
    return nil;
  
  return [self->dict valueForKey:_k];
}

- (void)takeValue:(id)_v forKey:_k {
  id tmp;

#if DEBUG && 0
  NSLog(@"%s: takeValue:%@ forKey:%@", __PRETTY_FUNCTION__, _v, _k);
#endif
  
  if (!self->isValid) {
    NSLog(@"ERROR[%s]: attempt to setValue:%@ forKey:%@ "
          @"on invalid SkyDBDocument",
          __PRETTY_FUNCTION__, _v, _k);
    return;
  }
  if (![[self supportedKeys] containsObject:_k]) {
    NSLog(@"WARNING[%s]: attempt to set value for unsupported key '%@'",
          __PRETTY_FUNCTION__, _k);
    return;
  }
  
  if (![_v isNotNull]) _v = nil;
  
  tmp = [self->dict valueForKey:_k];
  
  if (![tmp isEqual:_v]) {
    self->hasChanged = YES;

    NSAssert(self->dict, @"lost dictionary ..");
    [self->dict takeValue:_v forKey:_k];
    
#if DEBUG && 0
    NSLog(@"%s:  stored %@ in dict: %@ ..", __PRETTY_FUNCTION__,
          _v, self->dict);
#endif
  }
#if DEBUG && 0
  else
    NSLog(@"%s:  value didn't change ..", __PRETTY_FUNCTION__);
#endif
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ entityName %@ "
                   @"dict %@",
                   [super description], self->entityName,
                   self->dict];
}

@end /* SkyDBDocumentType */

@implementation SkyDBDocument(Internals)

- (void)_setGlobalID:(EOGlobalID *)_gid {
  if (self->gid != nil)
    NSLog(@"WARNING(%s): overwrite alredy exist gid");
  ASSIGN(self->gid, _gid);
}

- (NSMutableDictionary *)_keyValues {
  return self->dict;
}

- (void)_setKeyValues:(NSMutableDictionary *)_dict {
  ASSIGN(self->dict, _dict);
}

@end /* SkyDocument(Internals) */
