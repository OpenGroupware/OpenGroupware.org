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
// $Id: SxContactSQLQuery.m 1 2004-08-20 11:17:52Z znek $

#include "SxContactSQLQuery.h"
#include "common.h"

@implementation SxContactSQLQuery

- (void)dealloc {
  [self->prefix release];
  [super dealloc];
}

/* controlling generation */

- (void)setPrefix:(NSString *)_prefix {
  if (self->prefix != _prefix) {
    ASSIGNCOPY(self->prefix, _prefix);
    [self regenerateSQL];
  }
}
- (NSString *)prefix {
  return self->prefix;
}

- (void)makeAccountQuery {
  self->flags.isAccount    = 1;
  self->flags.isPublic     = 1;
  
  self->flags.isEnterprise = 0;
  self->flags.isPerson     = 1;
  self->flags.isTeam       = 0;
  [self regenerateSQL];
}
- (void)makePublicQuery {
  self->flags.isPublic = 1;
  [self regenerateSQL];
}
- (void)makeEnterpriseQuery {
  self->flags.isAccount    = 0;
  self->flags.isEnterprise = 1;
  self->flags.isPerson     = 0;
  self->flags.isTeam       = 0;
  [self regenerateSQL];
}
- (void)makeGroupQuery {
  self->flags.isAccount    = 0;
  self->flags.isPublic     = 1;
  
  self->flags.isEnterprise = 0;
  self->flags.isPerson     = 0;
  self->flags.isTeam       = 1;
  [self regenerateSQL];
}

- (BOOL)isPublicContactQuery {
  return self->flags.isPublic ? YES : NO;
}
- (BOOL)isPrivateContactQuery {
  return self->flags.isPublic ? NO : YES;
}
- (BOOL)isAccountContactQuery {
  return self->flags.isAccount ? YES : NO;
}

- (BOOL)isPersonQuery {
  return (self->flags.isTeam || self->flags.isEnterprise) ? NO : YES;
}
- (BOOL)isGroupQuery {
  return self->flags.isTeam ? YES : NO;
}
- (BOOL)isEnterpriseQuery {
  return self->flags.isEnterprise ? YES : NO;
}

/* SQL generation */

- (BOOL)shouldGenerateWhere {
  return YES;
}

- (void)generateWhereJoins:(NSMutableString *)_sql {
}

- (void)generateViewWhere:(NSMutableString *)_sql {
  if ([self isPersonQuery]) {
    [_sql appendString:@"c1.is_person=1"];
    [_sql appendString:@" AND "];
    
    /* does not include accounts in public addrbook */
    [_sql appendString:@"(c1.is_account="];
    if ([self isAccountContactQuery])
      [_sql appendString:@"1"];
    else
      [_sql appendString:@"0 OR c1.is_account IS NULL"];
    [_sql appendString:@")"];
  }
  else if ([self isEnterpriseQuery]) {
    [_sql appendString:@"c1.is_enterprise=1"];
  }
  else if ([self isGroupQuery]) {
    [_sql appendString:@"c1.is_team=1"];
  }
}

- (void)generatePermissionWhere:(NSMutableString *)_sql {
  [_sql appendString:@" AND "];
  
  if ([self isPublicContactQuery]) {
    [_sql appendString:@"(c1.is_private=0 OR c1.is_private IS NULL)"];
  }
  else if ([self isPrivateContactQuery]) {
    [_sql appendString:@"c1.is_private=1"];
    [_sql appendString:@" AND "];
    [_sql appendString:@"c1.owner_id="];
    [_sql appendString:[[self loginPrimaryKey] stringValue]];
  }
  else if ([self isAccountContactQuery]) {
    [_sql appendString:@"(c1.is_private=0 OR c1.is_private IS NULL)"];
  }
  else
    [self logWithFormat:@"don't know how to handle generate 'where' ..."];
}

- (void)generatePrefixWhere:(NSMutableString *)_sql {
  NSString *lp, *up;
  
  if ([self->prefix length] == 0)
    return;
  
  // TODO: fix upper/lower
  lp = [[self prefix] lowercaseString];
  up = [[self prefix] uppercaseString];
  
  [_sql appendString:@"("];
  if ([self isPersonQuery]) {
    // name, firstname, login
    [_sql appendString:@"c1.login LIKE '"];
    [_sql appendString:lp];
    [_sql appendString:@"%'"];
    [_sql appendString:@" OR c1.firstname LIKE '"];
    [_sql appendString:lp];
    [_sql appendString:@"%'"];
    [_sql appendString:@" OR c1."];
    [_sql appendString:[self nameColumn]];
    [_sql appendString:@" LIKE '"];
    [_sql appendString:lp];
    [_sql appendString:@"%'"];

    [_sql appendString:@" OR c1.login LIKE '"];
    [_sql appendString:up];
    [_sql appendString:@"%'"];
    [_sql appendString:@" OR c1.firstname LIKE '"];
    [_sql appendString:up];
    [_sql appendString:@"%'"];
    [_sql appendString:@" OR c1."];
    [_sql appendString:[self nameColumn]];
    [_sql appendString:@" LIKE '"];
    [_sql appendString:up];
    [_sql appendString:@"%'"];
  }
  else if ([self isGroupQuery] || [self isEnterpriseQuery]) {
    // description
    [_sql appendString:@"c1.description LIKE '"];
    [_sql appendString:lp];
    [_sql appendString:@"%'"];
    [_sql appendString:@" OR c1.description LIKE '"];
    [_sql appendString:up];
    [_sql appendString:@"%'"];
  }
  [_sql appendString:@")"];
}

- (void)generateWhere:(NSMutableString *)_sql {
  [self generateViewWhere:_sql];
  [self generatePermissionWhere:_sql];
  
  if ([self->prefix length] > 0) {
    [_sql appendString:@" AND "];
    [self generatePrefixWhere:_sql];
  }
  
  // TODO: generate email-where (needs to query company-value)
  
  [self generateWhereJoins:_sql];
}

@end /* SxContactSQLQuery */
