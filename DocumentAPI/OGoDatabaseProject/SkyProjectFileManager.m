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

#include "SkyProjectFileManager.h"

#include <GDLAccess/GDLAccess.h>
#include <EOControl/EOControl.h>
#include <LSFoundation/SkyObjectPropertyManager.h>
#include <LSFoundation/SkyAccessManager.h>
#include "common.h"
#include "SkyProjectFolderDataSource.h"
#include "SkyProjectFileManagerCache.h"
#include "SkyProjectDocument.h"
#include <OGoProject/SkyProjectDataSource.h>
#include <OGoProject/NSString+XMLNamespaces.h>
#include <OGoProject/SkyContentHandler.h>
#include <OGoProject/OGoFileManagerFactory.h>

// UI !!! #include <LSWFoundation/LSWNotifications.h>
NSString *SkyProjectFM_MoveFailedAtPaths = @"SkyProjectFM_MoveFailedAtPaths";

static NSDictionary *er_dict(int _i) {
  return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_i]
                       forKey:@"errorNumber"];
}

static NSData   *emptyData = nil;
static NSNumber *yesNum = nil, *noNum = nil;
static inline NSNumber *boolNum(BOOL value) {
  if (value) {
    if (yesNum == nil)
      yesNum = [[NSNumber numberWithBool:YES] retain];
    return yesNum;
  }
  else {
    if (noNum == nil)
      noNum = [[NSNumber numberWithBool:NO] retain];
    return noNum;
  }
}

@interface NSObject(Private)
- (EOGlobalID *)globalID;
- (void)fileManager:(id)_fm moveFailedForFile:(NSString *)_file code:(int)_code;
@end /* NSObject(Private) */

@interface SkyProjectFileManager(ErrorHandling_Internals)
- (void)_initializeErrorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel doFlush:(BOOL)_cache
  doRollback:(BOOL)_doRollback;
@end /* SkyProjectFileManager(ErrorHandling+Internals) */

@interface SkyProjectFileManager(Removing)
- (BOOL)_removeFileAttrs:(NSArray *)_paths handler:(id)_handler
  failed:(BOOL*)failed_;
- (BOOL)_removeFiles:(NSArray *)_fileAttrs handler:(id)_handler
  failed:(BOOL*)failed_;
- (BOOL)_removeDirs:(NSArray *)_dirAttr handler:(id)_handler failed:(BOOL*)failed_;
@end

@interface SkyProjectFileManager(Internals)

- (void)_checkCWDFor:(NSString *)_source;
- (id)_project;
- (NSString *)_defaultCompleteProjectDocumentNamespace;
- (NSArray *)subDirectoryNamesForPath:(NSString *)_path;
- (NSString *)_makeAbsolute:(NSString *)_path;
- (void)_subpathsAtPath:(NSString *)_path array:(NSMutableArray *)_array;
- (BOOL)_copyPath:(NSString*)_src toPath:(NSString*)_dest handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush;

- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path flush:(BOOL)_doFlush;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
  handler:(id)_handler;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush;

@end /* SkyProjectFileManager(Internals) */

@implementation SkyProjectFileManager

+ (int)version {
  return [super version] + 0 /* v0 */;
}
+ (void)initialize {
  NSAssert2([super version] == 0,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (yesNum    == nil) yesNum    = [[NSNumber numberWithBool:YES] retain];
  if (noNum     == nil) noNum     = [[NSNumber numberWithBool:NO] retain];
  if (emptyData == nil) emptyData = [[NSData alloc] init];
}

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid {
  SkyProjectFileManagerCache *fmCache;

  /* check license */

  fmCache = [SkyProjectFileManagerCache cacheWithContext:_context
                                       projectGlobalID:_gid];

  return [self initWithFileManagerCache:fmCache];
}

- (EOGlobalID *)_fetchGlobalIDForProjectCode:(NSString *)_code
  inContext:(id)_ctx
{
  EOFetchSpecification *fspec;
  EOQualifier          *q;
  SkyProjectDataSource *pds;
  id         project;
  EOGlobalID *pgid;

  if (_code == nil || _ctx == nil)
    return nil;
  
  q = [EOQualifier qualifierWithQualifierFormat:@"number=%@", _code];
  if (q == nil)
    return nil;
  
  fspec = [[EOFetchSpecification alloc]
                                 initWithEntityName:nil
                                 qualifier:q
                                 sortOrderings:nil
                                 usesDistinct:YES isDeep:NO hints:nil];
  
  pds = [SkyProjectDataSource alloc]; /* keep gcc happy */
  pds = [[pds initWithContext:_ctx] autorelease];
  
  [pds setFetchSpecification:fspec];
  [fspec release]; fspec = nil;
  project = [[pds fetchObjects] lastObject];
  
  pgid = [project valueForKey:@"globalID"];
  return [pgid isNotNull] ? pgid : (EOGlobalID *)nil;
}

- (id)initWithContext:(id)_context projectCode:(NSString *)_code {
  EOGlobalID *pgid;
  
  if (_code == nil || _context == nil) {
    [self logWithFormat:@"ERROR: missing context or project code"];
    [self release];
    return nil;
  }
  
  pgid = [self _fetchGlobalIDForProjectCode:_code inContext:_context];
  return [self initWithContext:_context projectGlobalID:pgid];
}

- (id)initWithFileManagerCache:(SkyProjectFileManagerCache *)_cache {
  if (!_cache) {
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->errorUserInfo = [[NSMutableDictionary alloc] initWithCapacity:64];
    self->cache = [_cache retain];
    [self->cache registerManager:self];
  }
  return self;
}  

- (void)dealloc {
  [self->cache removeManager:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->errorUserInfo  release];
  [self->cache          release];
  [self->notifyPathName release];
  [super dealloc];
}

/* current directory */

- (BOOL)changeCurrentDirectoryPath:(NSString *)_path {
  BOOL isDir;
  
  if (!_path)
    return NO;

  if ([_path pathVersion] != nil) {
    return [self _buildErrorWithSource:_path dest:nil msg:36 handler:nil
                 cmd:_cmd];
  }
  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if (![self fileExistsAtPath:_path isDirectory:&isDir])
    return NO;
  
  if (!isDir) {
    /* path is not a directory */
    return [self _buildErrorWithSource:_path dest:nil msg:27 handler:nil
                 cmd:_cmd];
  }
  ASSIGNCOPY(self->cwd, _path);
  return YES;
}

- (NSString *)currentDirectoryPath {
  return self->cwd;
}

/* existence */

- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL *)_flag {
  NSString *version;
  NSString *orig    = _path;

  if ([_path isEqual:@"/"]) {
    if (_flag) *_flag = YES;
    return YES;
  }
  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if ((version = [_path pathVersion])) {
    if (_flag) *_flag = NO;
    return [[self versionsAtPath:[_path stringByDeletingPathVersion]]
                  containsObject:version];
  }
  { /* take a look in the cache */
    NSString  *dir, *fileName;

    dir      = [_path stringByDeletingLastPathComponent];
    fileName = [_path lastPathComponent];

    if ([self->cache folder:dir hasSubFolder:fileName manager:self]) {
      if (_flag) *_flag = YES;
      return YES;
    }
    else if ([orig hasSuffix:@"/"]) {
      // NO Directory but '/' at end isn't valid
      if (_flag) *_flag = NO;
      return NO;
    }
  }
  if (!_flag) {
    if ([self globalIDForPath:_path])
      return YES;
  }
  else {
    NSDictionary *attrs;

    if ((attrs = [self fileAttributesAtPath:_path traverseLink:NO])) {
      *_flag = [[attrs objectForKey:NSFileType]
                       isEqualToString:NSFileTypeDirectory];
      return YES;
    }
  }
  self->lastErrorCode = 34; // TODO: USE A #define or enum!
  return NO;
}

