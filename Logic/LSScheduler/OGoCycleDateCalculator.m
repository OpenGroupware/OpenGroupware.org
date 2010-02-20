
#include "OGoCycleDateCalculator.h"
#include <NGExtensions/NSCalendarDate+misc.h>
#include <NGExtensions/NGCalendarDateRange.h>
#include <NGiCal/iCalRecurrenceCalculator.h>
#include <NGiCal/iCalRecurrenceRule.h>
#include "common.h"

@implementation OGoCycleDateCalculator

+ (NSCalendarDate *)_correctTimeOfDate:(NSCalendarDate *)_date
  sourceDate:(NSCalendarDate *)_source
  fixTimeZone:(BOOL)_fixTimeZone
{
  NSCalendarDate *fixed = _date;
  if (_fixTimeZone) {
    fixed = [[_date copy] autorelease];
    [fixed setTimeZone:[_source timeZone]];
  }
  return [fixed hour:[_source hourOfDay]
                minute:[_source minuteOfHour]
                second:[_source secondOfMinute]];
}

+ (NSArray *)cycleDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  type:(NSString *)_type
  maxCycles:(int)_maxCycles
  startAt:(int)_offset
  endDate:(NSCalendarDate *)_cycleEndDate
  keepTime:(BOOL)_keepTime
{
  int            i, cnt;
  BOOL           cycleEnd;
  NSMutableArray *ma;
  NSCalendarDate *sD, *eD;
  
  if ([_type hasPrefix:@"RRULE:"]) {
    iCalRecurrenceCalculator *cpu;
    iCalRecurrenceRule  *rrule;
    NGCalendarDateRange *eventRange;
    NSString *pattern;

    /* parse rule */
    
    pattern = [_type substringFromIndex:6];
    if ((rrule = [[iCalRecurrenceRule alloc] initWithString:pattern]) == nil) {
      [self errorWithFormat:@"%s: could not parse iCal rrule: '%@'",
            __PRETTY_FUNCTION__, pattern];
      return nil;
    }

    /* setup iCal calculator */
    
    eventRange = [NGCalendarDateRange calendarDateRangeWithStartDate:_startDate
                                      endDate:_endDate];
    
    cpu = [iCalRecurrenceCalculator 
            recurrenceCalculatorForRecurrenceRule:rrule
            withFirstInstanceCalendarDateRange:eventRange];
    
    if (![_cycleEndDate isNotNull]) {
      if ((_cycleEndDate = [[[rrule untilDate] copy] autorelease]) != nil) {
        /* UNTIL probably not saved in DB */
        [self warnWithFormat:@"rrule has an UNTIL, but the calculation not."];
      }
    }
    [rrule release]; rrule = nil;

    /* ensure some preconditions */
    
    if (!_keepTime) {
      [self errorWithFormat:@"%s: cannot process rrule %@ with keep-time off!",
            __PRETTY_FUNCTION__, rrule];
    }
    // TODO: check 'offset'?
    
    if (![_cycleEndDate isNotNull]) {
      [self errorWithFormat:@"%s: got no cycle enddate!", __PRETTY_FUNCTION__];
      return nil;
    }
    
    /* run calculation */
    
    eventRange = [NGCalendarDateRange calendarDateRangeWithStartDate:_startDate
                                      endDate:_cycleEndDate];
    return [cpu recurrenceRangesWithinCalendarDateRange:eventRange];
  }
  
  if (_cycleEndDate == nil || _maxCycles < 1) {
    if (_cycleEndDate == nil)
      [self warnWithFormat:@"got no cycle enddate!"];
    return [NSArray array]; // TODO: rather return 'nil'?
  }
  
  sD = [_startDate hour:12 minute:0 second:0];
  eD = [_endDate   hour:12 minute:0 second:0];
  ma = [NSMutableArray arrayWithCapacity:64];

  for (i = _offset, cnt = 0, cycleEnd = NO; !cycleEnd; ) {
    NSCalendarDate *newStartDate = nil;
    NSCalendarDate *newEndDate   = nil;
    BOOL           ignoreWeekends = NO;
    
    // TODO: use a category for that! (I think there even is some somewhere)
    if ([_type isEqual:@"daily"]) {
      newStartDate = [sD dateByAddingYears:0 months:0 days:i*1];
      newEndDate   = [eD dateByAddingYears:0 months:0 days:i*1];
    }
    else if ([_type isEqual:@"weekday"]) {
      /* every working day, that is, Monday to Friday */
      newStartDate = [sD dateByAddingYears:0 months:0 days:i*1];
      newEndDate   = [eD dateByAddingYears:0 months:0 days:i*1];
      ignoreWeekends = YES;
    }
    else if ([_type isEqual:@"weekly"]) {
      newStartDate = [sD dateByAddingYears:0 months:0 days:i*7];
      newEndDate   = [eD dateByAddingYears:0 months:0 days:i*7];
    }
    else if ([_type isEqual:@"14_daily"]) {
      newStartDate = [sD dateByAddingYears:0 months:0 days:i*14];
      newEndDate   = [eD dateByAddingYears:0 months:0 days:i*14];
    }
    else if ([_type isEqual:@"4_weekly"]) {
      newStartDate = [sD dateByAddingYears:0 months:0 days:i*28];
      newEndDate   = [eD dateByAddingYears:0 months:0 days:i*28];
    }
    else if ([_type isEqual:@"monthly"]) {
      newStartDate = [sD dateByAddingYears:0 months:i*1 days:0];
      newEndDate   = [eD dateByAddingYears:0 months:i*1 days:0];
    }
    else if ([_type isEqual:@"yearly"]) {
      newStartDate = [sD dateByAddingYears:i*1 months:0 days:0];
      newEndDate   = [eD dateByAddingYears:i*1 months:0 days:0];
    }
    else {
      [self errorWithFormat:@"%s: unknown repetition type: %@", 
            __PRETTY_FUNCTION__, _type];
      return [NSArray array];
    }
    i++;

    if (_keepTime) {
      newStartDate = [OGoCycleDateCalculator _correctTimeOfDate:newStartDate
                                             sourceDate:_startDate
                                             fixTimeZone:NO];
      newEndDate   = [OGoCycleDateCalculator _correctTimeOfDate:newEndDate
                                             sourceDate:_endDate
                                             fixTimeZone:NO];
    }
    
    if (ignoreWeekends) {
      // TODO: is checking the startdate sufficient? I suppose so.
      int day = [newStartDate dayOfWeek];
      if (day == 0 /* Sunday */ || day == 6 /* Saturday */)
        continue;
    }
    
    if ((_cycleEndDate != nil) &&
        ([newStartDate compare:_cycleEndDate] != NSOrderedAscending)) {
      cycleEnd = YES;
    }
    
    if (!cycleEnd) {
      static NSString *keys[2] = { @"startDate", @"endDate" };
      id values[2];
      NSDictionary *d;
      
      values[0] = newStartDate;
      values[1] = newEndDate;
      d = [[NSDictionary alloc] initWithObjects:values forKeys:keys count:2];
      [ma addObject:d];
      [d release]; d = nil;
      cnt++;
    }
    
    if ((_maxCycles > 0) && (cnt >= _maxCycles)) 
      cycleEnd = YES;
  }

  return ma;
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->seekIndex       = -1;
    self->frequency       =  1;
    self->maxCycles       = -1;
    self->repetitionIndex = 0;
  }
  return self;
}

