
#include "OGoCalWeekView.h"
#include "common.h"

@implementation OGoCalWeekView

- (NSCalendarDate *)startDate {
  NSCalendarDate *startDate;
  NSString *dateString;
  
  dateString = [[[self context] request] formValueForKey:@"startDate"];
  startDate = dateString
    ? [self dateForDateString:dateString]
    : [[NSCalendarDate date] mondayOfWeek];
  
  return startDate;
}

- (NSCalendarDate *)endDate {
  return [[self startDate] dateByAddingYears:0 months:0 days:7
			   hours:0 minutes:0 seconds:0];
}

/* URLs */

- (NSString *)prevWeekURL {
  NSCalendarDate *newWeekDate;
  
  newWeekDate = [[self startDate] dateByAddingYears:0 months:0 days:-7 
				   hours:0 minutes:0 seconds:0];
  return [self dateNavigationURLWithNewStartDate:newWeekDate];
}

- (NSString *)nextWeekURL {
  NSCalendarDate *newWeekDate;
  
  newWeekDate = [[self startDate] dateByAddingYears:0 months:0 days:7 
				   hours:0 minutes:0 seconds:0];
  return [self dateNavigationURLWithNewStartDate:newWeekDate];
}

- (NSString *)thisWeekURL {
  NSCalendarDate *newWeekDate;
  
  newWeekDate = [[NSCalendarDate date] mondayOfWeek];
  return [self dateNavigationURLWithNewStartDate:newWeekDate];
}

@end /* OGoCalWeekView */
