/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSData;
@class EOGlobalID;

@interface SkyProject4DocumentRename : LSWContentPage
{
  id         fileManager;
  EOGlobalID *fileGID;
  NSString   *newFileName;
}

@end

@interface NSObject(SkyProject4_Additions)
- (BOOL)supportsUniqueFileIds;
- (void)setDocumentId:(EOGlobalID *)_gid;
@end /* NSObject(FileManager_Additions) */

#include "common.h"
#include "OGoComponent+FileManagerError.h"
#include <NGExtensions/NSString+Ext.h>

@implementation SkyProject4DocumentRename

- (void)dealloc {
  [self->newFileName release];
  [self->fileManager release];
  [self->fileGID     release];
  [super dealloc];
}

/* activation */

- (id)activateDocument:(SkyProjectDocument *)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (![_verb isEqualToString:@"rename"]) return nil;
  if (_object == nil) return nil;
  
  [self takeValue:[_object globalID]    forKey:@"fileId"];
  [self takeValue:[_object fileManager] forKey:@"fileManager"];
  
  return self;
}

- (id)activateObject:(id)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (_object == nil) return nil;
  
  if ([_object isKindOfClass:[SkyDocument class]])
    return [self activateDocument:_object verb:_verb type:_type];
  
  [self logWithFormat:@"couldn't activate object %@", _object];
  return nil;
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setFileId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->fileGID, _gid);
}
- (id)fileId {
  return self->fileGID;
}

- (void)setNewFileName:(NSString *)_newFileName {
  ASSIGNCOPY(self->newFileName, _newFileName);
}
- (NSString *)newFileName {
  return self->newFileName;
}

- (NSString *)filePath {
  return [[self fileManager] pathForGlobalID:[self fileId]];
}
- (NSString *)fileName {
  return [[self filePath] stringByDeletingLastPathComponent];
}

/* actions */

- (BOOL)checkFileName {
  NSRange r;
  int     p2, i, p;
  
  r = [self->newFileName rangeOfString:@"."];
  p = (r.length == 0) ? NSNotFound : r.location;
  
  for (i = p; i != NSNotFound; i = p2) {
    // TODO: replace with -rangeOfString:
    p2 = [self->newFileName indexOfString:@"." fromIndex:i+1];
    if (p2 != NSNotFound)
      p = p2;
  }
  if (p == NSNotFound) {
    // No file extension .. don't care
    // SkyProjectFileManager will catch this
    return YES;
  }
  else {
    NSString *str, *repaired;
    str      = [self->newFileName substringFromIndex:p+1];
    repaired = [str stringByTrimmingWhiteSpaces];
    if ([repaired length] < [str length]) {
      // string realy repaired ... go on
      str = [NSString stringWithFormat:@"%@.%@",
                      [self->newFileName substringToIndex:p],
                      repaired];
      ASSIGNCOPY(self->newFileName,str);
    }
    return YES;
  }
}

- (id)renameFile {
  NSString *newPath;
  NSString *oldPath;
  
  if ([self->newFileName length] == 0) {
    [self setErrorString:@"missing new file name !"];
    return nil;
  }

  if (![self checkFileName]) {
    [self setErrorString:@"invalid file name !"];
    return nil;
  }

  oldPath = [self filePath];
  newPath = [[oldPath stringByDeletingLastPathComponent]
                      stringByAppendingPathComponent:[self newFileName]];
  
  if ([newPath isEqualToString:oldPath]) {
    /* same filename */
    [self debugWithFormat:@"nothing to rename .."];
    return [[(OGoSession *)[self session] navigation] leavePage];
  }
  
  [self debugWithFormat:@"rename %@ to %@.", oldPath, newPath];
  
  if (![[self fileManager] movePath:oldPath toPath:newPath handler:nil]) {
    return [self printErrorWithSource:oldPath destination:newPath];
  }
  if (![[self fileManager] supportsUniqueFileIds]) {
    id page, activePage;

    page       = [[(OGoSession *)[self session] navigation] leavePage];
    activePage = [[(OGoSession *)[self session] navigation] activePage];


    if ([activePage isKindOfClass:
                    NSClassFromString(@"SkyProject4DocumentViewer")]) {
      [activePage setDocumentId:[[self fileManager] globalIDForPath:newPath]];
    }
    return page;
  }
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)cancel {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

@end /* SkyProject4DocumentRename */
