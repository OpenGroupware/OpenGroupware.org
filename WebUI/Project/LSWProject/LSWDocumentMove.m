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

#include <OGoFoundation/LSWViewerPage.h>

@class NSMutableArray, NSMutableString, NSArray;

@interface LSWDocumentMove : LSWViewerPage
{
@private  
  NSMutableArray  *folderStack;
  NSMutableString *documentTitle;
  NSArray         *documents;
  NSArray         *badDocuments;
  unsigned        navItemIndex;
  id              project;
  id              folder;
  id              subFolder;

  NSArray         *folders;
}

- (void)setFolder:(id)_folder;

@end /* LSWDocumentMove */

#import "common.h"

@interface LSWDocumentMove(PrivateMethodes)
- (id)_moveDocuments;
- (void)_siftDocuments;
- (BOOL)_isMoveEnabledForDocument:(id)_doc;
- (BOOL)_isRootDocEqualToDoc:(id)_doc;
@end

@implementation LSWDocumentMove

static int compareDocumentEntries(id document1, id document2, void *context) {
  BOOL     doc1IsFolder, doc2IsFolder;
  NSString *title1, *title2;

  doc1IsFolder = [[document1 valueForKey:@"isFolder"] boolValue];
  doc2IsFolder = [[document2 valueForKey:@"isFolder"] boolValue];

  title1 = [document1 valueForKey:@"title"];
  title2 = [document2 valueForKey:@"title"];
  
  if (doc1IsFolder != doc2IsFolder)
    return doc1IsFolder ? -1 : 1;

  if (title1 == nil)
    title1 = @"";

  if (title2 == nil)
    title2 = @"";

  return [title1 compare:title2];
}

- (void)dealloc {
  [self->folderStack release];
  [self->documentTitle release];
  [self->documents release];
  [self->badDocuments release];
  [self->project release];
  [self->folder release];
  [self->subFolder release];
  [self->folders release];
  [super dealloc];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if ([super prepareForActivationCommand:_command type:_type
             configuration:_cmdCfg]) {
    id obj;

    obj = [self object];

    self->project = [[obj valueForKey:@"toProject"] retain];

    [self _siftDocuments];
    {
      id pFolder = nil;

      self->folderStack = [[NSMutableArray allocWithZone:[self zone]]
                                           initWithCapacity:16];

      pFolder = [obj valueForKey:@"toParentDocument"];
      [self setFolder:pFolder];
      
      while ([pFolder isNotNull]) {
        [self->folderStack insertObject:pFolder atIndex:0]; 
        pFolder = [pFolder valueForKey:@"toParentDocument"];
      }
    }
    
    {
      int i, cnt;

      cnt = [self->folderStack count];

      self->navItemIndex = [self->folderStack count] - 1;

      self->documentTitle = [[NSMutableString allocWithZone:[self zone]] init];

      for (i = 0; i < cnt; i++) {
        if (i) {
          [self->documentTitle appendString:@" / "];
        }
        [self->documentTitle appendString:
             [[self->folderStack objectAtIndex:i] valueForKey:@"title"]];
      }
      if ([self->documentTitle length]) {
        [self->documentTitle appendString:@" / "];
      }
      [self->documentTitle appendString:[obj valueForKey:@"title"]];

      if (![[obj valueForKey:@"isFolder"] boolValue]
          && ![[obj valueForKey:@"isObjectLink"] boolValue] ) {
        [self->documentTitle appendString:@"."];
        [self->documentTitle appendString:[obj valueForKey:@"fileType"]];
      }
    }
    return YES;
  }
  return NO;
}

// notifications

- (void)syncAwake {
  [super syncAwake];

  if (self->folderStack == nil) {
    self->folderStack = [[NSMutableArray allocWithZone:[self zone]]
                                         initWithCapacity:16];
    [self->folderStack addObject:self->folder];
  }
  else {
    if (self->navItemIndex < [self->folderStack count] - 1) {
      [self->folderStack removeObjectAtIndex:self->navItemIndex + 1];
    }
    if (![self->folderStack containsObject:self->folder]) {
     [self->folderStack addObject:self->folder];
    }
  }
}

// accessors

- (NSArray *)badDocuments {
  return self->badDocuments;
}

- (NSString *)documentTitle {
  return self->documentTitle;
}

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
  return self->folders;
}

