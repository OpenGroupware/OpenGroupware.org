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
#include "NGFileManagerZipTool.h"
#include "NGUnixTool.h"

@implementation NGFileManagerZipTool

- (NSException *)zipPath:(NSString *)_srcPath
  toPath:(NSString *)_toPath
  compressionLevel:(int)_level
{
  return [self zipPaths:[NSArray arrayWithObject:_srcPath] toPath:_toPath
               compressionLevel:_level];
}

- (NSException *)zipPaths:(NSArray *)_srcPaths
  toPath:(NSString *)_toPath
  compressionLevel:(int)_level
{
  id<NSObject,NGFileManager> oldTargetFm = nil;
  NSFileManager              *localFm    = nil;
  NSString                   *tmpPath    = nil;
  NGUnixTool                 *unixTool   = nil;
  NSData                     *zipData    = nil;
  NSEnumerator               *enumer     = nil;
  NSString                   *srcPath    = nil;
  BOOL                       isDir;

  localFm     = [NSFileManager defaultManager];
  unixTool    = [[NGUnixTool alloc] init];
  tmpPath     = [unixTool _uniquePath];
  [localFm createDirectoryAtPath:tmpPath attributes:nil];

  oldTargetFm = [self targetFileManager];
  [self setTargetFileManager:(id<NSObject,NGFileManager>)localFm];

  enumer      = [_srcPaths objectEnumerator];
  while ((srcPath = [enumer nextObject])) {
    [self copyPath:srcPath toPath:tmpPath handler:nil];
  }

  [self setTargetFileManager:oldTargetFm];

  zipData     = [self dataByZippingLocalPath:tmpPath compressionLevel:_level];
  [unixTool _removeLocalPath:tmpPath];
  RELEASE(unixTool);

  if ([[self targetFileManager] fileExistsAtPath:_toPath isDirectory:&isDir]) {
    if ([[self targetFileManager] isWritableFileAtPath:_toPath]) {
      if (![[self targetFileManager] writeContents:zipData atPath:_toPath]) {
        return [NSException exceptionWithName:@"cannotwritetozipfile"
                            reason:@"can not write to zip file" userInfo:nil];
      }
    }
    else {
      return [NSException exceptionWithName:@"zipfileNotWritable"
                          reason:@"zip file is not writable" userInfo:nil];
    }
  }
  else {
    if ([[self targetFileManager] createFileAtPath:_toPath contents:zipData
                                  attributes:nil] == NO) {
      return [NSException exceptionWithName:@"zipfileNotCreatable"
                          reason:@"can not create zip file" userInfo:nil];
    }
  }

  return nil;
}

- (NSData *)dataByZippingLocalPath:(NSString *)_path
  compressionLevel:(int)_level
{
  NSFileHandle  *nullHandle  = nil;
  NSFileHandle  *zipHandle   = nil;
  NSPipe        *zipPipe     = nil;
  NSTask        *zipTask     = nil;
  NSData        *result      = nil;
  NSString      *compression = nil;

  // man zip writes, 6 is the default value
  compression = [NSString stringWithFormat:
                          @"-%d", (_level < 0 || _level > 9) ? 6 : _level];

  zipPipe    = [NSPipe pipe];
  zipHandle  = [zipPipe fileHandleForReading];
  nullHandle = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
  zipTask    = [[NSTask alloc] init];
  [zipTask setLaunchPath:[NGUnixTool pathToZipTool]];
  [zipTask setCurrentDirectoryPath:_path];
  [zipTask setArguments:
           [NSArray arrayWithObjects:@"-qr", compression, @"-", @".", nil]];
  [zipTask setStandardOutput:zipPipe];
  [zipTask setStandardError:nullHandle];
  [zipTask launch];

  result     = [zipHandle readDataToEndOfFile];

  RELEASE(zipTask);
  return result;
}

@end /* NGFileManagerZipTool */


@implementation NGFileManagerUnzipTool

