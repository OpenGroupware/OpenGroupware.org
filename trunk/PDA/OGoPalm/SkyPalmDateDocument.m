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

#include <OGoPalm/SkyPalmDateDocument.h>
#include <OGoPalm/SkyPalmDateDocumentCopy.h>
#include <NGExtensions/NSCalendarDate+misc.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <EOControl/EOSortOrdering.h>
#include <OGoPalm/SkyPalmConstants.h>

#include <OGoCycleDateCalculator.h>

@implementation SkyPalmDateDocument

- (id)init {
  if ((self = [super init])) {
    self->description   = nil;
    self->enddate       = nil;
    self->note          = nil;
    self->repeatEnddate = nil;
    self->startdate     = nil;
    self->exceptions    = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->description);
  RELEASE(self->enddate);
  RELEASE(self->note);
  RELEASE(self->repeatEnddate);
  RELEASE(self->startdate);
  RELEASE(self->exceptions);
  [super dealloc];
}
#endif

// accessors
- (void)setAlarmAdvanceTime:(int)_time {
  self->alarmAdvanceTime = _time;
}
- (int)alarmAdvanceTime {
  return self->alarmAdvanceTime;
}

- (void)setAlarmAdvanceUnit:(int)_unit {
  self->alarmAdvanceUnit = _unit;
}
- (int)alarmAdvanceUnit {
  return self->alarmAdvanceUnit;
}

- (void)setDescription:(NSString *)_desc {
  ASSIGN(self->description,_desc);
}
- (NSString *)description {
  return self->description;
}
- (NSString *)nonEmptyDescription {
  if ([self->description length]) return self->description;
  return @"<empty>";
}

- (void)setEnddate:(NSCalendarDate *)_enddate {
  ASSIGN(self->enddate,_enddate);
}
- (NSCalendarDate *)enddate {
  return self->enddate;
}

- (void)setIsAlarmed:(BOOL)_flag {
  self->isAlarmed = _flag;
}
- (BOOL)isAlarmed {
  return self->isAlarmed;
}

- (void)setIsUntimed:(BOOL)_flag {
  self->isUntimed = _flag;
}
- (BOOL)isUntimed {
  return self->isUntimed;
}

- (void)setNote:(NSString *)_note {
  if ([_note indexOfString:@"\r\n"])
    _note = [[_note componentsSeparatedByString:@"\r\n"]
                    componentsJoinedByString:@"\n"];
  ASSIGN(self->note,_note);
}
- (NSString *)note {
  return self->note;
}

- (void)setRepeatEnddate:(NSCalendarDate *)_enddate {
  ASSIGN(self->repeatEnddate,_enddate);
}
- (NSCalendarDate *)repeatEnddate {
  return self->repeatEnddate;
}

- (void)setRepeatFrequency:(int)_freq {
  self->repeatFrequency = _freq;
}
- (int)repeatFrequency {
  return self->repeatFrequency;
}

- (void)setRepeatOn:(int)_repeatOn {
  self->repeatOn = _repeatOn;
}
- (int)repeatOn {
  return self->repeatOn;
}
- (NSArray *)weekdays {
  int            tmp = [self repeatOn];
  int            cnt = 0;
  NSMutableArray *ma = [NSMutableArray array];

  for (cnt = 0; cnt < 7; cnt++) {
    if ((tmp & 1) == 1) {
      [ma addObject:[NSNumber numberWithInt:cnt]];
    }
    tmp >>= 1;
  }
  return ma;
}

- (void)setRepeatStartWeek:(int)_week {
  self->repeatStartWeek = _week;
}
- (int)repeatStartWeek {
  return self->repeatStartWeek;
}

- (void)setRepeatType:(int)_type {
  self->repeatType = _type;
}
- (int)repeatType {
  return self->repeatType;
}

- (void)setStartdate:(NSCalendarDate *)_date {
  ASSIGN(self->startdate,_date);
}
- (NSCalendarDate *)startdate {
  return self->startdate;
}

