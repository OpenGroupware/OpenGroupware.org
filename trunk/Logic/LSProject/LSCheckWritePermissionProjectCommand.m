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
  project::check-write-permission

  TODO: document!
  - has special handling for fake projects?
*/

@interface LSCheckWritePermissionProjectCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSCheckWritePermissionProjectCommand

- (void)_executeInContext:(id)_context {
  // TODO: split up this huge method!
  NSMutableArray *permittedObjs = nil;
  NSArray        *teams         = nil;
  id             obj, account;
  NSNumber       *acId;
  int            i, cnt;

  obj     = [self object];  
  account = [_context valueForKey:LSAccountKey];
  acId    = [account valueForKey:@"companyId"]; 
  cnt     = [obj count];
  
  if ([acId intValue] == 10000) {
    /* is root */
    [self setReturnValue:obj];
    return;
  }
  
  permittedObjs = [NSMutableArray arrayWithCapacity:128];
  teams         = [account valueForKey:@"groups"];
  
  if (teams == nil) {
    teams = LSRunCommandV(_context, @"account", @"teams",
			  @"object", account, nil);
  }

  for (i = 0; i < cnt; i++) {
    id proj;

    proj = [obj objectAtIndex:i];

    if ([[proj valueForKey:@"isFake"] boolValue])
      [permittedObjs addObject:proj];
    else if ([[proj valueForKey:@"ownerId"] isEqual:acId])
      [permittedObjs addObject:proj];
    else if ([teams containsObject:[proj valueForKey:@"team"]])
      [permittedObjs addObject:proj];
    else {
        NSArray *assignments = nil;
        int     i, cnt;
        BOOL    wasFound;

        assignments = [proj valueForKey:@"companyAssignments"];
        wasFound    = NO;

        for (i = 0, cnt = [assignments count]; i < cnt; i++) {
          id           as  = nil;
          NSString     *ac = nil;
          EOGlobalID   *accGID;

          as     = [assignments objectAtIndex:i];
          ac     = [as valueForKey:@"accessRight"];
          accGID = [as valueForKey:@"companyId"];

          if (![ac isNotNull])
            ac = nil;

          if ([acId isEqual:accGID]) {
            if ([ac rangeOfString:@"m"].length > 0)
              [permittedObjs addObject:proj];
	    
            wasFound = YES;
            break;
          }
        }
        if (wasFound == NO) {
          for (i = 0, cnt = [assignments count]; i < cnt; i++) {
            id           as  = nil;
            NSString     *ac = nil;
            NSEnumerator *enumerator;
            EOGlobalID   *accGID;
            id           tObj;

            as     = [assignments objectAtIndex:i];
            ac     = [as valueForKey:@"accessRight"];
            accGID = [as valueForKey:@"companyId"];

            if (![ac isNotNull])
              ac = nil;

            enumerator = [teams objectEnumerator];
            while ((tObj = [enumerator nextObject])) {
              if ([[tObj valueForKey:@"companyId"] isEqual:accGID]) {
                if ([ac rangeOfString:@"m"].length > 0) {
                  [permittedObjs addObject:proj];
                  break;
                }
              }
            }
            if (tObj)
              break;
          }
        }
      }      
  }
  [self setReturnValue:permittedObjs];
}

@end /* LSCheckWritePermissionProjectCommand */
