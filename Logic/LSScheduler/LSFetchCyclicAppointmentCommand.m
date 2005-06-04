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

#import "common.h"
#include <LSFoundation/LSDBFetchRelationCommand.h>

@interface LSFetchCyclicAppointmentCommand : LSDBFetchRelationCommand
@end

@implementation LSFetchCyclicAppointmentCommand

- (void)_checkPermission:(NSArray *)_appointments context:(id)_ctx {
  NSMutableArray *filtered = nil;
  NSEnumerator   *e        = [_appointments objectEnumerator];
  id appointment           = nil;
  id login                 = nil;
  id loginId               = nil;
  id loginTeams            = nil;

  filtered = [[NSMutableArray allocWithZone:[self zone]]
                              initWithCapacity:[_appointments count]];

  // get login account
  login = [_ctx valueForKey:LSAccountKey];

  // get pkeys of the teams of the login account
  if (login)
    loginTeams = [_ctx runCommand:@"account::teams", @"object", login, nil];
  
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
  [self setReturnValue:filtered];
  RELEASE(filtered); filtered = nil;
}

- (void)_fetchParticipantsForAppointments:(NSArray *)_dates context:(id)_ctx{
  LSRunCommandV(_ctx, @"appointment", @"get-participants",
                @"appointments", _dates, nil);
}

- (void)_executeInContext:(id)_context {
  NSArray *results = nil;
  
  [super _executeInContext:_context];

  results = [self object];
    
  [self _fetchParticipantsForAppointments:results context:_context];
  [self _checkPermission:results context:_context];

  LSRunCommandV(_context, @"appointment", @"get-comments",
                @"objects", results, nil);
}

- (NSString *)entityName {
  return @"Date";
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"Date"];
}
 
- (BOOL)isToMany {
  return YES; 
}
 
- (NSString *)sourceKey {
  return @"dateId";
}

- (NSString *)destinationKey {
  return @"parentDateId";
}

@end