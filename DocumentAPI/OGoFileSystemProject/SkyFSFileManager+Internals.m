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
#include "SkyFSFileManager+Internals.h"
/*
  Defaults:
    SkyFSRepositoryPath
*/

@implementation SkyFSFileManager(Internals) 

- (NSString *)makeAbsoluteFS:(NSString *)_path {
  if (!_path)
    return nil;
  
  while ([_path hasPrefix:@"/"])
    _path = [_path substringWithRange:NSMakeRange(1, [_path length]-1)];
  
  while ([_path hasSuffix:@"/"])
    _path = [_path substringWithRange:NSMakeRange(0, [_path length]-1)];
  
  return [self->workingPath stringByAppendingPathComponent:_path];
}

- (NSString *)_makeAbsoluteInSky:(NSString *)_path {
  static Class NSStringClass = Nil;

  NSArray  *pathComponents;

#if LIB_FOUNDATION_LIBRARY // TODO: why is that?!
  _path = [_path stringByTrimmingWhiteSpaces];
#endif

  if (NSStringClass == Nil)
    NSStringClass = [NSString class];  
  if (![_path isKindOfClass:NSStringClass])
    return nil;
  
  if (_path == nil) {
    [self warnWithFormat:@"[%s]: missing path ", __PRETTY_FUNCTION__];
    [self setLastException:[SkyFSException reason:@"missing path"]];
    return nil;
  }
  _path = ([_path isAbsolutePath])
    ? _path
    : [[self currentDirectoryPath] stringByAppendingPathComponent:_path];
  
  if (![_path isNotEmpty])
    return @"/";

  while ([_path hasSuffix:@"/"]) {
    _path = [_path substringToIndex:[_path length] - 1];
  }
  pathComponents = [_path pathComponents];
  
  if ([_path rangeOfString:@"."].length > 0) { /* skip '.' and '..' entries */
    int cnt = 0;

    if ((cnt = [pathComponents count]) > 0) {
      int i          = 0;
      int pnCnt      = 0;
      id  *pathNames = NULL;

      pathNames          = calloc(cnt, sizeof(id));
      pathNames[pnCnt++] = @"/"; /* absolute path */

      for (i = 1; i < cnt; i++) {
        NSString *name = nil;

        name = [pathComponents objectAtIndex:i];
        if ([name isEqualToString:@"."] || ![name isNotEmpty])
        //        if ([name isEqualToString:@"."])        
          continue;
        if ([name isEqualToString:@".."]) {
          if (pnCnt > 1) /* first is '/' */
            pnCnt--;
          continue;
        }
        if ([name isEqualToString:[self attributesPath]]) {
          [self errorWithFormat:
		  @"(%s): try to read in internal skyrix structures ..."
                  @" _path %@", __PRETTY_FUNCTION__, _path];
          pnCnt = 0;
          break;
        }
        pathNames[pnCnt++] = name;
      }
      pathComponents = [NSArray arrayWithObjects:pathNames count:pnCnt];
      free(pathNames); pathNames = NULL;
    }
    else
      return @"/";
  }
  
  if ([pathComponents count] == 0)
    return @"/";
  
  return [NSString pathWithComponents:pathComponents];
}

- (NSString *)_makeAbsolute:(NSString *)_path {
  return [self makeAbsoluteFS:[self _makeAbsoluteInSky:_path]];
}

- (NSString *)_checkPath:(NSString *)_path {
  if ([_path rangeOfString:[self attributesPath]].length > 0) {
    NSDictionary *ui;
    NSException  *ex;
    
    ui = [NSDictionary dictionaryWithObjectsAndKeys:_path, @"path", nil];
    ex = [SkyFSException reason:@"attempty to use forbidden path"
			 userInfo:ui];
    [self setLastException:ex];
    return nil;
  }
  return _path;
}

- (NSString *)_reconvertPath:(NSString *)_path {
  NSString *str;
  int      pl, rl;

  pl = [_path length];
  rl = [self->workingPath length];

  if (pl < rl) {
    [self setLastException:
          [SkyFSException reason:@"unexpected path"
                          userInfo:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                                        _path, @"path",
                                        self->workingPath, @"workingPath",
                                        nil]]];
    [self errorWithFormat:@"[%s] unexpected path %@ repositoryPath %@",
          __PRETTY_FUNCTION__, _path, self->workingPath];
    return nil;
  }
  str = [_path substringWithRange:
               NSMakeRange(rl, pl-rl)];

  if (![str hasPrefix:@"/"]) {
    str = [@"/" stringByAppendingString:str];
  }
  return [self _checkPath:str];
}

static NSArray *FileSystemAttributes = nil;

- (NSArray *)fileSystemAttributes {
  if (FileSystemAttributes == nil) {
    FileSystemAttributes = [[NSArray alloc]
                                     initWithObjects:
                                     @"NSFileType", @"NSFileName",
                                     @"NSFilePath", @"NSFileMimeType",
                                     @"NSFileModificationDate",
                                     @"NSFileDeviceIdentifier",
                                     @"NSFileGroupOwnerAccountNumber",
                                     @"NSFileIdentifier",
                                     @"NSFileModificationDate",
                                     @"NSFilePosixPermissions",
                                     @"NSFileReferenceCount",
                                     @"NSFileSize",
                                     nil];
  }
  return FileSystemAttributes;
}

