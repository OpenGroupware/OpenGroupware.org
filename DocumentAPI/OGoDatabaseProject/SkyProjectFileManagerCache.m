/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

static BOOL     debugSearch = NO;
static NSNumber *yesNum = nil;

+ (void)initialize {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

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
  if ((self = [super init]) != nil) {
    NSString *ctx;
    NSUserDefaults *defaults;
    id              tmp;
    
    if (_context == nil) {
      [self errorWithFormat:@"missing context!"];
      [self release];
      return nil;
    }
    if (_gid == nil) {
      [self errorWithFormat:@"missing project global-id!"];
      [self release];
      return nil;
    }
    
    ctx           = @"context";
    self->context = [_context retain];
    
    defaults = [NSUserDefaults standardUserDefaults];

    tmp = [defaults valueForKey:@"SkyProjectFileManagerUseSessionCache"];
    self->useSessionCache = (tmp != nil) ? [tmp boolValue] : YES;

    tmp = [defaults valueForKey:@"SkyProjectFileManagerFlushTimeout"];
    self->flushTimeout = (tmp == nil) ? 0 : [tmp intValue];

    tmp = [defaults valueForKey:@"SkyProjectFileManagerClickTimeout"];
    self->clickTimeout = (tmp == nil) ? 0 : [tmp intValue];

    tmp = [defaults valueForKey:@"SkyProjectFileManagerCacheTimeout"];
    self->cacheTimeout = (tmp == nil) ? 0 : [tmp intValue];

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
      [self errorWithFormat:@"%s: did not find project for gid: %@", 
	    __PRETTY_FUNCTION__, _gid];
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
    [self warnWithFormat:
	    @"%s: versions for isReadableFileAtPath: are not allowed",
            __PRETTY_FUNCTION__];
    return NO;
  }
  boolResult = NO;
  if ((_path = [_manager _makeAbsolute:_path]) == nil) {
    return [_manager _buildErrorWithSource:_path dest:nil msg:20
                     handler:nil cmd:_cmd];
  }
  
  readCache  = @"_FileManager_isReadableFileAtPath_Cache";
  
  if ((cache = [self cacheValueForKey:readCache]) == nil) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:readCache];
  }
  if ((result = [cache objectForKey:_path]) == nil) {
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
  if ((result = [cache objectForKey:_path]) == nil) {
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
  return [NSString stringWithFormat:@"<%p[%@]: project=%@>",
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
  
  if ((cache = [self cacheValueForKey:readCache]) == nil) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:readCache];
  }

  cacheKey = [[_path stringByAppendingString:@"_"]
                     stringByAppendingString:_op];

  if ((result = [cache objectForKey:cacheKey]) == nil) {
    EOGlobalID *gid;
    
    if ((gid = [self gidForPath:_path manager:_manager]) != nil)
      boolResult = [self->accessManager operation:_op allowedOnObjectID:gid];
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
  if ((_path = [_manager _makeAbsolute:_path]) == nil) {
    // TODO: use a constant for error code 20!
    [_manager _buildErrorWithSource:_path dest:nil msg:20 
              handler:nil cmd:_cmd];
    return nil;
  }

  readCache  = @"_FileManager_filePermissionsAtPath_Cache";
  
  if (!(cache = [self cacheValueForKey:readCache])) {
    cache = [NSMutableDictionary dictionaryWithCapacity:256];
    [self takeCacheValue:cache forKey:readCache];
  }
  if ((result = [cache objectForKey:_path]) == nil) {
    EOGlobalID *gid;
    
    if ((gid = [self gidForPath:_path manager:_manager]) != nil)
      result = [self->accessManager allowedOperationsForObjectId:gid];
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
  NSFileName like 'blub.*'
  NSFileSubject = 'my subject'
  (NSFileName LIKE '*blub*.*') AND (NSFileName LIKE "*.txt") 
  (NSFileName LIKE 'blub.*') OR (NSFileSubject LIKE "my subject")
                             OR (NSFileName LIKE *.t*")
  NSFileType = 'NSFileTypeDirectory'
*/

- (NSArray *)deepSearchChildrenForFolder:(NSString *)_path
  qualifier:(EOQualifier *)_qualifier
  manager:(id)_manager
{
  // called only by searchChildsForFolder:..
  NSMutableArray *children;
  EOQualifier  *qual;
  NSArray      *docs;
  NSDictionary *docEditings;
  NSEnumerator *enumerator;
  id           doc;
  BOOL         evalQual;

  /* preconditions */
  
  if (![_path isEqualToString:@"/"]) {
    [self logWithFormat:
	    @"ERROR(%s): fetch deep only allowed for root path, got: '%@'",
            __PRETTY_FUNCTION__, _path];
    return nil;
  }

  qual = [SkyProjectFileManager convertQualifier:_qualifier
				projectId:
				  [self->project valueForKey:@"projectId"]
				evalInMemory:&evalQual];
  docs        = [self fetchDocsForParentId:nil siblingId:nil qualifier:qual];
  docEditings = [self fetchDocEditingsForParentId:nil siblingId:nil docPKeys:
                        [docs map:@selector(valueForKey:) with:@"documentId"]];

  children    = [NSMutableArray arrayWithCapacity:16];
  enumerator  = [docs objectEnumerator];
  while ((doc = [enumerator nextObject]) != nil) {
    // TODO: can we refactor that?
      NSDictionary  *fileAttrs;
      NSString      *path, *parent;
      EOKeyGlobalID *gid;
      NSNumber      *key;
      id editing;

      if ((key = [(NSDictionary*)doc objectForKey:@"parentDocumentId"]) == nil)
	continue;
      if (![key isNotNull])
        continue;
      
      gid    = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                              keys:&key keyCount:1 zone:NULL];
      parent = [self pathForGID:gid manager:_manager];
      
      editing = [docEditings objectForKey:
			       [(NSDictionary *)doc objectForKey:@"documentId"]];
      fileAttrs = [SkyProjectFileManager 
		    buildFileAttrsForDoc:doc
		    editing:editing
		    atPath:parent isVersion:NO
		    projectId:[self->project valueForKey:@"projectId"]
		    fileAttrContext:self];
      [children addObject:fileAttrs];
      
      gid  = [fileAttrs objectForKey:@"globalID"];
      path = [fileAttrs objectForKey:@"NSFilePath"];

      [[self fileName2GIDCache] setObject:gid forKey:path];
      [[self pk2FileNameCache] setObject:path forKey:[gid keyValues][0]];
      [[self fileAttributesAtPathCache] setObject:fileAttrs forKey:path];
  }
  
  if (evalQual && [_qualifier isNotNull]) {
    children = (id)[children filteredArrayUsingQualifier:_qualifier 
			     context:nil];
  }
  return children;
}

- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier
  manager:(id)_manager
{
  NSArray *children;

  children = nil;
  
  if (debugSearch) 
    [self logWithFormat:@"fm-search: '%@': %@", _path, _qualifier];
  
  if (!_deep) {
    children = [self childAttributesAtPath:_path manager:_manager];
    if (debugSearch)
      [self logWithFormat:@"  flat found %d children.", [children count]];
    
    if (_qualifier != nil) {
      children = [children filteredArrayUsingQualifier:_qualifier context:nil];
      if (debugSearch) {
	[self logWithFormat:@"  filtered out %@ to %d children.", 
	        _qualifier, [children count]];
      }
    }
  }
  else {
    children = [self deepSearchChildrenForFolder:_path 
		     qualifier:_qualifier manager:_manager];
  }

  if (debugSearch) 
    [self logWithFormat:@"=> fm-search found %d children.", [children count]];
  return children;
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

/* returns an login for a person_id */

- (NSDictionary *)_primaryFetchAccountLogin4PersonIdCache {
  NSDictionary *dict;

    static NSArray *personAttrs = nil;

    NSMutableDictionary *mdict;
    EOAdaptorChannel    *channel;
    EOSQLQualifier      *qualifier;
    EOEntity            *entity;
    NSDictionary        *row;
    NSException         *error;
    

    entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                               entityNamed:@"Person"];
    if (!personAttrs) {
      personAttrs = [[NSArray alloc]
                              initWithObjects:
                              [entity attributeNamed:@"companyId"],
                              [entity attributeNamed:@"login"], nil];
    }
    channel = [self beginTransaction];

    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A = %@",
                                          @"isPerson", yesNum, nil];

    error = [channel selectAttributesX:personAttrs
                     describedByQualifier:qualifier fetchOrder:nil lock:NO];
    if (error != nil) {
      [self errorWithFormat:@"[%s]: select failed for qualifier %@ attrs %@: %@",
              __PRETTY_FUNCTION__, qualifier, personAttrs, error];
      [qualifier release]; qualifier = nil;
      [self rollbackTransaction];
      return nil;
    }
    [qualifier release]; qualifier = nil;
    
    mdict = [[NSMutableDictionary alloc] initWithCapacity:255];
    
    while ((row = [channel fetchAttributes:personAttrs withZone:NULL]) != nil) {
      NSString *l;
      NSNumber *cid;

      cid = [row valueForKey:@"companyId"];

      if (![cid isNotNull]) {
        [self errorWithFormat:@"[%s]: missing companyId for account ...",
                __PRETTY_FUNCTION__];
        continue;
      }
      if (![(l = [row valueForKey:@"login"]) isNotNull])
        l = [cid stringValue];
      
      [mdict setObject:l forKey:cid];
    }
    dict = [[mdict copy] autorelease];
    [mdict release]; mdict = nil;
    return dict;
}

- (NSString *)accountLogin4PersonId:(NSNumber *)_personId {
  static NSString *PersonId2LoginCache_key = @"personId2LoginCache";
  NSDictionary *dict;
  NSString     *result;
  
  if ((dict = [self cacheValueForKey:PersonId2LoginCache_key]) == nil) {
    dict = [self _primaryFetchAccountLogin4PersonIdCache];
    [self takeCacheValue:dict forKey:PersonId2LoginCache_key];
  }
  
  if ((result = [dict objectForKey:_personId]) == nil) {
    /* missing login, take key */
    result = [_personId stringValue];
  }
  return result;
}

@end /* SkyProjectFileManagerCache */
