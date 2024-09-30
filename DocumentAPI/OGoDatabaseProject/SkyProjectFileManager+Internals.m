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

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include <OGoProject/SkyContentHandler.h>

@class NSString, NSMutableArray, NSArray, EOGenericRecord, NGHashMap;
@class EOAdaptorChannel;

static NSDictionary *er_dict(int _i) {
  return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_i]
                       forKey:@"errorNumber"];
}

@interface SkyProjectFileManager(DeleteDocument)
- (BOOL)prepareDeletionOf:(NSDictionary *)_dict;
- (BOOL)deleteVersions:(NSDictionary *)_attrs
  filesToRemove:(NSMutableArray *)_array;
- (BOOL)deleteDocumentEditing:(NSDictionary *)_attrs
  filesToRemove:(NSMutableArray *)_array;
- (BOOL)deleteDoc:(NSDictionary *)_attrs;
- (BOOL)reallyDeleteFile:(NSDictionary *)_attrs;
- (void)removeAllFiles:(NSArray *)_files;
@end

@interface SkyProjectFileManager(ErrorHandling_Internals)
- (void)_initializeErrorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
- (NSDictionary *)errorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel doFlush:(BOOL)_cache
  doRollback:(BOOL)_doRollback;
@end /* SkyProjectFileManager(ErrorHandling+Internals) */

@interface SkyProjectFileManager(Locking_Internals)
- (NSArray *)allVersionAttributesAtPath:(NSString *)_path;
@end /* SkyProjectFileManager(Locking_Internals) */

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

@interface SkyProjectFileManagerCache(Internals)
- (NGHashMap *)parent2ChildDirectoriesCache;
- (EOAdaptorChannel *)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
@end /* SkyProjectFileManagerCache(Internals) */

@interface SkyProjectFileManager(Removing)
- (BOOL)_removeFileAttrs:(NSArray *)_paths handler:(id)_handler
  failed:(BOOL*)failed_;
- (BOOL)_removeFiles:(NSArray *)_fileAttrs handler:(id)_handler
  failed:(BOOL*)failed_;
- (BOOL)_removeDirs:(NSArray *)_dirAttr handler:(id)_handler failed:(BOOL*)failed_;
@end

#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include "common.h"

@implementation SkyProjectFileManager(Internals)

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

- (void)_checkCWDFor:(NSString *)_source { /* not 100% */
  if (self->cwd == @"/") 
    return;
  if (![self->cwd hasPrefix:_source])
    return;
  
  ASSIGN(self->cwd, @"/");
}

- (id)_project {
  return [self->cache project];
}

- (NSString *)_defaultCompleteProjectDocumentNamespace {
  return @"{http://www.skyrix.com/namespaces/project-document}";
}

- (NSArray *)subDirectoryNamesForPath:(NSString *)_path {
  return [[self->cache parent2ChildDirectoriesCache] objectsForKey:_path];
}

