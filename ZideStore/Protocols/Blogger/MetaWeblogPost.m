/*
  Copyright (C) 2004 Helge Hess

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

#include "MetaWeblogAction.h"

@class NSDictionary;

@interface MetaWeblogPost : MetaWeblogAction
{
  NSDictionary *entry;
  BOOL         doPublish;
}

@end

#include "NSObject+Blogger.h"
#include "common.h"

@implementation MetaWeblogPost

- (void)dealloc {
  [self->entry release];
  [super dealloc];
}

/* accessors */

- (void)setEntry:(NSDictionary *)_entry {
  ASSIGNCOPY(self->entry, _entry);
}
- (NSDictionary *)entry {
  return self->entry;
}

- (void)setDoPublish:(BOOL)_flag {
  self->doPublish = _flag;
}
- (int)doPublish {
  return self->doPublish;
}

/* actions */

- (id)newPostAction {
  [self logWithFormat:@"%@ new post in blog %@: %@", 
	  [self login], [self blogID],
	  [self entry]];
  /* return String postid of new post */
  return [NSException exceptionWithName:@"NotImplemented"
		      reason:@"Post not yet implemented!"
		      userInfo:nil];
}

@end /* MetaWeblogPost */
