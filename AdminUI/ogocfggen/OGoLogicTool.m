/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "OGoLogicTool.h"
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@implementation OGoLogicTool

- (id)init {
  if ((self = [super init])) {
  }
  return self;
}

- (void)dealloc {
  [self->cmdctx release];
  [super dealloc];
}

/* accessors */

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}
- (NSString *)username {
  NSUserDefaults *ud = [self userDefaults];
  NSString *s;

  if ((s = [ud stringForKey:@"login"])) return s;
  if ((s = [ud stringForKey:@"l"]))     return s;
  if ((s = [ud stringForKey:@"user"]))  return s;
  if ((s = [ud stringForKey:@"u"]))     return s;
  return nil;
}
- (NSString *)password {
  NSUserDefaults *ud = [self userDefaults];
  NSString *s;

  if ((s = [ud stringForKey:@"pwd"]))      return s;
  if ((s = [ud stringForKey:@"p"]))        return s;
  if ((s = [ud stringForKey:@"password"])) return s;
  if ((s = [ud stringForKey:@"passwd"]))   return s;
  return nil;
}

/* operations */

- (BOOL)doLogin {
  // TODO: shouldn't that use the OGoContextFactory?
  NSString *login, *pwd;

  if ((login = [self username]) == nil)
    return NO;
  if ((pwd = [self password]) == nil)
    return NO;
  
  self->cmdctx = [[LSCommandContext alloc] init];
  if (![self->cmdctx login:login password:pwd]) {
    [self->cmdctx release];
    return NO;
  }
  return YES;
}

@end /* OGoLogicTool */
