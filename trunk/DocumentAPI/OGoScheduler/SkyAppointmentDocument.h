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

#ifndef __OGoScheduler_SkyAppointmentDocument_H_
#define __OGoScheduler_SkyAppointmentDocument_H_

#include <OGoDocuments/SkyDocument.h>

@class NSArray, NSNumber, NSString, NSCalendarDate;
@class EODataSource, EOGlobalID;

@interface SkyAppointmentDocument : SkyDocument
{
  EODataSource   *dataSource;
  EOGlobalID     *globalID;
  
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSCalendarDate *cycleEndDate;
  NSString       *title;
  NSString       *location;
  NSString       *type;    // repetition type
  NSString       *aptType; // appointment type

  NSNumber       *objectVersion;
  NSNumber       *parentDateId;
  SkyAppointmentDocument *parentDate;
  SkyDocument    *owner;
  NSString       *comment;
  NSArray        *participants;

  NSNumber       *notificationTime;
  NSString       *resourceNames;
  NSString       *permissions;

  EOGlobalID     *ownerGID;

  NSString       *writeAccessList;
  NSArray        *writeAccessMembers;
  id             accessTeamId;

  BOOL           saveCycles; // Default: YES
  
  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
}

- (id)initWithEO:(id)_obj globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds;
- (id)initWithEO:(id)_appointment dataSource:(EODataSource *)_ds;

- (void)invalidate;
- (BOOL)isValid;

/* attributes */

- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)isComplete;

/* operations */

- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;

/* change 'saveCycles'-Flag */
- (void)setSaveCycles:(BOOL)_flag;
- (BOOL)saveCycles;

/* context */

- (id)context;

/* attributes */

- (void)setStartDate:(NSCalendarDate *)_startDate;
- (NSCalendarDate *)startDate;

- (void)setEndDate:(NSCalendarDate *)_endDate;
- (NSCalendarDate *)endDate;

- (void)setCycleEndDate:(NSCalendarDate *)_endDate;
- (NSCalendarDate *)cycleEndDate;

- (void)setTitle:(NSString *)_title;
- (NSString *)title;

- (void)setLocation:(NSString *)_location;
- (NSString *)location;

- (void)setType:(NSString *)_type;
- (NSString *)type;

- (void)setAptType:(NSString *)_aptType;
- (NSString *)aptType;

- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

- (void)setOwner:(SkyDocument *)_owner;
- (SkyDocument *)owner;
- (EOGlobalID *)ownerGID;

- (void)setParticipants:(NSArray *)_participants;
- (NSArray *)participants;

- (void)setNotificationTime:(NSNumber *)_notificationTime;
- (NSNumber *)notificationTime;

- (void)setResourceNames:(NSString *)_names;
- (NSString *)resourceNames;

- (NSNumber *)objectVersion;

- (void)setParentDateId:(NSNumber *)_parentDateId;
- (NSNumber *)parentDateId;
- (BOOL)hasParentDate;
- (SkyAppointmentDocument *)parentDate;

- (NSString *)permissions;

- (void)setWriteAccess:(NSArray *)_accessIds;
- (NSArray *)writeAccess;
- (void)setWriteAccessList:(NSString *)_writeAccessList;
- (NSString *)writeAccessList;
- (NSArray *)writeAccessMembers;

- (id)accessTeamId;
- (void)setAccessTeamId:(id)_teamId;

- (id)asDict;
- (EODataSource *)dataSource;

@end

#include <OGoDocuments/SkyDocumentType.h>

@interface SkyAppointmentDocumentType : SkyDocumentType
@end /* SkyAppointmentDocumentType */


#endif /* __OGoScheduler_SkyAppointmentDocument_H_ */
