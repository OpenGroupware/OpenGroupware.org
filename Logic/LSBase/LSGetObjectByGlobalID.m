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

#include <LSFoundation/LSGetObjectForGlobalIDs.h>

/*
  This command fetches objects based on a list of EOGlobalIDs.

  Whats the difference to the superclass?
*/

@interface LSGetObjectByGlobalID : LSGetObjectForGlobalIDs
{
}
@end

#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@implementation LSGetObjectByGlobalID

- (void)_prepareForExecutionInContext:(id)_context {
  EOKeyGlobalID *gid;
  
  /* 
     This looks like a hack to extract the entity for follow-up fetches 
     using one of the given GIDs. Not too bad, but could be cleaned up
     somehow (low prio).
  */
  gid = [[self valueForKey:@"gids"] lastObject];
  [self setEntityName:[gid entityName]];
  [super _prepareForExecutionInContext:_context];
}

@end /* LSGetObjectByGlobalID */