- (void)setFolder:(id)_folder {
  if (_folder != self->folder) {
    ASSIGN(self->folder, _folder);
    
    [self->folders release]; self->folders = nil;
    self->folders =
      [[[_folder valueForKey:@"toDoc"]
                 sortedArrayUsingFunction:compareDocumentEntries
                 context:self]
                 copy];
  }
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

- (BOOL)isLastNavLink {
  return (self->navItemIndex == ([self->folderStack count] - 1)) ? YES : NO;
}

- (BOOL)isFolderOpen {
  return ([self->folderStack containsObject:self->subFolder]) ? YES : NO;
}

- (int)folderStackCount {
  return [self->folderStack count] + 1;
}

// actions

- (id)navigate { 
  [self->folderStack removeAllObjects];
  [self->folderStack addObject:self->folder];

  return nil;
}

- (void)folderClicked {
  unsigned int idx;
  
  idx = [self->folderStack indexOfObject:
               [self->folder valueForKey:@"toParentDocument"]];

  if (idx != NSNotFound) {
    unsigned i;

    for (i = [self->folderStack count] - 1; i > idx; i--) {
      [self->folderStack removeObjectAtIndex:i];
    }    
  }
  [self->folderStack addObject:self->folder];
}

- (id)subFolderClicked {
  ASSIGN(self->folder, self->subFolder);
  [self folderClicked];
    
  return nil;
}

- (id)move {
  id oldFolder = nil;
  
  [self subFolderClicked];

  if (self->documents != nil)
    return [self _moveDocuments];

  if ([[[self object] valueForKey:@"isFolder"] boolValue]) {
    oldFolder = [[self object] valueForKey:@"toParentDocument"];
  }

  if (![self->folder isEqual:[self object]]) {
    id result;

    result = [[self object] run:@"doc::move", @"folder", self->folder, nil];
    if (result) {
      [self postChange:LSWMovedDocumentNotificationName
            onObject:[self object]];

      if ([[[self object] valueForKey:@"isFolder"] boolValue]) {
        [self runCommand:@"doc::get", @"documentId",
              [oldFolder valueForKey:@"documentId"], nil];
      }
    }
  }
  [self leavePage];  

  return nil;
}

- (id)moveToRootFolder {
  id oldFolder = nil;
  
  [self navigate];
  
  if (self->documents != nil)
    return [self _moveDocuments];

  if ([[[self object] valueForKey:@"isFolder"] boolValue]) {
    oldFolder = [[self object] valueForKey:@"toParentDocument"];
  }  
  {
    id result;

    result = [[self object] run:@"doc::move", @"folder", self->folder, nil];
    if (result) {
      [self postChange:LSWMovedDocumentNotificationName
            onObject:[self object]];
      
      if ([[[self object] valueForKey:@"isFolder"] boolValue]) {
        [self runCommand:@"doc::get", @"documentId",
              [oldFolder valueForKey:@"documentId"], nil];
      }
    }
  }
  [self leavePage];  

  return nil;
}

// --- LSWDocumentMove(PrivateMethodes) -----------------------------------

- (id)_moveDocuments {
  NSEnumerator *docEnum;
  id           oldFolder = nil;
  id           doc;

  docEnum = [self->documents objectEnumerator];
  
  // all documents have the same parent folder...
  if ([[[self object] valueForKey:@"isFolder"] boolValue]) {
    oldFolder = [[self object] valueForKey:@"toParentDocument"];
  }
  while ((doc = [docEnum nextObject])) {
    if (![self->folder isEqual:doc]) {
      id result = nil;

      result = [self runCommand:@"doc::move",
                     @"object", doc,
                     @"folder", self->folder, nil];
      
      if (result) {
        [self postChange:LSWMovedDocumentNotificationName onObject:doc];
      
        if ([[doc valueForKey:@"isFolder"] boolValue]) {
          id toDoc = [oldFolder valueForKey:@"toDoc"];

          [toDoc clear];
        }
      }
    }
  }
  [self leavePage];

  return nil;
}

- (void)_siftDocuments {
  NSArray *docList;

  docList = [[self object] valueForKey:@"documentList"];
  
  if (docList != nil) {
    NSMutableArray *goodList, *badList;
    NSEnumerator   *docEnum;
    id             doc       = nil;

    goodList = [NSMutableArray arrayWithCapacity:4];
    badList = [NSMutableArray arrayWithCapacity:4];

    docEnum = [docList objectEnumerator];
    
    while ((doc = [docEnum nextObject])) {
      if ([self _isMoveEnabledForDocument:doc])
        [goodList addObject:doc];
      else
        [badList addObject:doc];
    }

    ASSIGN(self->documents,    goodList);
    ASSIGN(self->badDocuments, badList);

    [[self object] takeValue:nil forKey:@"documentList"];
  }
  else {
    [self->documents release]; self->documents = nil;
    ASSIGN(self->badDocuments, [NSArray array]);
  }
}

- (BOOL)_isMoveEnabledForDocument:(id)_doc {
  if ([[_doc valueForKey:@"isFolder"] boolValue])
    return YES;
  if ([[_doc valueForKey:@"isObjectLink"] boolValue]) {
    [self runCommand:@"doc::get", @"documentId",
          [_doc valueForKey:@"documentId"], nil];
    return YES; // is document link
  }
  
  if (![[_doc valueForKey:@"isIndexDoc"] boolValue]) {
    BOOL isEnabled  = NO;
    id   sn         = [self session];
    id   myAccount  = [sn activeAccount];
    id   accountId  = [myAccount valueForKey:@"companyId"];

    isEnabled = [accountId isEqual:[_doc valueForKey:@"firstOwnerId"]];
    isEnabled = isEnabled || [sn activeAccountIsRoot];
    
    return (isEnabled &&
            [[_doc valueForKey:@"status"] isEqualToString:@"released"]);
  }
  return YES;
}

@end /* LSWDocumentMove */
