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

#define REPEATTYPE_NONE            0
#define REPEATTYPE_DAILY           1
#define REPEATTYPE_WEEKLY          2
#define REPEATTYPE_MONTHLY_BY_DAY  3
#define REPEATTYPE_MONTHLY_BY_DATE 4
#define REPEATTYPE_YEARLY          5

#include <OGoPalmUI/SkyPalmEntryEditor.h>
#include <OGoPalm/SkyPalmDateDocument.h>

@class NSNumber, NSMutableArray;

@interface SkyPalmDateEditor : SkyPalmEntryEditor
{
  // startdate
  int             startHour;
  int             startMinute;
  NSString        *startdate;
  // enddate
  int              endHour;
  int              endMinute;
  // alarm
  NSString         *alarmUnit;   // value of alarmunits
  // repetition
  NSMutableArray   *repeatFrequencys;
  NSMutableArray   *weekdaySelection;
  NSString         *repeatEnddate;
  BOOL             hasRepeatEnddate;
}

- (id)date;
- (void)setStartdate:(NSString *)_date;
- (void)setRepeatEnddate:(NSString *)_date;
- (void)setAlarmUnit:(NSString *)_alarm;
- (void)_setRepeatFrequency:(NSString *)_freq ofMode:(int)_idx;

@end

#import <Foundation/Foundation.h>
#include <NGObjWeb/WOContext.h>
#include <NGObjWeb/WOResourceManager.h>
#include <NGExtensions/NGExtensions.h>
#include <OGoFoundation/LSWSession.h>

@implementation SkyPalmDateEditor

- (id)init {
  if ((self = [super init])) {
    self->repeatFrequencys =
      [NSMutableArray arrayWithObjects:
                      [NSNumber numberWithInt:0], // none
                      [NSNumber numberWithInt:1], // daily
                      [NSNumber numberWithInt:1], // weekly
                      [NSNumber numberWithInt:1], // monthly by day
                      [NSNumber numberWithInt:1], // monthly by date
                      [NSNumber numberWithInt:1], // yearly
                      nil];
    RETAIN(self->repeatFrequencys);
    self->weekdaySelection =
      [NSMutableArray arrayWithObjects:
                      [NSNumber numberWithBool:NO],  // Su
                      [NSNumber numberWithBool:NO],  // Mo
                      [NSNumber numberWithBool:NO],  // Tu
                      [NSNumber numberWithBool:NO],  // We
                      [NSNumber numberWithBool:NO],  // Th
                      [NSNumber numberWithBool:NO],  // Fr
                      [NSNumber numberWithBool:NO],  // Sa
                      nil];
    RETAIN(self->weekdaySelection);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->startdate);
  RELEASE(self->alarmUnit);
  RELEASE(self->repeatFrequencys);
  RELEASE(self->weekdaySelection);
  RELEASE(self->repeatEnddate);
  [super dealloc];
}
#endif

- (BOOL)prepareForActivationCommand:(NSString *)_command
                               type:(NGMimeType *)_type
                      configuration:(id)_cfg
{
  if ([super prepareForActivationCommand:_command type:_type
             configuration:_cfg])
    {
      
      NSCalendarDate *start;
      NSCalendarDate *end;
      int            repeatType;
      id             obj;

      obj = [self snapshot];
  
      // date
      start = [obj valueForKey:@"startdate"];
      end   = [obj valueForKey:@"enddate"];
      if (start == nil) {
        self->startHour   = -1;
        self->startMinute = -1;
        self->endHour     = -1;
        self->endMinute   = -1;
        start = [NSCalendarDate date];
        [start setTimeZone:[(id)[self session] timeZone]];
      }
      else if ([obj isUntimed]) {
        self->startHour   = -1;
        self->startMinute = -1;
        self->endHour     = -1;
        self->endMinute   = -1;
      }
      else {
        self->startHour   = [start hourOfDay];
        self->startMinute = [start minuteOfHour];
        self->endHour     = [end hourOfDay];
        self->endMinute   = [end minuteOfHour];
      }
      [self setStartdate:[start descriptionWithCalendarFormat:@"%Y-%m-%d"]];

      // alarm
      [self setAlarmUnit:
            [[NSNumber numberWithInt:[obj alarmAdvanceUnit]] stringValue]];

      // repeat
      end = [obj valueForKey:@"repeatEnddate"];
      if (end == nil) {
        [self setRepeatEnddate:@""];
        self->hasRepeatEnddate = NO;
      } else {
        [self setRepeatEnddate:
              [end descriptionWithCalendarFormat:@"%Y-%m-%d"]];
        self->hasRepeatEnddate = YES;
      }
  
      repeatType = [obj repeatType];
      if (repeatType == REPEATTYPE_WEEKLY) {
        int      repeatOn = [obj repeatOn];
        int      cnt      = 0;
        NSNumber *nYes    = [NSNumber numberWithBool:YES];
        for (cnt = 0; cnt < 7; cnt++) {
          if ((repeatOn & 1) == 1)
            [self->weekdaySelection replaceObjectAtIndex:cnt withObject:nYes];
          repeatOn >>= 1;
        }
      }
      [self _setRepeatFrequency:
            [[NSNumber numberWithInt:[obj repeatFrequency]] stringValue]
            ofMode:repeatType];
      
      return YES;
    }
  return NO;
}

// accessors
- (id)date {
  return [self snapshot];
}

// startdate
- (void)setStartHour:(NSNumber *)_h {
  self->startHour = [_h intValue];
}
- (NSNumber *)startHour {
  return [NSNumber numberWithInt:self->startHour];
}
- (void)setStartMinute:(NSNumber *)_m {
  self->startMinute = [_m intValue];
}
- (NSNumber *)startMinute {
  return [NSNumber numberWithInt:self->startMinute];
}
- (void)setStartdate:(NSString *)_date {
  ASSIGN(self->startdate,_date);
}
- (NSString *)startdate {
  return self->startdate;
}

// enddate
- (void)setEndHour:(NSNumber *)_h {
  self->endHour = [_h intValue];
}
- (NSNumber *)endHour {
  return [NSNumber numberWithInt:self->endHour];
}
- (void)setEndMinute:(NSNumber *)_m {
  self->endMinute = [_m intValue];
}
- (NSNumber *)endMinute {
  return [NSNumber numberWithInt:self->endMinute];
}
- (void)setRepeatEnddate:(NSString *)_date {
  ASSIGN(self->repeatEnddate,_date);
}
- (NSString *)repeatEnddate {
  return self->repeatEnddate;
}
- (void)setHasRepeatEnddate:(BOOL)_flag {
  self->hasRepeatEnddate = _flag;
}
- (BOOL)hasRepeatEnddate {
  return self->hasRepeatEnddate;
}

// alarm
- (void)setAlarmUnit:(NSString *)_alarm {
  ASSIGN(self->alarmUnit,_alarm);
}
- (NSString *)alarmUnit {
  return self->alarmUnit;
}

// labels
// label key for hours
- (NSString *)hourItemLabel {
  int h = [self->item intValue];
  if (h == -1)
    return @"--";
  return [NSString stringWithFormat:@"%02i", h];
}
// label key for minutes
- (NSString *)minuteItemLabel {
  return [self hourItemLabel];
}
// label key for alarm time
- (NSString *)alarmItemLabel {
  return [NSString stringWithFormat:@"alarmUnit_%i",
                   [self->item intValue]];
}
// label key for weekday
- (NSString *)weekdayItemLabel {
  return [NSString stringWithFormat:@"weekday_short_%i",
                   [self->item intValue]];
}

// calendar support
- (NSString *)calendarPageURL {
  WOResourceManager *rm;
  NSString *url;
  
  rm = [(id)[WOApplication application] resourceManager];
  
  url = [rm urlForResourceNamed:@"calendar.html"
            inFramework:nil
            languages:[[self session] languages]
            request:[[self context] request]];
  
  if (url == nil) {
    [self debugWithFormat:@"couldn't locate calendar page"];
    url = @"/Skyrix.woa/WebServerResources/English.lproj/calendar.html";
  }

  return url;
}
- (NSString *)_dateOnClickEvent:(NSString *)_date {
  return
    [NSString stringWithFormat:
              @"setDateField(document.editform.%@);"
              @"top.newWin=window.open('%@','cal','WIDTH=208,HEIGHT=230')",
              _date,
              [self calendarPageURL]];
}
- (NSString *)startdateOnClickEvent {
  return [self _dateOnClickEvent:@"startdate"];
}
//- (NSString *)enddateOnClickEvent {
//  return [self _dateOnClickEvent:@"enddate"];
//}
- (NSString *)repeatEnddateOnClickEvent {
  return [self _dateOnClickEvent:@"repeatEnddate"];
}

