// $Id$

#ifndef __OGoSchedulerTools_OGoCycleDateCalculator_H__
#define __OGoSchedulerTools_OGoCycleDateCalculator_H__

#include <Foundation/NSObject.h>

/*
  TODO: very bad programming style below! Instead of using a singleton a
        whole lot of class methods are introduced, sigh.

        Then there is a class "OGoCycleDateDelegate". *what the heck*?
        Delegates are a concept and delegates can be any object. It doesn't
        make sense to have a class called that way!
        And again it has lots of class methods.
*/

@class NSCalendarDate, NSArray;

@interface OGoCycleDateCalculator : NSObject
{
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSCalendarDate *periodStart;
  NSCalendarDate *periodEnd;

  NSArray        *exceptions;
  int            seekIndex;
  unsigned       frequency;
  NSCalendarDate *cycleEndDate;
  int            maxCycles;

  unsigned repetitionIndex;

  id delegate;
}

/* init */

- (id)initWithStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd
  frequency:(unsigned)_frequency
  delegate:(id)_delegate;

/* accessors */

- (void)setStartDate:(NSCalendarDate *)_startDate;
- (NSCalendarDate *)startDate;
- (void)setEndDate:(NSCalendarDate *)_endDate;
- (NSCalendarDate *)endDate;
- (void)setPeriodStart:(NSCalendarDate *)_periodStart;
- (NSCalendarDate *)periodStart;
- (void)setPeriodEnd:(NSCalendarDate *)_periodEnd;
- (NSCalendarDate *)periodEnd;

- (void)setExceptions:(NSArray *)_exceptions;
- (NSArray *)exceptions;
- (void)setFrequency:(unsigned)_freq;
- (unsigned)frequency;
- (void)setCycleEndDate:(NSCalendarDate *)_cycleEndDate;
- (NSCalendarDate *)cycleEndDate;
- (void)setSeekIndex:(int)_seek; // -1 for no seek
- (int)seekIndex;
- (void)setMaxCycles:(int)_maxCyckes; // < 1 for ignore
- (int)maxCycles;

- (unsigned)repetitionIndex;
- (BOOL)isDateInExceptions:(NSCalendarDate *)_date;


- (void)setDelegate:(id)_delegate;
- (id)delegate;

/* compute repetitions */
/* returns array, except if seek index is set */
- (id)calculateRepetitions;

- (BOOL)nextStartDate:(NSCalendarDate **)_start
           andEndDate:(NSCalendarDate **)_end;

// static 
+ (NSArray *)cycleDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  type:(NSString *)_type
  maxCycles:(int)_maxCycles
  startAt:(int)_offset
  endDate:(NSCalendarDate *)_cycleEndDate
  keepTime:(BOOL)_keepTime;

// some palm_date stuff

/*
  generates dictionaries for every repetition with the keys
  startDate, endDate, repetitionIndex
  either seekIndex must not be -1 or repetitionEndDate must be non nil
  or periodStart and periodEnd must be non nil
*/
+ (NSArray *)dailyDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  frequency:(int)_days
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_repetitionIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd;

+ (NSArray *)weeklyDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  onWeekDays:(NSArray *)_weekDays
  frequency:(int)_weeks
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd;

+ (NSArray *)montlyDatesByWeekDayForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  onWeekDay:(int)_weekDay
  inWeek:(int)_week
  frequency:(int)_months
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd;

+ (NSArray *)montlyDatesByDateForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  frequency:(int)_months
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd;

+ (NSArray *)yearlyDatesForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  frequency:(int)_years
  exceptions:(NSArray *)_exceptions
  repetitionEndDate:(NSCalendarDate *)_cycleEndDate
  seekIndex:(int)_seekIndex
  periodStart:(NSCalendarDate *)_periodStart
  periodEnd:(NSCalendarDate *)_periodEnd;

@end /* OGoCycleDateCalculator */

@interface OGoCycleDateDelegate : NSObject
{
}

- (BOOL)nextStartDate:(NSCalendarDate **)_startDate
  andEndDate:(NSCalendarDate **)_endDate
  forCycleCalculator:(OGoCycleDateCalculator *)_calculator;

+ (OGoCycleDateDelegate *)dailyCycleDates;
+ (OGoCycleDateDelegate *)weeklyCycleDatesOnWeekDays:(NSArray *)_weekDays;
+ (OGoCycleDateDelegate *)monthlyCycleOnWeekDay:(unsigned)_weekDay
  inWeek:(unsigned)_week;
+ (OGoCycleDateDelegate *)monthlyCycleByDate;
+ (OGoCycleDateDelegate *)yearlyCycleDates;

@end /* OGoCycleDateDelegate */

#endif /* __OGoSchedulerTools_OGoCycleDateCalculator_H__ */
