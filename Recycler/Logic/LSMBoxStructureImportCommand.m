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
// $Id: LSMBoxStructureImportCommand.m 1 2004-08-20 11:17:52Z znek $

#import "LSMBoxStructureImportCommand.h"
#import "common.h"

@implementation LSMBoxStructureImportCommand

static NSFileManager *fileManager;

+ (void)initialize {
  if (fileManager == nil) {
    fileManager = [NSFileManager defaultManager];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:([self object] != nil) reason:@"no import path is set"];
  [super _prepareForExecutionInContext:_context];
}

- (id)__getFolder:(NSString *)_name parentFolderId:(NSNumber *)_parent
        inContext:(id)_context {
  
  id folder = nil;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (_parent != nil) 
    folder = LSRunCommandV(_context,
                           @"emailFolder", @"get",
                           @"name", _name,
                           @"parentFolderId", _parent,
                           nil);
  else
    folder = LSRunCommandV(_context,
                           @"emailFolder", @"get",
                           @"name", _name,
                           nil);
  if ([folder count] == 0) {
    if (_parent != nil)
      folder = LSRunCommandV(_context,
                             @"emailFolder", @"new",
                             @"name", _name,
                             @"parentFolderId", _parent,
                             nil);
    else
      folder = LSRunCommandV(_context,
                             @"emailFolder", @"new",
                             @"name", _name,                             
                             nil);
  }
  else {
    if ([folder count] > 1)
      NSLog(@"WARNING: more than one folder %@", folder);
    folder = [folder lastObject];
  }
  RELEASE(pool); pool = nil;
  return folder;
}

- (void)__lookingForFiles:(NSString *)_path withParentId:(NSNumber *)_parent
                inContext:(id)_context {
  
  NSEnumerator *enumerator = nil;
  NSString     *file       = nil;
  
  enumerator = [[fileManager directoryContentsAtPath:_path] objectEnumerator];

  while ((file = [enumerator nextObject])) {
    BOOL     isDir         = NO;
    NSString *absoluteFile = [_path stringByAppendingPathComponent:file];
    
    if ([fileManager fileExistsAtPath:absoluteFile isDirectory:&isDir] == NO)
      isDir = NO;
    if (isDir == YES) {
      id folder = nil;

      if ([file hasSuffix:@".sbd"])
        file = [file substringWithRange:NSMakeRange(0, [file length] - 4)];
      else {
        NSLog(@"WARNING: found mbox folder without .sbd suffix");
      }
      folder = [self __getFolder:file parentFolderId:_parent
                     inContext:_context];
      [self __lookingForFiles:absoluteFile
            withParentId:[folder valueForKey:@"emailFolderId"]
            inContext:_context];
    }
    else {
      NSArray *fileTokens = [file componentsSeparatedByString:@"."];

      if ([fileTokens count] == 1) { // no extension -> mBoxFile
        id folder = [self __getFolder:file parentFolderId:_parent
                          inContext:_context];
        {
          EODatabaseContext *ctx = [_context valueForKey:LSDatabaseContextKey];
          if ([ctx transactionNestingLevel] != 0) {
            if (![ctx commitTransaction]) {
              NSLog(@"couldn`t commitTransaction");
              [ctx rollbackTransaction];
            }
          }
          if ([ctx beginTransaction]) {
            BOOL didRollback;
            *(&didRollback) = NO;
            NS_DURING {
              NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
              LSRunCommandV(_context,
                            @"mbox",        @"import-file",
                            @"file",        absoluteFile,
                            @"emailFolder", folder,
                            nil);
              RELEASE(pool); pool = nil;
            }
            NS_HANDLER {
              [ctx rollbackTransaction];
              [localException raise];
              didRollback = YES;
            }
            NS_ENDHANDLER;
            if (didRollback)
              NSLog(@"Transaction was rooled back (an error occured).");
            else {
              if (![ctx commitTransaction]) {
                NSLog(@"Could not commit transaction");
                [ctx rollbackTransaction];
              }
            }
          }
          else {
            NSLog(@"beginTransaction failed");
          }
          if (![ctx beginTransaction]) {
            NSLog(@"beginTransaction failed");
          }
        }
      }
    }
  }
}

- (void)_executeInContext:(id)_context {
  [self __lookingForFiles:[self object] withParentId:nil inContext:_context];
  [super _executeInContext:_context];
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"path"])
    [super takeValue:_value forKey:@"object"];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  return [super valueForKey:_key];
}

@end
