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

#include "NGFileManagerTarTool.h"
#include "common.h"

static id GetNGUnixTool(void) {
  return [[[NSClassFromString(@"NGUnixTool") alloc] init] autorelease];
}
static NSString *GetPathToTarTool(void) {
  return [NSClassFromString(@"NGUnixTool") pathToTarTool];
}

@implementation NGFileManagerTarTool

- (NSException *)tarPath:(NSString *)_srcPath toPath:(NSString *)_toPath {
  return [self tarPaths:[NSArray arrayWithObject:_srcPath] toPath:_toPath];
}

- (NSException *)tarPaths:(NSArray *)_srcPaths toPath:(NSString *)_toPath {
  id<NSObject,NGFileManager> oldTargetFm = nil;
  NSFileManager              *localFm    = nil;
  NSString                   *tmpPath    = nil;
  NGUnixTool                 *unixTool   = nil;
  NSData                     *tarData    = nil;
  NSEnumerator               *enumer     = nil;
  NSString                   *srcPath    = nil;
  BOOL                       isDir;

  localFm     = [NSFileManager defaultManager];
  unixTool    = GetNGUnixTool();
  if ((tmpPath = [unixTool _uniquePath]) == nil) {
    return [NSException exceptionWithName:@"couldntcreatetempfile"
                        reason:@"could not create temporary file" 
			userInfo:nil];
  }
  [localFm createDirectoryAtPath:tmpPath attributes:nil];

  oldTargetFm = [self targetFileManager];
  [self setTargetFileManager:(id<NSObject,NGFileManager>)localFm];

  enumer      = [_srcPaths objectEnumerator];
  while ((srcPath = [enumer nextObject])) {
    [self copyPath:srcPath toPath:tmpPath handler:nil];
  }

  [self setTargetFileManager:oldTargetFm];

  tarData     = [self dataByTaringLocalPath:tmpPath];
  [unixTool _removeLocalPath:tmpPath];
  
  if ([[self targetFileManager] fileExistsAtPath:_toPath isDirectory:&isDir]) {
    if ([[self targetFileManager] isWritableFileAtPath:_toPath]) {
      if (![[self targetFileManager] writeContents:tarData atPath:_toPath]) {
        return [NSException exceptionWithName:@"cannotwritetotarfile"
                            reason:@"can not write to tar file" userInfo:nil];
      }
    }
    else {
      return [NSException exceptionWithName:@"tarfileNotWritable"
                          reason:@"tar file is not writable" userInfo:nil];
    }
  }
  else {
    if ([[self targetFileManager] createFileAtPath:_toPath contents:tarData
                                  attributes:nil] == NO) {
      return [NSException exceptionWithName:@"tarfileNotCreatable"
                          reason:@"can not create tar file" userInfo:nil];
    }
  }

  return nil;
}

- (NSData *)dataByTaringLocalPath:(NSString *)_path {
  NSFileHandle  *nullHandle  = nil;
  NSFileHandle  *tarHandle   = nil;
  NSPipe        *tarPipe     = nil;
  NSTask        *tarTask     = nil;
  NSData        *result      = nil;

  tarPipe    = [NSPipe pipe];
  tarHandle  = [tarPipe fileHandleForReading];
  nullHandle = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
  tarTask    = [[NSTask alloc] init];
  [tarTask setLaunchPath:GetPathToTarTool()];
  [tarTask setCurrentDirectoryPath:_path];
  [tarTask setArguments:
           [NSArray arrayWithObjects:@"c", @".", nil]];
  [tarTask setStandardOutput:tarPipe];
  [tarTask setStandardError:nullHandle];
  [tarTask launch];

  result     = [tarHandle readDataToEndOfFile];

  RELEASE(tarTask);
  return result;
}

@end /* NGFileManagerTarTool */


@implementation NGFileManagerUntarTool

- (NSException *)untarPath:(NSString *)_tarfile toPath:(NSString *)_toPath {
  NSData *tarData = nil;

  tarData = [[self sourceFileManager] contentsAtPath:_tarfile];
  [self untarData:tarData toPath:_toPath];

  return nil;
}

- (NSException *)untarData:(NSData *)_data toPath:(NSString *)_toPath {
  id<NSObject,NGFileManager> oldSourceFm  = nil;
  NSFileManager              *localFm     = nil;
  NGUnixTool                 *unixTool    = nil;
  NSString                   *tmpPath     = nil;
  NSPipe                     *inputPipe   = nil;
  NSFileHandle               *inputHandle = nil;
  NSFileHandle               *nullHandle  = nil;
  NSTask                     *untarTask   = nil;
  int                        result;

  localFm     = [NSFileManager defaultManager];
  unixTool    = GetNGUnixTool();
  if (!(tmpPath = [unixTool _uniquePath])) {
    return [NSException exceptionWithName:@"couldntcreatetempfile"
                        reason:@"couldn`t create temporary file" userInfo:nil];
  }
  [localFm createDirectoryAtPath:tmpPath attributes:nil];

  inputPipe   = [NSPipe pipe];
  inputHandle = [inputPipe fileHandleForWriting];
  nullHandle  = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];

  untarTask   = [[NSTask alloc] init];
  [untarTask setLaunchPath:GetPathToTarTool()];
  [untarTask setCurrentDirectoryPath:tmpPath];
  [untarTask setArguments:[NSArray arrayWithObject:@"x"]];
  [untarTask setStandardInput:inputPipe];
  [untarTask setStandardOutput:nullHandle];
  [untarTask setStandardError:nullHandle];
  [untarTask launch];

  [inputHandle writeData:_data];
  [inputHandle closeFile];

  if ([untarTask isRunning]) [untarTask waitUntilExit];
  result = [untarTask terminationStatus];
  [untarTask release];

  oldSourceFm = [self sourceFileManager];
  [self setSourceFileManager:(id<NSObject,NGFileManager>)localFm];
  [self copyPath:[tmpPath stringByAppendingPathComponent:@"*"]
        toPath:_toPath handler:nil];
  [self setSourceFileManager:oldSourceFm];

  [unixTool _removeLocalPath:tmpPath];
  
  return nil;
}