- (id)initWithStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
  frequency:(unsigned)_frequency
  delegate:(id)_delegate
{
  if ((self = [self init])) {
    self->startDate   = [_startDate copy];
    self->endDate     = [_endDate   copy];
    self->periodStart = [_periodStart copy];
    self->periodEnd   = [_periodEnd   copy];
    self->delegate    = [_delegate retain]; // TODO: unusual! is this freed?
    self->frequency   = _frequency;
  }
  return self;
}

- (void)dealloc {
  [self->startDate    release];
  [self->endDate      release];
  [self->periodStart  release];
  [self->periodEnd    release];
  [self->exceptions   release];
  [self->cycleEndDate release];
  [self->delegate     release];
  [super dealloc];
}

/* accessors */

- (void)setStartDate:(NSCalendarDate *)_startDate {
  ASSIGNCOPY(self->startDate,_startDate);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_endDate {
  ASSIGNCOPY(self->endDate,_endDate);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setPeriodStart:(NSCalendarDate *)_periodStart {
  ASSIGNCOPY(self->periodStart,_periodStart);
}
- (NSCalendarDate *)periodStart {
  return self->periodStart;
}

- (void)setPeriodEnd:(NSCalendarDate *)_periodEnd {
  ASSIGNCOPY(self->periodEnd,_periodEnd);
}
- (NSCalendarDate *)periodEnd {
  return self->periodEnd;
}

- (void)setExceptions:(NSArray *)_exceptions {
  ASSIGN(self->exceptions,_exceptions);
}
- (NSArray *)exceptions {
  return self->exceptions;
}

- (void)setFrequency:(unsigned)_freq {
  self->frequency = _freq;
}
- (unsigned)frequency {
  return self->frequency;
}

- (void)setCycleEndDate:(NSCalendarDate *)_cycleEndDate {
  ASSIGNCOPY(self->cycleEndDate,_cycleEndDate);
}
- (NSCalendarDate *)cycleEndDate {
  return self->cycleEndDate;
}

- (void)setSeekIndex:(int)_seek { // < 0 for no seek
  self->seekIndex = _seek;
}
- (int)seekIndex {
  return self->seekIndex;
}

- (void)setMaxCycles:(int)_maxCyckes { // < 1 for ignore
  self->maxCycles = _maxCyckes;
}
- (int)maxCycles {
  return self->maxCycles;
}

- (unsigned)repetitionIndex {
  return self->repetitionIndex;
}
- (BOOL)isDateInExceptions:(NSCalendarDate *)_date {
  NSCalendarDate *day = nil;
  day = [NSCalendarDate dateWithYear:[_date yearOfCommonEra]
                        month:[_date monthOfYear]
                        day:[_date dayOfMonth]
                        hour:0 minute:0 second:0 timeZone:nil];
  return ([self->exceptions containsObject:day]) ? YES : NO;
}

- (void)setDelegate:(id)_delegate {
  ASSIGN(self->delegate,_delegate);
}
- (id)delegate {
  return self->delegate;
}

+ (NSDictionary *)createDictWithStartDate:(NSCalendarDate *)_start
  endDate:(NSCalendarDate *)_end
  repetitionIndex:(unsigned)_repetitionIndex
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
                       _start, @"startDate",
                       _end,   @"endDate",
                       [NSNumber numberWithInt:_repetitionIndex],
                       @"repetitionIndex", nil];
}

