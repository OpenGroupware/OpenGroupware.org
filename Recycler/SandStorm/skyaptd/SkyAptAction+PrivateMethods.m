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

#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>

@implementation SkyAptAction(PrivateMethods) 

- (NSTimeZone *)timeZone {
  NSTimeZone *tzone  = nil;
  NSString   *abbrev = [[[self commandContext] userDefaults]
                               objectForKey:@"timezone"];

  if (abbrev != nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:abbrev];

  if (tzone == nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:@"MET"];

  return tzone;
}
- (NSDictionary *)_buildAppointmentDict:(NSDictionary *)_dateStruct
                           participants:(NSArray *)_participants
                          resourceNames:(NSArray *)_resourceNames
                        writeAccessList:(NSArray *)_writeAccessList
                             repetition:(NSDictionary *)_repetitionStruct
                                comment:(NSString *)_comment
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:16];

  if (![self _setParticipants:_participants forDate:dict])   return nil;
  if (![self _setResourceNames:_resourceNames forDate:dict]) return nil;

  // basic apt data
  if (![self _setStartDate:[_dateStruct valueForKey:@"startDate"]
             endDate:[_dateStruct valueForKey:@"endDate"]
             title:[_dateStruct valueForKey:@"title"]
             location:[_dateStruct valueForKey:@"location"]
             forDate:dict]) return nil;
  
  // notify
  if (![self _setNotifyMinutesBefore:
             [_dateStruct valueForKey:@"notifyMinutesBefore"]
             notify:[_dateStruct valueForKey:@"notify"]
             forDate:dict]) return nil;

  // appointmentType
  if (![self _setAppointmentType:[_dateStruct valueForKey:@"appointmentType"]
             forDate:dict]) return nil;

  // ignore conflicts
  if (![self _setIgnoreConflicts:[_dateStruct valueForKey:@"ignoreConflicts"]
             forDate:dict]) return nil;

  // accessTeamId
  if (![self _setViewAccessTeam:[_dateStruct valueForKey:@"viewAccessTeam"]
             forDate:dict]) return nil;

  // repetition
  if (![self _setRepetition:[_repetitionStruct valueForKey:@"repetitionType"]
             cycleEndDate:[_repetitionStruct valueForKey:@"cycleEndDate"]
             forDate:dict]) return nil;

  // writeAccessList
  if (![self _setWriteAccessList:_writeAccessList forDate:dict]) return nil;

  // comment
  if (![self _setComment:_comment forDate:dict]) return nil;

  return dict;
}

- (NSDictionary *)_buildFetchDict:(id)_from
                          endDate:(id)_to
                     participants:(NSArray *)_participants
                    resourceNames:(NSArray *)_resourceNames
                 appointmentTypes:(NSArray *)_aptTypes
                            hints:(NSDictionary *)_hints
{
  NSArray  *participants  = [self _extractParticipants:_participants];
  NSArray  *resources     = nil;
  NSArray  *aptTypes      = nil;

  NSCalendarDate      *from    = nil;
  NSCalendarDate      *to      = nil;
  NSMutableDictionary *dict    = nil;

  participants  = [self _extractParticipants:_participants];
  if (participants == nil) {
    [self invalidArgument:@"participants"];
    return nil;
  }
  else {    
    participants = [participants valueForKey:@"globalID"];
  }
  if (_resourceNames != nil) {
    if (([_resourceNames isKindOfClass:[NSString class]]) &&
        ([_resourceNames isEqual:@"all"])) {
    }
    else {
      resources = [self _extractResources:_resourceNames];
      if (resources == nil) {
        [self invalidArgument:@"resources"];
        return nil;
      }
    }
  }
  if (_aptTypes != nil) {
    if (([_aptTypes isKindOfClass:[NSString class]]) &&
        ([_aptTypes isEqual:@"all"])) {
    }
    else {
      aptTypes = [self _extractAptTypes:_aptTypes];
      if (aptTypes == nil) {
        [self invalidArgument:@"appointmentTypes"];
        return nil;
      }
    }
  }

  if ([[_hints valueForKey:@"noFromDate"] boolValue])
    from = nil;
  else {
    from = [self _extractDate:_from defaultDate:[NSCalendarDate date]
                 defaultHour:0 defaultMinute:0 defaultSecond:0];

    if (from == nil) {
      [self invalidArgument:@"from"];
      return nil;
    }
  }
  if ([[_hints valueForKey:@"noToDate"] boolValue])
    from = nil;
  else {
    to   = [self _extractDate:_to   defaultDate:[from endOfDay]
                 defaultHour:23 defaultMinute:59 defaultSecond:59];
    if (to == nil) {
      [self invalidArgument:@"to"];
      return nil;
    }
  }

  if ((from != nil) && (to != nil)) {
    if ([from laterDate:to] == from) {
      [self invalidArgument:@"to"];
      return nil;
    }
  }

  dict = [NSMutableDictionary dictionaryWithCapacity:5];
  if (from != nil)
    [dict takeValue:from         forKey:@"fromDate"];
  if (to != nil)
    [dict takeValue:to           forKey:@"toDate"];
  [dict takeValue:participants forKey:@"companies"];
  if (resources != nil)
    [dict takeValue:resources    forKey:@"resourceNames"];
  if (aptTypes != nil)
    [dict takeValue:aptTypes     forKey:@"aptTypes"];

  return dict;
}

