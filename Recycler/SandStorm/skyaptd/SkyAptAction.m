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
#include "common.h"
#include "SkyAppointmentResourceCache.h"
#include <XmlRpc/XmlRpcMethodCall.h>
#include <OGoIDL/NGXmlRpcAction+Introspection.h>

@implementation SkyAptAction

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObjects:@"appointments", nil];
}

- (NSString *)xmlrpcComponentName {
  return @"appointments";
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;
    NSBundle *bundle;

    bundle = [NSBundle bundleForClass:[self class]];

    path = [bundle pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path forComponentName:@"appointments"];
    else
      NSLog(@"WARNING[%s]:INTERFACE.xml not found in bundle path",
            __PRETTY_FUNCTION__);

    self->lastError = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->lastError);
  [super dealloc];
}

- (BOOL)coreOnFault {
  return YES;
}

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_method {
  static NSArray *methodNames = nil;
  
  if (methodNames == nil) {
    methodNames = [[NSArray alloc] initWithObjects:
                            @"system.listMethods",
                            @"system.methodSignature",
                            @"system.methodHelp",
                            nil];
  }

  if ([methodNames containsObject:_method])
    return NO;
  return YES;
}

// appointments

- (id)createAppointmentAction:(NSDictionary *)_dateStruct
                             :(NSArray *)_participants
                             :(NSArray *)_resourceNames
                             :(NSArray *)_writeAccessList
                             :(NSDictionary *)_repetitionStruct
                             :(NSString *)_comment
{
  NSDictionary *apt;
  id           gid;
  id           ctx;

  if ((ctx = [self commandContext]) == nil) {
    [self setLastError:@"AuthentificationFailed"
          errorCode:1
          description:@"missing command context"];
    return [self lastError];
  }

  apt = [self _buildAppointmentDict:_dateStruct
              participants:_participants
              resourceNames:_resourceNames
              writeAccessList:_writeAccessList
              repetition:_repetitionStruct
              comment:_comment];

  if (apt == nil) return [self lastError];

  [apt takeValue:[NSNumber numberWithBool:YES] forKey:@"isWarningIgnored"];
  apt = [[self commandContext] runCommand:@"appointment::new" arguments:apt];
  gid = [apt valueForKey:@"globalID"];
  if (gid == nil) {
    [self setLastError:@"CreateFailed"
          errorCode:2
          description:@"Creation of appointment failed"];
    return [self lastError];
  }
  return [[[self commandContext] documentManager] urlForGlobalID:gid];
}

- (id)createAppointmentDictAction:(NSDictionary *)_vals {
  return [self createAppointmentAction:[self _buildBasicApt:_vals]
               :[[_vals valueForKey:@"participants"] valueForKey:@"companyId"]
               :[[_vals valueForKey:@"resourceNames"]
                        componentsSeparatedByString:@", "]
               :[[_vals valueForKey:@"writeAccessList"]
                        componentsSeparatedByString:@","]
               :[self _buildRepetitionDict:_vals]
               :[_vals valueForKey:@"comment"]];
}

- (id)listAppointmentsAction:(NSCalendarDate *)_from
                            :(NSCalendarDate *)_to
                            :(NSArray *)_participants
                            :(NSArray *)_resources
                            :(NSArray *)_aptTypes
                            :(NSDictionary *)_hints
{
  NSDictionary *args  = nil;
  id           ctx;
  NSArray      *dates = nil;

  if ((ctx = [self commandContext]) == nil) {
    [self setLastError:@"AuthentificationFailed"
          errorCode:1
          description:@"missing command context"];
    return [self lastError];
  }

  args = [self _buildFetchDict:_from endDate:_to
               participants:_participants
               resourceNames:_resources
               appointmentTypes:_aptTypes
               hints:_hints];
  
  if (args == nil)
    return [self lastError];

  dates = [ctx runCommand:@"appointment::query" arguments:args];

  if (![dates count]) return [NSArray array];

  if ([[_hints valueForKey:@"fetchUrls"] boolValue])
    return [[[self commandContext] documentManager] urlsForGlobalIDs:dates];
  
  dates = [self _aptsForGIDs:dates hints:_hints];

  [self _ensureCurrentTransactionIsCommitted];
  return dates;
}