@end /* NGFileManagerUntarTool */

@implementation NGFileManagerTarInfo

- (void)dealloc {
  [self->fileManager release];
  [super dealloc];
}

/* accessors */

- (void)setFileManager:(id<NSObject,NGFileManager>)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id<NSObject,NGFileManager>)fileManager {
  return self->fileManager;
}

- (NSDictionary *)infoOnTaredData:(NSData *)_data {
  NGUnixTool          *unixTool      = nil;
  NSTask              *tarInfoTask   = nil;
  NSFileHandle        *nullHandle    = nil;
  NSFileHandle        *inputHandle   = nil;
  NSFileHandle        *outputHandle  = nil;
  NSPipe              *inputPipe     = nil;
  NSPipe              *outputPipe    = nil;
  NSData              *outputData    = nil;
  NSMutableDictionary *info          = nil;
  NSString            *tmpString     = nil;
  NSEnumerator        *enumer        = nil;
  NSString            *infoString    = nil;
  int                 result;

  unixTool      = GetNGUnixTool();
  info          = [[NSMutableDictionary alloc] init];

  inputPipe     = [NSPipe pipe];
  outputPipe    = [NSPipe pipe];
  inputHandle   = [inputPipe  fileHandleForWriting];
  outputHandle  = [outputPipe fileHandleForReading];
  nullHandle    = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];

  tarInfoTask   = [[NSTask alloc] init];
  [tarInfoTask setLaunchPath:GetPathToTarTool()];
  [tarInfoTask setArguments:[NSArray arrayWithObject:@"tv"]];
  [tarInfoTask setStandardInput:inputPipe];
  [tarInfoTask setStandardOutput:outputPipe];
  [tarInfoTask setStandardError:nullHandle];
  [tarInfoTask launch];

  [inputHandle writeData:_data];
  [inputHandle closeFile];

  outputData = [outputHandle readDataToEndOfFile];
  result     = [tarInfoTask terminationStatus];
  tmpString  =
    [[NSString alloc] initWithData:outputData
                      encoding:[NSString defaultCStringEncoding]];
  enumer        = [[tmpString componentsSeparatedByString:@"\n"]
		              objectEnumerator];
  [tmpString release]; tmpString = nil;

  while ((infoString = [enumer nextObject])) {
    NSArray      *infoParts         = nil;
    NSEnumerator *enumer2           = nil;
    NSString     *part              = nil;
    NSDictionary *info2             = nil;
    NSString     *lastPathComponent = nil;
    NSString     *path              = nil;

    infoParts = [NSArray array];
    enumer2  = [[infoString componentsSeparatedByString:@" "]
                            objectEnumerator];
    while ((part = [enumer2 nextObject])) {
      if ([part length] > 0) {
        infoParts = [infoParts arrayByAddingObject:part];
      }
    }

    if ([infoParts count] < 6) continue;

    path              = [infoParts objectAtIndex:5];
    lastPathComponent = [path lastPathComponent];
    if ([lastPathComponent hasPrefix:@".attributes."] &&
        [lastPathComponent hasSuffix:@".plist"])
      continue;

    if ([path isEqualToString:@"./"])
      continue;

    info2 = [NSDictionary dictionaryWithObjectsAndKeys:
                          [infoParts objectAtIndex:0], @"permissions",
                          [infoParts objectAtIndex:1], @"owner",
                          [infoParts objectAtIndex:2], @"size",
                          [infoParts objectAtIndex:3], @"date",
                          [infoParts objectAtIndex:4], @"time",
                          nil];
    [info setObject:info2 forKey:[infoParts objectAtIndex:5]];
  }

  return AUTORELEASE(info);
}

- (NSDictionary *)infoOnTarFileAtPath:(NSString *)_path {
  NSData *data = nil;

  data = [[self fileManager] contentsAtPath:_path];
  return [self infoOnTaredData:data];
}

- (NSArray *)infoListOnTaredData:(NSData *)_data {
  NSMutableArray *result    = nil;
  NSEnumerator   *filenames = nil;
  NSString       *filename  = nil;
  NSDictionary   *infoDict  = nil;

  result    = [[NSMutableArray alloc] init];
  infoDict  = [self infoOnTaredData:_data];
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

- (NSArray *)infoListOnTarFileAtPath:(NSString *)_path {
  NSData *data = nil;

  data = [[self fileManager] contentsAtPath:_path];
  return [self infoListOnTaredData:data];
}

@end /* NGFileManagerTarInfo */
