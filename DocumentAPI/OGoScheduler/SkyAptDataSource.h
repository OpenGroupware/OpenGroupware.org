/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#ifndef __SkyAptDataSource_H__
#define __SkyAptDataSource_H__

#import <Foundation/NSCalendarDate.h>
#import <EOControl/EODataSource.h>
#import <NGExtensions/EODataSource+NGExtensions.h>

#define SkyUpdatedAppointmentNotification @"SkyUpdatedAppointmentNotification"
#define SkyDeletedAppointmentNotification @"SkyDeletedAppointmentNotification"
#define SkyNewAppointmentNotification     @"SkyNewAppointmentNotification"

@class NSString, SkyAppointmentQualifier, NSCalendarDate;
@class NSTimeZone;
@class LSCommandContext;

/*
  Input:

    EOFetchSpecification
      SkyAppointmentQualifier
      hints: attributeKeys => attributes
             SkyReturnDocs = YesNumber|NoNumber (default is NO)
             FetchGIDs     = date GlobalIDs to fetch 

  Notifications

    SkyDataSourceWillClear
    SkyDataSourceDidFetch

*/

@interface SkyAptDataSource : EODataSource
{
  /* execution context */
  LSCommandContext *lso;
  
  /* query qualifier */
  SkyAppointmentQualifier *q;
  NSArray        *attributes;
  NSArray        *sortOrderings;

  /* result cache */
  NSArray *objects;
  
  BOOL isResCategorySelected;
  BOOL objectsFetched;
  BOOL returnDocuments;

  NSArray *gidsToFetch;
}

- (void)setContext:(id)_ctx;
- (id)context;

- (NSTimeZone *)timeZone;
- (NSArray *)companies;
- (NSArray *)resources;
- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;

- (void)setIsResCategorySelected:(BOOL)_flag;
- (BOOL)isResCategorySelected;

- (NSArray *)appointmentsWithStartDate:(NSCalendarDate *)_start
  andInterval:(NSTimeInterval)_interval;

@end

#endif /* __SkyAptDataSource_H__ */
