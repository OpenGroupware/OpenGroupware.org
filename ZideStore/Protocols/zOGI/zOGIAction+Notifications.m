/*
  Copyright (C) 2006-2007 Whitemice Consulting

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
#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Appointment.h"
#include "zOGIAction+Notifications.h"

@implementation zOGIAction(Notifications)

- (NSArray *)_getNotifications:(id)_start until:(id)_end withFlags:(id)_flags {
  NSCalendarDate  *notifyDate, *startDate;
  NSEnumerator   *dateEnumerator, *participantEnumerator;
  id              date, args, participant;
  NSArray        *dates, *gids, *participants;
  NSMutableArray *results;
  int             notifyTime;
  EOQualifier    *filter;
  
  args = [NSMutableDictionary dictionaryWithCapacity:2];
  [args takeValue:_start forKey:@"fromDate"];
  [args takeValue:_end forKey:@"toDate"];
  gids = [[self getCTX] runCommand:@"appointment::query" arguments:args];
  /* If there are no appointments bail out */
  if ([gids count] == 0)
    return [NSArray arrayWithObjects:nil];

  /* Get appointments */
  dates = [self _getUnrenderedDatesForKeys:gids];
  /* Filter out appointments not set to do notification */
  filter =  [EOQualifier qualifierWithQualifierFormat:
                         @"(NOT ((%@ = %@) OR "
                         @"(%@ = 0)))",
                         @"notificationTime", [EONull null],
                         @"notificationTime"];
  dates = [dates filteredArrayUsingQualifier:filter];
  if ([self isDebug])
    [self logWithFormat:@"filtered down to %d dates for notification",
       [dates count]];
  /* Bail out if there are no qualifying appointments */
  if ([dates count] == 0)
    return [NSArray arrayWithObjects:nil];

  results = [NSMutableArray arrayWithCapacity:128];
  dateEnumerator = [dates objectEnumerator];
  while ((date = [dateEnumerator nextObject]) != nil) {
    startDate = [date objectForKey:@"startDate"];
    notifyTime = [[date objectForKey:@"notificationTime"] intValue];
    if (notifyTime > 0) {
      /* Check if notification is due */
      notifyDate = [startDate dateByAddingYears:0
                                         months:0
                                           days:0
                                          hours:0
                                        minutes:(notifyTime * -1)
                                        seconds:0];
      if ([[[NSDate date] earlierDate:notifyDate] isEqual:notifyDate]) {
        /* qualifies for notification, add to result */
        if ([self isDebug])
          [self logWithFormat:@"date %@ qualified for notification @ %@",
             [date objectForKey:@"dateId"],
             notifyDate];
        /* Create notifications */
        participants = [self _retrieveParticipantsForNotification:date];
        if ([self isDebug])
          [self logWithFormat:@"found %d participants to notify for date %@",
             [participants count],
             [date objectForKey:@"dateId"]];
        participantEnumerator = [participants objectEnumerator];
        while ((participant = [participantEnumerator nextObject])) {
          [results addObject:[self _renderNotification:participant 
                                                inDate:date]];
        }
        [self _clearNotificationTime:date];
      } else {
          /* notification time still in future, disqualified */
          if ([self isDebug])
            [self logWithFormat:@"date %@ disqualified from notification",
               [date objectForKey:@"dateId"]];
        }
    } else [self warnWithFormat:@"date %s had sub-zero notify time value",
           [date objectForKey:@"dateId"]];
  } /* end loop-dates */
  /*
      Get resource notifications
  dates = [self _getUnrenderedDatesForKeys:gids];
  filter = [EOQualifier qualifierWithQualifierFormat:
                        @"NOT ((resourceNames = %@) OR "
                        @"(resourceNames = ''))", [EONull null]];
  dates = [dates filteredArrayUsingQualifier:filter];
   */

  if ([_flags objectForKey:@"noCommit"] != nil) {
    /* database commit has been disabled by the noCommit flag */
    if ([self isDebug])
      [self logWithFormat:@"commit disabled via flag!"];
  } else {
      /* committing database transaction */
      [[self getCTX] commit];
    }

  return results;
}

