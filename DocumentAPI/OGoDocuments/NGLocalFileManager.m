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

#include "NGLocalFileManager.h"
#include "NGLocalFileDataSource.h"
#include "NGLocalFileGlobalID.h"
#include "NGLocalFileDocument.h"
#include <Foundation/Foundation.h>
#include <NGExtensions/NGExtensions.h>
#include <NGExtensions/NGFileManager.h>
#include <NGExtensions/NSFileManager+Extensions.h>
#include <NGExtensions/NGPropertyListParser.h>
#include "common.h"

#ifndef LIB_FOUNDATION_LIBRARY
@interface NSObject(SubclassResp)
- (void)notImplemented:(SEL)_sel;
@end
#endif

// #define PROF 1

@implementation NGLocalFileManager

static BOOL logPathTranslation = NO;
static NSNull *null = nil;

- (id)initWithRootPath:(NSString *)_root allowModifications:(BOOL)_allow {
  if (null == nil) null = [[NSNull null] retain];
  
  if ((self = [super init])) {
    BOOL d;

    if (_root == nil) {
      [self release]; self = nil;
      return nil;
    }

    self->fm = [[NSFileManager defaultManager] retain];
    
    if ([_root isAbsolutePath]) {
      self->rootPath = [_root copy];
    }
    else {
      NSString *cd;

      cd = [self->fm currentDirectoryPath];
      self->rootPath = [[cd stringByAppendingPathComponent2:_root] copy];
    }
    
    if (![self->fm fileExistsAtPath:self->rootPath isDirectory:&d] || !d) {
      [self release]; self = nil;
      return nil;
    }
    
    self->cdp = @"/";
    
    if ((self->allowModifications = _allow)) {
      self->pathToDoc =
        [[NSMutableDictionary alloc] initWithCapacity:1024];
      self->pathToDirList = 
        [[NSMutableDictionary alloc] initWithCapacity:200];
      self->pathExists = 
        [[NSMutableDictionary alloc] initWithCapacity:1024];
    }
  }
  return self;
}

- (void)dealloc {
  [self->pathToDirList release];
  [self->pathExists    release];
  [self->pathToDoc     release];
  [self->rootPath      release];
  [self->cdp           release];
  [self->fm            release];
  [super dealloc];
}

/* caches */

- (void)flush {
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"flushing cache ...");
  [self->pathToDoc removeAllObjects];
  [pool release];
}

/* path translation */

- (NSString *)_makeAbsolutePath:(NSString *)_path {
  if (logPathTranslation) [self logWithFormat:@"make absolute: %@", _path];
  if (![_path isAbsolutePath])
    _path = [self->cwd stringByAppendingPathComponent2:_path];
  if (logPathTranslation) [self logWithFormat:@"  path: %@", _path];
  _path = [self standardizePath:_path];
  if (logPathTranslation) [self logWithFormat:@"  standardized: %@", _path];
  return _path;
}

- (NSString *)_translatePathToSource:(NSString *)_path {
  NSString *translatedPath;
  
  if (logPathTranslation) [self logWithFormat:@"translate: %@", _path];
  if ([_path length] == 0) return _path;
  
  if (![_path isAbsolutePath])
    _path = [self _makeAbsolutePath:_path];
  
  if (logPathTranslation) {
    [self logWithFormat:@"  path: %@", _path];
    [self logWithFormat:@"  root: %@", self->rootPath];
  }
  translatedPath = [self->rootPath stringByAppendingString:_path];
  if (logPathTranslation)
    [self logWithFormat:@"  translated: %@", translatedPath];
  return translatedPath;
}

// Directory operations

- (BOOL)changeCurrentDirectoryPath:(NSString*)_path {
  NSString *p  = nil;
  NSString *p2 = nil;

  p  = [self->cdp stringByAppendingPathComponent2:_path];
  p2 = [self->rootPath stringByAppendingString:p];

  if ([self->fm changeCurrentDirectoryPath:p2]) {
    ASSIGN(self->cdp, p);
    return YES;
  }
  return NO;
}

- (BOOL)createDirectoryAtPath:(NSString*)_path
  attributes:(NSDictionary*)_attributes
{
  NSString *p = nil;

  if (self->allowModifications == NO) return NO;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm createDirectoryAtPath:p attributes:_attributes];
}

- (NSString*)currentDirectoryPath {
  return self->cdp;
}

// File operations

- (BOOL)copyPath:(NSString *)_source
  toPath:(NSString *)_destination
  handler:(id)_handler
{
  NSString *p  = nil;
  NSString *p2 = nil;

  if (self->allowModifications == NO) return NO;

  p  = [self->rootPath stringByAppendingString:
            [self->cdp stringByAppendingPathComponent2:_source]];
  p2 = [self->rootPath stringByAppendingString:
            [self->cdp stringByAppendingPathComponent2:_destination]];
  return [self->fm copyPath:p toPath:p2 handler:_handler];
}