- (void)setExceptions:(NSArray *)_exceptions {
  ASSIGN(self->exceptions,_exceptions);
}
- (void)_setExceptions:(NSString *)_exceptions {
  if ((_exceptions == nil) || ([_exceptions isEqualToString:@""]))
    [self setExceptions:[NSArray array]];
  else {
    NSArray        *strs = [_exceptions componentsSeparatedByString:@","];
    NSEnumerator   *e    = [strs objectEnumerator];
    id             one   = nil;
    NSMutableArray *ma   = [NSMutableArray array];

    while ((one = [e nextObject])) {
      NSCalendarDate *date = [NSCalendarDate dateWithString:one
                                             calendarFormat:@"%Y-%m-%d"];
      [ma addObject:date];
    }
    [self setExceptions:ma];
  }
}
- (NSArray *)exceptions {
  return self->exceptions;
}
- (NSString *)_exceptions {
  NSEnumerator   *e  = [[self exceptions] objectEnumerator];
  NSMutableArray *ma = [NSMutableArray array];
  id             one = nil;

  while ((one = [e nextObject])) {
    [ma addObject:[one descriptionWithCalendarFormat:@"%Y-%m-%d"]];
  }
  return [ma componentsJoinedByString:@","];
}

// overwriting
- (NSMutableString *)_md5Source {
  NSMutableString *src  = [NSMutableString stringWithCapacity:32];
  NSCalendarDate  *date;
  NSTimeZone      *gmt  = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  NSString        *timeFormat = nil;

  timeFormat = [self isUntimed]
    ? @"%Y-%m-%d" : @"%Y-%m-%d %H:%M";

  [src appendString:
       [[NSNumber numberWithInt:
                  [self isAlarmed] ? [self alarmAdvanceTime] : 0]
                  stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:
                  [self isAlarmed] ? [self alarmAdvanceUnit] : 0]
                  stringValue]];
  [src appendString:[self description]];
  
  date = [[self enddate] copy];
  [date setTimeZone:gmt];
  [src appendString:
       [date descriptionWithCalendarFormat:timeFormat]];
  RELEASE(date);
  
  [src appendString:
       [[NSNumber numberWithBool:[self isAlarmed]] stringValue]];
  [src appendString:
       [[NSNumber numberWithBool:[self isUntimed]] stringValue]];
  [src appendString:[self note]];
  
  date = [[self repeatEnddate] copy];
  [date setTimeZone:gmt];
  [src appendString:
       [date descriptionWithCalendarFormat:@"%Y-%m-%d"]];
  RELEASE(date);
  
  [src appendString:
       [[NSNumber numberWithInt:[self repeatFrequency]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self repeatOn]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self repeatStartWeek]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self repeatType]] stringValue]];

  date = [[self startdate] copy];
  [date setTimeZone:gmt];
  [src appendString:
       [date descriptionWithCalendarFormat:timeFormat]];
  RELEASE(date);
  
  [src appendString:[self _exceptions]];

  [src appendString:[super _md5Source]];
  return src;
}

- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  [self setAlarmAdvanceTime:
        [[_dict valueForKey:@"alarm_advance_time"] intValue]];
  [self setAlarmAdvanceUnit:
        [[_dict valueForKey:@"alarm_advance_unit"] intValue]];
  [self setDescription:   [_dict valueForKey:@"description"]];
  [self setEnddate:       [_dict valueForKey:@"enddate"]];
  [self setIsAlarmed:     [[_dict valueForKey:@"is_alarmed"] boolValue]];
  [self setIsUntimed:     [[_dict valueForKey:@"is_untimed"] boolValue]];
  [self setNote:          [_dict valueForKey:@"note"]];
  [self setRepeatEnddate: [_dict valueForKey:@"repeat_enddate"]];
  [self setRepeatFrequency:
        [[_dict valueForKey:@"repeat_frequency"] intValue]];
  [self setRepeatOn:      [[_dict valueForKey:@"repeat_on"] intValue]];
  [self setRepeatStartWeek:
        [[_dict valueForKey:@"repeat_start_week"] intValue]];
  [self setRepeatType:    [[_dict valueForKey:@"repeat_type"] intValue]];
  [self setStartdate:     [_dict valueForKey:@"startdate"]];
  [self _setExceptions:   [_dict valueForKey:@"exceptions"]];

  [super takeValuesFromDictionary:_dict];
}

