/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include "UIxMailTreeBlock.h"
#include "common.h"

@implementation UIxMailTreeBlock

+ (id)blockWithName:(NSString *)_name title:(NSString *)_title
  iconName:(NSString *)_icon
  link:(NSString *)_link isPathNode:(BOOL)_isPath isActiveNode:(BOOL)_isActive
  childBlocks:(NSArray *)_blocks
{
  UIxMailTreeBlock *block;

  block = [[self alloc] initWithName:_name title:_title iconName:_icon
			link:_link
			isPathNode:_isPath isActiveNode:_isActive
			childBlocks:_blocks];
  return [block autorelease];
}

- (id)initWithName:(NSString *)_name title:(NSString *)_title
  iconName:(NSString *)_icon
  link:(NSString *)_link isPathNode:(BOOL)_isPath isActiveNode:(BOOL)_isActive
  childBlocks:(NSArray *)_blocks
{
  if ((self = [self init])) {
    self->name     = [_name   copy];
    self->title    = [_title  copy];
    self->iconName = [_icon copy];
    self->link     = [_link   copy];
    self->blocks   = [_blocks retain];
    
    self->flags.isPath   = _isPath   ? 1 : 0;
    self->flags.isActive = _isActive ? 1 : 0;
  }
  return self;
}

- (void)dealloc {
  [self->iconName release];
  [self->blocks   release];
  [self->name     release];
  [self->title    release];
  [self->link     release];
  [super dealloc];
}

/* accessors */

- (NSString *)name {
  return self->name;
}
- (NSString *)title {
  return self->title;
}
- (NSString *)link {
  return self->link;
}
- (NSString *)iconName {
  return self->iconName;
}

- (NSArray *)children {
  return self->blocks;
}

- (BOOL)isPathNode {
  return self->flags.isPath ? YES : NO;
}
- (BOOL)isActiveNode {
  return self->flags.isActive ? YES : NO;
}

@end /* UIxMailTreeBlock */
