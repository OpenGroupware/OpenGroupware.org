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

/*
  LSDateAssignmentCommand / appointment::set-participants
  
  TODO: document

  The objects in the 'participants' array do not need to be full EO objects,
  they just need to have a 'companyId' attribute AND 'isAccount' or 'isTeam'
  if the record is one of those.
  It may have 'role', 'rsvp', 'partStatus', and 'comment' keys.
  
  Arguments:
    date | appointment | object
    participants | participantList
    logText
    logAction

  Called by:
    appointment::new
    appointment::set
    ...

  NOTE: yes, the key is 'partStatus' despite the DB column 'partstatus'.
*/

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
  NSString *role, *status, *comment;
  NSNumber *rsvp;

  // unused: pkey  = [_object valueForKey:@"companyId"];
  role  = [_object valueForKey:@"role"];
  rsvp  = [_object valueForKey:@"rsvp"];
  status = [_object valueForKey:@"partStatus"];
  comment = [_object valueForKey:@"comment"];
  
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
  if ([status isNotNull]) {
    if (![role isEqual:[_oldEntry valueForKey:@"partStatus"]])
      // no equal partStatus
      return YES; 
  }
  if ([comment isNotNull]) {
    if (![comment isEqual:[_oldEntry valueForKey:@"comment"]])
      // no equal comment 
      return YES;
  }

  // if id is equal
  // attributes are null or equal      
  return NO; // entry didn't change
}

- (id)_findOldEntry:(NSArray *)_oldEntries forCompanyId:(NSNumber *)pkey {
  /* Returns the 'old' DateCompanyAssignment EO object */
  unsigned int max, i;
  
  for (i = 0, max = [_oldEntries count]; i < max; i++) {
    NSNumber *opkey;
    id listObject = [_oldEntries objectAtIndex:i];
    
    opkey = [listObject valueForKey:@"companyId"];
    if (pkey == opkey || [pkey isEqual:opkey])
      return listObject;
  }
  
  return nil;
}

