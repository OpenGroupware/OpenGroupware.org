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
#include "common.h"

/*

  GetAccount

  Search for account by login. Returns account on stdout key:value\n

  
  Defaults/Arguments

  get_account_debug     NO    Debug Output
  sky_login             nil   Skyrix Login    
  sky_pwd               nil   Skyrix Password
  
  account_login         nil   login
*/

int mainProcedure() {
  OGoContextManager *lso   = nil;
  id              lss    = nil;
  NSString        *login = nil;
  NSString        *pwd   = nil;
  NSUserDefaults  *defs  = nil;
  BOOL            debug  = NO;
    
  OGoContextManager = [OGoContextManager defaultManager];

  defs  = [NSUserDefaults standardUserDefaults];
  debug = [defs boolForKey:@"get_account_debug"];
  login = [defs stringForKey:@"sky_login"]; 
  pwd   = [defs stringForKey:@"sky_pwd"];   

  if (debug == YES) {
    NSLog(@"got sky_login %@ sky_pwd %@", login, pwd);
  }
  
  if (login == nil) {
    NSLog(@"missing login");
    return -1;
  }
  
  if (pwd == nil)
    pwd = @"";
  
  lss = [lso login:login password:pwd];

  if (lss == nil) {
    NSLog(@"login failed");
    return -1;
  }
  
  {
    NSString     *l          = [defs stringForKey:@"account_login"];
    id           account     = nil;
    NSEnumerator *enumerator = nil;
    id           obj         = nil;

    if (debug == YES) {
      NSLog(@"account_login %@", l);
    }
    if (l == nil) {
      NSLog(@"missing account_login");
      [lss rollback];      
      return -1;
    }

    account = [lss runCommand:@"account::get-by-login",
                   @"login", l, nil];

    if (debug == YES) {
      NSLog(@"account after get-by-login  %@", account);
    }

    if (account == nil) {
      NSLog(@"didn`t found account for %@", l);
      [lss rollback];
      return -1;
    }

    enumerator = [[[[lso model] entityNamed:@"Person"] attributes]
                         objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      id n = nil;
      id v = nil;

      n = [obj name];
      v = [account valueForKey:n];
      if ([v isNotNull])
        printf("%s:%s\n", [n cString], [[v stringValue] cString]);
    }
    printf("\n");
    fflush(stdout);
  }
  [lss commit];
  return 0;
}

int main(int argc, const char **argv, char **env) {
  int result = 0;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif
  NGInitTextStdio();

#ifdef __MINGW32__
  [GDLExtensions class];
  [NGExtensions  class];
  [NGStreams     class];
  [NGMime        class];
#endif

  if (argc == 1) {
    printf("  GetAccount\n");
    printf("\n");
    printf("  Search for account by login. Returns account on stdout key:value"
           "\\n\n");
    printf("\n");
    printf("  \n");
    printf("  Defaults/Arguments\n");
    printf("\n");
    printf("  get_account_debug     NO    Debug Output\n");
    printf("  sky_login             nil   Skyrix Login    \n");
    printf("  sky_pwd               nil   Skyrix Password\n");
    printf("  \n");
    printf("  account_login         nil   login\n\n");
    return 0;
  }
  
  
  NS_DURING {
    result = mainProcedure();
  }
  NS_HANDLER {
    printf("got exception %s", [[localException description] cString]);
  }
  NS_ENDHANDLER;
  return result;
}
