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

#include <OGoRawDatabase/SkyDBDataSource.h>
#include <OGoRawDatabase/SkyDBDocument.h>
#include "common.h"

@interface SkyDocument(Internals)

- (void)_setGlobalID:(EOGlobalID *)_gid;
- (NSMutableDictionary *)_keyValues;
- (void)_setKeyValues:(NSMutableDictionary *)_dict;

@end /* SkyDocumentType(Internals) */

@interface SkyDBDataSource(Internals)
- (NSString *)_entityName;
@end

@implementation SkyDBDataSource

static NSNull *null = nil;

+ (int)version {
  return [super version] + 0; /* v2 */
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (null == nil)
    null = [[NSNull null] retain];
}

- (id)context {
  return self->context;
}

- (NSArray *)fetchObjects {
  id               *docs       = NULL;
  int              cnt         = 0;
  NSDictionary     *dict       = nil;
  NSEnumerator     *enumerator = nil;
  NSArray          *array      = nil;
  NSString         *eName      = nil;
    
  /*EOAdaptorChannel *adc = */ [self beginTransaction];
  array      = [super fetchObjects];
  enumerator = [array objectEnumerator];
  docs       = malloc(sizeof(id) * [array count]);
  eName      = [self _entityName];

  while ((dict = [enumerator nextObject])) {
    SkyDBDocument *doc = nil;
    
    doc = [[SkyDBDocument alloc] initWithDataSource:self
                                 dictionary:dict
                                 globalID:[dict objectForKey:@"globalID"]
                                 entityName:eName];
    [doc autorelease];
    docs[cnt++] = doc;
  }
  array = [NSArray arrayWithObjects:docs count:cnt];
  if (docs) free(docs); docs = NULL;
  [self commitTransaction];
  return array;
}

- (NSString *)_entityName {
  NSString *entityName = nil;
  
  entityName = [[self fetchSpecification] entityName];
  
  if (entityName == nil) {
    [NSException raise:NSInvalidArgumentException
		 format:
		   @"during createObject, missing entityName, "
		   @"perhaps missing fetchSpecification"];
  }
  return entityName;
}

- (NSSet *)newTableKeySetForAttributeArray:(NSArray *)_attrs {
  NSArray *a;
  
  a = [[_attrs map:@selector(columnName)] map:@selector(lowercaseString)];
  return [[NSSet alloc] initWithArray:a];
}

- (id)createObject {
  SkyDBDocument    *doc    = nil;
  EOAdaptorChannel *adC;
  NSDictionary     *dict   = nil;
  NSString         *eName;
  NSSet         *tableKeys;
  NSEnumerator  *enumerator = nil;
  id            obj         = nil;
  NSArray       *attrs;
  id            *keys       = NULL;
  id            *vals       = NULL;
  unsigned      cnt;

  eName = [self _entityName];
  adC   = [self beginTransaction];
  
  attrs = [adC attributesForTableName:eName];
  if ([attrs count] == 0) {
    [NSException raise:NSInvalidArgumentException
		 format:@"could not find table for entity named %@", eName];
  }
  
  tableKeys = [self newTableKeySetForAttributeArray:attrs];
  cnt  = [tableKeys count];
  keys = calloc(cnt + 2, sizeof(id));
  vals = calloc(cnt + 2, sizeof(id));
  cnt  = 0;
  enumerator = [tableKeys objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    keys[cnt] = obj;
    vals[cnt] = null;
    cnt++;
  }
  dict = [NSMutableDictionary dictionaryWithObjects:vals
			      forKeys:keys count:cnt];
    
  if (keys != NULL) free(keys); keys = NULL;
  if (vals != NULL) free(vals); vals = NULL;
  
  doc = [[SkyDBDocument alloc]
                        initWithDataSource:self
                        dictionary:dict globalID:nil
                        entityName:eName];
  doc = [doc autorelease];
  [self commitTransaction];
  return doc;
}

- (BOOL)canProcessObject:(id)_object {
  return [_object isKindOfClass:[SkyDBDocument class]] ? YES : NO;
}

- (void)_checkObject:(id)_obj {
  if ([self canProcessObject:_obj])
    return;
  
  [NSException raise:NSInvalidArgumentException
	       format:
		 @"argument passed in is not a SkyDBDocument object: %@",_obj];
}

/* operations */

- (NSException *)isDocumentValidForInsertion:(SkyDBDocument *)_doc {
  if ([_doc globalID] != nil) {
    [NSException raise:NSInvalidArgumentException
		 format:@"document is already inserted: %@", _doc];
  }
  if (![_doc isComplete]) {
    [NSException raise:NSInvalidArgumentException
		 format:@"document is incomplete: %@", _doc];
  }
  return nil;
}

- (NSException *)isDocumentValidForUpdate:(SkyDBDocument *)_doc {
  if (![_doc isValid]) {
    [NSException raise:NSInvalidArgumentException
		 format:@"document is incomplete: %@", _doc];
  }
  return nil;
}

- (void)insertObject:(id)_obj {
  SkyDBDocument       *doc;
  NSMutableDictionary *dict   = nil;

  if (_obj == nil) return;
  [self _checkObject:_obj];
  doc = _obj;
  
  [[self isDocumentValidForInsertion:doc] raise];
  
  dict = [doc _keyValues];
  
  [self debugWithFormat:@"INSERT document:\n%@\record:\n%@", doc, dict];
  
  [super insertObject:dict];
  
  [doc _setGlobalID:[dict valueForKey:@"globalID"]];
  [doc _setKeyValues:dict];
}

- (void)updateObject:(id)_obj {
  SkyDBDocument *doc = nil;
  NSMutableDictionary *dict = nil;

  if (_obj == nil) return;
  [self _checkObject:_obj];
  doc = _obj;

  [[self isDocumentValidForUpdate:doc] raise];
  
  dict = [[[doc _keyValues] mutableCopy] autorelease];
  [dict setObject:[doc globalID] forKey:@"globalID"];
  [super updateObject:dict];
}

- (void)deleteObject:(id)_obj {
  SkyDBDocument *doc = nil;
  NSMutableDictionary *dict = nil;
  
  if (_obj == nil) return;
  [self _checkObject:_obj];
  doc = _obj;
  
  if (![doc isValid]) {
    NSLog(@"ERROR[%s] try to delete invalid doc", __PRETTY_FUNCTION__);
    return;
  }
  dict = [doc _keyValues];

  [super deleteObject:dict];
  [doc invalidate];
}

@end /* SkyDBDocumentDataSource */
