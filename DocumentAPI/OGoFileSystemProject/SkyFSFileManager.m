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

#include "common.h"
#include "SkyFSFileManager.h"
#include "SkyFSDocument.h"
#include "SkyFSDataSource.h"
#include "SkyFSFolderDataSource.h"
#include "SkyFSGlobalID.h"
#include "SkyFSFileManager+Internals.h"
#include <OGoProject/OGoFileManagerFactory.h>

/*
  Defaults:
    SkFSPath
    SkyFSMaxFileLockTime
*/

@implementation SkyFSFileManager

static BOOL SkyFSDebug = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  SkyFSDebug = [ud boolForKey:@"SkyFSDebug"];
}

- (id)initWithContext:(id)_context project:(id)_project {
  if ((self = [super init])) {
    if (_context == nil || _project == nil) {
      NSLog(@"ERROR[%s] missing context(%@) or project (%@)",
            __PRETTY_FUNCTION__, _context, _project);
      [self release];
      return nil;
    }
    {
      NSURL *url;

      url = [NSURL URLWithString:[_project valueForKey:@"url"]];
      self->workingPath = [[url path] retain];
    }
    ASSIGN(self->project, _project);
    ASSIGN(self->context, _context);
    
    [self->fileManager release];
    self->fileManager = [[NSFileManager defaultManager] retain];
    
    {
      BOOL isDir;
      
      if (![self->fileManager fileExistsAtPath:self->workingPath
                isDirectory:&isDir]) {
        NSLog(@"ERROR[%s]: missing path <%@> for project %@",
              __PRETTY_FUNCTION__, self->workingPath, _project);
        [self release];
        [[SkyFSException exceptionWithName:@"SkyFSException"
                         reason:@"Missing path for project"
                         userInfo:nil] raise];
        return nil;
      }
      if (!isDir){
        NSLog(@"ERROR[%s]: path <%@> is no directory. project %@",
              __PRETTY_FUNCTION__, self->workingPath, _project);
        [self release];
        [[SkyFSException exceptionWithName:@"SkyFSException"
                         reason:@"Missing path for project"
                         userInfo:nil] raise];
        return nil;
      }
    }

    self->fileSystemAttributes =
      [[NSDictionary alloc]
                     initWithObjectsAndKeys:
                     [self->project globalID],    NSFileSystemNumber,
                     self->project, @"object",
                     [self->project valueForKey:@"ownerId"],
                     @"NSFileSystemOwnerAccountNumber",
                     [project valueForKey:@"name"],
                     @"NSFileSystemName", nil];
  }
  return self;
}

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid {
  id p;

  if (!_context || !_gid) {
    NSLog(@"ERROR[%s] missing context(%@) or gid (%@)",
          __PRETTY_FUNCTION__, _context, _gid);
    return nil;
  }
  p = [_context runCommand:@"project::get",
                @"projectId",  [(EOKeyGlobalID *)_gid keyValues][0], nil];
    
  if ([p isKindOfClass:[NSArray class]]) {
    p = ([p count] == 1) ? [p objectAtIndex:0] : nil;
  }

  if (p == nil) {
    NSLog(@"ERROR[%s]: missing project for gif %@",
          __PRETTY_FUNCTION__, _gid);
    [self release];
    return nil;
  }
  return [self initWithContext:_context project:p];
}

- (void)dealloc {
  [self->context               release];
  [self->project               release];
  [self->fileManager           release];
  [self->workingPath           release];
  [self->fileSystemAttributes  release];
  [self->lock                  release];
  [self->lastException         release];
  [super dealloc];
}

/* attributes */

- (Class)documentClass {
  return [SkyFSDocument class];
}
- (Class)dataSourceClass {
  return [SkyFSDataSource class];
}
- (Class)folderDataSourceClass {
  return [SkyFSFolderDataSource class];
}

- (NSDictionary *)fileSystemAttributesAtPath:(NSString *)_p {
  return self->fileSystemAttributes;
}

- (EODataSource *)dataSourceAtPath:(NSString *)_path {
  return [[[self dataSourceClass] alloc] 
           initWithFileManager:self
           context:self->context
           project:self->project
           path:_path];
    
}

- (BOOL)isOperation:(NSString *)_op allowedOnPath:(NSString *)_path {
  return YES;
}

