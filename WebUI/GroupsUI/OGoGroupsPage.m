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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray;

@interface OGoGroupsPage : OGoContentPage
{
  NSArray *groupList;
  id item;
}

@end

#include "common.h"

@implementation OGoGroupsPage

- (void)dealloc {
  [self->groupList release];
  [self->item      release];
  [super dealloc];
}

/* accessors */

- (void)setItem:(id)_value {
  ASSIGN(self->item, _value);
}
- (id)item {
  return self->item;
}

- (void)setGroupList:(NSArray *)_value {
  ASSIGN(self->groupList, _value);
}
- (NSArray *)groupList {
  return self->groupList;
}

/* operations */

- (NSArray *)_fetchMyTeams {
  [self logWithFormat:@"perform fetch ..."];
  return nil;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  
  if (self->groupList == nil)
    [self setGroupList:[self _fetchMyTeams]];
}

- (void)sleep {
  [self setItem:nil];
  [super sleep];
}

@end /* OGoGroupsPage */