- (BOOL)fileExistsAtPath:(NSString *)_path {
  return [self fileExistsAtPath:_path isDirectory:NULL];
}
- (BOOL)isReadableFileAtPath:(NSString *)_path {
  return [self->cache isReadableFileAtPath:[_path stringByDeletingPathVersion]
              manager:self];
}
- (BOOL)isWritableFileAtPath:(NSString *)_path {
  return [self->cache isWritableFileAtPath:[_path stringByDeletingPathVersion]
              manager:self];
}
- (BOOL)isExecutableFileAtPath:(NSString *)_path {
  return [self->cache isExecutableFileAtPath:
              [_path stringByDeletingPathVersion]
              manager:self];
}
- (BOOL)isDeletableFileAtPath:(NSString *)_path {
  return [self->cache isDeletableFileAtPath:
              [_path stringByDeletingPathVersion] manager:self];
}
- (BOOL)isInsertableDirectoryAtPath:(NSString *)_path {
  return [self->cache isInsertableDirectoryAtPath:
              [_path stringByDeletingPathVersion] manager:self];
}
- (BOOL)isMoveableFileAtPath:(NSString *)_path {
  return [self isOperation:@"d" allowedOnPath:
               [_path stringByDeletingPathVersion]];
}

/* generic stuff */

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_followLink
{
  NSString     *version;
  NSDictionary *attrs;
  NSDictionary *lnkAttr;
  NSString     *str, *path;

  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }

  /* check whether _path contains a version-spec (eg filename;2) */
  
  if ((version = [_path pathVersion]) != nil) {
    return [self fileAttributesAtPath:[_path stringByDeletingPathVersion]
                 traverseLink:_followLink version:version];
  }
  attrs = [self->cache fileAttributesAtPath:_path manager:self];
  if (!_followLink)
    return attrs;
  
  /* resolve link target */
  
  if (![[attrs objectForKey:NSFileType]
	       isEqualToString:NSFileTypeSymbolicLink]) return attrs;

  str  = [attrs objectForKey:@"SkyLinkTarget"];
  if ([str length] == 0) {
    [self logWithFormat:
	    @"WARNING(%s): couldn`t traverse link, missing link target",
	    __PRETTY_FUNCTION__];
    return attrs;
  }
  
  path = nil;
  if (isdigit([str characterAtIndex:0])) {
    EOGlobalID *targId;

    targId = [[[self context] typeManager] globalIDForPrimaryKey:str];
    path   = [self pathForGlobalID:targId];
  }
  if (![path isNotNull])
    path = str;
  
  if ((lnkAttr = [self->cache fileAttributesAtPath:path manager:self]))
    attrs = lnkAttr;
  
  return attrs;
}

- (BOOL)contentsEqualAtPath:(NSString *)_path1 andPath:(NSString *)_path2 {
  NSDictionary *doc1, *doc2;
  BOOL         isFolder, isLink;

  _path1 = [self _makeAbsolute:_path1];
  _path2 = [self _makeAbsolute:_path2];

  if (!_path1 || !_path2)
    return NO;
  
  if (!(doc1 = [self fileAttributesAtPath:_path1 traverseLink:NO]))
    return NO;

  if (!(doc2 = [self fileAttributesAtPath:_path2 traverseLink:NO]))
    return NO;

  {
    NSString *ft;

    ft = [doc1 objectForKey:NSFileType];

    if (![ft isEqual:[doc2 objectForKey:NSFileType]])
      return NO;
    
    isLink = NO;

    if (!(isFolder = [ft isEqualToString:NSFileTypeDirectory]))
      if (!(isLink = [ft isEqualToString:NSFileTypeSymbolicLink]))
        return YES;
  }
  if (isLink) {
    NSString *c1, *c2;

    c1 = [self pathContentOfSymbolicLinkAtPath:_path1];
    c2 = [self pathContentOfSymbolicLinkAtPath:_path2];
    
    return [c1 isEqualToString:c2];
  }
  else if (isFolder) {
    NSArray *c1, *c2;

    c1 = [self subpathsAtPath:_path1];
    c2 = [self subpathsAtPath:_path2];
    
    return [c1 isEqualToArray:c2];
  }
  else {
    NSData *d1, *d2;
    
    d1 = [self contentsAtPath:_path1];
    d2 = [self contentsAtPath:_path2];
    return [d1 isEqualToData:d2];
  }
  return NO;
}

/* files */

- (NSData *)contentsAtPath:(NSString *)_path {
  NSDictionary *dict;
  NSString     *version, *ft;

  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  
  if ((version = [_path pathVersion]) != nil) {
    return [self contentsAtPath:[_path stringByDeletingPathVersion]
                 version:version];
  }
  if (!(dict = [self fileAttributesAtPath:_path traverseLink:NO])) {
    return nil;
  }
  ft = [dict objectForKey:NSFileType];
  
  if ([ft isEqualToString:NSFileTypeDirectory] ||
      [ft isEqualToString:NSFileTypeSymbolicLink]) {
    [self _buildErrorWithSource:_path dest:nil msg:30 handler:nil
          cmd:_cmd];
    return nil;
  }

  if (![self isReadableFileAtPath:_path]) {
    [self _buildErrorWithSource:_path dest:nil msg:29 handler:nil
          cmd:_cmd];
    return nil;
  }
  {
    NSString *blobName;
    if ((blobName = [dict objectForKey:@"SkyBlobPath"]))
      return [NSData dataWithContentsOfMappedFile:blobName];
  }
  return nil;
}