- (NSArray *)_retrieveParticipantsForNotification:(id)_date {
  NSArray             *list;
  /* Used to expand teams */
  id                   team, member, tmp;
  NSArray             *members;
  NSMutableArray      *teams;
  NSEnumerator        *memberEnumerator;
  /* Uset to process participants */
  id                   participant;
  NSMutableDictionary *participants;
  NSEnumerator        *participantEnumerator;

  /* Retrieve participants from Logic */
  list = [[self getCTX] runCommand:@"appointment::list-participants",
             @"gid", [self _getEOForPKey:[_date valueForKey:@"dateId"]],
             @"attributes", 
                 [NSArray arrayWithObjects: @"role", @"companyId",
                    @"partStatus", @"comment", @"rsvp", 
                    @"team.isTeam", @"team.companyId",
                    @"person.extendedAttributes",
                    @"person.imAddress", @"person.isAccount",
                    @"dateId", 
                    nil],
             nil];

  /* If appointment has not participants then bail out */
  if ([list count] == 0) {
    [self warnWithFormat:@"date %@ has no participants to notify",
       [_date objectForKey:@"dateId"]];
    return [NSArray arrayWithObjects:nil];
  } else if ([self isDebug])
      [self logWithFormat:@"found %d participants in appointment list",
         [list count]];

  /* Process participants, queuing teams for expansion; we completely 
     process individual participants first because those entries can
     have role/status/comment/etc... whereas participants from a team
     entry are always nude */
  teams = nil;
  participants = [NSMutableDictionary dictionaryWithCapacity:64];
  participantEnumerator = [list objectEnumerator];
  while ((participant = [participantEnumerator nextObject])) {
    if([[participant valueForKey:@"isTeam"] isNotNull]) {
      /* participant is a team */
      if (teams == nil)
        teams = [NSMutableArray arrayWithCapacity:16];
      [teams addObject:participant];
    } else {
        [participants setObject:participant 
                         forKey:[participant objectForKey:@"companyId"]];
      }
  } /* end while loop */

  /* process teams if any of participants where teams */
  if ([teams isNotNull]) {
    participantEnumerator = [teams objectEnumerator]; 
    while ((participant = [participantEnumerator nextObject])) {
      if ([self isDebug])
        [self logWithFormat:@"Expanding members of team %@",
           [participant objectForKey:@"companyId"]];
      /* get the team object */
      tmp = [self _getEOsForPKeys:[participant objectForKey:@"companyId"]];
      team = [[[self getCTX] runCommand:@"team::get-by-globalid",
                             @"gids", tmp,
                             nil] lastObject];
      if ([team isNotNull]) {
        /* get team members */
        members = [[self getCTX] runCommand:@"team::members",
                      @"team", team,
                      nil];
        if ([self isDebug])
          [self logWithFormat:@"found %d members for team %@",
             [members count],
             [participant objectForKey:@"companyId"]];
        /* loop members */
        memberEnumerator = [members objectEnumerator];
        while ((member = [memberEnumerator nextObject])) {
          /* if participant not already in dictionary, add, otherwise skip
             this supresses duplicate notifications */
          tmp = [participants objectForKey:[member objectForKey:@"companyId"]];
          if (tmp == nil)
            [participants setObject:member
                             forKey:[member objectForKey:@"companyId"]];
        }  /* end for loop of team members */
      } /* end if team isNotNull */
    } /* end while loop */
  } /* end if teams exist to expand */

  return [participants allValues];
} /* End _retrieveParticipantsForNotification */

/* Create the notification entry for the specified participant */
- (NSDictionary *)_renderNotification:(id)_participant inDate:(id)_date {
  NSMutableArray *emails;
  NSString       *status, *ccAddress;
  NSTimeZone     *timeZone;
  id              tmp;

  if ([self isDebug])
    [self logWithFormat:@"rendering notifaction to %@ for %@",
       [_participant valueForKey:@"companyId"],
       [_date valueForKey:@"dateId"]];

  /* make status string */
  if ([[_participant valueForKey:@"partStatus"] isNotNull])
    status = [_participant valueForKey:@"partStatus"];
  else
    status = [NSString stringWithString:@"NEEDS-ACTION"];
  /* build array of e-mail addresses 
  TODO: Support additional type#3 XAs */
  emails = [NSMutableArray arrayWithCapacity:3];
  if ([[_participant valueForKey:@"email1"] isNotNull])
    [emails addObject:[_participant valueForKey:@"email1"]];
  if ([[_participant valueForKey:@"email2"] isNotNull])
    [emails addObject:[_participant valueForKey:@"email2"]];
  if ([[_participant valueForKey:@"email3"] isNotNull])
    [emails addObject:[_participant valueForKey:@"email3"]];
  /* get user's time zone */
  timeZone = nil;
  if ([[_participant valueForKey:@"isAccount"] isNotNull]) {
    if ([[_participant valueForKey:@"isAccount"] intValue] == 1) {
      tmp = [_participant valueForKey:@"companyId"];
      timeZone = [self _getTimeZoneForAccount:tmp];
      ccAddress = [self _getCCAddressForAccount:tmp];
      if ([ccAddress isNotNull]) {
        if ([ccAddress length] > 0) {
          [emails addObject:ccAddress];
        }
      }
    }
  }
  if (timeZone == nil)
    timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  return [NSDictionary dictionaryWithObjectsAndKeys:
            @"notification", @"entityName",
            @"Appointment", @"type",
            [_participant valueForKey:@"companyId"],
              @"notifyObjectId",
            @"Contact", @"notifyEntityName",
            status, @"status",
            [self NIL:[_participant valueForKey:@"comment"]], @"comment",
            [self ZERO:[_participant valueForKey:@"rsvp"]], @"rsvp",
            [_date valueForKey:@"dateId"], @"appointmentObjectId",
            [self NIL:[_participant valueForKey:@"imAddress"]],
               @"imAddress",
            [self ZERO:[_participant valueForKey:@"isAccount"]],
               @"isAccount",
            emails, @"email",
            [timeZone abbreviationForDate:[_date valueForKey:@"startDate"]], 
               @"startTimeZone",
            intObj([timeZone secondsFromGMTForDate:[_date valueForKey:@"startDate"]]),
               @"startOffsetFromGMT",
            [timeZone abbreviationForDate:[_date valueForKey:@"endDate"]], 
               @"endTimeZone",
            intObj([timeZone secondsFromGMTForDate:[_date valueForKey:@"endDate"]]),
               @"endOffsetFromGMT",
            nil];
} /* End _renderNotification */

- (void)_clearNotificationTime:(id)_date {
  [[self getCTX] runCommand:@"appointment::set",
      @"dateId", [_date objectForKey:@"dateId"],
      @"notificationTime", [EONull null],
      @"setAllCyclic", [NSNumber numberWithBool:NO],
      nil];
} /* End _clearNotificationTime */

@end /* End zOGIAction(Notifications) */
