/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include <SOGoUI/UIxComponent.h>

@interface UIxMailTree : UIxComponent
{
  id rootNodes;
  id item;
}
@end

#include "UIxMailTreeBlock.h"
#include <SoObjects/Mailer/SOGoMailBaseObject.h>
#include <SoObjects/Mailer/SOGoMailAccount.h>
#include "common.h"
#include <NGObjWeb/SoComponent.h>
#include <NGObjWeb/SoObject+SoDAV.h>

/*
  Support special icons:
    tbtv_leaf_corner_17x17.gif
    tbtv_inbox_17x17.gif
    tbtv_drafts_17x17.gif
    tbtv_sent_17x17.gif
    tbtv_trash_17x17.gif
*/

@implementation UIxMailTree

- (void)dealloc {
  [self->rootNodes release];
  [self->item      release];
  [super dealloc];
}

/* icons */

- (NSString *)defaultIconName {
  return @"tbtv_leaf_corner_17x17.gif";
}

- (NSString *)iconNameForType:(NSString *)_type {
  if (![_type isNotNull])
    return [self defaultIconName];
  
  //return @"tbtv_drafts_17x17.gif";
  
  return [self defaultIconName];
}

/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemIconName {
  // TODO: only called once!
  NSString *ftype;
  
  ftype = [[self item] valueForKey:@"outlookFolderClass"];
  return [self iconNameForType:ftype];
}

/* fetching subfolders */

- (NSArray *)fetchSubfoldersOfObject:(id)_object {
  /* Walk over toManyRelationshipKeys and lookup the controllers for them. */
  NSMutableArray *ma;
  NSArray  *names;
  unsigned i, count;
  
  if ((names = [_object toManyRelationshipKeys]) == nil)
    return nil;
  
  count = [names count];
  ma    = [NSMutableArray arrayWithCapacity:(count + 1)];
  for (i = 0; i < count; i++) {
    id folder;
    
    folder = [_object lookupName:[names objectAtIndex:i] inContext:nil 
		      acquire:NO];
    if (folder == nil)
      continue;
    if ([folder isKindOfClass:[NSException class]])
      continue;
    
    [ma addObject:folder];
  }
  return ma;
}

/* navigation nodes */

- (BOOL)isRootObject:(id)_object {
  if (![_object isNotNull]) {
    [self warnWithFormat:@"(%s): got to root by nil lookup ...",
            __PRETTY_FUNCTION__];
    return YES;
  }
  
  // TODO: make this a parameter to make UIxMailTree reusable
  return [_object isKindOfClass:NSClassFromString(@"SOGoMailAccount")];
}

- (NSString *)treeNavigationLinkForObject:(id)_object atDepth:(int)_depth {
  NSString *link;
  unsigned i;
  
  link = [[_object nameInContainer] stringByAppendingString:@"/"];
  for (i = 0; i < _depth; i++)
    link = [@"../" stringByAppendingString:link];
  return link;
}

- (void)getTitle:(NSString **)_t andIcon:(NSString **)_icon
  forObject:(id)_object
{
  // TODO: need to refactor for reuse!
  NSString *ftype;
  unsigned len;
  
  ftype = [_object valueForKey:@"outlookFolderClass"];
  len   = [ftype length];
  
  switch (len) {
  case 8:
    if ([ftype isEqualToString:@"IPF.Sent"]) {
      *_t = [self labelForKey:@"SentFolderName"];
      *_icon = @"tbtv_sent_17x17.gif";
      return;
    }
    break;
  case 9:
    if ([ftype isEqualToString:@"IPF.Inbox"]) {
      *_t = [self labelForKey:@"InboxFolderName"];
      *_icon = @"tbtv_inbox_17x17.gif";
      return;
    }
    if ([ftype isEqualToString:@"IPF.Trash"]) {
      *_t = [self labelForKey:@"TrashFolderName"];
      *_icon = @"tbtv_trash_17x17.gif";
      return;
    }
    break;
  case 10:
    if ([ftype isEqualToString:@"IPF.Drafts"]) {
      *_t = [self labelForKey:@"DraftsFolderName"];
      *_icon = @"tbtv_drafts_17x17.gif";
      return;
    }
    if ([ftype isEqualToString:@"IPF.Filter"]) {
      *_t = [self labelForKey:@"SieveFolderName"];
      *_icon = nil;
      return;
    }
    break;
  }
  
  *_t    = [_object davDisplayName];
  *_icon = nil;
  return;
}

- (UIxMailTreeBlock *)treeNavigationBlockForLeafNode:(id)_o atDepth:(int)_d {
  UIxMailTreeBlock *md;
  NSString *n, *i;
  id blocks;
  
  /* 
     Trigger plus in treeview if it has subfolders. It is an optimization that
     we do not generate blocks for folders which are not displayed anyway.
  */
  blocks = [[_o toManyRelationshipKeys] count] > 0
    ? [[NSArray alloc] initWithObjects:@"FAKE", nil]
    : nil;

  [self getTitle:&n andIcon:&i forObject:_o];
  
  md = [UIxMailTreeBlock blockWithName:nil
			 title:n iconName:i
			 link:[self treeNavigationLinkForObject:_o atDepth:_d]
			 isPathNode:NO isActiveNode:NO
			 childBlocks:blocks];
  return md;
}

