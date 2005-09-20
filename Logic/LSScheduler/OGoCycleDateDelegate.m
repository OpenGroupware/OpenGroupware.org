
#include "OGoCycleDateCalculator.h"

@interface OGoCycleDateDailyDelegate : OGoCycleDateDelegate
@end

@interface OGoCycleDateWeeklyDelegate : OGoCycleDateDelegate
{
  NSArray        *weekDays;
  unsigned       weekDayIndex;
  NSCalendarDate *sunday;

  double startDiv;
  double endDiv;
  id     calculator; // non-retained
}

- (id)initWithWeekDays:(NSArray *)_weekDays;

@end

@interface OGoCycleDateMonthlyWeekDayDelegate : OGoCycleDateDelegate
{
  unsigned weekDay;
  unsigned week;
  
  double startDiv;
  double endDiv;
  id     calculator; // non-retained
}
- (id)initWithWeekDay:(unsigned)_weekDay inWeek:(unsigned)_week;
@end

@interface OGoCycleDateMonthlyDateDelegate : OGoCycleDateDelegate
{
  double startDiv;
  double endDiv;
  id     calculator; // non-retained  
}
@end

@interface OGoCycleDateYearlyDelegate : OGoCycleDateDelegate
@end

#include "common.h"
#include <NGExtensions/NSCalendarDate+misc.h>


@implementation OGoCycleDateDelegate

- (BOOL)nextStartDate:(NSCalendarDate **)_startDate
  andEndDate:(NSCalendarDate **)_endDate
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator
{
  [self errorWithFormat:@"%s: subclass should override this method: %@", 
        __PRETTY_FUNCTION__, NSStringFromSelector(_cmd)];
  return NO;
}

+ (OGoCycleDateDelegate *)dailyCycleDates {
  static id sharedInstance = nil;
  if (sharedInstance == nil) {
    sharedInstance = [[OGoCycleDateDailyDelegate alloc] init];
  }
  return sharedInstance;
}
+ (OGoCycleDateDelegate *)weeklyCycleDatesOnWeekDays:(NSArray *)_weekDays {
  return [[[OGoCycleDateWeeklyDelegate alloc] initWithWeekDays:_weekDays]
                                       autorelease];
}
+ (OGoCycleDateDelegate *)monthlyCycleOnWeekDay:(unsigned)_weekDay
  inWeek:(unsigned)_week
{
  return [[[OGoCycleDateMonthlyWeekDayDelegate alloc] initWithWeekDay:_weekDay
                                                      inWeek:_week]
                                               autorelease];
}
+ (OGoCycleDateDelegate *)monthlyCycleByDate {
  static id sharedInstance = nil;
  if (sharedInstance == nil)
    sharedInstance = [[OGoCycleDateMonthlyDateDelegate alloc] init];
  
  return sharedInstance;
}
+ (OGoCycleDateDelegate *)yearlyCycleDates {
  static id sharedInstance = nil;
  if (sharedInstance == nil)
    sharedInstance = [[OGoCycleDateYearlyDelegate alloc] init];
  
  return sharedInstance;
}

@end /* OGoCycleDateDelegate */

@implementation OGoCycleDateDailyDelegate

- (BOOL)nextStartDate:(NSCalendarDate **)_start
  andEndDate:(NSCalendarDate **)_end
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator
{
  if ([_calculator repetitionIndex] > 0) {
    (*_start) =
      [(*_start) dateByAddingYears:0 months:0 days:[_calculator frequency]];
    (*_end)   =
      [(*_end)   dateByAddingYears:0 months:0 days:[_calculator frequency]];
  }
  return YES;
}

@end /* OGoCycleDateDailyDelegate */

@implementation OGoCycleDateWeeklyDelegate

- (id)initWithWeekDays:(NSArray *)_weekDays {
  if ((self = [super init])) {    
    self->weekDays     = [_weekDays retain];
    self->weekDayIndex = 0;
    self->sunday       = nil;
    self->startDiv     = 0.0;
    self->endDiv       = 0.0;
  }
  return self;
}

- (void)dealloc {
  [self->weekDays release];
  [self->sunday   release];
  [super dealloc];
}

/* operations */

