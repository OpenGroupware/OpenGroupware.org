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
#import  "SkyTool.h"

/*
  Exit codes:
  5 - wrong parameters
  6 - database failed
*/

@interface SkyDelAccount : SkyTool
@end /* SkyDelAccount */

@implementation SkyDelAccount

- (BOOL)onlyRoot {
  return YES;
}


- (NSString *)additionalSwitches {
  return @"\t-login\t\taccount login";
}

- (NSString *)toolName {
  return @"sky_delete_account";
}

- (NSString *)versionInformation {
  return @"1.0.0";
}

- (NSString *)toolDescription {
  return @"This tool deletes a SKYRiX account specified by login";
}

- (int)runWithArguments:(NSArray *)_args {
  if (![super runWithArguments:_args]) {
    LSCommandContext    *ctx;
    NSUserDefaults      *def;
    NSString            *login;
    id                  obj;

    ctx   = [self commandContext];
    def   = [NSUserDefaults standardUserDefaults];

    if (!(login = [def stringForKey:@"login"])) {
      NSLog(@"Wrong parameterm, missing 'login'");
      exit(5);
    }
    if (!(obj = [[ctx runCommand:@"account::get", @"login", login, nil]
                      lastObject])) {
      NSLog(@"Missing account for login %@", login);
      exit(5);
    }
    
    [self logFormat:@"delete account %@", login];

    if (![ctx runCommand:@"account::toperson", @"object", obj, nil]) {
      NSLog(@"Account to person failed with %@", login);
      exit(5);
    }
    if (![ctx commit]) {
      NSLog(@"commit failed");
      [ctx rollback];
      exit(6);
    }
  }
  return 0;
}

@end /* SkyGetAccountLoginNames */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  SkyDelAccount  *tool;
  
  pool = [[NSAutoreleasePool alloc] init];
  
#if LIB_FOUNDATION_LIBRARY  
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  tool = [[SkyDelAccount alloc] init];
  /* unused: res = */[tool runWithArguments:
		                          [[NSProcessInfo processInfo] arguments]];
  [tool release];
  
  [pool release];
  exit(0);
  /* static linking */
  [NGExtensions class];
  return 0;
}


