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

#include "OGoConfigDatabase.h"
#include "OGoConfigFile.h"
#include "OGoConfigDataSource.h"
#include "OGoConfigEntryGlobalID.h"
#include "common.h"

@implementation OGoConfigDatabase

static NSDictionary *extToFactory = nil;

+ (void)initialize {
  if (extToFactory == nil) {
    NSMutableDictionary *md;
    
    md = [NSMutableDictionary dictionaryWithCapacity:8];
    
    [md setObject:NSClassFromString(@"OGoCyrusConfigFile") 
        forKey:@"cyrus"];
    [md setObject:NSClassFromString(@"OGoPostfixConfigFile") 
        forKey:@"postfix"];
    [md setObject:NSClassFromString(@"OGoAccountsVirtualConfigFile") 
        forKey:@"uvirtual"];
    [md setObject:NSClassFromString(@"OGoTeamsVirtualConfigFile") 
        forKey:@"tvirtual"];
    [md setObject:NSClassFromString(@"OGoQuotaTabConfigFile") 
        forKey:@"quotatab"];
    
    extToFactory = [md copy];
  }
}

- (id)initWithPath:(NSString *)_path fileManager:(NSFileManager *)_fm {
  if ((self = [super init])) {
    self->path        = [_path copy];
    self->fileManager = [_fm retain];
  }
  return self;
}

- (id)initWithSystemPath:(NSString *)_path {
  return [self initWithPath:_path fileManager:[NSFileManager defaultManager]];
}
- (id)init {
  return [self initWithPath:nil fileManager:nil];
}

- (void)dealloc {
  [self->fileManager release];
  [self->path        release];
  [super dealloc];
}

/* accessors */

- (NSFileManager *)fileManager {
  return self->fileManager;
}
- (NSString *)path {
  return self->path;
}

/* file operations */

- (id)foreachFileDo:(SEL)_selector context:(id)_ctx {
  NSArray      *a;
  NSEnumerator *e;
  NSString     *s;
  
  if ((a = [self->fileManager directoryContentsAtPath:self->path]) == nil) {
    return [NSException exceptionWithName:@"NSFileException"
                        reason:@"could not list directory"
                        userInfo:nil];
  }
  
  e = [a objectEnumerator];
  while ((s = [e nextObject])) {
    NSString *p;
    BOOL     isDir;
    id result;
    
    p = [self->path stringByAppendingPathComponent:s];
    if (![self->fileManager fileExistsAtPath:p isDirectory:&isDir])
      continue;
    if (isDir)
      continue;
    if (![self->fileManager isReadableFileAtPath:p])
      continue;
    
    result = [self performSelector:_selector withObject:s withObject:_ctx];
    if (result) /* aborted by method */
      return result;
  }
  
  return nil;
}

/* entry factory */

- (id)entryFactoryForPathExtension:(NSString *)_ext {
  if (_ext == nil)
    return nil;
  
  return [extToFactory objectForKey:_ext];
}
- (id)entryFactoryForFilename:(NSString *)_filename {
  return [self entryFactoryForPathExtension:[_filename pathExtension]];
}

- (id)entryForFilename:(NSString *)_filename {
  id factory;
  NSString *p;
  
  if ((factory = [self entryFactoryForFilename:_filename]) == nil) {
    [self logWithFormat:@"ERROR: found no factory for filename: %@",_filename];
    return nil;
  }
  
  p = [self->path stringByAppendingPathComponent:_filename];
  
  return [factory loadEntryFromPath:p configDatabase:self];
}

/* operating on the content */

- (NSString *)entryNameFromFilename:(NSString *)_s {
  return [[_s lastPathComponent] stringByDeletingPathExtension];
}

- (id)addEntryNameForFilename:(NSString *)_s toArray:(NSMutableArray *)_ma {
  NSString *sp;
  
  sp = [self entryNameFromFilename:_s];
  if ([_ma containsObject:sp]) {
    [self logWithFormat:@"WARNING: contains duplicate entries: '%@'", _s];
    return nil;
  }
  
  [_ma addObject:sp];
  return nil; // means, continue
}
- (NSArray *)fetchEntryNames {
  NSMutableArray *ma;
  id result;
  
  ma = [NSMutableArray arrayWithCapacity:16];
  result = [self foreachFileDo:@selector(addEntryNameForFilename:toArray:)
                 context:ma];
  if (result) return result;
  
  return ma;
}

- (id)pathForEntryFilename:(NSString *)_s lookForName:(NSString *)_name {
  NSString *sp;
  
  sp = [self entryNameFromFilename:_s];
  if ([sp isEqualToString:_name])
    return _s;
  return nil;
}
- (id)fetchEntryWithName:(NSString *)_name {
  NSString *entryFilename;
  id result;
  
  if (_name == nil) return nil;
  
  result = [self foreachFileDo:@selector(pathForEntryFilename:lookForName:)
                 context:_name];
  if (result == nil) 
    return nil;
  if ([result isKindOfClass:[NSException class]]) {
    [self logWithFormat:@"did not find entry: %@", result];
    return nil;
  }
  entryFilename = result;
  
  return [self entryForFilename:entryFilename];
}

- (EODataSource *)configDataSource {
  return [[[OGoConfigDataSource alloc] initWithConfigDatabase:self] 
                                autorelease];
}

- (id)fetchEntryForGlobalID:(EOGlobalID *)_gid {
  if (_gid == nil) return nil;
  if (![_gid isKindOfClass:[OGoConfigEntryGlobalID class]]) {
    [self logWithFormat:@"WARNING: cannot process global-id: %@", _gid];
    return nil;
  }
  return [self fetchEntryWithName:[(OGoConfigEntryGlobalID *)_gid entryName]];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  
  if (self->path) [ms appendFormat:@" dir='%@'", self->path];
  if (self->fileManager && self->fileManager != [NSFileManager defaultManager])
    [ms appendFormat:@" fm=%@", self->fileManager];
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoConfigDatabase */
