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

#include <OGoFoundation/OGoContentPage.h>

@class NSTimeZone, NSCalendarDate, NSArray, NSMutableArray, NSDictionary;
@class NSMutableSet;

// TODO: move proposal logic to a separate object?
// TODO: this code needs MAJOR cleanups

@interface LSWAppointmentProposal : OGoContentPage
{
@private
  int earliestStartTime;
  int latestFinishTime;
  id  appointment;
  id  item;
  id  dayItem;
  id  editor;
  int idx;
  int itemIdx;
  int interval; /* in minutes */
  int duration; /* in minutes */

  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSTimeZone     *timeZone;
  
  NSArray        *searchList;
  NSMutableArray *minuteCaptionList;
  NSMutableArray *allDayHours;
  NSArray        *hourCaptionList;
  NSDictionary   *sortedDates;
  NSDictionary   *calculatedTable;
  id             calcItem;
  id             searchTeam;

  NSMutableArray *resources;
  NSMutableSet   *addedResources;
  id             resource;
  int            resourceIndex;

  NSMutableArray *participants;
  NSMutableArray *selectedParticipants;
  
  NSMutableArray *resultList;
  NSMutableArray *removedParticipants;  
  NSMutableArray *enterprise;
  NSString       *searchText;
  NSMutableArray *addedParticipants;

  BOOL addedResourcesWasSet;
  BOOL showExtended;  
  BOOL hasSearched;
}
@end

#include "common.h"
#include <NGMime/NGMimeType.h>

@interface NSObject(LSWAppointmentProposal_PRIVATE)
- (void)setStartDateFromProposal:(NSCalendarDate *)_date;
- (void)setEndDateFromProposal:(NSCalendarDate *)_date;
- (void)setResources:(id)_resources;
- (void)setMoreResources:(id)_resources;
- (void)setParticipantsFromProposal:(id)_part;
@end

static int compareDates(id part1, id part2, void* context) {
  return [part1 caseInsensitiveCompare:part2];
}

@implementation LSWAppointmentProposal

static NSArray *hourArray;
static NSArray *minuteArray;

static inline NSCalendarDate *_getDate(LSWAppointmentProposal*,int,int,int,
                                       NSString*);
static inline NSString *_getTimeStringFromInt(LSWAppointmentProposal*,int);
static inline int _getIntFromTimeString(LSWAppointmentProposal*,NSString*);
static inline NSDictionary *_getTimeEntry(LSWAppointmentProposal*,NSArray*,
                                          NSString*, int, int);

+ (void)initialize {
  [super initialize];

  if (hourArray == nil) {
    hourArray = [[NSArray allocWithZone:[self zone]]
                          initWithObjects:@"0", @"1", @"2", @"3", @"4", @"5",
                                          @"6", @"7", @"8", @"9", @"10", @"11",
                                          @"12", @"13", @"14", @"15", @"16",
                                          @"17", @"18", @"19", @"20", @"21",
                                          @"22", @"23", nil];
  }
  if (minuteArray == nil) {
    minuteArray = [[NSArray allocWithZone:[self zone]]
                            initWithObjects:@"00", @"30", nil];
  }
}

+ (int)version {
  return [super version] + 2;
}

