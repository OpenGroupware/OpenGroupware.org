/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org

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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSData;
@class EOGlobalID;

@interface SkyProject4DocumentVersionSave : LSWContentPage
{
  id       fileManager;
  NSString *filePath;
  NSString *newFilePath;
}

@end

#include "common.h"

@implementation SkyProject4DocumentVersionSave

- (void)dealloc {
  RELEASE(self->filePath);
  RELEASE(self->newFilePath);
  RELEASE(self->fileManager);
  [super dealloc];
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setNewFilePath:(NSString *)_path {
  ASSIGNCOPY(self->newFilePath, _path);
}
- (NSString *)newFilePath {
  return self->newFilePath;
}

- (void)setFilePath:(NSString *)_path {
  ASSIGN(self->filePath, _path);
}
- (NSString *)filePath {
  return self->filePath;
}

/* actions */

- (id)saveFile {
  NSString *newPath;
  NSString *oldPath;
  NSData   *contents;
  id       fm;
  
  oldPath = [self filePath];
  newPath = [self newFilePath];

  if ([newPath length] == 0) {
    [self setErrorString:@"missing new file name !"];
    return nil;
  }

  if ([[newPath pathVersion] length] > 0) {
    [self setErrorString:@"invalid file name"];
    return nil;
  }

  if (![newPath hasPrefix:@"/"]) {
    newPath = [[oldPath stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:newPath];
  }

  fm = [self fileManager];
  if ([fm fileExistsAtPath:newPath]) {
    [self setErrorString:@"file already exists"];
    return nil;
  }

  [self debugWithFormat:@"save %@ as %@.", oldPath, newPath];

  contents = [fm contentsAtPath:oldPath];
  if (![fm createFileAtPath:newPath contents:contents attributes:nil]) {
    [self setErrorString:@"couldn't save file"];
    return nil;
  }

  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)cancel {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

@end /* SkyProject4DocumentVersionSave */