- (BOOL)movePath:(NSString *)_source toPath:(NSString *)_dest
  handler:(id)_handler
{
  EOGenericRecord *srcGenRec, *desGenRec;
  NSDictionary    *srcAttrs;
  NSString        *name, *ext, *destDir;
  BOOL            srcIsDir, result;

  if (!(_source = [self _makeAbsolute:_source]))
    return [self _buildErrorWithSource:_source dest:_dest msg:4
                 handler:_handler cmd:_cmd];
    
  if (!(_dest   = [self _makeAbsolute:_dest]))
    return [self _buildErrorWithSource:_source dest:_dest msg:5
                 handler:_handler cmd:_cmd];

  /* check move path */

  if ([_source pathVersion] || [_dest pathVersion]) {
    return [self _buildErrorWithSource:_source dest:_dest
                 msg:1 handler:_handler cmd:_cmd];
  }
  if ([_source isEqualToString:@"/"]) {
    return [self _buildErrorWithSource:_source dest:_dest
                 msg:2 handler:_handler cmd:_cmd];
  }
  if ([[[_dest stringByDeletingLastPathComponent] stringByAppendingString:@"/"]
               hasPrefix:[_source stringByAppendingString:@"/"]])
    return [self _buildErrorWithSource:_source dest:_dest msg:3
                 handler:_handler cmd:_cmd];

  srcIsDir = NO;
  if (![self fileExistsAtPath:_source isDirectory:&srcIsDir])
    return [self _buildErrorWithSource:_source dest:_dest msg:6
                 handler:_handler cmd:_cmd];

  if ([self fileExistsAtPath:_dest isDirectory:NULL]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:7
                 handler:_handler cmd:_cmd];
  }
  /* check access */
  if (![self isMoveableFileAtPath:_source]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:9
                 handler:_handler cmd:_cmd];
  } 
 
  srcAttrs = [self fileAttributesAtPath:_source traverseLink:NO];
  {
    NSString *status;

    status = [srcAttrs objectForKey:@"SkyStatus"];

    if ([status isEqual:@"edited"]) {
      id a, aid;

      a   = [[self context] valueForKey:LSAccountKey];
      aid = [a valueForKey:@"companyId"];

      if (![[srcAttrs objectForKey:@"SkyOwnerId"] isEqual:aid] &&
          ([aid intValue] != 10000))
        return [self _buildErrorWithSource:_source dest:_dest msg:10
                     handler:_handler cmd:_cmd];
    }
  }
  destDir = [_dest stringByDeletingLastPathComponent];

  if (![self isInsertableDirectoryAtPath:destDir]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:11
                 handler:_handler cmd:_cmd];
  }
  srcGenRec = [self->cache genericRecordForAttrs:srcAttrs manager:self];
  desGenRec = [self->cache genericRecordForFileName:destDir manager:self];

  if (!srcGenRec || !desGenRec) {
      return [self _buildErrorWithSource:nil dest:nil msg:20 handler:_handler
                   cmd:_cmd];
  }
  if ([self fileExistsAtPath:_dest isDirectory:NULL]) {
    return [self _buildErrorWithSource:[srcAttrs objectForKey:NSFilePath]
                 dest:_dest msg:7 handler:_handler cmd:_cmd];
  }
  
  name      = [_dest lastPathComponent];
  ext       = [name pathExtension];
  name      = [name stringByDeletingPathExtension];

  if ([[srcGenRec valueForKey:@"isObjectLink"] boolValue]) {
    result = [self moveLink:srcGenRec toPath:desGenRec name:name
                   extension:ext handler:_handler];
  }
  else if (srcIsDir) {
    result = [self moveDir:srcGenRec toPath:desGenRec name:name
                   extension:ext handler:_handler];
  }
  else {
    result = [self moveFile:srcGenRec toPath:desGenRec name:name
                   extension:ext handler:_handler];
  }
  if (!result) {
    return NO;
  }
  [self postChangeNotificationForPath:
	  [_source stringByDeletingLastPathComponent]];
  [self postChangeNotificationForPath:
	  [_dest stringByDeletingLastPathComponent]];
  [self _checkCWDFor:_source];
  return YES;
}


- (BOOL)removeFilesAtPaths:(NSArray *)_paths handler:(id)_handler {
  BOOL           result;
  NSMutableArray *attrs;
  NSEnumerator   *enumerator;
  NSString       *path;

  enumerator = [_paths objectEnumerator];
  attrs      = [NSMutableArray arrayWithCapacity:[_paths count]];
  while ((path = [enumerator nextObject])) {
    NSDictionary *attr;

    if ((attr = [self fileAttributesAtPath:path traverseLink:NO])) {
      [attrs addObject:attr];
    }
  }
  result = [self _removeFileAttrs:attrs handler:_handler failed:NULL];

  [self flush];
  return result;
}

- (BOOL)removeFileAtPath:(NSString *)_path handler:(id)_handler {
  if ([_path length] == 0)
    return NO;
  
  return [self removeFilesAtPaths:[NSArray arrayWithObject:_path] 
	       handler:_handler];
}

/* like movePaths: ... */

- (BOOL)fileManager:(NSFileManager *)_fm
  shouldProceedAfterError:(NSDictionary *)_err
{
  return YES;
}

- (BOOL)trashFilesAtPaths:(NSArray *)_paths handler:(id)_handler {
  NSString *trash;
  BOOL     isDir;

  if ([_paths count] == 0)
    return YES;
  
  if (![self supportsTrashFolderAtPath:[_paths lastObject]])
    return NO;
  
  if ([(trash = [self trashFolderForPath:[_paths lastObject]]) length] == 0)
    return NO;
  
  if ([(NSString *)[_paths lastObject] hasPrefix:trash])
    /* path already is in trash ... */
    return YES;
  
  /* ensure that the trash folder is existent */

  if ([self fileExistsAtPath:trash isDirectory:&isDir]) {
    if (!isDir) {
      NSLog(@"%s: '%@' exists, but isn't a folder !", __PRETTY_FUNCTION__,
            trash);
      return NO;
    }
  }
  else { /* trash doesn't exist yet */
    if (![self createDirectoryAtPath:trash attributes:nil]) {
      NSLog(@"%s: couldn't create trash folder '%@' !", __PRETTY_FUNCTION__,
            trash);
      return NO;
    }
  }
  if (![self movePaths:_paths toPath:trash handler:self]) {
    NSEnumerator   *enumerator;
    NSString       *str;

    _paths     = [self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths];
    [[_paths retain] autorelease];
    
    enumerator = [_paths objectEnumerator];

    [self->errorUserInfo setObject:[NSMutableArray array]
         forKey:SkyProjectFM_MoveFailedAtPaths];
             
    while ((str = [enumerator nextObject])) {
      NSString *s = nil;
      
      s = [trash stringByAppendingPathComponent:[s lastPathComponent]];

      while ([self fileExistsAtPath:s]) {
        s = [@"$" stringByAppendingString:s];
      }
      if (![self movePath:str toPath:[trash stringByAppendingPathComponent:s]
                 handler:_handler]) {
        [self->errorUserInfo setObject:[NSArray arrayWithObject:str]
             forKey:SkyProjectFM_MoveFailedAtPaths];
        [self flush];
        return NO;
      }
      
    }
  }
  return YES;
}

- (BOOL)trashFilesAtPath:(NSArray *)_paths handler:(id)_handler {
  return [self trashFilesAtPaths:_paths handler:_handler];
}


/**
   move files/directories from _path to _dest. _dest is an existing path
   Supported handler methods:
   currently supports only files with one directory
   in errorUserInfo objectForKey:@"failedFile" -->list of failed files
*/

- (BOOL)movePaths:(NSArray *)_filePaths toPath:(NSString *)_dest 
  handler:(id)_handler
{
  /* TODO: split up this huge method! */
  EOGenericRecord *srcGenRec, *desGenRec;
  NSString        *name, *ext;
  BOOL            isDir, result;
  id              handler;
  NSString        *_source;
  NSMutableArray  *_files;

  [self->errorUserInfo setObject:[NSMutableArray array]
       forKey:SkyProjectFM_MoveFailedAtPaths];

  handler = nil;

  if (![_filePaths count])
    return YES;
  
  if ([_handler respondsToSelector:
                @selector(fileManager:shouldProceedAfterError:)]) {
    handler = _handler;
  }

  _source = nil;
  { /* check whether files in one directory */
    NSEnumerator *enumerator;
    NSString     *p;

    _files  = [NSMutableArray arrayWithCapacity:[_filePaths count]];

    enumerator = [_filePaths objectEnumerator];

    while ((p = [enumerator nextObject])) {
      NSString *t;
      if (!(t = [self _makeAbsolute:p])) {
        return [self _buildErrorWithSource:p dest:_dest msg:4
                     handler:_handler cmd:_cmd];
      }
      if ([t pathVersion]) {
        return [self _buildErrorWithSource:p dest:_dest
                     msg:1 handler:_handler cmd:_cmd];
      }
      if (!_source) {
        _source = [t stringByDeletingLastPathComponent];

        if (![_source length]) {
          return [self _buildErrorWithSource:p dest:_dest msg:4
                       handler:_handler cmd:_cmd];
        }
        [_files addObject:[t lastPathComponent]];
      }
      else {
        if (![[t stringByDeletingLastPathComponent] isEqualToString:_source]) {
          return [self _buildErrorWithSource:p dest:_dest msg:4
                       handler:_handler cmd:_cmd];
        }
        [_files addObject:[t lastPathComponent]];
      }
    }
  }
  result = YES;

  [self flush];
  
  if (!(_dest   = [self _makeAbsolute:_dest]))
    return [self _buildErrorWithSource:_source dest:_dest msg:5
                 handler:_handler cmd:_cmd];

  /* check move path */

  if ([_dest pathVersion]) {
    return [self _buildErrorWithSource:_source dest:_dest
                 msg:1 handler:_handler cmd:_cmd];
  }
  isDir = NO;
  if (![self fileExistsAtPath:_source isDirectory:&isDir])
    return [self _buildErrorWithSource:_source dest:_dest msg:6
                 handler:_handler cmd:_cmd];
  if (!isDir)
    return [self _buildErrorWithSource:_source dest:_dest msg:58
                 handler:_handler cmd:_cmd];

  if (![self fileExistsAtPath:_dest isDirectory:&isDir]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:5
                 handler:_handler cmd:_cmd];
  }
  if (!isDir)
    return [self _buildErrorWithSource:_source dest:_dest msg:59
                 handler:_handler cmd:_cmd];

  if (![self isInsertableDirectoryAtPath:_dest]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:11
                 handler:_handler cmd:_cmd];
  }
  desGenRec = [self->cache genericRecordForFileName:_dest manager:self];

  if (!desGenRec) {
    return [self _buildErrorWithSource:nil dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  {
    NSMutableDictionary *attributes;
    NSEnumerator        *enumerator;
    NSString            *fName;
    NSArray             *gids;
    EOGlobalID          *gid;

    attributes = [NSMutableDictionary dictionaryWithCapacity:[_files count] + 1];
    enumerator = [_files objectEnumerator];
    
    while ((fName = [enumerator nextObject])) {
      NSDictionary *dict;

      dict = [self fileAttributesAtPath:
                   [_source stringByAppendingPathComponent:fName] traverseLink:NO];
      if ([dict isNotNull]) {
        if ([[dict valueForKey:@"SkyStatus"] isEqualToString:@"edited"]) {
          id aid;

          aid = [[[self context] valueForKey:LSAccountKey] valueForKey:@"companyId"];

          if (![[dict valueForKey:@"SkyOwnerId"] isEqual:aid] &&
              ([aid intValue] != 10000)) {
            result = [self _buildErrorWithSource:_source dest:_dest msg:10
                           handler:_handler cmd:_cmd doFlush:NO doRollback:NO];

            [[self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths]
                                  addObject:[dict valueForKey:NSFilePath]];

            if (![handler fileManager:(id)self shouldProceedAfterError:er_dict(10)])
              return NO;

            continue;
          }
        }
        if ([self fileExistsAtPath:[_dest stringByAppendingPathComponent:
                                          [dict objectForKey:NSFileName]]
                  isDirectory:NULL]) {
          result = [self _buildErrorWithSource:[dict objectForKey:NSFilePath]
                         dest:_dest msg:7 handler:nil
                         cmd:_cmd doFlush:NO doRollback:NO];

          [[self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths]
                                addObject:[dict objectForKey:NSFilePath]];

          if (![handler fileManager:(id)self shouldProceedAfterError:er_dict(7)])
            return NO;

          continue;
        }
        [attributes setObject:dict forKey:[dict objectForKey:@"globalID"]];
      }
    }
    gids = [attributes allKeys];
    
    gids = [[[self context] accessManager] objects:gids forOperation:@"d"];
    if ([gids count] != [attributes count]) {
      result = [self _buildErrorWithSource:_source dest:_source msg:12
                     handler:_handler cmd:_cmd doFlush:NO doRollback:NO];
      {
        NSEnumerator *attrEnum;
        id           obj;

        attrEnum = [attributes keyEnumerator];

        while ((obj = [attrEnum nextObject])) {
          if (![gids containsObject:obj]) {
            [[self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths]
                                  addObject:[[attributes objectForKey:obj]
                                                         valueForKey:NSFilePath]];
            if (![handler fileManager:(id)self shouldProceedAfterError:er_dict(12)])
              return NO;
          }
        }
      }
    }
    enumerator = [gids objectEnumerator];

    while ((gid = [enumerator nextObject])) {
      NSDictionary *attr;
      NSString     *ft;
      BOOL         b;
      
      attr = [attributes objectForKey:gid];
        
      srcGenRec = [self->cache genericRecordForAttrs:attr manager:self];
      if (!srcGenRec) {
        result = [self _buildErrorWithSource:[attr objectForKey:NSFilePath]
                       dest:_dest msg:20 handler:_handler
                       cmd:_cmd doFlush:NO doRollback:NO];
        [[self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths]
                              addObject:[attr objectForKey:NSFilePath]];

        if (![handler fileManager:(id)self shouldProceedAfterError:er_dict(20)])
          return NO;

        continue;
      }
      name = [attr objectForKey:NSFileName];
      ext  = [name pathExtension];
      name = [name stringByDeletingPathExtension];

      ft = [attr objectForKey:NSFileType];


      if ([[_dest stringByAppendingString:@"/"]
                   hasPrefix:[[attr objectForKey:NSFilePath]
                                    stringByAppendingString:@"/"]]) {
        result = [self _buildErrorWithSource:[attr objectForKey:NSFilePath]
                       dest:_dest msg:3 handler:_handler
                       cmd:_cmd doFlush:NO doRollback:NO];
        [[self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths]
                              addObject:[attr objectForKey:NSFilePath]];

        if (![handler fileManager:(id)self shouldProceedAfterError:er_dict(3)])
          return NO;

        continue;
      }
      
      if ([ft isEqual:NSFileTypeRegular] || [ft isEqual:NSFileTypeUnknown]) {
        b = [self moveFile:srcGenRec toPath:desGenRec name:name
                  extension:ext handler:_handler doFlush:NO];
      }
      else if ([ft isEqual:NSFileTypeSymbolicLink]) {
        b = [self moveLink:srcGenRec toPath:desGenRec name:name
                  extension:ext handler:_handler doFlush:NO];
      }
      else if ([ft isEqual:NSFileTypeDirectory]) {
        b = [self moveDir:srcGenRec toPath:desGenRec name:name
                  extension:ext handler:_handler doFlush:NO];
      }
      else {
        b = NO;
      }
      if (result)
        result = b;

      if (!b) {
        [[self->errorUserInfo objectForKey:SkyProjectFM_MoveFailedAtPaths]
                              addObject:[attr objectForKey:NSFilePath]];
        if (handler)
          if (![handler fileManager:(id)self shouldProceedAfterError:er_dict(12)])
            return NO;
      }
    }
  }
  [self postChangeNotificationForPath:_source];
  [self postChangeNotificationForPath:_dest];
  [self flush];
  return result;
}

/*
    NSFilePath = {
      attributes = { '...' = '...' };
      contents   = NSData;

      // copy properties from .. 
      sourceGID  = EOGlobalID;
      //create new properties ...
      properties = { properties };
    }
  _path: dir to file
  
  in the moment already existing files will be ignored
*/

- (id)_newFileDocAtPath:(NSString *)filePath withName:(NSString *)name
  abstract:(NSString *)abstract ownerPrimaryKey:(NSNumber *)ownerId
  parentPrimaryKey:(NSNumber *)currentParentID
  content:(NSData *)content doNotCheckAccess:(BOOL)_noCheckAccess
{
  // Note: may not be called in recursion ...
  static NSMutableDictionary *args = nil; // THREAD
  id doc, fileSize;
  NSAssert(yesNum && noNum && emptyData, @"missing constant stuff");
  [args removeAllObjects];
  if (args == nil) args = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  if (![content isNotNull]) content = emptyData;
  fileSize = [NSNumber numberWithUnsignedInt:[content length]];
  
  [args setObject:name            forKey:@"title"];
  [args setObject:abstract        forKey:@"abstract"];
  [args setObject:filePath        forKey:@"filePath"];
  [args setObject:ownerId         forKey:@"firstOwnerId"];
  [args setObject:ownerId         forKey:@"currentOwnerId"];
  [args setObject:noNum           forKey:@"isObjectLink"];
  [args setObject:noNum           forKey:@"isFolder"];
  [args setObject:currentParentID forKey:@"parentDocumentId"];
  [args setObject:[self _project] forKey:@"project"];
  [args setObject:content         forKey:@"data"];
  [args setObject:fileSize        forKey:@"fileSize"];
  [args setObject:yesNum          forKey:@"autoRelease"];
  if (_noCheckAccess) [args setObject:noNum forKey:@"checkAccess"];
  
  doc = [[self context] runCommand:@"doc::new" arguments:args];
  return doc;
}
- (id)_newLinkDocAtPath:(NSString *)_path withName:(NSString *)name
  ownerPrimaryKey:(NSNumber *)ownerId parentPrimaryKey:(NSNumber *)_parentPKey
  target:(NSString *)_target
{
  id doc;
  NSAssert(yesNum && noNum, @"missing constant stuff");
  
  doc = [[self context] runCommand:@"doc::new",
                          @"title",            name,
                          @"objectLink",       _target,
                          @"filePath",         [_path lastPathComponent],
                          @"firstOwnerId",     ownerId,
                          @"currentOwnerId",   ownerId,
                          @"isObjectLink",     yesNum,
                          @"isFolder",         noNum,
			  @"parentDocumentId", _parentPKey,
                          @"project",          [self _project], nil];
  return doc;
}

- (BOOL)createFiles:(NSDictionary *)_dict atPath:(NSString *)_path {
  // TODO: split up method */
  NSNumber     *parentID, *ownerId;
  NSDictionary *parentAttrs;
  int          ec;
  
  /* check for abort conditionals */

  if (!(_path = [self _makeAbsolute:_path]))
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];

  parentAttrs = [self fileAttributesAtPath:_path traverseLink:NO];
  
  if (parentAttrs == nil) {
    return [self _buildErrorWithSource:_path dest:nil msg:34 
		 handler:nil cmd:_cmd];
  }
  if (![[parentAttrs objectForKey:NSFileType] 
	 isEqualToString:NSFileTypeDirectory]) {
    return [self _buildErrorWithSource:_path dest:nil msg:24 handler:nil
                 cmd:_cmd];
  }
  
  if (![self isInsertableDirectoryAtPath:_path]) {
    return [self _buildErrorWithSource:_path dest:nil msg:11 handler:nil
                 cmd:_cmd];
  }
  parentID = [[[parentAttrs valueForKey:@"globalID"] keyValuesArray]
                            lastObject];
  ec = 0;
  NS_DURING { /* now insert files */
    NSEnumerator   *enumerator;
    NSString       *fileName;
    NSMutableArray *soureGIDs, *destGIDs;

    soureGIDs  = [NSMutableArray arrayWithCapacity:[_dict count]];
    destGIDs   = [NSMutableArray arrayWithCapacity:[_dict count]];
    ownerId    = [[[self context] valueForKey:LSAccountKey]
                         valueForKey:@"companyId"];    
    enumerator = [_dict keyEnumerator];

    while ((fileName = [enumerator nextObject])) {
      NSNumber     *currentParentID;
      NSDictionary *attrs;
      NSData       *content;
      NSDictionary *dict;
      NSString     *name, *filePath, *abstract;
      id           handler, doc;

      currentParentID = parentID;
      
      if (![[fileName pathExtension] length]) {
        NSLog(@"ERROR[%s]: missing file extensions for %@", __PRETTY_FUNCTION__,
              fileName);
        continue;
      }
      
      dict    = [_dict objectForKey:fileName];
      attrs   = [dict objectForKey:@"attributes"];

      handler = nil;
      content = nil;
      
      if (!(content = [dict objectForKey:@"content"]))
        handler = [dict objectForKey:@"contentHandler"];

      if ((abstract = [attrs objectForKey:@"SkyTitle"]) == nil) {
        if ((abstract = [attrs objectForKey:@"NSFileSubject"]) == nil)
          if ((abstract = [attrs objectForKey:@"title"]) == nil)
            abstract = (id)[NSNull null];
      }
      filePath = [fileName stringByDeletingLastPathComponent];

      if ([filePath length]) { /* check access */
        filePath = [_path stringByAppendingPathComponent:filePath];
        
        if (![self isInsertableDirectoryAtPath:filePath]) {
          NSLog(@"WARNING[%s] missing insert access for path %@",
                __PRETTY_FUNCTION__, filePath);
          continue;
        }
        currentParentID = [[(EOKeyGlobalID *)[self globalIDForPath:filePath]
                                             keyValuesArray] lastObject];
      }
      name     = [[fileName lastPathComponent] stringByDeletingPathExtension];
      filePath = [_path stringByAppendingPathComponent:fileName];

      if ([self fileExistsAtPath:filePath isDirectory:NULL])
        continue;

      {
        NSAutoreleasePool *pool;
	
        pool = [[NSAutoreleasePool alloc] init];
	
        if (handler)
          content = [handler blob];
        
	doc = [self _newFileDocAtPath:filePath withName:name abstract:abstract
		    ownerPrimaryKey:ownerId parentPrimaryKey:currentParentID
		    content:content doNotCheckAccess:YES];
	
        [pool release]; pool = nil;
      }
      
      if (doc == nil) {
        return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                     cmd:_cmd];
      }
      else { /* copy properties if exist */
        EOGlobalID *gid;
        NSDictionary *props;

        if ((gid = [dict objectForKey:@"sourceGID"])) {
          [soureGIDs addObject:gid];
          [destGIDs  addObject:[doc globalID]];
        }
        else if ((props = [dict objectForKey:@"properties"])) {
          [[[self context] propertyManager] 
	          addProperties:props
	          accessOID:nil globalID:[doc globalID]];
        }
      }
    }
    if ([soureGIDs count] > 0) {
      [[[self context] propertyManager] 
	      copyPropertiesFrom:soureGIDs to:destGIDs];
    }
  }
  NS_HANDLER {
    ec  = 25; // TODO: use constants
    printf("%s: got exception %s\n", __PRETTY_FUNCTION__,
           [[localException description] cString]);
  }
  NS_ENDHANDLER;
  if (ec)
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                 cmd:_cmd];
  /* mark container as modified */
  [self postChangeNotificationForPath:_path];
  /* flush caches */
  [self flush];
  /* return new document object ... */
  return YES;
}

