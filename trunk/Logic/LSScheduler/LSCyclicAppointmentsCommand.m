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

@class NSString, NSArray;

@interface LSCyclicAppointmentsCommand : LSDBObjectBaseCommand
{
@private
  BOOL     isWarningIgnored;
  NSArray  *participants;
  NSString *comment;
}

@end

#import "common.h"
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
  id cyclic = [self object];
  id pkey   = [cyclic valueForKey:@"dateId"];
  LSRunCommandV(_context, @"appointment", @"new",
                @"ownerId",           [cyclic valueForKey:@"ownerId"],
                @"creatorId",         [cyclic valueForKey:@"creatorId"],
		@"parentDateId",      pkey,
                @"startDate",         _startDate,
                @"endDate",           _endDate,
                @"cycleEndDate",      [cyclic valueForKey:@"cycleEndDate"],
                @"accessTeamId",      [cyclic valueForKey:@"accessTeamId"],
                @"type",              [cyclic valueForKey:@"type"],
                @"location",          [cyclic valueForKey:@"location"],
                @"title",             [cyclic valueForKey:@"title"],
                @"aptType",           [cyclic valueForKey:@"aptType"],
                @"rdvType",           [cyclic valueForKey:@"rdvType"],
                @"absence",           [cyclic valueForKey:@"absence"],
                @"resourceNames",     [cyclic valueForKey:@"resourceNames"],
                @"writeAccessList",   [cyclic valueForKey:@"writeAccessList"],
                @"readAccessList",    [cyclic valueForKey:@"readAccessList"],
                @"isAbsence",         [cyclic valueForKey:@"isAbsence"],
                @"isAttendance",      [cyclic valueForKey:@"isAttendance"],
                @"isConflictDisabled",[cyclic valueForKey:@"isConflictDisabled"],
                @"notificationTime",  [cyclic valueForKey:@"notificationTime"],
                @"participants",      self->participants,
                @"isWarningIgnored", [NSNumber numberWithBool:self->isWarningIgnored],
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
  int            i          = 1;
  int            cnt        = 0;
  
  id             cyclic     = [self object];
  NSString       *type      = [cyclic valueForKey:@"type"];
  NSCalendarDate *realStart = [cyclic valueForKey:@"startDate"];
  NSCalendarDate *realEnd   = [cyclic valueForKey:@"endDate"];
  NSCalendarDate *cycleDate = [[cyclic valueForKey:@"cycleEndDate"] endOfDay];
  NSArray        *cycles;
  NSDictionary   *cycle;

  cycles =
    [OGoCycleDateCalculator cycleDatesForStartDate:realStart
                            endDate:realEnd
                            type:type
                            maxCycles:maxCycleCount
                            startAt:1
                            endDate:cycleDate
                            keepTime:YES];

  cnt = [cycles count];
  for (i = 0; i < cnt; i++) {
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

- (void)_executeInContext:(id)_context {
  id       obj  = [self object];
  NSNumber *pId = [obj valueForKey:@"parentDateId"];
  
  if ([pId isNotNull]) {
    id firstCyclic;
    
    firstCyclic = LSRunCommandV(_context, @"appointment", @"get",
                                @"dateId", pId, nil);

    if ([firstCyclic count] == 1) {
      NSCalendarDate *sD  = [obj valueForKey:@"startDate"];
      NSCalendarDate *eD  = [obj valueForKey:@"endDate"];
      NSCalendarDate *fSD = nil;
      NSCalendarDate *fED = nil;

      firstCyclic = [firstCyclic objectAtIndex:0];

      fSD = [firstCyclic valueForKey:@"startDate"];
      fED = [firstCyclic valueForKey:@"endDate"];
      [fSD setTimeZone:[sD timeZoneDetail]];
      [fED setTimeZone:[eD timeZoneDetail]];

      fSD = [fSD hour:[sD hourOfDay] minute:[sD minuteOfHour]];
      fED = [fED hour:[eD hourOfDay] minute:[eD minuteOfHour]];
      [_context runCommand:@"appointment::set",
        @"object", firstCyclic,
        @"ownerId"         ,   [firstCyclic valueForKey:@"ownerId"], 
	@"creatorId"	   ,   [firstCyclic valueForKey:@"creatorId"],           
        @"accessTeamId"    ,   [obj valueForKey:@"accessTeamId"],
        @"type"            ,   [firstCyclic valueForKey:@"type"],            
        @"startDate"       ,   fSD,
        @"endDate"         ,   fED,
        @"cycleEndDate"    ,   [firstCyclic valueForKey:@"cycleEndDate"],
        @"isWarningIgnored",   [NSNumber numberWithBool:self->isWarningIgnored],
        @"location"        ,   [obj valueForKey:@"location"],
        @"title"           ,   [obj valueForKey:@"title"],
        @"aptType"         ,   [obj valueForKey:@"aptType"],
        @"rdvType"         ,   [obj valueForKey:@"rdvType"],
        @"absence"         ,   [obj valueForKey:@"absence"],
        @"isAbsence",          [obj valueForKey:@"isAbsence"],
        @"isAttendance",       [obj valueForKey:@"isAttendance"],
        @"isConflictDisabled", [obj valueForKey:@"isConflictDisabled"],
        @"resourceNames"   ,   [obj valueForKey:@"resourceNames"],
        @"writeAccessList" ,   [obj valueForKey:@"writeAccessList"],
        @"readAccessList" ,    [obj valueForKey:@"readAccessList"],
        @"notificationTime",   [obj valueForKey:@"notificationTime"],
        @"participants"    ,   self->participants,
        @"comment"         ,   self->comment,   
        nil];

      [self setObject:firstCyclic];
    }
  }
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
  ASSIGN(self->comment, _comment);
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

- (void)takeValue:(id)_value forKey:(id)_key {
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

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"cyclicAppointment"])
    return [self cyclicAppointment];
  else if ([_key isEqualToString:@"participants"])
    return [self participants];
  else if ([_key isEqualToString:@"comment"])
    return [self comment];
  else if ([_key isEqualToString:@"isWarningIgnored"])
    return [NSNumber numberWithBool:self->isWarningIgnored];
  return [super valueForKey:_key];
}

@end /* LSCyclicAppointmentsCommand */
