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
// $Id$

#ifndef __SkyInlineAptDataSourceView__
#define __SkyInlineAptDataSourceView__

#include <OGoFoundation/LSWComponent.h>

@class NSCalendarDate, NSFormatter;

@interface SkyInlineAptDataSourceView : LSWComponent
{
@protected
  id             dataSource;
  id             cacheDS;
  id             holidays;
  BOOL           printMode;
  BOOL           hidePropAndNew;
  NSString*      yearDirectActionName;
  NSString*      monthDirectActionName;
  NSString*      weekDirectActionName;
  NSString*      dayDirectActionName;
  
  // transient  
  id             appointment;
  int            index;
  NSCalendarDate *currentDate;
  NSArray        *sortOrderings;
  NSCalendarDate *browserDate;
  NSArray        *allDayApts; // infos, additionaly to holidays
  
  // browser
  BOOL           browserDateInMonth;
  BOOL           showFullNames;
  BOOL           showAMPMDates;
  NSArray        *aptTypes;
}

/* accessors */
- (void)setDataSource:(id)_ds;
- (id)dataSource;
- (id)cacheDataSource;

- (void)setHolidays:(id)_days;
- (id)holidays;

- (void)setPrintMode:(BOOL)_flag;
- (BOOL)printMode;

- (void)setAppointment:(id)_apt;
- (id)appointment;

- (void)setIndex:(int)_index;
- (int)index;

- (void)setCurrentDate:(NSCalendarDate *)_date;
- (NSCalendarDate *)currentDate;

- (NSArray *)sortOrderings;
- (BOOL)showFullNames;
- (BOOL)showAMPMDates;

/* additional */
- (BOOL)appointmentViewAccessAllowed;
- (BOOL)isAppointmentDraggable;
- (BOOL)isPrivateAppointment;

/* SkyAppointmentFormatter */
- (NSFormatter *)aptTimeFormatter;
- (NSFormatter *)aptTitleFormatter;
- (NSFormatter *)aptParticipantFormatter;
- (NSFormatter *)aptFullInfoFormatter;
- (NSString *)fullInfoForApt;
- (NSCalendarDate *)referenceDateForFormatter; // <- overwrite in subclasses
- (NSString *)shortTextForApt;
/* apt type stuff */
- (NSString *)dateCellIcon;
- (NSString *)aptTypeLabel;

/* companyListing for print-mode */
- (NSString *)companyName;
  
/* day info support (holidays) */
- (NSString *)holidayInfo;
- (BOOL)hasCurrentDayInfo;

- (BOOL)isThisAllDayApt:(id)_apt;

// dnd support
- (NSCalendarDate *)droppedAptDateWithOldDate:(NSCalendarDate *)_date;

// action
- (id)personWasDropped:(id)_person;
- (id)droppedAppointment;

@end

#endif
