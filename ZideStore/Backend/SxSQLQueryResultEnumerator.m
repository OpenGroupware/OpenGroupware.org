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

#include "SxSQLQueryResultEnumerator.h"
#include "SxSQLQuery.h"
#include <LSFoundation/LSCommandContext.h>
#include <GDLAccess/EOAdaptorChannel.h>
#include "common.h"

@interface SxSQLQuery(Privates)
- (BOOL)finalizeFetchEnumerator:(SxSQLQueryResultEnumerator *)_e;
@end

@implementation SxSQLQueryResultEnumerator

static BOOL sqlDebugOn = NO;

- (id)initWithSQLQuery:(SxSQLQuery *)_query; {
  if ((self = [super init])) {
    self->query   = [_query  retain];
    self->ch      = [[_query adaptorChannel] retain];
    self->cmdctx  = [[_query commandContext] retain];
  }
  return self;
}

- (void)dealloc {
  [self finalize];
  [super dealloc];
}

/* accessors */

- (EOAdaptorChannel *)channel {
  return self->ch;
}
- (LSCommandContext *)commandContext {
  return self->cmdctx;
}

- (void)setAutoCommit:(BOOL)_flag {
  if (_flag) {
    self->flags.commit   = 1;
    self->flags.rollback = 0;
  }
  else
    self->flags.commit = 0;
}
- (BOOL)doesAutoCommit {
  return self->flags.commit ? YES : NO;
}

- (void)setAutoRollback:(BOOL)_flag {
  if (_flag) {
    self->flags.rollback = 1;
    self->flags.commit   = 0;
  }
  else
    self->flags.rollback = 0;
}
- (BOOL)doesAutoRollback {
  return self->flags.rollback ? YES : NO;
}

/* finalize */

- (void)finalize {
  // [self logWithFormat:@"finalizing enumerator ..."];
  
  if ([self->cmdctx isTransactionInProgress]) {
    if (self->flags.commit) {
      if (![cmdctx commit]) {
	[self logWithFormat:@"ERROR: could not commit transaction ..."];
	if ([cmdctx isTransactionInProgress]) [cmdctx rollback];
      }
    }
    else if (self->flags.rollback) {
      if (![cmdctx rollback])
	[self logWithFormat:@"WARNING: could not rollback transaction ..."];
    }
  }
  
  [self->query finalizeFetchEnumerator:self];
  
  ASSIGN(self->query,      (id)nil);
  ASSIGN(self->ch,         (id)nil);
  ASSIGN(self->cmdctx,     (id)nil);
  ASSIGN(self->attributes, (id)nil);
}

/* SQL */

- (NSException *)evaluateSQL:(NSString *)_sql {
  if (![self->ch isOpen]) {
    return [NSException exceptionWithName:@"SQLException"
			reason:@"channel is not open"
			userInfo:nil];
  }
  if (![self->ch evaluateExpression:_sql]) {
    return [NSException exceptionWithName:@"SQLException"
			reason:@"could not execute SQL statement"
			userInfo:nil];
  }
  
  if ((self->attributes = [[self->ch describeResults] retain]) == nil) {
    [self cancelFetch];
    return [NSException exceptionWithName:@"SQLException"
			reason:
			  @"could not get a description of the SQL results"
			userInfo:nil];
  }
  return nil;
}

/* fetching */

- (id)mapRow:(NSMutableDictionary *)_row {
  if (sqlDebugOn)
    [self logWithFormat:@"fetched: %@", _row];
  return _row;
}

- (id)nextObject {
  NSMutableDictionary *row;
  id result;
  
  /* preconditions */
  
  if (self->attributes == nil) {
    [self debugWithFormat:@"missing attributes ..."];
    [self finalize];
    return nil;
  }
  if (self->ch == nil) {
    [self debugWithFormat:@"missing channel ..."];
    [self finalize];
    return nil;
  }

  /* fetch row */
  
  row = [self->ch fetchAttributes:self->attributes withZone:NULL];
  if (sqlDebugOn) [self debugWithFormat:@"ROW: %@", row];
  
  if (row == nil) {
    /* fetched all rows */
    [self finalize];
    return nil;
  }
  
  /* map row using model */
  
  if ((result = [self mapRow:row]) == nil) {
    result = [NSException exceptionWithName:@"RawRowMappingException"
			  reason:@"failed to map a row to a record"
			  userInfo:nil];
  }
  if (sqlDebugOn) [self logWithFormat:@"MAPPED: %@", result];
  return result;
}

- (void)cancelFetch {
  [self->ch cancelFetch];
  [self finalize];
}

@end /* SxSQLQueryResultEnumerator */