- (id)init {
  if ((self = [super init])) {    
    self->earliestStartTime = -1;
    self->latestFinishTime  = -1;

    self->duration = 60;
    self->interval = 30;
    
    self->resources    = [[NSMutableArray alloc] init];
    self->participants = [[NSMutableArray alloc] init];
    //[self->participants addObject:[[self session] activeAccount]];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->searchTeam);
  RELEASE(self->searchText);
  RELEASE(self->startDate);
  RELEASE(self->endDate);
  RELEASE(self->appointment);
  RELEASE(self->item);
  RELEASE(self->searchList);
  RELEASE(self->editor);
  RELEASE(self->hourCaptionList);
  RELEASE(self->minuteCaptionList);
  RELEASE(self->sortedDates);
  RELEASE(self->allDayHours);
  RELEASE(self->calcItem);
  RELEASE(self->calculatedTable);
  RELEASE(self->resources);
  RELEASE(self->selectedParticipants);
  RELEASE(self->participants);
  RELEASE(self->timeZone);
  [super dealloc];
}
#endif

- (void)syncAwake {
  [super syncAwake];

  if (self->timeZone == nil) {
    NSTimeZone *tz  = nil;
    NSString   *tzA = nil;
    
    if ((tz = [[self context] valueForKey:@"SkySchedulerTimeZone"]) == nil)
      tz = [[self session] timeZone];

    self->timeZone = tz;
    RETAIN(self->timeZone);

    tzA = [self->timeZone abbreviation]; 

    self->startDate = RETAIN(_getDate(self, 9, 0, 0, tzA));
    self->endDate   = RETAIN(_getDate(self, 18, 59, 59, tzA));

    [self runCommand:@"person::enterprises",
          @"persons",     self->participants,
          @"relationKey", @"enterprises", nil];
  }

  if (self->earliestStartTime == -1)
    self->earliestStartTime = 9 * 60;

  if (self->latestFinishTime == -1)
    self->latestFinishTime = 18 * 60;

  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
}

// Actions

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)search {
  NSMutableArray *resourceNames = nil;
  NSMutableArray *categories    = nil;
  NSEnumerator   *enumerator    = nil;
  id             obj            = nil;
  NSString       *str;

  str = [[self labels] valueForKey:@"resCategory"];

  if (str == nil) str = @"resCategory";

  str           = [NSString stringWithFormat:@" (%@)", str];
  resourceNames = [[NSMutableArray alloc] init];
  categories    = [[NSMutableArray alloc] init];
  enumerator    = [self->resources objectEnumerator];

  while ((obj = [enumerator nextObject])) {

    if ([obj hasSuffix:str]) {
      [categories addObject:[obj substringWithRange:
                                 NSMakeRange(0, [obj length] - [str length])]];
    }
    else
      [resourceNames addObject:obj];
#if 0      
    NSArray *comp;

    comp = [obj componentsSeparatedByString:@" ("];
    
    if ([comp count] == 1)
      [resourceNames addObject:obj];
    else {
      [categories addObject:[comp objectAtIndex:0]];
    }
#endif    
  }
  if ((self->startDate == nil) || (![self->startDate isNotNull]))
    return nil;
  if ((self->endDate == nil) || (![self->endDate isNotNull]))
    return nil;

  if ((self->duration < 0) || (self->interval < 0) ||
      (self->earliestStartTime < 0) || (self->latestFinishTime < 0))
    return nil;
    
  if (self->searchList != nil) {
    RELEASE(self->searchList); self->searchList = nil;
  }

  self->searchList =
    [self runCommand:@"appointment::proposal",
          @"participants", self->selectedParticipants,
          @"resources",    resourceNames,
          @"categories",   categories,          
          @"startDate",    self->startDate,
          @"endDate",      self->endDate,
          @"timeZone",     self->timeZone,
          @"duration",     [NSNumber numberWithInt:self->duration], 
          @"startTime",    [NSNumber numberWithInt:self->earliestStartTime],
          @"endTime",      [NSNumber numberWithInt:self->latestFinishTime],
          @"interval",     [NSNumber numberWithInt:self->interval],
          nil];

  RETAIN(self->searchList);
  RELEASE(resourceNames); resourceNames = nil;
  RELEASE(categories);    categories    = nil;

  { /* build captions */
    int i, cnt = 0;
    int st, lf = 0;
    int add    = 0;

    st = self->earliestStartTime;
    lf = self->latestFinishTime;
    st = st / 60;
    lf = lf / 60;

    lf = (lf < st) ? st : lf;    
    if (self->hourCaptionList != nil)
      RELEASE(self->hourCaptionList);

    add = ((self->latestFinishTime % 60) == 0) ? 0 : 1;
    self->hourCaptionList =
      [hourArray subarrayWithRange:NSMakeRange(st, lf - st + add)];
    RETAIN(self->hourCaptionList);

    if (self->minuteCaptionList != nil)
      RELEASE(self->minuteCaptionList);

    self->minuteCaptionList = [[NSMutableArray allocWithZone:[self zone]]
                                        initWithCapacity:48];

    if (self->allDayHours != nil)
      RELEASE(self->allDayHours);

    self->allDayHours = [[NSMutableArray allocWithZone:[self zone]]
                                              initWithCapacity:64];
    
    for (i = 0, cnt = [self->hourCaptionList count]; i < cnt; i++) {
      NSString *str = [self->hourCaptionList objectAtIndex:i];
      NSString *dum = nil;

      if ([str length] < 2)
        dum = @"0";
      else
        dum = @"";
      
      [self->minuteCaptionList addObjectsFromArray:minuteArray];
      
      [self->allDayHours addObject:[NSString stringWithFormat:@"%@%@:%@",
                                             dum, str, @"00"]];
      [self->allDayHours addObject:[NSString stringWithFormat:@"%@%@:%@",
                                             dum, str, @"30"]];
    }
  }
  { /* build day-arrays */
    NSMutableDictionary *dict;
    NSEnumerator        *enumerator;
    id                  obj;
    NSString            *date  = nil;
    NSMutableArray      *dates = nil;
    
    dict = [[NSMutableDictionary alloc] initWithCapacity:64];
    enumerator = [self->searchList objectEnumerator];
    
    while ((obj = [enumerator nextObject]) != nil) {
      NSCalendarDate *sD;
      NSString *str;
      
      sD = [(NSDictionary *)obj objectForKey:@"startDate"];
      str = [[NSString alloc] initWithFormat:@"%04d-%02d-%02d",
                              [sD yearOfCommonEra],
                              [sD monthOfYear],
                              [sD dayOfMonth]];
      if (date == nil) {
        date = str;
        dates = [NSMutableArray arrayWithCapacity:64];
        [dict setObject:dates forKey:date];
      }
      else {
        if (![str isEqualToString:date]) {
          date = str;
          dates = [NSMutableArray arrayWithCapacity:64];
          [dict setObject:dates forKey:date];
        }
      }
      [dates addObject:obj];
      [str release]; str = nil;
    }
    [self->sortedDates release]; self->sortedDates = nil;
    self->sortedDates = dict;
    dict = nil;
  }
  { /* build timeslices */
    NSMutableDictionary *dict     = nil;
    NSEnumerator        *dateEnum = [self->sortedDates keyEnumerator];
    id                  dateObj   = nil;

    dict = [NSMutableDictionary dictionaryWithCapacity:64];
    
    while ((dateObj = [dateEnum nextObject])) {
      id             obj         = nil;
      NSMutableArray *array      = nil;
      int            i, cnt      = 0;

      array = [NSMutableArray arrayWithCapacity:48];

      for (i = 0, cnt = [self->allDayHours count]; i < cnt; i++) {
        NSDictionary *entry;
        
        obj = [self->allDayHours objectAtIndex:i];
        
        entry = _getTimeEntry(self, [self->sortedDates objectForKey:dateObj],
                              obj, i, cnt);
        [array addObject:entry];
      }
      [dict setObject:array forKey:dateObj];
    }
    ASSIGN(self->calculatedTable, dict);
  }
  self->hasSearched = YES;
  return nil;
}