- (NSMutableDictionary *)asDictionary {
  NSMutableDictionary *dict = [super asDictionary];

  [self _takeValue:[NSNumber numberWithInt:self->alarmAdvanceTime]
        forKey:@"alarm_advance_time" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->alarmAdvanceUnit]
        forKey:@"alarm_advance_unit" toDict:dict];
  
  [self _takeValue:self->description forKey:@"description" toDict:dict];
  if (([dict valueForKey:@"description"] == nil) ||
      ([[dict valueForKey:@"description"] length]) == 0)
    [dict takeValue:@" " forKey:@"description"];
  [self _takeValue:self->enddate     forKey:@"enddate" toDict:dict];
  
  [self _takeValue:[NSNumber numberWithBool:self->isAlarmed]
        forKey:@"is_alarmed" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isUntimed]
        forKey:@"is_untimed" toDict:dict];

  [self _takeValue:self->note          forKey:@"note" toDict:dict];
  [self _takeValue:self->repeatEnddate forKey:@"repeat_enddate" toDict:dict];
  
  [self _takeValue:[NSNumber numberWithInt:self->repeatFrequency]
        forKey:@"repeat_frequency" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->repeatOn]
        forKey:@"repeat_on" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->repeatStartWeek]
        forKey:@"repeat_start_week" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->repeatType]
        forKey:@"repeat_type" toDict:dict];

  [self _takeValue:self->startdate forKey:@"startdate" toDict:dict];
  [self _takeValue:[self _exceptions] forKey:@"exceptions" toDict:dict];

  return dict;
}

- (void)takeValuesFromDocument:(SkyPalmDocument *)_doc {
  SkyPalmDateDocument *doc = (SkyPalmDateDocument *)_doc;
  [self setAlarmAdvanceTime:[doc alarmAdvanceTime]];
  [self setAlarmAdvanceUnit:[doc alarmAdvanceUnit]];
  [self setDescription:     [doc description]];
  [self setEnddate:         [doc enddate]];
  [self setIsAlarmed:       [doc isAlarmed]];
  [self setIsUntimed:       [doc isUntimed]];
  [self setNote:            [doc note]];
  [self setRepeatEnddate:   [doc repeatEnddate]];
  [self setRepeatFrequency: [doc repeatFrequency]];
  [self setRepeatOn:        [doc repeatOn]];
  [self setRepeatStartWeek: [doc repeatStartWeek]];
  [self setRepeatType:      [doc repeatType]];
  [self setStartdate:       [doc startdate]];
  [self setExceptions:      [doc exceptions]];

  [super takeValuesFromDocument:_doc];
}


- (void)prepareAsNew {
  [super prepareAsNew];
  [self setAlarmAdvanceTime:0];
  [self setAlarmAdvanceUnit:5];
  [self setIsAlarmed:NO];
  [self setRepeatType:0];
  [self setExceptions:[NSArray array]];
  [self setRepeatFrequency:1];
}

- (NSString *)insertNotificationName {
  return SkyNewPalmDateNotification;
}
- (NSString *)updateNotificationName {
  return SkyUpdatedPalmDateNotification;
}
- (NSString *)deleteNotificationName {
  return SkyDeletedPalmDateNotification;
}

@end /* SkyPalmDateDocument */

#include <OGoScheduler/SkyAppointmentDataSource.h>
#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOKeyGlobalID.h>
#include <NGExtensions/NSCalendarDate+misc.h>
#include <NGExtensions/EODataSource+NGExtensions.h>

@implementation SkyPalmDateDocument(AssignmentToSkyAppointmentDocument)

// assignement to skyrix document (SkyAppointmentDocument)

- (BOOL)_isAllDayApt:(id)_apt {
  NSCalendarDate *start, *end;
  
  start = [_apt startDate];
  end   = [_apt endDate];
  if (([start hourOfDay] == 0) &&
      ([start minuteOfHour] == 0) &&
      ([start secondOfMinute] == 0) &&
      ((([end hourOfDay] == 0) &&
        ([end minuteOfHour] == 0) &&
        ([end secondOfMinute] == 0)) ||
       (([end hourOfDay] == 23) &&
        ([end minuteOfHour] == 59)
        )))
    {
      return YES;
    }
  return NO;
}

- (void)takeValuesFromSkyrixRecord:(id)_skyrixRecord {
  // of type SkyAppointmentDocument
  NSString       *type = nil;
  NSCalendarDate *end  = nil;
  BOOL           noTime;

  noTime = [self _isAllDayApt:_skyrixRecord];
  
  end = [_skyrixRecord endDate];
  if (![end isDateOnSameDay:[_skyrixRecord startDate]])
    end = [[_skyrixRecord endDate] endOfDay];
  
  [self setStartdate:  [_skyrixRecord startDate]];
  [self setEnddate:end];
  [self setDescription:[_skyrixRecord title]];
  [self setNote:[_skyrixRecord comment]];

  type = [_skyrixRecord type];

  [self setRepeatStartWeek:0];
  [self setRepeatOn:0];
  [self setRepeatFrequency:1];
  [self setIsUntimed:noTime];
  
  if (type == nil) {
    [self setRepeatType:REPEAT_TYPE_SINLGE]; // no more repetitions
    [self setRepeatFrequency:0];
  }
  else if ([type isEqualToString:@"daily"]) {
    [self setRepeatType:REPEAT_TYPE_DAILY];
  }
  else if ([type isEqualToString:@"weekly"]) {
    int dow = [end dayOfWeek];
    [self setRepeatType:REPEAT_TYPE_WEEKLY];
    [self setRepeatOn:1 << dow];
    [self setRepeatStartWeek:1];
  }
  else if ([type isEqualToString:@"weekday"]) {
    [self setRepeatType:REPEAT_TYPE_WEEKLY];
    [self setRepeatOn:62]; // Mo - Fr
    [self setRepeatStartWeek:1];
  }
  else if ([type isEqualToString:@"14_daily"]) {
    int dow = [end dayOfWeek];
    [self setRepeatType:REPEAT_TYPE_WEEKLY];
    [self setRepeatOn:1 << dow];
    [self setRepeatStartWeek:1];
    [self setRepeatFrequency:2];
  }
  else if ([type isEqualToString:@"monthly"]) {
    [self setRepeatType:REPEAT_TYPE_MONTHLY_BY_DATE];
  }
  else if ([type isEqualToString:@"yearly"]) {
    [self setRepeatType:REPEAT_TYPE_YEARLY];
  }
  else {
    // unknown type
    [self setRepeatType:REPEAT_TYPE_SINLGE];
    [self setRepeatFrequency:0];
  }

  end = [_skyrixRecord cycleEndDate];
  if (end != nil) {
    [self setRepeatEnddate:end];
  }
}

- (void)putValuesToSkyrixRecord:(id)_skyrixRecord {
  int      type;
  NSString *perm;

  if ((perm = [_skyrixRecord permissions])) {
    if ([perm indexOfString:@"e"] == NSNotFound) { // edit
      NSLog(@"WARNING[%s]: skyrix date %@ is not editable",
            __PRETTY_FUNCTION__, _skyrixRecord);
      return;
    }
  }
  else if ([_skyrixRecord isNew]) {
    // that's ok, don't need permissions
  }
  else {
    NSLog(@"WARNING[%s]: skyrix date %@ has no permissions attribute",
          __PRETTY_FUNCTION__, _skyrixRecord);
    return;
  }
  
  [_skyrixRecord setStartDate:[self startDate]];// take startDate not startdate
  [_skyrixRecord setEndDate:  [self endDate]];  // take endDate   not enddate
  [_skyrixRecord setTitle:    [self description]];
  [_skyrixRecord setComment:  [self note]];
  if ([self repeatEnddate] != nil)
    [_skyrixRecord setCycleEndDate:[self repeatEnddate]];

  type = [self repeatType];

  switch (type) {
    case (REPEAT_TYPE_SINLGE):
      [_skyrixRecord setType:nil];
      break;
      
    case (REPEAT_TYPE_DAILY):
      [_skyrixRecord setType:@"daily"];
      break;
      
    case (REPEAT_TYPE_WEEKLY):
      if ([self repeatOn] == 62) // Mo - Fr
        [_skyrixRecord setType:@"weekday"];
      else if (([self repeatFrequency] % 2) == 0)
        [_skyrixRecord setType:@"14_daily"];
      else
        [_skyrixRecord setType:@"weekly"];
      break;

    case (REPEAT_TYPE_MONTHLY_BY_DATE):
    case (REPEAT_TYPE_MONTHLY_BY_WEEKDAY):
      [_skyrixRecord setType:@"monthly"];
      break;

    case (REPEAT_TYPE_YEARLY):
      [_skyrixRecord setType:@"yearly"];
      break;
      
    default:
      [_skyrixRecord setType:nil];
      break;
  }
}

