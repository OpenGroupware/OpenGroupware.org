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

#ifndef __skyaptd_SkyAppointmentResourceCache_H__
#define __skyaptd_SkyAppointmentResourceCache_H__

#import <Foundation/NSObject.h>

@class NSMutableDictionary, NSMutableArray;
@class NSDate, NSNumber;
@class EOGlobalID, EODataSource;

/*
  the SkyAppointmentResourceCache caches appointmentResources for the
  whole database, which should not be as much. since this it only needs
  information to connect the database which is taken from the command
  context. there is NO access checking wether the user, which is unknown
  to this cache, has access to list/insert/update or delete an
  appointmentresource.

  BIG PROBLEM:
  before cache is deallocated, changes must be overtaken
  for this a commandcontext is needed!

*/

@interface SkyAppointmentResourceCache : NSObject
{
  NSMutableDictionary *map;       // mapping appointmentResourceId to dicts
  NSMutableArray      *removed;   // contains removed dicts
  NSMutableArray      *changed;   // contains changed ids

  NSDate  *fetchDate;    // date of last update
  int     updateTimeout; // seconds to update cache and write changed data
                         // default: 1800 (30 minutes)
}

+ (SkyAppointmentResourceCache *)cacheWithCommandContext:(id)_context;

- (void)checkUpdateWithContext:(id)_context; // update if timeout reached
- (void)flushWithContext:(id)_context;


- (NSArray *)allObjectsWithContext:(id)_context;
- (NSArray *)allCategoriesWithContext:(id)_context;
- (BOOL)insertAppointmentResource:(NSString *)_name
                         category:(NSString *)_category
                            email:(NSString *)_email
                     emailSubject:(NSString *)_emailSubject
                 notificationTime:(NSNumber *)_number
                          context:(id)_context;
- (BOOL)updateAppointmentResource:(EOGlobalID *)_gid
                         category:(NSString *)_category
                            email:(NSString *)_email
                     emailSubject:(NSString *)_emailSubject
                 notificationTime:(NSNumber *)_number
                          context:(id)_context;
- (BOOL)deleteAppointmentResource:(EOGlobalID *)_gid
                          context:(id)_context;

@end /* SkyAppointmentResourceCache */

#endif /* __skyaptd_SkyAppointmentResourceCache_H__ */
