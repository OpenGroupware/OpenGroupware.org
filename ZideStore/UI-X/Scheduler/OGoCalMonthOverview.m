
#include "OGoCalMonthView.h"

@interface OGoCalMonthOverview : OGoCalMonthView
{
}

@end

#include "common.h"

@implementation OGoCalMonthOverview

- (NSArray *)appointments {
  return [self fetchCoreInfos];
}

@end /* OGoCalMonthOverview */
