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

#include "LSWImapMailFolderTree.h"
#include "common.h"

// TODO: needs cleanup!

@implementation LSWImapMailFolderTree

- (id)init {
  if ((self = [super init])) {
    self->folderStack = [[NSMutableArray alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->rootFolder           release];
  [self->folder               release];
  [self->subFolder            release];
  [self->folderStack          release];
  [self->onClick              release];
  [self->compareObj           release];
  [self->idName               release];
  [self->subFolderAction      release];
  [self->moreInfosAction      release];  
  [self->subFolderTitleAction release];
  [self->folderTitleAction    release];
  [self->parentFolderAction   release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  [self->folderStack removeAllObjects];
  [self folderClicked];
}

/* accessors */

- (NSArray *)folderStack {
  return self->folderStack;
}

- (void)setNavItemIndex:(unsigned)_idx {
  self->navItemIndex = _idx;
}
- (unsigned)navItemIndex {
  return self->navItemIndex;
}

- (NSArray *)folders {
  return [self->folder subFolders];
}

- (void)setFolder:(id)_folder {
  ASSIGN(self->folder, _folder);
}
- (id)folder {
  return self->folder;
}

- (void)setSubFolder:(id)_subFolder {
  ASSIGN(self->subFolder, _subFolder);
}
- (id)subFolder {
  return self->subFolder;
}

- (void)setOnClick:(NSString *)_onClick {
  ASSIGNCOPY(self->onClick, _onClick);
}
- (NSString *)onClick {
  return self->onClick;
}

- (void)setCompareObj:(id)_obj {
  ASSIGN(self->compareObj, _obj);;
}
- (id)compareObj {
  return self->compareObj;
}

- (void)setIdName:(NSString *)_idName {
  ASSIGN(self->idName, _idName);;
}
- (NSString *)idName {
  return self->idName;
}

- (void)setSubFolderAction:(NSString *)_action {
  ASSIGN(self->subFolderAction, _action);
}
- (id)subFolderAction {
  return self->subFolderAction;
}

- (void)setMoreInfosAction:(NSString *)_action {
  ASSIGN(self->moreInfosAction, _action);
}
- (id)moreInfosAction {
  return self->moreInfosAction;
}

- (void)setParentFolderAction:(NSString *)_action {
  ASSIGN(self->parentFolderAction, _action);
}
- (id)parentFolderAction {
  return self->parentFolderAction;
}

- (BOOL)isLastNavLink {
  return (self->navItemIndex == ([self->folderStack count] - 1)) ? YES : NO;
}

- (BOOL)isFolderOpen {
  return ([self->folderStack containsObject:self->subFolder]) ? YES : NO;
}

- (NSString *)subFolderTitleAction {
  return self->subFolderTitleAction;
}
- (void)setSubFolderTitleAction:(NSString *)_action {
  ASSIGN(self->subFolderTitleAction, _action);
}

- (NSString *)folderTitleAction {
  return self->folderTitleAction;
}
- (void)setFolderTitleAction:(NSString *)_action {
  ASSIGN(self->folderTitleAction, _action);
}

- (NSString *)subFolderId {
  return [[self->subFolder valueForKey:self->idName] stringValue];
}
- (NSString *)folderId {
  return [[self->folder valueForKey:self->idName] stringValue];
}

- (NSString *)subFolderTitle {
  return [(NGImap4Folder *)self->subFolder name];
}
- (NSString *)folderTitle {
  return [(NGImap4Folder *)self->folder name];
}

- (NSNumber *)showRootFolder {
  return self->showRootFolder;
}
- (void)setShowRootFolder:(NSNumber *)_bool {
  ASSIGN(self->showRootFolder, _bool);
}

- (NSString *)moreInfos {
  return [self performParentAction:self->moreInfosAction];
}

- (NSString *)rootFolderMoreInfos {
  [self setSubFolder:self->rootFolder];
  return [self performParentAction:self->moreInfosAction];
}

/* folder stack */

- (void)_rebuildFolderStack {
  NGImap4Folder *pFolder;

  [self->folderStack removeAllObjects];

  pFolder = [self folder];
  while ((pFolder != nil)) {
    [self->folderStack insertObject:pFolder atIndex:0];
    pFolder = (NGImap4Folder *)[pFolder parentFolder];
    if (pFolder == nil)
      pFolder = self->rootFolder;
  }
}


- (void)folderClicked {
  [self _rebuildFolderStack];
}
- (void)folderClicked:(id)_newFolder {
  [self setFolder:_newFolder];
  [self _rebuildFolderStack];
}

- (NSString *)rootFolderTitle {
  return [(NGImap4Folder *)self->rootFolder name];
}

- (NSString *)folderIcon {
  NGImap4Folder *f = self->subFolder;

  if ([self isFolderOpen]) {
    if ([f hasNewMessagesSearchRecursiv:NO])
      return @"folder_open_green_arrow.gif";

    if ([f hasUnseenMessagesSearchRecursiv:NO] > 0)
      return @"folder_open_green_point.gif";

    return @"folder_opened.gif";
  }
  else {
    if ([f hasNewMessagesSearchRecursiv:YES])
      return @"ordner_unread.gif";

    if ([f hasUnseenMessagesSearchRecursiv:YES])
      return @"ordner_green_point.gif";

    return @"folder_closed.gif";
  }
}

- (NSString *)rootFolderIcon {
  NGImap4Folder *f = self->rootFolder;

  if ([f hasNewMessagesSearchRecursiv:NO])
    return @"folder_open_green_arrow.gif";

  if ([f hasUnseenMessagesSearchRecursiv:NO])
    return @"folder_open_green_point.gif";

  return @"folder_opened.gif";
}

/* actions */

- (id)rootFolderClicked {
  [self folderClicked:self->rootFolder];
  return [self performParentAction:[self onClick]];
}

- (id)subFolderClicked {
  [self folderClicked:self->subFolder];
  return [self performParentAction:[self onClick]];
}

- (id)rootFolder {
  return self->rootFolder;
}
- (void)setRootFolder:(id)_f {
  ASSIGN(self->rootFolder, _f);
}

- (NSString *)selectedFolderColor {
  return [[self performParentAction:@"config"]
                valueForKey:@"colors_selectedMailColor"];
}

- (NSString *)bgColorForFolder {
  if ([self isFolderOpen])
    return [self selectedFolderColor];
  
  return [[self performParentAction:@"config"]
                valueForKey:@"colors_mainButtonRow"];
}

@end /* LSWImapMailFolderTree */
