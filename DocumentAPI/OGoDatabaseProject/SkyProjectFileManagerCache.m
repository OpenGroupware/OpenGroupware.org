/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
/// $Id$

#define PROFILE 0

#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include "common.h"

@interface SkyProjectFileManager(Internals)
- (NSString *)_makeAbsolute:(NSString *)_path;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
@end /* SkyProjectFileManager(Internals) */

@interface SkyProjectFileManagerCache(Caching_Internals)
- (void)takeCacheValue:(id)_v forKey:(NSString *)_k;
- (id)cacheValueForKey:(NSString *)_k;
- (NGHashMap *)parent2ChildDirectoriesCache;
- (EOAdaptorChannel *)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
@end /* SkyProjectFileManagerCache(Caching_Internals) */

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
- (NSString *)buildSelectForSiblingSearch:(EOEntity *)_entity
  attrs:(NSArray *)_attrs;
- (NSArray *)fetchDocsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  qualifier:(EOQualifier *)_qual;
- (NSDictionary *)fetchDocEditingsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  docPKeys:(NSArray *)_pkeys;
- (NSString *)accountLogin4PersonId:(NSNumber *)_personId;
- (void)cacheChildsForFolder:(NSString *)_folder
  orSiblingsForId:(NSNumber *)_sid;
- (NSDictionary *)rootFolderAttrs;
- (NSMutableDictionary *)fileAttributesAtPathCache;
@end /* SkyProjectFileManagerCache(Internals) */

@implementation SkyProjectFileManagerCache

+ (id)cacheWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid {
  NSMutableDictionary        *dict  = nil;
  SkyProjectFileManagerCache *cache = nil;
  
  if (_gid == nil)
    return nil;
  
  if ((dict = [_context valueForKey:@"FileManagerCaches"]) == nil) {
    dict = [NSMutableDictionary dictionaryWithCapacity:16];
    [_context takeValue:dict forKey:@"FileManagerCaches"];
  }
  if ((cache = [dict objectForKey:_gid]))
    return cache;
  
  cache = [[SkyProjectFileManagerCache alloc] initWithContext:_context
					      projectGlobalID:_gid];
  if (cache == nil)
    return nil;
  cache = [cache autorelease];
    
  [dict setObject:cache forKey:_gid];
  return cache;
}

- (id)_projectForGID:(EOGlobalID *)_gid {
  id p;
  
  p = [self->context runCommand:@"project::get",
           @"projectId",  [(EOKeyGlobalID *)_gid keyValues][0], nil];
    
  if ([p isKindOfClass:[NSArray class]])
    p = ([p count] == 1) ? [p objectAtIndex:0] : nil;
  
  return p;
}

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid {
  if ((self = [super init])) {
    NSString *ctx;
    NSUserDefaults *defaults;
    id              tmp;
    
    NSAssert(_context, @"missing context ..");
    NSAssert(_gid,     @"missing gid ..");
    
    ctx           = @"context";
    self->context = [_context retain];
      
    defaults = [NSUserDefaults standardUserDefaults];
    tmp      = [defaults valueForKey:@"SkyProjectFileManagerUseSessionCache"];

    self->useSessionCache = (tmp) ? [tmp boolValue] : YES;

    tmp = [defaults valueForKey:@"SkyProjectFileManagerFlushTimeout"];

    self->flushTimeout = (!tmp) ? 0 : [tmp intValue];

    tmp = [defaults valueForKey:@"SkyProjectFileManagerClickTimeout"];

    self->clickTimeout = (!tmp) ? 0 : [tmp intValue];

    tmp = [defaults valueForKey:@"SkyProjectFileManagerCacheTimeout"];

    self->cacheTimeout = (!tmp) ? 0 : [tmp intValue];

    [self initSessionCache];
    [self initClickTimer];
    [self initFlushTimer];

    self->accessManager    = [self->context accessManager];
    self->managerRegister  = 0;
    self->fileManagerCache = [[NSMutableDictionary alloc] initWithCapacity:16];
    self->notifyUserInfo   = 
      [[NSDictionary alloc] initWithObjects:&self->context
			    forKeys:&ctx count:1];
    self->project = [[self _projectForGID:_gid] retain];
    if (self->project == nil) {
      NSLog(@"ERROR[%s] missing project", __PRETTY_FUNCTION__);
      [self release];
      return nil;
    }
    
#if DEBUG
    NSAssert1([self->project isKindOfClass:[EOGenericRecord class]],
              @"ROOT is not a eogeneric-record, but '%@'",
              [self->project class]);
#endif

  }  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->flushTimer invalidate];
  [self->cacheTimer invalidate];
  [self->clickTimer invalidate];
  
  [self->notifyUserInfo   release];
  [self->project          release];
  [self->context          release];
  [self->fileManagerCache release];
  [self->getAttachmentNameCommand release];
  [self->flushTimer release];
  [self->cacheTimer release];
  [self->clickTimer release];
  [super dealloc];
}

