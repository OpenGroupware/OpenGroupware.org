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

#ifndef __LSWScheduler_LSWAppointmentEditor_H__
#define __LSWScheduler_LSWAppointmentEditor_H__

#include <OGoFoundation/LSWEditorPage.h>

/*
  LSWEditorPage
  
  This is the editor component for OGo appointments. Yes, it is indeed quite
  bloated and needs a replacement ;-)
*/

@class NSString, NSArray, NSMutableArray, NSUserDefaults, NSTimeZone;

@interface LSWAppointmentEditor : LSWEditorPage
{
@private
  id             item;       // non-retained
  id             enterprise; // non-retained
  NSArray        *accessTeams;
  id             selectedAccessTeam;
  id             searchTeam;
  NSString       *searchText;
  
  NSMutableArray *participants;
  NSArray        *selectedParticipants;
  
  NSMutableArray *accessMembers;
  NSArray        *selectedAccessMembers;

  NSUserDefaults *defaults;
  
  NSTimeZone     *timeZone;
  NSString       *comment;
  NSString       *startHour;
  NSString       *endHour;
  NSString       *startTime;
  NSString       *endTime;
  NSString       *startMinute;
  NSString       *endMinute;

  NSString       *notificationTime;
  NSString       *measure;           // (minutes, hours, days)
  NSString       *selectedMeasure;   // (minutes, hours, days)

  // preferences
  NSString       *timeInputType;
  
  // resources
  NSMutableArray *resources;
  NSArray        *moreResources;  

  //NSArray        *aptTypes;
  
  // move fields
  char moveAmount;
  char moveUnit;      // 0=days, 1=weeks, 2=months
  char moveDirection; // 0=forward, 1=backward
  
  struct {
    int ignoreConflicts:1;
    int deleteAllCyclic:1;
    int isSchedulerClassicEnabled:1;
    int isMailEnabled:1;
    int isParticipantsClicked:1;
    int isResourceClicked:1;
    int isAccessClicked:1;
    int isAllDayEvent:1;
    int isAllDayEventSetup:1;
    int reserved:23;
  } aeFlags;
}

// move accessors

- (void)setMoveAmount:(char)_amount;
- (char)moveAmount;
- (void)setMoveUnit:(char)_unit;
- (char)moveUnit;
- (void)setMoveDirection:(char)_direction;
- (char)moveDirection;
- (void)setNotificationTime:(NSString *)_time;
- (void)setSelectedMeasure:(NSString *)_measure;
- (void)setIgnoreConflicts:(BOOL)_flag;
- (BOOL)ignoreConflicts;
- (void)setResourceStrings:(id)_id;
- (void)setSelectedParticipants:(NSArray *)_array;
- (void)setSelectedAccessMembers:(NSArray *)_array;

/* defaults */

- (NSArray *)defaultWriteAccessAccounts;
- (NSArray *)defaultWriteAccessTeams;

@end

#endif /* __LSWScheduler_LSWAppointmentEditor_Fetches_H__ */