- (BOOL)createFileAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs
{
  NSString     *name, *path;
  NSNumber     *ownerId;
  id           doc;
  NSDictionary *attrs;
  int          ec;

  if (!(_path = [self _makeAbsolute:_path]))
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];

  // TODO: replace error codes with constants!

  /* check whether file already exists ... */
  
  if ([self fileExistsAtPath:_path isDirectory:NULL]) {
    return [self _buildErrorWithSource:_path dest:nil 
		 msg:7 handler:nil cmd:_cmd];
  }
  path = [_path stringByDeletingLastPathComponent];
  name = [[_path lastPathComponent] stringByDeletingPathExtension];
  /* ensure that the path contains an extension */
  if (![[_path pathExtension] length]) {
    return [self _buildErrorWithSource:_path dest:nil msg:15 handler:nil
                 cmd:_cmd];
  }
  /* lookup document for container of new file */
  if (!(attrs = [self fileAttributesAtPath:path traverseLink:NO])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  /* ensure that the parent object of the new file is a directory */
  if (!([[attrs objectForKey:NSFileType] 
	        isEqualToString:NSFileTypeDirectory])) {
    return [self _buildErrorWithSource:_path dest:nil msg:24 handler:nil
                 cmd:_cmd];
  }
  /* ensure that we have 'insert' right in the container */
  if (![self isInsertableDirectoryAtPath:path]) {
    return [self _buildErrorWithSource:_path dest:nil msg:11 handler:nil
                 cmd:_cmd];
  }
  /* current account is the new owner .. */
  ownerId = [[[self context] valueForKey:LSAccountKey]
                    valueForKey:@"companyId"];
  
  NS_DURING {
    NSString *abstract;

    ec = 0;
    
    if ((abstract = [_attrs objectForKey:@"SkyTitle"]) == nil) {
      if ((abstract = [_attrs objectForKey:@"NSFileSubject"]) == nil)
        if ((abstract = [_attrs objectForKey:@"title"]) == nil)
          abstract = (id)[NSNull null];
    }
    
    #if 0 // hh(2024-09-19): unused
    NSNumber *fileSize = [NSNumber numberWithInt:
                           (int)((_contents) ? [_contents length] : 0)];
    #endif

    // TODO: this did not set checkaccess to no!
    doc = [self _newFileDocAtPath:_path withName:name abstract:abstract
		ownerPrimaryKey:ownerId 
		parentPrimaryKey:
		  [[attrs objectForKey:@"globalID"] keyValues][0]
		content:_contents doNotCheckAccess:NO];
  }
  NS_HANDLER {
    ec  = 25; // TODO: use constant
    doc = nil;
  }
  NS_ENDHANDLER;
  
  if (!doc) {
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                 cmd:_cmd];
  }
  /* mark container as modified */
  [self postChangeNotificationForPath:
	  [_path stringByDeletingLastPathComponent]];
  /* flush caches */
  [self flush];
  /* return new document object ... */
  return YES;
}

