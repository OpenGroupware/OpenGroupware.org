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

#import "common.h"
#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command loads the access team info into the appointments
  given as a parameter.

  It assign the property 'isViewAllowed' to the appointment objects.
*/

@interface LSGetAccessTeamInfoCommand : LSDBObjectBaseCommand
{
  NSArray *appointments;
}

@end

@implementation LSGetAccessTeamInfoCommand

static NSNumber *nYes = nil;
static NSNumber *nNo  = nil;

+ (void)initialize {
  if (nYes == nil) nYes = [[NSNumber numberWithBool:YES] retain];
  if (nNo  == nil) nNo  = [[NSNumber numberWithBool:NO]  retain];
}

- (void)dealloc {
  RELEASE(self->appointments);
  [super dealloc];
}

/* execution */

- (void)_executeInContext:(id)_context {
  NSEnumerator *e;
  id appointment = nil;
  id login       = nil;
  id loginId     = nil;
  id loginTeams  = nil;

  e = [self->appointments objectEnumerator];
  
  // get login account
  login = [_context valueForKey:LSAccountKey];

  // get pkeys of the teams of the login account

  loginTeams = [login valueForKey:@"groups"];
  
  if (loginTeams == nil) {
    if (login)
      loginTeams = [_context runCommand:@"account::teams", @"object", login,nil];
    
    loginTeams = [login valueForKey:@"groups"];
  }

  loginTeams = [loginTeams mappedSetUsingSelector:@selector(valueForKey:)
                           withObject:@"companyId"];
  
  // get pkey of login account
  loginId = [login valueForKey:@"companyId"];
                             
  while ((appointment = [e nextObject])) {
    id teamKey = [appointment valueForKey:@"accessTeamId"];
    
    // the owner may always view the appointment
    if ([[appointment valueForKey:@"ownerId"] isEqual:loginId] ||
        ([loginId intValue] == 10000)) {
      [appointment takeValue:nYes forKey:@"isViewAllowed"];
      continue;
    }
    
    if (teamKey) {
      // if team is 'null', the appointment is private to the owner

      // check whether the login user is in access-team
      if ([loginTeams containsObject:teamKey]) {
        [appointment takeValue:nYes forKey:@"isViewAllowed"];
        continue;
      }
    }

    // check whether the login user is a participant
    {
      NSArray *participants;
      int  i, count;
      BOOL found = NO;
      
      participants = [appointment valueForKey:@"participants"];
      
      for (i = 0, count = [participants count]; i < count; i++) {
        id participant, pkey;
        
        participant = [participants objectAtIndex:i];
        pkey        = [participant valueForKey:@"companyId"];
        
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
        [appointment takeValue:nYes forKey:@"isViewAllowed"];
        continue;
      }
    }

    [appointment takeValue:nNo forKey:@"isViewAllowed"];
  }
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"appointments"]) {
    ASSIGN(self->appointments, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"appointments"])
    return self->appointments;
  else
    return [super valueForKey:_key];
}

@end