// compute repetitions
- (id)calculateRepetitions {
  NSCalendarDate *start;
  NSCalendarDate *end;
  NSCalendarDate *pStart;
  NSCalendarDate *pEnd;
  NSMutableArray *ma;
  id             entry;

  pStart = (self->periodStart != nil)
    ? (([self->startDate laterDate:self->periodStart] == self->startDate)
       ? self->startDate : self->periodStart)
    : self->startDate;
  pEnd   = (self->periodEnd != nil) ? self->periodEnd : self->cycleEndDate;  

  if (pEnd == nil && self->seekIndex < 0 && self->maxCycles < 1) {
    NSLog(@"%s: either a regionEnd (regionEnd or cycleEndDate) or "
          @" a seekIndex or maxCycles must be set!");
    return nil;
  }

#if 0
  NSLog(@"%s: start calculation in period: %@ - %@ "
        @"(seekIndex: %d, maxCycles: %d) with delegate: %@",
        __PRETTY_FUNCTION__, pStart, pEnd, self->seekIndex, self->maxCycles,
        self->delegate);
#endif

  start           = [self->startDate hour:12 minute:0 second:0];
  end             = [self->endDate hour:12 minute:0 second:0];
  ma              = [NSMutableArray array];

  self->repetitionIndex = 0;
  if (![self nextStartDate:&start andEndDate:&end]) {
    NSLog(@"%s: failed gettings first start and enddate", __PRETTY_FUNCTION__);
    return nil;
  }
  
  while (((int)self->repetitionIndex < (int)self->seekIndex) ||
         (([start earlierDate:pEnd] == start) ||
          ([start isEqual:pEnd]))) {
    // while not reached end of period or seek-index

#if 0
    NSLog(@"%s:%d:  start: %@ end: %@", __PRETTY_FUNCTION__,
          self->repetitionIndex, start, end);
#endif

    if (([end laterDate:pStart] == end) ||
        ([end isEqual:pStart])) {
      // if date is in the period
      if (![self isDateInExceptions:start]) {
        // if date is not a exception
        entry = [OGoCycleDateCalculator createDictWithStartDate:start
                                        endDate:end
                                        repetitionIndex:self->repetitionIndex];
        if (self->seekIndex == self->repetitionIndex) return entry;
        [ma addObject:entry];
        if ([ma count] == self->maxCycles) return ma;
      }
    }
    // next day
    self->repetitionIndex++;
    if (self->seekIndex >= 0 && self->seekIndex < self->repetitionIndex) {
      NSLog(@"%s: invalid seekIndex:%d. Maybe caused by repetition-exceptions",
            __PRETTY_FUNCTION__, self->seekIndex);
      return nil;
    }
    if (![self nextStartDate:&start andEndDate:&end]) {
      NSLog(@"%s: failed gettings next start and enddate at index %d",
            __PRETTY_FUNCTION__, self->repetitionIndex);
      return nil;
    }
    if (start == nil || end == nil) {
      NSLog(@"%s: error during compution of next date", __PRETTY_FUNCTION__);
      return nil;
    }
  }
#if 0
  NSLog(@"%s:%d: finaly: start: %@ end: %@", __PRETTY_FUNCTION__,
        self->repetitionIndex, start, end);
#endif
  return ma;
}

