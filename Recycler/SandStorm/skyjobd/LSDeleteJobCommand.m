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

#import <LSFoundation/LSDBObjectDeleteCommand.h>

@interface LSDeleteJobCommand : LSDBObjectDeleteCommand
@end

#import "common.h"
 
@implementation LSDeleteJobCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"10_archived"  forKey:@"logAction"];
    [self takeValue:@"Job archived" forKey:@"logText"];
  }
  return self;
}

- (NSArray *)relations {
  NSArray        *myRelations       = nil;
  NSEnumerator   *enumerator        = nil;
  NSMutableArray *relevantRelations = nil;
  EORelationship *rs                = nil;
  NSMutableArray *excludeRels       = nil;

  myRelations       = [[self entity] relationships];
  enumerator        = [myRelations objectEnumerator];
  relevantRelations = [[NSMutableArray alloc] init];

  excludeRels = [NSMutableArray arrayWithCapacity:4];
  [excludeRels addObjectsFromArray:[NSArray arrayWithObjects:@"toJob", nil]];
  
  while ((rs = [enumerator nextObject])) {
    if (![excludeRels containsObject:[rs name]]) {
      [relevantRelations addObject:rs];
    }
  }

  return AUTORELEASE(relevantRelations);
}

- (NSString *)entityName {
  return @"Job";
}

// command methods

- (void)_executeInContext:(id)_context {
  [self _deleteRelations:[self relations] inContext:_context];

  if (![self reallyDelete]) {
  
    LSRunCommandV(_context, @"object", @"add-log",
                  @"logText"    , [self valueForKey:@"logText"],
                  @"action"     , [self valueForKey:@"logAction"],
                  @"objectToLog", [self object],
                  nil);
  }
  [super _executeInContext:_context];
}

@end
