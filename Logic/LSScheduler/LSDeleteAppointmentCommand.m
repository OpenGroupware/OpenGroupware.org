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

#import "common.h"
#include <LSFoundation/LSDBObjectDeleteCommand.h>

@interface LSDeleteAppointmentCommand : LSDBObjectDeleteCommand
{
@protected
  BOOL deleteAllCyclic;
  BOOL checkPermissions;
}

@end

@implementation LSDeleteAppointmentCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
{
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->deleteAllCyclic  = NO;
    self->checkPermissions = YES;
  }
  return self;
}

- (NSArray *)relations {
  NSArray        *myRelations;
  NSEnumerator   *enumerator;
  NSMutableArray *relevantRelations;
  EORelationship *rs;

  myRelations       = [[self entity] relationships];
  enumerator        = [myRelations objectEnumerator];
  relevantRelations = [NSMutableArray arrayWithCapacity:4];
  rs                = nil;
  
  while ((rs = [enumerator nextObject]) != nil) {
    if (![[rs name] isEqualToString:@"toDateInfo"] &&
        ![[rs name] isEqualToString:@"toDate"]) {
      [relevantRelations addObject:rs];
    }
  }
  return relevantRelations;
}

/* command methods */

- (void)_deleteDateInfo:(id)_ctx {
  BOOL isOk     = YES; 
  id   dateInfo = nil;

  LSRunCommandV(_ctx, @"appointment", @"get-comment",
                @"object", [self object],
                @"relationKey", @"dateInfo", nil);
  dateInfo = [[self object] valueForKey:@"dateInfo"];
  if ([dateInfo isKindOfClass:[NSArray class]])
    dateInfo = [dateInfo lastObject];
  
  if (dateInfo) {
    if ([self reallyDelete])
      isOk = [[self databaseChannel] deleteObject:dateInfo];
    else {
      [dateInfo takeValue:@"archived" forKey:@"dbStatus"];
      isOk = [[self databaseChannel] updateObject:dateInfo];
    }
  }
  [self assert:isOk reason:[dbMessages description]];
}

- (void)_separateNotesInContext:(id)_context {
  id  notes;
  int i, cnt;

  notes  = [[self object] valueForKey:@"toNote"];

  for (i = 0, cnt = [notes count]; i < cnt; i++) {
    /*
      detach if project or company is assigned
      delete if nothing assigned
      access to delete notes should be granted since the notes are assigend
      to the appointment
    */
    id note = [notes objectAtIndex:i];
    
    if (([[note valueForKey:@"projectId"] isNotNull]) ||
        ([[note valueForKey:@"companyId"] isNotNull])) {
      // project or company still assigned
      LSRunCommandV(_context, @"note", @"set",
                              @"object", note,
                              @"dateId", [EONull null],
                              @"dontCheckAccess", [NSNumber numberWithBool:YES],
                              nil);
    } else {
      LSRunCommandV(_context, @"note", @"delete",
                    @"object", note, nil);
    }
  }
  
  if ([notes respondsToSelector:@selector(clear)])
    [notes clear];
}

- (BOOL)checkDeletePermissionInContext:(id)_context {
  NSString   *permissions;
  EOGlobalID *gid;
  id         obj;
  
  obj = [self object];
  gid = [obj valueForKey:@"globalID"];
  [self assert:(gid != nil)
        format:@"got no global-id for appointment object: %@", obj];
  
  permissions = LSRunCommandV(_context, @"appointment", @"access",
                                        @"gid", gid, 
                                        nil);
  return ([permissions rangeOfString:@"d"].length > 0) ? YES : NO;
}

- (NSException *)_removeObjectLogsInContext:(id)_context {
  id obj;

  obj = [self object];
  [self assert:(obj != nil) reason:@"no object available"];

  if ([self isDeleteLogsEnabled])
    LSRunCommandV(_context, @"object", @"remove-logs", 
                            @"object", obj, 
                            nil);

  if ([self isTombstoneEnabled])
    LSRunCommandV(_context, @"object", @"add-log",
                            @"logText"    , @"Appointment deleted",
                            @"action"     , @"99_delete",
                            @"objectToLog", obj,
                            nil);
  return nil;
}

- (NSArray *)_getCyclicForAppointment:(id)_apt inContext:(id)_context {
  return LSRunCommandV(_context, @"appointment", @"get-cyclic",
                                 @"object", _apt, 
                                 nil);      
}