- (SkyAppointmentQualifier *)_qualifierForSkyrixRecord {
  SkyAppointmentQualifier *qual;
  NSTimeZone              *tz;
  qual = [[SkyAppointmentQualifier alloc] init];

  tz = [self->startdate timeZone];
  if (tz == nil) tz = [NSTimeZone localTimeZone];
  [qual setTimeZone:tz];

  return AUTORELEASE(qual);
}
- (NSArray *)_sortOrderings {
  return [NSArray arrayWithObject:
                  [EOSortOrdering sortOrderingWithKey:@"startDate"
                                  selector:EOCompareAscending]];
}
- (NSArray *)_neededAttributes {
  return [NSArray arrayWithObjects:
                  @"dateId", @"startDate", @"endDate", @"cycleEndDate",
                  @"type", @"title", @"globalID", @"permissions",
                  @"participants.login", @"objectVersion", @"comment",
                  @"location", @"accessTeamId", @"writeAccessList", 
                  nil];
}
- (NSDictionary *)_hintsForSkyrixRecord {
  EOKeyGlobalID *gid  = nil;
  NSDictionary *hints = nil;

  gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
                       keys:&self->skyrixId keyCount:1 zone:nil];
  hints = 
    [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSArray arrayWithObject:gid], @"fetchGIDs",
                  [self _neededAttributes],      @"attributes",
                  nil];
  return hints;
}
- (EOFetchSpecification *)_fetchSpecForSkyrixRecord {
  EOFetchSpecification *fspec =
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Date"
                          qualifier:[self _qualifierForSkyrixRecord]
                          sortOrderings:[self _sortOrderings]];
  [fspec setHints:[self _hintsForSkyrixRecord]];
  return fspec;
}
- (SkyAppointmentDataSource *)_dataSourceForSkyrixRecord {
  SkyAppointmentDataSource *ds;
  ds = [[SkyAppointmentDataSource alloc] initWithContext:[self context]];
  [ds setFetchSpecification:[self _fetchSpecForSkyrixRecord]];

  return AUTORELEASE(ds);
}
- (void)_observeSkyrixRecord:(id)_skyrixRecord {
  NSNotificationCenter     *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
      selector:@selector(skyrixRecordChanged)
      name:EODataSourceDidChangeNotification
      object:[(SkyAppointmentDocument *)_skyrixRecord dataSource]];
  self->isObserving = YES;
}
- (id)fetchSkyrixRecord {
  SkyAppointmentDataSource *ds;
  id                       obj = nil;
  
  ds  = [self _dataSourceForSkyrixRecord];
  obj = [[ds fetchObjects] lastObject];
  return obj;
}

- (id)createSkyrixRecordCopy {
  SkyAppointmentDocument *newApt = nil;
  id oldSkyrixRecord;
  oldSkyrixRecord = [self skyrixRecord];
  if (oldSkyrixRecord != nil) { 
    SkyAppointmentDataSource *ds;
    ds  = [self _dataSourceForSkyrixRecord];

    newApt = [ds createObject];
   
    if (newApt != nil) {
      NSArray        *writeAccess;
      id             readAccess;
      NSUserDefaults *ud;
      id tmp;
      
      [(id)newApt setTitle:@"new appointment created due to palm conflict"];

      ud  = [[self context] userDefaults];
      writeAccess =
        [ud arrayForKey:@"ogopalm_default_scheduler_write_access_accounts"];
      tmp = 
        [ud arrayForKey:@"ogopalm_default_scheduler_write_access_teams"];

      if (tmp == nil) {
        if (writeAccess == nil) writeAccess = [NSArray array];
      }
      else {
        if (writeAccess == nil) writeAccess = tmp;
        else writeAccess = [writeAccess arrayByAddingObjectsFromArray:tmp];
      }
      readAccess =
        [ud stringForKey:@"ogopalm_default_scheduler_read_access_team"];
      readAccess = [readAccess length]
        ? [NSNumber numberWithInt:[readAccess intValue]]
        : nil;
      
      [newApt setWriteAccess:writeAccess];
      [newApt setAccessTeamId:readAccess];
    }
  }

  return [newApt save] ? newApt : nil;
}