- (NSException *)unzipPath:_zipfile toPath:_toPath {
  NSData *zipData = nil;

  zipData = [[self sourceFileManager] contentsAtPath:_zipfile];
  NSAssert([zipData length], @"zipfile contains no data");
  [self unzipData:zipData toPath:_toPath];

  return nil;
}

- (NSException *)unzipData:(NSData *)_data toPath:_toPath {
  id<NSObject,NGFileManager> oldSourceFm  = nil;
  NSFileManager              *localFm     = nil;
  NGUnixTool                 *unixTool    = nil;
  NSString                   *tmpPath     = nil;
  NSString                   *tmpZipFile  = nil;
  NSFileHandle               *nullHandle  = nil;
  NSTask                     *unzipTask   = nil;
  int                        result;

  localFm     = [NSFileManager defaultManager];
  unixTool    = [[NGUnixTool alloc] init];
  tmpPath     = [unixTool _uniquePath];
  tmpZipFile  = [[unixTool _uniquePath] stringByAppendingPathExtension:@"zip"];
  [localFm createDirectoryAtPath:tmpPath attributes:nil];
  [localFm createFileAtPath:tmpZipFile contents:_data attributes:nil];

  nullHandle  = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
  unzipTask   = [[NSTask alloc] init];
  [unzipTask setLaunchPath:[NGUnixTool pathToUnzipTool]];
  [unzipTask setCurrentDirectoryPath:tmpPath];
  [unzipTask setArguments:[NSArray arrayWithObject:tmpZipFile]];
  [unzipTask setStandardOutput:nullHandle];
  [unzipTask setStandardError:nullHandle];
  [unzipTask launch];
  if ([unzipTask isRunning]) [unzipTask waitUntilExit];
  result      = [unzipTask terminationStatus];

  oldSourceFm = [self sourceFileManager];
  [self setSourceFileManager:(id<NSObject,NGFileManager>)localFm];
  [self copyPath:[tmpPath stringByAppendingPathComponent:@"*"]
        toPath:_toPath handler:nil];
  [self setSourceFileManager:oldSourceFm];

  [unixTool _removeLocalPath:tmpPath];
  [localFm removeFileAtPath:tmpZipFile handler:nil];

  RELEASE(unixTool);
  RELEASE(unzipTask);

  if (result != 0) {
    return [NSException exceptionWithName:@"unzipFailure"
                        reason:@"an error occured while running unzip"
                        userInfo:nil];
  }
  return nil;
}

@end /* NGFileManagerUnzipTool */

@implementation NGFileManagerZipInfo

- (void)dealloc {
  RELEASE(self->fileManager);
  [super dealloc];
}

- (void)setFileManager:(id<NSObject,NGFileManager>)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id<NSObject,NGFileManager>)fileManager {
  return self->fileManager;
}

