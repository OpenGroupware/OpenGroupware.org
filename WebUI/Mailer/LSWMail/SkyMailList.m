/*
  Copyright (C) 2000-2003 SKYRIX Software AG

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

#include "SkyMailList.h"
#include "common.h"
#include <OGoFoundation/LSWNotifications.h>

// TODO: is this actually used somewhere?

@interface SkyMailList(PrivateMethods)
- (void)_syncronizeFolder;
- (void)fetchFolder;
- (NSString *)isCheckedKey;
- (void)setFolder:(id)_folder;
- (void)setRootFolder:(id)_rootFolder;
- (void)setParentFolder:(id)_parentFolder;
@end

@implementation SkyMailList

static inline void _markFolderInDefaults(SkyMailList *self, id _folder,
                                         BOOL _all)
{
  NSString       *key  = @"LSMailsShowAllMessages_";
  NSUserDefaults *defs = [[self session] userDefaults];
  
  key = [key stringByAppendingString:[[_folder valueForKey:@"emailFolderId"]
                                               stringValue]];
  [self runCommand:@"userDefaults::write",
        @"key",      key,
        @"value",    [NSNumber numberWithBool:_all],
        @"userDefaults", defs, nil];
}

- (id)init {
  if ((self = [super init])) {
    self->checkList        = [[NSMutableArray alloc] initWithCapacity:10];
    self->navItemIndex     = 0;
    self->shouldSyncronize = YES;
    self->isShowAll        = NO;
    self->isNewSearch      = NO;
    
    [self registerForNotificationNamed:LSWNewMailFolderNotificationName];
    [self registerForNotificationNamed:LSWMailDeletedNotification];
    [self registerForNotificationNamed:LSWMailMovedNotification];
    [self registerForNotificationNamed:LSWMailFilterDidChangeNotificationName];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  RELEASE(self->rootFolder);
  RELEASE(self->selectedFolder);
  RELEASE(self->mails);
  RELEASE(self->mail);
  RELEASE(self->folderItem);
  RELEASE(self->checkList);
  RELEASE(self->selectedHeader);
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->shouldSyncronize) {
    [self fetchFolder];
    self->shouldSyncronize = NO;
    [self _syncronizeFolder];
    [self->checkList removeAllObjects];
  }
}

/* request handling */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  int i   = 0;
  int cnt = 0;
  
  [self _ensureSyncAwake];
  cnt = [self->mails count];

  for (i = 0; i < cnt; i++) {
    id   m         = [self->mails objectAtIndex:i];
    BOOL isChecked = [[m valueForKey:[self isCheckedKey]] boolValue];

    if (isChecked && ![self->checkList containsObject:m]) {
      [self->checkList addObject:m];
    }
    else if (!isChecked ) {
      [self->checkList removeObject:m];
    }
    [m takeValue:[NSNumber numberWithBool:NO] forKey:[self isCheckedKey]];
  }
  return [super invokeActionForRequest:_rq inContext:_ctx];
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWNewMailFolderNotificationName]) {
    self->shouldSyncronize = YES;
  }
  else if ([_cn isEqualToString:LSWMailDeletedNotification]) {
    [self _syncronizeFolder];
    [self->checkList removeAllObjects];
    self->isNewSearch = YES;
  }
  else if ([_cn isEqualToString:LSWMailMovedNotification]) {
    [self _syncronizeFolder];
    [self->checkList removeAllObjects];
    self->isNewSearch = YES;
  }
}

/* accessors */

- (void)setNavItemIndex:(unsigned)_idx {
  self->navItemIndex = _idx;
}
- (unsigned)navItemIndex {
  return self->navItemIndex;
}

- (void)setSelectedFolder:(id)_selectedFolder { 
  ASSIGN(self->selectedFolder, _selectedFolder);
}
- (id)selectedFolder {
  return self->selectedFolder;
}