/* accessors */

- (id)context {
  return self->context;
}
- (id)project {
  return self->project;
}

- (void)registerManager:(SkyProjectFileManager *)_manager {
  self->managerRegister++;
}

- (void)removeManager:(SkyProjectFileManager *)_manager {
  self->managerRegister--;

  if (self->managerRegister == 0) {
    [self initCacheTimer];
  }
}

- (void)flushWithManager:(SkyProjectFileManager *)_manager {
  [self flush];
}

/* existence */

- (BOOL)isInsertableDirectoryAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  BOOL isDir;
  id                  result;
  BOOL                boolResult;
  NSString            *readCache;
  NSMutableDictionary *cache;

  isDir = NO;
  if ((_path = [_manager _makeAbsolute:_path]) == nil) {
    // TODO: replace code with constant
    return [_manager _buildErrorWithSource:_path dest:nil msg:20
                     handler:nil cmd:_cmd];
  }

  if (![_manager fileExistsAtPath:_path isDirectory:&isDir])
    isDir = NO;
  
  if (!isDir)
    return NO;

  boolResult = NO;
  readCache  = @"_FileManager_isInsertableFileAtPath_Cache";
  
  if ((cache = [self cacheValueForKey:readCache]) == nil) {
      cache = [NSMutableDictionary dictionaryWithCapacity:255];
      [self takeCacheValue:cache forKey:readCache];
  }
  if ((result = [cache objectForKey:_path]) == nil) {
    EOGlobalID *gid;

    if ((gid = [self gidForPath:_path manager:_manager])) {
      boolResult = [self->accessManager operation:@"i" allowedOnObjectID:gid];
    }
    else {
      /* did not found path .. */
      boolResult = NO;
    }
    [cache setObject:[NSNumber numberWithBool:boolResult] forKey:_path];
  }
  else {
    boolResult = [result boolValue];
  }
  isDir = boolResult;
  
  return isDir;
}

- (BOOL)isReadableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  id                  result;
  BOOL                boolResult;
  NSString            *readCache;
  NSMutableDictionary *cache;

  if ([_path pathVersion] != nil) {
    NSLog(@"WARNING[%s]: versions for isReadableFileAtPath: are not allowed",
          __PRETTY_FUNCTION__);
    return NO;
  }
  boolResult = NO;
  if (!(_path = [_manager _makeAbsolute:_path])) {
    return [_manager _buildErrorWithSource:_path dest:nil msg:20
                     handler:nil cmd:_cmd];
  }
  
  readCache  = @"_FileManager_isReadableFileAtPath_Cache";
  
  if (!(cache = [self cacheValueForKey:readCache])) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:readCache];
  }
  if (!(result = [cache objectForKey:_path])) {
    EOGlobalID *gid;

    if ((gid = [self gidForPath:_path manager:_manager])) {
      boolResult = [self->accessManager operation:@"r" allowedOnObjectID:gid];
    }
    else {
      /* did not found path .. */
        boolResult = NO;
    }
    [cache setObject:[NSNumber numberWithBool:boolResult] forKey:_path];
  }
  else {
    boolResult = [result boolValue];
  }
  return boolResult;
}

- (BOOL)isWritableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  id                  status;
  NSMutableDictionary *cache;
  BOOL                boolResult;
  NSNumber            *result;
  NSString            *writeCache;

  boolResult = NO;
  
 if ([_path pathVersion] != nil) {
    NSLog(@"WARNING[%s]: versions for isWritableFileAtPath are not allowed",
          __PRETTY_FUNCTION__);
    return NO;
  }
  boolResult = NO;
  if (!(_path = [_manager _makeAbsolute:_path])) {
    return [_manager _buildErrorWithSource:_path dest:nil msg:20
                     handler:nil cmd:_cmd];
  }
  writeCache = @"_FileManager_isWritableFileAtPath";
  
  if (!(cache = [self cacheValueForKey:writeCache])) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:writeCache];
  }
  if (!(result = [cache objectForKey:_path])) {
    EOGlobalID *gid;

    boolResult = NO;
    if ((gid = [self gidForPath:_path manager:_manager])) {
      if ([self->accessManager operation:@"w" allowedOnObjectID:gid]) {
        NSDictionary *dict;
        
        boolResult = YES;

        dict = [_manager fileAttributesAtPath:_path traverseLink:NO];

        status = [dict valueForKey:@"SkyStatus"];
        
        if (![status isNotNull])
          status = nil;
    
        if ([status isEqualToString:@"edited"]) {
          id a;
          id aid;
      
          a   = [self->context valueForKey:LSAccountKey];
          aid = [a valueForKey:@"companyId"];
      
#if !LIB_FOUNDATION_LIBRARY
          if ([[dict objectForKey:NSFileOwnerAccountID] isEqual:aid] ||
#else
          if ([[dict objectForKey:NSFileOwnerAccountNumber] isEqual:aid] ||
#endif
              ([[a valueForKey:@"companyId"] intValue] == 10000))
            boolResult = YES;
          else
            boolResult = NO;
        }
      }
    }
    [cache setObject:[NSNumber numberWithBool:boolResult] forKey:_path];
  }
  else {
    boolResult = [result boolValue];
  }
  return boolResult;
}

