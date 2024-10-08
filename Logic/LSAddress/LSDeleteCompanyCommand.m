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
                              reason:[dbMessages description]];
  return YES;
}

- (void)_separateNotesInContext:(id)_context {
  id  notes;
  int i, cnt;

  notes  = [[self object] valueForKey:@"toNote"];

  for (i = 0, cnt = [notes count]; i < cnt; i++) {
    /*
      detach if date or project is assigned
      delete if nothing assigned
      access to delete notes should be granted since the notes are assigend
      to the appointment
    */
    id note = [notes objectAtIndex:i];

    if (([[note valueForKey:@"dateId"] isNotNull]) ||
        ([[note valueForKey:@"projectId"] isNotNull])) {
      // project or date still assigned
      LSRunCommandV(_context, @"note", @"set",
                              @"object", note,
                              @"companyId", [EONull null],
                              @"dontCheckAccess",
                                 [NSNumber numberWithBool:YES],
                              nil);
    } else {
        LSRunCommandV(_context, @"note", @"delete",
                                @"object", note,
                                nil);
      }
  }

  if ([notes respondsToSelector:@selector(clear)])
    [notes clear];
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

  /* detach or delete notes */
  [self _separateNotesInContext:_context];

  [self _deleteRelations:[self relations] inContext:_context];

  /* delete properties */
  [[_context propertyManager] removeAllPropertiesForGlobalID:
                  [[self object] globalID]];
  /* delete links */
  [[_context linkManager] deleteLinksTo:(id)[[self object] globalID] type:nil];
  [[_context linkManager] deleteLinksFrom:(id)[[self object] globalID] type:nil];

  if ([self isDeleteLogsEnabled])
    LSRunCommandV(_context, @"object", @"remove-logs",
                            @"object", [self object], nil);

  if ([self isTombstoneEnabled])
    LSRunCommandV(_context, @"object", @"add-log",
                            @"logText"    , @"Company deleted",
                            @"action"     , @"99_delete",
                            @"objectToLog", [self object],
                            nil);
  [self calculateCTagInContext:_context]; 
  [super _executeInContext:_context];
}

@end /* LSDeleteCompanyCommand */
