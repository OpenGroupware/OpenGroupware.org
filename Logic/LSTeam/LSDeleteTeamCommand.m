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

#include <LSAddress/LSSetCompanyCommand.h>

@class NSArray, NSData, NSString;

@interface LSDeleteTeamCommand : LSSetCompanyCommand
@end

#include "common.h"

@implementation LSDeleteTeamCommand

- (void)_executeInContext:(id)_context {
  OGoAccessManager *am;
  NSString *delKey;
  id obj;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no team object"];
  
  /* check permission */
  
  // TODO: we should rather check for 'd', which in turn should only the owner
  //       or root the deletion?
  am = [_context accessManager];
  [self assert:[am operation:@"w" 
                   allowedOnObjectID:[obj valueForKey:@"globalID"]]
        reason:@"permission denied"];
  
  /* reset members */

  LSRunCommandV(_context, @"team", @"setmembers",
                @"members", [NSArray array],
                @"group", obj, nil);
  
  /* mark as archived and reset login */
  
  [obj takeValue:@"archived" forKey:@"dbStatus"];
  
  delKey = [NSString stringWithFormat:@"LS%@",[obj valueForKey:@"companyId"]];
  [obj takeValue:delKey forKey:@"login"];
  
  delKey = [delKey stringByAppendingFormat:@" [was: %@]",
                   [obj valueForKey:@"description"]];
  [obj takeValue:delKey forKey:@"description"];
  
  /* let superclass perform update */
  
  [super _executeInContext:_context];
}

/* record initializer */

- (NSString *)entityName {
  return @"Team";
}

@end /* LSDeleteTeamCommand */