- (BOOL)nextStartDate:(NSCalendarDate **)_startDate
  andEndDate:(NSCalendarDate **)_endDate
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator
{
  /* context:
     weekDays:   indizes of week days to repeat (Sunday:0)
     weekDayIdx: index of last entry in the weekDays; 0/nil at start
     sunday:     sunday of current week; nil at start
     startDiv:   time of startDate; nil at start
     endDiv:     time of endDate; nil at end
     
  */
  unsigned       weekDayCount;
  NSCalendarDate *day;

  if ((weekDayCount = [self->weekDays count]) < 1) {
    NSLog(@"%s: need weekDays to compute nextWeekly date",
          __PRETTY_FUNCTION__);
    return NO;
  }

  if ((self->sunday == nil) || (self->calculator != _calculator)) {
    [self->sunday release]; self->sunday = nil;
    self->sunday = [[[(*_startDate) mondayOfWeek]
                                    dateByAddingYears:0 months:0 days:-1]
                                    beginOfDay];
    self->sunday = [self->sunday retain];
    [self->sunday setTimeZone:[(*_startDate) timeZone]];
    self->startDiv =
      [(*_startDate) timeIntervalSinceDate:[(*_startDate) beginOfDay]];
    self->endDiv   =
      [(*_endDate) timeIntervalSinceDate:[(*_startDate) beginOfDay]];
    self->weekDayIndex = 0;
    self->calculator   = _calculator;
  }

  if (self->weekDayIndex >= weekDayCount) {
    id tmp = [self->sunday dateByAddingYears:0 months:0
                  days:(7*[_calculator frequency])];
    [self->sunday release]; self->sunday = [tmp retain];
    self->weekDayIndex = 0;
  }

  day =
    [self->sunday dateByAddingYears:0 months:0
         days:[[self->weekDays objectAtIndex:self->weekDayIndex] intValue]];
  (*_startDate) =
    [[[NSCalendarDate alloc] initWithTimeInterval:self->startDiv
                             sinceDate:day] autorelease];
  (*_endDate)   =
    [[[NSCalendarDate alloc] initWithTimeInterval:self->endDiv
                             sinceDate:day] autorelease];

  self->weekDayIndex++;
  return YES;
}

@end /* OGoCycleDateWeeklyDelegate */

@implementation OGoCycleDateMonthlyWeekDayDelegate : OGoCycleDateDelegate

- (id)initWithWeekDay:(unsigned)_weekDay inWeek:(unsigned)_week {
  if ((self = [super init])) {
    self->weekDay = _weekDay;
    self->week    = _week;
  }
  return self;
}

- (BOOL)nextStartDate:(NSCalendarDate **)_start
  andEndDate:(NSCalendarDate **)_end
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator
{
  /* context:
     weekDay:   which day of week days to repeat (Sunday:0)
     week:      which week of month     
     startDiv:   time of startDate; nil at start
     endDiv:     time of endDate; nil at end
  */
  NSCalendarDate *date;
  int days;

  if ([_calculator repetitionIndex] <= 0)
    return YES;

  if (self->calculator != _calculator) {
      self->startDiv =
        [(*_start) timeIntervalSinceDate:[(*_start) beginOfDay]];
      self->endDiv   =
        [(*_end)   timeIntervalSinceDate:[(*_start) beginOfDay]];
      self->calculator = _calculator;
  }
    
  date    = [(*_start) firstDayOfMonth];
  date    = [date dateByAddingYears:0 months:[_calculator frequency] days:0];
  days    = self->weekDay - [date dayOfWeek];
  if (days < 0) days += 7;
  days += self->week * 7;
  while (days >= [date numberOfDaysInMonth]) 
    days -= 7;

  date = [[date beginOfDay] dateByAddingYears:0 months:0 days:days];
  (*_start) = [[[NSCalendarDate alloc] initWithTimeInterval:self->startDiv
                                       sinceDate:date] autorelease];
  (*_end)   = [[[NSCalendarDate alloc] initWithTimeInterval:self->endDiv
                                       sinceDate:date] autorelease];
  return YES;
}

@end /* OGoCycleDateMonthlyWeekDayDelegate */

@implementation OGoCycleDateMonthlyDateDelegate : OGoCycleDateDelegate

- (BOOL)nextStartDate:(NSCalendarDate **)_start
  andEndDate:(NSCalendarDate **)_end
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator
{
  /* context:
     startDiv:   time of startDate; nil at start
     endDiv:     time of endDate; nil at end
  */
  NSCalendarDate *last, *date;    
  int            div;

  if ([_calculator repetitionIndex] <= 0)
    return YES;

  if (self->calculator != _calculator) {
      self->startDiv =
        [(*_start) timeIntervalSinceDate:[(*_start) beginOfDay]];
      self->endDiv   =
        [(*_end)   timeIntervalSinceDate:[(*_start) beginOfDay]];
      self->calculator = _calculator;
  }

  last = (*_start);
  date = [[last beginOfDay]
                dateByAddingYears:0 months:[_calculator frequency] days:0];

  div = [date monthOfYear] - [last monthOfYear];
  if (div < 0) div += 12;
  if (div == ([_calculator frequency]+1)) 
    date = [[date dateByAddingYears:0 months:-1 days:0] lastDayOfMonth];
    
  (*_start) = [[[NSCalendarDate alloc] initWithTimeInterval:self->startDiv
                                       sinceDate:date] autorelease];
  (*_end)   = [[[NSCalendarDate alloc] initWithTimeInterval:self->endDiv
                                       sinceDate:date] autorelease];    
  return YES;
}

@end /* OGoCycleDateMonthlyDateDelegate */

@implementation OGoCycleDateYearlyDelegate : OGoCycleDateDelegate

- (BOOL)nextStartDate:(NSCalendarDate **)_start
  andEndDate:(NSCalendarDate **)_end
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator
{
  if ([_calculator repetitionIndex] > 0) {
    (*_start) =
      [(*_start) dateByAddingYears:[_calculator frequency] months:0 days:0];
    (*_end)   =
      [(*_end)   dateByAddingYears:[_calculator frequency] months:0 days:0];
  }
  return YES;
}

@end /* OGoCycleDateDailyDelegate */
