/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "SkyInlineAptDataSourceView.h"

// TODO: looks like a DUP to SkyInlineDayHChart!

@class NSCalendarDate, NSArray;

@interface SkyInlineWeekHChart : SkyInlineAptDataSourceView
{
@protected
  int maxInfoLength;

  NSCalendarDate *weekStart;

  NSArray *persons;
  BOOL    isRowLinkEnabled;
  
  /* transient */
  NSArray *rows;
  int     column;
  int     columnsPerDay;
  id      row;

  NSCalendarDate *aptStartDate;
  NSCalendarDate *aptEndDate;
}

@end

#include "SkyAppointmentFormatter.h"
#include "common.h"
#include <EOControl/EOControl.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/WOComponent+Commands.h>

@implementation SkyInlineWeekHChart

static NSNumber *yesNum = nil;

+ (int)version {
  return [super version] + 0;
}
+ (void)initialize {
  // TODO: check parent version
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (void)dealloc {
  [self->rows      release];
  [self->row       release];
  [self->weekStart release];
  [self->persons   release];
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
    [ud integerForKey:@"scheduler_weekchart_maxaptinfolength"];
  self->columnsPerDay =
    [ud integerForKey:@"scheduler_weekchart_columnsperday"];
}

/* accessors */

- (void)setAppointment:(id)_apt {
  if (self->appointment == _apt)
    return;
  
  [super setAppointment:_apt];

  self->aptStartDate = [self->appointment valueForKey:@"startDate"];
  self->aptEndDate   = [self->appointment valueForKey:@"endDate"];
}

- (void)setWeekStart:(NSCalendarDate *)_weekStart {
  ASSIGN(self->weekStart,_weekStart);
}
- (NSCalendarDate *)weekStart {
  return self->weekStart;
}

- (void)setIsRowLinkEnabled:(BOOL)_flag {
  self->isRowLinkEnabled = _flag;
}
- (BOOL)isRowLinkEnabled {
  return self->isRowLinkEnabled;
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

// additional accessors

- (int)columnsPerDay {
  return self->columnsPerDay; // 1 | 2 | 3 | 4 | 6 | 8 | 12 | 24 | 48
}

- (NSArray *)columns {
  int cnt;
  int pos;
  NSMutableArray *ma;
  
  cnt = [self columnsPerDay] * 7;
  pos = 0;
  ma  = [NSMutableArray array];
  
  while (pos < cnt)
    [ma addObject:[NSNumber numberWithInt:pos++]];
  return ma;
}

- (NSArray *)rows {
  return self->rows;
}

- (NSArray *)persons {
  return self->persons;
}

- (NSString *)labelForCompany:(id)_compId {
  NSString     *label = nil;

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
  NSString *label = nil;
  
  if ([self->row isKindOfClass:[NSString class]])
    // is resource
    label = self->row;
  else 
    label = [self labelForCompany:self->row];
  
  return label;
}

- (NSString *)rowSelection {
  NSString *selection = nil;
  
  if ([self->row isKindOfClass:[NSString class]]) {
    // is resource
    selection = [@"resource:" stringByAppendingString:self->row];
  }
  else {
    selection = [@"company:" stringByAppendingString:
                          [[self->row valueForKey:@"companyId"] stringValue]];
  }
  return selection;
}

- (NSCalendarDate *)weekday {
  NSCalendarDate *date = nil;
  double interval = 1440 / [self columnsPerDay];

  date = [[self weekStart] beginOfDay];
  date = [date hour:0 minute:0 second:0];
  date = [date dateByAddingYears:0 months:0 days:0 hours:0
               minutes:(int)(interval * self->column)
               seconds:0];
  return date;
}

- (NSString *)spaceImg {
  NSDictionary* size =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  @"1",  [NSNumber numberWithInt:48],
                  @"2",  [NSNumber numberWithInt:24],
                  @"6",  [NSNumber numberWithInt:12],
                  @"10", [NSNumber numberWithInt:8],
                  @"14", [NSNumber numberWithInt:6],
                  @"22", [NSNumber numberWithInt:4],
                  @"30", [NSNumber numberWithInt:3],
                  @"46", [NSNumber numberWithInt:2],
                  @"94", [NSNumber numberWithInt:1],
                  nil];
  NSString *img =
    [size objectForKey:[NSNumber numberWithInt:[self columnsPerDay]]];
  return [NSString stringWithFormat:@"invisible_space_%@.gif", img];
}

- (BOOL)isAppointmentInRow {
  // TODO: split up?
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
                          @"fetchGlobalIDs", yesNum,
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
        }
        [self->appointment takeValue:members forKey:@"members"];

        if ([members containsObject:[self->row valueForKey:@"globalID"]]) {
          return YES;
        }
      }
    }
  }
  return NO;
}

