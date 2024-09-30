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

#include <OGoFoundation/OGoComponent.h>

/*
  SkyAptDateSelection
  
  This component is used in LSWAppointmentEditor for editing the startdate and
  enddate fields.

  Note that it expects a <table> tag around itself (it creates a set of <tr>
  tags).
*/

@interface SkyAptDateSelection : OGoComponent
{
  // start
  NSString *startDate;
  NSString *startHour;
  NSString *startMinute;
  NSString *startTime;
  // end
  NSString *endDate;
  NSString *endHour;
  NSString *endMinute;
  NSString *endTime;
  // all day?
  BOOL isAllDayEvent;
  // inputType
  NSString *timeInputType;
  NSString *formName;
  BOOL     isNewOrNotCyclic;

  BOOL     useAMPMDates;
  BOOL     startAM;
  BOOL     endAM;
  id       item;
}

@end /* SkyAptDateSelection */

#include "common.h"

@implementation SkyAptDateSelection

- (void)dealloc {
  [self->startDate   release];
  [self->startHour   release];
  [self->startMinute release];
  [self->startTime   release];
  [self->endDate     release];
  [self->endHour     release];
  [self->endMinute   release];
  [self->endTime     release];
  
  [self->timeInputType release];
  [self->formName      release];
  [super dealloc];
}

/* accessors */

- (void)setUseAMPMDates:(BOOL)_flag {
  self->useAMPMDates = _flag;
}
- (BOOL)useAMPMDates {
  return self->useAMPMDates;
}

- (BOOL)useExtraAMPMPopUp {
  // TODO: AM/PM is sometimes a user and sometimes a global default?
  static int useAMPMPopUp = -1;
  
  if (![self useAMPMDates]) return NO;
  
  if (useAMPMPopUp == -1) {
    useAMPMPopUp =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"scheduler_useAMPMButton"] ? 1 : 0;
  }

  return useAMPMPopUp ? YES : NO;
}

- (void)setStartDate:(NSString *)_date {
  ASSIGN(self->startDate,_date);
}
- (NSString *)startDate {
  return self->startDate;
}

- (void)setStartHour:(NSString *)_hour {
  ASSIGN(self->startHour,_hour);
  self->startAM = [_hour intValue] < 12 ? YES : NO;
}
- (NSString *)startHour {
  return self->startHour;
}

- (void)setStartMinute:(NSString *)_minute {
  ASSIGN(self->startMinute,_minute);
}
- (NSString *)startMinute {
  return self->startMinute;
}

- (void)setStartTime:(NSString *)_time {
  ASSIGN(self->startTime,_time);
}
- (NSString *)startTime {
  return self->startTime;
}

//end
- (void)setEndDate:(NSString *)_date {
  ASSIGN(self->endDate,_date);
}
- (NSString *)endDate {
  return self->endDate;
}

- (void)setEndHour:(NSString *)_hour {
  ASSIGN(self->endHour,_hour);
  self->endAM = [_hour intValue] < 12 ? YES : NO;
}
- (NSString *)endHour {
  return self->endHour;
}

- (void)setEndMinute:(NSString *)_minute {
  ASSIGN(self->endMinute,_minute);
}
- (NSString *)endMinute {
  return self->endMinute;
}

- (void)setEndTime:(NSString *)_time {
  ASSIGN(self->endTime,_time);
}
- (NSString *)endTime {
  return self->endTime;
}

// all day?
- (void)setIsAllDayEvent:(BOOL)_flag {
  self->isAllDayEvent = _flag;
}
- (BOOL)isAllDayEvent {
  return self->isAllDayEvent;
}

// inputType
- (void)setTimeInputType:(NSString *)_type {
  ASSIGN(self->timeInputType,_type);
}
- (NSString *)timeInputType {
  return self->timeInputType;
}

- (void)setFormName:(NSString *)_name {
  ASSIGN(self->formName,_name);
}
- (NSString *)formName {
  return self->formName;
}

- (void)setIsNewOrNotCyclic:(BOOL)_flag {
  self->isNewOrNotCyclic = _flag;
}
- (BOOL)isNewOrNotCyclic {
  return self->isNewOrNotCyclic;
}

- (NSString *)timeInputStyle {
  return ([self isAllDayEvent])
    ? @"visibility:hidden;"
    : @"visibility:visible;";
}

