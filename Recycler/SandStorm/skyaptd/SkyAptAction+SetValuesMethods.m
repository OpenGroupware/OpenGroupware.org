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

#include "SkyAptAction.h"
#import <Foundation/Foundation.h>
#include <NGExtensions/NGExtensions.h>

@implementation SkyAptAction(SetValuesMethods)

- (BOOL)_setParticipants:(NSArray *)_participants
                 forDate:(NSMutableDictionary *)_date
{
  NSArray *participants = [self _extractParticipants:_participants];
  if (participants == nil) {
    [self invalidArgument:@"participants"];
    return NO;
  }

  [_date takeValue:participants forKey:@"participants"];
  
  return YES;
}
- (BOOL)_setResourceNames:(NSArray *)_resourceNames
                  forDate:(NSMutableDictionary *)_date
{
  NSArray *resourceNames = [self _extractResources:_resourceNames];
  if (resourceNames == nil) {
    [self invalidArgument:@"resourceNames"];
    return NO;
  }
  if ([resourceNames count])
    [_date takeValue:[resourceNames componentsJoinedByString:@", "]
           forKey:@"resourceNames"];
  else
    [_date takeValue:[NSNull null] forKey:@"resourceNames"];
  return YES;
}

- (BOOL)_setStartDate:(id)_startDate
              endDate:(id)_endDate
                title:(id)_title
             location:(id)_location
              forDate:(NSMutableDictionary *)_date
{
  NSCalendarDate *start, *end;
  id tmp;

    // startdate
  tmp = [self _extractDate:_startDate];

  if (tmp == nil) {
    [self invalidArgument:@"date.startDate"];
    return NO;
  }
  start = tmp;

  // enddate
  if (_endDate == nil)
    // default: 1 hour after startdate
    tmp = [start dateByAddingYears:0 months:0 days:0
                 hours:1 minutes:0 seconds:0];
  else 
    tmp = [self _extractDate:_endDate];
  if (tmp == nil) {
    [self invalidArgument:@"date.endDate"];
    return NO;
  }
  end = tmp;

  if (([start isEqual:end]) || ([start laterDate:end] == start)) {
    [self setLastError:@"InvalidArgument" errorCode:21
          description:@"startDate must be before endDate"];
    return NO;
  }

  // title
  if (![_title length]) {
    [self invalidArgument:@"date.title"];
    return NO;
  }

  // location
  if (_location == nil) _location = (id)[NSNull null];

  [_date takeValue:start     forKey:@"startDate"];
  [_date takeValue:end       forKey:@"endDate"];
  [_date takeValue:_title    forKey:@"title"];
  [_date takeValue:_location forKey:@"location"];

  return YES;
}

- (BOOL)_setWriteAccessList:(NSArray *)_writeAccessList
                    forDate:(NSMutableDictionary *)_date
{
  id writeAccessList = nil;

  if (_writeAccessList == nil)
    writeAccessList = (id)[NSNull null];
  else {
    writeAccessList = [self _extractParticipants:_writeAccessList];
    writeAccessList = [writeAccessList valueForKey:@"companyId"];
    if (writeAccessList == nil) writeAccessList = (id)[NSNull null];
    else writeAccessList = [writeAccessList componentsJoinedByString:@","];
  }

  [_date takeValue:writeAccessList forKey:@"writeAccessList"];
  
  return YES;
}

- (BOOL)_setNotifyMinutesBefore:(id)_minutes
                         notify:(id)_notify
                        forDate:(NSMutableDictionary *)_date
{
  id notify = _minutes;
  if (notify != nil) {
    if ([notify isKindOfClass:[NSString class]]) {
      int n = [notify intValue];
      if (n > 0) notify = [NSNumber numberWithInt:n];
      else       notify = (id)[NSNull null];
    }
    else if (![notify isKindOfClass:[NSNumber class]]) {
#if 0
      [self invalidArgument:@"date.notifyMinutesBefore"];
      return NO;
#else
      notify = (id)[NSNull null];
#endif
    }
  }
  else { // notifyMinutesBefore == nil
    if (_notify == nil) {
      notify = (id)[NSNull null];
    }
    else {
      notify = [self _extractNotify:_notify];
      if (notify == nil) {
#if 0
        [self invalidArgument:@"date.notify"];
        return NO;
#else
        notify = (id)[NSNull null];
#endif
      }
    }
  }
  if (([(id)notify isNotNull]) && ([notify intValue] < 1))
    notify = (id)[NSNull null];

  [_date takeValue:notify forKey:@"notificationTime"];
  return YES;
}