- (UIxMailTreeBlock *)treeNavigationBlockForRootNode:(id)_object {
  /*
     This generates the block for the root object (root of the tree, we get
     there by walking up the chain starting with the client object).
  */
  UIxMailTreeBlock *md;
  NSMutableArray   *blocks;
  NSArray          *folders;
  NSString         *title, *icon;
  unsigned         i, count;
  
  /* process child folders */
  
  folders = [self fetchSubfoldersOfObject:_object];
  count   = [folders count];
  blocks  = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    id block;
    
    block = [self treeNavigationBlockForLeafNode:[folders objectAtIndex:i]
		  atDepth:0];
    if ([block isNotNull]) [blocks addObject:block];
  }
  if ([blocks count] == 0)
    blocks = nil;
  
  /* build block */
  
  [self getTitle:&title andIcon:&icon forObject:_object];
  md = [UIxMailTreeBlock blockWithName:[_object nameInContainer]
			 title:title iconName:icon
			 link:[@"../" stringByAppendingString:
				  [_object nameInContainer]]
			 isPathNode:YES isActiveNode:YES
			 childBlocks:blocks];
  return md;
}

- (UIxMailTreeBlock *)treeNavigationBlockForActiveNode:(id)_object {
  /* 
     This generates the block for the clientObject (the object which has the 
     focus)
  */
  UIxMailTreeBlock *md;
  NSMutableArray   *blocks;
  NSArray  *folders;
  NSString *title, *icon;
  unsigned i, count;
  
  // TODO: maybe we can join the two implementations, this might not be
  //       necessary
  if ([self isRootObject:_object]) /* we are at the top */
    return [self treeNavigationBlockForRootNode:_object];
  
  /* process child folders */
  
  folders = [self fetchSubfoldersOfObject:_object];
  count   = [folders count];
  blocks  = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    UIxMailTreeBlock *block;
    
    block = [self treeNavigationBlockForLeafNode:[folders objectAtIndex:i]
		  atDepth:0];
    if ([block isNotNull]) [blocks addObject:block];
  }
  if ([blocks count] == 0) blocks = nil;
  
  /* build block */
  
  [self getTitle:&title andIcon:&icon forObject:_object];
  md = [UIxMailTreeBlock blockWithName:[_object nameInContainer]
			 title:title iconName:icon
			 link:@"."
			 isPathNode:YES isActiveNode:YES
			 childBlocks:blocks];
  return md;
}

- (UIxMailTreeBlock *)treeNavigationBlockForObject:(id)_object
  withActiveChildBlock:(UIxMailTreeBlock *)_activeChildBlock 
  depth:(int)_depth
{
  UIxMailTreeBlock *md;
  NSMutableArray   *blocks;
  NSString         *activeName;
  NSArray          *folders;
  NSString         *title, *icon;
  unsigned         i, count;
  
  if ([self isRootObject:_object]) /* we are at the top */
    return _activeChildBlock;
  
  /* the following is not run on the OGoMailAccounts (root) object */
  
  activeName = [_activeChildBlock valueForKey:@"name"];
  
  /* process child folders */
  
  folders = [self fetchSubfoldersOfObject:_object];
  count   = [folders count];
  blocks  = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    UIxMailTreeBlock *block;
    id folder;
    
    folder = [folders objectAtIndex:i];
    block = [activeName isEqualToString:[folder nameInContainer]]
      ? _activeChildBlock
      : [self treeNavigationBlockForLeafNode:folder atDepth:_depth];
    
    if ([block isNotNull]) [blocks addObject:block];
  }
  if ([blocks count] == 0) blocks = nil;
  
  /* build block */
  
  [self getTitle:&title andIcon:&icon forObject:_object];
  md = [UIxMailTreeBlock blockWithName:[_object nameInContainer]
			 title:title iconName:icon
			 link:[self treeNavigationLinkForObject:_object 
				    atDepth:(_depth + 1)] 
			 isPathNode:YES isActiveNode:NO
			 childBlocks:blocks];
  
  /* recurse up */
  
  return [self treeNavigationBlockForObject:[_object container] 
	       withActiveChildBlock:md
	       depth:(_depth + 1)];
}

- (id)buildNavigationNodesForObject:(id)_object {
  id block;
  
  block = [self treeNavigationBlockForActiveNode:_object];
  
  if ([self isRootObject:_object])
    return block;
  
  /* the following returns the root block! */
  block = [self treeNavigationBlockForObject:[_object container] 
		withActiveChildBlock:block
		depth:1];
  return block;
}

/* tree */

- (NSArray *)rootNodes {
  id navNode;
  
  if (self->rootNodes != nil)
    return self->rootNodes;
  
  navNode = [self buildNavigationNodesForObject:[self clientObject]];
  self->rootNodes = [[NSArray alloc] initWithObjects:&navNode count:1];
  return self->rootNodes;
}

/* notifications */

- (void)sleep {
  [self->item      release]; self->item      = nil;
  [self->rootNodes release]; self->rootNodes = nil;
  [super sleep];
}

@end /* UIxMailTree */