- (NSArray *)_aptFetchAttributes {
  static NSArray *aptFetchAttributes = nil;
  if (aptFetchAttributes == nil) {
    aptFetchAttributes =
      [NSArray arrayWithObjects:@"dateId", @"parentDateId", @"startDate",
               @"endDate", @"cycleEndDate", @"ownerId", @"accessTeamId",
               @"isAttendance", @"isAbsence", @"isViewAllowed",
               @"isConflictDisabled", @"type", @"notificationTime",
               @"dbStatus", @"objectVersion",
               @"aptType", @"comment", @"location",
               @"participants.globalID",
               @"participants.companyId",
               @"participants.login",
               @"participants.isAccount",
               @"participants.isTeam",
               @"participants.isPerson",
               @"participants.isLocked",
               @"participants.description",
               @"participants.firstname",
               @"participants.name",
               @"permissions", @"resourceNames", @"writeAccessList",
               @"title", 
               @"globalID", nil];
    RETAIN(aptFetchAttributes);
  }
  return aptFetchAttributes;
}
- (NSDictionary *)_partDict4EO:(id)_eo {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:8];
  id tmp;
  id gid;
  id url;

  tmp = [_eo valueForKey:@"login"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"login"];

  tmp = [_eo valueForKey:@"companyId"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"companyId"];

  tmp = [_eo valueForKey:@"isAccount"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isAccount"];
  
  tmp = [_eo valueForKey:@"isPerson"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isPerson"];
  
  tmp = [_eo valueForKey:@"isLocked"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isLocked"];
  
  tmp = [_eo valueForKey:@"description"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"description"];
  
  tmp = [_eo valueForKey:@"isTeam"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isTeam"];

  tmp = [_eo valueForKey:@"firstname"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"firstname"];

  tmp = [_eo valueForKey:@"name"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"name"];
  
  gid = [_eo valueForKey:@"globalID"];
  url = [[[self commandContext] documentManager] urlForGlobalID:gid];
  if ([url isNotNull]) [dict takeValue:url forKey:@"id"];
  
  return dict;
}
- (NSArray *)_buildParticipants:(NSArray *)_parts {
  int            max = [_parts count];
  NSMutableArray *ma = [NSMutableArray arrayWithCapacity:max];
  NSEnumerator   *e  = [_parts objectEnumerator];
  id             one;

  while ((one = [e nextObject])) {
    [ma addObject:[self _partDict4EO:one]];
  }
  return ma;
}
- (NSDictionary *)_aptDict4EO:(id)_eo {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:24];
  id tmp;
  id gid;
  id url;
  
  tmp = [_eo valueForKey:@"accessTeamId"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"accessTeamId"];

  tmp = [_eo valueForKey:@"aptType"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"aptType"];

  tmp = [_eo valueForKey:@"comment"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"comment"];

  tmp = [_eo valueForKey:@"cycleEndDate"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"cycleEndDate"];

  tmp = [_eo valueForKey:@"dateId"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"dateId"];
  
  tmp = [_eo valueForKey:@"dbStatus"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"dbStatus"];
  
  tmp = [_eo valueForKey:@"endDate"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"endDate"];

  tmp = [_eo valueForKey:@"isAbsence"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isAbsence"];
  
  tmp = [_eo valueForKey:@"isAttendance"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isAttendance"];
  
  tmp = [_eo valueForKey:@"isConflictDisabled"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isConflictDisabled"];

  tmp = [_eo valueForKey:@"isViewAllowed"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"isViewAllowed"];
  
  tmp = [_eo valueForKey:@"location"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"location"];

  tmp = [_eo valueForKey:@"notificationTime"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"notificationTime"];

  tmp = [_eo valueForKey:@"objectVersion"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"objectVersion"];
  
  tmp = [_eo valueForKey:@"ownerId"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"ownerId"];
  
  tmp = [_eo valueForKey:@"parentDateId"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"parentDateId"];
  
  tmp = [_eo valueForKey:@"participants"];
  if ([tmp isNotNull])
    [dict takeValue:[self _buildParticipants:tmp] forKey:@"participants"];

  tmp = [_eo valueForKey:@"permissions"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"permissions"];
  
  tmp = [_eo valueForKey:@"resourceNames"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"resourceNames"];
  
  tmp = [_eo valueForKey:@"startDate"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"startDate"];

  tmp = [_eo valueForKey:@"title"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"title"];
  
  tmp = [_eo valueForKey:@"type"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"type"];

  tmp = [_eo valueForKey:@"writeAccessList"];
  if ([tmp isNotNull]) [dict takeValue:tmp forKey:@"writeAccessList"];

  gid = [_eo valueForKey:@"globalID"];
  url = [[[self commandContext] documentManager] urlForGlobalID:gid];
  if ([url isNotNull]) [dict takeValue:url forKey:@"id"];
  
  return dict;
}
- (NSArray *)_buildAppointments:(NSArray *)_apts {
  int            max = [_apts count];
  NSMutableArray *ma = [NSMutableArray arrayWithCapacity:max];
  NSEnumerator   *e  = [_apts objectEnumerator];
  id             one;

  while ((one = [e nextObject])) {
    [ma addObject:[self _aptDict4EO:one]];
  }
  return ma;
}

- (void)_ensureCurrentTransactionIsCommitted {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    if ([ctx isTransactionInProgress]) {
      if (![ctx commit]) {  
        [self logWithFormat:@"couldn't commit transaction ..."];
      }
    }
  }
}

- (id)_aptEOForId:(NSString *)_id {
  NSArray      *dates;
  id           gid;
  id           ctx;

  ctx = [self commandContext];
  
  if ((gid = [[ctx documentManager] globalIDForURL:_id]) == nil) {
    [self invalidAppointmentId:_id];
    return nil;
  }

  dates = [self _aptEOsForGIDs:[NSArray arrayWithObject:gid]];

  if ([dates count] != 1) {
    [self setLastError:@"InvalidArgument"
          errorCode:21
          description:
          [NSString stringWithFormat:@"didn't find appointment for id %@",
                    gid]];
    return nil;
  }
  return [dates lastObject];
}
- (NSDictionary *)_aptForId:(NSString *)_id {
  id eo = [self _aptEOForId:_id];
  return (eo == nil) ? nil : [self _aptDict4EO:eo];
}

- (NSArray *)_aptEOsForGIDs:(NSArray *)_gids hints:(NSDictionary *)_hints {
  NSDictionary *args;
  NSArray      *result;
  id           tz;
  tz = [_hints valueForKey:@"timeZone"];
  if (tz != nil) tz = [NSTimeZone timeZoneWithAbbreviation:tz];
  else           tz = [self timeZone];
  args = [NSDictionary dictionaryWithObjectsAndKeys:
                       _gids,                      @"gids",
                       tz,                         @"timeZone",
                       [self _aptFetchAttributes], @"attributes",
                       nil];
  result = [[self commandContext]
                  runCommand:@"appointment::get-by-globalid" arguments:args];
  [self _ensureCurrentTransactionIsCommitted];
  return result;
}
- (NSArray *)_aptEOsForGIDs:(NSArray *)_gids {
  return [self _aptEOsForGIDs:_gids hints:nil];
}
- (NSArray *)_aptsForGIDs:(NSArray *)_gids hints:(NSDictionary *)_hints {
  return [self _buildAppointments:[self _aptEOsForGIDs:_gids
                                        hints:_hints]];
}
- (NSArray *)_aptsForGIDs:(NSArray *)_gids {
  return [self _aptsForGIDs:_gids hints:nil];
}

- (NSDictionary *)_buildBasicApt:(id)_apt {
  NSMutableDictionary *basic = [NSMutableDictionary dictionaryWithCapacity:8];
  id                  tmp;
  id                  s      = _apt;
  id                  ignore;
  id                  accessT;

  if ([[s valueForKey:@"isConflictDisabled"] boolValue])
    ignore = @"always";
  else if ([[s valueForKey:@"isWarningIgnored"] boolValue])
    ignore = @"onlyNow";
  else
    ignore = @"no";

  accessT = [s valueForKey:@"accessTeamId"];

  if ([(tmp = [s valueForKey:@"title"]) isNotNull])
      [basic setObject:tmp forKey:@"title"];
  if ([(tmp = [s valueForKey:@"location"]) isNotNull])
      [basic setObject:tmp forKey:@"location"];
  if ([(tmp = [s valueForKey:@"startDate"]) isNotNull])
      [basic setObject:tmp forKey:@"startDate"];
  if ([(tmp = [s valueForKey:@"endDate"]) isNotNull])
      [basic setObject:tmp forKey:@"endDate"];
  if ([(tmp = [s valueForKey:@"notificationTime"]) isNotNull])
      [basic setObject:tmp forKey:@"notifyMinutesBefore"];
  if ([(tmp = [s valueForKey:@"aptType"]) isNotNull])
      [basic setObject:tmp forKey:@"appointmentType"];

  [basic setObject:ignore forKey:@"ignoreConflicts"];
  if ([accessT isNotNull])
    [basic setObject:accessT forKey:@"viewAccessTeam"];

  return basic;
}

- (NSDictionary *)_buildRepetitionDict:(id)_apt {
  NSMutableDictionary *rep = [NSMutableDictionary dictionaryWithCapacity:2];
  id                  tmp;
  id                  s    = _apt;

  if ([(tmp = [s valueForKey:@"type"]) isNotNull])
      [rep setObject:tmp forKey:@"repetitionType"];
  if ([(tmp = [s valueForKey:@"cycleEndDate"]) isNotNull])
      [rep setObject:tmp forKey:@"cycleEndDate"];

  return rep;
}

@end /* SkyAptAction(PrivateMethods) */


