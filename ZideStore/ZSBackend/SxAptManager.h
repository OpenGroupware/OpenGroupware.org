/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#ifndef __Backend_SxAptManager_H__
#define __Backend_SxAptManager_H__

#include <ZSBackend/SxBackendManager.h>

/*
  SxAptManager, SxAptSetIdentifier
  
  Manage the appointment backend. Identify folder sets using the
  set-identifier.
*/

@class NSString, NSDate, NSArray, NSDictionary, NSMutableDictionary;
@class NSCalendarDate, NSException, NSEnumerator;

@interface SxAptSetIdentifier : NSObject < NSCopying >
{
  NSString *group;
  BOOL     overview;
}

+ (id)privateAptSet;
+ (id)privateOverviewSet;
+ (id)aptSetForGroup:(NSString *)_group;
+ (id)overviewSetForGroup:(NSString *)_group;

/* accessors */

- (BOOL)isOverviewSet;
- (NSString *)group;

/* filename key */

- (NSString *)flatKey; // TODO: deprecated ?

/* caching */

- (NSString *)cachePrefixInContext:(id)_ctx;

@end

@interface SxAptManager : SxBackendManager
{
  NSMutableDictionary *setIdToHandler;
}

/* accessors */

- (NSCalendarDate *)defaultStartDate;
- (NSCalendarDate *)defaultEndDate;

/* operations */

- (NSArray *)freeBusyDataForUser:(id)_user
  from:(NSDate *)_from to:(NSDate *)_to;

/* the new set-queries */

- (NSArray *)gidsOfAppointmentSet:(SxAptSetIdentifier *)_set;
- (NSArray *)gidsOfAppointmentSet:(SxAptSetIdentifier *)_set
  from:(NSDate *)_from to:(NSDate *)_to;

// returns array of dict with "pkey" and "lastmodified"
- (NSArray *)pkeysAndModDatesOfSet:(SxAptSetIdentifier *)_sid
  from:(NSDate *)_from to:(NSDate *)_to;

// returns: title, location, end/startdate, sensititivty
- (NSArray *)coreInfoForAppointmentSet:(SxAptSetIdentifier *)_set;
- (NSArray *)coreInfoOfAppointmentsWithGIDs:(NSArray *)_gids 
  inSet:(SxAptSetIdentifier *)_set;

// returns: full info for appointment
- (NSDictionary *)zlAppointmentWithID:(id)_aid;
- (NSArray *)zlAppointmentsWithIDs:(NSArray *)_ids;

// Returns a string in the format: (id:version\n)*
- (NSString *)idsAndVersionsCSVForAppointmentSet:(SxAptSetIdentifier *)_set;
- (int)generationOfAppointmentSet:(SxAptSetIdentifier *)_set;
- (int)countOfAppointmentSet:(SxAptSetIdentifier *)_set;

@end

@interface SxAptManager(iCal)

// returns enum of dicts with "pkey", "lastmodified" and "iCalData"
- (NSEnumerator *)pkeysAndModDatesAndICalsForGlobalIDs:(NSArray *)_gids;
- (NSEnumerator *)pkeysAndModDatesAndICalsForGlobalIDs:(NSArray *)_gids
  timezone:(id)_tz;

// fetches participants for appointments, including ical attributes
- (void)fetchParticipantsForAppointments:(NSArray *)_apts;

- (id)putVEvents:(NSArray *)_events;
- (id)putVEvents:(NSArray *)_events
  inAptSet:(SxAptSetIdentifier *)_aptSet;

@end

/*
  The following is not really clean, since it uses the EO attributes
  as keys ... It should be specified, what exactly is given in the
  dictionaries.
*/

@interface SxAptManager(EOChanges)

- (id)updateRecordWithPrimaryKey:(NSNumber *)_key
  withEOChanges:(NSMutableDictionary *)_record log:(NSString *)_log;
- (id)createWithEOAttributes:(NSMutableDictionary *)_record 
  log:(NSString *)_log;
- (NSException *)deleteRecordWithPrimaryKey:(NSNumber *)_key;

- (id)eoForPrimaryKey:(NSNumber *)_key;

@end

#endif /* __Backend_SxAptManager_H__ */
