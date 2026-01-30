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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSString, NSNumber, NSTimeZone, NSCalendarDate;

@interface LSGetAppointmentsOfAccountCommand : LSDBObjectBaseCommand
{
  /* temporary */
  NSString       *ids;
  id             company;
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSTimeZone     *tz;
  NSNumber       *fetchGlobalIDs;
}

- (NSArray *)_fetchObjects:(id)_context;
- (NSArray *)_fetchIds:(id)_context;

@end

#include "common.h"

@implementation LSGetAppointmentsOfAccountCommand

static NSNumber *nYes = nil, *nNo = nil;

+ (int)version {
  return [super version] + 0;
}
+ (void)initialize {
  // TODO: check superclass version
  if (nYes == nil) nYes = [[NSNumber numberWithBool:YES] retain];
  if (nNo  == nil) nNo  = [[NSNumber numberWithBool:NO]  retain];
}

- (void)dealloc {
  [self->startDate release];
  [self->endDate   release];
  [self->tz        release];
  [self->ids       release];
  [self->company   release];
  [self->fetchGlobalIDs release];
  [super dealloc];
}

/* commands */

- (NSArray *)_checkPermission:(NSArray *)_appointments context:(id)_ctx {
  // TODO: split up method
  NSMutableArray *filtered;
  NSEnumerator   *e;
  id appointment           = nil;
  id login                 = nil;
  id loginId               = nil;
  id loginTeams            = nil;
  
  e        = [_appointments objectEnumerator];
  filtered = [NSMutableArray arrayWithCapacity:[_appointments count]];

  // get login account
  login = [_ctx valueForKey:LSAccountKey];

  // get pkeys of the teams of the login account
  loginTeams = LSRunCommandV(_ctx,
                             @"account", @"teams",
                             @"account", login, nil);

  loginTeams = [loginTeams mappedSetUsingSelector:@selector(valueForKey:)
                           withObject:@"companyId"];
  // get pkey of login account
  loginId = [login valueForKey:@"companyId"];
  
  while ((appointment = [e nextObject])) {
    id teamKey = [appointment valueForKey:@"accessTeamId"];
    
    // the owner may always view the appointment
    if ([[appointment valueForKey:@"ownerId"] isEqual:loginId] ||
        ([loginId intValue] == 10000)) {
      [filtered addObject:appointment];
      continue;
    }

    if (teamKey) {
      // if team is 'null', the appointment is private to the owner
      
      // check whether the login user is in access-team
      if ([loginTeams containsObject:teamKey]) {
        [filtered addObject:appointment];
        continue;
      }
    }

    // check whether the login user is a participant
    {
      NSArray *participants = [appointment valueForKey:@"participants"];
      int i, count = [participants count];
      BOOL found = NO;
      
      for (i = 0; i < count; i++) {
        id participant = [participants objectAtIndex:i];
        id pkey        = [participant valueForKey:@"companyId"];

        if ([[participant valueForKey:@"isTeam"] boolValue]) {
          if ([loginTeams containsObject:pkey]) {
            found = YES;
            break;
          }
        }
        else {
          if ([loginId isEqual:pkey]) {
            found = YES;
            break;
          }
        }
      }
      if (found) {
        [filtered addObject:appointment];
        continue;
      }
    }
  }
  return filtered;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id groups, group;
  NSMutableString *s;

  if (self->company == nil)
    self->company = [[_context valueForKey:LSAccountKey] retain];
  
  [self assert:[self->company isNotNull] 
	reason:@"missing account in context !"];
  
  [_context runCommand:@"account::teams", @"object", self->company, nil];
  groups = [[self->company valueForKey:@"groups"] objectEnumerator];

  s = [NSMutableString stringWithCapacity:256];
  [s appendString:[[self->company valueForKey:@"companyId"] stringValue]];

  while ((group = [groups nextObject])) {
    [s appendString:@","];
    [s appendString:[[group valueForKey:@"companyId"] stringValue]];
  }
  self->ids = [s copy];
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  NSArray *r;

  pool = [[NSAutoreleasePool alloc] init];

  r = ([self->fetchGlobalIDs boolValue])
    ? [self _fetchIds:_context]
    : [self _fetchObjects:_context];
  
  r = [r copy];
  [self setReturnValue:r];
  [r release];

  [pool release];
}