// repeat frequency
- (void)_setRepeatFrequency:(NSString *)_freq ofMode:(int)_idx {
  [self->repeatFrequencys replaceObjectAtIndex:_idx withObject:_freq];
}
- (NSString *)_repeatFrequencyOfMode:(int)_idx {
  return [self->repeatFrequencys objectAtIndex:_idx];
}
// day
- (void)setRepeatFrequency1:(NSString *)_freq { // day
  [self _setRepeatFrequency:_freq ofMode:REPEATTYPE_DAILY];
}
- (NSString *)repeatFrequency1 {
  return [self _repeatFrequencyOfMode:REPEATTYPE_DAILY];
}
// week
- (void)setRepeatFrequency2:(NSString *)_freq { // week
  [self _setRepeatFrequency:_freq ofMode:REPEATTYPE_WEEKLY];
}
- (NSString *)repeatFrequency2 {
  return [self _repeatFrequencyOfMode:REPEATTYPE_WEEKLY];
}
// month by day
- (void)setRepeatFrequency3:(NSString *)_freq { // month by day
  [self _setRepeatFrequency:_freq ofMode:REPEATTYPE_MONTHLY_BY_DAY];
}
- (NSString *)repeatFrequency3 {
  return [self _repeatFrequencyOfMode:REPEATTYPE_MONTHLY_BY_DAY];
}
// month by date
- (void)setRepeatFrequency4:(NSString *)_freq { // month by date
  [self _setRepeatFrequency:_freq ofMode:REPEATTYPE_MONTHLY_BY_DATE];
}
- (NSString *)repeatFrequency4 {
  return [self _repeatFrequencyOfMode:REPEATTYPE_MONTHLY_BY_DATE];
}
// year
- (void)setRepeatFrequency5:(NSString *)_freq { // year
  [self _setRepeatFrequency:_freq ofMode:REPEATTYPE_YEARLY];
}
- (NSString *)repeatFrequency5 {
  return [self _repeatFrequencyOfMode:REPEATTYPE_YEARLY];
}

// weekday support
- (void)setWeekdayChecked:(BOOL)_flag {
  [self->weekdaySelection replaceObjectAtIndex:[self->item intValue]
       withObject:[NSNumber numberWithBool:_flag]];
}
- (BOOL)weekdayChecked {
  NSNumber *c = 
    [self->weekdaySelection objectAtIndex:[self->item intValue]];
  return [c boolValue];
}

// saving
- (void)_checkDates {
  id             d;
  NSCalendarDate *date;
  BOOL           isEvent;
  NSTimeZone     *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

  d    = [self date];
  
  // getting date values
  date = [NSCalendarDate dateWithString:self->startdate
                         calendarFormat:@"%Y-%m-%d"];
  if (date == nil)
    date = [[NSCalendarDate date] beginOfDay];
  isEvent = ((self->startHour == -1) || (self->startMinute == -1) ||
             (self->endHour == -1)   || (self->endMinute == -1))
    ? YES : NO;

  // checking hours and minutes
  if (self->endHour < self->startHour)
    self->endHour = self->startHour;
  if ((self->endHour == self->startHour) &&
      (self->endMinute <= self->startMinute)) {
    self->endMinute = self->startMinute + 1;
    if (self->endMinute == 60) {
      self->startMinute = 58;
      self->endMinute   = 59;
    }
  }

  // setting values
  if (isEvent)
    date = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                           month:[date monthOfYear]
                           day:[date dayOfMonth]
                           hour:12
                           minute:0
                           second:0
                           timeZone:gmt];
  else
    date = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                           month:[date monthOfYear]
                           day:[date dayOfMonth]
                           hour:self->startHour
                           minute:self->startMinute
                           second:0
                           timeZone:[(id)[self session] timeZone]];
  [d takeValue:date forKey:@"startdate"];
  if (!isEvent)
    date = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                           month:[date monthOfYear]
                           day:[date dayOfMonth]
                           hour:self->endHour
                           minute:self->endMinute
                           second:0
                           timeZone:[(id)[self session] timeZone]];
  [d takeValue:date forKey:@"enddate"];
  [d setIsUntimed:isEvent];
}

