/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "SkyAttributeDataSource.h"
#include "common.h"
#include <LSFoundation/LSFoundation.h>

@interface NSObject(Private)
- (id)globalID;
@end

@interface SkyAttributeDataSource(Internals)
- (BOOL)_hasOnlyDBKeys:(EOQualifier *)_qual;
- (BOOL)_hasOnlyAttrKeys:(EOQualifier *)_qual;
- (BOOL)_hasAttributeKey:(EOQualifier *)_qual;
- (NSSet *)_getGidsFromArray:(NSArray *)_array objectsAreDics:(BOOL)_isDict;
- (NSSet *)_handleQualifier:(EOQualifier *)_qual;
- (NSSet *)_evaluateQualifier:(EOQualifier *)_qual;
- (EOGlobalID *)_gidForObj:(id)_obj;
- (NSArray *)_buildObjects:(NSArray *)_gids;
- (void)_freeCaches;
@end


@implementation SkyAttributeDataSource

- (id)init {
  NSLog(@"WARNING: Wrong initializer, use 'initWithContext:'");
  [self release];
  return nil;
}

- (id)initWithDataSource:(EODataSource *)_ds context:(id)_context {
  if ((self = [super init])) {
    NSAssert([_ds isKindOfClass:[EODataSource class]], @"_ds != EODataSource");
    ASSIGN(self->context, _context);
    ASSIGN(self->source, _ds);
    self->fetchSpecification = nil;
    self->namespaces         = nil;
    self->verifyIds          = NO;
    self->dbKeys             = nil;
  }
  return self;
}

- (void)dealloc {
  [self->context            release];
  [self->fetchSpecification release];
  [self->source             release];
  [self->namespaces         release];
  [self->_gid2ObjCache      release];
  [self->globalIdKey        release];
  [self->dbKeys             release];
  [self->defaultNamespace   release];
  [self->_evaluateAttributeQualifierCache release];
  [self->_evaluateDBQualifierCache        release];
  [self->_evaluateQualifierCache          release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  /* TODO: shouldn't that post a datasource-changed notification? */
  ASSIGN(self->fetchSpecification, _fSpec);
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (NSSet *)namespaces {
  NSLog(@"WARNING[%s]: use of depricated method, set namespace in hints"
        ,__PRETTY_FUNCTION__);
  return self->namespaces;
}
- (void)setNamespaces:(NSSet *)_ns {
  NSLog(@"WARNING[%s]: use of depricated method, set namespace in hints",
        __PRETTY_FUNCTION__);
  ASSIGN(self->namespaces, _ns);
}

- (NSString *)globalIDKey {
  NSString *entityName = nil;
  
  if (self->globalIdKey == nil &&
      (entityName = [self->fetchSpecification entityName]) != nil) {
    EOModel  *model = nil;
    NSString *key   = nil;

    model = [[[self->context valueForKey:LSDatabaseKey] adaptor] model];
    key   =  [(EOAttribute *)[[[model entityNamed:entityName]
                                      primaryKeyAttributes] lastObject]
                             columnName];
    self->globalIdKey = RETAIN(key);
  }
  return self->globalIdKey;
}

- (void)setGlobalIDKey:(NSString *)_gidName {
  ASSIGN(self->globalIdKey, _gidName);
}

/* verifies Ids from PropertyManager agains source */

- (BOOL)verifyIds {
  return self->verifyIds;
}

- (void)setVerifyIds:(BOOL)_bool {
  self->verifyIds = _bool;
}

- (NSArray *)fetchObjects {
  NSArray                  *objects    = nil;
  NSArray                  *gids       = nil;
  NSEnumerator             *enumerator = nil;
  NSString                 *namesp     = nil;
  SkyObjectPropertyManager *objPropMan = nil;
  EOQualifier              *qualifier  = nil;
  NSSet                    *ns         = nil;

  if (self->namespaces != nil)
    ns = self->namespaces;
  else {
    ns = [[self->fetchSpecification hints] objectForKey:@"namespaces"];
  }
  
  if ((qualifier = [self->fetchSpecification qualifier]) == nil) {
    NSLog(@"WARNING[%s]: missing qualifier", __PRETTY_FUNCTION__);
    return nil;
  }

  if ((self->defaultNamespace == nil && self->dbKeys != nil) ||
      (self->defaultNamespace != nil && self->dbKeys == nil)) {
    NSLog(@"ERROR[%s]: either defaultNamespace and dbKeys has to be nil "
          @"or values", __PRETTY_FUNCTION__);
    return nil;
  }
  
  [self->_gid2ObjCache release];
  
  self->_gid2ObjCache = [[NSMutableDictionary alloc] initWithCapacity:128];
  objPropMan          = [self->context propertyManager];
  
  if ([self _hasAttributeKey:qualifier]) {
    gids    = [[self _evaluateQualifier:qualifier] allObjects];
    [self _freeCaches];
    objects = (self->verifyIds == YES) ? [self _buildObjects:gids] : gids;
  }
  else {
    id           *objs       = NULL;
    int          objCnt      = 0;
    NSEnumerator *enumerator = nil;
    id           obj         = nil;

    [self->source setFetchSpecification:self->fetchSpecification];
    objects    = [self->source fetchObjects];
    objs       = malloc(sizeof(id) * [objects count]);
    enumerator = [objects objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      objs[objCnt++] = [self _gidForObj:obj];
    }
    gids = [NSArray arrayWithObjects:objs count:objCnt];
    free(objs); objs = NULL;
  }
  enumerator = [ns objectEnumerator];
  while ((namesp = [enumerator nextObject])) {
    NSDictionary *props   = nil;
    NSEnumerator *objEnum = nil;
    id           obj      = nil;

    props   = [objPropMan propertiesForGlobalIDs:gids namespace:namesp];
    objEnum = [objects objectEnumerator];
    
    while ((obj = [objEnum nextObject])) {
      NSDictionary *p = nil;

      if ((p = [props objectForKey:[self _gidForObj:obj]]) != nil)
        [obj takeValue:p forKey:namesp];
      else
        [obj takeValue:[NSMutableDictionary dictionary] forKey:namesp];
    }
  }
  [self->_gid2ObjCache release]; self->_gid2ObjCache = nil;

  return objects;
}

- (id)createObject {
  return [self->source createObject];
}

- (void)insertObject:(id)_obj {
  [self->source insertObject:_obj];
}

- (void)deleteObject:(id)_obj {
  [self->source deleteObject:_obj];
}

- (void)updateObject:(id)_obj {
  [self->source updateObject:_obj];
}

- (void)setDbKeys:(NSArray *)_keys {
  ASSIGN(self->dbKeys, _keys);
}
- (NSArray *)dbKeys {
  return self->dbKeys;
}

- (void)setDefaultNamespace:(NSString *)_ns {
  ASSIGN(self->defaultNamespace, _ns);
}
- (NSString *)defaultNamespace {
  return self->defaultNamespace;
}

@end /* SkyAttributeDataSource */