- (id)getAppointmentAction:(NSString *)_id {
  id ctx, date;

  if ((ctx = [self commandContext]) == nil) {
    [self setLastError:@"AuthentificationFailed"
          errorCode:1
          description:@"missing command context"];
    return [self lastError];
  }

  if ((date = [self _aptForId:_id]) == nil) {
    return [self lastError];
  }
  return date;
}

- (id)_prepareAptAction:(NSString *)_id
                version:(NSNumber *)_basedOnVersion
                context:(id *)_ctx
                   date:(id *)_date
{
  id ctx, date;

  if ((ctx = [self commandContext]) == nil) {
    [self setLastError:@"AuthentificationFailed"
          errorCode:1
          description:@"missing command context"];
    return [self lastError];
  }

  if ((date = [self _aptEOForId:_id]) == nil) 
    return [self lastError];

  if (_basedOnVersion != nil) {
    int mustBe = [_basedOnVersion intValue];
    if ([[date valueForKey:@"objectVersion"] intValue] != mustBe) 
      return [self editedByAnotherUserError];
  }

  *_ctx  = ctx;
  *_date = date;

  return nil;
}
- (id)_updateAppointment:(id)_date withContext:(id)_ctx {
  id date;
  // ignore warnings
  [_date takeValue:[NSNumber numberWithBool:YES] forKey:@"isWarningIgnored"];
  date = [_ctx runCommand:@"appointment::set" arguments:_date];
  if (date == nil) {
    NSLog(@"%s failed to save appointment: %@", __PRETTY_FUNCTION__, _date);
    return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (id)moveAppointmentAction:(NSString *)_id
                           :(NSNumber *)_amount
                           :(NSString *)_unit
                           :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  NSCalendarDate *tmp;

  int years, months, days, hours, minutes, seconds;

  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;
  
  if (_amount == nil) _amount = [NSNumber numberWithInt:60];
  if (![self _extractTimeDistance:_amount
             unit:_unit
             years:&years
             months:&months
             days:&days
             hours:&hours
             minutes:&minutes
             seconds:&seconds]) {
    return [self lastError];
  }

  tmp = [date valueForKey:@"startDate"];
  tmp = [tmp dateByAddingYears:years months:months days:days
             hours:hours minutes:minutes seconds:seconds];
  [date takeValue:tmp forKey:@"startDate"];

  tmp = [date valueForKey:@"endDate"];
  tmp = [tmp dateByAddingYears:years months:months days:days
             hours:hours minutes:minutes seconds:seconds];
  [date takeValue:tmp forKey:@"endDate"];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentParticipantsAction:(NSString *)_id
                                      :(NSArray *)_participants
                                      :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setParticipants:_participants forDate:date]) {
    return [self lastError];
  }

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentResourcesAction:(NSString *)_id
                                   :(NSArray *)_resourceNames
                                   :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;

  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setResourceNames:_resourceNames forDate:date]) {
    return [self lastError];
  }

  return [self _updateAppointment:date withContext:ctx];
}

