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

#import <LSFoundation/LSDBFetchRelationCommand.h>

@interface LSFetchJobExecutantCommand : LSDBFetchRelationCommand
@end

#import "common.h"

@implementation LSFetchJobExecutantCommand

- (NSString *)entityName {
  return @"Job";
}

- (NSArray *)_fetchRelations {
  NSMutableArray *relations = [NSMutableArray arrayWithCapacity:64];

  [super takeValue:@"Team" forKey:@"destinationEntityName"];
  [relations addObjectsFromArray:[super _fetchRelations]];

  [super takeValue:@"Person" forKey:@"destinationEntityName"];
  [relations addObjectsFromArray:[super _fetchRelations]];
  return relations;
}

- (void)_executeInContext:(id)_context {
  int i,  cnt    = 0;
  id      obj    = nil;
  NSArray *array = nil;
  
  [super _executeInContext:_context];

  array = [self object];
  if ([array isKindOfClass:[NSArray class]] == NO) 
    array = [NSArray arrayWithObject:obj];

  for (i = 0, cnt = [array count]; i < cnt; i++) {
    id value = nil;
    obj = [array objectAtIndex:i];
    if ([[obj valueForKey:@"isTeamJob"] boolValue] == YES) {
      value = [[obj valueForKey:@"executant"] valueForKey:@"description"];
    }
    else {
      value = [[obj valueForKey:@"executant"] valueForKey:@"login"];
    }
    [obj takeValue:value forKey:@"__executant_name__"];
  }
}

- (BOOL)isToMany {
  return NO; 
}
 
- (NSString *)sourceKey {
  return @"executantId";
}

- (NSString *)destinationKey {
  return @"companyId";
}


@end
