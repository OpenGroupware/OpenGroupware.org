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

#include <OGoFoundation/OGoComponent.h>

@class NGImap4Folder, NGImap4Context;

@interface SkyImapMailListFooter : OGoComponent
{
  NGImap4Folder *selectedFolder;
  struct {
    BOOL showTree:1;
    BOOL isTrashEmpty:1;
    BOOL canMoveFolder:1;
    BOOL allowNewFilter:1;
    BOOL canDeleteFolder:1;
    BOOL serverHasFilter:1;
    BOOL canEditFolder:1;
    BOOL canNewFolder:1;
    int  reserved:24;
  } flags;
}
@end

#import "common.h"

@implementation SkyImapMailListFooter

- (void)dealloc {
  [self->selectedFolder release];
  [super dealloc];
}

/* accessors */

- (void)setSelectedFolder:(NGImap4Folder *)_selectedFolder {
  ASSIGN(self->selectedFolder, _selectedFolder);
}
- (NGImap4Folder *)selectedFolder {
  return self->selectedFolder;
}

- (void)setShowTree:(BOOL)_showTree {
  self->flags.showTree = _showTree;
}
- (BOOL)showTree {
  return self->flags.showTree;
}

- (NSArray *)folders {
  NSArray        *folders;
  NSMutableArray *tmp;
  NGImap4Folder  *fold;
  id             *objs;
  int            i, cnt;
    
  fold = [self selectedFolder];
  tmp  = [[NSMutableArray alloc] initWithObjects:fold, nil];

  while (([fold = (id)[fold parentFolder] isNotNull]))
    [tmp addObject:fold];
  
  folders = tmp;
  cnt     = [folders count];
  objs    = malloc(sizeof(id) * cnt);
  
  for (i = 0; i < cnt; i++) {
    objs[i] = [folders objectAtIndex:(cnt - i - 1)];
  }
  tmp = [NSArray arrayWithObjects:objs count:cnt];
  [folders release]; folders = nil;
  free(objs);        objs    = NULL;
  return tmp;
}

/* actions */

- (id)newFolder {
  return [self performParentAction:@"newFolder"];
}

- (id)editFolder {
  return [self performParentAction:@"editFolder"];
}

- (id)moveFolder {
  return [self performParentAction:@"moveFolder"];
}

- (id)deleteFolder {
  return [self performParentAction:@"deleteFolder"];
}

- (id)newMail {
  return [self performParentAction:@"newMail"];
}

- (id)newFilterForFolder {
  return [self performParentAction:@"newFilterForFolder"];
}

- (id)emptyTrash {
  return [self performParentAction:@"emptyTrash"];
}

- (id)folderClicked {
  [self setSelectedFolder:[self valueForKey:@"folder"]];
  return [self performParentAction:@"folderClicked"];
}

- (id)doShowTree {
  [self setShowTree:YES];
  return nil;
}

- (id)doHideTree {
  [self setShowTree:NO];
  return nil;
}

- (BOOL)isTrashEmpty {
  return self->flags.isTrashEmpty;
}
- (void)setIsTrashEmpty:(BOOL)_b {
  self->flags.isTrashEmpty = _b ? 1 : 0;
}
- (BOOL)canMoveFolder {
  return self->flags.canMoveFolder;
}
- (void)setCanMoveFolder:(BOOL)_b {
  self->flags.canMoveFolder = _b ? 1 : 0;
}
- (BOOL)allowNewFilter {
  return self->flags.allowNewFilter;
}
- (void)setAllowNewFilter:(BOOL)_b {
  self->flags.allowNewFilter = _b ? 1 : 0;
}
- (BOOL)canDeleteFolder {
  return self->flags.canDeleteFolder;
}
- (void)setCanDeleteFolder:(BOOL)_b {
  self->flags.canDeleteFolder = _b ? 1 : 0;
}
- (BOOL)serverHasFilter {
  return self->flags.serverHasFilter;
}
- (void)setServerHasFilter:(BOOL)_b {
  self->flags.serverHasFilter = _b ? 1 : 0;
}
- (BOOL)canEditFolder {
  return self->flags.canEditFolder;
}
- (void)setCanEditFolder:(BOOL)_b {
  self->flags.canEditFolder = _b ? 1 : 0;
}
- (BOOL)canNewFolder {
  return self->flags.canNewFolder;
}
- (void)setCanNewFolder:(BOOL)_bool {
  self->flags.canNewFolder = _bool ? 1 : 0;
}

@end /* SkyImapMailListFooter */