- (NSNumber *)skyrixRecordVersion {
  return [(SkyAppointmentDocument *)[self skyrixRecord] objectVersion];
}
- (void)saveSkyrixRecord {
  // is class SkyAppointmentDocument
  [(SkyAppointmentDocument *)[self skyrixRecord] save];
  // force reload -> by notifications
}

@end /* SkyPalmDateDocument (AssignmentToSkyAppointmentDocument) */

// repeat support
@implementation SkyPalmDateDocument(DateDocumentCopy)

- (id)copyWithStartdate:(NSCalendarDate *)_start
                enddate:(NSCalendarDate *)_end
                  index:(unsigned)_repetitionIndex
{
  return [SkyPalmDateDocumentCopy documentWithDocument:self
                                  dataSource:self->dataSource
                                  startdate:_start
                                  enddate:_end
                                  index:_repetitionIndex];
}

- (BOOL)dateExceptionOnDay:(NSCalendarDate *)_day {
  NSCalendarDate *day = nil;
  day = [NSCalendarDate dateWithYear:[_day yearOfCommonEra]
                        month:[_day monthOfYear]
                        day:[_day dayOfMonth]
                        hour:0 minute:0 second:0 timeZone:nil];
  return ([[self exceptions] containsObject:day])
    ? YES : NO;
}

// repeatType singleDate
- (NSArray *)singleDateBetween:(NSCalendarDate *)_start
                           and:(NSCalendarDate *)_end
{
  // checking enddate
  if (([_start laterDate:self->enddate] == self->enddate) ||
      ([_start isEqual:self->enddate])) {

    // checking startdate
    if (([_end earlierDate:self->startdate] == self->startdate) ||
        ([_end isEqual:self->startdate])) {
      return [NSArray arrayWithObject:self];
    }
  }
  return [NSArray array];
}

- (NSArray *)copiesWithDates:(NSArray *)_dates {
  NSMutableArray *ma;
  unsigned i, max;
  id       entry;
  max = [_dates count];
  ma = [NSMutableArray arrayWithCapacity:max+1];
  for (i = 0; i < max; i++) {
    entry = [_dates objectAtIndex:i];
    entry = [self copyWithStartdate:[entry valueForKey:@"startDate"]
                  enddate:[entry valueForKey:@"endDate"]
                  index:[[entry valueForKey:@"repetitionIndex"] intValue]];
    [ma addObject:entry];
  }
  return ma;
}

- (id)cycleDelegate {
  switch (self->repeatType) {
    case (REPEAT_TYPE_SINLGE): // single date
      return nil;
    case (REPEAT_TYPE_DAILY): // daily
      return [OGoCycleDateDelegate dailyCycleDates];
    case (REPEAT_TYPE_WEEKLY): // weekly
      return [OGoCycleDateDelegate weeklyCycleDatesOnWeekDays:[self weekdays]];
    case (REPEAT_TYPE_MONTHLY_BY_WEEKDAY): // monthly by weekday
      return [OGoCycleDateDelegate monthlyCycleOnWeekDay:self->repeatOn % 7
                                   inWeek:self->repeatOn / 7];
    case (REPEAT_TYPE_MONTHLY_BY_DATE): // monthly by date
      return [OGoCycleDateDelegate monthlyCycleByDate];
    case (REPEAT_TYPE_YEARLY): // yearly
      return [OGoCycleDateDelegate yearlyCycleDates];
  }
  // invalid repeatType
  return nil;
}

