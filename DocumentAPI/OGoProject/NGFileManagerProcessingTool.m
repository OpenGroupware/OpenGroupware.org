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
#include "NGFileManagerProcessingTool.h"
#include "NGFileManagerCopyTool.h"

@interface NSObject(HiddenCallbacks) /* see header file of copy-tool */

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFiles:(NSArray *)_files atPath:(NSString *)_path;;

@end

@implementation NGFileManagerProcessingTool

- (void)dealloc {
  [self->fileManager     release];
  [self->processedPathes release];
  [self->handler         release];
  [super dealloc];
}

/* accessors */

- (void)setFileManager:(id<NSObject,NGFileManager>)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id<NSObject,NGFileManager>)fileManager {
  return self->fileManager;
}

/* operations */

- (NSException *)processFileNames:(NSArray *)_fileNames atPath:(NSString *)_path
  handler:(id)_handler
{
  NSEnumerator   *enumerator;
  NSMutableArray *files;
  int            cnt;
  id             obj;
  NSException    *exc;
  
  cnt   = [_fileNames count];
  files = [NSMutableArray arrayWithCapacity:cnt];

  enumerator = [_fileNames objectEnumerator];
  exc        = nil;
  while ((obj = [enumerator nextObject])) {
    NSDictionary *dict;
    NSString     *p, *ftype;

    if (![obj length])
      continue;
    
    p     = [_path stringByAppendingPathComponent:obj];
    dict  = [[self fileManager] fileAttributesAtPath:p traverseLink:NO];
    ftype = [dict objectForKey:NSFileType];

    if ([ftype isEqualToString:NSFileTypeRegular]) {
      [files addObject:obj];
    }
    else if ([ftype isEqualToString:NSFileTypeSymbolicLink]) {
      exc = [_handler tool:self processLinkPath:p];
    }
    else if ([ftype isEqualToString:NSFileTypeDirectory]) {
      exc = [_handler tool:self processDirectoryPath:p];
    }
    else {
      NSLog(@"%s: unknown file type '%@'", __PRETTY_FUNCTION__, ftype);
    }
    if (exc)
      break;
  }
  if (exc) {
    NSLog(@"WARNING[%s]: got exception %@", __PRETTY_FUNCTION__, exc);
    return exc;
  }
  return [_handler tool:self processFiles:files atPath:_path];
}

- (NSException *)processPath:(NSString *)_path handler:(id)_handler {
  NSDictionary *attributes    = nil;
  NSString *ftype;

  attributes = [[self fileManager] fileAttributesAtPath:_path traverseLink:NO];
  ftype = [attributes fileType];
  
  if ([ftype isEqualToString:NSFileTypeRegular]) {
    return [_handler tool:self processFilePath:_path];
  }
  else if ([ftype isEqualToString:NSFileTypeSymbolicLink]) {
    return [_handler tool:self processLinkPath:_path];
  }
  else if ([ftype isEqualToString:NSFileTypeDirectory]) {
    return [_handler tool:self processDirectoryPath:_path];
  }
  else {
    NSLog(@"%s: unknown file type '%@'", __PRETTY_FUNCTION__, ftype);
  }
  return nil;
}

@end /* NGFileManagerProcessingTool */