- (void)setLastExceptionOnPath:(NSString *)_path reason:(NSString *)_reason {
  NSException  *ex;
  NSDictionary *ui;
  static NSString *k = @"path";
  
  ui = _path 
    ? [[NSDictionary alloc] initWithObjects:&_path forKeys:&k count:1]:nil;
  ex = [SkyFSException reason:_reason userInfo:ui];
  [ui release];
  
  [self setLastException:ex];
}
- (void)setLastExceptionOnSource:(NSString *)_s andTarget:(NSString *)_t 
  reason:(NSString *)_reason 
{
  NSException  *ex;
  NSDictionary *ui;

  ui = [[NSDictionary alloc] initWithObjectsAndKeys:
                               _s, @"source",
                               _t, @"destination", nil];
  
  ex = [SkyFSException reason:_reason userInfo:ui];
  [ui release];

  [self setLastException:ex];
}

- (SkyDocument *)documentAtPath:(NSString *)_path {
  NSString     *name, *path;
  BOOL         isDir;
  NSDictionary *attrs;
  
  [self resetLastException];

  if ((_path = [self _makeAbsoluteInSky:_path]) == nil)
    return nil;

  name  = [_path lastPathComponent];
  path  = [_path stringByDeletingLastPathComponent];

  if (![self fileExistsAtPath:_path isDirectory:&isDir]) {
    [self setLastExceptionOnPath:_path reason:@"Missing File"];
    return nil;
  }
  
  attrs = [self fileAttributesAtPath:_path traverseLink:NO];
  return [[[[self documentClass] alloc]
                          initWithFileManager:self context:self->context
                          project:self->project
                          path:path fileName:name
                          attributes:attrs]
                          autorelease];
}

- (void)flush {
}

- (int)lastErrorCode {
  return 0;
}

- (BOOL)_movePath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler {
  NSString     *source, *dest;
  NSDictionary *attrs;
  BOOL         isDir;
  NSException  *ex;

  [self resetLastException];
  
  source = [self _makeAbsolute:_s];
  dest   = [self _makeAbsolute:_d];

  attrs = [self fileAttributesAtPath:_s traverseLink:NO];

  if ([self->fileManager fileExistsAtPath:dest isDirectory:&isDir]) {
    if (isDir)
      dest = [dest stringByAppendingPathComponent:[source lastPathComponent]];
  }
  if ([self->fileManager movePath:source toPath:dest handler:nil]) {
    [self _removeAttributesForPath:source];
    [self resetLastException];
    return [self _saveAttributes:attrs forPath:dest isNew:YES];
  }

  ex = [SkyFSException reason:@"move failed"
                       userInfo:
                        [NSDictionary dictionaryWithObjectsAndKeys:
                                      _s, @"source",
                                      _d, @"destination", nil]];
  [self setLastException:ex];
  return NO;
}

- (BOOL)movePath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler {
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _movePath:_s toPath:_d handler:_handler];

  [self unlock];
  
  return res;
}


- (BOOL)_movePaths:(NSArray *)_src toPath:(NSString *)_d handler:(id)_handler {
  NSEnumerator *enumerator;
  NSString     *path;

  enumerator = [_src objectEnumerator];
  
  while ((path = [enumerator nextObject])) {
    if (![self _movePath:path toPath:_d handler:_handler])
      return NO;
  }
  return YES;
}

- (BOOL)movePaths:(NSArray *)_src toPath:(NSString *)_d handler:(id)_handler {
  BOOL res;
  
  if (![self tryLock])
    return NO;
  
  res = [self _movePaths:_src toPath:_d handler:_handler];

  [self unlock];
  
  return res;
}

- (NSNumber *)_loginId {
  return [[self->context valueForKey:LSAccountKey] valueForKey:@"companyId"];
}
- (NSString *)_loginName {
  return [[self->context valueForKey:LSAccountKey] valueForKey:@"login"];
}

- (BOOL)_createDirectoryAtPath:(NSString *)_path
  attributes:(NSDictionary *)_ats
{
  NSString    *path;
  NSException *ex;

  [self resetLastException];

  path = [self _makeAbsolute:_path];
  
  if ([self->fileManager
           createDirectoryAtPath:path attributes:nil]) {
    return [self _saveAttributes:_ats forPath:path isNew:YES];
  }
  
  ex = [SkyFSException reason:@"Create directory failed"
                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                _path, @"path", nil]];
  [self setLastException:ex];
  return NO;
}