- (BOOL)isAppointmentInCell {
  NSTimeInterval start, aptStart;
  NSTimeInterval end,   aptEnd;
  NSCalendarDate *d = nil;
  int mins;

  if (![self isAppointmentInRow])
    return NO;

  d = [self weekday];
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
  return [self weekday];
}

- (NSFormatter *)aptInfoFormatter {
  NSString *format = nil;

  format = [NSString stringWithFormat:@"%%%dT", self->maxInfoLength];

  return [SkyAppointmentFormatter formatterWithFormat:format];
}

// conditional

- (BOOL)hasRows {
  return ([[self rows] count] > 0) ? YES : NO;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  // TODO: split up?
  NSArray        *all;
  NSMutableArray *pers;
  NSMutableArray *tms;
  int cnt = 0;

  all  = [[self dataSource] companies];
  pers = [NSMutableArray array];
  tms  = [NSMutableArray array];
  
  while (cnt < [all count]) {
    id one = [all objectAtIndex:cnt++];
    if ([[one entityName] isEqualToString:@"Person"])
      [pers addObject:one];
    else
      [tms addObject:one];
  }
  if ([tms count] > 0) {
    id members = nil;
    int cnt = 0;
    members = [self runCommand:@"team::members",
                    @"groups",         tms,
                    @"fetchGlobalIDs", yesNum,
                    nil];

    while (cnt < [members count]) {
      id obj = [members objectAtIndex:cnt++];
      if (![pers containsObject:obj])
        [pers addObject:obj];
    }
  }
  if ([pers count] > 0) {
    static NSArray *attrs     = nil;
    static NSArray *orderings = nil;
    NSArray *recs;
    if (attrs == nil) {
      attrs = [[NSArray alloc] initWithObjects:@"login", @"name",
                                 @"firstname", @"globalID", nil];
    }
    if (orderings == nil) {
      EOSortOrdering *nameAsc, *fnameAsc;
      nameAsc  = [EOSortOrdering sortOrderingWithKey:@"name"
                                 selector:EOCompareAscending];
      fnameAsc = [EOSortOrdering sortOrderingWithKey:@"firstname"
                                 selector:EOCompareAscending];
      orderings = [[NSArray alloc] initWithObjects:nameAsc, fnameAsc, nil];
    }

    if ([pers count]) {
      recs = [self runCommand:@"person::get-by-globalid",
                   @"gids",       pers,
                   @"attributes", attrs,
                   nil];
      recs = [recs sortedArrayUsingKeyOrderArray:orderings];
    }
    else
      recs = [NSArray array];
    
    ASSIGN(self->persons, recs);
  }
  else
    self->persons = [[NSArray alloc] init];
  
  {
    NSArray *rs = nil;
    
    rs = [self->dataSource resources];
    rs = [rs sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    rs = [rs arrayByAddingObjectsFromArray:self->persons];
    ASSIGN(self->rows, rs);
  }
  [super appendToResponse:_response inContext:_ctx];
}

@end /* SkyInlineWeekHChart */