/* links */

- (NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)_path {
  id           result;
  NSDictionary *attrs;

  if ((_path = [self _makeAbsolute:_path]) == nil) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  
  if (![self isReadableFileAtPath:_path]) {
    [self _buildErrorWithSource:_path dest:nil msg:29 handler:nil cmd:_cmd];
    return nil;
  }
    
  attrs  = [self fileAttributesAtPath:_path traverseLink:NO];
  if ((result = [attrs objectForKey:@"SkyLinkTarget"])) {
    if ((attrs = [self fileAttributesAtPath:result traverseLink:NO])) {
      result = [attrs objectForKey:NSFilePath];
    }
  }
  return result;
}

- (BOOL)createSymbolicLinkAtPath:(NSString *)_path
  pathContent:(NSString *)_target
{
  id           doc, loginId;
  NSString     *dir, *linkName, *linkType;
  NSDictionary *dirAttrs;
  int          ec;

  
  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if (![_target length]) {
    return [self _buildErrorWithSource:_path dest:nil msg:26 handler:nil
                 cmd:_cmd];
  }
  //  [self flush];
  if ([self fileExistsAtPath:_path isDirectory:NULL]) {
    return [self _buildErrorWithSource:_path dest:nil msg:7 handler:nil
                 cmd:_cmd];
  }
  linkName = [[_path lastPathComponent] stringByDeletingPathExtension];
  dir      = [_path stringByDeletingLastPathComponent];

  if (![self isInsertableDirectoryAtPath:dir]) {
    return [self _buildErrorWithSource:_path dest:nil msg:29 handler:nil
                 cmd:_cmd];
  }
  if (!(dirAttrs = [self fileAttributesAtPath:dir traverseLink:NO]))
    return [self _buildErrorWithSource:_path dest:nil msg:27 handler:nil
                 cmd:_cmd];

  if (![[dirAttrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self _buildErrorWithSource:_path dest:nil msg:24 handler:nil
                 cmd:_cmd];

  loginId = 
    [[[self context] valueForKey:LSAccountKey] valueForKey:@"companyId"];
  if ((linkType = [_path pathExtension]) == nil)
    linkType = (id)[NSNull null];
  
  NS_DURING {
    ec  = 0;
    doc = [self _newLinkDocAtPath:_path withName:linkName
		ownerPrimaryKey:loginId
		parentPrimaryKey:
		  [[dirAttrs objectForKey:@"globalID"] keyValues][0]
		target:_target];
  }
  NS_HANDLER {
    ec  = 28; // TODO: use constant
    doc = nil;
    [self setLastException:localException];
  }
  NS_ENDHANDLER;
  if (!doc) 
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                 cmd:_cmd];
  
  [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
  [self flush];
  
  return YES;
}

/* directories */


- (NSArray *)subpathsAtPath:(NSString *)_path {
  NSMutableArray *array;

  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  array = [NSMutableArray arrayWithCapacity:16];
  [self _subpathsAtPath:_path array:array];
  return array;
}

- (NSArray *)directoryContentsAtPath:(NSString *)_path
{
  if ((_path = [self _makeAbsolute:_path]) == nil) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  return [[[self->cache childFileNamesAtPath:_path manager:self] 
	                copy] autorelease];
}

- (BOOL)copyPath:(NSString *)_source toPath:(NSString *)_dest
  handler:(id)_handler
{
  BOOL sourceIsDir;

  sourceIsDir = NO;

  if (!(_source = [self _makeAbsolute:_source])) {
    return [self _buildErrorWithSource:_source dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if (!(_dest = [self _makeAbsolute:_dest])) {
    return [self _buildErrorWithSource:_dest dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if (![self fileExistsAtPath:_source isDirectory:&sourceIsDir]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:4 
		 handler:_handler cmd:_cmd];
  }
  
  if ([self fileExistsAtPath:_dest isDirectory:NULL]) {
    return [self _buildErrorWithSource:_source dest:_dest msg:7
                 handler:_handler cmd:_cmd];
  }
  if (sourceIsDir) {
	/* If destination directory is a descendant of source directory copying
       isn't possible. */
    if ([[_dest stringByAppendingString:@"/"]
                hasPrefix:[_source stringByAppendingString:@"/"]]) {
      return [self _buildErrorWithSource:_source dest:_dest msg:31
                   handler:_handler cmd:_cmd];
    }
    return [self _copyPath:_source toPath:_dest handler:_handler];
  }
  else {
    NSMutableDictionary *dict;
    NSDictionary        *d, *attrs;
    id                  keys[3], vals[3];

    if (_handler)
      [_handler fileManager:(id)self willProcessPath:_source];

    attrs   = [self fileAttributesAtPath:_source traverseLink:NO];

    keys[0] = @"contentHandler";
    keys[1] = @"attributes";
    keys[2] = @"sourceGID";

    vals[0] = [self blobHandlerAtPath:[attrs objectForKey:NSFilePath]];
    vals[1] = attrs;
    vals[2] = [attrs objectForKey:@"globalID"];
    d       = [NSDictionary dictionaryWithObjects:vals forKeys:keys count:3];
    dict    = [NSDictionary dictionaryWithObject:d forKey:[_dest lastPathComponent]];
    
    return [self createFiles:dict atPath:[_dest stringByDeletingLastPathComponent]];
  }
  return NO;
}

- (BOOL)createDirectoryAtPath:(NSString *)_path 
  attributes:(NSDictionary *)_attr
{
  NSString      *dir, *dirName;
  NSNumber      *loginId;
  EOKeyGlobalID *dirGID;
  int           ec;

  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  //  [self flush];
  if ([self fileExistsAtPath:_path isDirectory:NULL]) {
    return [self _buildErrorWithSource:_path dest:nil msg:7 handler:nil cmd:_cmd];
  }
  dirName = [_path lastPathComponent];
  dir     = [_path stringByDeletingLastPathComponent];

  if (![self isInsertableDirectoryAtPath:dir]) {
    return [self _buildErrorWithSource:_path dest:nil msg:11 handler:nil
                 cmd:_cmd];
  }
  dirGID  = (id)[self globalIDForPath:dir];
  loginId = [[[self context] valueForKey:LSAccountKey] valueForKey:@"companyId"];
  
  NS_DURING {
    ec  = 0;
    if (![[self context] runCommand:@"doc::new",
                         @"title",            dirName,
                         @"firstOwnerId",     loginId,
                         @"currentOwnerId",   loginId,
                         @"isFolder",         [NSNumber numberWithBool:YES],
                         @"parentDocumentId", [dirGID keyValues][0],
                         @"project",          [self _project],
                         @"status",           @"released", nil])
      ec = 33;
  }
  NS_HANDLER {
    ec  = 33;
    [self setLastException:localException];
  }
  NS_ENDHANDLER;
  if (ec) {
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                 cmd:_cmd];
  }
  [self postChangeNotificationForPath:dir];
  [self flush];
  return YES;
}

/* file-system (=project) */

- (NSDictionary *)fileSystemAttributesAtPath:(NSString *)_path {
  NSMutableDictionary *result;
  NSDictionary        *attrs;
  NSString            *ft;
  
  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  
  if (!(attrs = [self fileAttributesAtPath:_path traverseLink:NO])) {
    [self _buildErrorWithSource:_path dest:nil msg:34 handler:nil cmd:_cmd];
    return nil;
  }
  result = [NSMutableDictionary dictionaryWithCapacity:8];
  ft     = [attrs objectForKey:NSFileType];
  
  if (![ft isEqualToString:NSFileTypeDirectory] &&
      ![ft isEqualToString:NSFileTypeSymbolicLink]) {
    NSString      *blobPath;
    NSDictionary  *blobAttrs;
    id            tmp;

    if ((blobPath = [attrs objectForKey:@"SkyBlobPath"]) == nil) {
      blobPath = [SkyProjectFileManager blobNameForDocument:attrs
					globalID:
					  [attrs objectForKey:@"globalID"]
                                        realDoc:nil manager:self
                                        projectId:
					  [[self _project]
					    valueForKey:@"projectId"]
                                        context:self->cache];
    }
    if (blobPath) {
      blobAttrs = [[NSFileManager defaultManager]
                                  fileSystemAttributesAtPath:blobPath];
    }
    else 
      blobAttrs = nil;

    if ((tmp = [blobAttrs objectForKey:NSFileSystemSize]))
      [result setObject:tmp forKey:NSFileSystemSize];
    if ((tmp = [blobAttrs objectForKey:NSFileSystemFreeSize]))
      [result setObject:tmp forKey:NSFileSystemFreeSize];
  }
  [result setObject:[[self _project] valueForKey:@"ownerId"]
         forKey:@"NSFileSystemOwnerAccountNumber"];
  [result setObject:[[self _project] valueForKey:@"name"]
         forKey:@"NSFileSystemName"];

  /* this following should be removed later ... */
  [result setObject:[self _project] forKey:@"object"];
  
  [result setObject:[[self _project] globalID] forKey:NSFileSystemNumber];
  
  return result;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p[%@]: cache=%@ cwd=%@>",
                     self, NSStringFromClass([self class]),
                     self->cache, [self currentDirectoryPath]];
}

- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path
{
  return [self changeFileAttributes:_attributes atPath:_path flush:YES];
}

- (BOOL)isRootAccountID:(NSNumber *)_pkey {
  if (![_pkey isNotNull]) return NO;
  return [_pkey intValue] == 10000 ? YES : NO; // TODO: use some command
}

- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path flush:(BOOL)_doFlush
{
  id subj;
  
  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  //  [self flush];
  if (![self isWritableFileAtPath:_path]) {
    return [self _buildErrorWithSource:_path dest:nil msg:35 handler:nil
                 cmd:_cmd];
  }
  if ((subj = [_attributes valueForKey:@"NSFileSubject"])) {
    id  doc;
    int ec;

    if ([_path pathVersion]) {
      return [self _buildErrorWithSource:_path dest:nil msg:36 handler:nil
                   cmd:_cmd];
    }
    doc = [self->cache genericRecordForFileName:_path manager:self];
    {
      NSString *status;

      status = [doc valueForKey:@"status"];
      
      if ([status isEqualToString:@"edited"]) {
        NSNumber *a, *aid;
	
        a   = [[self context] valueForKey:LSAccountKey];
        aid = [a valueForKey:@"companyId"];
	
        if (![[doc valueForKey:@"currentOwnerId"] isEqual:aid] &&
            ![self isRootAccountID:aid])
          return [self _buildErrorWithSource:_path dest:nil msg:37 handler:nil
                       cmd:_cmd];
      }
    }
    NS_DURING {
      ec = 0;

      [[self context] runCommand:@"doc::set", @"object", doc,
                      @"abstract", subj, nil];
    }
    NS_HANDLER {
      ec = 17;
      [self setLastException:localException];
    }
    NS_ENDHANDLER;
    if (ec) {
      return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                       cmd:_cmd];
    }
    [self postChangeNotificationForPath:_path];
    [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
    if (_doFlush)
      [self flush];
    return YES;
  }
  return YES;
}


- (void)clearCaches {
  NSLog(@"WARNING[%s] depricated, use flush instead", __PRETTY_FUNCTION__);
  [self->cache flushWithManager:self];
}

/* copying */

- (id)copyWithZone:(NSZone *)_zone {
  SkyProjectFileManager *fm;
  
  fm = [[[self class] alloc] initWithFileManagerCache:self->cache];
  [fm changeCurrentDirectoryPath:[self currentDirectoryPath]];
  
  return fm;
}

/* capabilities */

- (BOOL)supportsHistoryDataSource {
  return YES;
}
- (BOOL)supportsProperties {
  return YES;
}
- (BOOL)supportsUniqueFileIds {
  return YES;
}

- (BOOL)isSymbolicLinkEnabledAtPath:(NSString *)_path {
  return YES;
}

- (EODataSource *)dataSourceForDocumentSearchAtPath:(NSString *)_path {
  return [[[SkyProjectFolderDataSource alloc]
                                       initWithContext:[self context]
                                       folderGID:
                                       [self globalIDForPath:_path]
                                       projectGID:[[self _project] globalID]
                                       path:_path
                                       fileManager:self] autorelease];
}

- (BOOL)supportAccessRights {
  return YES;
}

/* creating new URLs (this is used by OGoFileManagerFactory) */

+ (NSURL *)newURLForProjectBase:(NSString *)_base
  stringValue:(NSString *)url
  commandContext:(id)_ctx
{
  return [[OGoFileManagerFactory sharedFileManagerFactory] skyrixBaseURL];
}

@end /* SkyProjectFileManager */
