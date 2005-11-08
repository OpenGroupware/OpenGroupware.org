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

#include "LSWImapMailFolderMove.h"
#include "common.h"

@implementation LSWImapMailFolderMove

- (void)dealloc {
  [self->rootFolder release];
  [self->folder     release];
  [self->item       release];
  [super dealloc];
}

- (void)setItem:(NGImap4Folder *)_item {
  ASSIGN(self->item, _item);
}
- (NGImap4Folder *)item {
  return self->item;
}

- (void)setFolder:(NGImap4Folder *)_folder {
  ASSIGN(self->folder, _folder);
}
- (NGImap4Folder *)folder {
  return self->folder;
}

- (void)setRootFolder:(NGImap4Folder *)_rootFolder {
  ASSIGN(self->rootFolder, _rootFolder);
}
- (NGImap4Folder *)rootFolder {
  return self->rootFolder;
}

- (NSArray *)rootFolders {
  return [NSArray arrayWithObject:self->rootFolder];
}

/* conditionals */

- (BOOL)canMoveToFolder {
  return
    ![[self->item absoluteName] hasPrefix:[self->folder absoluteName]] &&
    ![[self->folder parentFolder] isEqual:self->item];
}

- (BOOL)isFolderToMove {
  return [self->item isEqual:self->folder];
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)moveFolder {
  // TODO: cleanup
  
  [self->folder resetLastException];
  [[self->folder parentFolder] moveSubFolder:self->folder to:self->item];
  [[[[self session] navigation] activePage]
           postChange:@"LSWImapMailFolderWasDeleted"
           onObject:self->folder];
  {
    NSException *localException;
    
    if ((localException = [self->folder lastException])) {
      NSString *str;
      
      str = [(NSDictionary *)[(NSDictionary *)[localException userInfo] 
	                      objectForKey:@"RawResponse"]
                              objectForKey:@"reason"];

      if ([str isEqualToString:@"Permission denied"]) {
        NSString *s;
        
        s = [[self labels] valueForKey:@"FolderMovePermissionDenied"];
        s = [[NSString alloc] initWithFormat:s, [self->item absoluteName]];
        [self setErrorString:s];
        [s release];
      }
      else
        [self setErrorString:[localException description]];
    }
    else
      [self leavePage];
  }  
  return nil;
}

/* icon */

- (NSString *)_iconName {
  NSMutableString *result;
  static NSString *arrow = @"_green_arrow_13.gif";
  static NSString *point = @"_green_point_13.gif";
  static NSString *other = @"_13.gif";
  
  result = [NSMutableString stringWithCapacity:64];
  
  [result appendString:([self isFolderToMove]) ? @"opened" : @"closed"];
  
  {
    NSException *localException;

    [self->item resetLastException];
    
    if ([self->item hasNewMessagesSearchRecursiv:NO])
      [result appendString:arrow];
    else if ([self->item hasUnseenMessagesSearchRecursiv:NO])
      [result appendString:point];
    else
      [result appendString:other];

    if ((localException = [self->item lastException])) {
      [self setErrorString:[localException description]];
      [result appendString:other];
    }
  }
  
  return result;
}

- (NSString *)folderIcon {
  return [NSString stringWithFormat:@"folder_%@", [self _iconName]];
}

- (NSString *)cornerFolderIcon {
  return [NSString stringWithFormat:@"folder_corner_%@", [self _iconName]];
}

- (NSString *)folderBGColor {
  return [[self config] valueForKey:[self isFolderToMove]
                        ? @"colors_valueCell" : @"colors_attributeCell"];
}

@end /* LSWImapMailFolderMove */