- (id)takeAppointment {
  NSDictionary *obj;
  id e;
  
  [self leavePage];
  
  obj = [(NSDictionary *)self->item objectForKey:@"dates"];
  e   = self->editor;
  if (e == nil) {
    [[self session] transferObject:[obj objectForKey:@"startDate"] 
                    owner:self];
    e = [[self session] instantiateComponentForCommand:@"new"
                        type:[NGMimeType mimeType:@"eo/date"]];
  }
  [e setStartDateFromProposal:[obj objectForKey:@"startDate"]];
  [e setEndDateFromProposal:[obj objectForKey:@"endDate"]];

  /* move to own method?! */
  {
    id             tmp         = nil;
    NSEnumerator   *enumerator = nil;
    NSMutableArray *resArray   = nil;
    NSMutableArray *moreRes    = nil;
    NSString *str;

    if ((str = [[self labels] valueForKey:@"resCategory"]) == nil)
      str = @"resCategory";
    
    str = [NSString stringWithFormat:@" (%@)", str];
    
    resArray   = [NSMutableArray arrayWithCapacity:4];
    moreRes    = [NSMutableArray arrayWithCapacity:4];
    enumerator = [self->resources objectEnumerator];
    
    while ((tmp = [enumerator nextObject]) != nil) {
      if (![tmp hasSuffix:str]) {
        if (![resArray containsObject:tmp]) {
          [moreRes removeObject:tmp];
          [resArray addObject:tmp];
        }
      }
      else {
        NSString       *catName;
        NSArray        *res      = nil;
        NSMutableArray *allRes   = nil;
        NSEnumerator   *resEnum  = nil;
        id             aRes      = nil;
        BOOL           resHasObj = NO;       
	NSRange        r;

	r = [tmp rangeOfString:str];
        catName = (r.length > 0)
	  ? [tmp substringToIndex:r.location]
          : tmp;
	
        allRes = [[self runCommand:@"appointmentresource::categories",
                        @"category", catName, nil] mutableCopy];
        
        res = [self runCommand:@"appointment::used-resources",
                    @"startDate", [obj valueForKey:@"startDate"],
                    @"endDate",   [obj valueForKey:@"endDate"],
                    @"category",  catName, nil];
        resEnum = [res objectEnumerator];
        while ((aRes = [resEnum nextObject])) {
          [allRes removeObject:aRes];
        }
        resEnum = [allRes objectEnumerator];
        resHasObj = NO;
        while ((aRes = [resEnum nextObject]) != nil) {
          if (![resArray containsObject:aRes]) {
            if (!resHasObj) {
              resHasObj =YES;
              [resArray addObject:aRes];
            }
            else {
              if (![moreRes containsObject:aRes]) {
                [moreRes addObject:aRes];
              }
            }
          }
        }
        [allRes release]; allRes = nil;
      }
    }
    [e setResources:resArray];
    [e setMoreResources:moreRes];
  }
  [e setParticipantsFromProposal:self->selectedParticipants];
  [self enterPage:e];
  return nil;
}

