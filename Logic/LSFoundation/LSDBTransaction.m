/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "LSDBTransaction.h"
#include "common.h"

@implementation LSDBTransaction

+ (int)version {
  return 1;
}

- (id)initWithDatabaseContext:(EODatabaseContext *)_databaseContext
  andDatabaseChannel:(EODatabaseChannel *)_databaseChannel {
  if ((self = [super init])) {
    databaseContext = [_databaseContext retain];
    databaseChannel = [_databaseChannel retain];
  }
  return self;
}
- (id)init {
  return [self initWithDatabaseContext:nil andDatabaseChannel:nil];
}

- (void)dealloc {
  [self->databaseContext release];
  [self->databaseChannel release];
  [super dealloc];
}

/* operation */

- (BOOL)beginTransaction {
  //[[self databaseChannel] openChannel];

  return [[self databaseContext] beginTransaction];
}

- (BOOL)commitTransaction {
  BOOL isOk = NO;
  
  isOk = [[self databaseContext] commitTransaction];
  //[[self databaseChannel] closeChannel];

  return isOk;
}

- (BOOL)rollbackTransaction {
  BOOL isOk = NO;
  
  isOk = [[self databaseContext] rollbackTransaction];
  //[[self databaseChannel] closeChannel];

  return isOk;  
}

/* accessors */

- (void)setDatabaseContext:(EODatabaseContext *)_databaseContext {
  ASSIGN(databaseContext, _databaseContext);
}
- (EODatabaseContext *)databaseContext {
  return databaseContext;
}

- (void)setDatabaseChannel:(EODatabaseChannel *)_databaseChannel {
  ASSIGN(databaseChannel, _databaseChannel);
}
- (EODatabaseChannel *)databaseChannel {
  return databaseChannel;
}

@end
