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

#include "SkyAccountTeamsDataSource.h"

#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOSortOrdering.h>

@interface SkyTeamDataSource(accountTeams)
- (id)initWithContext:(LSCommandContext *)_ctx;
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
@end

@implementation SkyAccountTeamsDataSource

- (id)initWithContext:(LSCommandContext *)_ctx account:(id)_account {
  if ((self = [super initWithContext:_ctx])) {
    ASSIGN(self->account, _account);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->account);
  [super dealloc];
}
#endif

- (NSArray *)fetchObjects {
  NSArray *teams;

  teams =
    [self->context runCommand:@"account::teams",
         @"account", self->account,
         nil];

  teams = [self _morphEOsToDocuments:teams];

  {
    NSArray *sortOrderings = [self->fetchSpecification sortOrderings];
    if (sortOrderings != nil)
      teams = [teams sortedArrayUsingKeyOrderArray:sortOrderings];
  }
  return teams;
}

@end /* SkyAccountTeamsDataSource */