- (NSArray *)_getCyclicInContext:(id)_context {
  id obj;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no object available"];
  
  return [self _getCyclicForAppointment:obj inContext:_context];
}

- (NSException *)_deleteAppointment:(id)_apt physically:(BOOL)_physically
                          inContext:(id)_context
{
  /* this runs this command again, but always with no cyclic
     deletions. So in the recursive runs the deleteAllCyclic value
     will be false. */
  if (!_physically) {
    LSRunCommandV(_context, @"appointment", @"delete",
                  @"object", _apt, nil);
  }
  else {
    LSRunCommandV(_context, @"appointment", @"delete",
                  @"object", _apt,
                  @"reallyDelete", [NSNumber numberWithBool:YES],
                  nil);
  }
  return nil;
}

- (NSException *)_deleteNoCyclicInContext:(id)_context {
  NSArray *cyclics = nil;
  id  firstCyclic = nil;
  id  obj;
  int i, cnt;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no object available"];

  cyclics = [self _getCyclicInContext:_context];
  if ([cyclics count] == 0)
    return nil;
  
  firstCyclic = [cyclics objectAtIndex:0];

  /* this sets the parentDataId of the first appointment in the cycle to 
     NULL and maintains all the other values. */    
  LSRunCommandV(_context, @"appointment", @"set",
                    @"object", firstCyclic,
                    @"parentDateId", [EONull null],
                    @"type"        , [obj valueForKey:@"type"],
                    @"cycleEndDate", [obj valueForKey:@"cycleEndDate"],
                    @"ownerId"     , [firstCyclic valueForKey:@"ownerId"],
                    @"accessTeamId", [firstCyclic valueForKey:@"accessTeamId"],
                    @"startDate"   , [firstCyclic valueForKey:@"startDate"],
                    @"endDate"     , [firstCyclic valueForKey:@"endDate"],
                    @"location"    , [firstCyclic valueForKey:@"location"],
                    @"title"       , [firstCyclic valueForKey:@"title"],
                    @"absence"     , [firstCyclic valueForKey:@"absence"],
                    @"isAbsence",    [firstCyclic valueForKey:@"isAbsence"],
                    @"isAttendance", [firstCyclic valueForKey:@"isAttendance"],
                    @"resourceNames", [firstCyclic valueForKey:@"resourceNames"],
                    @"isWarningIgnored", [NSNumber numberWithBool:YES],
                    nil);
  /* loop through all the remaining appointments in the cycle setting the
     parentDateId to the id of the first appointment in the cycle */
  for (i = 1, cnt = [cyclics count]; i < cnt; i++) {
    id apmt;
        
    apmt = [cyclics objectAtIndex:i];
    /* 
       TODO: this is expensive, use a mutable dictionary for the params
             and clear/refill instead of doing the vargs parsing over and 
             over again.
    */
    LSRunCommandV(_context, @"appointment", @"set",
                      @"object", apmt,
                      @"parentDateId", [firstCyclic valueForKey:@"dateId"],
                      @"ownerId"     , [apmt valueForKey:@"ownerId"],            
                      @"accessTeamId", [apmt valueForKey:@"accessTeamId"],
                      @"startDate"   , [apmt valueForKey:@"startDate"],
                      @"endDate"     , [apmt valueForKey:@"endDate"],
                      @"location"    , [apmt valueForKey:@"location"],
                      @"title"       , [apmt valueForKey:@"title"],
                      @"absence"     , [apmt valueForKey:@"absence"],
                      @"isAbsence",        [apmt valueForKey:@"isAbsence"],
                      @"isAttendance",     [apmt valueForKey:@"isAttendance"],
                      @"resourceNames"   , [apmt valueForKey:@"resourceNames"],
                      @"isWarningIgnored", [NSNumber numberWithBool:YES],
                      nil);
  }
  return nil;
}

