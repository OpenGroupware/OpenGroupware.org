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
    if (![_ds isKindOfClass:[EODataSource class]]) {
      [self logWithFormat:@"ERROR(%s): expected datasource as parameter: %@", 
	    __PRETTY_FUNCTION__, _ds];
      [self release];
      return nil;
    }

    self->context = [_context retain];
    self->source  = [_ds retain];
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
  [self logWithFormat:
	  @"WARNING(%s): use of deprecated method, set namespace in hints",
	  __PRETTY_FUNCTION__];
  return self->namespaces;
}
- (void)setNamespaces:(NSSet *)_ns {
  [self logWithFormat:
	  @"WARNING(%s): use of deprecated method, set namespace in hints",
          __PRETTY_FUNCTION__];
  ASSIGN(self->namespaces, _ns);
}

- (EOModel *)model {
  static EOModel *model = nil;
  
  if (model != nil)
    return model;
  
  model = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model] retain];
  return model;
}
- (EOAttribute *)primaryKeyOfEntityNamed:(NSString *)entityName {
  return [[[[self model] entityNamed:entityName] 
	    primaryKeyAttributes] lastObject];
}

- (void)setGlobalIDKey:(NSString *)_gidName {
  ASSIGNCOPY(self->globalIdKey, _gidName);
}
- (NSString *)globalIDKey {
  NSString *entityName = nil;
  
  if (self->globalIdKey == nil &&
      (entityName = [self->fetchSpecification entityName]) != nil) {
    NSString *key;
    
    key = [[self primaryKeyOfEntityNamed:entityName] columnName];
    self->globalIdKey = [key copy];
  }
  return self->globalIdKey;
}

/* verifies Ids from PropertyManager agains source */

- (void)setVerifyIds:(BOOL)_bool {
  self->verifyIds = _bool;
}
- (BOOL)verifyIds {
  return self->verifyIds;
}

/* fetch method */

- (BOOL)isNamespaceOrDbKeysValid {
  if (self->defaultNamespace == nil && self->dbKeys != nil)
    return NO;
  if (self->defaultNamespace != nil && self->dbKeys == nil)
    return NO;
  return YES;
}

- (void)_fetchPropertiesInNamespaces:(NSSet *)ns
  forObjects:(NSArray *)objects withGIDs:(NSArray *)gids
{
  SkyObjectPropertyManager *objPropMan;
  NSEnumerator *nsEnum;
  NSString     *namesp;
  
  objPropMan = [self->context propertyManager];
  nsEnum     = [ns objectEnumerator];
  while ((namesp = [nsEnum nextObject]) != nil) {
    NSDictionary *props   = nil;
    NSEnumerator *objEnum = nil;
    id           obj      = nil;
    
    props   = [objPropMan propertiesForGlobalIDs:gids namespace:namesp];
    objEnum = [objects objectEnumerator];
    
    while ((obj = [objEnum nextObject]) != nil) {
      NSDictionary *p = nil;
      
      if ((p = [props objectForKey:[self _gidForObj:obj]]) != nil)
        [obj takeValue:p forKey:namesp];
      else {
        [obj takeValue:[NSMutableDictionary dictionaryWithCapacity:8] 
	     forKey:namesp];
      }
    }
  }
}

- (NSArray *)fetchObjects {
  NSArray     *objects = nil;
  NSArray     *gids    = nil;
  EOQualifier *qualifier;
  NSSet       *ns;
  
  ns = (self->namespaces != nil)
    ? self->namespaces
    : [[self->fetchSpecification hints] objectForKey:@"namespaces"];

  /* check preconditions */
  
  if ((qualifier = [self->fetchSpecification qualifier]) == nil) {
    [self logWithFormat:@"WARNING(%s): missing qualifier", 
	    __PRETTY_FUNCTION__];
    return nil;
  }
  
  if (![self isNamespaceOrDbKeysValid]) {
    [self logWithFormat:
	    @"ERROR(%s): either defaultNamespace and dbKeys has to be nil "
            @"or values", __PRETTY_FUNCTION__];
    return nil;
  }

  /* setup cache */
  
  [self->_gid2ObjCache release]; self->_gid2ObjCache = nil;
  self->_gid2ObjCache = [[NSMutableDictionary alloc] initWithCapacity:128];

  /* fetch GIDs and objects */
  
  if ([self _hasAttributeKey:qualifier]) {
    gids = [[self _evaluateQualifier:qualifier] allObjects];
    [self _freeCaches];
    objects = self->verifyIds ? [self _buildObjects:gids] : gids;
  }
  else {
    id           *objs       = NULL;
    int          objCnt      = 0;
    NSEnumerator *enumerator = nil;
    id           obj         = nil;

    [self->source setFetchSpecification:self->fetchSpecification];
    objects    = [self->source fetchObjects];
    objs       = calloc([objects count] + 2, sizeof(id));
    enumerator = [objects objectEnumerator];
    while ((obj = [enumerator nextObject]) != nil) {
      objs[objCnt] = [self _gidForObj:obj];
      objCnt++;
    }
    gids = [NSArray arrayWithObjects:objs count:objCnt];
    free(objs); objs = NULL;
  }
  
  /* fetch properties */
  
  [self _fetchPropertiesInNamespaces:ns forObjects:objects withGIDs:gids];
  
  [self->_gid2ObjCache release]; self->_gid2ObjCache = nil;

  return objects;
}

/* operations */

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

/* accessors */

- (void)setDbKeys:(NSArray *)_keys {
  ASSIGN(self->dbKeys, _keys);
}
- (NSArray *)dbKeys {
  return self->dbKeys;
}

- (void)setDefaultNamespace:(NSString *)_ns {
  ASSIGNCOPY(self->defaultNamespace, _ns);
}
- (NSString *)defaultNamespace {
  return self->defaultNamespace;
}

@end /* SkyAttributeDataSource */
