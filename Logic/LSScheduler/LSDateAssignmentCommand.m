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

#include <LSFoundation/LSDBObjectNewCommand.h>

@class NSArray;

@interface LSDateAssignmentCommand : LSDBObjectNewCommand
{
@private 
  NSArray *participantList;
}

- (void)setAppointment:(id)_appointment;
- (id)appointment;

- (void)setParticipantList:(NSArray *)_participantList;
- (NSArray *)participantList;

@end

#include "common.h"

@implementation LSDateAssignmentCommand

- (void)dealloc {
  [self->participantList release];
  [super dealloc];
}

// command methods

- (BOOL)_newEntry:(id)_object changedSinceEntry:(id)_oldEntry {
  id pkey, role, state, rsvp;

  pkey  = [_object valueForKey:@"companyId"];
  role  = [_object valueForKey:@"role"];
  rsvp  = [_object valueForKey:@"rsvp"];
  state = [_object valueForKey:@"partStatus"];
      
  // check these participant attributes only, if both not null
  if ([role isNotNull]) {
    if (![role isEqual:[_oldEntry valueForKey:@"role"]])
      // no equal role
      return YES; 
  }
  if ([rsvp isNotNull]) {
    if (![role isEqual:[_oldEntry valueForKey:@"rsvp"]])
      // no equal rsvp
      return YES; 
  }
  if ([state isNotNull]) {
    if (![role isEqual:[_oldEntry valueForKey:@"partStatus"]])
      // no equal partStatus
      return YES; 
  }

  // if id is equal
  // attributes are null or equal      
  return NO; // entry didn't change
}

- (id)_findOldEntry:(NSArray *)_oldEntries forNewEntry:(id)_newOne {
  unsigned int max, i;
  id           listObject, pkey, opkey;

  max  = [_oldEntries count];
  pkey = [_newOne valueForKey:@"companyId"];
  
  for (i = 0; i < max; i++) {
    listObject = [_oldEntries objectAtIndex:i];

    opkey = [listObject valueForKey:@"companyId"];
    if ([pkey isEqual:opkey])
      return listObject;
  }

  return nil;
}

- (void)_removeOldAssignments:(NSArray *)_oldAssignments
  inContext:(id)_context
{
  NSEnumerator *listEnum;
  id           assignment;

  listEnum       = [_oldAssignments objectEnumerator];
  
  while ((assignment = [listEnum nextObject])) {
    LSDBObjectDeleteCommand *dCmd;

    dCmd = LSLookupCommandV(@"DateCompanyAssignment", @"delete",
                            @"object", assignment, nil);
    [dCmd setReallyDelete:YES];
    [dCmd runInContext:_context];
  }
}

- (void)_addAssignments:(NSArray *)_assignments
  inContext:(id)_context
{
  NSEnumerator *listEnum;
  id           newParticipant;

  listEnum       = [_assignments objectEnumerator];
  
  while ((newParticipant = [listEnum nextObject])) {
    BOOL isStaff;

    isStaff = ([[newParticipant valueForKey:@"isAccount"] boolValue] ||
               [[newParticipant valueForKey:@"isTeam"] boolValue]);
    
    LSRunCommandV(_context, @"DateCompanyAssignment", @"new",
                  @"dateId",     [[self object] valueForKey:@"dateId"],
                  @"companyId",  [newParticipant valueForKey:@"companyId"],
                  @"isStaff",    [NSNumber numberWithBool:isStaff],
                  @"partStatus", [newParticipant valueForKey:@"partStatus"],
                  @"role",       [newParticipant valueForKey:@"role"],
                  @"rsvp",       [newParticipant valueForKey:@"rsvp"],
                  nil);
  }
  [self setReturnValue:[self object]];
}

- (void)syncOldList:(NSArray *)_oldList
  withNewList:(NSArray *)_newList
  toRemove:(NSMutableArray *)_toRemove
  toAdd:(NSMutableArray *)_toAdd
{
  unsigned int max, i;
  NSMutableArray *oldList, *addedIds;

  max      = [_newList count];
  oldList  = [[_oldList mutableCopy] autorelease];
  addedIds = [NSMutableArray arrayWithCapacity:max+1];

  // check every new entry
  for (i = 0; i < max; i++) {
    id newEntry, oldEntry, cId;

    newEntry = [_newList objectAtIndex:i];
    oldEntry = [self _findOldEntry:oldList forNewEntry:newEntry];
    cId      = [newEntry valueForKey:@"companyId"];

    if ([addedIds containsObject:cId]) {
      // no double add
      continue;
    }

    else if (oldEntry == nil) {
      // no old entry -> totaly new entry
      [_toAdd addObject:newEntry];
    }

    else if ([self _newEntry:newEntry changedSinceEntry:oldEntry]) {
      // new entry changed since old
      [_toAdd    addObject:newEntry];
      [_toRemove addObject:oldEntry];
      
      [oldList removeObject:oldEntry];
      [addedIds addObject:cId];
    }
    else { /* no changes */
      [oldList removeObject:oldEntry];
    }
  }

  if ([oldList count])
    [_toRemove addObjectsFromArray:oldList];
}