- (BOOL)createDirectoryAtPath:(NSString *)_path
  attributes:(NSDictionary *)_ats
{
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _createDirectoryAtPath:_path attributes:_ats];

  [self unlock];
  
  return res;
  
}

- (BOOL)_createFileAtPath:(NSString *)_path contents:(NSData *)_contents
  attributes:(NSDictionary *)_attributes
{
  NSString *path;

  [self resetLastException];
  
  path = [self _makeAbsolute:_path];

  if ([self->fileManager createFileAtPath:path contents:_contents
           attributes:nil]) {
    return [self _saveAttributes:_attributes forPath:path isNew:YES];
  }

  [self setLastExceptionOnPath:_path reason:@"Create file failed"];
  return NO;
}

- (BOOL)createFileAtPath:(NSString *)_path contents:(NSData *)_contents
  attributes:(NSDictionary *)_attributes
{
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _createFileAtPath:_path contents:_contents
              attributes:_attributes];

  [self unlock];
  
  return res;
}

- (BOOL)_changeFileAttributes:(NSDictionary *)_attrs atPath:(NSString *)_p {
  return [self _saveAttributes:_attrs forPath:[self _makeAbsolute:_p] 
	       isNew:NO];
}

- (BOOL)changeFileAttributes:(NSDictionary *)_attrs atPath:(NSString *)_p {
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _changeFileAttributes:_attrs atPath:_p];
  [self unlock];
  return res;
}

- (BOOL)supportsHistoryDataSource {
  return NO;
}

static NSDictionary *LSMimeTypes = nil;

- (NSDictionary *)fileAttributesAtPath:(NSString *)_p
  traverseLink:(BOOL)_flag
{
  NSMutableDictionary *attrs;
  NSDictionary        *tmp;
  NSString            *ext, *mt, *fileName;
  NSString            *absoluteSystemPath, *absoluteFSPath;

  absoluteSystemPath = [self _makeAbsolute:_p];

  if (!(absoluteFSPath = [self _makeAbsoluteInSky:_p]))
    return nil;
  
  attrs = [[self->fileManager fileAttributesAtPath:absoluteSystemPath
                traverseLink:_flag] mutableCopy];
  
  if (LSMimeTypes == nil) {
    LSMimeTypes  = [[[self->context valueForKey:LSUserDefaultsKey]
                                    dictionaryForKey:@"LSMimeTypes"] retain];
  }
  if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
    [attrs setObject:@"x-skyrix/filemanager-directory"
           forKey:@"NSFileMimeType"];
  }
  else {
    ext = [[absoluteFSPath pathExtension] lowercaseString];
    mt  = nil;
    if (ext)
      mt  = [LSMimeTypes objectForKey:ext];

    if (!mt)
      mt = @"application/octet-stream";

    [attrs setObject:mt forKey:@"NSFileMimeType"];
  }
  fileName = [absoluteFSPath lastPathComponent];

  [attrs setObject:fileName forKey:@"NSFileName"];
  [attrs setObject:absoluteFSPath forKey:@"NSFilePath"];

  [attrs addEntriesFromDictionary:
         [self _attributesForPath:absoluteSystemPath]];
  
  tmp = [attrs copy];
  [attrs release]; attrs = nil;

  return [tmp autorelease];
}

- (BOOL)supportsProperties {
  return NO;
}

- (BOOL)supportsUniqueFileIds {
  return NO;
}

- (BOOL)isSymbolicLinkEnabledAtPath:(NSString *)_path {
  return NO;
}

- (EODataSource *)dataSourceForDocumentSearchAtPath:(NSString *)_path {
  return [[[[self folderDataSourceClass] alloc]
            initWithPath:_path fileManager:self] autorelease];
}

/* file operations */

- (BOOL)_copyPath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler {
  NSString *source, *dest;

  [self resetLastException];
  
  source = [self _makeAbsolute:_s];
  dest   = [self _makeAbsolute:_d];

  if ([self->fileManager copyPath:source toPath:dest handler:_handler]) {
    return [self _saveAttributes:[self fileAttributesAtPath:_s traverseLink:NO]
                 forPath:dest isNew:YES];
  }
  
  [self setLastExceptionOnSource:_s andTarget:_d
        reason:@"Copy path failed"];
  return NO;
}