/* accessors */

- (void)setShowExtended:(BOOL)_flag {
  self->showExtended = _flag;
}
- (BOOL)showExtended {
  return self->showExtended;
}

- (void)setAppointment:(id)_app {
  ASSIGN(self->appointment, _app);
}
- (id)appointment {
  return self->appointment;
}

- (void)setItem:(id)_it {
  ASSIGN(self->item, _it);
}
- (id)item {
  return self->item;
}

- (void)setDayItem:(id)_it {
  ASSIGN(self->dayItem, _it);
}
- (id)dayItem {
  return self->dayItem;
}

- (void)setIdx:(int)_idx {
  self->idx = _idx;
}
- (int)idx {
  return self->idx;
}

- (id)sortedDates {
  return self->sortedDates;
}

- (BOOL)resultListHasComponents {
  return ([self->searchList count] > 0) ? YES : NO;
}

- (NSString *)configuredTimeZoneName {
  NSString *tz;

  tz = [[[self session] userDefaults] objectForKey:@"timezone"];
  if ([tz length] == 0)
    tz = @"GMT";
  
  return tz;
}

// TODO: clean up this startDate/endDate conversions

- (void)setStartDate:(NSString *)_startDate {
  NSString *s;
  
  s  = [[NSString alloc] initWithFormat:@"%@ 00:00:00 %@",
                           _startDate, [self configuredTimeZoneName]];
  
  [self->startDate autorelease]; self->startDate = nil;
  self->startDate =
    [[NSCalendarDate alloc] initWithString:s
                            calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  [s release];
}

- (NSString *)startDate {
  if (self->startDate == nil) return nil;
  return [self->startDate descriptionWithCalendarFormat:@"%Y-%m-%d"];
}

- (void)setEndDate:(NSString *)_endDate {
  NSString *s;
  
  s = [[NSString alloc] initWithFormat:@"%@ 23:59:59 %@",
                        _endDate, [self configuredTimeZoneName]];
  
  [self->endDate autorelease]; self->endDate = nil;
  self->endDate =
    [[NSCalendarDate alloc] initWithString:s
                            calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  [s release];
}

- (NSString *)endDate {
  if (self->endDate == nil) return nil;
  return [self->endDate descriptionWithCalendarFormat:@"%Y-%m-%d"];
}

- (NSString *)duration {
  return _getTimeStringFromInt(self, self->duration);
}

- (void)setDuration:(NSString *)_dur {
  self->duration = _getIntFromTimeString(self, _dur);
}

- (id)interval {
  return _getTimeStringFromInt(self, self->interval);
}
- (void)setInterval:(NSString *)_interval {
  self->interval = _getIntFromTimeString(self, _interval);
}

- (NSString *)earliestStartTime {
  return _getTimeStringFromInt(self, self->earliestStartTime);
}
- (void)setEarliestStartTime:(NSString *)_str {
  self->earliestStartTime = _getIntFromTimeString(self, _str);
}

- (NSString *)latestFinishTime {
  return _getTimeStringFromInt(self, self->latestFinishTime);
}
- (void)setLatestFinishTime:(NSString *)_str {
  self->latestFinishTime = _getIntFromTimeString(self, _str);
}

- (id)searchList {
  return self->searchList;
}

- (NSString *)appointmentStartDate {
  return [[(NSDictionary *)self->item objectForKey:@"startDate"]
                descriptionWithCalendarFormat:@"%Y-%m-%d"];
}
- (NSString *)appointmentStartTime {
  return [[(NSDictionary *)self->item objectForKey:@"startDate"]
                descriptionWithCalendarFormat:@"%H:%M"];
}
- (NSString *)appointmentEndDate {
  return [[(NSDictionary *)self->item objectForKey:@"endDate"]
                descriptionWithCalendarFormat:@"%Y-%m-%d"];
}
- (NSString *)appointmentEndTime {
  return [[(NSDictionary *)self->item objectForKey:@"endDate"]
                descriptionWithCalendarFormat:@"%H:%M"];
}

- (NSArray *)hourCaptionList {
  return self->hourCaptionList;
}

- (NSArray *)minuteCaptionList {
  return self->minuteCaptionList;
}

- (id)dayValue {
  return [[self->item allKeys] lastObject];
}

- (NSArray *)allDayHours {
  return self->allDayHours;
}

- (NSArray *)allSortedDates {
  return [self->sortedDates allKeys];
}

- (BOOL)hasNoEntries {
  return ([self->calculatedTable count] > 0) ? NO : YES;
}

- (NSDictionary *)calculatedTable {
  return self->calculatedTable;
}

- (NSArray *)calcTableKeys {
  return [[self->calculatedTable allKeys] sortedArrayUsingFunction:compareDates
                                          context:NULL];
}

- (void)setCalcItem:(id)_id {
  ASSIGN(self->calcItem, _id);
}
- (id)calcItem {
  return self->calcItem;
}

- (NSArray *)calcArray {
  if (self->calcItem == nil)
    return nil;
  return [self->calculatedTable objectForKey:self->calcItem];
}
- (int)itemIdx {
  return self->itemIdx;
}
- (void)setItemIdx:(int)_idx {
  self->itemIdx = _idx;
}

- (BOOL)hasSearched {
  return self->hasSearched;
}

- (int)noOfCols {
  id  d = [[[self session] userDefaults] objectForKey:@"scheduler_no_of_cols"];
  int n = [d intValue];
  
  return (n > 0) ? n : 2;
}

- (BOOL)isEditorPage {
  return (self->editor == nil) ? NO : YES;
}

- (id)tabKey {
  return @"search";
}

- (void)addResources:(NSArray *)_res {
  [self->resources addObjectsFromArray:_res];
}
- (void)setResources:(id)_res {
  ASSIGN(self->resources, _res);
}
- (NSArray *)resources {
  return self->resources;
}

- (void)setSelectedParticipants:(NSArray *)_array {
  ASSIGN(self->selectedParticipants, _array);
}
- (id)selectedParticipants {
  return self->selectedParticipants;
}

- (void)setParticipantsFromGids:(id)_gids {
  NSMutableArray *pgids      = nil;
  NSMutableArray *tgids      = nil;    
  NSEnumerator   *enumerator = nil;
  id             gid         = nil;
  NSMutableArray *result     = nil;

  pgids      = [[NSMutableArray alloc] init];
  tgids      = [[NSMutableArray alloc] init];
  result     = [[NSMutableArray alloc] init];
  enumerator = [_gids objectEnumerator];
  
  while ((gid = [enumerator nextObject])) {
    if ([[gid entityName] isEqualToString:@"Person"]) {
      [pgids addObject:gid];
    }
    else if ([[gid entityName] isEqualToString:@"Team"]) {
      [tgids addObject:gid];
    }
    else {
      NSLog(@"WARNING: unknown gid %@", gid);
    }
  }
  if ([pgids count] > 0)
    [result addObjectsFromArray:[self runCommand:@"person::get-by-globalID",
                                      @"gids", pgids, nil]];
  if ([tgids count] > 0)
    [result addObjectsFromArray:[self runCommand:@"team::get-by-globalID",
                                      @"gids", tgids, nil]];

  [self->participants addObjectsFromArray:result];
  RELEASE(result); result = nil;
  RELEASE(tgids);  tgids  = nil;
  RELEASE(pgids);  pgids  = nil;    
}

- (void)setParticipants:(id)_part {
  ASSIGN(self->participants, _part);
}
- (NSArray *)participants {
  return self->participants;
}

- (BOOL)isEvenItem {
  if ((self->idx & 1) == 1) {
    return NO;
  }
  return YES;
}

- (BOOL)isEvenItemNotNull {
  if (self->idx == 0)
    return NO;
  return [self isEvenItem];
}
- (BOOL)isParticipantChecked {
  return YES;
}

- (BOOL)isResultEntryChecked {
  return NO;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"appointment"])
    [self setAppointment:_value];
  else if ([_key isEqualToString:@"editor"]) {
    ASSIGN(self->editor, _value);
  }
  else if ([_key isEqualToString:@"startDate"]) {
    ASSIGN(self->startDate, _value);
  }
  else if ([_key isEqualToString:@"endDate"]) {
    ASSIGN(self->endDate, _value);
  }
  else if ([_key isEqualToString:@"resources"]) {
    id tmp = self->resources;
    self->resources = [_value mutableCopy];
    RELEASE(tmp);
  }
  else if ([_key isEqualToString:@"participants"]) {
    id tmp = self->participants;
    self->participants = [_value mutableCopy];
    RELEASE(tmp);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"appointment"])
    return [self appointment];
  
  return [super valueForKey:_key];
}