- (BOOL)movePath:(NSString *)_source
          toPath:(NSString *)_destination 
         handler:(id)_handler
{
  NSString *p  = nil;
  NSString *p2 = nil;

  p  = [self->rootPath stringByAppendingString:
            [self->cdp stringByAppendingPathComponent2:_source]];
  p2 = [self->rootPath stringByAppendingString:
            [self->cdp stringByAppendingPathComponent2:_destination]];
  return [self->fm movePath:p toPath:p2 handler:_handler];
}

- (BOOL)linkPath:(NSString *)_source
  toPath:(NSString *)_destination
  handler:(id)_handler
{
  NSString *p  = nil;
  NSString *p2 = nil;

  if (self->allowModifications == NO) return NO;

  p  = [self->rootPath stringByAppendingString:
            [self->cdp stringByAppendingPathComponent2:_source]];
  p2 = [self->rootPath stringByAppendingString:
            [self->cdp stringByAppendingPathComponent2:_destination]];
  return [self->fm linkPath:p toPath:p2 handler:_handler];
}

- (BOOL)removeFileAtPath:(NSString *)_path handler:(id)_handler {
  NSString *p  = nil;

  if (self->allowModifications == NO) return NO;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm removeFileAtPath:p handler:_handler];
}

- (BOOL)createFileAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attributes
{
  NSString *p = nil;

  if (self->allowModifications == NO) return NO;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm createFileAtPath:p contents:_contents
              attributes:_attributes];
}

// Getting and comparing file contents	

- (NSData *)contentsAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm contentsAtPath:p];
}

- (BOOL)contentsEqualAtPath:(NSString *)_path1 andPath:(NSString *)_path2 {
  NSString *p  = nil;
  NSString *p2 = nil;
  
  p  = [self _translatePathToSource:_path1];
  p2 = [self _translatePathToSource:_path2];
  return [self->fm contentsEqualAtPath:p andPath:p2];
}

/* Determining access to files */

- (BOOL)fileExistsAtPath:(NSString *)_path {
  NSString *srcPath;
  BOOL ok;
  id   tmp;
  
  _path = [self _makeAbsolutePath:_path];
  if ((tmp = [self->pathExists objectForKey:_path])) {
    if (![tmp isNotNull])
      return NO;
    else
      return YES;
  }
  
  srcPath = [self _translatePathToSource:_path];
  
  if (self->pathExists) {
    BOOL dummy = NO;
    /* use that, since cache stores the type as well ! */
    ok = [self fileExistsAtPath:_path isDirectory:&dummy];
  }
  else
    ok = [self->fm fileExistsAtPath:srcPath];
  
  return ok;
}

- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL *)_isDirectory {
  NSString *srcPath;
  NSString *tmp;
  BOOL     isDir = NO, ok;
  
  _path = [self _makeAbsolutePath:_path];
  if ((tmp = [self->pathExists objectForKey:_path])) {
    if (![tmp isNotNull])
      return NO;
    else {
      if (_isDirectory) {
        if ([tmp isEqualToString:NSFileTypeDirectory])
          *_isDirectory = YES;
        else
          *_isDirectory = NO;
      }
      return YES;
    }
  }

  srcPath = [self _translatePathToSource:_path];
  ok = [self->fm fileExistsAtPath:srcPath isDirectory:&isDir];
  
  if (self->pathExists) {
    if (!ok)
      [self->pathExists setObject:null forKey:_path];
    else if (isDir)
      [self->pathExists setObject:NSFileTypeDirectory forKey:_path];
    else
      [self->pathExists setObject:NSFileTypeRegular forKey:_path];
  }
  
  if (_isDirectory)
    *_isDirectory = isDir;
  return ok;
}

- (BOOL)isInsertableDirectoryAtPath:(NSString *)_path { 
  return [self isWritableFileAtPath:_path];
}

- (BOOL)isReadableFileAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm isReadableFileAtPath:p];
}

- (BOOL)isWritableFileAtPath:(NSString *)_path {
  NSString *p = nil;

  if (self->allowModifications == NO) return NO;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm isWritableFileAtPath:p];
}

- (BOOL)isExecutableFileAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm isExecutableFileAtPath:p];
}

- (BOOL)isDeletableFileAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm isDeletableFileAtPath:p];
}