- (NSArray *)repeatsBetween:(NSCalendarDate *)_start
                        and:(NSCalendarDate *)_end
{
  NSArray        *repeats = nil;
  id             delegate;
  OGoCycleDateCalculator *calc;

  //  NSLog(@"<SkyPalmDateDocument %@> repeats between %@ and %@",
  //        self, _start, end);

  if (self->repeatType == REPEAT_TYPE_SINLGE) { // single date
    NSCalendarDate *end;
    end = (self->repeatEnddate != nil)
      ? (NSCalendarDate *)[self->repeatEnddate earlierDate:_end]
      : _end;
    return [self singleDateBetween:_start and:end];
  }

  if ((delegate = [self cycleDelegate]) == nil)
    return [NSArray array];

  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:[self startDate]
                                         endDate:[self endDate]
                                         periodStart:_start
                                         periodEnd:_end
                                         frequency:[self repeatFrequency]
                                         delegate:delegate];
  [calc setExceptions:[self exceptions]];
  [calc setCycleEndDate:[self repeatEnddate]];

  repeats = [calc calculateRepetitions];
  [calc release]; calc = nil;

  return [self copiesWithDates:repeats];
}

- (id)repetitionAtIndex:(unsigned)_idx {
  id                     repetition;
  id                     delegate;
  OGoCycleDateCalculator *calc;

  if (self->repeatType == REPEAT_TYPE_SINLGE) // single date
    return (_idx == 0) ? self : nil;

  if ((delegate = [self cycleDelegate]) == nil)
    return nil;

  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:[self startDate]
                                         endDate:[self endDate]
                                         periodStart:nil
                                         periodEnd:nil
                                         frequency:[self repeatFrequency]
                                         delegate:delegate];
  [calc setExceptions:[self exceptions]];
  [calc setCycleEndDate:[self repeatEnddate]];
  [calc setSeekIndex:_idx];

  repetition = [calc calculateRepetitions];
  [calc release]; calc = nil;
  if ([repetition isKindOfClass:[NSArray class]])
    repetition = [repetition lastObject];

  if (repetition == nil) return nil;

  return [self copyWithStartdate:[repetition objectForKey:@"startDate"]
               enddate:[repetition objectForKey:@"endDate"]
               index:[[repetition objectForKey:@"repetitionIndex"] intValue]];
}

- (id)detachDate:(SkyPalmDateDocumentCopy *)_child {
  NSCalendarDate *childDate;
  
  if (![[_child globalID] isEqual:[self globalID]]) {
    NSLog(@"<%@, %@> %@ is not my child! could not detach it from me!",
          [self class], [self description], [_child description]);
    return nil;
  }

  childDate = [_child startdate];
  childDate = [childDate beginOfDay];

  [self setExceptions:[[self exceptions] arrayByAddingObject:childDate]];
  return [self save];
}

@end /* SkyPalmDateDocument(DateDocumentCopy) */

// SkyScheduler support

@implementation SkyPalmDateDocument(SkySchedulerSupport)
// view allways allowed
- (NSString *)permissions {
  return @"v";  // view
}
- (BOOL)isViewAllowed {
  return YES;
}
// dates
- (NSCalendarDate *)startDate {
  return [self isUntimed] ? [[self startdate] beginOfDay]
    : [self startdate];
}
- (NSCalendarDate *)endDate {
  return [self isUntimed] ? [[self enddate] endOfDay]
    : [self enddate];
}
// title
- (NSString *)title {
  return [self description];
}
// owner
- (NSNumber *)ownerId {
  return [self companyId];
}
- (NSArray *)participants {
  return [NSArray arrayWithObject:[self->dataSource currentAccount]];
}

- (NSString *)aptType {
  static NSString *palmAptType = nil;
  if (palmAptType == nil)
    palmAptType = [[NSString alloc] initWithString:@"_palm_"];
  return palmAptType;
}

@end /* SkyPalmDateDocument(SkySchedulerSupport) */

@implementation SkyPalmDateDocumentSelection

- (Class)mustBeClass {
  return [SkyPalmDateDocument class];
}

@end /* SkyPalmDateDocumentSelection */
