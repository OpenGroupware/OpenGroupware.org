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

#include <LSFoundation/LSBaseCommand.h>

/*
  LSCheckPermissionProjectCommand

  TODO: document
*/

@interface LSCheckPermissionProjectCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSCheckPermissionProjectCommand

- (void)_executeInContext:(id)_context {
  NSNumber *teamId;
  id   login;
  id   project;
  int  loginId;
  BOOL retVal  = NO;
  
  login   = [_context valueForKey:LSAccountKey];
  project = [self object];
  teamId  = [project valueForKey:@"teamId"];
  loginId = [[login valueForKey:@"companyId"] intValue];
  
  [self assert:(project != nil) reason:@"No project is set"];
  if (![teamId isNotNull]) {
    if ([[project valueForKey:@"ownerId"] intValue] == loginId)
      retVal = YES;
  }
  else {
    NSArray *staff = nil;

    LSRunCommandV(_context, @"project", @"get-team",
                  @"object",      project,
                  @"relationKey", @"team", nil);
    LSRunCommandV(_context, @"project", @"get-owner",
                  @"object",      project,
                  @"relationKey", @"owner", nil);
    
    staff = [NSArray arrayWithObjects:
                     [project valueForKey:@"team"],
                     [project valueForKey:@"owner"], nil];
    
    retVal = [LSRunCommandV(_context, @"login", @"check-login",
                     @"staffList", staff,
                     nil) boolValue];
  } 
  [self setReturnValue:[NSNumber numberWithBool:retVal]];
}

@end /* LSCheckPermissionProjectCommand */