- (NSException *)_deleteCyclicInContext:(id)_context {
  //EODatabaseContext *dbCtx;
  NSArray  *cyclics = nil;
  NSNumber *pId     = nil;
  id        firstCyclic = nil;
  id        obj;
  int       i, cnt;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no object available"];

  pId   = [obj valueForKey:@"parentDateId"];
  //dbCtx = [_context valueForKey:LSDatabaseContextKey];
  
  if (pId == nil) {
    /* the appointment passed to this command had a nil parentDateId meaning
       that it must be the "root" appointment? */
    cyclics = [self _getCyclicInContext:_context];
  } else {
      /* the appointment passed to this command is NOT the root appointment
         in the cyclic chain, so we need to load the parent date */
      NSMutableArray *c;
    
      c = [NSMutableArray array];
      firstCyclic = LSRunCommandV(_context, @"appointment", @"get",
                                            @"dateId", pId, 
                                            nil);
      
      if ([firstCyclic count] == 1) 
        firstCyclic = [firstCyclic objectAtIndex:0];
  
      /* load all the appointments rooted with the parent appointment */  
      cyclics = [self _getCyclicForAppointment:firstCyclic inContext:_context];
      [c addObjectsFromArray:cyclics];
      /* remove current object, it is deleted by the super */
      [c removeObject:[self object]];
      cyclics = c;
    }

  for (i = 0, cnt = [cyclics count]; i < cnt; i++) {
    id appointment;
    
    appointment = [cyclics objectAtIndex:i];
    [self _deleteAppointment:appointment physically:YES inContext:_context];
  }
  [self _removeObjectLogsInContext:_context];
  
  /* 
     TODO: hh asks: why is that?? 
     
     Shouldn't the caller (execute) commit the transaction? And why doesn't
     happen everything in a single transaction?
  [(EODatabaseContext *)dbCtx commitTransaction];
  [(EODatabaseContext *)dbCtx beginTransaction];
  */

  [super _executeInContext:_context];
    
  if (firstCyclic)
    [self _deleteAppointment:firstCyclic physically:YES inContext:_context];
  
  return nil;
}

- (void)_executeInContext:(id)_context {
  id       obj;
  NSNumber *pId        = nil;
  NSString *type       = nil;
  //EODatabaseContext *dbCtx;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no object available"];
  //dbCtx = [_context valueForKey:LSDatabaseContextKey];

  if (self->checkPermissions) {
    [self assert:[self checkDeletePermissionInContext:_context]
          format:@"denied permission to delete appointment '%@'",
            [obj valueForKey:@"title"]];
  }
  
  pId  = [obj valueForKey:@"parentDateId"];
  type = [obj valueForKey:@"type"];

  [[_context propertyManager] removeAllPropertiesForGlobalID:
				[obj valueForKey:@"globalID"]];
  
  [self _deleteDateInfo:_context];
  [self _separateNotesInContext:_context];
  [self _deleteRelations:[self relations] inContext:_context];

  /* delete properties */
  [[_context propertyManager] removeAllPropertiesForGlobalID:
		  [[self object] globalID]];
  /* delete links */
  [[_context linkManager] deleteLinksTo:(id)[[self object] globalID] 
                                   type:nil];
  [[_context linkManager] deleteLinksFrom:(id)[[self object] globalID] 
                                     type:nil];
  
  /* TODO: document the following section */

  if (self->deleteAllCyclic) {
    [[self _deleteCyclicInContext:_context] raise];
  } else {
      /* reset the parentDateId of all the appointments in the cycle as
         we are deleting an appointment from the cycle chain and thus
         run the risk that we are deleting the root appointment */
      [[self _deleteNoCyclicInContext:_context] raise];
      [[self _removeObjectLogsInContext:_context] raise];
      //[self assert:[dbCtx beginTransaction] reason:@"couldn't begin tx .."];
      [super _executeInContext:_context];
    }
}

/* entity name for DB-delete-command (superclass) */

- (NSString *)entityName {
  return @"Date";
}

/* accessors */

- (void)setDeleteAllCyclic:(BOOL)_flag {
  self->deleteAllCyclic = _flag;
}
- (BOOL)deleteAllCyclic {
  return self->deleteAllCyclic;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"deleteAllCyclic"])
    [self setDeleteAllCyclic:[_value boolValue]];
  if ([_key isEqualToString:@"checkPermissions"]) 
    self->checkPermissions = [_value boolValue];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"deleteAllCyclic"])
    return [NSNumber numberWithBool:[self deleteAllCyclic]];
  else if ([_key isEqualToString:@"checkPermissions"])
    return [NSNumber numberWithBool:self->checkPermissions];

  return [super valueForKey:_key];
}

@end /* LSDeleteAppointmentCommand */
