
#include "OGoCalMonthView.h"
#include "common.h"

@implementation OGoCalMonthView

// TODO: look how to properly calculate month range!

- (NSCalendarDate *)startDate {
  // TODO: copy of the startdate method
  NSCalendarDate *startDate;
  NSString *dateString;
  
  dateString = [[[self context] request] formValueForKey:@"startDate"];
  startDate = dateString
    ? [self dateForDateString:dateString]
    : [[NSCalendarDate date] mondayOfWeek];
  
  return startDate;
}
- (NSCalendarDate *)endDate {
  return [[self startDate] dateByAddingYears:0 months:0 days:31
			   hours:0 minutes:0 seconds:0];
}

/* URLs (TODO: fix scroll ranges for months!) */

- (NSString *)prevMonthURL {
  NSCalendarDate *newMonthDate;
  
  newMonthDate = [[self startDate] dateByAddingYears:0 months:0 days:-31
				   hours:0 minutes:0 seconds:0];
  return [self dateNavigationURLWithNewStartDate:newMonthDate];
}

- (NSString *)nextMonthURL {
  NSCalendarDate *newMonthDate;
  
  newMonthDate = [[self startDate] dateByAddingYears:0 months:0 days:31
				   hours:0 minutes:0 seconds:0];
  return [self dateNavigationURLWithNewStartDate:newMonthDate];
}

- (NSString *)thisMonthURL {
  NSCalendarDate *newMonthDate;
  
  newMonthDate = [[NSCalendarDate date] mondayOfWeek];
  return [self dateNavigationURLWithNewStartDate:newMonthDate];
}

@end /* OGoCalMonthView */