- (NSDictionary *)removeFileSystemAttributes:(NSDictionary *)_attrs {
  int ac = [_attrs count];
  id           objs[ac];
  id           keys[ac];
  int          objCnt = 0;
  NSEnumerator *enumerator;
  id           obj;
  NSArray      *fsAttr;

  if (![_attrs count])
    return [NSDictionary dictionary];
  
  fsAttr     = [self fileSystemAttributes];
  enumerator = [_attrs keyEnumerator];

  while ((obj = [enumerator nextObject])) {
    if (![fsAttr containsObject:obj]) {
      keys[objCnt]   = obj;
      objs[objCnt++] = [_attrs objectForKey:obj];
    }
  }
  return [NSDictionary dictionaryWithObjects:objs forKeys:keys count:objCnt];
}

- (NSString *)attributesPath {
  static NSString *SkyFSHiddenAttributesPath = nil;

  if (SkyFSHiddenAttributesPath == nil) {
    SkyFSHiddenAttributesPath =
      [[[[NSUserDefaults standardUserDefaults]
                       objectForKey:@"SkyFSHiddenAttributesPath"] stringValue]
                         retain];

    if (![SkyFSHiddenAttributesPath isNotEmpty])
      SkyFSHiddenAttributesPath = @".skyrix_attributes";
  }
  return SkyFSHiddenAttributesPath;
}

- (NSString *)pathForAttributeFile:(NSString *)_path
  createOnDemand:(BOOL)_create
{
  NSString *path;
  BOOL     isDir;

  path = [[_path stringByDeletingLastPathComponent]
                 stringByAppendingPathComponent:[self attributesPath]];

  if ([self->fileManager fileExistsAtPath:path isDirectory:&isDir]) {
    if (!isDir) {
      [self warnWithFormat:@"[%s] Attributes path is not a directory %@",
            __PRETTY_FUNCTION__, path];
      return nil;
    }
  }
  else if (_create) {
    if (![self->fileManager createDirectoryAtPath:path attributes:nil]) {
      [self warnWithFormat:@"[%s] could not create directory at path %@",
            __PRETTY_FUNCTION__, path];
      return nil;
    }
  }
  else {
    return nil;
  }
  return [[path stringByAppendingPathComponent:[_path lastPathComponent]]
                stringByAppendingPathExtension:@"plist"];
}

- (BOOL)_saveAttributes:(NSDictionary *)_attrs forPath:(NSString *)_path
  isNew:(BOOL)_new
{
  NSDictionary        *attrs;
  NSString            *attrsFilePath, *login;
  NSMutableDictionary *dict;
  NSNumber            *ownerId;

  attrs = [self removeFileSystemAttributes:_attrs];

  if (!(attrsFilePath =
        [self pathForAttributeFile:_path createOnDemand:YES])) {
    return NO;
  }

  dict = [[attrs mutableCopy] autorelease];
  ownerId = [self _loginId];
  login   = [self _loginName];
  
  if (_new) {
    [dict setObject:ownerId forKey:@"SkyFirstOwnerId"];
  }
#if !LIB_FOUNDATION_LIBRARY
  [dict setObject:ownerId forKey:NSFileOwnerAccountID];
#else
  [dict setObject:ownerId forKey:NSFileOwnerAccountNumber];
#endif
  [dict setObject:ownerId forKey:@"SkyOwnerId"];
  [dict setObject:login forKey:NSFileOwnerAccountName];

  return [dict writeToFile:attrsFilePath atomically:YES];
}

- (BOOL)_updateAttributes:(NSDictionary *)_attrs forPath:(NSString *)_path {
  NSMutableDictionary *mdict;
  NSDictionary        *attrs;

  attrs = [self removeFileSystemAttributes:_attrs];

  mdict = [[[self _attributesForPath:_path] mutableCopy] autorelease];
  [mdict addEntriesFromDictionary:attrs];
  return [self _saveAttributes:attrs forPath:_path isNew:NO];
}

- (BOOL)_removeAttributesForPath:(NSString *)_path {
  NSString *path;

  if ((path = [self pathForAttributeFile:_path createOnDemand:NO]))
    return [self->fileManager removeFileAtPath:path handler:nil];

  return YES;
}

- (NSDictionary *)_attributesForPath:(NSString *)_path {
  NSString *path;

  if ((path = [self pathForAttributeFile:_path createOnDemand:NO])) 
    return [NSDictionary dictionaryWithContentsOfFile:path];

  return [NSDictionary dictionary];
}

- (NSNumber *)_loginId {
  return [[self->context valueForKey:LSAccountKey] valueForKey:@"companyId"];
}
- (NSString *)_loginName {
  return [[self->context valueForKey:LSAccountKey] valueForKey:@"login"];
}

@end /* SkyFSFileManager(Internals) */
