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

#include "SkyHolidayCalculator.h"
#include "common.h"

@interface NSCalendarDate(Easter)
+ (NSCalendarDate *)easterForHolidaysForYear:(int)y timeZone:(NSTimeZone *)_tz;
@end

@implementation SkyHolidayCalculator

static NSString     *holidaysPath   = nil;
static NSDictionary *holidaysConfig = nil;

+ (int)version {
  return 2 /* v2 */;
}

+ (NSString *)_findHolidaysConfigFile {
  // TODO: fix me for Cocoa / gstep-base
  NSFileManager *fm;
  NSDictionary *env;
  NSEnumerator *e;
  NSArray  *pathes;
  NSString *path;
  id tmp;
  
  /* extract pathes from GNUstep environment */
  
  env = [[NSProcessInfo processInfo] environment];
  if ((tmp = [env objectForKey:@"GNUSTEP_PATHPREFIX_LIST"]) == nil)
    tmp = [env objectForKey:@"GNUSTEP_PATHLIST"];
  pathes = [tmp componentsSeparatedByString:@":"];
  
  /* check pathes */
  
  fm = [NSFileManager defaultManager];
  e = [pathes objectEnumerator];
  while ((path = [e nextObject])) {
    path = [path stringByAppendingPathComponent:@"Libraries"];
    path = [path stringByAppendingPathComponent:@"Resources"];
    path = [path stringByAppendingPathComponent:@"OGoScheduler"];
    path = [path stringByAppendingPathComponent:@"Holidays.plist"];
    
    if ([fm isReadableFileAtPath:path])
      return path;
  }
  
  /* check FHS pathes */
  
  pathes = [NSArray arrayWithObjects:
		      @"/usr/local/share/opengroupware.org-5.5/",
		      @"/usr/share/opengroupware.org-5.5/",
		    nil];
  e = [pathes objectEnumerator];
  while ((path = [e nextObject])) {
    path = [path stringByAppendingPathComponent:@"Holidays.plist"];
    
    if ([fm isReadableFileAtPath:path])
      return path;
  }
  
  return nil;
}

+ (void)initialize {
  if (holidaysPath == nil) {
    holidaysPath = [[self _findHolidaysConfigFile] copy];
    if (![holidaysPath isNotNull]) {
      NSLog(@"WARNING: did not find config file for holidays: "
	    @"'Holidays.plist'");
    }
  }
  if (holidaysConfig == nil && [holidaysPath isNotNull]) {
    // TODO: might want to use skyDictionary...? for Cocoa/gstep-base
    holidaysConfig = 
      [[NSDictionary alloc] initWithContentsOfFile:holidaysPath];
    if (holidaysConfig == nil) {
      NSLog(@"WARNING: could not load holiday configuration: '%@'", 
	    holidaysPath);
    }
  }
}

+ (SkyHolidayCalculator *)calculatorWithYear:(int)_year
  timeZone:(NSTimeZone *)_tz
  userDefaults:(NSUserDefaults *)_ud
{
  return [[[SkyHolidayCalculator alloc] initWithYear:_year timeZone:_tz 
					userDefaults:_ud] autorelease];
}

- (id)init {
  if ((self = [super init])) {
    self->year = -1;
  }
  return self;
}

- (id)initWithYear:(int)_year timeZone:(NSTimeZone *)_tz 
  userDefaults:(NSUserDefaults *)_ud 
{
  if ((self = [self init])) {
    self->year         = _year;
    self->timeZone     = [_tz retain];
    self->userDefaults = [_ud retain];
  }
  return self;
}

- (void)dealloc {
  [self->userDefaults release];
  [self->timeZone     release];
  [self->holidays     release];
  [self->easter       release];
  [self->firstMay     release];
  [self->firstAdvent  release];
  [self->christmasEve release];
  [super dealloc];
}

/* accessors */

- (void)_resetYearCaches {
  [self->holidays     release]; self->holidays     = nil;
  [self->easter       release]; self->easter       = nil;
  [self->firstMay     release]; self->firstMay     = nil;
  [self->firstAdvent  release]; self->firstAdvent  = nil;
  [self->christmasEve release]; self->christmasEve = nil;
}