- (NSString *)_makeAbsolute:(NSString *)_path {
  static Class NSStringClass = Nil;
  NSString *version;
  NSString *path;
  NSArray  *pathComponents;
  
#if LIB_FOUNDATION_LIBRARY
  // TODO: hh asks: why is that?!
  _path = [_path stringByTrimmingWhiteSpaces];
#else
  if (![_path isNotNull])
    return nil;
#endif
  
  if (NSStringClass == Nil)
    NSStringClass = [NSString class];
  
  if (_path == nil) {
    NSLog(@"WARNING[%s]: missing path argument.", __PRETTY_FUNCTION__);
    return nil;
  }
  if (![_path isKindOfClass:NSStringClass])
    return nil;
  
  if ((version = [_path pathVersion]))
    _path = [_path stringByDeletingPathVersion];
  
  _path = ([_path isAbsolutePath] || ![_path isNotNull])
    ? _path
    : [[self currentDirectoryPath] stringByAppendingPathComponent:_path];
  
  if ([_path length] == 0)
    return @"/";
  
  while ([_path hasSuffix:@"/"]) {
    _path = [_path substringToIndex:([_path length] - 1)];
  }
  pathComponents = [_path pathComponents];
  
  if ([_path rangeOfString:@"."].length > 0) { /* skip '.' and '..' entries */
    int cnt = 0;

    if ((cnt = [pathComponents count]) > 0) {
      int i          = 0;
      int pnCnt      = 0;
      id  *pathNames = NULL;

      pathNames          = calloc(cnt + 1, sizeof(id));
      pathNames[pnCnt++] = @"/"; /* absolute path */

      for (i = 1; i < cnt; i++) {
        NSString *name = nil;

        name = [pathComponents objectAtIndex:i];
        if ([name isEqualToString:@"."] || ![name length])
        //        if ([name isEqualToString:@"."])        
          continue;
        if ([name isEqualToString:@".."]) {
          if (pnCnt > 1) /* first is '/' */
            pnCnt--;
          continue;
        }
        pathNames[pnCnt++] = name;
      }
      pathComponents = [NSArray arrayWithObjects:pathNames count:pnCnt];
      if (pathNames) free(pathNames); pathNames = NULL;
    }
    else
      return @"/";
  }
  if ([pathComponents count] == 0)
    return @"/";
  
  path = [NSString pathWithComponents:pathComponents];
  if (version)
    path = [path stringByAppendingPathVersion:version];
  
  return path;
}

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush
{
  int ec;

  if (_dirName == nil) 
    _dirName = (id)[NSNull null];

  if (![_dirExt isNotNull])
    _dirExt = (id)[NSNull null];
  else if (![_dirExt length])
    _dirExt = (id)[NSNull null];

  if (_doFlush)
    [self flush];
  
  NS_DURING {
    ec = 0;
    [[self context] runCommand:@"doc::set-folder",
         @"object",   _srcGen,
         @"title",    _dirName,
         @"fileType", _dirExt,
         @"folder",   _destGen, nil];
  }
  NS_HANDLER {
    [self setLastException:localException];
    ec = 13;
  }
  NS_ENDHANDLER;
  if (ec) {
    return [self _buildErrorWithSource:nil dest:nil msg:ec handler:_handler
                 cmd:_cmd];
  }
  return YES;
}

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handler
{
  return [self moveDir:_srcGen toPath:_destGen name:_dirName
               extension:_dirExt handler:_handler doFlush:YES];
}

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush
{
  int ec;
  
  if (_linkName == nil) 
    _linkName = (id)[NSNull null];

  if (![_linkExt isNotNull])
    _linkExt = (id)[NSNull null];
  else if (![_linkExt length])
    _linkExt = (id)[NSNull null];

  if (_doFlush)  
    [self flush];
  
  NS_DURING {
    ec = 0;
    [[self context] runCommand:@"doc::set-object-link",
         @"object",   _srcGen,
         @"title",    _linkName,
         @"fileType", _linkExt,
         @"folder",   _destGen, nil];
  }
  NS_HANDLER {
    ec = 14;
    [self setLastException:localException];
  }
  NS_ENDHANDLER;
  if (ec)
    return [self _buildErrorWithSource:nil dest:nil msg:ec handler:_handler
                 cmd:_cmd];
  return YES;
}

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler
{
  return [self moveLink:_srcGen toPath:_destGen name:_linkName extension:_linkExt
               handler:_handler doFlush:YES];
}

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush
{
  int      ec;
  BOOL     checkin;
  NSString *title, *ext;
  id       doc;

  title = [SkyProjectFileManager formatTitle:[_srcGen valueForKey:@"title"]];

  if (![title isNotNull])
    title = (id)[NSNull null];

  ext = [_srcGen valueForKey:@"fileType"];

  if (![ext isNotNull])
    ext = (id)[NSNull null];
  else if (![ext length])
    ext = (id)[NSNull null];
    
  if (![_fileName isNotNull]) 
    _fileName = (id)[NSNull null];

  if (_fileExt == nil || [_fileExt length] == 0)
    return [self _buildErrorWithSource:nil dest:nil msg:15
                 handler:_handler cmd:_cmd];

  if (_doFlush)
    [self flush];
  
  checkin = NO;
  doc     = nil;
  if (![_fileName isEqual:title] || ![_fileExt isEqual:ext]) {
    if ([[_srcGen valueForKey:@"status"] isEqualToString:@"released"]) {
      /* now checkout */
      checkin = YES;

      NS_DURING {
        ec      = 0;
        doc     = [[self context] runCommand:@"doc::checkout",
                       @"object", _srcGen, nil];
        _srcGen = [doc valueForKey:@"toDocumentEditing"];
      }
      NS_HANDLER {
        ec = 16;
        [self setLastException:localException];
      }
      NS_ENDHANDLER;
      if (ec)
        return [self _buildErrorWithSource:nil dest:nil msg:ec handler:_handler
                     cmd:_cmd];
    }
    NS_DURING {
      ec      = 0;
      if ([_srcGen isNotNull])
        _srcGen = [[self context] runCommand:@"doc::set",
                                  @"object", _srcGen,
                                  @"title", _fileName,
                                  @"fileType", _fileExt, nil];
      else
        ec = 4;
    }
    NS_HANDLER {
      ec = 17; 
      [self setLastException:localException];
    }
    NS_ENDHANDLER;
    if (ec)
      return [self _buildErrorWithSource:nil dest:nil msg:ec handler:_handler
                   cmd:_cmd];
  
    if (checkin) {
      NS_DURING {
        ec = 0;
        if ([doc isNotNull])
          [[self context] runCommand:@"doc::release", @"object", doc, nil];
        else
          ec = 4;
      }
      NS_HANDLER {
        ec = 18;
        [self setLastException:localException];
      }
      NS_ENDHANDLER;
      if (ec)
        return [self _buildErrorWithSource:nil dest:nil msg:ec handler:_handler
                     cmd:_cmd];
    }
  }
  if (doc == nil) {
    doc = (![[_srcGen entityName] isEqualToString:@"Doc"])
      ? [_srcGen valueForKey:@"toDoc"]
      : (id)_srcGen;
  }
  
  if (![[doc valueForKey:@"parentDocumentId"]
            isEqual:[_destGen valueForKey:@"documentId"]]) {
    NS_DURING {
      ec = 0;
      if ([doc isNotNull]) 
        [[self context] runCommand:@"doc::move", @"object", doc,
                        @"folder", _destGen, nil];
      else
        ec = 4;
    }
    NS_HANDLER {
      ec = 19;
      [self setLastException:localException];
    }
    NS_ENDHANDLER;
    if (ec)
      return [self _buildErrorWithSource:nil dest:nil msg:ec handler:_handler
                   cmd:_cmd];
  }
  return YES;
}

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
  handler:(id)_handler
{
  return [self moveFile:_srcGen toPath:_destGen name:_fileName extension:_fileExt
               handler:_handler doFlush:YES];
}