// Getting and setting attributes

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_flag
  useAttributesFile:(BOOL)_use
{
  NSString            *p      = nil;
  NSString            *p2     = nil;
  NSString            *p3     = nil;
  NSString            *lp     = nil;
  NSDictionary        *attr   = nil;
  NSDictionary        *attr2  = nil;
  NSMutableDictionary *result = nil;

  p     = [self->rootPath stringByAppendingString:
               [self->cdp stringByAppendingPathComponent2:_path]];
  lp    = [p lastPathComponent];
  p2    = [p stringByDeletingLastPathComponent];
  result = [[NSMutableDictionary alloc] initWithCapacity:8];
  if (_use) {
    p3   = [p2 stringByAppendingPathComponent:@".attributes.plist"];
    attr = [NSDictionary skyDictionaryWithContentsOfFile:p3];
    attr = [attr objectForKey:lp];
    [result addEntriesFromDictionary:attr];
  }
  attr2 = [self->fm fileAttributesAtPath:p traverseLink:_flag];
  if (attr2 != nil)
    [result addEntriesFromDictionary:attr2];
  
  [result setObject:[self->cdp stringByAppendingPathComponent2:_path]
          forKey:@"NSFilePath"];
  [result setObject:lp forKey:@"NSFileName"];

#if DEBUG && PROF
  printf("%s %s %0.5fs\n", __PRETTY_FUNCTION__, [_path cString],
         [[NSDate date] timeIntervalSinceDate:st]);
#endif

  return [result autorelease];
}
- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_flag
{
  return [self fileAttributesAtPath:_path
               traverseLink:_flag
               useAttributesFile:YES];
}

- (NSDictionary *)fileSystemAttributesAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm fileSystemAttributesAtPath:p];
}

- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path
{
  NSString *p = nil;

  if (self->allowModifications == NO) return NO;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm changeFileAttributes:_attributes atPath:p];
}

// Discovering directory contents

- (NSArray *)directoryContentsAtPath:(NSString *)_path {
  NSArray      *contents = nil;
  NSString     *p  = nil;
  NSEnumerator *enumer = nil;
  NSString     *s;
  NSAutoreleasePool *pool;
  
  _path = [self _makeAbsolutePath:_path];
  
  if (self->pathToDirList) {
    if ((contents = [self->pathToDirList objectForKey:_path]))
      return contents;
  }
  
  pool = [[NSAutoreleasePool alloc] init];

  p = [self _translatePathToSource:_path];
  
  enumer = [[self->fm directoryContentsAtPath:p] objectEnumerator];
  
  contents = [NSMutableArray arrayWithCapacity:16];
  while ((s = [enumer nextObject])) {
    if (!([s hasPrefix:@".attributes."] && [s hasSuffix:@".plist"]))
      [(NSMutableArray *)contents addObject:s];
  }
  
  contents = [contents copy];
  [self->pathToDirList setObject:contents forKey:_path];
  [pool release];
  
  return [contents autorelease];
}

- (NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm enumeratorAtPath:p];
}

- (NSArray *)subpathsAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm subpathsAtPath:p];
}

// Symbolic-link operations

- (BOOL)createSymbolicLinkAtPath:(NSString *)_path
  pathContent:(NSString *)_otherPath
{
  return NO;
}

- (NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm pathContentOfSymbolicLinkAtPath:p];
}

// Converting file-system representations
- (const char *)fileSystemRepresentationWithPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  return [self->fm fileSystemRepresentationWithPath:p];
}

- (NSString *)stringWithFileSystemRepresentation:(const char *)_string
  length:(unsigned int)_len
{
  return [self->fm stringWithFileSystemRepresentation:_string length:_len];
}

/* feature check */

- (BOOL)supportsVersioningAtPath:(NSString *)_path {
  return NO;
}

- (BOOL)supportsLockingAtPath:(NSString *)_path {
  return NO;
}

- (BOOL)supportsFolderDataSourceAtPath:(NSString *)_path {
  return YES;
}

- (BOOL)supportsFeature:(NSString *)_featureURI atPath:(NSString *)_path {
  #if 0 // HH(2024-09-18): path unused, correct or bug?
  NSString *p = nil;

  p = [self->rootPath stringByAppendingString:
           [self->cdp stringByAppendingPathComponent2:_path]];
  #endif
  return [self->fm supportsFeature:_featureURI atPath:_path];
}

/* datasources */

- (EODataSource *)dataSourceAtPath:(NSString *)_path {
  NSString *p = nil;

  p = [self->cdp stringByAppendingPathComponent2:_path];
  return [[[NGLocalFileDataSource alloc] initWithPath:p fileManager:self] 
           autorelease];
}

- (EODataSource *)dataSource {
  return [self dataSourceAtPath:[self currentDirectoryPath]];
}

