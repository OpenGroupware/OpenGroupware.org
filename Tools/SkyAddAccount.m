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
  7 - missing all intranet team
  8 - number license user exceeded
*/

@interface SkyAddAccount : SkyTool
@end /* SkyAddAccount */

@implementation SkyAddAccount

- (BOOL)onlyRoot {
  return YES;
}


- (NSString *)additionalSwitches {
  return @"\t-login\t\taccount login\n"
    @"\t-firstname\t\account first name\n"
    @"\t-lastname\taccount last name\n"
    @"\t-phone\t\taccount phone\n"
    @"\t-mobile\t\taccount mobile phone\n"
    @"\t-fax\t\taccount fax number\n"
    @"\t-title\t\taccount title";
}

- (NSString *)toolName {
  return @"sky_add_account";
}

- (NSString *)versionInformation {
  return @"1.0.1";
}

- (NSString *)toolDescription {
  return @"This tool creates a new SKYRiX account.";
}

- (int)runWithArguments:(NSArray *)_args {
  if (![super runWithArguments:_args]) {
    LSCommandContext    *ctx;
    NSMutableDictionary *dict;
    NSMutableArray      *tel;
    NSUserDefaults      *def;
    NSString            *obj;

    ctx   = [self commandContext];
    dict  = [NSMutableDictionary dictionaryWithCapacity:8];
    tel   = [NSMutableArray arrayWithCapacity:8];
    def   = [NSUserDefaults standardUserDefaults];

    if (!(obj = [def stringForKey:@"login"])) {
      NSLog(@"Wrong parameterm, missing 'login'");
      exit(5);
    }
    [dict setObject:obj forKey:@"login"];
    
    if ((obj = [def stringForKey:@"firstname"])) {
      [dict setObject:obj forKey:@"firstname"];
    }
    if ((obj = [def stringForKey:@"lastname"])) {
      [dict setObject:obj forKey:@"name"];
    }
    if ((obj = [def stringForKey:@"phone"])) {
      [tel addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   @"01_tel", @"type",
                                   obj, @"number", nil]];
    }
    if ((obj = [def stringForKey:@"mobile"])) {
      [tel addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   @"03_tel_funk", @"type",
                                   obj, @"number", nil]];
    }
    if ((obj = [def stringForKey:@"fax"])) {
      [tel addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   @"10_fax", @"type",
                                   obj, @"number", nil]];
    }
    if ((obj = [def stringForKey:@"title"])) {
      [dict setObject:obj forKey:@"degree"];
    }
    if ([tel count] > 0)
      [dict  setObject:tel forKey:@"telephones"];

    {
      NSArray *team;

      team = [ctx runCommand:@"team::get",
                  @"companyId", [NSNumber numberWithInt:10003], nil];
      if ([team count] != 1) {
        NSLog(@"Missing all intranet team");
        exit(7);
      }
      [dict setObject:team forKey:@"teams"];

    }
    
    [self logFormat:@"create account %@", dict];

    if ([ctx runCommand:@"account::new" arguments:dict]) {
      if (![ctx commit]) {
        NSLog(@"Couldn`t commit transaction");
        exit(6);
      }
    }
    else {
      NSLog(@"insert failed, rollback");
      [ctx rollback];
      exit(6);
    }
  }
  return 0;
}

@end /* SkyGetAccountLoginNames */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  SkyAddAccount  *tool;
  int res;
  
  pool = [[NSAutoreleasePool alloc] init];
  
#if LIB_FOUNDATION_LIBRARY  
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  tool = [[SkyAddAccount alloc] init];
  res = [tool runWithArguments:
		[[NSProcessInfo processInfo] arguments]];
  [tool release];
  
  [pool release];
  exit(0);
  /* static linking */
  [NGExtensions class];
  return 0;
}