- (void)_removeOldAssignments:(NSArray *)_oldAssignments
  inContext:(id)_context
{
  // TODO: use raw SQL instead?
  //   DELETE FROM date_company_assignment WHERE company_id IN (a,b,c)
  //   => might need to notify the EO objects of change?
  NSEnumerator *listEnum;
  id           assignment;
  
  listEnum = [_oldAssignments objectEnumerator];
  while ((assignment = [listEnum nextObject]) != nil) {
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
  NSNumber     *aptPKey;

  aptPKey = [[self object] valueForKey:@"dateId"];
  
  listEnum = [_assignments objectEnumerator];
  while ((newParticipant = [listEnum nextObject]) != nil) {
    BOOL isStaff;
    
    isStaff = ([[newParticipant valueForKey:@"isAccount"] boolValue] ||
               [[newParticipant valueForKey:@"isTeam"] boolValue]);
    
    if (!isStaff) {
      if ([newParticipant valueForKey:@"isAccount"] == nil &&
          [newParticipant valueForKey:@"isTeam"]) {
        [self warnWithFormat:
                @"non-staff participant (probably missing type marker!): %@",
                newParticipant];
      }
    }
    
    LSRunCommandV(_context, @"DateCompanyAssignment", @"new",
                  @"dateId",     aptPKey,
                  @"companyId",  [newParticipant valueForKey:@"companyId"],
                  @"isStaff",    [NSNumber numberWithBool:isStaff],
                  @"partStatus", [newParticipant valueForKey:@"partStatus"],
                  @"role",       [newParticipant valueForKey:@"role"],
                  @"rsvp",       [newParticipant valueForKey:@"rsvp"],
                  @"comment",    [newParticipant valueForKey:@"comment"],
                  nil);
  }
  [self setReturnValue:[self object]];
}

- (void)_updateAssignments:(NSArray *)_assignments
  inContext:(id)_context
{
  NSEnumerator *listEnum;
  id           updatedParticipant;
  NSNumber     *aptPKey;

  aptPKey = [[self object] valueForKey:@"dateId"];

  listEnum = [_assignments objectEnumerator];
  while ((updatedParticipant = [listEnum nextObject]) != nil) {
    BOOL isStaff;

    isStaff = ([[updatedParticipant valueForKey:@"isAccount"] boolValue] ||
               [[updatedParticipant valueForKey:@"isTeam"] boolValue]);

    if (!isStaff) {
      if ([updatedParticipant valueForKey:@"isAccount"] == nil &&
          [updatedParticipant valueForKey:@"isTeam"]) {
        [self warnWithFormat:
                @"non-staff participant (probably missing type marker!): %@",
                updatedParticipant];
      }
    }

    LSRunCommandV(_context, @"DateCompanyAssignment", @"set",
                  @"dateCompanyAssignmentId", 
                      [updatedParticipant valueForKey:@"dateCompanyAssignmentId"],
                  @"dateId",     aptPKey,
                  @"companyId",  [updatedParticipant valueForKey:@"companyId"],
                  @"isStaff",    [NSNumber numberWithBool:isStaff],
                  @"partStatus", [updatedParticipant valueForKey:@"partStatus"],
                  @"role",       [updatedParticipant valueForKey:@"role"],
                  @"rsvp",       [updatedParticipant valueForKey:@"rsvp"],
                  @"comment",    [updatedParticipant valueForKey:@"comment"],
                  nil);
  }
  [self setReturnValue:[self object]];
}

- (void)syncOldList:(NSArray *)_oldList
  withNewList:(NSArray *)_newList
  toRemove:(NSMutableArray *)_toRemove
  toAdd:(NSMutableArray *)_toAdd
  toUpdate:(NSMutableArray *)_toUpdate
{
  NSMutableArray *oldList, *addedIds;
  unsigned int newListCount, i;
  
  newListCount = [_newList count];
  oldList      = [[_oldList mutableCopy] autorelease];
  addedIds     = [NSMutableArray arrayWithCapacity:(newListCount + 1)];
  
  /* check every new entry */
  for (i = 0; i < newListCount; i++) {
    NSNumber *cId;
    id newEntry, oldEntry;
 
    if ([[_newList objectAtIndex:i] isKindOfClass:[NSDictionary class]]) {
      /* Take a mutable copy of the participant dictionary so we can add
         the comment/role/status etc... from the existing participant
         entry if it was not provided */
      newEntry = [[[_newList objectAtIndex:i] mutableCopy] autorelease];
    } else {
        /* Participant provided as an LSPerson object,  in this case
           we know it won't have comment/role/status etc... so we
           make a mutable dictionary grabbing the companyId out of the
           LSPerson object */
        newEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [[_newList objectAtIndex:i] objectForKey:@"companyId"],
                      @"companyId",
	      nil];
       }
  
    oldEntry = [self _findOldEntry:oldList 
                     forCompanyId:[newEntry valueForKey:@"companyId"]];
    cId      = [newEntry valueForKey:@"companyId"];
    
    if ([addedIds containsObject:cId]) {
      /* no double add */
      [self warnWithFormat:@"attempt to add a participant twice: %@", cId];
      continue;
    }
    
    if (oldEntry == nil) {
      /* no old entry -> completely new entry */
      [_toAdd addObject:newEntry];
      [addedIds addObject:cId];
      continue;
    }
    
    if ([self _newEntry:newEntry changedSinceEntry:oldEntry]) {
      /* This entry already exists but has changed -> update 
         The only required fields/values for an update are:
           dateCompanyAssignmentId, dateId, & companyId */
      [newEntry setObject:[oldEntry valueForKey:@"dateCompanyAssignmentId"]
                   forKey:@"dateCompanyAssignmentId"];

      /* if new entry does not provide status, get from old entry */
      if (([newEntry valueForKey:@"partStatus"] == nil) &&
          ([[oldEntry valueForKey:@"partStatus"] isNotNull]))
        [newEntry setObject:[oldEntry valueForKey:@"partStatus"]
                     forKey:@"partStatus"];

      /* if new entry does not provide rsvp, get from old entry */
      if (([newEntry valueForKey:@"rsvp"] == nil) &&
          ([[oldEntry valueForKey:@"rsvp"] isNotNull]))
        [newEntry setObject:[oldEntry valueForKey:@"rsvp"]
                     forKey:@"rsvp"];

      /* if new entry does not provide comment, get from old entry */
      if (([newEntry valueForKey:@"comment"] == nil) &&
          ([[oldEntry valueForKey:@"comment"] isNotNull]))
        [newEntry setObject:[oldEntry valueForKey:@"comment"]
                     forKey:@"comment"];

      /* if new entry does not provide role, get from old entry */
      if (([newEntry valueForKey:@"role"] == nil) &&
          ([[oldEntry valueForKey:@"role"]  isNotNull]))
        [newEntry setObject:[oldEntry valueForKey:@"role"]
                     forKey:@"role"];

      [_toUpdate   addObject:newEntry];
      
      [oldList removeObject:oldEntry];
      [addedIds addObject:cId];
      continue;
    }
    
    /* no changes */
    [oldList removeObject:oldEntry]; /* keep it */
  } /* end for-loop newlist */
 
  /* copy all remaining objects from previous participant list
     to list of participants to remove,  these participants
     were not found in the new participant list -> delete */ 
  if ([oldList isNotEmpty])
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

  validatedList = [[NSMutableArray alloc] initWithCapacity:8];
  
  listEnum = [self->participantList objectEnumerator];
  while ((obj = [listEnum nextObject]) != nil) {
    if ([obj respondsToSelector:@selector(entity)]) {
      NSString *ename;

      ename = [[obj entity] name];
    
      if (([ename isEqual:@"Person"] || [ename isEqual:@"Team"]))
        [validatedList addObject:obj];
      else {
        [self errorWithFormat:
                @"got participant object with unknown entity %@: %@",
                ename, obj];
      }
    }
    else { /* is not an EO object (eg a dictionary) */
      if ([[obj valueForKey:@"companyId"] isNotNull])
        [validatedList addObject:obj];
      else
        [self errorWithFormat:@"participant has no company-id: %@", obj];
    }
  }
  
  [self->participantList release];
  self->participantList = validatedList; // validatedList is retained
}