/* wod bindings */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSArray *)hourAMPMStrings {
  static NSArray *hoursAMPM = nil;
  if (hoursAMPM == nil) {
    hoursAMPM =
      [[NSArray alloc] initWithObjects:
                       @"12 AM", @"01 AM", @"02 AM", @"03 AM", @"04 AM",
                       @"05 AM", @"06 AM", @"07 AM", @"08 AM", @"09 AM",
                       @"10 AM", @"11 AM", 
                       @"12 PM", @"01 PM", @"02 PM", @"03 PM", @"04 PM",
                       @"05 PM", @"06 PM", @"07 PM", @"08 PM", @"09 PM",
                       @"10 PM", @"11 PM", 
                       nil];
  }
  return hoursAMPM;
}

- (NSArray *)hour24Strings {
  static NSArray *hours24   = nil;

  if (hours24 == nil) {
    hours24 =
      [[NSArray alloc] initWithObjects:
                       @"00", @"01", @"02", @"03", @"04",
                       @"05", @"06", @"07", @"08", @"09",
                       @"10", @"11", @"12", @"13", @"14",
                       @"15", @"16", @"17", @"18", @"19",
                       @"20", @"21", @"22", @"23",
                       nil];
  }
  return hours24;
}

- (NSArray *)hour12Strings {
  static NSArray *hours12   = nil;

  if (hours12 == nil) {
    hours12 =
      [[NSArray alloc] initWithObjects:
                       @"12", @"01", @"02", @"03", @"04",
                       @"05", @"06", @"07", @"08", @"09",
                       @"10", @"11",
                       nil];
  }
  return hours12;
}

- (NSArray *)hourStrings {
  return (self->useAMPMDates)
    ? ([self useExtraAMPMPopUp]?[self hour12Strings]:[self hourAMPMStrings])
    : [self hour24Strings];
}

/* careing about ampm dates */

- (unsigned int)indexOf24HourEntry:(NSString *)_entry {
  NSUInteger idx;
  idx = [[self hour24Strings] indexOfObject:_entry];
  // only return a valid index
  return (idx == NSNotFound) ? 0 : idx;
}
- (NSString *)hourForListEntry:(NSString *)_entry {
  if (self->useAMPMDates) {
    unsigned int idx;
    if ([self useExtraAMPMPopUp]) {
      idx = [[self hour12Strings]   indexOfObject:_entry]
        + (self->startAM ? 0 : 12);
    }
    else {
      idx = [[self hourAMPMStrings] indexOfObject:_entry];
    }
    return (idx < 24)
      ? [[self hour24Strings] objectAtIndex:idx]
      : nil;
  }
  return _entry;
}

- (NSString *)listEntryForHour:(NSString *)_hour {
  if (self->useAMPMDates) {
    unsigned int idx;
    idx = [[self hour24Strings] indexOfObject:_hour];
    if (idx < 24)
      return [self useExtraAMPMPopUp]
        ? [[self hour12Strings]   objectAtIndex:idx % 12]
        : [[self hourAMPMStrings] objectAtIndex:idx];    
  }
  return _hour;
}

- (void)setStartHourWod:(NSString *)_str {
  [self setStartHour:[self hourForListEntry:_str]];
}
- (NSString *)startHourWod {
  return [self listEntryForHour:[self startHour]];
}

- (void)setEndHourWod:(NSString *)_str {
  [self setEndHour:[self hourForListEntry:_str]];
}
- (NSString *)endHourWod {
  return [self listEntryForHour:[self endHour]];
}

- (int)maxTimeTextFieldSize {
  return self->useAMPMDates ? 8 : 5;
}

/* AMPM buttons */
- (NSString *)startAMPM {
  return self->startAM ? @"AM" : @"PM";
}
- (NSString *)endAMPM {
  return self->endAM ? @"AM" : @"PM";
}

- (void)setStartAMPM:(NSString *)_am {  
  BOOL isAM;
  int idx;
  
  isAM = [_am isEqualToString:@"AM"];
  idx  = [self indexOf24HourEntry:[self startHour]];
  self->startAM = isAM;
  idx %= 12;
  if (!isAM) idx += 12;
  [self setStartHour:[[self hour24Strings] objectAtIndex:idx]];
}
- (void)setEndAMPM:(NSString *)_am {
  BOOL isAM;
  int idx;
  
  isAM = [_am isEqualToString:@"AM"];
  idx  = [self indexOf24HourEntry:[self endHour]];
  self->endAM = isAM;
  idx %= 12;
  if (!isAM) idx += 12;
  [self setEndHour:[[self hour24Strings] objectAtIndex:idx]];
}

@end /* SkyAptDateSelection */
