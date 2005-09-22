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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  LSCyclicAppointmentsCommand (appointment::new-cyclic)
  
  TODO: document
  
  Note: this command does NOT preserve cyclic appointments or exceptions, when
        applied, it deletes all old cycles prior applying the new ones!
     => not sure whether this is necessary. At least the OGo apt-editor does
        not allow editing of the recurrence pattern anyway? (so we could just
        update the value-fields of the apts)
     => we probably do want to adjust for changes in the 'time' of the start/
        enddate but not in the date (which would be similiar to a pattern
        change).
     => maybe we can detect local changes based on the object-version (in case
        it differs from the master?)
  
  Arguments:
    cyclicAppointment - EO object - base appointment
    isWarningIgnored  - BOOL
    participants      - array of dicts/EOs (for appointment::set-participants)
    comment           - string
  
  Used by:
    appointment::new
    appointment::set (with 'setAllCyclic' YES)
*/

@class NSString, NSArray;

@interface LSCyclicAppointmentsCommand : LSDBObjectBaseCommand
{
@private
  BOOL     isWarningIgnored;
  NSArray  *participants;
  NSString *comment;
}

@end

#include "common.h"
#include "OGoCycleDateCalculator.h"

@implementation LSCyclicAppointmentsCommand

static int maxCycleCount = 100;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  maxCycleCount = [[ud objectForKey:@"LSMaxAptCycles"] intValue];
  if (maxCycleCount < 1) maxCycleCount = 100;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->isWarningIgnored = NO;
  }
  return self;
}

- (void)dealloc {
  [self->comment      release];
  [self->participants release];
  [super dealloc];
}

/* command methods */

- (BOOL)_appointmentIsCyclic {
  return [[[self object] valueForKey:@"type"] isNotNull];
}
- (BOOL)_appointmentHasCycleEnd {
  return [[[self object] valueForKey:@"cycleEndDate"] isNotNull];
}

- (void)_newCyclicAppointmentInContext:(id)_context
  start:(NSCalendarDate *)_startDate
  end:(NSCalendarDate *)_endDate
{
  id master;
  NSNumber *pkey;

  master = [self object];
  pkey   = [master valueForKey:@"dateId"];

  LSRunCommandV(_context, @"appointment", @"new",
                @"ownerId",           [master valueForKey:@"ownerId"],
                @"parentDateId",      pkey,
                @"startDate",         _startDate,
                @"endDate",           _endDate,
                @"cycleEndDate",      [master valueForKey:@"cycleEndDate"],
                @"accessTeamId",      [master valueForKey:@"accessTeamId"],
                @"type",              [master valueForKey:@"type"],
                @"location",          [master valueForKey:@"location"],
                @"title",             [master valueForKey:@"title"],
                @"aptType",           [master valueForKey:@"aptType"],
                @"absence",           [master valueForKey:@"absence"],
                @"resourceNames",     [master valueForKey:@"resourceNames"],
                @"writeAccessList",   [master valueForKey:@"writeAccessList"],
                @"isAbsence",         [master valueForKey:@"isAbsence"],
                @"isAttendance",      [master valueForKey:@"isAttendance"],
                @"isConflictDisabled",[master valueForKey:@"isConflictDisabled"],
                @"notificationTime",  [master valueForKey:@"notificationTime"],
                @"participants",      self->participants,
                @"isWarningIgnored",
                [NSNumber numberWithBool:self->isWarningIgnored],
                @"comment",           self->comment,
                nil);
}

- (void)_deleteOldCyclicAppointmentsInContext:(id)_context {
  int     i, cnt;
  NSArray *cyclics;

  cyclics = [self object]
    ? [_context runCommand:@"appointment::get-cyclic",
                  @"object", [self object], nil]
    : nil;
  
  for (i = 0, cnt = [cyclics count]; i < cnt; i++) {
    id appointment = [cyclics objectAtIndex:i];

#if DEBUG
    NSAssert1(appointment, @"missing apt from array %@", cyclics);
#endif

    [_context runCommand:@"appointment::delete",
                @"object", appointment,
                @"reallyDelete", [NSNumber numberWithBool:YES],
                nil];
  }
}

- (int)_computeDayForItem:(int)_i {
  NSCalendarDate *startDate;
  NSCalendarDate *testDate;
  
  startDate = [[self object] valueForKey:@"startDate"];
  testDate  = [startDate dateByAddingYears:0 months:0
                         days:_i*1 hours:0 minutes:0 seconds:0];
  
  return [testDate dayOfWeek];
}

- (void)_newCyclicAppointmentsInContext:(id)_context {
  unsigned       i, cnt;
  id             cyclic;
  NSString       *type;
  NSCalendarDate *realStart, *realEnd, *cycleDate;
  NSArray        *cycles;
  
  cyclic    = [self object];
  type      = [cyclic valueForKey:@"type"];
  realStart = [cyclic valueForKey:@"startDate"];
  realEnd   = [cyclic valueForKey:@"endDate"];
  cycleDate = [[cyclic valueForKey:@"cycleEndDate"] endOfDay];
  
  /* 
     Note: this skips the first instance for OGo types, but the iCal calculator
           returns all instances!
  */
  cycles =
    [OGoCycleDateCalculator cycleDatesForStartDate:realStart
                            endDate:realEnd
                            type:type
                            maxCycles:maxCycleCount
                            startAt:1
                            endDate:cycleDate
                            keepTime:YES];
  
  /*
     Note: this is tricky. iCal recurrence rules _include_ the first instance
           of the recurrence. So we need to skip that.
           We _also_ must patch the master event since the first rrule instance
           does not necessarily match the startdate/enddate given!
  */
  cnt = [cycles count];
  for (i = [type hasPrefix:@"RRULE:"] ? 1 : 0; i < cnt; i++) {
    id cycle; /* either an NSDictionary or an NGCalendarDateRange */
    
    cycle = [cycles objectAtIndex:i];
    [self _newCyclicAppointmentInContext:_context
          start:[cycle valueForKey:@"startDate"]
          end:[cycle valueForKey:@"endDate"]];
  }
}

