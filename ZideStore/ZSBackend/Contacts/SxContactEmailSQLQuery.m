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
// $Id: SxContactEmailSQLQuery.m 1 2004-08-20 11:17:52Z znek $

#include "SxContactEmailSQLQuery.h"
#include "common.h"

@implementation SxContactEmailSQLQuery

- (void)dealloc {
  [self->emails release];
  [super dealloc];
}

/* controlling generation */

- (void)setEmails:(NSArray *)_emls {
  if (self->emails != _emls) {
    ASSIGNCOPY(self->emails, _emls);
    [self regenerateSQL];
  }
}
- (NSArray *)emails {
  return self->emails;
}

- (void)setEmail:(NSString *)_eml {
  [self setEmails:[NSArray arrayWithObject:_eml]];
}
- (NSString *)email {
  return [[self emails] lastObject];
}

/* SQL generation */

- (BOOL)shouldGenerateWhere {
  return YES;
}

- (void)generateSelect:(NSMutableString *)_sql {
  [_sql appendString:@"DISTINCT "];
  [self addFirstColumn:@"c1.company_id" as:@"pkey" to:_sql];
  if ([self isGroupQuery])
    [self addColumn:@"c1.is_team" as:@"isteam" to:_sql];
}

- (void)generateFrom:(NSMutableString *)_sql {
  if ([self isGroupQuery])
    [_sql appendString:@"team c1"];
  else
    [_sql appendString:@"company_value cv, person c1"];
}

// company_value cv, person|team c1
// TODO: check for empty array, check for clusterSize of IN query
- (void)generateWhereJoins:(NSMutableString *)_sql {
  if ([self->emails count] == 1) {
    if ([self isGroupQuery]) {
      [_sql appendString:@" AND c1.email = '"];
      [self addStringValue:[self->emails lastObject] to:_sql];
      [_sql appendString:@"'"];
    }
    else {
      [_sql appendString:@" AND ( lower(cv.value_string) = '"];
      [self addStringValue:[self->emails lastObject] to:_sql];
      [_sql appendString:
            @"' AND lower(cv.attribute) = 'email1'"
            @" AND (c1.db_status <> 'archived')"
            @" AND c1.company_id = cv.company_id )"];
    }
  }
  else {
    NSMutableString *ins;
    unsigned max, i;
    ins = [NSMutableString stringWithCapacity:8];
    max = [self->emails count];
    for (i = 0; i < max; i++) {
      if (i)
        [ins appendString:@"','"];
      [self addStringValue:[self->emails objectAtIndex:i] to:ins];
    }
    if ([self isGroupQuery]) {
      [_sql appendFormat:@" AND c1.email IN ('%@')", ins];
    }
    else {
      [_sql appendFormat:
            @" AND ( lower(cv.value_string) IN ('%@')"
            @" AND lower(cv.attribute) = 'email1'"
            @" AND (c1.db_status <> 'archived')"
            @" AND c1.company_id = cv.company_id )",
            ins];
    }
  }
}
  
@end /* SxContactEmailSQLQuery */
