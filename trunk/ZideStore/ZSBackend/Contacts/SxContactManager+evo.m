/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxContactManager.h"
#include "common.h"

#include "SxListContactSQLQuery.h"
#include "SxEvoContactSQLQuery.h"
#include "SxContactEmailSQLQuery.h"
#include "SxFetchPerson.h"
#include "SxFetchEnterprise.h"
#include "NSString+DBName.h"

@implementation SxContactManager(Evo)

- (SxEvoContactSQLQuery *)createEvoQuery {
  SxEvoContactSQLQuery *query;
  NSString *mn;

  mn = [self modelName];
  
  if (![mn isPostgreSQL]) {
    [self logWithFormat:@"Evo queries only tested for PostgreSQL ..."];
    [self logWithFormat:@"model: %@", [self modelName]];
    return nil;
  }

  query = [SxEvoContactSQLQuery alloc];
  query = [query initWithContext:[self commandContext]];
  return [query autorelease];
}

- (NSEnumerator *)evoPublicPersonsWithPrefix:(NSString *)_prefix {
  SxEvoContactSQLQuery *query = [self createEvoQuery];
  [query makePublicQuery];
  [query setPrefix:_prefix];
  return [query runAndRollback];
}

- (NSEnumerator *)evoPrivatePersonsWithPrefix:(NSString *)_prefix {
  SxEvoContactSQLQuery *query = [self createEvoQuery];
  [query setPrefix:_prefix];
  return [query runAndRollback];
}

- (NSEnumerator *)evoAccountsWithPrefix:(NSString *)_prefix {
  SxEvoContactSQLQuery *query = [self createEvoQuery];
  [query makeAccountQuery];
  [query setPrefix:_prefix];
  return [query runAndRollback];
}

- (NSEnumerator *)evoAccountsForGroup:(NSString *)_grp
  prefix:(NSString *)_prefix
{
  if (![_grp isNotNull]) /* list all accounts */
    return [self evoAccountsWithPrefix:_prefix];
  
  // TODO: implement
  [self logWithFormat:@"evoquery of group accounts is not implemented ..."];
  return [[NSArray array] objectEnumerator];
}

- (NSEnumerator *)evoPublicEnterprisesWithPrefix:(NSString *)_prefix {
  SxEvoContactSQLQuery *query = [self createEvoQuery];
  [query makePublicQuery];
  [query setPrefix:_prefix];
  [query makeEnterpriseQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)evoPrivateEnterprisesWithPrefix:(NSString *)_prefix {
  SxEvoContactSQLQuery *query = [self createEvoQuery];
  [query setPrefix:_prefix];
  [query makeEnterpriseQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)evoGroupsWithPrefix:(NSString *)_prefix {
  SxEvoContactSQLQuery *query = [self createEvoQuery];
  [query makeGroupQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)evoContactsWithPrefix:(NSString *)_prefix 
  inContactSet:(SxContactSetIdentifier *)_sid
{
  if ([_sid isAccountSet])
    return [self evoAccountsWithPrefix:_prefix];
  
  if ([_sid isEnterpriseSet]) {
    return [_sid isPublicSet]
      ? [self evoPublicEnterprisesWithPrefix:_prefix]
      : [self evoPrivateEnterprisesWithPrefix:_prefix];
  }
  
  return [_sid isPublicSet]
    ? [self evoPublicPersonsWithPrefix:_prefix]
    : [self evoPrivatePersonsWithPrefix:_prefix];
}


@end /* SxContactManager(Evo) */
