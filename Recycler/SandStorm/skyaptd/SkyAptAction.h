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

#ifndef __skyaptd_SkyAptAction_H__
#define __skyaptd_SkyAptAction_H__

#include <OGoDaemon/SDXmlRpcAction.h>

@class NSCalendarDate, NSTimeZone;

@interface SkyAptAction : SDXmlRpcAction
{
  NSException *lastError;
}

+ (NSArray *)xmlrpcNamespaces;
- (id)listAppointmentsAction:(NSCalendarDate *)_from
                            :(NSCalendarDate *)_to
                            :(NSArray *)_participants
                            :(NSArray *)_resources
                            :(NSArray *)_aptTypes
                            :(NSDictionary *)_hints;

- (id)removeMeFromAppointmentAction:(NSString *)_id
                                   :(NSNumber *)_basedOnVersion;

- (id)deleteAppointmentAction:(NSString *)_id
                             :(NSNumber *)_deleteAllCyclic
                             :(NSNumber *)_basedOnVersion;

- (id)createAppointmentAction:(NSDictionary *)_dateStruct
                             :(NSArray *)_participants
                             :(NSArray *)_resourceNames
                             :(NSArray *)_writeAccessList
                             :(NSDictionary *)_repetitionStruct
                             :(NSString *)_comment;
- (id)_updateAppointment:(id)_date withContext:(id)_ctx;

@end

@interface SkyAptAction(InputParsing)
- (BOOL)_extractTimeDistance:(NSNumber *)_amount
                        unit:(NSString *)_unit
                       years:(int *)_years
                      months:(int *)_months
                        days:(int *)_days
                       hours:(int *)_hours
                     minutes:(int *)_minutes
                     seconds:(int *)_seconds;
- (NSArray *)_extractParticipants:(NSArray *)_participants;
- (NSArray *)_extractResources:(id)_resources;
- (NSArray *)_extractResourceCategories:(id)_categories;
- (NSCalendarDate *)_extractDate:(id)_val
                     defaultDate:(NSCalendarDate *)_dDate
                     defaultHour:(int)_dHour
                   defaultMinute:(int)_dMin
                   defaultSecond:(int)_dSec;
- (NSCalendarDate *)_extractDate:(id)_val;
- (NSNumber *)_extractNotify:(id)_notify;
- (NSNumber *)_extractAccessTeamId:(id)_accessTeam;
- (NSArray *)_validAptTypes;
//- (NSString *)_checkAptType:(NSString *)_aptType;
- (NSArray *)_extractAptTypes:(NSArray *)_types;
- (NSString *)_checkRepetitionType:(NSString *)_repType;
@end /* SkyAptAction(InputParsing) */

@interface SkyAptAction(LastError)
- (void)setLastError:(NSString *)_name
           errorCode:(int)_errorCode
         description:(NSString *)_desc;
- (NSException *)lastError;
- (NSException *)invalidArgument:(NSString *)_argName;
- (NSException *)editedByAnotherUserError;
- (NSException *)invalidAppointmentId:(NSString *)_aptId;
@end /* SkyAptAction(LastError) */

@interface SkyAptAction(SetValuesMethods)
// checks values and sets them in _date or sets last error and returns NO
- (BOOL)_setParticipants:(NSArray *)_participants
                 forDate:(NSMutableDictionary *)_date;
- (BOOL)_setResourceNames:(NSArray *)_resourceNames
                  forDate:(NSMutableDictionary *)_date;
- (BOOL)_setStartDate:(id)_startDate
              endDate:(id)_endDate
                title:(id)_title
             location:(id)_location
              forDate:(NSMutableDictionary *)_date;
- (BOOL)_setWriteAccessList:(NSArray *)_writeAccessList
                    forDate:(NSMutableDictionary *)_date;
- (BOOL)_setNotifyMinutesBefore:(id)_minutes
                         notify:(id)_notify
                        forDate:(NSMutableDictionary *)_date;
- (BOOL)_setAppointmentType:(NSString *)_type
                    forDate:(NSMutableDictionary *)_date;
- (BOOL)_setIgnoreConflicts:(NSString *)_ignore
                    forDate:(NSMutableDictionary *)_date;
- (BOOL)_setViewAccessTeam:(id)_viewAccessTeam
                   forDate:(NSMutableDictionary *)_date;
- (BOOL)_setRepetition:(id)_repetitionType
          cycleEndDate:(id)_cycleEndDate
               forDate:(NSMutableDictionary *)_date;
- (BOOL)_setComment:(id)_comment forDate:(NSMutableDictionary *)_date;
@end /* SkyAptAction(SetValuesMethods) */

@interface SkyAptAction(PrivateMethods)
- (NSDictionary *)_buildAppointmentDict:(NSDictionary *)_dateStruct
                           participants:(NSArray *)_participants
                          resourceNames:(NSArray *)_resourceNames
                        writeAccessList:(NSArray *)_writeAccessList
                             repetition:(NSDictionary *)_repetitionStruct
                                comment:(NSString *)_comment;
- (NSDictionary *)_buildFetchDict:(id)_from
                          endDate:(id)_to
                     participants:(NSArray *)_participants
                    resourceNames:(NSArray *)_resourceNames
                 appointmentTypes:(NSArray *)_aptTypes
                            hints:(NSDictionary *)_hints;
- (NSArray *)_buildAppointments:(NSArray *)_apts;
- (NSArray *)_buildParticipants:(NSArray *)_parts;
- (NSArray *)_aptFetchAttributes;
- (NSTimeZone *)timeZone;
- (NSDictionary *)_aptForId:(NSString *)_id;
- (id)_aptEOForId:(NSString *)_id;
- (NSArray *)_aptEOsForGIDs:(NSArray *)_gids;
- (NSArray *)_aptsForGIDs:(NSArray *)_gids;
- (NSArray *)_aptsForGIDs:(NSArray *)_gids hints:(NSDictionary *)_hints;
- (void)_ensureCurrentTransactionIsCommitted;
- (NSDictionary *)_buildBasicApt:(id)_apt;
- (NSDictionary *)_buildRepetitionDict:(id)_apt;
@end /* SkyAptAction(PrivateMethods) */

@interface SkyAptAction(AppointmentBindings)
- (NSDictionary *)bindingsForAppointment:(id)_date;
@end /* SkyAptAction(AppointmentBindings) */

@interface SkyAptAction(Logging)
- (BOOL)_addLog:(NSString *)_logText
         action:(NSString *)_action
         toApId:(NSNumber *)_oid;
@end /* SkyAptAction(Logging) */


@interface SkyAptAction(Conflicts)
- (NSArray *)conflictGIDsForAppointment:(id)_apt;
@end /* SkyAptAction(Logging) */

@class ICalVEvent;

@interface SkyAptAction(ICal)
- (id)updateAppointmentsFromICalEvents:(NSArray *)_events;
- (id)updateAppointmentFromICalEvent:(ICalVEvent *)_event;
- (id)updateAppointment:(id)_apt
          fromICalEvent:(ICalVEvent *)_event;
- (id)createAppointmentFromICalEvent:(ICalVEvent *)_event;
- (id)createAppointmentFromICalEvent:(ICalVEvent *)_event
                             aptType:(NSString *)_aptType;
@end /* SkyAptAction(ICal) */

#endif /* __skyaptd_SkyAptAction_H__ */
