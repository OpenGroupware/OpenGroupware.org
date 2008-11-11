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

#include "LSDeleteCompanyCommand.h"
#include "common.h"
 
@implementation LSDeleteCompanyCommand

// command methods

- (NSArray *)relations {
  NSArray        *myRelations;
  NSEnumerator   *enumerator;
  NSMutableArray *relevantRelations, *excludeRels;
  EORelationship *rs;

  myRelations       = [[self entity] relationships];
  enumerator        = [myRelations objectEnumerator];
  relevantRelations = [[NSMutableArray alloc] init];
  excludeRels       = [[NSMutableArray alloc] init];
  
  [excludeRels addObjectsFromArray:[NSArray arrayWithObjects:
                                            @"toCompanyAssignment",
                                            @"toDateCompanyAssignment",
                                            //@"toProjectCompanyAssignment",
                                            nil]];
  
  while ((rs = [enumerator nextObject])) {
    if (![excludeRels containsObject:[rs name]]) {
      [relevantRelations addObject:rs];
    }
  }
  [excludeRels release]; excludeRels = nil;
  return [relevantRelations autorelease];
}

- (BOOL)_deleteCompanyInfo {
  BOOL isOk; 
  id   companyInfo;

  //[[self databaseChannel] refetchObject:[self object]];

  companyInfo = [[self object] valueForKey:@"toCompanyInfo"];
  isOk        = NO;

  if ([companyInfo isNotNull]) {
    if ([self reallyDelete]) 
      isOk = [[self databaseChannel] deleteObject:companyInfo];
    else {
      [companyInfo takeValue:@"archived" forKey:@"dbStatus"];
      isOk = [[self databaseChannel] updateObject:companyInfo];
    }
  }
  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
  return YES;
}

- (BOOL)isRootID:(NSNumber *)_pkey {
  return [_pkey intValue] == 10000 ? YES : NO;
}

- (void)_executeInContext:(id)_context {
  id user;
  id isAccount;
  
  [self assert:([self object] != nil) reason:  @"no object available"];

  user      = [_context valueForKey:LSAccountKey];
  isAccount = [[self object] valueForKey:@"isAccount"];

  if ((isAccount != nil) && ([isAccount boolValue])) {
    [self assert:[self isRootID:[user valueForKey:@"companyId"]]
          reason:@"Only root can delete accounts!"];
  }
  if (![[_context accessManager] operation:@"w"
                                 allowedOnObjectID:
                                 [[self object] globalID]]) {
    [self assert:NO reason:@"Delete failed due to missing write access."];
  }
  
  [self _deleteCompanyInfo];
  [self _deleteRelations:[self relations] inContext:_context];
  
  LSRunCommandV(_context, @"object", @"remove-logs",
                          @"object", [self object], nil);
  
  [super _executeInContext:_context];
}

@end /* LSDeleteCompanyCommand */
