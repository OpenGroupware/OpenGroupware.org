/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <LSFoundation/LSDBObjectGetCommand.h>

@interface LSGetAppointmentCommand : LSDBObjectGetCommand
@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@implementation LSGetAppointmentCommand

static int LSRootPrimaryKey = 10000;

/* command methods */

- (BOOL)isRootAccountId:(NSNumber *)_accountId {
  // TODO: use some command to check whether an account has root permissions
  if ([_accountId intValue] == LSRootPrimaryKey)
    return YES;
  
  return NO;
}

- (void)_checkPermission:(NSArray *)_appointments context:(id)_ctx {
  // TODO: split up
  NSMutableArray *filtered;
  NSEnumerator   *e;
  NSNumber *loginId    = nil;
  NSArray  *loginTeams = nil;
  id appointment       = nil;
  id login;

  e        = [_appointments objectEnumerator];
  filtered = [[NSMutableArray alloc] initWithCapacity:[_appointments count]];
  
  /* get login account */
  login = [_ctx valueForKey:LSAccountKey];
  
  /* get pkeys of the teams of the login account */
  if (login)
    loginTeams = [_ctx runCommand:@"account::teams", @"object", login, nil];
  
  loginTeams = [loginTeams valueForKey:@"companyId"];
  
  /* get pkey of login account */
  loginId = [login valueForKey:@"companyId"];
                             
  while ((appointment = [e nextObject])) {
    NSNumber *teamKey;

    teamKey = [appointment valueForKey:@"accessTeamId"];
    
    /* the owner may always view the appointment */
    if ([[appointment valueForKey:@"ownerId"] isEqual:loginId] ||
        [self isRootAccountId:loginId]) {
      [filtered addObject:appointment];
      continue;
    }
    
    if (teamKey != nil) {
      /* if team is 'null', the appointment is private to the owner */
      
      /* check whether the login user is in access-team */
      if ([loginTeams containsObject:teamKey]) {
        [filtered addObject:appointment];
        continue;
      }
    }

    /* check whether the login user is a participant */
    {
      NSArray *participants;
      int  i, count;
      BOOL found = NO;
      
      participants = [appointment valueForKey:@"participants"];
      count = [participants count];
      
      for (i = 0; i < count; i++) {
        NSNumber *pkey;
        id participant;
	
	participant = [participants objectAtIndex:i];
	pkey        = [participant valueForKey:@"companyId"];

        if ([[participant valueForKey:@"isTeam"] boolValue]) {
          if ([loginTeams containsObject:pkey]) {
            found = YES;
            break;
          }
        }
        else if ([loginId isEqual:pkey]) {
	  found = YES;
	  break;
        }
      }
      if (found) {
        [filtered addObject:appointment];
        continue;
      }
    }
  }
  [self setReturnValue:filtered];
  [filtered release]; filtered = nil;
}

- (void)_executeInContext:(id)_context {
  NSArray *results;
  
  [super _executeInContext:_context];
  
  /* 
     Note: retain/autorelease is necessary because the other calls may release
           it! (seems to happen on OSX)
  */
  results = [[[self object] retain] autorelease];
  
  LSRunCommandV(_context, @"appointment", @"get-participants",
                @"appointments", results, nil);
  
  [self _checkPermission:results context:_context];
  
  LSRunCommandV(_context, @"appointment", @"get-comments",
                @"objects", results, nil);
}

/* record initializer */

- (NSString *)entityName {
  return @"Date";
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"]) {
    _key   = @"dateId";
    _value = [_value keyValues][0];
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"gid"]) {
    id v;
    
    v = [super valueForKey:@"dateId"];
    v = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                       keys:&v keyCount:1
                       zone:NULL];
    return v;
  }

  return [super valueForKey:_key];
}

@end /* LSGetAppointmentCommand */
