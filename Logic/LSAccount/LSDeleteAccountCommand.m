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

#include <LSSetCompanyCommand.h>

@class NSArray, NSData, NSString;

@interface LSDeleteAccountCommand : LSSetCompanyCommand
@end

#import "common.h"

@implementation LSDeleteAccountCommand

- (void)_executeInContext:(id)_context {
  NSString *newLogin;
  NSNumber *nullNum, *oneNum;
  id obj;

  obj = [self object];
  
  [self assert:(obj != nil) reason:@"no account object"];

  LSRunCommandV(_context, @"account", @"setgroups",
                @"member", [self object],
                @"groups", [NSArray array], nil);
  
  newLogin = [[obj valueForKey:@"companyId"] stringValue];
  newLogin = [@"OGo" stringByAppendingString:newLogin];
  
  [obj takeValue:newLogin    forKey:@"login"];
  [obj takeValue:@"archived" forKey:@"dbStatus"];
  [obj takeValue:@""         forKey:@"imapPasswd"];
  [obj takeValue:@""         forKey:@"sourceUrl"];
  
  nullNum = [NSNumber numberWithInt:0];
  oneNum  = [NSNumber numberWithInt:1];
  [obj takeValue:nullNum     forKey:@"isAccount"];
  [obj takeValue:nullNum     forKey:@"isTemplateUser"];
  [obj takeValue:nullNum     forKey:@"isIntraAccount"];
  [obj takeValue:nullNum     forKey:@"isExtraAccount"];
  [obj takeValue:oneNum      forKey:@"isLocked"];
  
  [super _executeInContext:_context];
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

@end /* LSDeleteAccountCommand */
