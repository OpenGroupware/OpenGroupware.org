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

#include <LSFoundation/LSDBObjectGetCommand.h>

/*

  Parameter:
    states - array of states (NSString objects)

*/

@interface LSGetEnterpriseWithInvoiceStatus: LSDBObjectGetCommand
{
  NSArray  *states;
  NSString *statesIN;
}

@end

#import "common.h"

@implementation LSGetEnterpriseWithInvoiceStatus

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->states);
  RELEASE(self->statesIN);
  [super dealloc];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  id           account;
  NSEnumerator *teamEnum;
  id           team;
  BOOL         access = NO;
  
  account = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  [self assert: (self->states != nil)
        reason: @"No States set!"];
  
  [super _prepareForExecutionInContext:_context];

  /* construct IN states */

  {
    self->statesIN = [[NSString stringWithFormat:@"'%@'",
      [self->states componentsJoinedByString:@"','"]] copy];
  }
}

- (id)_getEnterprisesInContext:(id)_context {
  EOSQLQualifier    *entQualifier;
  EODatabaseChannel *dbChannel;
  NSMutableArray    *result;
  id                entity;
  id                enterprise;

  entity = [[self database] entityNamed:[self entityName]];
  entQualifier =
    [[EOSQLQualifier alloc]
                     initWithEntity:entity
                     qualifierFormat:
                     @"%A IN (%@)",
                     @"toInvoice.status",
                     self->statesIN];
  [entQualifier setUsesDistinct: YES];

  dbChannel = [self databaseChannel];
  [dbChannel selectObjectsDescribedByQualifier:entQualifier
             fetchOrder:nil];

  result = [NSMutableArray array];

  while ((enterprise = [dbChannel fetchWithZone:nil])) {
    [result addObject:enterprise];
  }
  RELEASE(entQualifier); entQualifier = nil;
  return result;
}

- (void)_executeInContext:(id)_context {
  [self setReturnValue:[self _getEnterprisesInContext:_context]];
}

- (NSString*)entityName {
  return @"Enterprise";
}

// key/value coding

- (void)setStates:(NSArray*)_states {
  ASSIGN(self->states, _states);
}
- (NSArray*)states {
  return self->states;
}

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"states"]) {
    [self setStates: _val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"states"]) {
    return [self states];
  }
  return [super valueForKey:_key];
}

@end