- (BOOL)isRootPKey:(NSNumber *)_pkey inContext:(id)_ctx {
  return [_pkey unsignedIntValue] == 10000 ? YES : NO;
}

- (void)_checkOwnerInContext:(id)_context {
  id       ac, acId;

  // checks owner of appointment
  ac    = [_context valueForKey:LSAccountKey];
  // unused: login = [ac valueForKey:@"login"];
  acId  = [ac valueForKey:@"companyId"];
  
  if (![self isRootPKey:acId inContext:_context]) {
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
                       @"comment",  
                       nil];
  }
  return keys;
}

- (NSArray *)_fetchOldParticipants:(id)_context {
#if 0 // TODO: why not use this?
  return LSRunCommandV(_context, @"appointment", @"list-participants",
                         @"appointment", [self object],
                         @"attributes",  [self _neededParticipantKeys],
                         nil);
#else
  return
    LSRunCommandV(_context,
                  @"datecompanyassignment", @"get",
                  @"dateId",     [[self object] valueForKey:@"dateId"],
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil);
#endif
}

- (void)_prepareForExecutionInContext:(id)_context {
}

- (void)_executeInContext:(id)_context {
  NSArray        *oldList, *newList;
  NSMutableArray *toRemove, *toAdd, *toUpdate;

  //oldList = [[self object] valueForKey:@"toDateCompanyAssignment"];
  oldList = [self _fetchOldParticipants:_context];
  newList = self->participantList;
  
  toRemove = [NSMutableArray arrayWithCapacity:4];
  toAdd    = [NSMutableArray arrayWithCapacity:4];
  toUpdate = [NSMutableArray arrayWithCapacity:4];
  
  [self syncOldList:oldList withNewList:newList
        toRemove:toRemove 
        toAdd:toAdd
        toUpdate:toUpdate];
  
  if ([toRemove isNotEmpty])
    [self _removeOldAssignments:toRemove inContext:_context];
  if ([toAdd isNotEmpty])
    [self _addAssignments:toAdd inContext:_context];
  if ([toUpdate isNotEmpty])
    [self _updateAssignments:toUpdate inContext:_context];
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

  if ([_key isEqualToString:@"participantList"] ||
      [_key isEqualToString:@"participants"]) {
    [self setParticipantList:_value];
    return;
  }

  if ([_key isEqualToString:@"logText"] ||
      [_key isEqualToString:@"logAction"]) {
    [super takeValue:_value forKey:_key];
    return;
  }
  
  [self errorWithFormat:@"got invalid KVC key: '%@'", _key];
  [super takeValue:_value forKey:_key];
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
