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

#include "SkyRegistryAction+Authorization.h"
#include "common.h"

@implementation SkyRegistryAction(Authorization)

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}

- (NSString *)authorizationUser {
  NSString *result = nil;

  result =  [[self userDefaults] objectForKey:@"SxRegistryComponentUser"];

  if (result == nil)
    [self logWithFormat:
          @"WARNING: Default SxRegistryComponentUser is not set !"];
  return result;
}

- (NSString *)authorizationPassword {
  NSString *result = nil;

  result =  [[self userDefaults] objectForKey:@"SxRegistryComponentPassword"];

  if (result == nil)
    [self logWithFormat:
          @"WARNING: Default SxRegistryComponentPassword is not set !"];
  return result;
}

- (NSArray *)credentialsArray {
  NSString *creds;

  creds = [[self credentials] stringByDecodingBase64];
  return [creds componentsSeparatedByString:@":"];
}

- (BOOL)isAuthorized {
  NSArray  *creds;
  NSString *user, *password;

  if ((creds = [self credentialsArray]) != nil) {
    user = [creds objectAtIndex:0];
    password = [creds objectAtIndex:1];
  }
  else {
    [self logWithFormat:@"ERROR: no credentials set"];
    return NO;
  }
  
  if ([user isEqualToString:[self authorizationUser]]) {
    if ([password isEqualToString:[self authorizationPassword]])
      return YES;
    else
      [self logWithFormat:@"ERROR: invalid password"];
  }
  else
    [self logWithFormat:@"ERROR: invalid user '%@'",user];
  return NO;
}

@end /* SkyRegistryAction(Authorization) */