- (void)_checkAlarm {
  id   d;
  BOOL isAlarmed;

  d         = [self date];
  isAlarmed = [d isAlarmed];

  if (isAlarmed) {
    int unit = [self->alarmUnit intValue];
    [d setAlarmAdvanceUnit:unit];
  } else {
    [d setAlarmAdvanceTime:0];
    [d setAlarmAdvanceUnit:0];
  }
}

- (void)_checkRepetition {
  id             d;
  int            repeatType;
  int            repeatOn        = 0;
  int            repeatFrequency;
  int            repeatStartWeek = 0;
  NSCalendarDate *endDate        = nil;

  d          = [self date];
  repeatType = [d repeatType];
  repeatFrequency =
    [[self->repeatFrequencys objectAtIndex:repeatType] intValue];
  // checking repeat values
  switch (repeatType) {
    case REPEATTYPE_NONE:
      repeatFrequency = 0;
      break;
    case REPEATTYPE_DAILY:
      break;
    case REPEATTYPE_WEEKLY: {
      int cnt;
      for (cnt = 0; cnt < 7; cnt++) {
        if ([[self->weekdaySelection objectAtIndex:cnt] boolValue])
          repeatOn |= (1 << cnt);
      }
      repeatStartWeek = 1;
    }
      break;
    case REPEATTYPE_MONTHLY_BY_DAY: {
      NSCalendarDate *date = [d valueForKey:@"startdate"];
      int            week;
      week     = ([date dayOfMonth] - 1) / 7;
      repeatOn = [date dayOfWeek] + 7 * week;
    }
      break;
    case REPEATTYPE_MONTHLY_BY_DATE:
      break;
    case REPEATTYPE_YEARLY:
      break;
    default:
      repeatFrequency = 0;
      break;
  }
  // enddate
  if (self->hasRepeatEnddate) {
    endDate = [NSCalendarDate dateWithString:self->repeatEnddate
                              calendarFormat:@"%Y-%m-%d"];

    if (endDate) {
      endDate = [NSCalendarDate dateWithYear:[endDate yearOfCommonEra]
                                month:[endDate monthOfYear]
                                day:[endDate dayOfMonth]
                                hour:12
                                minute:0
                                second:0
                                timeZone:
                                [NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    }
  }

  // setting values
  [d setRepeatFrequency:repeatFrequency];
  [d setRepeatStartWeek:repeatStartWeek];
  [d setRepeatOn:repeatOn];
  [(SkyPalmDateDocument *)d setRepeatEnddate:endDate];
}

- (BOOL)checkData {
  [self _checkDates];
  [self _checkAlarm];
  [self _checkRepetition];
  [self checkStringForKey:@"description"];
  [self checkStringForKey:@"note"];
  {
    NSString *desc = [[self snapshot] valueForKey:@"description"];
    if ((desc == nil) || ([desc length] == 0)) {
      [self setErrorString:@"please fill description field"];
      return NO;
    }
  }
  return YES;
}

- (id)save {
  if (![self checkData])
    return nil;
  return [super save];
}

// overwriting
- (NSString *)palmDb {
  return @"DatebookDB";
}

// exceptions
- (BOOL)hasExceptions {
  return ([[[self date] exceptions] count] > 0)
    ? YES : NO;
}
- (id)removeException {
  NSMutableArray *ma = [[[self date] exceptions] mutableCopy];

  [ma removeObject:self->item];
  [[self date] setExceptions:ma];
  RELEASE(ma); ma = nil;
  
  return nil;
}

@end /* SkyPalmDateEditor */
