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

#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>

#define PROFILE 1

@interface SkyProjectFileManagerCache(Caching_Internals)
- (void)takeCacheValue:(id)_v forKey:(NSString *)_k;
- (id)cacheValueForKey:(NSString *)_k;
@end

#include "common.h"

@interface SkyProjectFileManagerCache(Internals)
- (EOAdaptorChannel *)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
- (NSString *)buildPathWithParent:(NSString *)_parent doc:(NSDictionary *)_doc;
- (void)createCacheStructuresWithMap:(NGHashMap *)_map
  root:(NSDictionary *)_root;
- (void)initializeFolderNameCaches;
- (NSMutableDictionary *)pk2FileNameCache;
- (NGMutableHashMap *)parent2ChildDirectoriesCache;
- (NSMutableDictionary *)fileName2ChildAttrs;
- (NSMutableDictionary *)cacheChildsForFolderStatusCache;
- (NSMutableDictionary *)fileName2ChildNames;
- (NSMutableDictionary *)pk2GenRecCache;
- (NSMutableDictionary *)fileName2GIDCache;
- (NSMutableDictionary *)allVersionAttrsAtPathCache;
- (NSString *)buildSelectForSiblingSearch:(EOEntity *)_entity
  attrs:(NSArray *)_attrs;
- (NSString *)buildSelectForAllSubVersionsWithAttributes:(NSArray *)_attrs;
- (NSArray *)fetchDocsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  qualifier:(EOQualifier *)_qual;
- (NSDictionary *)fetchDocEditingsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  docPKeys:(NSArray *)_pkeys;
- (NSString *)accountLogin4PersonId:(NSNumber *)_personId;
- (EOQualifier *)convertQualifier:(EOQualifier *)_qual;
- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier
  manager:(id)_manager;
- (void)cacheChildsForFolder:(NSString *)_folder
  orSiblingsForId:(NSNumber *)_sid;
- (NSDictionary *)rootFolderAttrs;
- (NSMutableDictionary *)fileAttributesAtPathCache;
- (void)cacheChildsForSiblings:(NSArray *)_siblingIds;
- (NSArray *)pathsForGIDs:(NSArray *)_gids manager:(id)_manager;
@end /* SkyProjectFileManagerCache(Internals) */

@implementation SkyProjectFileManagerCache(Caching)

- (NSArray *)childAttributesAtPath:(NSString *)_path manager:(id)_manager {
  NSArray *array;

  if (![_path length])
    return [NSArray array];
  
  if (!(array = [[self fileName2ChildAttrs] objectForKey:_path])) {
    [self cacheChildsForFolder:_path orSiblingsForId:nil];
    if (!(array = [[self fileName2ChildAttrs] objectForKey:_path])) {
      NSLog(@"ERROR[%s]: missing childs for parent %@",
            __PRETTY_FUNCTION__, _path);
    }
  }
  return array;
}

- (NSArray *)childFileNamesAtPath:(NSString *)_path manager:(id)_manager {
  NSArray *array;

  if (![_path length])
    return [NSArray array];
  
  if (!(array = [[self fileName2ChildNames] objectForKey:_path])) {
    [self cacheChildsForFolder:_path orSiblingsForId:nil];
    if (!(array = [[self fileName2ChildNames] objectForKey:_path])) {
      NSLog(@"ERROR[%s]: missing childs for parent %@",
            __PRETTY_FUNCTION__, _path);
    }
  }
  return array;
}

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path manager:(id)_manager {
  NSDictionary *result;

  if ([_path length] == 0)
    return nil;
  
  if ((result = [[self fileAttributesAtPathCache] objectForKey:_path]) ==nil) {
    /* 
       Fetch all file attributes for the folder the file is in and cache that.
       Then retrieve the result from the cache.
    */
    [self cacheChildsForFolder:[_path stringByDeletingLastPathComponent]
          orSiblingsForId:nil /* Note: only one argument is allowed */];
    result = [[self fileAttributesAtPathCache] objectForKey:_path];
  }
  if (result == nil) {
    NSMutableDictionary *mdict;

    mdict = [self fileAttributesAtPathCache];
    [mdict setObject:[EONull null] forKey:_path];
  }
  if (![result isNotNull])
    result = nil;
  
  return result;
}

