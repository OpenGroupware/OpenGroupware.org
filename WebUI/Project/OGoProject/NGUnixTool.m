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

#import <Foundation/NSDictionary.h>
#include "NGUnixTool.h"

@implementation NGUnixTool

static NSUserDefaults *ud = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  NSMutableDictionary *defs;

  if (didInit) return;
  didInit = YES;
  
  ud   = [[NSUserDefaults standardUserDefaults] retain];
  defs = [NSMutableDictionary dictionaryWithCapacity:5];
  
  if ([ud stringForKey:@"zip"] == nil)
    [defs setObject:@"/usr/bin/zip"     forKey:@"zip"];
  if ([ud stringForKey:@"unzip"] == nil)
    [defs setObject:@"/usr/bin/unzip"   forKey:@"unzip"];
  if ([ud stringForKey:@"zipinfo"] == nil)
    [defs setObject:@"/usr/bin/zipinfo" forKey:@"zipinfo"];
  if ([ud stringForKey:@"rm"] == nil)
    [defs setObject:@"/bin/rm"          forKey:@"rm"];
  if ([ud stringForKey:@"diff"] == nil)
    [defs setObject:@"/usr/bin/diff"    forKey:@"diff"];
  if ([ud stringForKey:@"tar"] == nil)
    [defs setObject:@"/bin/tar"         forKey:@"tar"];

  [ud registerDefaults:defs];
}

+ (NSString *)pathToZipTool {
  return [ud stringForKey:@"zip"];
}
+ (NSString *)pathToUnzipTool {
  return [ud stringForKey:@"unzip"];
}
+ (NSString *)pathToZipInfoTool {
  return [ud stringForKey:@"zipinfo"];
}
+ (NSString *)pathToRmTool {
  return [ud stringForKey:@"rm"];
}
+ (NSString *)pathToDiffTool {
  return [ud stringForKey:@"diff"];
}
+ (NSString *)pathToTarTool {
  return [ud stringForKey:@"tar"];
}
- (NSString *)pathToZipTool {
  return [[self class] pathToZipTool];
}
- (NSString *)pathToUnzipTool {
  return [[self class] pathToUnzipTool];
}
- (NSString *)pathToZipInfoTool {
  return [[self class] pathToZipInfoTool];
}
- (NSString *)pathToRmTool {
  return [[self class] pathToRmTool];
}
- (NSString *)pathToDiffTool {
  return [[self class] pathToDiffTool];
}
- (NSString *)pathToTarTool {
  return [[self class] pathToTarTool];
}

- (NSString *)_uniquePath { /* backward compatiblity */
  return [[self class] _uniquePath];
}

+ (NSString *)_uniquePath {
  char name[] = "/tmp/NGUnixToolXXXXXX";
  int  fd;

  if ((fd = mkstemp(name)) == -1) {
    NSLog(@"creation of unique file [%s] using mkstemp failed with %d[%s]",
          name, errno, strerror(errno));
    return nil; // create unique file
  }
  close(fd);                                  // close this file
  if (unlink(name) == -1) {
    NSLog(@"unlink of %s failed with %d[%s]", name, errno, strerror(errno));
    return nil;
  }
  return [NSString stringWithCString:name];
}

- (NSString *)_uniqueFileWithData:(NSData *)_data {
  char name[]      = "/tmp/NGUnixToolXXXXXX";
  int  fd          = 0;
  NSString *result = nil;

  if ((fd = mkstemp(name)) == -1) return nil;
  close(fd); // mkstemp creates a uniq file and opens it. we only need the
             // name, so we can close this file

  result = [NSString stringWithCString:name];
  [_data writeToFile:result atomically:YES];

  return result;
}

- (BOOL)_removeLocalPath:(NSString *)_path {
  NSTask *task = nil;
  int    result;

  if (_path == 0)
    return NO;

  task = [[NSTask alloc] init];
  [task setLaunchPath:[self pathToRmTool]];
  [task setArguments:[NSArray arrayWithObjects:@"-rf", _path, nil]];
  [task launch];

  if ([task isRunning])
    [task waitUntilExit];

  result = [task terminationStatus];
  RELEASE(task);

  return result == 0;
}

@end
