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

#include "SkyPalmDateWeekOverviewState.h"
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#include <NGExtensions/NGExtensions.h>

@implementation SkyPalmDateWeekOverviewState

- (id)initWithDefaults:(NSUserDefaults *)_ud
             companyId:(NSNumber *)_comp
                subKey:(NSString *)_subKey
{
  if ((self = [super init])) {
    NSCalendarDate *date = [NSCalendarDate date];
    ASSIGN(self->defaults, _ud);
    ASSIGN(self->companyId,_comp);
    ASSIGN(self->subKey,_subKey);
    self->year = [date yearOfCommonEra];
    self->week = [date weekOfYear];
  }
  return self;
}

- (id)initWithDefaults:(NSUserDefaults *)_ud
             companyId:(NSNumber *)_comp
{
  return [self initWithDefaults:_ud companyId:_comp subKey:@""];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->defaults);
  RELEASE(self->companyId);
  RELEASE(self->subKey);
  [super dealloc];
}
#endif

// keys

- (NSString *)_userDefaultsKeyForKey:(NSString *)_key {
  return [NSString stringWithFormat:@"SkyPalmDateWeekOverview_%@_%@",
                   self->subKey, _key];
}
- (NSString *)_timeZoneKey {
  return [self _userDefaultsKeyForKey:@"TimeZone"];
}

// default values

- (NSString *)_defaultTimeZone {
  NSCalendarDate *date = [NSCalendarDate date];
  return [[date timeZone] abbreviation];
}

// accessors

- (void)setTimeZone:(NSTimeZone *)_tz {
  [self->defaults setObject:[_tz abbreviation] forKey:[self _timeZoneKey]];
}
- (NSTimeZone *)timeZone {
  NSString *key = nil;
  NSString *tz;
  key = [self _timeZoneKey];
  if ((tz = [self->defaults objectForKey:key]) == nil) {
    tz = [self _defaultTimeZone];
    [self->defaults setObject:tz forKey:key];
  }
  return [NSTimeZone timeZoneWithAbbreviation:tz];
}

- (void)setWeekStart:(NSCalendarDate *)_date {
  self->year = [_date yearOfCommonEra];
  self->week = [_date weekOfYear];
}
- (NSCalendarDate *)weekStart {
  return [NSCalendarDate mondayOfWeek:self->week
                         inYear:self->year
                         timeZone:[self timeZone]];
}

- (int)year {
  return self->year;
}

// actions

- (void)synchronize {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self->defaults synchronize];
  NSLog(@"%s done", __PRETTY_FUNCTION__);
}

// fetchSpecification

- (EOFetchSpecification *)fetchSpecification {
  EOQualifier *qual;
  
  NSCalendarDate *start = [self weekStart];
  NSCalendarDate *end   = [start dateByAddingYears:0 months:0 days:7];

  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"company_id=%@ AND ("
                      @"(startdate<%@ AND enddate>%@) OR"
                      @"(is_untimed=1)"
                      @")", self->companyId,
                      end, start];
  return [EOFetchSpecification fetchSpecificationWithEntityName:
                               @"palm_date"
                               qualifier:qual
                               sortOrderings:nil];
}

@end
