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

#include "Session.h"
#include "common.h"

@implementation Session

- (id)init {
  if ((self = [super init])) {
    [self setStoresIDsInCookies:NO];
  }
  return self;
}

- (void)dealloc {
  [self->commandContext   release];
  [self->accountDS        release];
  [self->personDS         release];
  [self->teamDS           release];
  [super dealloc];
}

- (void)setCommandContext:(id)_ctx {
  ASSIGN(self->commandContext, _ctx);
}
- (id)commandContext {
  return self->commandContext;
}

- (void)sleep {
  if ([self->commandContext isTransactionInProgress])
    [self->commandContext commit];
  [super sleep];
}

- (EODataSource *)_dataSourceWithClassName:(NSString *)_dsName {
  EODataSource *ds;
  Class clazz;
  
  if ((clazz = NGClassFromString(_dsName)) == nil) {
    [self logWithFormat:@"no datasource named '%@' ...", _dsName];
    return nil;
  }
  
  ds = [[clazz alloc] initWithContext:[self commandContext]];
  [self debugWithFormat:@"instantiated new datasource '%@' ...", _dsName];
  return AUTORELEASE(ds);
}

- (EODataSource *)accountDataSource {
  if (self->accountDS == nil) {
    self->accountDS =
      [[self _dataSourceWithClassName:@"SkyAccountDataSource"] retain];
  }
  return self->accountDS;
}

- (EODataSource *)personDataSource {
  if (self->personDS == nil) {
    self->personDS =
      [[self _dataSourceWithClassName:@"SkyPersonDataSource"] retain];
  }
  return self->personDS;
}

- (EODataSource *)teamDataSource {
  if (self->teamDS == nil) {
    self->teamDS =
      [[self _dataSourceWithClassName:@"SkyTeamDataSource"] retain];
  }
  return self->teamDS;
}

@end /* Session */