// overwrite in subclasses
- (BOOL)nextStartDate:(NSCalendarDate **)_start
  andEndDate:(NSCalendarDate **)_end
{
  NSCalendarDate *start, *end;
  BOOL           result;
  static NSTimeZone *gmt = nil;

  if (gmt == nil) gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
  if (self->delegate == nil) {
    [self warnWithFormat:@"%s: no delegate set", __PRETTY_FUNCTION__];
    return NO;
  }
  start = [(*_start) hour:12 minute:0 second:0];
  end   = [(*_end)   hour:12 minute:0 second:0];
  [start setTimeZone:gmt]; [end setTimeZone:gmt];
  result =  [self->delegate nextStartDate:&start
                 andEndDate:&end
                 forCycleCalculator:self];
  if (result) {
    (*_start) = [OGoCycleDateCalculator _correctTimeOfDate:start
                                        sourceDate:self->startDate
                                        fixTimeZone:YES];
    (*_end)   = [OGoCycleDateCalculator _correctTimeOfDate:end
                                        sourceDate:self->endDate
                                        fixTimeZone:YES];
  }
  return result;
}

+ (NSArray *)dailyDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  frequency:(int)_days
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
{
  OGoCycleDateCalculator *calc;
  id del;
  id result;

  del  = [OGoCycleDateDelegate dailyCycleDates];
  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:_startDate
                                         endDate:_endDate
                                         periodStart:_periodStart
                                         periodEnd:_periodEnd
                                         frequency:_days
                                         delegate:del];
  [calc setExceptions:_exceptions];
  [calc setCycleEndDate:_cycleEndDate];
  [calc setSeekIndex:_seekIndex];

  result = [calc calculateRepetitions];
  [calc release];
  return result;
}

+ (NSArray *)weeklyDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  onWeekDays:(NSArray *)_weekDays
  frequency:(int)_weeks
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
{
  OGoCycleDateCalculator *calc;
  id del;
  id result;

  del  = [OGoCycleDateDelegate weeklyCycleDatesOnWeekDays:_weekDays];
  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:_startDate
                                         endDate:_endDate
                                         periodStart:_periodStart
                                         periodEnd:_periodEnd
                                         frequency:_weeks
                                         delegate:del];
  [calc setExceptions:_exceptions];
  [calc setCycleEndDate:_cycleEndDate];
  [calc setSeekIndex:_seekIndex];

  result = [calc calculateRepetitions];
  [calc release];
  return result;
}

+ (NSArray *)montlyDatesByWeekDayForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  onWeekDay:(int)_weekDay
  inWeek:(int)_week
  frequency:(int)_months
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
{
  OGoCycleDateCalculator *calc;
  id del;
  id result;

  del  = [OGoCycleDateDelegate monthlyCycleOnWeekDay:_weekDay inWeek:_week];
  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:_startDate
                                         endDate:_endDate
                                         periodStart:_periodStart
                                         periodEnd:_periodEnd
                                         frequency:_months
                                         delegate:del];
  [calc setExceptions:_exceptions];
  [calc setCycleEndDate:_cycleEndDate];
  [calc setSeekIndex:_seekIndex];

  result = [calc calculateRepetitions];
  [calc release];
  return result;
}

+ (NSArray *)montlyDatesByDateForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  frequency:(int)_months
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
{
  OGoCycleDateCalculator *calc;
  id del;
  id result;

  del  = [OGoCycleDateDelegate monthlyCycleByDate];
  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:_startDate
                                         endDate:_endDate
                                         periodStart:_periodStart
                                         periodEnd:_periodEnd
                                         frequency:_months
                                         delegate:del];
  [calc setExceptions:_exceptions];
  [calc setCycleEndDate:_cycleEndDate];
  [calc setSeekIndex:_seekIndex];

  result = [calc calculateRepetitions];
  [calc release];
  return result;
}

+ (NSArray *)yearlyDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  frequency:(int)_years
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
{
  OGoCycleDateCalculator *calc;
  id del;
  id result;

  del  = [OGoCycleDateDelegate yearlyCycleDates];
  calc = [[OGoCycleDateCalculator alloc] initWithStartDate:_startDate
                                         endDate:_endDate
                                         periodStart:_periodStart
                                         periodEnd:_periodEnd
                                         frequency:_years
                                         delegate:del];
  [calc setExceptions:_exceptions];
  [calc setCycleEndDate:_cycleEndDate];
  [calc setSeekIndex:_seekIndex];

  result = [calc calculateRepetitions];
  [calc release];
  return result;
}

@end /* OGoCycleDateCalculator */
