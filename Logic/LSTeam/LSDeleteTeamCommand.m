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

@interface LSDeleteTeamCommand : LSSetCompanyCommand
@end

#import "common.h"

@implementation LSDeleteTeamCommand

- (void)_executeInContext:(id)_context {
  id obj = [self object];
  
  [self assert:(obj != nil) reason:@"no team object"];

  LSRunCommandV(_context, @"team", @"setmembers",
                @"members", [NSArray array],
                @"group", obj, nil);
  
  [obj takeValue:@"archived" forKey:@"dbStatus"];
  [obj takeValue:[NSString stringWithFormat:@"LS%@",
                           [obj valueForKey:@"companyId"]] forKey:@"login"];
  
  [super _executeInContext:_context];
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

@end