- (BOOL)copyPath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler {
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _copyPath:_s toPath:_d handler:_handler];

  [self unlock];
  
  return res;
}

- (BOOL)linkPath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler {
  NSLog(@"WARNING(%s): not implemented, path: '%@'", __PRETTY_FUNCTION__,_s);
  return NO;
}

- (BOOL)_removeFileAtPath:(NSString *)_path handler:(id)_handler {
  NSString *path;

  [self resetLastException];

  path = [self _makeAbsolute:_path];
  
  if ([self->fileManager removeFileAtPath:path handler:_handler])
    return [self _removeAttributesForPath:path];
  
  [self setLastExceptionOnPath:_path reason:@"Remove path failed"];
  return NO;
}

- (BOOL)removeFileAtPath:(NSString *)_path handler:(id)_handler {
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _removeFileAtPath:_path handler:_handler];

  [self unlock];
  
  return res;
}


/* getting and comparing file contents */

- (NSData *)contentsAtPath:(NSString *)_path {
  return [self->fileManager contentsAtPath:[self _makeAbsolute:_path]];
}

- (BOOL)contentsEqualAtPath:(NSString *)_path1 andPath:(NSString *)_path2 {
  return [self->fileManager contentsEqualAtPath:[self _makeAbsolute:_path1]
                            andPath:[self _makeAbsolute:_path2]];
}

/* determining access to files */

- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL*)_isDirectory {
  return [self->fileManager fileExistsAtPath:[self _makeAbsolute:_path]
                            isDirectory:_isDirectory];
}

/* discovering directory contents */

- (NSArray *)directoryContentsAtPath:(NSString *)_path {
  NSEnumerator *enumerator;
  NSMutableArray *result;
  NSString       *str;
  NSString       *path;
  
  [self resetLastException];
  path       = [self _makeAbsolute:_path];
  result     = [NSMutableArray arrayWithCapacity:64];
  enumerator = [[self->fileManager directoryContentsAtPath:path]
                                   objectEnumerator];

  while ((str = [enumerator nextObject])) {
    NSString *p;
    
    if ((p = [self _checkPath:str]) == nil) {
      [self resetLastException]; /* we don't care */
      continue;
    }
    
    [result addObject:p];
  }
  return [[result copy] autorelease];
}

- (NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)_path {
  NSLog(@"WARNING(%s): not implemented, path: '%@'",
	__PRETTY_FUNCTION__, _path);
  return nil;
}

- (NSArray *)subpathsAtPath:(NSString *)_path {
  NSEnumerator *enumerator;
  NSMutableArray *result;
  NSString       *str;
  NSString       *path;

  path       = [self _makeAbsolute:_path];

  result     = [NSMutableArray arrayWithCapacity:64];
  enumerator = [[self->fileManager subpathsAtPath:path]
                                   objectEnumerator];

  while ((str = [enumerator nextObject])) {
    [result addObject:str];
  }
  return [[result copy] autorelease];
}

/* symbolic-link operations */

- (BOOL)createSymbolicLinkAtPath:(NSString *)_p pathContent:(NSString *)_dp {
  NSLog(@"WARNING(%s): not implemented, path: '%@'", __PRETTY_FUNCTION__, _p);
  return NO;
}
- (NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)_path {
  return nil;
}

/* feature check */

- (BOOL)supportsFeature:(NSString *)_featureURI atPath:(NSString *)_path {
  return NO;
}

/* writing */

- (BOOL)_writeContents:(NSData *)_content atPath:(NSString *)_path {
  NSString *path;
  BOOL     exist, isDir;

  [self resetLastException];

  path = [self _makeAbsolute:_path];
 
  if ([self->fileManager fileExistsAtPath:path isDirectory:&isDir]) {
    exist = YES;
    if (isDir) {
      [self setLastExceptionOnPath:_path 
            reason:@"Write contents failed (is directory!)"];
      return NO;
    }
  }
  else {
    exist = NO;
  }
  
  if ([self->fileManager writeContents:_content atPath:path]) {
    if (!exist)
      return [self _updateAttributes:nil forPath:path];
    else
      return YES;
  }
  [self setLastExceptionOnPath:_path reason:@"Write contents failed"];
  return NO;
}

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path {
  BOOL res;

  if (![self tryLock])
    return NO;
  
  res = [self _writeContents:_content atPath:_path];

  [self unlock];
  return res;
}