- (void)setYear:(int)_year {
  if (self->year == _year)
    return;
  
  [self _resetYearCaches];
  self->year = _year;
}
- (int)year {
  return self->year;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone, _tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setUserDefaults:(NSUserDefaults *)_ud {
  [self _resetYearCaches];
  // force reload, TODO: explain the calls below?
  [self setYear:(self->year + 1)];
  [self setYear:(self->year - 1)];
  ASSIGN(self->userDefaults,_ud);
}
- (NSUserDefaults *)userDefaults {
  return self->userDefaults;
}

- (void)setEaster:(NSCalendarDate *)_easter {
  ASSIGN(self->easter,_easter);
}

- (NSCalendarDate *)easter {
  if (self->easter == nil) {
    self->easter = [[NSCalendarDate easterForHolidaysForYear:self->year
				    timeZone:self->timeZone] copy];
  }
  return self->easter;
}

/* fix holidays */

- (NSCalendarDate *)dateForDay:(int)_day inMonth:(int)_month {
  return [NSCalendarDate dateWithYear:self->year month:_month day:_day
                         hour:0 minute:0 second:0 timeZone:self->timeZone];
}

- (void)setFirstMay:(NSCalendarDate *)_firstMay {
  ASSIGN(self->firstMay, _firstMay);
}
- (NSCalendarDate *)firstMay {
  // Erster Mai
  if (self->firstMay != nil)
    return self->firstMay;
  
  self->firstMay =
    [[NSCalendarDate alloc] initWithYear:self->year month:5 day:1
			    hour:0 minute:0 second:0 timeZone:self->timeZone];
  return self->firstMay;
}

- (NSCalendarDate *)allSaintsDay {
  // Allerheiligen
  return [self dateForDay:1 inMonth:11];
}

- (void)setChristmasEve:(NSCalendarDate *)_day {
  ASSIGN(self->christmasEve,_day);
}
- (NSCalendarDate *)christmasEve {
  // Weihnachten
  if (self->christmasEve)
    return self->christmasEve;

  self->christmasEve =
    [[NSCalendarDate alloc] initWithYear:self->year month:12 day:24
			    hour:0 minute:0 second:0 timeZone:self->timeZone];
  return self->christmasEve;
}

- (NSCalendarDate *)christmasDay {
  return [self dateForDay:25 inMonth:12]; /* Erster Weihnachtsfeiertag */
}
- (NSCalendarDate *)boxingDay {
  return [self dateForDay:26 inMonth:12]; /* Zweiter Weihnachtsfeiertag */
}
- (NSCalendarDate *)newYearsEve {
  return [self dateForDay:31 inMonth:12]; /* Silvester */
}
- (NSCalendarDate *)newYear {
  return [self dateForDay:1 inMonth:1]; /* Neujahr */
}

/* variable holidays */

- (NSCalendarDate *)easterDateWithOffset:(int)_offset {
  /* for holidays relative to easter */
  return [[self easter] dateByAddingYears:0 months:0 days:_offset];
}

- (NSCalendarDate *)goodFriday {
  return [self easterDateWithOffset:-2]; /* Karfreitag */
}
- (NSCalendarDate *)easterMonday {
  return [self easterDateWithOffset:1]; /* Ostermontag */
}
- (NSCalendarDate *)shrovetide {
  return [self easterDateWithOffset:-47]; /* Fastnacht */
}
- (NSCalendarDate *)ascension {
  return [self easterDateWithOffset:39]; /* Christi Himmelfahrt */
}
- (NSCalendarDate *)whitsun {
  return [self easterDateWithOffset:49]; /* Pfingstsonntag */
}
- (NSCalendarDate *)whitmonday {
  return [self easterDateWithOffset:50]; /* Pfingstmontag */
}
- (NSCalendarDate *)corpurChristi {
  return [self easterDateWithOffset:60]; /* Fronleichnam */
}

- (NSCalendarDate *)summertimeChange {
  // TODO: whats that? That depends on the timezone and can't be calculated?
  // Sommerzeitumstellung
  NSCalendarDate *lastMarch;
  
  lastMarch =
    [NSCalendarDate dateWithYear:self->year month:3 day:31
                    hour:0 minute:0 second:0 timeZone:self->timeZone];
  return [lastMarch dateByAddingYears:0 months:0 days:-[lastMarch dayOfWeek]];
}

- (NSCalendarDate *)wintertimeChange {
  // TODO: whats that? That depends on the timezone and can't be calculated?
  // Winterzeitumstellung
  int y    = self->year;
  int mDay = y < 1996 ? 30 : 31;
  NSCalendarDate *lastOct;
  
  lastOct =
    [NSCalendarDate dateWithYear:self->year
                    month:(y < 1996 ? 9 : 10)
                    day:mDay
                    hour:0 minute:0 second:0 timeZone:self->timeZone];
  return [lastOct dateByAddingYears:0 months:0
                  days:-[lastOct dayOfWeek]];
}

- (NSCalendarDate *)mothersDay {
  NSCalendarDate *date, *may1;
  int d;
  
  may1 = [self firstMay];
  d = 14 - [may1 dayOfWeek];
  date = [may1 dateByAddingYears:0 months:0 days:d];
  if ([date isEqual:[self whitsun]]) { // to avoid incorrect calc in 2005
    d = 7 - [may1 dayOfWeek];
    date = [may1 dateByAddingYears:0 months:0 days:d];
  }
  return date;
}

- (void)setFirstAdvent:(NSCalendarDate *)_fadvent {
  ASSIGN(self->firstAdvent,_fadvent);
}
- (NSCalendarDate *)firstAdvent {
  // Erster Advent
  if (self->firstAdvent != nil)
    return self->firstAdvent;
  
  [self setFirstAdvent:
          [[self christmasEve] dateByAddingYears:0 months:0
                               days: (-21 - [[self christmasEve] dayOfWeek])]];
  return self->firstAdvent;
}

- (NSCalendarDate *)adventDateWithOffset:(int)_offset {
  /* for holidays relative to first advent */
  return [[self firstAdvent] dateByAddingYears:0 months:0 days:_offset];
}

- (NSCalendarDate *)dayOfPrayerAndRepetance {
  return [self adventDateWithOffset:-11]; /* Buss- und Bettag */
}
- (NSCalendarDate *)deathsSunday {
  return [self adventDateWithOffset:-7]; /* Totensonntag */
}
- (NSCalendarDate *)secondAdvent {
  return [self adventDateWithOffset:7]; /* zweiter Advent */
}
- (NSCalendarDate *)thirdAdvent {
  return [self adventDateWithOffset:14]; /* dritter Advent */
}
- (NSCalendarDate *)fourthAdvent {
  return [self adventDateWithOffset:21]; /* vierter Advent */
}

/* holidays dictionary */

- (void)addHolidayKey:(NSString *)_dateKey defaultKey:(NSString *)_defKey
  withName:(NSString *)_key toList:(NSMutableDictionary *)_list
{
  NSString *flagKey;
  NSArray  *a;
  
  flagKey = @"scheduler_show_holiday_";
  flagKey = [flagKey stringByAppendingString:_defKey];

  if (![self->userDefaults boolForKey:flagKey])
    return;

  a = [_list objectForKey:_dateKey];
  if (a == nil)
    a = [NSArray array];
  if (![a containsObject:_key])
    a = [a arrayByAddingObject:_key];
  
  [_list setObject:a forKey:_dateKey];
}

- (void)addHolidayKey:(NSString *)_dateKey withName:(NSString *)_key
  toList:(NSMutableDictionary *)_list
{
  [self addHolidayKey:_dateKey defaultKey:_key withName:_key toList:_list];
}

- (void)addHoliday:(NSCalendarDate *)_day withName:(NSString *)_key
  toList:(NSMutableDictionary *)_list
{
  NSString *dateKey;
  
  dateKey = [_day descriptionWithCalendarFormat:@"%Y-%m-%d"];
  
  [self addHolidayKey:dateKey withName:_key toList:_list];
}

- (void)addHoliday:(NSCalendarDate *)_day withDefKey:(NSString *)_defKey
  withName:(NSString *)_key toList:(NSMutableDictionary *)_list
{
  NSString *dateKey;

  dateKey = [_day descriptionWithCalendarFormat:@"%Y-%m-%d"];

  [self addHolidayKey:dateKey defaultKey:_defKey withName:_key toList:_list];
}

- (void)addEveryYearHolidays:(NSDictionary *)_days
  withDefKey:(NSString *)_defKey
  toList:(NSMutableDictionary *)_list
{
  NSArray *keys;
  int     i, cnt;

  keys = [_days allKeys];
  
  for (i = 0, cnt = [keys count]; i < cnt; i++) {
    NSString *key;
    NSString *dateKey;

    key = [keys objectAtIndex:i];
    dateKey = [[NSString alloc] initWithFormat:@"%i-%@", self->year, key];
    
    if (_defKey == nil) {
      [self addHolidayKey:dateKey withName:[_days objectForKey:key]
            toList:_list];
    }
    else {
      [self addHolidayKey:dateKey defaultKey:_defKey
            withName:[_days objectForKey:key]
            toList:_list];
    }
    [dateKey release];
  }
}

- (void)_addCommonHolidaysToList:(NSMutableDictionary *)md {
  // Ostern
  [self addHoliday:[self goodFriday] withDefKey:@"holidaygroup_bylaw"
	withName:@"goodFriday" toList:md];
  [self addHoliday:[self easter] withDefKey:@"holidaygroup_bylaw"
	withName:@"easter" toList:md];
  [self addHoliday:[self easterMonday] withDefKey:@"holidaygroup_bylaw"
	withName:@"easterMonday" toList:md];
  // Fastnacht
  [self addHoliday:[self shrovetide] withName:@"shrovetide" toList:md];
  // Christi Himmelfahrt
  [self addHoliday:[self ascension] withDefKey:@"holidaygroup_bylaw"
	withName:@"ascension" toList:md];
  // Pfingsten
  [self addHoliday:[self whitsun] withDefKey:@"holidaygroup_bylaw"
	withName:@"whitsun" toList:md];
  [self addHoliday:[self whitmonday] withDefKey:@"holidaygroup_bylaw"
	withName:@"whitmonday" toList:md];
  // Erster Mai
  [self addHoliday:[self firstMay] withDefKey:@"holidaygroup_bylaw"
	withName:@"firstMay" toList:md];
  // Muttertag
  [self addHoliday:[self mothersDay] withName:@"mothersDay" toList:md];
  // Fronleichnam
  [self addHoliday:[self corpurChristi] withDefKey:@"holidaygroup_bylaw"
	withName:@"corpusChristi" toList:md];
  // Sommerzeitumstellung
  [self addHoliday:[self summertimeChange]
	withName:@"summertimeChange" toList:md];
  // Winterzeitumstellung
  [self addHoliday:[self wintertimeChange]
	withName:@"wintertimeChange" toList:md];
  // Weihnachtsabend
  [self addHoliday:[self christmasEve]
	withName:@"christmasEve"     toList:md];
  // Buss- und Bettag
  [self addHoliday:[self dayOfPrayerAndRepetance]
	withDefKey:@"holidaygroup_bylaw" withName:@"dayOfPrayerAndRepetance"
	toList:md];
  // Totensonntag
  [self addHoliday:[self deathsSunday]
	withName:@"deathsSunday"     toList:md];
  // Erster Advent
  [self addHoliday:[self firstAdvent] withDefKey:@"holidaygroup_advent"
	withName:@"firstAdvent" toList:md];
  // Zweiter Advent
  [self addHoliday:[self secondAdvent] withDefKey:@"holidaygroup_advent"
	withName:@"secondAdvent" toList:md];
  // Dritter Advent
  [self addHoliday:[self thirdAdvent] withDefKey:@"holidaygroup_advent"
	withName:@"thirdAdvent" toList:md];
  // Vierter Advent
  [self addHoliday:[self fourthAdvent] withDefKey:@"holidaygroup_advent"
	withName:@"fourthAdvent" toList:md];
}

- (NSDictionary *)everyYearHolidaysMap {
  return [holidaysConfig objectForKey:@"scheduler_everyyear_holidays"];
}
- (NSDictionary *)holidaysMapForYear:(int)_year {
  NSString *key;
  
  key = [NSString stringWithFormat:@"scheduler_%i_holidays", _year];
  return [holidaysConfig objectForKey:key];
}

- (NSDictionary *)defCustomEveryYearHolidays {
  return [self->userDefaults dictionaryForKey:
		@"scheduler_custom_everyyear_holidays"];
}
- (NSDictionary *)defCustomHolidays {
  /* those are for a specific year */
  return [self->userDefaults dictionaryForKey:@"scheduler_custom_holidays"];
}

- (void)_addConfigHolidaysToList:(NSMutableDictionary *)md {
  NSDictionary *everyYear;
  NSDictionary *thisYear;
  NSDictionary *customEveryYear;
  NSDictionary *custom;

  everyYear = [self everyYearHolidaysMap];
  thisYear  = [self holidaysMapForYear:self->year];
  
  customEveryYear = [self defCustomEveryYearHolidays];
  custom          = [self defCustomHolidays];
  
  /* adding custom everyYear holidays */
  if (customEveryYear != nil) {
    [self addEveryYearHolidays:customEveryYear
	  withDefKey:@"holidaygroup_custom_private" toList:md];
  }
  
  /* adding custom holidays */
  if (custom != nil) {
    NSDictionary *thisYear;
    NSString *key;
    
    key      = [NSString stringWithFormat:@"%i", self->year];
    thisYear = [custom objectForKey:key];
    if (thisYear != nil) {
      [self addEveryYearHolidays:thisYear
	    withDefKey:@"holidaygroup_custom_private" toList:md];
    }
  }
  
  /* adding everyYear holidays */
  if (everyYear != nil) {
      NSArray *allGrps;
      int i, cnt;

      allGrps = [everyYear allKeys];

      for (i = 0, cnt = [allGrps count]; i < cnt; i++) {
        id key, val;
        NSString *defKey = nil;
        
        key = [allGrps objectAtIndex:i];
        val = [everyYear objectForKey:key];
        if ([val isKindOfClass:[NSString class]]) {
          val = [NSDictionary dictionaryWithObject:val forKey:key];
        }
        else {
          defKey = 
	    [@"holidaygroup_" stringByAppendingString:[key stringValue]];
        }
        [self addEveryYearHolidays:val withDefKey:defKey toList:md];
      }
  }

  /* adding thisYear holidays */
  if (thisYear != nil) {
      NSArray *keys;
      int      i, cnt;
      
      keys = [thisYear allKeys];
      
      for (i = 0, cnt = [keys count]; i < cnt; i++) {
        NSArray      *holiKeys;
        NSDictionary *holiDict;
        NSString     *key;
        int          j, holiCnt;

        key      = [keys objectAtIndex:i];
        holiDict = [thisYear objectForKey:key];
        holiKeys = [holiDict allKeys];

        for (j = 0, holiCnt = [holiKeys count]; j < holiCnt; j++) {
          NSString *dateKey;
          NSString *holiKey;
          NSString *holiName;
          NSString *defaultKey;

          holiKey  = [holiKeys objectAtIndex:j];
          dateKey  = [NSString stringWithFormat:@"%i-%@", self->year, holiKey];
          // custom all is non localized
          holiName = ([key isEqualToString:@"custom_all"])
            ? [holiDict objectForKey:holiKey]
            : [NSString stringWithFormat:@"%@_%@",
                        [holiDict objectForKey:holiKey], key];
          defaultKey = @"holidaygroup_";
          defaultKey = [defaultKey stringByAppendingString:key];

          [self addHolidayKey:dateKey defaultKey:defaultKey
                withName:holiName toList:md];
        }
      }
  }
}

- (void)setHolidays:(NSDictionary *)_holidays {
  ASSIGN(self->holidays, _holidays);
}
- (NSDictionary *)holidays {
  // TODO: cleanup
  NSMutableDictionary *md;
  
  if (self->holidays)
    return self->holidays;
  
  md = [NSMutableDictionary dictionaryWithCapacity:16];
  [self _addConfigHolidaysToList:md];
  [self _addCommonHolidaysToList:md];
  
  self->holidays = [md copy];
  return self->holidays;
}

- (NSArray *)holidaysOfDate:(NSCalendarDate *)_date {
  NSString *dateKey;
  NSArray  *result;
  char buf[16];
  
  if (_date == nil)
    return nil;
  
  [self setYear:[_date yearOfCommonEra]];
  
  sprintf(buf, "%04i-%02ld-%02ld", self->year,
	  [_date monthOfYear],
	  [_date dayOfMonth]);
  
  dateKey = [[NSString alloc] initWithCString:buf];
  result = [[self holidays] objectForKey:dateKey];
  [dateKey release];
  return result;
}

@end /* SkyHolidayCalculator */

@implementation NSCalendarDate(Easter)

+ (NSCalendarDate *)easterForHolidaysForYear:(int)y timeZone:(NSTimeZone *)_tz{
  // TODO: probably a DUP with something in NGExtensions
  // Ostern
  /* http://www.uni-bamberg.de/~ba1lw1/fkal.html#Algorithmus */
  unsigned m, n;
  int a, b, c, d, e;
  unsigned easterMonth, easterDay;
  
  if ((y > 1699) && (y < 1800)) {
      m = 23;
      n = 3;
  }
  else if ((y > 1799) && (y < 1900)) {
      m = 23;
      n = 4;
  }
  else if ((y > 1899) && (y < 2100)) {
      m = 24;
      n = 5;
  }
  else if ((y > 2099) && (y < 2200)) {
      m = 24;
      n = 6;
  }
  else {
    [self logWithFormat:@"WARNING: cannot calculate easter of year %d", y];
    return nil;
  }
    
  a = y % 19;
  b = y % 4;
  c = y % 7;
  d = (19 * a + m) % 30;
  e = (2 * b + 4 * c + 6 * d + n) % 7;
  
  easterMonth = 3;
  easterDay   = 22 + d + e;
  if (easterDay > 31) {
    easterDay  -= 31;
    easterMonth = 4;
    if (easterDay == 26)
      easterDay = 19;
    if ((easterDay == 25) && (d == 28) && (a > 10))
      easterDay = 18;
  }

  return
    [[[NSCalendarDate alloc] initWithYear:y month:easterMonth day:easterDay
			     hour:0 minute:0 second:0 timeZone:_tz]
      autorelease];
}

@end /* NSCalendarDate(Easter) */
