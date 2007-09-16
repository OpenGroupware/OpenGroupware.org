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
#include "zOGIAction+Appointment.h"

@implementation zOGIAction(Notifications)

- (NSArray *)_getNotifications:(id)_start until:(id)_end {
  NSCalendarDate  *notifyDate, *startDate;
  NSEnumerator   *dateEnumerator, *participantEnumerator;
  id              date, args, participant;
  NSArray        *dates, *gids, *participants;
  NSMutableArray *emails, *results;
  int             notifyTime;
  EOQualifier    *filter;
  NSString       *status;
  
  results = [NSMutableArray arrayWithCapacity:128];
  args = [NSMutableDictionary dictionaryWithCapacity:2];
  [args takeValue:_start forKey:@"fromDate"];
  [args takeValue:_end forKey:@"toDate"];
  gids = [[self getCTX] runCommand:@"appointment::query" arguments:args];
  /*
       Get appointment notifications 
   */
  dates = [self _getUnrenderedDatesForKeys:gids];
  filter =  [EOQualifier qualifierWithQualifierFormat:
                         @"(NOT ((%@ = %@) OR "
                         @"(%@ = 0)))",
                         @"notificationTime", [EONull null],
                         @"notificationTime"];
  dates = [dates filteredArrayUsingQualifier:filter];
  if ([self isDebug])
    [self logWithFormat:@"filtering %d dates for notification",
       [dates count]];
  dateEnumerator = [dates objectEnumerator];
  while ((date = [dateEnumerator nextObject]) != nil) {
    startDate = [date objectForKey:@"startDate"];
    notifyTime = [[date objectForKey:@"notificationTime"] intValue];
    if (notifyTime > 0) {
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
        participants = 
          [[self getCTX] runCommand:@"appointment::list-participants",
                         @"gid", [self _getEOForPKey:[date valueForKey:@"dateId"]],
                         @"attributes", 
                             [NSArray arrayWithObjects: @"role", @"companyId",
                                @"partStatus", @"comment", @"rsvp", @"team.isTeam",
                                @"team.email", @"team.description", @"team.companyId",
                                @"person.extendedAttributes",
                                @"dateId", 
                                nil],
                         nil];
        if ([participants count] == 0) {
          [self warnWithFormat:@"date %@ has no participants to notify",
             [date objectForKey:@"dateId"]];
        } else {
            participantEnumerator = [participants objectEnumerator];
            while ((participant = [participantEnumerator nextObject])) {
              if([participant valueForKey:@"isTeam"] == nil) {
                /* Participant is a contact */
                /* make status string */
                if ([participant valueForKey:@"partStatus"] == nil)
                  status = [NSString stringWithString:@"NEEDS-ACTION"];
                else
                  status = [participant valueForKey:@"partStatus"];
                /* build array of e-mail addresses 
                   TODO: Support additional type#3 XAs */
                emails = [NSMutableArray arrayWithCapacity:3];
                if ([participant valueForKey:@"email1"] != nil)
                  [emails addObject:[participant valueForKey:@"email1"]];
                if ([participant valueForKey:@"email2"] != nil)
                  [emails addObject:[participant valueForKey:@"email2"]];
                if ([participant valueForKey:@"email3"] != nil)
                  [emails addObject:[participant valueForKey:@"email3"]];
                /* render contact notification */
                [results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                   @"notification", @"entityName",
                   @"Appointment", @"type",
                   [participant valueForKey:@"companyId"],
                      @"notifyObjectId",
                   @"Contact", @"notifyEntityName",
                   status, @"status",
                   [self NIL:[participant valueForKey:@"comment"]], @"comment",
                   [self ZERO:[participant valueForKey:@"rsvp"]], @"rsvp",
                   [date valueForKey:@"dateId"], @"appointmentObjectId",
                   [self NIL:[participant valueForKey:@"imAddress"]],
                      @"imAddress",
                   [self ZERO:[participant valueForKey:@"isAccount"]],
                      @"isAccount",
                   emails, @"email",
                   nil]];
                /* end render contact notification */
              } else {
                  /* participant is a team */
                  if ([participant valueForKey:@"email"] != nil)
                    emails = [NSConcreteEmptyArray new];
                  else
                    emails = [NSArray arrayWithObject:
                                [participant valueForKey:@"email"]];
                  /* render team/date notification */
                  [results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                     @"notification", @"entityName",
                     @"Appointment", @"type",
                     [participant valueForKey:@"companyId"],
                        @"notifyObjectId",
                     @"Team", @"notifyEntityName",
                     @"N/A", @"status",
                     @"N/A", @"comment",
                     intObj(0), @"rsvp", 
                     [participant valueForKey:@"role"], @"role",
                     [date valueForKey:@"dateId"], @"appointmentObjectId",
                     @"", @"imAddress",
                     intObj(1), @"isAccount",
                     emails, @"email",
                     nil]];
                  /* end render team notification */
                 }
            } /* while loop-participants */
          } /* end else-date-has-participants */
        [[self getCTX] runCommand:@"appointment::set",
                         @"dateId", [date objectForKey:@"dateId"],
                         @"notificationTime", [EONull null],
                         @"setAllCyclic", [NSNumber numberWithBool:NO],
                         nil];
      } else {
          /* notfication time still in future, disqualified */
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

  [[self getCTX] commit];
  return results;
}

@end /* End zOGIAction(Notifications) */
