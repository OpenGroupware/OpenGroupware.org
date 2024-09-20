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

#include "SxUserSettingsPage.h"
#include <ZSBackend/SxContactManager.h>
#include "common.h"
#include <LSFoundation/LSFoundation.h>

@implementation SxUserSettingsPage

- (id)init {
  if ((self = [super init])) {
    NSEnumerator *extAttrEnum;
    id extAttr;
    
    extAttrEnum = [[[self account] valueForKey:@"companyValue"]
                          objectEnumerator];
    
    while ((extAttr = [extAttrEnum nextObject])) {
      if ([[extAttr valueForKey:@"attribute"] isEqualToString:@"email1"])
        self->email = [[extAttr valueForKey:@"value"] retain];
    }

    self->selectedTimeZone = [[[[self commandContext] userDefaults]
                                      valueForKey:@"timezone"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->password         release];
  [self->selectedTimeZone release];
  [self->email            release];
  [self->message          release];
  [self->groups           release];
  [self->group            release];
  
  [super dealloc];
}

/* accessors */

- (BOOL)hasMessage {
  return ([self message] != nil);
}

- (void)setPassword:(NSString *)_password {
  ASSIGNCOPY(self->password, _password);
}
- (NSString *)password {
  return self->password;
}

- (void)setSelectedTimeZone:(NSString *)_timeZone {
  ASSIGNCOPY(self->selectedTimeZone, _timeZone);
}
- (NSString *)selectedTimeZone {
  return self->selectedTimeZone;
}

- (void)setEmail:(NSString *)_email {
  ASSIGNCOPY(self->email, _email);
}
- (NSString *)email {
  return self->email;
}

- (void)setMessage:(NSString *)_message {
  ASSIGNCOPY(self->message, _message);
}
- (NSString *)message {
  return self->message;
}


- (NSArray *)timeZones {
  NSArray *tmp;

  if ((tmp = [[NSUserDefaults standardUserDefaults]
                              valueForKey:@"LSTimeZones"]) != nil)
    return tmp;
  
  return [NSArray arrayWithObjects:
                  @"GMT",@"MET",@"PST",@"CET",@"EET",@"EST",@"HST",@"MST",
                  @"NZ",@"GMT+0100",@"GMT+0200",@"GMT+0300",@"GMT+0400",
                  @"GMT+0500",@"GMT+0600",@"GMT+0700",@"GMT+0800",@"GMT+0900",
                  @"GMT+1000",@"GMT+1100",@"GMT+1200",@"GMT-0100",@"GMT-0200",
                  @"GMT-0300",@"GMT-0400",@"GMT-0500",@"GMT-0600",@"GMT-0700",
                  @"GMT-0800",@"GMT-0900",@"GMT-1000",@"GMT-1100",@"GMT-1200",
                  nil];
}

- (NSDictionary *)settings {
  return [NSArray arrayWithObject:
                  [NSDictionary dictionaryWithObjectsAndKeys:[self zsBaseURL],
                                                @"User Homepage", nil]];
}

/* actions */

- (id)saveSettingsAction {
  id       request, acc;
  NSString *mail, *tz;

  [self setMessage:nil];
  
  request = [[self context] request];
  mail    = [request formValueForKey:@"email"];
  tz      = [[self timeZones] objectAtIndex:
                              [[request formValueForKey:@"timeZone"]
                                        intValue]];
  
  [self setEmail:mail];
  [self setSelectedTimeZone:tz];

  // save email
  if ((acc = [self account]) != nil) {
    id cmdctx;

    if ((cmdctx = [self commandContext]) != nil) {
      id person;

      person = [[cmdctx runCommand:@"object::get-by-globalid",
                       @"gid", [acc valueForKey:@"globalID"],
                       nil] objectAtIndex:0];

      if (person != nil) {
        [person takeValue:mail forKey:@"email1"];
        
        /*unused:result = */[cmdctx runCommand:@"person::set"
                         arguments:person];
        [cmdctx commit];
      }

      // save timezone setting
      [[cmdctx userDefaults] takeValue:tz forKey:@"timezone"];
      [[cmdctx userDefaults] synchronize];
    }
  }

  [self setMessage:@"Defaults successfully saved"];
  return self;
}

- (id)setPasswordAction {
  id       request, cmdctx;
  NSString *oldPwd, *newPwd, *newPwdRep, *oldCrypt, *currentPwd;
  BOOL     update;

  [self setMessage:nil];
  
  update     = YES;
  currentPwd = [[self account] valueForKey:@"password"];
  request    = [[self context] request];
  oldPwd     =  [request formValueForKey:@"oldpwd"];
  newPwd     =  [request formValueForKey:@"newpwd"];
  newPwdRep  =  [request formValueForKey:@"newpwdrep"];

  if (![newPwd isEqualToString:newPwdRep]) {
    [self logWithFormat:@"new passwords don't match"];
    [self setMessage:@"ERROR: New passwords don't match!"];
    update = NO;
  }

  if ([newPwd length] < 6) {
    [self logWithFormat:@"new password too short (min. 6 chars)"];
    [self setMessage:@"ERROR: New password is too short (min. 6 chars)!"];
    update = NO;
  }
  
  cmdctx   = [self commandContext];
  oldCrypt = [cmdctx runCommand:@"system::crypt",
                     @"password", oldPwd,
                     @"salt", currentPwd,
                     nil];

  if (![oldCrypt isEqualToString:currentPwd]) {
    [self logWithFormat:@"invalid old password"];
    [self setMessage:@"ERROR: Old password is wrong!"];
    update = NO;
  }

  if (update) {
    /*result =*/ [cmdctx runCommand:@"account::change-password",
                     @"object", [self account],
                     @"newPassword", newPwd,
                     nil];
    [cmdctx commit];
    [self setMessage:@"Password set successfully"];
  }
  
  return self;
}

- (SxContactManager *)contactManager {
  LSCommandContext *cmdctx;
  SxContactManager *sm;

  if ((cmdctx = [self commandContext]) == nil) {
    [self logWithFormat:@"got no OGo context for user"];
    return nil;
  }
  if ((sm = [SxContactManager managerWithContext:cmdctx]) == nil) {
    [self logWithFormat:@"got no contact manager for OGo context: %@", 
            cmdctx];
    return nil;
  }
  return sm;
}

- (id)saveGroupsAction {
  NSEnumerator   *enumerator;
  id             obj, ud;
  NSMutableArray *array;
  WORequest      *req;

  req        = [[self context] request];
  array      = [NSMutableArray arrayWithCapacity:10];
  enumerator = [[self groups] objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    NSString *cn;

    cn = [obj valueForKey:@"cn"];
    if (![[req formValueForKey:cn] boolValue]) {
      [obj setObject:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
      [array addObject:cn];
    }
    else {
      [obj setObject:[NSNumber numberWithBool:YES] forKey:@"isSelected"];
    }
  }
  ud = [[self commandContext] userDefaults];
  [ud takeValue:array forKey:@"ZLGroupSelection"];
  [(NSUserDefaults *)ud synchronize];
  return self;
}


- (NSArray *)groups {
  if (self->groups == nil) {
    NSMutableArray *array;
    NSEnumerator   *enumerator;
    id             obj;
    NSArray        *selectedGroups;

    selectedGroups = [[[self commandContext] userDefaults]
                             arrayForKey:@"ZLGroupSelection"];
    array          = [NSMutableArray array];
    enumerator     = [[self contactManager] listGroups];
    
    while ((obj = [enumerator nextObject])) {
      NSString *cn;

      cn = [obj valueForKey:@"cn"];
      if (![cn isEqualToString:@"all intranet"]) {
        NSNumber            *n;
        NSMutableDictionary *dict;

        dict = [obj mutableCopy];
        n    = [NSNumber numberWithBool:![selectedGroups containsObject:cn]];
        
        [dict setObject:n forKey:@"isSelected"];
        [array addObject:[dict autorelease]];
      }
    }
    self->groups = [array copy];
  }
  return self->groups;
}

- (id)group {
  return self->group;
}
- (void)setGroup:(id)_g {
  ASSIGN(self->group, _g);
}
@end /* SxUserSettingsPage */
