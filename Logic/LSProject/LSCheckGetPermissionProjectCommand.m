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

#import <LSFoundation/LSBaseCommand.h>

@interface LSCheckGetPermissionProjectCommand : LSBaseCommand
{
}

@end

#import "common.h"

@implementation LSCheckGetPermissionProjectCommand

- (NSArray *)_getTeamsOfAccount:(id)_obj inContext:(id)_context {
  NSArray *teams;
  
  if ((teams = [_obj valueForKey:@"groups"]))
    /* used cached teams */
    return teams;
  
  teams = LSRunCommandV(_context, @"account", @"teams", @"object", _obj, nil);
  return teams;
}

- (BOOL)_isFakeProject:(id)_project {
  return [[_project valueForKey:@"isFake"] boolValue];
}
- (BOOL)_isProject:(id)_project ownedByAccountID:(id)_accountId {
  return [[_project valueForKey:@"ownerId"] isEqual:_accountId];
}

- (void)_executeInContext:(id)_context {
  // TODO: split up this method
  NSMutableArray *permittedObjs = nil;
  NSArray        *teams         = nil;
  id             obj            = nil;
  id             account        = nil;
  NSNumber       *acId          = nil;
  int            i, cnt;

  obj     = [self object];  
  account = [_context valueForKey:LSAccountKey];
  acId    = [account valueForKey:@"companyId"]; 
  cnt     = [obj count];

  if ([acId intValue] == 10000) {
    [self setReturnValue:obj];
    return;
  }

  permittedObjs = [NSMutableArray arrayWithCapacity:128];

  teams = [self _getTeamsOfAccount:account inContext:_context];
  
  for (i = 0; i < cnt; i++) {
    id project = [obj objectAtIndex:i];
    
    if ([self _isFakeProject:project]) {
      [permittedObjs addObject:project];
      continue;
    }
    if ([self _isProject:project ownedByAccountID:acId]) {
      [permittedObjs addObject:project];
      continue;
    }
    if ([teams containsObject:[project valueForKey:@"team"]]) {
      [permittedObjs addObject:project];
      continue;
    }
    
    // TODO: the following sections needs to be split up!
    {
      NSArray *assignments = nil;
      int     i, cnt;
      BOOL    foundAccess;

      foundAccess = NO;
      assignments = [project valueForKey:@"companyAssignments"];

      for (i = 0, cnt = [assignments count]; i < cnt; i++) {
        id       as  = nil;
        NSString *ac = nil;

        as = [assignments objectAtIndex:i];
        ac = [as valueForKey:@"accessRight"];

        if (![ac isNotNull])
          ac = nil;

        if ([acId isEqual:[as valueForKey:@"companyId"]]) {
          foundAccess = YES;
          if ([[as valueForKey:@"hasAccess"] boolValue])
            [permittedObjs addObject:project];
          else if ([ac rangeOfString:@"r"].length > 0)
            [permittedObjs addObject:project];
          break;
        }
      }
      if (foundAccess == NO) {
        int j, jCnt;

        for (j = 0, jCnt = [teams count]; j < jCnt; j++) {
          id teamId;

          teamId = [[teams objectAtIndex:j] valueForKey:@"companyId"];

          for (i = 0, cnt = [assignments count]; i < cnt; i++) {
            id       as  = nil;
            NSString *ac = nil;

            as = [assignments objectAtIndex:i];
            ac = [as valueForKey:@"accessRight"];

            if (![ac isNotNull])
              ac = nil;

            if ([teamId isEqual:[as valueForKey:@"companyId"]]) {
              if ([[as valueForKey:@"hasAccess"] boolValue] ||
                  [ac rangeOfString:@"r"].length > 0) {
                foundAccess = YES;
                [permittedObjs addObject:project];
              }
              break;
            }
          }
          if (foundAccess)
            break;
        }
      }
    }
  }
  [self setReturnValue:permittedObjs];
}

@end /*LSCheckGetPermissionProjectCommand */