- (BOOL)isUnlockableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  return [self isWritableFileAtPath:_path manager:_manager];
}

- (BOOL)isExecutableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  return NO;
}

- (BOOL)isDeletableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  id                  result;
  BOOL                boolResult;
  NSString            *deleteCache;
  NSMutableDictionary *cache;

  if ([_path pathVersion] != nil) {
    NSLog(@"WARNING[%s]: versions for isDeletableFileAtPath: are not allowed",
          __PRETTY_FUNCTION__);
    return NO;
  }
  boolResult  = NO;
  if (!(_path = [_manager _makeAbsolute:_path])) {
    return [_manager _buildErrorWithSource:_path dest:nil msg:20
                     handler:nil cmd:_cmd];
  }

  if ([_path isEqualToString:@"/"])
    return NO;
  
  deleteCache = @"_FileManager_isDeletableFileAtPath_Cache";
  
  if (!(cache = [self cacheValueForKey:deleteCache])) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:deleteCache];
  }
  if (!(result = [cache objectForKey:_path])) {
    NSDictionary *attrs;
    EOGlobalID   *gid;
    
    boolResult = NO;
    attrs      = [_manager fileAttributesAtPath:_path traverseLink:NO];
    gid        = [attrs objectForKey:@"globalID"];

    if ([[attrs valueForKey:@"SkyStatus"] isEqualToString:@"edited"]) {
      id a;
      id aid;
      
      a   = [self->context valueForKey:LSAccountKey];
      aid = [a valueForKey:@"companyId"];
      
#if !LIB_FOUNDATION_LIBRARY
      if ([[attrs objectForKey:NSFileOwnerAccountID] isEqual:aid] ||
#else
      if ([[attrs objectForKey:NSFileOwnerAccountNumber] isEqual:aid] ||
#endif
          ([[a valueForKey:@"companyId"] intValue] == 10000))
        boolResult = YES;
      else
        boolResult = NO;
    }
    else {
      if ((gid = [self gidForPath:_path manager:_manager])) {
        boolResult = [self->accessManager operation:@"w" allowedOnObjectID:gid];
      
        if (boolResult) {
          _path = [_path stringByDeletingLastPathComponent];
          boolResult = NO;
        
          if ((gid = [self gidForPath:_path manager:_manager]))
            boolResult = [self->accessManager operation:@"d"
                              allowedOnObjectID:gid];
        }
      }
    }
    [cache setObject:[NSNumber numberWithBool:boolResult] forKey:_path];
  }
  else {
    boolResult = [result boolValue];
  }
  return boolResult;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%08X[%@]: project=%@>",
                     self, NSStringFromClass([self class]),
                     [self->project valueForKey:@"projectId"]];
}


- (BOOL)isOperation:(NSString *)_op allowedOnPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  id                  result;
  BOOL                boolResult;
  NSString            *readCache, *cacheKey;
  NSMutableDictionary *cache;
  
  if ([_path pathVersion] != nil) {
    NSLog(@"WARNING[%s]: versions for isReadableFileAtPath: are not allowed",
          __PRETTY_FUNCTION__);
    return NO;
  }
  boolResult = NO;
  if (!(_path = [_manager _makeAbsolute:_path])) {
    return [_manager _buildErrorWithSource:_path dest:nil msg:20
                     handler:nil cmd:_cmd];
  }
  readCache  = @"_FileManager_isOperationAllowed_Cache";
  
  if (!(cache = [self cacheValueForKey:readCache])) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:readCache];
  }

  cacheKey = [[_path stringByAppendingString:@"_"]
                     stringByAppendingString:_op];

  if (!(result = [cache objectForKey:cacheKey])) {
    EOGlobalID *gid;
    
    if ((gid = [self gidForPath:_path manager:_manager])) {
      boolResult = [self->accessManager operation:_op allowedOnObjectID:gid];
    }
    else 
      boolResult = NO;

    [cache setObject:[NSNumber numberWithBool:boolResult] forKey:cacheKey];
  }
  else {
    boolResult = [result boolValue];
  }
  return boolResult;
}

- (NSString *)filePermissionsAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager
{
  id                  result;
  NSString            *readCache;
  NSMutableDictionary *cache;
  
  if ([_path pathVersion] != nil) {
    NSLog(@"WARNING[%s]: versions for isReadableFileAtPath: are not allowed",
          __PRETTY_FUNCTION__);
    return NO;
  }
  if (!(_path = [_manager _makeAbsolute:_path])) {
    [_manager _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }

  readCache  = @"_FileManager_filePermissionsAtPath_Cache";
  
  if (!(cache = [self cacheValueForKey:readCache])) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:readCache];
  }
  if (!(result = [cache objectForKey:_path])) {
    EOGlobalID *gid;
    
    if ((gid = [self gidForPath:_path manager:_manager])) {
      result = [self->accessManager allowedOperationsForObjectId:gid];
    }
    else
      result = @"";

    [cache setObject:result forKey:_path];
  }
  return result;
}

- (BOOL)folder:(NSString *)_folder hasSubFolder:(NSString *)_subFolder
  manager:(SkyProjectFileManager *)_manager
{
  NGHashMap *map;

  map = [self parent2ChildDirectoriesCache];

  return [[map objectsForKey:_folder] containsObject:_subFolder];
}

/*
  qualifer to evalutate in database has to be like:
  NSFileName like 'doof.*'
  NSFileSubject = 'my subject'
  (NSFileName like '*doof*.*') AND (NSFileName like "*.txt") 
  (NSFileName like 'doof.*') OR (NSFileSubject like "my subject")
                             OR (NSFileName like *.t*")
  NSFileType = 'NSFileTypeDirectory'
*/

- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier
  manager:(id)_manager
{
  NSArray *childs;

  childs = nil;

  if (!_deep) {
    childs = [self childAttributesAtPath:_path manager:_manager];

    if (_qualifier)
      childs = [childs filteredArrayUsingQualifier:_qualifier context:nil];
  }
  else if ([_path isEqualToString:@"/"]) {
    EOQualifier  *qual;
    NSArray      *docs;
    NSDictionary *docEditings;
    NSEnumerator *enumerator;
    id           doc;
    BOOL         evalQual;

    qual        =
      [SkyProjectFileManager convertQualifier:_qualifier
                             projectId:[self->project valueForKey:@"projectId"]
                             evalInMemory:&evalQual];
    docs        = [self fetchDocsForParentId:nil siblingId:nil qualifier:qual];
    docEditings = [self fetchDocEditingsForParentId:nil siblingId:nil docPKeys:
                        [docs map:@selector(valueForKey:) with:@"documentId"]];
    childs      = [NSMutableArray arrayWithCapacity:16];
    enumerator  = [docs objectEnumerator];

    while ((doc = [enumerator nextObject])) {
      NSDictionary  *fileAttrs;
      NSString      *path, *parent;
      EOKeyGlobalID *gid;
      NSNumber      *key;

      key    = [doc objectForKey:@"parentDocumentId"];

      if (![key isNotNull])
        continue;

      gid    = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                              keys:&key keyCount:1 zone:NULL];
      parent = [self pathForGID:gid manager:_manager];
      
      fileAttrs = [SkyProjectFileManager buildFileAttrsForDoc:doc
                        editing:[docEditings objectForKey:
                                             [doc objectForKey:@"documentId"]]
                        atPath:parent isVersion:NO
                                         projectId:[self->project
                                                     valueForKey:@"projectId"]
                                         fileAttrContext:self];
      [(NSMutableArray *)childs addObject:fileAttrs];
      
      gid  = [fileAttrs objectForKey:@"globalID"];
      path = [fileAttrs objectForKey:@"NSFilePath"];

      [[self fileName2GIDCache] setObject:gid forKey:path];
      [[self pk2FileNameCache] setObject:path forKey:[gid keyValues][0]];
      [[self fileAttributesAtPathCache] setObject:fileAttrs forKey:path];
    }
    if (evalQual) {
      if ([_qualifier isNotNull])
        childs = [childs filteredArrayUsingQualifier:_qualifier context:nil];
    }
  }
  else {
    [self logWithFormat:
	    @"ERROR(%s): fetch deep only allowed for root path, using %@",
            __PRETTY_FUNCTION__, _path];
    return nil;
  }
  return childs;
}

/* accessors */

- (LSCommandContext *)commandContext {
  return self->context;
}

- (void)setGetAttachmentNameCommand:(id)_c {
  ASSIGN(self->getAttachmentNameCommand, _c);
}
- (id)getAttachmentNameCommand {
  return self->getAttachmentNameCommand;
}

@end /* SkyProjectFileManagerCache */