- (BOOL)_setAppointmentType:(NSString *)_type
                    forDate:(NSMutableDictionary *)_date
{
  //id aptType = [self _checkAptType:_type];
  id aptType = _type;
  if (aptType == nil) aptType = (id)[NSNull null];

  [_date takeValue:aptType forKey:@"aptType"];
  return YES;
}

- (BOOL)_setIgnoreConflicts:(NSString *)_ignore
                    forDate:(NSMutableDictionary *)_date
{
  id conflictDisabled, ignoreWarning;

  static NSNumber *nNo  = nil;
  static NSNumber *nYes = nil;

  if (nNo  == nil) nNo  = [[NSNumber alloc] initWithBool:NO];
  if (nYes == nil) nYes = [[NSNumber alloc] initWithBool:YES];
  
  if ((_ignore == nil) || (![_ignore isKindOfClass:[NSString class]]))
    _ignore = @"no";
  if ([_ignore isEqualToString:@"onlyNow"]) {
    conflictDisabled = nNo;
    ignoreWarning    = nYes;
  }
  else if ([_ignore isEqualToString:@"always"]) {
    conflictDisabled = nYes;
    ignoreWarning    = nYes;
  }
  else {
    conflictDisabled = nNo;
    ignoreWarning    = nNo;
  }

  [_date takeValue:conflictDisabled forKey:@"isConflictDisabled"];
  [_date takeValue:ignoreWarning    forKey:@"isWarningIgnored"];

  return YES;
}

- (BOOL)_setViewAccessTeam:(id)_viewAccessTeam
                   forDate:(NSMutableDictionary *)_date
{
  id accessTeamId = [self _extractAccessTeamId:_viewAccessTeam];
  if (accessTeamId == nil) accessTeamId = (id)[NSNull null];

  [_date takeValue:accessTeamId forKey:@"accessTeamId"];
  
  return YES;
}

- (BOOL)_setRepetition:(id)_repetitionType
          cycleEndDate:(id)_cycleEndDate
               forDate:(NSMutableDictionary *)_date
{
  id             repetitionType;
  NSCalendarDate *cycleEndDate;

  NSCalendarDate *end = [_date valueForKey:@"endDate"];
  
  if (![end isNotNull]) return NO;

  repetitionType = [self _checkRepetitionType:_repetitionType];
  if (repetitionType == nil) {
    repetitionType = (id)[NSNull null];
    cycleEndDate   = (id)[NSNull null];
  }
  else {
    cycleEndDate = [self _extractDate:_cycleEndDate];
    if (cycleEndDate == nil) {
      cycleEndDate   = (id)[NSNull null];
      repetitionType = (id)[NSNull null];
    }
    else {
      cycleEndDate = [cycleEndDate endOfDay];
      if ([cycleEndDate laterDate:end] == end) {
        [self invalidArgument:@"repetition.cycleEndDate"];
        return NO;
      }
    }
  }

  [_date takeValue:cycleEndDate   forKey:@"cycleEndDate"];
  [_date takeValue:repetitionType forKey:@"type"];

  return YES;
}

- (BOOL)_setComment:(id)_comment forDate:(NSMutableDictionary *)_date {
  id comment = (_comment == nil)
    ? (id)[NSNull null] : [(id)_comment stringValue];
  [_date takeValue:comment forKey:@"comment"];

  return YES;
}

@end /* SkyAptAction(SetValuesMethods) */