- (id)editAppointmentLightAction:(NSString *)_id
                                :(NSCalendarDate *)_startDate
                                :(NSCalendarDate *)_endDate
                                :(NSString *)_title
                                :(NSString *)_location
                                :(NSNumber *)_saveAllCyclic
                                :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setStartDate:_startDate
             endDate:_endDate
             title:_title
             location:_location
             forDate:date]) {
    return [self lastError];
  }

  if ([_saveAllCyclic boolValue]) {
    NSArray *cyclics;
    id      pid = [date valueForKey:@"parentDateId"];
    if (pid != nil) {
      NSMutableArray *cs = [NSMutableArray array];
      id             p   = [self getAppointmentAction:pid];
      [cs addObject:p];
      [cs addObjectsFromArray:[ctx runCommand:@"appointment::get-cyclics",
                                   @"object", p, nil]];
      cyclics = cs;
    }
    else {
      cyclics = [ctx runCommand:@"appointment::get-cyclics",
                     @"object", date, nil];
    }
    [date takeValue:[NSNumber numberWithBool:YES] forKey:@"setAllCyclic"];
    [date takeValue:cyclics forKey:@"cyclics"];
  }
  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentWriteAccessListAction:(NSString *)_id
                                         :(NSArray *)_writeAccessList
                                         :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setWriteAccessList:_writeAccessList forDate:date]) {
    return [self lastError];
  }

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentNotificationAction:(NSString *)_id
                                      :(id)_notify
                                      :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setNotifyMinutesBefore:nil notify:_notify forDate:date])
    return [self lastError];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentTypeAction:(NSString *)_id
                              :(NSString *)_aptType
                              :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setAppointmentType:_aptType forDate:date])
    return [self lastError];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentIgnoreConflictAction:(NSString *)_id
                                        :(NSString *)_ignore
                                        :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (_ignore == nil) _ignore = @"always";
  if (![self _setIgnoreConflicts:_ignore forDate:date])
    return [self lastError];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentViewAccessTeamAction:(NSString *)_id
                                        :(id)_viewAccessTeam
                                        :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setViewAccessTeam:_viewAccessTeam forDate:date])
    return [self lastError];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentRepetitionAction:(NSString *)_id
                                    :(id)_repetitionType
                                    :(id)_cycleEndDate
                                    :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setRepetition:_repetitionType cycleEndDate:_cycleEndDate
             forDate:date])
    return [self lastError];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)setAppointmentCommentAction:(NSString *)_id
                                 :(NSString *)_comment
                                 :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setComment:_comment forDate:date])
    return [self lastError];

  return [self _updateAppointment:date withContext:ctx];
}

- (id)addAppointmentLogAction:(NSString *)_id
                             :(NSString *)_action
                             :(NSString *)_logText
                             :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![_action length])
    return [self invalidArgument:@"action"];

  if (![_logText length])
    _logText = _action;

  return [NSNumber numberWithBool:
                   [self _addLog:_logText
                         action:_action
                         toApId:[date valueForKey:@"dateId"]]];
}