- (NSDictionary *)infoOnZippedData:(NSData *)_data {
  NSString            *tmpZipFile    = nil;
  NSFileManager       *localFm       = nil;
  NGUnixTool          *unixTool      = nil;
  NSTask              *zipInfoTask   = nil;
  NSPipe              *zipInfoPipe   = nil;
  NSFileHandle        *zipInfoHandle = nil;
  NSFileHandle        *nullHandle    = nil;
  NSData              *infoData      = nil;
  NSString            *tmpString     = nil;
  NSEnumerator        *enumer        = nil;
  NSString            *infoString    = nil;
  NSMutableDictionary *info          = nil;
  int                 result;

  localFm       = [NSFileManager defaultManager];
  unixTool      = [[NGUnixTool alloc] init];
  tmpZipFile    = [[unixTool _uniquePath]
                             stringByAppendingPathExtension:@"zip"];
  [localFm createFileAtPath:tmpZipFile contents:_data attributes:nil];

  info          = [[NSMutableDictionary alloc] init];

  zipInfoPipe   = [NSPipe pipe];
  zipInfoHandle = [zipInfoPipe fileHandleForReading];
  nullHandle    = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];

  zipInfoTask   = [[NSTask alloc] init];
  [zipInfoTask setLaunchPath:[NGUnixTool pathToZipInfoTool]];
  [zipInfoTask setArguments:[NSArray arrayWithObject:tmpZipFile]];
  [zipInfoTask setStandardOutput:zipInfoPipe];
  [zipInfoTask setStandardError:nullHandle];
  [zipInfoTask launch];
  
  infoData = [zipInfoHandle readDataToEndOfFile];
  
  if ([zipInfoTask isRunning])
    [zipInfoTask waitUntilExit];
  
  result = [zipInfoTask terminationStatus];
  
  RELEASE(zipInfoTask); zipInfoTask = nil;
  RELEASE(unixTool);    unixTool    = nil;

  tmpString     =
    [[NSString alloc] initWithData:infoData
                      encoding:[NSString defaultCStringEncoding]];
  enumer        = [[tmpString componentsSeparatedByString:@"\n"]
                          objectEnumerator];
  RELEASE(tmpString); tmpString = nil;

  while ((infoString = [enumer nextObject])) {
    NSArray      *infoParts         = nil;
    NSEnumerator *enumer2           = nil;
    NSString     *part              = nil;
    NSDictionary *info2             = nil;
    NSString     *lastPathComponent = nil;

    infoParts = [NSArray array];
    enumer2   = [[infoString componentsSeparatedByString:@" "]
                             objectEnumerator];
    while ((part = [enumer2 nextObject])) {
      if ([part length] > 0) {
        infoParts = [infoParts arrayByAddingObject:part];
      }
    }

    // do not process lines, which does not contain file informations
    if (([infoParts count] != 9) ||
        [(NSString *)[infoParts objectAtIndex:1] hasPrefix:@"file"])
      continue;

    lastPathComponent = [[infoParts objectAtIndex:8] lastPathComponent];
    if ([lastPathComponent hasPrefix:@".attributes."] &&
        [lastPathComponent hasSuffix:@".plist"])
      continue;

    info2 = [NSDictionary dictionaryWithObjectsAndKeys:
                          [infoParts objectAtIndex:0], @"permissions",
                          [infoParts objectAtIndex:1], @"version",
                          //[infoParts objectAtIndex:2], @"xxx",
                          [infoParts objectAtIndex:3], @"size",
                          //[infoParts objectAtIndex:4], @"xxx",
                          //[infoParts objectAtIndex:5], @"xxx",
                          [infoParts objectAtIndex:6], @"date",
                          [infoParts objectAtIndex:7], @"time",
                          nil];
    [info setObject:info2 forKey:[infoParts objectAtIndex:8]];
  }

  [localFm removeFileAtPath:tmpZipFile handler:nil];

  if (result != 0) {
    RELEASE(info);
    return nil;
  }

  return AUTORELEASE(info);
}

- (NSDictionary *)infoOnZipFileAtPath:(NSString *)_path {
  NSData *data = nil;

  data = [[self fileManager] contentsAtPath:_path];
  return [self infoOnZippedData:data];
}
- (NSArray *)infoListOnZippedData:(NSData *)_data {
  NSMutableArray *result    = nil;
  NSEnumerator   *filenames = nil;
  NSString       *filename  = nil;
  NSDictionary   *infoDict  = nil;

  result    = [[NSMutableArray alloc] init];
  infoDict  = [self infoOnZippedData:_data];
  filenames = [infoDict keyEnumerator];

  while ((filename = [filenames nextObject])) {
    NSMutableDictionary *attributes = nil;

    attributes = [NSMutableDictionary dictionaryWithDictionary:
                                      [infoDict objectForKey:filename]];
    [attributes setObject:filename forKey:@"pathName"];
    [result addObject:attributes];
  }
  
  return AUTORELEASE(result);
}

- (NSArray *)infoListOnZipFileAtPath:(NSString *)_path {
  NSData *data = nil;

  data = [[self fileManager] contentsAtPath:_path];
  NSAssert([data length] > 0, @"zipfile does not exist or contains no data");
  return [self infoListOnZippedData:data];
}

@end /* NGFileManagerZipInfo */