/* if not found in cache, reload this cache entry */
- (EOGlobalID *)gidForPath:(NSString *)_path manager:(id)_manager {
  EOKeyGlobalID *gid;

  gid = nil;
  
  if ([_path hasSuffix:@"//"])
    _path = [_path substringToIndex:[_path length] - 1];
    
  if (![_path cStringLength]) {
    NSLog(@"ERROR[%s]: missing _path ...", __PRETTY_FUNCTION__);
    return nil;
  }
  if (!(gid = [[self fileName2GIDCache] objectForKey:_path])) {
    NSString *p;

    /* suppose to get an not cached file --> now load complete folder into cache */
    p = [_path stringByDeletingLastPathComponent];
    if ([p length])
      [self cacheChildsForFolder:p orSiblingsForId:nil];

    gid = [[self fileName2GIDCache] objectForKey:_path];
  }
  if (!gid) {
    NSMutableDictionary *mdict;

    mdict = [self fileName2GIDCache];
    [mdict setObject:[EONull null] forKey:_path];
  }
  if (![gid isNotNull])
    gid = nil;
  
  return gid;
}

/*
  returns a filepath for the global id
  
*/
- (NSString *)pathForGID:(EOGlobalID *)_gid manager:(id)_manager {
  EOKeyGlobalID *kid;
  NSString      *path;
  NSNumber      *key;

  kid = (EOKeyGlobalID *)_gid;
  if (![kid isNotNull]) {
    NSLog(@"ERROR[%s]: missing gid ...", __PRETTY_FUNCTION__);
    return nil;
  }
  if (![[kid entityName] isEqualToString:@"Doc"] &&
      ![[kid entityName] isEqualToString:@"DocumentEditing"]) {
    NSLog(@"ERROR[%s]: pathForGID_cache can only handle Doc Global Ids ... "
          @"got %@", __PRETTY_FUNCTION__, _gid);
    return nil;
  }
  key = [(EOKeyGlobalID *)_gid keyValues][0];
  if (![path = [[self pk2FileNameCache] objectForKey:key] isNotNull]) {
    [self cacheChildsForFolder:nil orSiblingsForId:key];

    if (![path = [[self pk2FileNameCache] objectForKey:key] isNotNull]) {
      NSLog(@"WARNING[%s]: missing path for id %@",
            __PRETTY_FUNCTION__, _gid);
    }
  }
  return [[path retain] autorelease];
}

- (NSArray *)pathsForGIDs:(NSArray *)_gids manager:(id)_manager {
  NSMutableArray *result;
  NSMutableArray *toBeFetched;
  NSEnumerator   *enumerator;
  id             obj;
  int            cnt;
  
  cnt         = [_gids count];
  result      = [NSMutableArray arrayWithCapacity:cnt];
  toBeFetched = [NSMutableArray arrayWithCapacity:cnt];
  enumerator  = [_gids objectEnumerator];
    
  while ((obj = [enumerator nextObject])) {
    EOKeyGlobalID *kid;
    NSString      *path;
    NSNumber      *key;

    kid = (EOKeyGlobalID *)obj;

    if (![[kid entityName] isEqualToString:@"Doc"] &&
        ![[kid entityName] isEqualToString:@"DocumentEditing"]) {
      NSLog(@"ERROR[%s]: pathForGID_cache can only handle Doc Global Ids ... "
            @"got %@", __PRETTY_FUNCTION__, _gids);
      return nil;
    }
    key = [(EOKeyGlobalID *)obj keyValues][0];
    if ([path = [[self pk2FileNameCache] objectForKey:key] isNotNull]) {
      [result addObject:path];
    }
    else {
      [toBeFetched addObject:key];
    }
  }
  {
    NSAutoreleasePool *pool;

    pool = [NSAutoreleasePool new];
    if ([toBeFetched count] > 0) {
      [self cacheChildsForSiblings:toBeFetched];
      enumerator = [toBeFetched objectEnumerator];

      while ((obj = [enumerator nextObject])) {
        NSString  *path;
      
        if ([path = [[self pk2FileNameCache] objectForKey:obj] isNotNull]) {
          [result addObject:path];
        }
        else {
          NSLog(@"ERROR[%s]: pathForGID_cache can only handle Doc Global Ids... "
                @"got %@", __PRETTY_FUNCTION__, _gids);
        }
      }
    }
    RELEASE(pool); pool = nil;
  }
  return result;
}

