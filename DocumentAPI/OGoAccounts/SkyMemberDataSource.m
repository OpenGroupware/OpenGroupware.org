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

#include "SkyMemberDataSource.h"

#include <LSFoundation/LSFoundation.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOSortOrdering.h>

@interface SkyAccountDataSource(memberDataSource)
- (id)initWithContext:(LSCommandContext *)_ctx;
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
@end /* SkyAccountDataSource(memberInit) */

@implementation SkyMemberDataSource

- (id)initWithContext:(LSCommandContext *)_ctx team:(id)_team {
  if ((self = [super initWithContext:_ctx])) {
    ASSIGN(self->team,_team);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->team);
  [super dealloc];
}
#endif

- (NSArray *)fetchObjects {
  NSArray *members;

  members =
    [self->context runCommand:@"team::members",
         @"team", self->team,
         nil];

  members = [self _morphEOsToDocuments:members];

  {
    NSArray *sortOrderings = [self->fetchSpecification sortOrderings];
    if (sortOrderings != nil)
      members = [members sortedArrayUsingKeyOrderArray:sortOrderings];
  }
  return members;
}

@end /* SkyMemberDataSource */