/* global-IDs */

- (EOGlobalID *)globalIDForPath:(NSString *)_path {
  if (!(_path = [self _makeAbsoluteInSky:_path]))
    return nil;
  
  return [[[SkyFSGlobalID alloc] initWithPath:_path
                                 projectGID:[self->project globalID]]
                          autorelease];
}

- (NSString *)pathForGlobalID:(EOGlobalID *)_gid {
  return [(id)_gid path];
}

/* trash */

- (BOOL)supportsTrashFolderAtPath:(NSString *)_path {
  return YES;
}
- (NSString *)trashFolderForPath:(NSString *)_path {
  static NSString *trashFolderPath = nil;
  if (trashFolderPath == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    trashFolderPath = [[ud stringForKey:@"OGoProjectTrashFolderPath"] copy];
    if (trashFolderPath == nil) trashFolderPath = @"/trash";
  }
  return trashFolderPath;
}

- (BOOL)supportAccessRights {
  return NO;
}

- (BOOL)supportsExternalErrorDescription {
  return NO;
}

- (NSString *)lastErrorDescription {
  return nil;
}

- (BOOL)supportsVersioning {
  return NO;
}

- (BOOL)supportsVersioningAtPath:(NSString *)_path {
  return NO;
}

- (BOOL)changeCurrentDirectoryPath:(NSString *)_path {
  BOOL isDir;

  [self resetLastException];
  
  if ((_path = [self _makeAbsoluteInSky:_path]) == nil)
    return NO;
  
  if (![self fileExistsAtPath:_path isDirectory:&isDir]) {
    [self setLastExceptionOnPath:_path 
          reason:@"Couldn`t change working directory, path does not exist"];
    return NO;
  }
  if (!isDir) {
    [self setLastExceptionOnPath:_path
          reason:
            @"Couldn`t change working directory, path is not a directory"];
    return NO;
  }
  
  ASSIGNCOPY(self->cwd, _path);
  
  return YES;
}

- (BOOL)isExecutableFileAtPath:(NSString *)_path {
  return [self->fileManager isExecutableFileAtPath:[self _makeAbsolute:_path]];
}
- (BOOL)isWritableFileAtPath:(NSString*)_path {
  return [self->fileManager isWritableFileAtPath:[self _makeAbsolute:_path]];
}
- (BOOL)isDeletableFileAtPath:(NSString*)_path {
  return [self->fileManager isWritableFileAtPath:[self _makeAbsolute:_path]];
}
- (BOOL)isReadableFileAtPath:(NSString*)_path {
  return [self->fileManager isReadableFileAtPath:[self _makeAbsolute:_path]];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];

  if (self->project)
    [ms appendFormat:@" project=%@", self->project];
  else
    [ms appendString:@" no-project"];
  [ms appendString:@">"];
  return ms;
}

/* lock */

static NSString *LockPrefix = @"lock";