- (void)_subpathsAtPath:(NSString *)_path
  array:(NSMutableArray *)_array
{
  NSDictionary *attrs;

  if (_array == nil) {
    NSLog(@"ERROR[%s] internal inconsistency ...", __PRETTY_FUNCTION__);
    return;
  }
  attrs  = [self fileAttributesAtPath:_path traverseLink:NO];
  
  if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
    NSEnumerator *enumerator;
    NSDictionary *obj;

    enumerator = [[self->cache childAttributesAtPath:_path manager:self]
                               objectEnumerator];

    while ((obj = [enumerator nextObject])) {
      NSString *path;

      path = [obj objectForKey:NSFilePath];
      [_array addObject:path];
      if ([[obj objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
        [self _subpathsAtPath:path array:_array];
    }
  }
}

/* got absolute paths */
- (BOOL)_copyPath:(NSString*)_src
  toPath:(NSString*)_dest
  handler:(id)_handler
{
  BOOL         srcIsFolder;
  NSDictionary *attrs;
  NSEnumerator *enumerator;
  NSArray      *contents;

  srcIsFolder = NO;
  if (![self fileExistsAtPath:_src isDirectory:&srcIsFolder]) {
    return [self _buildErrorWithSource:_src dest:_dest msg:4 handler:_handler
                 cmd:_cmd];
  }
  if (!srcIsFolder) {
    return [self _buildErrorWithSource:_src dest:_dest msg:32 handler:_handler
                 cmd:_cmd];
  }
  if (!(_dest = [self _makeAbsolute:_dest])) {
    return [self _buildErrorWithSource:_dest dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if ([self fileExistsAtPath:_dest isDirectory:NULL]) {
    return [self _buildErrorWithSource:_src dest:_dest msg:7 handler:_handler
                 cmd:_cmd];
  }
  if (!(attrs = [self fileAttributesAtPath:_src traverseLink:NO])) {
    return [self _buildErrorWithSource:_src dest:_dest msg:6 handler:_handler
                 cmd:_cmd];
  }
  if (![self createDirectoryAtPath:_dest attributes:attrs]) {
    return NO;
  }
  contents   = [self->cache childAttributesAtPath:_src manager:self];
  enumerator = [contents objectEnumerator];
  {
    NSMutableDictionary *dict;
    id                  keys[3];

    keys[0] = @"contentHandler";
    keys[1] = @"attributes";
    keys[2] = @"sourceGID";
    dict    = [NSMutableDictionary dictionaryWithCapacity:[contents count]];

    while ((attrs = [enumerator nextObject])) {
      if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
        if (![self _copyPath:[attrs objectForKey:NSFilePath]
                   toPath:[_dest stringByAppendingPathComponent:
                                 [attrs objectForKey:NSFileName]] handler:_handler]) {
          return NO;
        }
      }
      else if ([[attrs objectForKey:NSFileType]
                       isEqualToString:NSFileTypeSymbolicLink]) {
        if (![self createSymbolicLinkAtPath:
                   [_dest stringByAppendingPathComponent:
                          [attrs objectForKey:NSFileName]]
                   pathContent:[attrs objectForKey:@"SkyLinkTarget"]])
          return NO;
                   
      }
      else if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
        NSDictionary *d;
        id vals[3];

        vals[0] = [self blobHandlerAtPath:[attrs objectForKey:NSFilePath]];
        vals[1] = attrs;
        vals[2] = [attrs objectForKey:@"globalID"];

        d       = [NSDictionary dictionaryWithObjects:vals forKeys:keys count:3];
        [dict setObject:d forKey:[attrs objectForKey:NSFileName]];
      }
    }
    if (![self createFiles:dict atPath:_dest]) {
      return NO;
    }
  }
  [self postChangeNotificationForPath:
        [_dest stringByDeletingLastPathComponent]];
  return YES;
}

@end /* SkyProjectFileManager(Internals) */

@implementation SkyProjectFileManager(ErrorHandling_Internals)

static NSDictionary *errorDict = NULL;

static NSNumber *num(int _i) {
  return [NSNumber numberWithInt:_i];
}

- (void)_initializeErrorDict {
  if (!errorDict) {
    errorDict =
      [[NSDictionary alloc]
                     initWithObjectsAndKeys:
                     @"try to move from/to version",                      num(1),
                     @"try to move root folder",                          num(2),
                     @"try to move do descendant",                        num(3),
                     @"missing source",                                   num(4),
                     @"missing destination",                              num(5),
                     @"source path doesn`t exist",                        num(6),
                     @"destination path already exist",                   num(7),
                     @"missing global id for parent folder",              num(8),
                     @"missing access for move",                          num(9),
                     @"only current owner or root can move edited files", num(10),
                     @"missing access for insert",                        num(11),
                     @"move failed",                                      num(12),
                     @"doc::set-folder failed",                           num(13),
                     @"doc::set-object-link failed",                      num(14),
                     @"missing path extension",                           num(15),
                     @"doc::checkout failed",                             num(16),
                     @"doc::set failed",                                  num(17),
                     @"doc::release failed",                              num(18),
                     @"doc::move failed",                                 num(19),
                     @"missing file",                                     num(20),
                     @"missing access for delete",                        num(21),
                     @"couldn`t delete",                                  num(22),
                     @"only current owner or root can delete edited files",
                     num(23),
                     @"path isn`t a directory",                           num(24),
                     @"couldn't create file",                             num(25),
                     @"missing target",                                   num(26),
                     @"missing directory",                                num(27),
                     @"couldn`t create link",                             num(28),
                     @"missing access for read",                          num(29),
                     @"directories or symbolic links has no content",     num(30),
                     @"try to copy do descendant",                        num(31),
                     @"source is a folder",                               num(32),
                     @"couldn't create directory",                        num(33),
                     @"missing path",                                     num(34),
                     @"missing access for write",                         num(35),
                     @"operation is not allowed for versions",            num(36),
                     @"only current owner or root can edit edited files", num(37),
                     @"unsupported file attributes",                      num(38),
                     @"missing doc",                                      num(39),
                     @"uncomplete document",                              num(40),
                     @"couldn`t autocreate document",                     num(41),
                     @"couldn`t delete tmp file after exception",         num(42),
                     @"missing propertymanager",                          num(43),
                     @"missing globalID",                                 num(44),
                     @"error during add properties",                      num(45),
                     @"error during delete properties",                   num(46),
                     @"error during update properties",                   num(47),
                     @"couldn`t checkout directory",                      num(48),
                     @"file is already in edit mode",                     num(49),
                     @"doc::checkout failed",                             num(50),
                     @"file is already released",                         num(51),
                     @"doc::release failed",                              num(52),
                     @"doc::reject failed",                               num(53),
                     @"missing version",                                  num(54),
                     @"documentversion::checkout failed",                 num(55),
                     @"missing blob name",                                num(56),
                     @"reject failed after doc::set failed",              num(57),
                     @"source path isn`t a directory",                    num(58),
                     @"destination path isn`t a directory",              num(59),
                     nil];
  }
}

- (NSDictionary *)errorDict {
  if (!errorDict)
    [self _initializeErrorDict];
  return errorDict;
}

static BOOL logError_value = NO;
static BOOL logError_flag  = NO;

static inline BOOL _logError(id self) {
  if (!logError_flag) {
    logError_flag  = YES;
    logError_value =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"SkyProjectFileManagerErrorLogEnabled"];
  }
  return logError_value;
}

static BOOL abortError_value = NO;
static BOOL abortError_flag  = NO;

static inline BOOL _abortError(id self) {
  if (!abortError_flag) {
    abortError_flag  = YES;
    abortError_value =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"SkyProjectFileManagerAbortOnErrors"];
  }
  return abortError_value;
}

- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel
{
  return [self _buildErrorWithSource:_src dest:_dest msg:_msgId handler:_handler
               cmd:_sel doFlush:YES doRollback:YES];
}

- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel doFlush:(BOOL)_doFlush
  doRollback:(BOOL)_doRollback
{
  NSString     *errMsg;

  self->lastErrorCode = _msgId;
  errMsg              = [[self errorDict] objectForKey:num(_msgId)];
  
  if (_handler != nil) {
    id           obj[3];
    id           key[3];
    int          cnt     = 0;
    NSDictionary *errMsg = nil;
    
    if (_src != nil) {
      obj[cnt] = _src;
      key[cnt] = @"Path";
      cnt++;
    }
    if (_dest != nil) {
      obj[cnt] = _dest;
      key[cnt] = @"toPath";
      cnt++;
    }
    if (errMsg != nil) {
      obj[cnt] = errMsg;
      key[cnt] = @"Error";
      cnt++;
    }
    if (_msgId) {
      obj[cnt] = num(_msgId);
      key[cnt] = @"ErrorCode";
      cnt++;
    }
    errMsg = [NSDictionary dictionaryWithObjects:obj forKeys:key count:cnt];

    if ([_handler respondsToSelector:
                  @selector(fileManager:shouldProceedAfterError:)]) {
      if ([_handler fileManager:(id)self shouldProceedAfterError:errMsg]) {
        return YES;
      }
    }
  }
  if (_logError(self) || _abortError(self)) {
    NSLog(@"ERROR(%@): _src <%@> _dest <%@> msgCode <%d> msg <%@> "
          @"handler <%@> exception: %@",
	  NSStringFromSelector(_sel), _src, _dest,
          _msgId, errMsg, _handler, self->lastException);
  }
  if (_abortError(self))
    abort();
  
  if (_doRollback)
    [self->cache rollbackTransaction];

  if (_doFlush)
    [self flush];
  
  return NO;
}