- (void)_validateKeysInContext:(id)_context {
  [self assert:[self _appointmentIsCyclic]
        reason:@"Appointment was not set cyclic!"];
}

- (id)_getAppointmentEOForId:(NSNumber *)pId inContext:(id)_context {
  id firstCyclic;
  
  firstCyclic = LSRunCommandV(_context, @"appointment", @"get",
                              @"dateId", pId, nil);
  if ([firstCyclic count] == 0) {
    [self warnWithFormat:@"did not find given id: %@", pId];
    return nil;
  }
  if ([firstCyclic count] > 1) {
    [self errorWithFormat:@"found more than one object for pkey: %@", pId];
    return nil;
  }
  return [firstCyclic objectAtIndex:0];
}

- (void)_processObjectWithParentId:(NSNumber *)pId inContext:(id)_context {
  // TODO: document what this method does!
  // Note: this method patches the 'object'
  NSTimeZone     *tz;
  NSCalendarDate *sD, *eD, *fSD = nil, *fED = nil;
  id firstCyclic;
  id obj;

  if (![pId isNotNull])
    return;
  
  obj = [self object];
  sD  = [obj valueForKey:@"startDate"];
  eD  = [obj valueForKey:@"endDate"];
  tz  = [sD timeZoneDetail];
  
  firstCyclic = [self _getAppointmentEOForId:pId inContext:_context];
  fSD = [firstCyclic valueForKey:@"startDate"];
  fED = [firstCyclic valueForKey:@"endDate"];
  [fSD setTimeZone:tz];
  [fED setTimeZone:tz];
  
  fSD = [fSD hour:[sD hourOfDay] minute:[sD minuteOfHour]];
  fED = [fED hour:[eD hourOfDay] minute:[eD minuteOfHour]];
  
  // TODO: this one is interesting, what does it do?
  [_context runCommand:@"appointment::set",
                @"object", firstCyclic,
        @"ownerId"         ,   [firstCyclic valueForKey:@"ownerId"],
        @"accessTeamId"    ,   [obj valueForKey:@"accessTeamId"],
        @"type"            ,   [firstCyclic valueForKey:@"type"],            
        @"startDate"       ,   fSD,
        @"endDate"         ,   fED,
        @"cycleEndDate"    ,   [firstCyclic valueForKey:@"cycleEndDate"],
        @"isWarningIgnored",   [NSNumber numberWithBool:self->isWarningIgnored],
        @"location"        ,   [obj valueForKey:@"location"],
        @"title"           ,   [obj valueForKey:@"title"],
        @"aptType"         ,   [obj valueForKey:@"aptType"],
        @"absence"         ,   [obj valueForKey:@"absence"],
        @"isAbsence",          [obj valueForKey:@"isAbsence"],
        @"isAttendance",       [obj valueForKey:@"isAttendance"],
        @"isConflictDisabled", [obj valueForKey:@"isConflictDisabled"],
        @"resourceNames"   ,   [obj valueForKey:@"resourceNames"],
        @"writeAccessList" ,   [obj valueForKey:@"writeAccessList"],
        @"notificationTime",   [obj valueForKey:@"notificationTime"],
        @"participants"    ,   self->participants,
        @"comment"         ,   self->comment,   
        nil];
  
  [self setObject:firstCyclic];
}

- (void)_executeInContext:(id)_context {
  NSNumber *pId;
  
  /* if the given object is not the first apt in the sequence, do "something"*/
  if ([(pId = [[self object] valueForKey:@"parentDateId"]) isNotNull])
    /* this patches the 'object' of the command */
    [self _processObjectWithParentId:pId inContext:_context];
  
  [self assert:[self _appointmentHasCycleEnd]
        reason:@"Appointment has no cycle end date!"];

  [self _deleteOldCyclicAppointmentsInContext:_context];
  [self _newCyclicAppointmentsInContext:_context];
}

/* initialize records */

- (NSString *)entityName {
  return @"Date";
}

/* accessors */

- (void)setCyclicAppointment:(id)_cyclicAppointment {
  [self setObject:_cyclicAppointment];
}
- (id)cyclicAppointment {
  return [self object];
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;
}

- (void)setParticipants:(NSArray *)_participants {
  ASSIGN(self->participants, _participants);
}
- (NSArray *)participants {
  return self->participants;
}

- (void)setIsWarningIgnored:(BOOL)_isWarningIgnored {
  self->isWarningIgnored = _isWarningIgnored;
}
- (BOOL)isWarningIgnored {
  return self->isWarningIgnored;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString  *)_key {
  if ([_key isEqualToString:@"cyclicAppointment"])
    [self setCyclicAppointment:_value];
  else  if ([_key isEqualToString:@"participants"])
    [self setParticipants:_value];
  else  if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else if ([_key isEqualToString:@"isWarningIgnored"])
    [self setIsWarningIgnored:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"cyclicAppointment"])
    return [self cyclicAppointment];
  if ([_key isEqualToString:@"participants"])
    return [self participants];
  if ([_key isEqualToString:@"comment"])
    return [self comment];
  if ([_key isEqualToString:@"isWarningIgnored"])
    return [NSNumber numberWithBool:self->isWarningIgnored];
  return [super valueForKey:_key];
}

@end /* LSCyclicAppointmentsCommand */
