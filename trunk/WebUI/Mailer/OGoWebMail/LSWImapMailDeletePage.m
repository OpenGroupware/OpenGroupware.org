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

#include <OGoFoundation/LSWViewerPage.h>

@interface LSWImapMailDeletePage : LSWViewerPage
@end

#include "common.h"
#include <NGImap4/NGImap4Message.h>
#include <NGImap4/NGImap4Folder.h>

@implementation LSWImapMailDeletePage

- (id)moveFolderIntoTrash:(NGImap4Folder *)_folder {
  return nil; // is not supported now
}

- (id)moveMessageIntoTrash:(NGImap4Message *)_message {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
  NGImap4Folder        *f  = [_message folder];

  if (![f isInTrash]) {
    [f moveMessages:[NSArray arrayWithObject:_message]
           toFolder:[[f context] trashFolder]];
    [nc postNotificationName:@"LSWImapMailWasDeleted" object:_message];
  }
  return [[self navigation] activePage];
}

- (id)activateObject:(id)_obj verb:(NSString *)_verb type:(NGMimeType *)_type {
  if ([_obj isKindOfClass:[NGImap4Message class]])
    return [self moveMessageIntoTrash:_obj];
  
  if ([_obj isKindOfClass:[NGImap4Folder class]])
    return [self moveFolderIntoTrash:_obj];
  
  return nil;
}

@end /* LSWImapMailDeletePage */
