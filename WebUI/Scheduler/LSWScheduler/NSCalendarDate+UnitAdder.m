
#include "common.h"

@implementation NSCalendarDate(UnitAdder)

- (NSCalendarDate *)dateByAddingValue:(int)_i inUnit:(NSString *)_unit {
  if (_i == 0)
    return self;
  
  if ([_unit isEqual:@"daily"])
    return [self dateByAddingYears:0 months:0 days:_i];
  
  if ([_unit isEqual:@"weekday"])
    return [self dateByAddingYears:0 months:0 days:_i];
  
  if ([_unit isEqual:@"weekly"])
    return [self dateByAddingYears:0 months:0 days:(_i * 7)];

  if ([_unit isEqual:@"14_daily"])
    return [self dateByAddingYears:0 months:0 days:(_i * 14)];
  
  if ([_unit isEqual:@"4_weekly"])
    return [self dateByAddingYears:0 months:0 days:(_i * 28)];
  
  if ([_unit isEqual:@"monthly"])
    return [self dateByAddingYears:0 months:(_i * 1) days:0];
  
  if ([_unit isEqual:@"yearly"])
    return [self dateByAddingYears:(_i * 1) months:0 days:0];
  
  /* the following are used in LSWAppointmentMove */
  
  if ([_unit isEqual:@"minutes"]) {
    return [self dateByAddingYears:0 months:0 days:0 hours:0
		 minutes:_i seconds:0];
  }
  if ([_unit isEqualToString:@"hours"]) {
    return [self dateByAddingYears:0 months:0 days:0 hours:_i
		 minutes:0 seconds:0];
  }
  if ([_unit isEqualToString:@"days"]) {
    return [self dateByAddingYears:0 months:0 days:_i hours:0
		 minutes:0 seconds:0];
  }
  if ([_unit isEqualToString:@"weeks"]) {
    return [self dateByAddingYears:0 months:0 days:7*_i hours:0
		 minutes:0 seconds:0];
  }
  if ([_unit isEqualToString:@"months"]) {
    return [self dateByAddingYears:0 months:_i days:0 hours:0
		 minutes:0 seconds:0];
  }
  if ([_unit isEqualToString:@"weekdays"]) {
    int i;
    int dir = (_i > 0) ? 1 : -1;
    
    for (i = _i; i != 0; i -= dir) {
      self = [self dateByAddingYears:0 months:0 days:dir hours:0
		   minutes:0 seconds:0];
      if (([self dayOfWeek] == 0) || ([self dayOfWeek] == 6)) {
        // sunday or saturday
        i += dir;
      }
    }
    return self;
  }
  
  NSLog(@"WARNING(%s): got unknown appointment value unit %@", 
        __PRETTY_FUNCTION__, _unit);
  return nil;
}

@end /* NSCalendarDate(CycleDateAdder) */