- (void)setMails:(NSArray *)_mails {
  ASSIGN(self->mails, _mails);
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

- (NSString *)isCheckedKey {
  return @"isCheckedInMailList";
}

- (void)setSelectedHeader:(NSDictionary *)_selectedHeader {
  ASSIGN(self->selectedHeader, _selectedHeader);
}
- (NSDictionary *)selectedHeader {
  return self->selectedHeader;
}

- (void)setIsShowAll:(BOOL)_flag {
  self->isShowAll = _flag;
}
- (BOOL)isShowAll {
  return self->isShowAll;
}

- (void)setIsNewSearch:(BOOL)_flag {
  self->isNewSearch = _flag;
}
- (BOOL)isNewSearch {
  return self->isNewSearch;
}

- (BOOL)isTrashFolder {
  return
    [[self->selectedFolder valueForKey:@"name"]
                           isEqualToString:@"trash"] &&
    ([[self->selectedFolder valueForKey:@"isSpecial"] intValue] == 1);
}

- (BOOL)isNotTrashFolder {
  return ![self isTrashFolder];
}

- (BOOL)canDeleteFolder {
  return ![[self->selectedFolder valueForKey:@"isSpecial"] boolValue];
}

- (BOOL)canEditFolder {
  return ![[self->selectedFolder valueForKey:@"isSpecial"] boolValue];
}

- (BOOL)canMoveFolder {
  return ![[self->selectedFolder valueForKey:@"isSpecial"] boolValue];
}

- (id)folderItem {
  return self->folderItem;
}
- (void)setFolderItem:(id)_item {
  ASSIGN(self->folderItem, _item);
}

- (BOOL)isDescending {
  return self->isDescending;
}
- (void)setIsDescending:(BOOL)_flag {
  self->isDescending = _flag;
}

/* actions */

- (id)selectAll {
  int i, cnt = [self->mails count];
  
  for (i = 0; i < cnt; i++) {
    id m = [self->mails objectAtIndex:i];

    [m takeValue:[NSNumber numberWithBool:YES] forKey:[self isCheckedKey]];
  }
  return nil;
}

- (id)showAll {
  self->isShowAll = YES;
  _markFolderInDefaults(self, self->selectedFolder, YES);  
  [self _syncronizeFolder];  
  [self->checkList removeAllObjects];
  return nil;
}

- (id)showUnread {
  self->isShowAll = NO;
  _markFolderInDefaults(self, self->selectedFolder, NO);      
  [self _syncronizeFolder];  
  [self->checkList removeAllObjects];
  return nil;
}
 
- (id)moveMail {
  OGoContentPage *page;
  
  if ([self->checkList count] == 0)
    return nil;

  page = [self pageWithName:@"LSWMailMove"];
  [(id)page setMails:self->checkList];
  self->shouldSyncronize = YES;
  self->isNewSearch      = YES;
  [self enterPage:page];
  return nil; // TODO: can't we just return the page?
}

- (id)moveFolder {
  OGoContentPage *page;
  
  page = [self pageWithName:@"LSWMailFolderMove"];
  [(id)page setFolder:self->selectedFolder];
  [(id)page setRootFolder:self->rootFolder];
  [self enterPage:page];
  self->shouldSyncronize = YES;  
  return nil; // TODO: can't we just return the page?
}

- (id)deleteMail {
  if ([[self->selectedFolder valueForKey:@"name"] isEqualToString:@"trash"]) {
    NSEnumerator *enumerator = nil;
    id           obj         = nil;

    enumerator = [self->checkList objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      [self runCommandInTransaction:@"email::delete",
            @"object", obj, nil];
    }
  }
  else {
    [self runCommandInTransaction:@"email::remove",
          @"objects", self->checkList, nil];
  }
  [self _syncronizeFolder];
  [self->checkList removeAllObjects];
  self->isNewSearch = YES;
  return nil;
}

- (id)deleteFolder {
  [self->selectedFolder run:@"emailfolder::remove", nil];
  {
    id tmp = self->selectedFolder;
    self->selectedFolder = [self->selectedFolder valueForKey:@"parent"];
    RETAIN(self->selectedFolder);
    RELEASE(tmp); tmp = nil;
  }
  [self->checkList removeAllObjects];
  [self _syncronizeFolder];
  //[self setIsInWarningMode:NO];
  self->isNewSearch = YES;
  return nil;
}

- (id)emptyTrash {
  [self runCommandInTransaction:@"email::empty-trash", nil];
  [self _syncronizeFolder];
  [self->checkList removeAllObjects];
  self->isNewSearch = YES;
  //[self setIsInWarningMode:NO];
  return nil;
}

- (id)markRead {
  NSEnumerator *mailEnum = [self->checkList objectEnumerator];
  id           myMail;

  while ((myMail = [mailEnum nextObject])) {
    [myMail run:@"email::mark-read", nil];
  }

  [self->checkList removeAllObjects];
  return nil;
}

- (id)markUnread {
  NSEnumerator *mailEnum = [self->checkList objectEnumerator];
  id           myMail;

  while ((myMail = [mailEnum nextObject])) {
    [myMail run:@"email::mark-unread", nil];
  }

  [self->checkList removeAllObjects];
  return nil;
}

- (id)newFolder {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"emailfolder"];
  WOComponent *ct = nil;

  self->shouldSyncronize = YES;
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];

  if (![self->selectedFolder isKindOfClass:[NSDictionary class]]) {
    [(id)ct setParentFolder:self->selectedFolder];
  }
  [self enterPage:(id)ct];
  return nil;
}

- (id)editFolder {
  if ([[self->selectedFolder valueForKey:@"isSpecial"] intValue] == 1) {
    return nil;
  }
  else {
    NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"emailfolder"];
    WOComponent *ct = nil;

    [[self session] transferObject:self->selectedFolder owner:self];
    ct = [[self session] instantiateComponentForCommand:@"edit" type:mt];
    [self enterPage:(id)ct];
    return nil;
  }
}

- (id)viewMail {
  [self->mail run:@"email::mark-read", nil];
  return [self activateObject:self->mail withVerb:@"view"];
}

- (id)newMail {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"email"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  [self enterPage:(id)ct];
  return nil;
}

- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;
}

- (void)fetchFolder {
  NSArray *folders = nil;
  self->navItemIndex = 1;
  
  RELEASE(self->rootFolder); self->rootFolder = nil;
  
  self->rootFolder = [[NSMutableDictionary allocWithZone:[self zone]] init];
  
  [self->rootFolder takeValue:@"Local Mail" forKey:@"name"];
  [self->rootFolder takeValue:[NSNumber numberWithBool:YES]
                    forKey:@"isSpecial"];    
  // fetch root folder

  folders = [self runCommand:@"emailfolder::get", nil];

  if ([folders count] == 0) {
    [self runCommand:@"emailfolder::build-special-folders", nil];
    folders = [self runCommand:@"emailfolder::get", nil];
  }
  
  [self->rootFolder takeValue:folders forKey:@"folder"];
  {
    NSEnumerator *enumerator;
    id           fo;

    enumerator = [folders objectEnumerator];
    
    while ((fo = [enumerator nextObject])) {
      [fo takeValue:self->rootFolder forKey:@"parent"];      
    }
  }
  if (self->selectedFolder == nil) {
    NSEnumerator *enumerator;
    id           fo;

    enumerator = [folders objectEnumerator];

    while ((fo = [enumerator nextObject])) {
      if (([[fo valueForKey:@"name"] isEqualToString:@"inbox"])) {
        ASSIGN(self->selectedFolder, fo);        
        break;
      }
    }
    if ((self->selectedFolder == nil)) {
      [self runCommand:@"emailfolder::build-special-folders", nil];
      folders = [self runCommand:@"emailfolder::get", nil];
      
      [self->rootFolder takeValue:folders forKey:@"folder"];  
      ASSIGN(self->selectedFolder, self->rootFolder);
    }
  }
}

- (id)rootFolder {
  return self->rootFolder;
}

- (id)selectedFolderClicked {
  [self _syncronizeFolder];
  return nil;
}

- (NSString *)moreInfos {
  int      cntAll = 0;
  int      cntUnr = 0;
  NSString *res   = nil;
  
  cntAll =
    [[self->folderItem run:@"emailfolder::count-messages", nil] intValue];
  cntUnr =
    [[self->folderItem run:@"emailfolder::count-unread-messages", nil] intValue];

  res = (cntUnr > 0)
    ? [NSString stringWithFormat:@"( %d / %d )", cntUnr, cntAll]
    : [NSString stringWithFormat:@"( %d )", cntAll];
  
  return res;
}

- (BOOL)hasSubFolders {
  if ([self->selectedFolder isKindOfClass:[EOGenericRecord class]]) {  
    if ([[self runCommand:@"emailfolder::get",
                 @"parentFolder", self->selectedFolder, nil] count] > 0)
      return YES;
  }
  else 
    return YES;
  return NO;
}

- (NSArray *)selectedSubFolder {
  if ([self->selectedFolder isKindOfClass:[EOGenericRecord class]]) {
    NSEnumerator  *enumerator = nil;
    NSArray       *folders    = nil;
    id            obj         = nil;

    folders = [self runCommand:@"emailfolder::get",
                    @"parentFolder", self->selectedFolder,                  
                    nil];
    enumerator = [folders objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      [obj takeValue:self->selectedFolder forKey:@"parent"];
    }
    return folders;
  }
  return [self->selectedFolder valueForKey:@"folder"];    
}
 
- (id)folderClicked {
  ASSIGN(self->selectedFolder, self->folderItem);
  return [self selectedFolderClicked];
}


/* private methodes */

- (void)_syncronizeFolder {
  if ([self->selectedFolder isKindOfClass:[EOGenericRecord class]]) {
    LSSort  *sorter;

    { /* set show-read */
      id boolValue = [[[self session] userDefaults]
                               objectForKey:[@"LSMailsShowAllMessages_"
                                              stringByAppendingString:
                       [[self->selectedFolder valueForKey:@"emailFolderId"]
                                              stringValue]]];
      if (boolValue != nil) 
        self->isShowAll = [boolValue boolValue];
      else
        self->isShowAll = YES;
    }

    [self->selectedFolder run:@"emailfolder::fetch-content",
         @"fetchOnlyUnread", [NSNumber numberWithBool:!self->isShowAll], nil];

    if (self->selectedHeader != nil) {
      sorter = [LSSort sortWithArray:[self->selectedFolder valueForKey:@"email"]
                       andContext:[self->selectedHeader objectForKey:@"key"]];
      [sorter setOrdering:(self->isDescending) ? 1 : -1];
      [self setMails:[sorter sortedArray]];
    } else {
      [self setMails:[self->selectedFolder valueForKey:@"email"]];      
    }
  }
  else {
    NSArray *f = [self runCommandInTransaction:@"emailfolder::get", nil];
    
    [self->rootFolder     takeValue:f forKey:@"folder"];
    [self->selectedFolder takeValue:f forKey:@"folder"];
    [self setMails:[NSArray array]];
  }
}

@end /* SkyMailList */
