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
// $Id$

#include <OGoFoundation/LSWComponent.h>

@class NSString;
@class LSWTreeState;
@class NGImap4Folder, NGImap4Message;

@interface SkyImapMailFolderTree : LSWComponent
{
@protected
  NGImap4Folder  *folder;
  NGImap4Folder  *rootFolder;
  NGImap4Folder  *selectedFolder;
  NSString       *onClick;

  LSWTreeState   *treeState;
  NGImap4Message *droppedMail;
  int            showAllMessages;
}
@end

#include "common.h"

static NSString *LSWImapMailWasDeleted = @"LSWImapMailWasDeleted";
static NSString *DnDCoundNotMoveMail   = @"DnD: Warning: Could not move mail!";

@implementation SkyImapMailFolderTree

static int DisplayImapExceptions = -1;

+ (void)initialize {
  if (DisplayImapExceptions == -1)
    DisplayImapExceptions =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"DisplayImapExceptions"] ? 1 : 0;
}

- (id)init {
  if ((self = [super init])) {
    self->treeState = [[LSWTreeState allocWithZone:[self zone]]
                                     initWithObject:self
                                            pathKey:@"folderKeyPath"];
    [self->treeState read:@"MailFolderTree"];
    self->showAllMessages = 0;
  }
  return self;
}

- (void)dealloc {
  [self->rootFolder     release];
  [self->folder         release];
  [self->selectedFolder release];
  [self->onClick        release];
  [self->treeState      release];
  [self->droppedMail    release];
  
  [super dealloc];
}

- (void)syncAwake {
  [super syncAwake];
  RELEASE(self->droppedMail); self->droppedMail = nil;
}
- (void)sleep {
  [self->treeState write:@"MailFolderTree"];
  [super sleep];
}

// accessors

- (NGImap4Folder *)rootFolder {
  return self->rootFolder;
}
- (void)setRootFolder:(NGImap4Folder *)_rootFolder {
  ASSIGN(self->rootFolder, _rootFolder);
}

- (NGImap4Folder *)folder {
  return self->folder;
}
- (void)setFolder:(NGImap4Folder *)_folder {
  ASSIGN(self->folder, _folder);
}

- (NGImap4Folder *)selectedFolder {
  return self->selectedFolder;
}
- (void)setSelectedFolder:(NGImap4Folder *)_selectedFolder {
  ASSIGN(self->selectedFolder, _selectedFolder);
}

- (void)setOnClick:(NSString *)_onClick {
  id tmp = self->onClick;
  self->onClick = [_onClick copyWithZone:[self zone]];
  RELEASE(tmp);
}
- (NSString *)onClick {
  return self->onClick;
}

- (void)setDroppedMail:(NGImap4Message *)_mail {
  ASSIGN(self->droppedMail, _mail);
}
- (NGImap4Message *)droppedMail {
  return self->droppedMail;
}


- (LSWTreeState *)treeState {
  return self->treeState;
}

- (NSArray *)rootFolders {
  return (self->rootFolder)
    ? [NSArray arrayWithObject:self->rootFolder]
    : [NSArray array];
}

// --- conditionals ---------------------------------------------------------

- (BOOL)isSelectedFolder {
  return [self->folder isEqual:self->selectedFolder];
}

- (BOOL)hasNewOrUnseenMails {
  BOOL recursive = [self->treeState isExpanded];
  
  if ([self->folder hasNewMessagesSearchRecursiv:!recursive] ||
      [self->folder hasUnseenMessagesSearchRecursiv:!recursive])
    return YES;
  return NO;
}

- (BOOL)hasParent {
  return [self->folder parentFolder] != nil;
}

// --- actions --------------------------------------------------------------

- (id)_folderClicked {
  [self setSelectedFolder:self->folder];
  return [self performParentAction:self->onClick];
}

- (id)folderClicked {
  self->showAllMessages = 0;
  return [self _folderClicked];
}

- (id)showAllMessagesAction {
  self->showAllMessages = 1;
  return [self _folderClicked];
}

- (id)showUnreadMessagesAction {
  self->showAllMessages = -1;
  return [self _folderClicked];
}

// --------------------------------------------------------------------------

- (NSString *)folderKeyPath { // used by treeState
  return [self->folder absoluteName];
}

- (NSString *)_iconName {
  NSMutableString *result;
  BOOL          recursive;
  static NSString *arrow = @"_green_arrow_13.gif";
  static NSString *point = @"_green_point_13.gif";
  static NSString *other = @"_13.gif";
  
  result = [NSMutableString stringWithCapacity:64];
  recursive = [self->treeState isExpanded];
  
  [result appendString:([self isSelectedFolder]) ? @"opened" : @"closed"];

  {
    NSException *localException;
    
    [self->folder resetLastException];
    
    if ([self->folder hasNewMessagesSearchRecursiv:!recursive])
      [result appendString:arrow];
    else if ([self->folder hasUnseenMessagesSearchRecursiv:!recursive])
      [result appendString:point];
    else
      [result appendString:other];

    if ((localException = [self->folder lastException])) {
      [self logWithFormat:@"%s: got exception[display:%@] %@",
            __PRETTY_FUNCTION__,
            DisplayImapExceptions ? @"YES" : @"NO",
            [localException description]];

      if (DisplayImapExceptions) {
        [(id)[[self context] page] setErrorString:
	       [localException description]];
        [result appendString:other];
      }
    }
  }  
  return result;
}

- (int)showAllMessages {
  return self->showAllMessages;
}
- (void)setShowAllMessages:(int)_showAllMessages {
  self->showAllMessages = _showAllMessages;
}

- (NSString *)cornerFolderIcon {
  return [NSString stringWithFormat:@"folder_corner_%@", [self _iconName]];
}

- (NSString *)folderIcon {
  return [NSString stringWithFormat:@"folder_%@", [self _iconName]];
}

- (NSString *)folderBGColor {
  id conf = [self performParentAction:@"config"];

  if ([self isSelectedFolder])
    return [conf valueForKey:@"colors_mainButtonRow"];
  if (![self hasParent])
    return [conf valueForKey:@"colors_tableHeaderRow"];
  else
    return [conf valueForKey:@"colors_tableViewContentCell"];
}

- (BOOL)showAllUnreadIcons {
  return [[[self session] userDefaults]
                 boolForKey:@"mail_show_all_unread_links"];
}

/* actions */

- (id)droppedMailOnFolder {
  if (self->droppedMail) {
    NSException          *localException;
    NSNotificationCenter *nc;
    NSArray              *mesgs;

    [self->droppedMail resetLastException];
      
    nc    = [NSNotificationCenter defaultCenter];      
    mesgs = [NSArray arrayWithObjects:self->droppedMail, nil];
    
    [[self->droppedMail folder] moveMessages:mesgs toFolder:self->folder];
    [nc postNotificationName:LSWImapMailWasDeleted object:mesgs];
    
    if ((localException = [self->droppedMail lastException]))
      [(id)[[self context] page] setErrorString:DnDCoundNotMoveMail];
  }
  else {
    [(id)[[self context] page] setErrorString:DnDCoundNotMoveMail];
  }
  return nil;
}

@end /* SkyImapMailFolderTree */
