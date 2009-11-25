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

#include <LSFoundation/LSDBObjectDeleteCommand.h>

@interface LSDeleteJobCommand : LSDBObjectDeleteCommand
@end

#include "common.h"
 
@implementation LSDeleteJobCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"10_archived"  forKey:@"logAction"];
    [self takeValue:@"Job archived" forKey:@"logText"];
  }
  return self;
}

- (NSArray *)relations {
  NSArray        *myRelations;
  NSEnumerator   *enumerator;
  NSMutableArray *relevantRelations;
  EORelationship *rs;
  NSMutableArray *excludeRels;

  myRelations       = [[self entity] relationships];
  enumerator        = [myRelations objectEnumerator];
  relevantRelations = [NSMutableArray arrayWithCapacity:4];
  
  excludeRels = [NSMutableArray arrayWithCapacity:4];
  [excludeRels addObjectsFromArray:[NSArray arrayWithObjects:@"toJob", nil]];
  
  while ((rs = [enumerator nextObject])) {
    if ([excludeRels containsObject:[rs name]])
      continue;

    [relevantRelations addObject:rs];
  }
  
  return relevantRelations;
}

- (NSString *)entityName {
  return @"Job";
}

/* command methods */

- (void)_executeInContext:(id)_context {
  [self _deleteRelations:[self relations] inContext:_context];
  /* delete properties */
  [[_context propertyManager] removeAllPropertiesForGlobalID:
		  [[self object] globalID]];
  /* delete links */
  [[_context linkManager] deleteLinksTo:(id)[[self object] globalID] type:nil];
  [[_context linkManager] deleteLinksFrom:(id)[[self object] globalID] type:nil];
  /* log deletion */
  if (![self reallyDelete]) {
    LSRunCommandV(_context, @"object", @"add-log",
                  @"logText"    , [self valueForKey:@"logText"],
                  @"action"     , [self valueForKey:@"logAction"],
                  @"objectToLog", [self object],
                  nil);
  }
  [self calculateCTagInContext:_context];
  [super _executeInContext:_context];
}

@end /* LSDeleteJobCommand */