- (id)genericRecordForGID:(EOGlobalID *)_gid manager:(id)_manager {
  EOKeyGlobalID       *kgid;
  NSString            *entityName;
  id                  genRec, doc;
  NSMutableDictionary *cache;

  if (![_gid isNotNull]) {
    NSLog(@"WARNING[%s] genericRecordForGID_cache called with empty _gid",
          __PRETTY_FUNCTION__);
    return nil;
  }
    
  kgid       = (id)_gid;
  entityName = [kgid entityName];
  genRec     = nil;
  cache      = [self pk2GenRecCache];

  if ((doc = [cache objectForKey:[kgid keyValues][0]]))
    return doc;
  
  if ([entityName isEqualToString:@"Doc"]) {
    NSString *path;

    if (![path = [self pathForGID:kgid manager:_manager] isNotNull]) {
      NSLog(@"WARNING[%s] missing path for gid %@", __PRETTY_FUNCTION__, _gid);
      return nil;
    }
    doc = [self genericRecordForFileName:path manager:_manager];
    [cache setObject:doc forKey:[kgid keyValues][0]];
  }
  else if ([entityName isEqualToString:@"DocumentEditing"]) {
    NSLog(@"WARNING[%s]: using genericRecordForGID_cache for DocumentEditing %@",
          __PRETTY_FUNCTION__, _gid);
    doc = [self->context runCommand:@"documentediting::get",
               @"documentEditingId", [kgid keyValues][0] , nil];
  }
  else if ([entityName isEqualToString:@"DocumentVersion"]) {
    NSLog(@"WARNING[%s]: using genericRecordForGID_cache for DocumentVersion %@",
          __PRETTY_FUNCTION__, _gid);
    doc = [self->context runCommand:@"documentversion::get",
               @"documentVersionId", [kgid keyValues][0] , nil];
  }
  else {
    NSLog(@"ERROR[%s]: unknown gid %@", __PRETTY_FUNCTION__, _gid);
  }
  return doc;
}

- (id)genericRecordForFileName:(NSString *)_path manager:(id)_manager {
  return [self genericRecordForAttrs:[self fileAttributesAtPath:_path
                                           manager:_manager]
               manager:_manager];
}

- (id)genericRecordForAttrs:(NSDictionary *)_attrs manager:(id)_manager {
  NSMutableDictionary *cache;
  id                  doc;
  NSNumber            *key;
  NSString            *entityName;
  EOKeyGlobalID       *gid;
 
  gid        = [_attrs objectForKey:@"globalID"];

  if (!gid)
    return nil;

  key        = [gid keyValues][0];
  entityName = [gid entityName];

  if (![entityName isEqualToString:@"Doc"]) {
    NSLog(@"WARNING[%s]: couldn`t build generic recored for %@",
          __PRETTY_FUNCTION__, _attrs);
    return nil;
  }
  if (![key isNotNull]) {
    NSLog(@"ERROR[%s]: missing key for _attrs %@", __PRETTY_FUNCTION__, _attrs);
    return nil;
  }
  cache = [self pk2GenRecCache];
  if (![doc = [cache objectForKey:key] isNotNull]) {
    NSNumber     *parentKey;
    NSArray      *docs;
    NSEnumerator *enumerator;
    id           tmp;

    parentKey = [_attrs objectForKey:@"SkyParentId"];
    if (!parentKey)
      parentKey = (id)[EONull null];

    docs = [self->context runCommand:@"doc::get",
                @"parentDocumentId", parentKey,
                @"returnType", intObj(LSDBReturnType_ManyObjects),
                @"operator", @"AND",
                @"projectId", [self->project valueForKey:@"projectId"], nil];

    enumerator  = [docs objectEnumerator];
    
    while ((tmp = [enumerator nextObject])) {
      NSNumber *k;

      k = [(id)[tmp globalID] keyValues][0];
      [cache setObject:tmp forKey:k];

      if ([k isEqual:key])
        doc = tmp;
    }
  }
  if ([[doc entityName] isEqualToString:@"Doc"]) {
    
    if ([[doc valueForKey:@"status"] isEqual:@"edited"] &&
        [[_attrs valueForKey:@"SkyOwnerId"]
              isEqual:[[self->context valueForKey:LSAccountKey]
                                      valueForKey:@"companyId"]]) {
      
      /* now take doc edititng */
      id tmp;
    
      tmp = [self->context runCommand:@"documentediting::get",
                 @"documentId", [doc valueForKey:@"documentId"], nil];

      if ([tmp isKindOfClass:[NSArray class]])
        tmp = [tmp lastObject];
      
      if (tmp) {
        [tmp takeValue:doc forKey:@"toDoc"];
        doc = tmp;
        [cache setObject:doc forKey:key];
      }
    }
  }
  if (![doc isNotNull]) {
    NSLog(@"WARNING[%s] got no doc attrs %@", __PRETTY_FUNCTION__, _attrs);
  }
  return doc;
}

/* could be improved, use c-array to store objects for keys ... */

- (NSDictionary *)versionAttrsAtPath:(NSString *)_path
  version:(NSString *)_version manager:(id)_manager
{
  NSEnumerator *enumerator;
  NSDictionary *attrs;

  enumerator = [[self allVersionAttrsAtPath:_path manager:_manager]
                      objectEnumerator]; 
  while ((attrs = [enumerator nextObject])) {
    if ([[attrs objectForKey:@"SkyVersionName"] isEqualToString:_version])
      break;
  }
  return attrs;
}