@end /* SkyProjectFileManager(ErrorHandling+Internals) */

@implementation SkyProjectFileManager(Locking_Internals)

- (NSArray *)allVersionAttributesAtPath:(NSString *)_path {
  return [self->cache allVersionAttrsAtPath:_path manager:self];
}

@end /* SkyProjectFileManager(Locking_Internals) */

@implementation SkyProjectFileManager(Removing)

- (BOOL)_removeFileAttrs:(NSArray *)_paths handler:(id)_handler failed:(BOOL*)failed_
{
  NSMutableArray *files;
  NSMutableArray *dirs;
  NSEnumerator   *enumerator;
  NSDictionary   *attrs;

  enumerator = [_paths objectEnumerator];

  files = [NSMutableArray array];
  dirs  = [NSMutableArray array];
  
  while ((attrs = [enumerator nextObject])) {

    if ([[attrs objectForKey:NSFileType] isEqual:NSFileTypeDirectory]) {
      [dirs addObject:attrs];
    }
    else {
      [files addObject:attrs];
    }
  }
  if (![self _removeFiles:files handler:_handler failed:failed_]) {
    return NO;
  }
  if (![self _removeDirs:dirs handler:_handler failed:failed_]) {
    return NO;
  }
  return YES;
}

- (BOOL)_removeFiles:(NSArray *)_fileAttrs handler:(id)_handler failed:(BOOL*)failed_
{
  NSEnumerator *enumerator;
  NSDictionary *attrs;
  id           handler;

  if (failed_)
    *failed_ = NO;
  
  handler = nil;
  if ([_handler respondsToSelector:
                @selector(fileManager:shouldProceedAfterError:)]) {
    handler = _handler;
  }
    
  enumerator = [_fileAttrs objectEnumerator];

  while ((attrs = [enumerator nextObject])) {
    NSString *_path;
    int      ec;

    _path = [attrs objectForKey:NSFilePath];
    
    if ([[attrs objectForKey:@"SkyStatus"] isEqualToString:@"edited"]) {
      id a, aid;

      a   = [[self context] valueForKey:LSAccountKey];
      aid = [a valueForKey:@"companyId"];

      if (![[attrs objectForKey:@"SkyOwnerId"] isEqual:aid] &&
          ([aid intValue] != 10000)) {
        if (![handler fileManager:(id)self 
		      shouldProceedAfterError:er_dict(23)]) {
          return NO;
        }
        if (failed_)
          *failed_ = YES;

        return YES;
      }
    }
    NS_DURING {
      ec = 0;
#if 1
      if (![self reallyDeleteFile:attrs])
        ec = 22;
#else
      id d;
      if ((d = [self->cache genericRecordForAttrs:attrs manager:self])) {

        if ([[d entityName] isEqualToString:@"DocumentEditing"]) {
          d = [d valueForKey:@"toDoc"];
        }
        [[self context] runCommand:@"doc::delete",
                        @"object", d,
                        @"reallyDelete", [NSNumber numberWithBool:YES], nil];
      }
      else {
        ec = 22;
      }
#endif    
    }
    NS_HANDLER {
      ec = 22;
      [self setLastException:localException];
      [self _buildErrorWithSource:_path dest:nil msg:ec handler:_handler
            cmd:_cmd];
    }
    NS_ENDHANDLER;

    if (ec) {
      if (![_handler fileManager:(id)self shouldProceedAfterError:er_dict(23)]) {
        return NO;
      }
      if (failed_)
        *failed_ = YES;
    }
    [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
    [self postUnvalidateNotificationForPath:_path];
    [self postSkyGlobalIDWasDeleted:[attrs objectForKey:@"globalID"]];
  }
  return YES;
}

- (BOOL)_removeDirs:(NSArray *)_dirAttr handler:(id)_handler failed:(BOOL*)failed_ {
  NSEnumerator   *enumerator;
  NSDictionary   *attrs;
  NSMutableArray *dirs;

  #if 0 // hh(2024-09-19): unused, maybe it should be used below?
  id handler = nil;
  if ([_handler respondsToSelector:
                @selector(fileManager:shouldProceedAfterError:)]) {
    handler = _handler;
  }
  #endif

  dirs       = [NSMutableArray arrayWithCapacity:[_dirAttr count]];
  enumerator = [_dirAttr objectEnumerator];

  while ((attrs = [enumerator nextObject])) {
    NSArray *files;
    BOOL    failed;

    files = [self->cache childAttributesAtPath:[attrs objectForKey:NSFilePath]
                 manager:self];

    if (![self _removeFileAttrs:files handler:_handler failed:&failed])
      return NO;

    if (failed)
      continue;

    [dirs addObject:attrs];
  }
  return [self _removeFiles:dirs handler:_handler failed:failed_];
}

@end /* SkyProjectFileManager(Removing) */
