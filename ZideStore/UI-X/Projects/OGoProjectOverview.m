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

#include "OGoProjectView.h"

@interface OGoProjectOverview : OGoProjectView
{
  id item;
}

@end

#include "common.h"

@implementation OGoProjectOverview

- (void)dealloc {
  [self->item release];
  [super dealloc];
}

/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (id)documentFolder {
  return [[self clientObject] 
	   lookupName:@"Documents" inContext:[self context] acquire:NO];
}

- (NSString *)docItemLink {
  // TODO: it should be really not necessary to write code for that ...
  return [[@"Documents/" stringByAppendingString:
	                   [[self item] stringByEscapingURL]]
	                 stringByAppendingString:@"/view"];
}

@end /* OGoProjectOverview */
