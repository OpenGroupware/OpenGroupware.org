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
// $Id: SxListContactSQLQuery.m 1 2004-08-20 11:17:52Z znek $

#include "SxListContactSQLQuery.h"
#include "common.h"

@implementation SxListContactSQLQuery

/* controlling generation */

- (BOOL)limitFetchToAccountGroups {
  return [self isGroupQuery];
}

/* SQL generation */

- (void)generateSelect:(NSMutableString *)_sql {
  /* selects: pkey, sn, givenname, version */
  NSString *t;
  
  [self addFirstColumn:@"c1.company_id" as:@"pkey" to:_sql];
  
  if ([self isPersonQuery]) {
    t = [@"c1." stringByAppendingString:[self nameColumn]];
    [self addColumn:t as:@"sn" to:_sql];
  
    [self addColumn:@"c1.firstname"   as:@"givenname"  to:_sql];
  }
  else {
    [self addColumn:@"c1.description" as:@"cn" to:_sql];
  }

  [self addColumn:@"c1.object_version" as:@"version" to:_sql];
}

- (void)generateFrom:(NSMutableString *)_sql {
  [_sql appendString:@"company c1"];
  
  if ([self limitFetchToAccountGroups])
    [_sql appendString:@", company_assignment a"];
}

- (void)generateWhereJoins:(NSMutableString *)_sql {
  if ([self limitFetchToAccountGroups]) {
    [_sql appendString:@" AND (a.sub_company_id="];
    [_sql appendString:[[self loginPrimaryKey] stringValue]];
    [_sql appendString:@" AND a.company_id=c1.company_id)"];
  }
}

@end /* SxListContactSQLQuery */
