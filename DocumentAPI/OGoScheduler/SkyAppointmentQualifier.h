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

#ifndef __SkyAppointmentQualifier__
#define __SkyAppointmentQualifier__

#import <EOControl/EOQualifier.h>

@class NSCalendarDate, NSTimeZone;

@interface SkyAppointmentQualifier : EOQualifier
{
@protected
  NSCalendarDate *startDate; // startdate
  NSCalendarDate *endDate;   // enddate
  NSTimeZone     *timeZone;  // timezone
  NSArray        *companies; // gids of companies
  NSArray        *resources; // Array of strings (resourceNames)
  BOOL           onlyNotified; // fetch only notified
  BOOL           onlyResourceApts; // fetch only resource appointments

  NSArray        *aptTypes;   // default: nil (nil or empty means fetch all)
  NSArray        *personIds;
}

- (void)setStartDate:(NSCalendarDate *)_startDate;
- (NSCalendarDate *)startDate;

- (void)setEndDate:(NSCalendarDate *)_endDate;
- (NSCalendarDate *)endDate;

- (void)setTimeZone:(NSTimeZone *)_tz;
- (NSTimeZone *)timeZone;

- (void)setCompanies:(NSArray *)_companies;
- (NSArray *)companies;

- (void)setResources:(NSArray *)_resources;
- (NSArray *)resources;

- (void)setOnlyNotified:(BOOL)_flag;
- (BOOL)onlyNotified;

- (void)setOnlyResourceApts:(BOOL)_flag;
- (BOOL)onlyResourceApts;

- (void)setAptTypes:(NSArray *)_aptTypes;
- (NSArray *)aptTypes;

- (void)setPersonIds:(NSArray *)_p;
- (NSArray *)personIds;
- (NSArray *)personGIDs;

@end

#endif /* __SkyAppointmentQualifier__ */
