/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "LSWImapMailMove.h"
#include "common.h"

@implementation LSWImapMailMove

- (id)init {
  if ((self = [super init])) {
    self->treeState = [[LSWTreeState alloc] initWithObject:self
                                            pathKey:@"folderKeyPath"];
    [self->treeState read:@"MailFolderMove"];
  }
  return self;
}

- (void)dealloc {
  [self->currentFolder release];
  [self->mail          release];
  [self->mails         release];
  [self->rootFolder    release];
  [self->treeState     release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->treeState write:@"MailFolderMove"];
  [super sleep];
}

/* accessors */

- (BOOL)isEditorPage {
  return NO;
}

- (void)setMails:(NSArray *)_mails {
  ASSIGNCOPY(self->mails, _mails);
}
- (NSArray *)mails {
  return self->mails;
}

- (void)setMail:(id)_mail {
  ASSIGN(self->mail, _mail);
}
- (id)mail {
  return self->mail;
}

- (id)rootFolder {
  if (self->rootFolder == nil) {
    if ([self->mails count] > 0) {
      self->rootFolder = [[[(NGImap4Message *)[self->mails objectAtIndex:0]
                                              context] serverRoot] retain];
    }
  }
  return self->rootFolder;
}

- (void)setCurrentFolder:(id)_folder {
  ASSIGN(self->currentFolder, _folder);
}
- (id)currentFolder {
  return self->currentFolder;
}

- (LSWTreeState *)treeState {
  return self->treeState;
}

- (NSArray *)rootFolders {
  return [NSArray arrayWithObject:[self rootFolder]];
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)folderClicked {
  NGMutableHashMap *map        = nil;
  NSEnumerator     *enumerator = nil;
  id               obj         = nil;

  map = [[NGMutableHashMap allocWithZone:[self zone]] initWithCapacity:64];

  enumerator = [self->mails objectEnumerator];
  while ((obj = [enumerator nextObject]))
    [map addObject:obj forKey:[obj folder]];

  enumerator = [map keyEnumerator];
  while ((obj = [enumerator nextObject])) {
    BOOL result;
    
    if (self->copyMode) {
      result = [obj copyMessages:[map objectsForKey:obj]
                    toFolder:self->currentFolder];
    }
    else {
      result = [obj moveMessages:[map objectsForKey:obj]
                    toFolder:self->currentFolder];
    }
    if (!result)
      break;
  }
  if (obj) { /* got error */
    NSString *warning;
    id       l;

    l       = [self labels];
    warning = [[self->currentFolder lastException] reason];

    if (self->copyMode) {
      warning = [NSString stringWithFormat:@"%@ : '%@'.",
                          [l valueForKey:@"CopyFailedWithReason"],
                          [l valueForKey:warning]];
    }
    else {
      warning = [NSString stringWithFormat:@"%@ : '%@'.",
                          [l valueForKey:@"MoveFailedWithReason"],
                          [l valueForKey:warning]];
    }
    [self setErrorString:warning];
  }
  if (!self->copyMode) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"LSWImapMailWasDeleted" object:self->mails];
  }
  ASSIGN(map, nil);

  if (!obj)
    [self leavePage];  
  
  return nil;
}

- (NSString *)folderKeyPath { // used by treeState
  return [self->currentFolder absoluteName];
}

- (NSString *)_iconName {
  NSMutableString *result;
  BOOL          recursive;
  static NSString *arrow = @"_green_arrow_13.gif";
  static NSString *point = @"_green_point_13.gif";
  static NSString *other = @"_13.gif";
  
  result    = [NSMutableString stringWithCapacity:64];
  recursive = [self->treeState isExpanded];
  
  [result appendString:@"closed"];

  {
    NSException *localException;

    [self->currentFolder resetLastException];

    if ([self->currentFolder hasNewMessagesSearchRecursiv:!recursive])
      [result appendString:arrow];
    else if ([self->currentFolder hasUnseenMessagesSearchRecursiv:!recursive])
      [result appendString:point];
    else
      [result appendString:other];

    if ((localException = [self->currentFolder lastException])) {
      [self setErrorString:[localException description]];
      [result appendString:other];
    }
  }
  return result;
}

- (NSString *)folderIcon {
  return [@"folder_" stringByAppendingString:[self _iconName]];
}

- (NSString *)cornerFolderIcon {
  return [@"folder_corner_" stringByAppendingString:[self _iconName]];
}

- (NSString *)folderBGColor {
  return [[self config] valueForKey:@"colors_attributeCell"];
}

- (BOOL)copyMode {
  return self->copyMode;
}
- (void)setCopyMode:(BOOL)_cp {
  self->copyMode = _cp;
}

- (NSString *)copyOrMoveTitle {
  return (self->copyMode)
    ? [[self labels] valueForKey:@"MailCopyTitle"]
    : [[self labels] valueForKey:@"MailMoveTitle"];
}

- (NSString *)copyOrMoveTo {
  return (self->copyMode)
    ? [[self labels] valueForKey:@"copyTo"]
    : [[self labels] valueForKey:@"moveTo"];
}

@end /* LSWImapMailMove */