- (void)_validateDate {
  BOOL isOk;

  isOk = NO;

  if ([[self object] respondsToSelector:@selector(entity)])
    isOk = [[[[self object] entity] name] isEqual:@"Date"];

  [self assert:isOk
        format:@"key: date is not valid in domain '%@' for operation '%@'.",
               [self domain], [self operation]];
}

- (void)_validateParticipantList {
  NSMutableArray *validatedList;
  NSEnumerator   *listEnum;
  id             obj;

  validatedList = [[NSMutableArray alloc] init];
  listEnum      = [self->participantList objectEnumerator];

  while ((obj = [listEnum nextObject])) {
    NSString *ename;

    ename = nil;
    
    if ([obj respondsToSelector:@selector(entity)]) {
      ename = [[obj entity] name];
    
      if (([ename isEqual:@"Person"] || [ename isEqual:@"Team"]))
        [validatedList addObject:obj];
    }
    else
      [validatedList addObject:obj];
  }
  ASSIGN(self->participantList, nil);
  self->participantList = validatedList; // validatedList is retained
}

- (void)_checkOwnerInContext:(id)_context {
  id       ac, acId;
  NSString *login;

  // checks owner of appointment
  ac    = [_context valueForKey:LSAccountKey];
  login = [ac valueForKey:@"login"];
  acId  = [ac valueForKey:@"companyId"];

  if ([acId intValue] != 10000) {
    /* old version (problem: can't add active account to appointment
                             if acctive account is't owner)
    [self assert:[acId isEqual:[[self object] valueForKey:@"ownerId"]] 
          reason:@"tried to change appointment of other account"];
    */
    // only private appointments can't be changed
    if (![acId isEqual:[[self object] valueForKey:@"ownerId"]]) {
      [self assert:[[self object] valueForKey:@"accessTeamId"] != nil
            reason:@"tried to change private appointment"];
    }
  }
}

- (void)_validateKeysForContext:(id)_context {
  [self _validateDate];
  [self _validateParticipantList];
}

- (NSArray *)_neededParticipantKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys =
      [[NSArray alloc] initWithObjects:
                       @"companyId", @"partStatus",
                       @"role",      @"rsvp",
                       @"dateId",    @"isStaff",
                       nil];
  }
  return keys;
}

- (NSArray *)_fetchOldParticipants:(id)_context {
  //  return LSRunCommandV(_context, @"appointment", @"list-participants",
  //                       @"appointment", [self object],
  //                       @"attributes",  [self _neededParticipantKeys],
  //                       nil);
  return
    LSRunCommandV(_context,
                  @"datecompanyassignment", @"get",
                  @"dateId",     [[self object] valueForKey:@"dateId"],
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil);
}

- (void)_prepareForExecutionInContext:(id)_context {
}

- (void)_executeInContext:(id)_context {
  NSArray        *oldList, *newList;
  NSMutableArray *toRemove, *toAdd;

  //oldList = [[self object] valueForKey:@"toDateCompanyAssignment"];
  oldList = [self _fetchOldParticipants:_context];
  newList = self->participantList;

  toRemove = [NSMutableArray array];
  toAdd    = [NSMutableArray array];

  [self syncOldList:oldList withNewList:newList
        toRemove:toRemove toAdd:toAdd];

  if ([toRemove count])
    [self _removeOldAssignments:toRemove inContext:_context];
  if ([toAdd count])
    [self _addAssignments:toAdd inContext:_context];
}

/* initialize records */

- (NSString *)entityName {
  return @"DateCompanyAssignment";
}

/* accessors */

- (void)setDate:(id)_date {
  [self setAppointment:_date];
}
- (id)date {
  return [self appointment];
}

- (void)setAppointment:(id)_appointment {
  [self setObject:_appointment];
}
- (id)appointment {
  return [self object];
}

- (void)setParticipantList:(NSArray *)_participantList {
  ASSIGN(self->participantList, _participantList);
}
- (NSArray *)participantList {
  return self->participantList;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"date"] ||
      [_key isEqualToString:@"appointment"] ||
      [_key isEqualToString:@"object"]) {
    [self setObject:_value];
    return;
  }
  else if ([_key isEqualToString:@"participantList"] ||
           [_key isEqualToString:@"participants"]) {
    [self setParticipantList:_value];
    return;
  }
  else if ([_key isEqualToString:@"logText"] ||
           [_key isEqualToString:@"logAction"]) {
    [super takeValue:_value forKey:_key];
  }
  else {
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:
                                [NSString stringWithFormat:
                                          @"key: %@ is not valid in domain "
                                          @"'%@' for operation '%@'.",
                                          _key, [self domain],
                                          [self operation]]];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"date"] ||
      [_key isEqualToString:@"appointment"] ||
      [_key isEqualToString:@"object"])
    return [self object];
  
  if ([_key isEqualToString:@"participantList"] ||
      [_key isEqualToString:@"participants"])
    return [self participantList];

  return nil; /* rather call super? */
}

@end /* LSDateAssignmentCommand */