- (NSArray *)allVersionAttrsAtPath:(NSString *)_path manager:(id)_manager {
  static NSArray  *versionAttrs = nil;
  static NSString *sqlExpr      = nil;
  
  NSArray             *versions;
  NSString            *parentPath, *expression;
  NSDictionary        *attrs, *row;
  NSMutableDictionary *cache;
  NSNumber            *gidNumber;
  NSMutableArray      *result;
  NSEnumerator        *enumerator;
  EOKeyGlobalID       *gid;
  EOEntity            *vEntity;
  EOAdaptorChannel    *channel;

  if ([_path isEqualToString:@"/"]) {
#if DEBUG    
    NSLog(@"WARNING[%s] try to get versions for root folder",
          __PRETTY_FUNCTION__);
#endif    
    return nil;
  }
  gid = (EOKeyGlobalID *)[self gidForPath:_path manager:_manager];
  if (![gid isKindOfClass:[EOKeyGlobalID class]]) {
#if 0    
    NSLog(@"WARNING[%s] missing gid at path", __PRETTY_FUNCTION__, _path);
#endif
    return nil;
  }
  gidNumber = [gid keyValues][0];
  cache     = [self allVersionAttrsAtPathCache];
  
  if ((versions = [cache objectForKey:gidNumber]))
    return versions;
  
  parentPath = [_path stringByDeletingLastPathComponent];
  
  if (!(attrs = [self fileAttributesAtPath:parentPath manager:_manager])) {
#if DEBUG    
    NSLog(@"WARNING[%s] missing fileAttributesAtPath %@", __PRETTY_FUNCTION__,
          parentPath);
#endif    
    return nil;
  }

  if (![[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
#if DEBUG    
    NSLog(@"WARNING[%s] file should be a directory %@", __PRETTY_FUNCTION__,
          attrs);
#endif    
    return nil;
  }
  vEntity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                              entityNamed:@"DocumentVersion"];
  if (!versionAttrs) {
    versionAttrs = [[vEntity attributes] retain];
  }
  if (!sqlExpr) {
    sqlExpr = [[self buildSelectForAllSubVersionsWithAttributes:versionAttrs]
                     retain];
  }
  gid        = [attrs objectForKey:@"globalID"];
  expression = [[NSString alloc] initWithFormat:sqlExpr,[gid keyValues][0]];
  channel    = [self beginTransaction];
  
  if (![channel evaluateExpression:expression]) {
    NSLog(@"ERROR(%s): select failed for expression %@ attrs %@ ",
          __PRETTY_FUNCTION__, expression, versionAttrs);
    [expression release]; expression = nil;
    [self rollbackTransaction];
    return nil;
  }
  [expression release]; expression = nil;

  result = [[NSMutableArray alloc] initWithCapacity:16];
  while ((row = [channel fetchAttributes:versionAttrs withZone:NULL]))
    [result addObject:row];
  
  enumerator = [result objectEnumerator];
  while ((row = [enumerator nextObject])) {
    NSMutableArray *array;
    NSDictionary   *attrs;
    NSNumber       *docId, *pId;
    
    docId = [row objectForKey:@"documentId"];
    if (![docId isNotNull])
      continue;

    if (!(array = [cache objectForKey:docId])) {
      array = [NSMutableArray arrayWithCapacity:16];
      [cache setObject:array forKey:docId];
    }
    pId = [self->project valueForKey:@"projectId"];
    attrs = [SkyProjectFileManager buildFileAttrsForDoc:row
                                   editing:nil atPath:parentPath
                                   isVersion:YES
                                   projectId:pId
                                   fileAttrContext:self];
    [array addObject:attrs]; 
  }
  [result release]; result = nil;
  return [cache objectForKey:gidNumber];
}

@end /* SkyProjectFileManagerCache(Caching) */

@implementation SkyProjectFileManagerCache(Caching_Internals)

- (void)takeCacheValue:(id)_v forKey:(NSString *)_k {
  if (_k == nil) {
    NSLog(@"ERROR[%s] missing key", __PRETTY_FUNCTION__);
    return;
  }
  if (_v == nil)
    _v = [EONull null];
  
  [self->fileManagerCache setObject:_v forKey:_k];
}

- (id)cacheValueForKey:(NSString *)_k {
  if (_k == nil) {
    NSLog(@"ERROR[%s] missing key", __PRETTY_FUNCTION__);
    return nil;
  }
  return [self->fileManagerCache objectForKey:_k];
}

@end /* SkyProjectFileManagerCache(Caching_Internals) */
