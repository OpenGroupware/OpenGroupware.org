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

#include "NGUnixTool.h"

@implementation NGUnixTool

+ (void)initialize {
  static BOOL didInit = NO;
  if (!didInit) {
    NSDictionary *defs;
    didInit = YES;

    defs = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"/usr/bin/zip",     @"zip",
                         @"/usr/bin/unzip",   @"unzip",
                         @"/usr/bin/zipinfo", @"zipinfo",
                         @"/bin/rm",          @"rm",
                         @"/usr/bin/diff",    @"diff",
                         @"/bin/tar",         @"tar",
                         nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defs];
  }
}

+ (NSString *)pathToZipTool {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"zip"];
}
+ (NSString *)pathToUnzipTool {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"unzip"];
}
+ (NSString *)pathToZipInfoTool {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"zipinfo"];
}
+ (NSString *)pathToRmTool {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"rm"];
}
+ (NSString *)pathToDiffTool {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"diff"];
}
+ (NSString *)pathToTarTool {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"tar"];
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


- (NSString *)_uniquePath {
  char name[] = "/tmp/NGUnixToolXXXXXX";
  int  fd;

  if ((fd = mkstemp(name)) == -1) return nil; // create unique file
  close(fd);                                  // close this file
  if (remove(name) == -1) return nil;         // remove this file

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

  task = [[NSTask alloc] init];
  [task setLaunchPath:[self pathToRmTool]];
  [task setArguments:[NSArray arrayWithObjects:@"-rf", _path, nil]];
  [task launch];
  if ([task isRunning]) [task waitUntilExit];

  result = [task terminationStatus];
  RELEASE(task);

  return result == 0;
}

@end
