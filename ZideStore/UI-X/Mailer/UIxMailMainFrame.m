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

#include <SOGoUI/UIxComponent.h>

@interface UIxMailMainFrame : UIxComponent
{
  NSString *title;
  NSString *rootURL;
  NSString *userRootURL;
  id       item;
  BOOL     hideFolderTree;
}

- (NSString *)rootURL;
- (NSString *)userRootURL;
- (NSString *)calendarRootURL;

@end

#include "common.h"
#include <NGObjWeb/SoComponent.h>

@implementation UIxMailMainFrame

- (void)dealloc {
  [self->item        release];
  [self->title       release];
  [self->rootURL     release];
  [self->userRootURL release];
  [super dealloc];
}

/* accessors */

- (void)setHideFolderTree:(BOOL)_flag {
   self->hideFolderTree = _flag;
}
- (BOOL)hideFolderTree {
  return self->hideFolderTree;
}

- (void)setTitle:(NSString *)_value {
  ASSIGNCOPY(self->title, _value);
}
- (NSString *)title {
  if ([self->title length] == 0)
    return @"OpenGroupware.org";
  
  return self->title;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

/* notifications */

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

/* URL generation */
// TODO: I think all this should be done by the clientObject?!
// TODO: is the stuff below necessary at all in the mailer frame?

- (NSString *)rootURL {
  WOContext *ctx;
  NSArray   *traversalObjects;

  if (self->rootURL != nil)
    return self->rootURL;

  ctx = [self context];
  traversalObjects = [ctx objectTraversalStack];
  self->rootURL = [[[traversalObjects objectAtIndex:0]
                                      rootURLInContext:ctx]
                                      copy];
  return self->rootURL;
}

- (NSString *)userRootURL {
  WOContext *ctx;
  NSArray   *traversalObjects;

  if (self->userRootURL)
    return self->userRootURL;

  ctx = [self context];
  traversalObjects = [ctx objectTraversalStack];
  self->userRootURL = [[[[traversalObjects objectAtIndex:1]
                                           baseURLInContext:ctx]
                                           stringByAppendingString:@"/"]
                                           retain];
  return self->userRootURL;
}

- (NSString *)calendarRootURL {
  return [[self userRootURL] stringByAppendingString:@"Calendar/"];
}
- (NSString *)contactsRootURL {
  return [[self userRootURL] stringByAppendingString:@"Contacts/"];
}

@end /* UIxMailMainFrame */