/* writing */

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path {
  BOOL isDir;

  if (self->allowModifications == NO) return NO;

  if ([self fileExistsAtPath:_path isDirectory:&isDir]) {
    if (isDir || ![self isDeletableFileAtPath:_path]) {
      return NO;
    }
    else {
      if ([self removeFileAtPath:_path handler:nil] == NO) {
        return NO;
      }
    }
  }
  return [self createFileAtPath:_path contents:_content attributes:nil];
}

/* global-IDs */

- (EOGlobalID *)globalIDForPath:(NSString *)_path {
  NGLocalFileGlobalID *gid     = nil;
  NSString       *absPath = nil;

  absPath = [self->cdp stringByAppendingPathComponent2:_path];
  gid = [[NGLocalFileGlobalID alloc] initWithPath:absPath
                                     rootPath:self->rootPath];

  return [gid autorelease];

#if 0 /* why is this commented out ?? */
  NSString *p = nil;
  id       keys[2];

  p = [self->cdp stringByAppendingPathComponent2:_path];
  keys[0] = self->rootPath;
  keys[1] = p;
  NSLog(@"%@ %@", self->rootPath, p);
  return [EOKeyGlobalID globalIDWithEntityName:@"Path" keys:keys
                        keyCount:2 zone:nil];
#endif
}

- (NSString *)pathForGlobalID:(EOGlobalID *)_gid {
  id *keys;

  if (_gid == nil || [(EOKeyGlobalID *)_gid keyCount] != 2 ||
      ![[_gid entityName] isEqualToString:@"Path"]) {
    return nil;
  }

  keys = [(EOKeyGlobalID *)_gid keyValues];
  if (![keys[0] isEqualToString:self->rootPath])
    return nil;

  return keys[1];
}

/* trash */

- (BOOL)supportsTrashFolderAtPath:(NSString *)_path {
  return NO;
}
- (NSString *)trashFolderForPath:(NSString *)_path {
  return nil;
}

/* documents */

- (NGLocalFileDocument *)documentAtPath:(NSString *)_path {
  NGLocalFileDocument *doc;
  
  _path = [self _makeAbsolutePath:_path];
  if ((doc = [self->pathToDoc objectForKey:_path]))
    return doc;
  if (![self fileExistsAtPath:_path])
    return nil;
  
  doc = [[NGLocalFileDocument alloc] initWithPath:_path fileManager:self];
  
  if (doc)
    [self->pathToDoc setObject:doc forKey:_path];
  
  return [doc autorelease];
}

- (BOOL)writeDocument:(NGLocalFileDocument *)_doc toPath:(NSString *)_path {
  if (self->allowModifications == NO) return NO;

  // TODO: implement
  [self notImplemented:_cmd];
  return NO;
}

- (NGLocalFileDocument *)createDocumentAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs
{
  if (self->allowModifications == NO) return NO;

  if ([self createFileAtPath:_path contents:_contents attributes:_attrs])
    return [self documentAtPath:_path];
  
  return nil;
}

- (BOOL)deleteDocument:(NGLocalFileDocument *)_doc {
  if (self->allowModifications == NO) return NO;

  return NO;
}

- (BOOL)updateDocument:(NGLocalFileDocument *)_doc {
  if (self->allowModifications == NO) return NO;
  
  // TODO: implement
  return NO;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NGLocalFileManager root='%@'>",
                   self->rootPath, self->cdp];
}

@end /* NGLocalFileManager */

@implementation NSString(NGLocalFileManager)

/*
   stringByAppendingPathComponent2 is like stringByAppendingPathComponent
   but it also handles absolute _path and ".."
*/
- (NSString *)stringByAppendingPathComponent2:(NSString *)_path {
  NSArray        *pcs;
  unsigned int   i;
  NSMutableArray *pcs2;
  NSString       *result;

  if (_path == nil)
    return self;

  pcs = [_path pathComponents];

  if (![_path isAbsolutePath])
    pcs = [[self pathComponents] arrayByAddingObjectsFromArray:pcs];

  pcs2 = [[NSMutableArray alloc] initWithCapacity:4];

  for (i = 0; i < [pcs count]; i++) {
    NSString *pc = [pcs objectAtIndex:i];

    if ([pc length] == 0 || [pc isEqualToString:@"."] ||
        ([pc isEqualToString:@"/"] && [pcs2 count] > 0)) {
      continue;
    }
    else if ([pc isEqualToString:@".."]) {
      if ([pcs2 count] > 0 && ![[pcs2 lastObject] isEqualToString:@"/"]) {
        [pcs2 removeLastObject];
      }
    }
    else {
      [pcs2 addObject:pc];
    }
  }

  result = [NSString pathWithComponents:pcs2];
  [pcs2 release];
  return result;
}

@end /* NSString(NGLocalFileManager) */