/* functions */

static inline NSCalendarDate *_getDate(LSWAppointmentProposal *self,
                                       int _h, int _m, int _s, NSString *_tzA)
{
  NSString *ds = nil;

  ds = [[NSCalendarDate date] descriptionWithCalendarFormat:@"%Y-%m-%d"];
  ds = [NSString stringWithFormat:@"%@ %d:%d:%d %@", ds, _h, _m, _s, _tzA];

  return [NSCalendarDate dateWithString:ds
                         calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
}

static inline NSString *_getTimeStringFromInt(LSWAppointmentProposal *self,
                                                int _number) {
  if (_number < 0) {
    return @"01:00";
  }
  else {
    int hour, min;

    min = _number % 60;

    if (_number > 59)
      hour = _number / 60;
    else
      hour = 0;
    return [NSString stringWithFormat:@"%02i:%02i", hour, min];
  }
  return nil;
}

static inline int _getIntFromTimeString(LSWAppointmentProposal *self,
                                         NSString *_str) {
  if (_str == nil) {
    return -1;
  }
  else {
    int hour, min;

    hour = [[_str substringToIndex:2] intValue];
    min  = [[_str substringFromIndex:3] intValue];
    
    if ((hour < 0) || (hour > 23))
      hour = 1;
    if ((min < 0) || (min > 59))
      min = 0;
    
    return hour * 60 + min;
  }
}

static inline id _isStartTime(LSWAppointmentProposal *self, NSArray *_dates,
                              NSString *_time) {
  NSEnumerator *enumerator;
  NSDictionary *obj;

  enumerator = [_dates objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if (![[obj objectForKey:@"kind"] isEqualToString:@"start"])
      continue;
    
    // TODO: fix this hack
    if ([[[obj objectForKey:@"startDate"]
               descriptionWithCalendarFormat:@"%H:%M"] isEqualToString:_time])
      return obj;
  }
  return nil;
}

static inline BOOL _isStartOrEndTime(LSWAppointmentProposal *self,
                                     NSArray *_dates, NSString *_time,
                                     int _pos, int _cnt) {
  BOOL result = NO;

  if (_pos == 0)
    result = ((self->earliestStartTime % 60) == 0) ? NO : YES;
  else if (_pos == (_cnt - 1))
    result = ((self->latestFinishTime % 60) == 0) ? NO : YES;
  return result;
}

static inline BOOL _isFreeTime(NSArray *_dates, NSString *_time) {
  // TODO: cleanup this mess
  NSEnumerator   *enumerator;
  NSDictionary   *obj;
  NSTimeInterval d = 0.0;
  
  d = [[NSCalendarDate dateWithString:[_time stringByAppendingString:@" 1"]
                       calendarFormat:@"%H:%M %m"]
                       timeIntervalSinceReferenceDate];
  
  enumerator = [_dates objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSTimeInterval sD, eD = 0;
    NSString *s;
    
    s = [[[obj objectForKey:@"startDate"]
               descriptionWithCalendarFormat:@"%H:%M"]
          stringByAppendingString:@" 1"];
    sD = [[NSCalendarDate dateWithString:s calendarFormat:@"%H:%M %m"]
                          timeIntervalSinceReferenceDate];
    
    s = [[[obj objectForKey:@"endDate"]
               descriptionWithCalendarFormat:@"%H:%M"]
          stringByAppendingString:@" 1"];
    eD = [[NSCalendarDate dateWithString:s calendarFormat:@"%H:%M %m"]
                          timeIntervalSinceReferenceDate];
    
    if (((d - sD) >= 0) && ((d - eD) < 0))
      return YES;
  }
  return NO;
}

static inline NSDictionary *_getTimeEntry(LSWAppointmentProposal *self,
                                          NSArray *_dates, NSString *_time,
                                          int _pos, int _count) 
{
  // TODO: make this a method!
  NSMutableDictionary *result;
  NSString            *status;
  id                  obj     = nil;
  
  if (_isStartOrEndTime(self, _dates, _time, _pos, _count))
    status = @"startOrEnd";
  else if ((obj = _isStartTime(self, _dates, _time)) != nil)
    status = @"startTime";
  else if (_isFreeTime(_dates, _time))
    status = @"free";
  else
    status = @"unfree";

  // TODO: use immutable dict?
  result = [NSMutableDictionary dictionaryWithCapacity:2];
  [result setObject:status forKey:@"status"];
  if (obj != nil)
    [result setObject:obj forKey:@"dates"];
  return result;
}

@end /* LSWAppointmentProposal */
