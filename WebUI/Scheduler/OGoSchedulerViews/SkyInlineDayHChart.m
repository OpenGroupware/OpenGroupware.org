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

#include "SkyInlineAptDataSourceView.h"

@class NSCalendarDate;

@interface SkyInlineDayHChart : SkyInlineAptDataSourceView
{
@protected
  int maxInfoLength;

  NSCalendarDate *day;

  NSArray *persons;

  /* transient */
  NSArray *rows;
  int     column;
  int     columnsPerDay;
  int     dayStart;
  int     dayEnd;
  id      row;

  NSCalendarDate *aptStartDate;
  NSCalendarDate *aptEndDate;
}

@end

#include <OGoScheduler/SkyAptDataSource.h>
#include "SkyAppointmentFormatter.h"
#include "common.h"

@implementation SkyInlineDayHChart

+ (int)version {
  return [super version] + 0;
}

- (void)dealloc {
  [self->rows    release];
  [self->row     release];
  [self->day     release];
  [self->persons release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  [self->rows    release]; self->rows    = nil;
  [self->persons release]; self->persons = nil;
  [super syncSleep];
}

- (void)syncAwake {
  NSUserDefaults *ud;
  
  [super syncAwake];
  
  ud = [(id)[self session] userDefaults];
  self->maxInfoLength = 
    [ud integerForKey:@"scheduler_daychart_maxaptinfolength"];
  self->dayStart = [ud integerForKey:@"scheduler_dayoverview_daystart"];
  self->dayEnd   = [ud integerForKey:@"scheduler_dayoverview_dayend"];
  self->columnsPerDay =
    [ud integerForKey:@"scheduler_daychart_columnsperday"];
  self->columnsPerDay = (self->columnsPerDay < 12)
    ? 12
    : self->columnsPerDay;
}

/* accessors */

- (void)setAppointment:(id)_apt {
  if (self->appointment == _apt) 
    return;
  
  [super setAppointment:_apt];

  self->aptStartDate = [self->appointment valueForKey:@"startDate"];
  self->aptEndDate   = [self->appointment valueForKey:@"endDate"];
}

- (void)setDay:(NSCalendarDate *)_day {
  ASSIGN(self->day,_day);
}
- (NSCalendarDate *)day {
  return self->day;
}

- (void)setColumn:(int)_column {
  self->column = _column;
}
- (int)column {
  return self->column;
}

- (void)setRow:(id)_row {
  ASSIGN(self->row,_row);
}
- (id)row {
  return self->row;
}

/* additional accessors */

- (int)columnsPerDay {
  return self->columnsPerDay; // 12 | 24 | 48 | 96
}

- (NSArray *)columns {
  int cnt = [self columnsPerDay];
  int step = (int) 1440 / cnt;
  int pos = 0;
  NSMutableArray *ma = [NSMutableArray array];
  
  while (pos < cnt) {
    int width = pos * step;
    if ((width >= self->dayStart) && (width <= self->dayEnd))
      [ma addObject:[NSNumber numberWithInt:pos]];
    
    pos++;
  }
  return ma;
}

- (NSArray *)rows {
  return self->rows;
}

- (NSArray *)persons {
  return self->persons;
}

- (NSString *)labelForCompany:(id)_compId {
  NSString     *label;

  if ((label = [self->row valueForKey:@"name"]) == nil)
        label = [self->row valueForKey:@"login"];
  else {
    NSString *fd = [self->row valueForKey:@"firstname"];

    if (fd != nil)
      label = [NSString stringWithFormat:@"%@, %@", label, fd];
  }
  return label;
}

- (NSString *)currentRowLabel {
  NSString *label;
  if ([self->row isKindOfClass:[NSString class]])
    // is resource
    label = self->row;
  else
    label = [self labelForCompany:self->row];
  
  return label;
}

- (NSCalendarDate *)hour {
  NSCalendarDate *date;
  double interval = 1440 / [self columnsPerDay];

  date = [[self day] beginOfDay];
  date = [date hour:0 minute:0 second:0];
  date = [date dateByAddingYears:0 months:0 days:0 hours:0
               minutes:(int)(interval * self->column)
               seconds:0];
  return date;
}

- (NSString *)hourLabel {
  NSString *format;
  format = [self showAMPMDates] ? @"%I:%M %p" : @"%H:%M";
  return [[self hour] descriptionWithCalendarFormat:format];
}

- (BOOL)isAppointmentInRow {
  // TODO: cleanup/splitup
  if (self->appointment == nil)
    return NO;
  
  if ([self->row isKindOfClass:[NSString class]]) {
    // isResource
    NSString *resources;
    
    resources = [self->appointment valueForKey:@"resourceNames"];

    if (![resources isNotNull])
      return NO;
    
    return ([resources rangeOfString:self->row].length == 0) ? NO : YES;
  }
  else {
    NSArray *participants;
    
    participants = [self->appointment valueForKey:@"participants"];

    if (participants == nil)
      return NO;
    else {
      NSMutableArray *teams = nil;
      int            i, cnt;

      teams = [NSMutableArray array];

      for (i = 0, cnt = [participants count]; i < cnt; i++) {
        id gid = nil;

        gid = [[participants objectAtIndex:i] valueForKey:@"globalID"];

        if ([gid isEqual:[self->row valueForKey:@"globalID"]])
          return YES;
        if ([[gid entityName] isEqualToString:@"Team"]) {
          [teams addObject:gid];
        }
      }
      if ([teams count] > 0) {
        id members = nil;
        
        if ((members = [self->appointment valueForKey:@"members"]) == nil) {
          members = [self runCommand:@"team::members",
                          @"groups",         teams,
                          @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                          nil];
          if ([members isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *a = nil;
            int             i, cnt;
            
            a = [NSMutableArray array];
            members = [members allValues];

            for (i = 0, cnt = [members count]; i < cnt; i++) 
              [a addObjectsFromArray:[members objectAtIndex:i]];
            members = a;
          }
          [self->appointment takeValue:members forKey:@"members"];
        }
        if ([members containsObject:[self->row valueForKey:@"globalID"]])
          return YES;
      }
    }
    return NO;
  }
  return NO;
}

- (BOOL)isAppointmentInCell {
  NSTimeInterval start, aptStart;
  NSTimeInterval end,   aptEnd;
  NSCalendarDate *d;
  int mins;

  if (![self isAppointmentInRow])
    return NO;

  d = [self hour];
  mins = (int)(1440 / [self columnsPerDay]);
  
  start    = [d timeIntervalSince1970];
  aptStart = [self->aptStartDate timeIntervalSince1970];

  d = [d dateByAddingYears:0 months:0 days:0 hours:0 minutes:mins seconds:0];
  end      = [d timeIntervalSince1970];
  aptEnd   = [self->aptEndDate timeIntervalSince1970] - 2;

  if (aptStart >= end)
    return NO;
  if (aptEnd < start)
    return NO;

  return YES;
}

- (NSCalendarDate *)referenceDateForFormatter {
  return [self hour];
}

- (NSFormatter *)aptInfoFormatter {
  NSString *format;

  format = [NSString stringWithFormat:@"%%%dT", self->maxInfoLength];

  return [SkyAppointmentFormatter formatterWithFormat:format];
}

// conditional

- (BOOL)hasRows {
  return ([[self rows] count] > 0) ? YES : NO;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  id all = [[self dataSource] companies];
  id pers = [NSMutableArray array];
  id tms  = [NSMutableArray array];
  int cnt = 0;

  while (cnt < [all count]) {
    id one = [all objectAtIndex:cnt++];
    if ([[one entityName] isEqualToString:@"Person"])
      [pers addObject:one];
    else
      [tms addObject:one];
  }
  if ([tms count] > 0) {
    id members;
    int cnt = 0;
    members = [self runCommand:@"team::members",
                    @"groups",         tms,
                    @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                    nil];

    while (cnt < [members count]) {
      id obj = [members objectAtIndex:cnt++];
      if (![pers containsObject:obj]) {
        [pers addObject:obj];
      }
    }
  }
  if ([pers count] > 0) {
    pers = [self runCommand:@"person::get-by-globalid",
                 @"gids", pers,
                 @"attributes",[NSArray arrayWithObjects:@"login", @"name",
                                        @"firstname", @"globalID", nil],
                 nil];

    pers = [pers sortedArrayUsingKeyOrderArray:
                 [NSArray arrayWithObjects:
                          [EOSortOrdering sortOrderingWithKey:@"name"
                                          selector:EOCompareAscending],
                          [EOSortOrdering sortOrderingWithKey:@"firstname"
                                          selector:EOCompareAscending],
                          nil]];

    ASSIGN(self->persons, pers);
  }
  else
    self->persons = [[NSArray alloc] init];
  {
    NSArray *rs;
    
    rs = [self->dataSource resources];
    rs = [rs sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    rs = [rs arrayByAddingObjectsFromArray:self->persons];
    ASSIGN(self->rows,rs);
  }
  [super appendToResponse:_response inContext:_ctx];
}

@end /* SkyInlineDayHChart */