- (NSDistributedLock *)lock {
  if (self->lock == nil) {
    static BOOL     CheckLockDefault = YES;
    static NSString *LockPath         = nil;
    
    NSString        *tmp;
    BOOL            isDir;

    if (CheckLockDefault) {
      LockPath =
        [[[NSUserDefaults standardUserDefaults] stringForKey:@"SkyFSLockPath"]
                          retain];
      CheckLockDefault = NO;

      if (SkyFSDebug)
        [self logWithFormat:@"got logpath: <%@>", LockPath];
    }

    tmp = [self->workingPath stringByAppendingPathComponent:
               [self attributesPath]];

    if (SkyFSDebug)
      [self logWithFormat:@"search logpath in <%@>", tmp];

    if (![self->fileManager fileExistsAtPath:tmp isDirectory:&isDir]) {

      if (SkyFSDebug)
        [self logWithFormat:@"file at path %@ does not exist", tmp];
      
      if (![self->fileManager createDirectoryAtPath:tmp attributes:nil]) {
        if (SkyFSDebug)
          [self logWithFormat:@"createDirectoryAtPath %@ failed",
                tmp];
        
	tmp = LockPath != nil ? LockPath : @"/tmp/";
	
        if (SkyFSDebug)
          [self logWithFormat:@"try now %@", tmp];
        
        if (![self->fileManager fileExistsAtPath:tmp isDirectory:&isDir]) {
          NSLog(@"ERROR[%s:%d]: "
                @"Couldn`t read lock directory at path %@, use Default "
                @"\"SkyFSLockPath\" to set a path for lock-files",
                __PRETTY_FUNCTION__, __LINE__, tmp);
          return nil;
        }
        else if (!isDir) {
          NSLog(@"ERROR[%s:%d]: "
                @"Lockfile-Path %@ should be a directory, use Default "
                @"\"SkyFSLockPath\" to set a path for lock-files",
                __PRETTY_FUNCTION__, __LINE__, tmp);
          return nil;
        }
      }
    }
    else if (!isDir) {
      NSLog(@"ERROR[%s]: "
            @"Lockfile-Path %@ should be a directory, use Default "
            @"\"SkyFSLockPath\" to set a path for lock-files",
            __PRETTY_FUNCTION__, tmp);
      return nil;
    }
    tmp = [tmp stringByAppendingPathComponent:
               [[[self->project valueForKey:@"projectId"] stringValue]
                                stringByAppendingPathExtension:LockPrefix]];

    self->lock = [[NSDistributedLock alloc] initWithPath:tmp];
  }
  return self->lock;
}

- (BOOL)tryLock {
  NSDistributedLock *l;
  static int MaxLockTime = -1; /* max lock time in seconds */
  NSDate       *lockDate;
  NSException  *ex;
  NSDictionary *ui;

  [self resetLastException];
  
  l = [self lock];

  if ([l tryLock])
    return YES;

  if (MaxLockTime == -1) {
      MaxLockTime = [[NSUserDefaults standardUserDefaults]
                                     integerForKey:@"SkyFSMaxFileLockTime"];
      if (!MaxLockTime)
        MaxLockTime = 15;
  }
  if ((lockDate = [self lockDate])) {
      if (abs([lockDate timeIntervalSinceNow]) > MaxLockTime) {
        NSLog(@"WARNING[%s]: unlock locked FS-Project %@, locked "
              @"since %@ now %@", __PRETTY_FUNCTION__,
              self, lockDate, [NSDate date]);
        [l breakLock];
      
        if ([l tryLock]) {
          return YES;
        }
      }
  } 
  NSLog(@"WARNING[%s] try to lock already locked FS-Project %@."
        @"Locked since:%@ now:%@.", __PRETTY_FUNCTION__, self, lockDate,
        [NSDate date]);
  
  ui = [NSDictionary dictionaryWithObjectsAndKeys:
                                        self, @"project",
                     lockDate, @"lockDate", nil];
  ex = [SkyFSException reason:@"Couldn`t lock project, "
                          @"project already locked"
                       userInfo:ui];
  [self setLastException:ex];
  return NO;
}

- (void)breakLock {
  [[self lock] breakLock];
}

- (NSException *)_handleUnlockException:(NSException *)_exception {
  [self logWithFormat:
          @"ERROR[SkyFSFileManager::unlock]: got exception during unlock: %@",
          _exception];
  return nil;
}
- (void)unlock {
  NS_DURING
    [[self lock] unlock];
  NS_HANDLER
    [self _handleUnlockException:localException];
  NS_ENDHANDLER;
}

- (NSDate *)lockDate {
  return [[self lock] lockDate];
}

/* exception */

- (void)resetLastException {
  [self->lastException release]; self->lastException = nil;
}
- (void)setLastException:(NSException *)_exc {
  ASSIGN(self->lastException, _exc);
}
- (NSException *)lastException {
  return self->lastException;
}

/* creating new URLs (this is used by OGoFileManagerFactory) */

+ (NSURL *)newURLForProjectBase:(NSString *)_base
  stringValue:(NSString *)url
  commandContext:(id)_ctx
{
  if (![url isNotNull])
    url = @"";
    
  if ([url length] > 0)
    return [NSURL URLWithString:url];
    
  return [[OGoFileManagerFactory sharedFileManagerFactory]
	                         newFileSystemURLWithContext:_ctx];
}

@end /* SkyFSFileManager */