- (EOSQLQualifier *)_buildQualifierWithContext:(id)_context {
  EOSQLQualifier *q = nil;
  NSString       *fmtStart = nil, *fmtEnd = nil;
  BOOL           isRoot;

  fmtStart = nil;
  fmtEnd   = nil;
  isRoot   = [_context isRoot];
  {
    EOAdaptor   *adaptor;
    EOEntity    *entity;
    EOAttribute *startAttr, *endAttr;
    
    adaptor   = [self databaseAdaptor];
    entity    = [self entity];
    
    startAttr = [entity attributeNamed:@"startDate"];
    endAttr   = [entity attributeNamed:@"endDate"];

    if (self->startDate)
      fmtStart = [adaptor formatValue:self->startDate forAttribute:startAttr];
    if (self->endDate)
      fmtEnd   = [adaptor formatValue:self->endDate   forAttribute:endAttr];
  }

  q = [EOSQLQualifier alloc];
  
  if ((self->startDate != nil) && (self->endDate != nil)) {
    if (isRoot) {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"(%A > %@ AND %A < %@) AND "
               @"toDateCompanyAssignment.companyId IN (%@)",
               @"endDate",   fmtStart,
               @"startDate", fmtEnd,
               self->ids];
    }
    else {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"(%A > %@ AND %A < %@) AND "
               @"toDateCompanyAssignment.companyId IN (%@) AND "
               @"dbStatus <> 'archived'",
               @"endDate",   fmtStart,
               @"startDate", fmtEnd,
               self->ids];
    }
  }
  else if (self->startDate) {
    if (isRoot) {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"(%A > %@) AND "
               @"toDateCompanyAssignment.companyId IN (%@)",
               @"endDate", fmtStart,
               self->ids];
    }
    else {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"(%A > %@) AND "
               @"toDateCompanyAssignment.companyId IN (%@) AND "
               @"dbStatus <> 'archived'",
               @"endDate", fmtStart,
               self->ids];
    }
  }
  else if (self->endDate) {
    if (isRoot) {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"(%A < %@) AND "
               @"toDateCompanyAssignment.companyId IN (%@)",
               @"startDate", fmtEnd,
               self->ids];
    }
    else {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"(%A < %@) AND "
               @"toDateCompanyAssignment.companyId IN (%@) AND "
               @"dbStatus <> 'archived'",
               @"startDate", fmtEnd,
               self->ids];
    }
  }
  else {
    if (isRoot) {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"toDateCompanyAssignment.companyId IN (%@)",
             self->ids];
    }
    else {
      q = [q initWithEntity:[self entity]
             qualifierFormat:
               @"toDateCompanyAssignment.companyId IN (%@) AND "
               @"dbStatus <> 'archived'",
             self->ids];
    }
  }
  [q setUsesDistinct:YES];
  return [q autorelease];
}

- (NSArray *)_fetchIds:(id)_context {
  EOSQLQualifier   *qualifier  = nil;
  NSMutableArray   *results    = nil;
  EOAdaptorChannel *channel    = nil;
  NSArray          *attributes = nil;
  EOEntity         *entity     = nil;
  int maxSearch = 0;
  int cnt       = 0;
  
  channel    = [[self databaseChannel] adaptorChannel];
  results    = [NSMutableArray arrayWithCapacity:512];
  qualifier  = [self _buildQualifierWithContext:_context];
  entity     = [qualifier entity];
  attributes = [entity primaryKeyAttributes];
  
  [self assert:[channel selectAttributes:attributes
                        describedByQualifier:qualifier
                        fetchOrder:nil lock:YES]];
  
  while ((maxSearch == 0) || (cnt < maxSearch)) {
    NSDictionary *row;
    EOGlobalID   *gid;
    
    if ((row = [channel fetchAttributes:attributes withZone:NULL]) == nil)
      break;
    
    gid = [entity globalIDForRow:row];
    [results addObject:gid];
    
    cnt = [results count];
    if ((maxSearch != 0) && (cnt == maxSearch)) {
      [[self databaseChannel] cancelFetch];
      break;
    }
  }
  return results;
}

- (NSArray *)_fetchObjects:(id)_context {
  NSMutableArray    *results;
  EOSQLQualifier    *qualifier;
  EODatabaseChannel *channel;
  id                apmt;
  
  channel   = [self databaseChannel];
  qualifier = [self _buildQualifierWithContext:_context];

  [self assert:[self->ids length] > 0 reason:@"missing ID string .."];

  [self assert:[channel selectObjectsDescribedByQualifier:qualifier
                        fetchOrder:nil]];

  results = [NSMutableArray arrayWithCapacity:100];

  while ((apmt = [channel fetchWithZone:NULL])) {
    NSCalendarDate *d;
    
    [results addObject:apmt];
    
    if (self->tz == nil)
      continue;
    
    [[apmt valueForKey:@"startDate"] setTimeZone:self->tz];
    [[apmt valueForKey:@"endDate"]   setTimeZone:self->tz];
      
    d = [apmt valueForKey:@"cycleEndDate"];
    if (d != nil) [d setTimeZone:self->tz];
  }
  
  LSRunCommandV(_context,
                @"appointment", @"get-participants",
                @"appointments", results, nil);

  LSRunCommandV(_context,
                @"appointment", @"get-comments",
                @"objects", results, nil);
  
  return [self _checkPermission:results context:_context];
}

- (NSString *)entityName {
  return @"Date";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"company"]) {
    ASSIGN(self->company, _value);
    return;
  }
  if ([_key isEqualToString:@"startDate"]) {
    ASSIGNCOPY(self->startDate, _value);
    return;
  }
  if ([_key isEqualToString:@"endDate"]) {
    ASSIGNCOPY(self->endDate, _value);
    return;
  }
  if ([_key isEqualToString:@"timeZone"]) {
    ASSIGN(self->tz, _value);
    return;
  }
  if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    ASSIGNCOPY(self->fetchGlobalIDs, _value);
    return;
  }

  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"company"])
    return self->company;
  if ([_key isEqualToString:@"startDate"])
    return self->startDate;
  if ([_key isEqualToString:@"endDate"])
    return self->endDate;
  if ([_key isEqualToString:@"timeZone"])
    return self->tz;
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return self->fetchGlobalIDs;

  return [super valueForKey:_key];
}

@end /* LSGetAppointmentsOfAccountCommand */
