/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "NGUnixTool.h"



@interface FileManagerZipper : NSObject
{
  id<NGFileManager,NSObject> fileManager;
}

@end

@implementation FileManagerZipper

static int ZipDebug = -1;

- (BOOL)zipDebug {
  if (ZipDebug == -1)
    ZipDebug = [[NSUserDefaults standardUserDefaults]
                                boolForKey:@"ZipDebugEnabled"] ? 1 : 0;
  
  return (ZipDebug == 1) ? YES : NO;
}

- (id)zipSelection {
  NGDirectoryEnumerator *e;
  NSString      *tmpdir;
  NSFileManager *fm;
  NSString      *path;
  
  e = [[[NGDirectoryEnumerator alloc]
                               initWithFileManager:self->fileManager
                               directoryPath:@"/"] autorelease];
  
  tmpdir = [NSString stringWithFormat:@"_zipcopy_%d_%d", getpid(), time(NULL)];
  tmpdir = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpdir];
  
  fm = [NSFileManager defaultManager];
  
  if (![fm createDirectoryAtPath:tmpdir attributes:nil]) {
    [self logWithFormat:@"couldn't create tmpdir: %@", tmpdir];
    return nil;
  }
  
  while ((path = [e nextObject])) {
    NSString     *sp, *tp;
    NSDictionary *info;
    NSString     *stype;

    if ([path isEqualToString:@"Trash"]) {
      [e skipDescendents];
      continue;
    }
    
    sp = [@"/"   stringByAppendingPathComponent:path];
    tp = [tmpdir stringByAppendingPathComponent:path];
    
    info = [self->fileManager fileAttributesAtPath:sp traverseLink:NO];
    
    if (info == nil) {
      [self logWithFormat:@"missing fileinfo at path %@", sp];
      continue;
    }

    stype = [info objectForKey:NSFileType];

    if ([stype isEqualToString:NSFileTypeDirectory]) {
      if (![fm createDirectoryAtPath:tp attributes:nil]) {
        NSLog(@"couldn't create dir: %@", tp);
      }
    }
    else if ([stype isEqualToString:NSFileTypeRegular]) {
      NSData *data;
      
      data = [self->fileManager contentsAtPath:sp];
      
      if (![fm createFileAtPath:tp contents:data attributes:nil]) {
        NSLog(@"couldn't create dir: %@", tp);
      }
    }
    else {
      NSLog(@"unknown type: %@", stype);
    }
  }
  
  // try to zip -X
  
  {
    NSTask *zip;
    NSMutableArray *args;
    
    args = [NSMutableArray arrayWithCapacity:16];
    [args addObject:@"-X"]; // no Unix flags
    [args addObject:@"-r"]; // recursive
    [args addObject:@"-q"]; // quiet
    [args addObject:@"my.zip"]; // zipfile
    [args addObject:@"."];      // source

    if ([self zipDebug]) {
      [self logWithFormat:@"zip path: %@ argument: %@ currentdir %@",
            [NGUnixTool pathToZipTool], args, tmpdir];
    }
    
    
    zip = [[[NSTask alloc] init] autorelease];

    [zip setLaunchPath:[NGUnixTool pathToZipTool]];
    [zip setArguments:args];
    [zip setCurrentDirectoryPath:tmpdir];
    [zip launch];
    [zip waitUntilExit];
    NSLog(@"zip exited: %i", [zip terminationStatus]);
    
    [args removeAllObjects];
    [args addObject:@"-r"];  // recursive
    [args addObject:tmpdir];
    [NSTask launchedTaskWithLaunchPath:[NGUnixTool pathToRmTool]
            arguments:args];
  }
  
  return nil;
}

@end /* FileManagerZipper */
