/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __Appointments_SxAppointment_H__
#define __Appointments_SxAppointment_H__

#include <ZSFrontend/SxObject.h>

/*
  SxAppointment
  
  A controller for an individual appointment. Mostly used for creation,
  modification and deletion of appointments.
  
  Maybe ZideLook will query them individually too.
*/

@class NSNumber, NSArray;
@class EOKeyGlobalID;
@class SxAptManager;

@interface SxAppointment : SxObject
{
  NSString *group;
}

- (EOKeyGlobalID *)globalIDOfGroupInContext:(id)_ctx;
- (NSNumber *)pkeyOfGroupInContext:(id)_ctx;
- (id)groupInContext:(id)_ctx; // fetches team eo

- (SxAptManager *)aptManagerInContext:(id)_ctx;

- (BOOL)isInOverviewFolder;

- (void)reloadObjectInContext:(id)_ctx;

+ (BOOL)logAptChange;

@end

@interface SxAppointment(Participants)
- (NSArray *)fetchParticipantsForPersons:(NSArray *)_persons
  inContext:(id)_ctx;
- (NSArray *)checkChangedParticipants:(NSArray *)_newParts
  forOldParticipants:(NSArray *)_oldParts
  inContext:(id)_ctx;

+ (BOOL)usePKeyEmails;
+ (NSString *)pKeyEmailForParticipant:(id)_participant;
+ (NSString *)emailForParticipant:(id)_participant;
+ (NSNumber *)pKeyForPKeyEmail:(NSString *)_email isTeam:(BOOL *)_isTeamFlag;
+ (EOGlobalID *)gidForPKeyEmail:(NSString *)_email;
@end /* SxAppointment(Participants) */

#endif /* __Appointments_SxAppointment_H__ */
