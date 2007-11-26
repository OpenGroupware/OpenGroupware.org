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
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Resource.h"
#include "zOGIAction+Team.h"
#include "zOGIAction+Appointment.h"
#include "zOGIAction+AppointmentConflicts.h"

@implementation zOGIAction(AppointmentConflicts)

-(id)_getConflictsForDate:(id)_appointment {
  NSArray         *conflictAttrs;
  id               conflictList;

  /* TODO: Do we really need to get the conflict attirbutes from defaults? */
  conflictAttrs = [[[self _getDefaults]
                        arrayForKey:@"schedulerconflicts_conflictkeys"] copy];  
  conflictList = [[self getCTX] runCommand:@"appointment::conflicts",
                                           @"appointment", _appointment,
                                           @"fetchConflictInfo", @"YES",
                                           @"fetchGlobalIDs", @"YES",  
                                           @"conflictInfoAttributes", 
                                              conflictAttrs,
                                nil];
  return conflictList;
} /* end _getConflictsForDate */

/* Create an array of conflicts with the provided appointment */
-(NSArray *)_renderConflictsForDate:(id)_eo {
  NSArray               *aptAttrs      = nil;
  NSMutableDictionary   *renderedConflict;
  NSDictionary          *conflict;
  NSDictionary          *conflictDates;
  NSDictionary          *conflictDate;
  NSMutableArray        *conflicts;
  NSEnumerator          *dateEnumerator;
  NSEnumerator          *conflictEnumerator;
  id                    resource;

  /* Bail out if conflict detection is disabled */
  if ([[_eo objectForKey:@"isConflictDisabled"] isNotNull])
    if ([[_eo objectForKey:@"isConflictDisabled"] intValue])
      return [NSArray arrayWithObjects:nil];
    
  /* Get required bits from user defaults */
  aptAttrs = [[[[self getCTX] userDefaults]
                   arrayForKey:@"schedulerconflicts_fetchkeys"] copy];

  /* Getting conflict info */
  conflictDates = [self _getConflictsForDate:_eo];

  /* Initialize array of conflicts */
  conflicts = [NSMutableArray arrayWithCapacity:[conflictDates count]];

  /* Initialize dictionary for results with summary
     of conflicting appointments */
  dateEnumerator = [[conflictDates allKeys] objectEnumerator];
  while ((conflictDate = [dateEnumerator nextObject]) != nil) {
    conflictEnumerator = [[conflictDates objectForKey:conflictDate] 
                             objectEnumerator];
      while ((conflict = [conflictEnumerator nextObject]) != nil) {
        renderedConflict = [NSMutableDictionary dictionaryWithCapacity:16];
        [renderedConflict 
           setObject:@"appointmentConflict" forKey:@"entityName"];
        [renderedConflict setObject:[self _getPKeyForEO:(id)conflictDate]
                             forKey:@"appointmentObjectId"];
        [renderedConflict setObject:[conflict objectForKey:@"partStatus"]
                             forKey:@"status"];
        if([conflict objectForKey:@"companyId"] == nil) {
          /* resource conflict */
          [renderedConflict setObject:@"Resource" 
                               forKey:@"conflictingEntityName"];
 
          resource = [self _getResourceByName:[conflict
                                             objectForKey:@"resourceName"]];
          if (resource == nil) {
             [self warnWithFormat:@"could not resolve pkey for resource %@",
                [conflict objectForKey:@"resourceName"]];
          } else {
              [renderedConflict 
                 setObject:[resource valueForKey:@"appointmentResourceId"]
                    forKey:@"conflictingObjectId"];
            } 
        } else {
           /* contact or team conflict */
           [renderedConflict setObject:[conflict objectForKey:@"companyId"]
                                forKey:@"conflictingObjectId"];
           if([conflict objectForKey:@"isTeam"] == nil)
             [renderedConflict setObject:@"Contact" 
                                  forKey:@"conflictingEntityName"];
             else [renderedConflict setObject:@"Team" 
                                       forKey:@"conflictingEntityName"];
          }
        [conflicts addObject:renderedConflict];
      } /* end conflicting-entity-while-loop */
  } /* end conflicted-appointment-while-loop */
  return conflicts;
} /* end _renderConflictsForDate */

@end /* zOGIAction(AppointmentConflicts */