- (id)addMeToAppointmentAction:(NSString *)_id
                              :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  id account;
  id parts;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  account = [[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  parts   = [[date valueForKey:@"participants"] valueForKey:@"companyId"];
  if (![parts containsObject:account]) {
    parts = [parts arrayByAddingObject:account];
    if (![self _setParticipants:parts forDate:date])
      return [self lastError];
    return [self _updateAppointment:date withContext:ctx];
  }

  NSLog(@"WARNING[%s]: You already take part in this appointment",
        __PRETTY_FUNCTION__);
  return [NSNumber numberWithBool:NO];
}

- (id)removeMeFromAppointmentAction:(NSString *)_id
                                   :(NSNumber *)_basedOnVersion
{
  id ctx, date, err;
  id account;
  id parts;
  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  account = [[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  parts   = [[date valueForKey:@"participants"] valueForKey:@"companyId"];
  if ([parts containsObject:account]) {
    parts = [parts mutableCopy];
    [parts removeObject:account];
    if (![self _setParticipants:parts forDate:date]) {
      RELEASE(parts);
      return [self lastError];
    }
    RELEASE(parts);
    return [self _updateAppointment:date withContext:ctx];
  }

  NSLog(@"WARNING[%s]: You don't take part in this appointment",
        __PRETTY_FUNCTION__);
  return [NSNumber numberWithBool:NO];
}

- (id)editAppointmentAction:(NSString *)_id
                           :(NSDictionary *)_dateStruct
                           :(NSArray *)_participants
                           :(NSArray *)_resourceNames
                           :(NSArray *)_writeAccessList
                           :(NSDictionary *)_repetitionStruct
                           :(NSString *)_comment
                           :(NSNumber *)_saveAllCyclic
                           :(NSNumber *)_basedOnVersion
{
  id date, ctx, err;

  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (![self _setParticipants:_participants forDate:date])
    return [self lastError];
  if (![self _setResourceNames:_resourceNames forDate:date])
    return [self lastError];

  // basic apt data
  if (![self _setStartDate:[_dateStruct valueForKey:@"startDate"]
             endDate:[_dateStruct valueForKey:@"endDate"]
             title:[_dateStruct valueForKey:@"title"]
             location:[_dateStruct valueForKey:@"location"]
             forDate:date]) return [self lastError];
  
  // notify
  if (![self _setNotifyMinutesBefore:
             [_dateStruct valueForKey:@"notifyMinutesBefore"]
             notify:[_dateStruct valueForKey:@"notify"]
             forDate:date]) return [self lastError];

  // appointmentType
  if (![self _setAppointmentType:[_dateStruct valueForKey:@"appointmentType"]
             forDate:date]) return [self lastError];

  // ignore conflicts
  if (![self _setIgnoreConflicts:[_dateStruct valueForKey:@"ignoreConflicts"]
             forDate:date]) return [self lastError];

  // accessTeamId
  if (![self _setViewAccessTeam:[_dateStruct valueForKey:@"viewAccessTeam"]
             forDate:date]) return [self lastError];

  // repetition
  if (![self _setRepetition:[_repetitionStruct valueForKey:@"repetitionType"]
             cycleEndDate:[_repetitionStruct valueForKey:@"cycleEndDate"]
             forDate:date]) return [self lastError];

  // writeAccessList
  if (![self _setWriteAccessList:_writeAccessList forDate:date])
    return [self lastError];

  // comment
  if (![self _setComment:_comment forDate:date])
    return [self lastError];

  if ([_saveAllCyclic boolValue]) {
    NSArray *cyclics;
    id      pid = [date valueForKey:@"parentDateId"];
    if (pid != nil) {
      NSMutableArray *cs = [NSMutableArray array];
      id             p   = [self getAppointmentAction:pid];
      [cs addObject:p];
      [cs addObjectsFromArray:[ctx runCommand:@"appointment::get-cyclics",
                                   @"object", p, nil]];
      cyclics = cs;
    }
    else {
      cyclics = [ctx runCommand:@"appointment::get-cyclics",
                     @"object", date, nil];
    }
    [date takeValue:[NSNumber numberWithBool:YES] forKey:@"setAllCyclic"];
    [date takeValue:cyclics forKey:@"cyclics"];
  }

  return [self _updateAppointment:date withContext:ctx];
}

- (id)editAppointmentDictAction:(NSDictionary *)_vals {
  id allCyclic = [_vals valueForKey:@"setAllCyclic"];
  id com       = [_vals valueForKey:@"comment"];

  if (com == nil)       com       = @"";
  if (allCyclic == nil) allCyclic = [NSNumber numberWithBool:NO];

  return [self editAppointmentAction:
               [_vals valueForKey:@"dateId"]
               :[self _buildBasicApt:_vals]
               :[[_vals valueForKey:@"participants"] valueForKey:@"companyId"]
               :[[_vals valueForKey:@"resourceNames"]
                        componentsSeparatedByString:@", "]
               :[[_vals valueForKey:@"writeAccessList"]
                        componentsSeparatedByString:@","]
               :[self _buildRepetitionDict:_vals]
               :com
               :allCyclic
               :[_vals valueForKey:@"objectVersion"]];
}

- (id)deleteAppointmentAction:(NSString *)_id
                             :(NSNumber *)_deleteAllCyclic
                             :(NSNumber *)_basedOnVersion
{
  id date, ctx, err;

  if ((err = [self _prepareAptAction:_id
                   version:_basedOnVersion
                   context:&ctx date:&date]) != nil)
    return err;

  if (_deleteAllCyclic == nil) _deleteAllCyclic = [NSNumber numberWithBool:NO];

  // fetch a real eo ( no dictionary )
  date = [ctx runCommand:@"appointment::get-by-globalid",
              @"gid", [date valueForKey:@"globalID"],
              nil];

  date = [ctx runCommand:@"appointment::delete",
              @"object",          date,
              @"reallyDelete",    [NSNumber numberWithBool:YES],
              @"deleteAllCyclic", _deleteAllCyclic,
              nil];

  if (date == nil)
    return [NSNumber numberWithBool:NO];
  return [NSNumber numberWithBool:YES];
}

- (id)getAppointmentPermissionsAction:(NSString *)_id
{
  id date, ctx, err;

  if ((err = [self _prepareAptAction:_id
                   version:nil
                   context:&ctx date:&date]) != nil)
    return err;
  return [date valueForKey:@"permissions"];
}

- (id)getAppointmentCommentAction:(NSString *)_id
{
  id date, ctx, err;

  if ((err = [self _prepareAptAction:_id
                   version:nil
                   context:&ctx date:&date]) != nil)
    return err;
  return [date valueForKey:@"comment"];
}

- (id)listAppointmentParticipantsAction:(NSString *)_id
                                       :(NSString *)_format
{
  NSArray *parts;
  id date, ctx, err;

  if ((err = [self _prepareAptAction:_id
                   version:nil
                   context:&ctx date:&date]) != nil)
    return err;
  parts = [self _buildParticipants:[date valueForKey:@"participants"]];
  if ([_format isEqualToString:@"urls"])
    return [parts valueForKey:@"id"];
  
  // anything else: full dicts
  return parts;
}

- (id)listConflictingAppointmentsAction:(NSCalendarDate *)_startDate
                                       :(NSCalendarDate *)_endDate
                                       :(NSArray *)_participants
                                       :(NSArray *)_resourceNames
                                       :(NSDictionary *)_repetition
                                       :(NSArray *)_cyclics
                                       :(NSString *)_ignoreConflicts
                                       :(NSDictionary *)_hints
{
  NSMutableDictionary            *apt;
  NSArray                        *cs;
  id                             refId;

  if (_endDate == nil)
    _endDate = [_startDate dateByAddingYears:0 months:0 days:0
                           hours:1 minutes:0 seconds:0];

  refId = [_hints valueForKey:@"dateId"];
  apt   = [NSMutableDictionary dictionaryWithCapacity:8];
  [apt takeValue:_startDate    forKey:@"startDate"];
  [apt takeValue:_endDate      forKey:@"endDate"];

  if (![self _setStartDate:_startDate endDate:_endDate title:@"dummy"
             location:nil forDate:apt])
    return [self lastError];
  if (![self _setParticipants:_participants   forDate:apt])
    return [self lastError];
  if (![self _setResourceNames:_resourceNames forDate:apt])
    return [self lastError];
  if (![self _setRepetition:[_repetition valueForKey:@"repetitionType"]
             cycleEndDate:[_repetition valueForKey:@"cycleEndDate"]
             forDate:apt])
    return [self lastError];
  if (![self _setIgnoreConflicts:_ignoreConflicts forDate:apt])
    return [self lastError];

  if ([refId isNotNull]) [apt takeValue:refId forKey:@"dateId"];
  if ([_cyclics count]) {
    [apt takeValue:_cyclics forKey:@"cyclics"];
    [apt takeValue:[NSNumber numberWithBool:YES] forKey:@"setAllCyclic"];
  }
  
  [self _ensureCurrentTransactionIsCommitted];
  
  cs = [self conflictGIDsForAppointment:apt];
  if ([[_hints valueForKey:@"fetchUrls"] boolValue]) {
    [self _ensureCurrentTransactionIsCommitted];
    return [[[self commandContext] documentManager]
                   urlsForGlobalIDs:cs];
  }

  cs = [self _aptsForGIDs:cs];
  [self _ensureCurrentTransactionIsCommitted];
  
  return cs;
}

- (id)listAppointmentProposalsAction:(NSDictionary *)_time
                                    :(NSArray *)_participants
                                    :(NSArray *)_resourceNames
                                    :(NSArray *)_categories
{
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSTimeZone     *tz;
  NSNumber       *duration, *startTime, *endTime, *interval;
  NSArray        *parts, *res, *cats;
  id             result;

  startDate = [_time valueForKey:@"startDate"];
  if (![startDate isNotNull])  return [self invalidArgument:@"time.startDate"];
  endDate   = [_time valueForKey:@"endDate"];
  if (![endDate isNotNull])    return [self invalidArgument:@"time.endDate"];
  duration  = [_time valueForKey:@"duration"];
  if (![duration isNotNull])   return [self invalidArgument:@"time.duration"];
  startTime = [_time valueForKey:@"startTime"];
  if (![startTime isNotNull])  return [self invalidArgument:@"time.startTime"];
  endTime   = [_time valueForKey:@"endTime"];
  if (![endTime isNotNull])    return [self invalidArgument:@"time.endTime"];
  interval  = [_time valueForKey:@"interval"];
  if (![interval isNotNull])   return [self invalidArgument:@"time.interval"];
  tz        = [NSTimeZone timeZoneWithAbbreviation:
                          [_time valueForKey:@"timeZone"]];
  if (![tz isNotNull])         return [self invalidArgument:@"time.timeZone"];

  if (([_participants isKindOfClass:[NSArray class]]) &&
      ([_participants count] == 0))
    // allow empty participants
    parts = [NSArray array];
  else
    parts = [self _extractParticipants:_participants];
  if (![parts isNotNull])      return [self invalidArgument:@"participants"];
  res   = [self _extractResources:_resourceNames];
  if (![res isNotNull])        return [self invalidArgument:@"resourceNames"];
  cats  = [self _extractResourceCategories:_categories];
  if (![cats isNotNull])       return [self invalidArgument:@"categories"];

  result = [[self commandContext] runCommand:@"appointment::proposal",
                                  @"participants", parts,
                                  @"resources",    res,
                                  @"categories",   cats,
                                  @"startDate",    startDate,
                                  @"endDate",      endDate,
                                  @"timeZone",     tz,
                                  @"duration",     duration,
                                  @"startTime",    startTime,
                                  @"endTime",      endTime,
                                  @"interval",     interval,
                                  nil];
  [self _ensureCurrentTransactionIsCommitted];
  return result;
}

- (id)getFilledAppointmentMailBodyAction:(id)_date {
  id             ctx;
  NSUserDefaults *ud;
  NSString       *template;
  NSDictionary   *bindings;

  ctx      = [self commandContext];
  ud       = [ctx valueForKey:LSUserDefaultsKey];
  template = [ud valueForKey:@"scheduler_mail_template"];
  bindings = [self bindingsForAppointment:_date];

  if ([template isNotNull])
    template = [template stringByReplacingVariablesWithBindings:bindings
                         stringForUnknownBindings:@""];
  if (![template isNotNull])
    template = @"";

  return template;
}

- (id)getFilledAppointmentMailBodyByIdAction:(id)_id {
  id date, ctx, err;
  if ((err = [self _prepareAptAction:_id
                        version:nil
                        context:&ctx date:&date]) != nil)
    return err;
  
  return [self getFilledAppointmentMailBodyAction:date];
}

// appointmentTypes

- (id)listAppointmentTypesAction {
  id           ctx;
  if ((ctx = [self commandContext]) == nil) {
    [self setLastError:@"AuthentificationFailed"
          errorCode:1
          description:@"missing command context"];
    return [self lastError];
  }

  return [self _validAptTypes];
}

// appointmentResources
- (NSArray *)listAppointmentResourcesAction:(NSString *)_category {
  LSCommandContext *ctx    = [self commandContext];
  NSArray          *result = nil;
  
  if (ctx != nil) {
    SkyAppointmentResourceCache *cache;
    cache = [SkyAppointmentResourceCache cacheWithCommandContext:ctx];
    result = [cache allObjectsWithContext:ctx];
    
    if (_category != nil) {
      EOQualifier *qual = [EOQualifier qualifierWithQualifierFormat:
                                       @"category = %@", _category];
      result = [result filteredArrayUsingQualifier:qual];
    }
  }
  return result;
}

- (NSArray *)listAppointmentResourceNamesAction:(NSString *)_category {
  id result = [self listAppointmentResourcesAction:_category];
  return [result valueForKey:@"name"];
}

- (NSArray *)listAppointmentResourceCategoriesAction {
  id                          ctx;
  SkyAppointmentResourceCache *cache;
  ctx   = [self commandContext];
  cache = [SkyAppointmentResourceCache cacheWithCommandContext:ctx];

  return [cache allCategoriesWithContext:ctx];
}

- (id)listUsedResourceNamesAction:(id)_startDate
                                 :(id)_endDate
                                 :(NSString *)_category
{
  NSCalendarDate *startDate = [self _extractDate:_startDate];
  NSCalendarDate *endDate   = [self _extractDate:_endDate];

  if (![startDate isNotNull]) return [self invalidArgument:@"startDate"];
  if (![endDate isNotNull])   return [self invalidArgument:@"endDate"];

  if ([_category length]) {
    return [[self commandContext] runCommand:
                                  @"appointment::used-resources",
                                  @"startDate", startDate,
                                  @"endDate",   endDate,
                                  @"category",  _category,
                                  nil];
  }
  return [[self commandContext] runCommand:
                                @"appointment::used-resources",
                                @"startDate", startDate,
                                @"endDate",   endDate,
                                nil];
}

@end /* SkyAptAction */

