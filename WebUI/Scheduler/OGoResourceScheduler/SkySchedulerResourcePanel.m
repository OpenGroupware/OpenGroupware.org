/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoFoundation/OGoComponent.h>

/*
  a component to generate a fetchSpecification for a SkyAptDataSource
  includes input fields for all needed data
  used in scheduler page. (soon)

  Parameters:
  <>  timeZone    - timeZone
  <>  year        - selected year
  <>  month       - selected month
  <>  weekStart   - start of selected week
  <>  day         - selected day
  <   fetchSpecification - fetchSpecification for SkyAptDataSource
   >  mode        - viewMode (values:dayoverview|weekoverview|
                                     monthoverview|yearoverview)
*/

@class NSTimeZone, NSCalendarDate, NSArray, NSString, NSUserDefaults;

@interface SkySchedulerResourcePanel : OGoComponent
{
@protected
  NSArray        *resourceCategories;
  NSArray        *selectedCategories;
  NSArray        *resources;
  NSArray        *selectedResources;
  NSString       *searchString;

  id             item;
  NSArray        *resCache;             // caching resources of a category
  BOOL           reconfigure;
  BOOL           alreadyReconfigured;
  NSUserDefaults *defaults;
}

- (NSTimeZone *)timeZone;
- (NSCalendarDate *)weekStart;
- (id)show;

@end

#include "common.h"
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <time.h>

@interface SkySchedulerResourcePanel(PrivateMethods)
- (void)setResources:(NSArray *)_resources;
@end

@implementation SkySchedulerResourcePanel

+ (int)version {
  return 1;
}
- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}
- (id)init {
  if ((self = [super init])) {
    self->resourceCategories  = nil;
    self->resCache            = nil;
    self->selectedCategories  = nil;
    self->resources           = nil;
    self->selectedResources   = nil;
    self->reconfigure         = YES;
    self->alreadyReconfigured = NO;
    self->defaults            =
      [[self runCommand:@"userdefaults::get", @"user",
	       [[self session] activeAccount], nil] retain];
    
    self->searchString        = @"";
    self->selectedCategories =
      [[self->defaults valueForKey:@"scheduler_resourcePanel_selections"]
	               retain];
    self->selectedResources =
      [[self->defaults valueForKey:
	      @"scheduler_resourcePanel_resourceSelections"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->resourceCategories release];
  [self->selectedCategories release];
  [self->resources          release];
  [self->selectedResources  release];
  [self->searchString       release];
  [self->item               release];
  [self->resCache           release];
  [self->defaults           release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [super sleep];
  [self->defaults synchronize];
}

/* accessors */

- (NSArray *)fetchResourceCategories {
  NSArray *cats;
  cats = [self runCommand:@"appointmentresource::categories", nil];
  return cats;
}

- (NSArray *)fetchResources {
  NSMutableArray *all = [NSMutableArray array];
  NSEnumerator   *en  = nil;
  id             res  = nil;
  
  if ((self->searchString != nil) &&
      (![self->searchString isEqualToString:@""])) {
    res = [self runCommand:@"appointmentresource::extended-search",
                @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                @"operator",       @"OR",
                @"category",       self->searchString,
                @"name",           self->searchString,
                @"maxSearchCount", [NSNumber numberWithInt:1000], nil];
    if ([res count])
      res = [self runCommand:@"appointmentresource::get-by-globalid",
                  @"gids", res,
                  @"attributes", [NSArray arrayWithObject:@"name"], nil];
    if (res != nil) {
      NSEnumerator *resEnum = [res objectEnumerator];
      while ((res = [resEnum nextObject]))
        [all addObject:[res valueForKey:@"name"]];
    }
  }

  en = [[self->defaults
             valueForKey:@"scheduler_resourcePanel_resourceSelections"]
             objectEnumerator];
  while ((res = [en nextObject])) {
    if (![all containsObject:res])
      [all addObject:res];
  }
  return all;
}

/* accessors */

- (void)setResourceCategories:(NSArray *)_categories {
  ASSIGN(self->resourceCategories,_categories);
}
- (NSArray *)resourceCategories {
  if (self->resourceCategories == nil)
    [self setResourceCategories:[self fetchResourceCategories]];
  return self->resourceCategories;
}

- (void)setSelectedCategories:(NSArray *)_cats {
  ASSIGN(self->selectedCategories,_cats);
  self->reconfigure = YES;
  [self->resCache release]; self->resCache = nil;
  
  [self->defaults setObject:self->selectedCategories
       forKey:@"scheduler_resourcePanel_selections"];
}
- (NSArray *)selectedCategories {
  if (self->selectedCategories == nil) {
    [self setResourceCategories:[self fetchResourceCategories]];
    ASSIGN(self->selectedCategories, self->resourceCategories);
  }
  return self->selectedCategories;
}

- (void)setSelectedCategory:(NSString *)_category {
  [self setSelectedCategories:[NSArray arrayWithObject:_category]];
}
- (NSString *)selectedCategory {
  return [[self selectedCategories] lastObject];
}

- (void)setResources:(NSArray *)_resources {
  ASSIGN(self->resources,_resources);
}
- (NSArray *)resources {
  if (self->resources == nil)
    return [NSArray array];
  
  return self->resources;
}

- (void)setSelectedResources:(NSArray *)_res {
  ASSIGN(self->selectedResources,_res);
  self->reconfigure = YES;
  [self->resCache release]; self->resCache = nil;
  [self->defaults setObject:self->selectedResources
       forKey:@"scheduler_resourcePanel_resourceSelections"];
}
- (NSArray *)selectedResources {
  if (self->selectedResources == nil)
    return [NSArray array];
  
  return self->selectedResources;
}

- (void)setSearchString:(NSString *)_str {
  if ([self->searchString isEqualToString:_str])
    return;
  
  ASSIGNCOPY(self->searchString, _str);
    
  [self->resCache  release];  self->resCache  = nil;
  [self->resources release]; self->resources = nil;
  self->reconfigure = YES;
}
- (NSString *)searchString {
  return self->searchString;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (NSString *)categoryLabel {
  return self->item;
}

- (BOOL)showResources {
  return ((self->resources != nil) && ([self->resources count] > 0))
    ? YES : NO;
}

/* binding accessors */

- (void)setTimeZone:(NSTimeZone *)_tz {
  if ([_tz isEqual:[self timeZone]])
    return;

  [self setValue:_tz forBinding:@"timeZone"];
  self->reconfigure = YES;
}
- (NSTimeZone *)timeZone {
  return [self valueForBinding:@"timeZone"];
}

- (void)setYear:(int)_y {
  [self setValue:[NSNumber numberWithInt:_y] forBinding:@"year"];
}
- (int)year {
  return [[self valueForBinding:@"year"] intValue];
}

- (void)setIsResCategorySelected:(BOOL)_flag {
  [self setValue:[NSNumber numberWithBool:_flag]
        forBinding:@"isResCategorySelected"];
}

- (void)setMonth:(int)_m {
  [self setValue:[NSNumber numberWithInt:_m] forBinding:@"month"];
}
- (int)month {
  return [[self valueForBinding:@"month"] intValue];
}

- (void)setWeekStart:(NSCalendarDate *)_ws {
  if ([_ws isEqualToDate:[self weekStart]])
    return;

  [self setValue:_ws forBinding:@"weekStart"];
  [self setMonth:[_ws monthOfYear]];
  self->reconfigure = YES;
}
- (NSCalendarDate *)weekStart {
  return [self valueForBinding:@"weekStart"];
}

- (void)setDay:(NSCalendarDate *)_day {
  [self setValue:_day forBinding:@"day"];
}
- (NSCalendarDate *)day {
  return [self valueForBinding:@"day"];
}

- (NSString *)mode {
  return [self valueForBinding:@"mode"];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  [self setValue:_fspec forBinding:@"fetchSpecification"];
}

/* direct action support */

- (int)nextDayNumber {
  return [[[self day] tomorrow] dayOfMonth];
}
- (int)nextDayMonth {
  return [[[self day] tomorrow] monthOfYear];
}
- (int)nextDayYear {
  return [[[self day] tomorrow] yearOfCommonEra];
}

- (int)lastDayNumber {
  return [[[self day] yesterday] dayOfMonth];
}
- (int)lastDayMonth {
  return [[[self day] yesterday] monthOfYear];
}
- (int)lastDayYear {
  return [[[self day] yesterday] yearOfCommonEra];
}

// TODO: cache 'now' in ivar? (maybe reset in sleep?)

- (int)thisDayNumber {
  return [[NSCalendarDate date] dayOfMonth];
}
- (int)thisDayMonth {
  return [[NSCalendarDate date] monthOfYear];
}
- (int)thisDayYear {
  return [[NSCalendarDate date] yearOfCommonEra];
}

- (int)nextWeekNumber {
  NSCalendarDate *d;
  short woy, nowy;
  
  d = [[self weekStart] dateByAddingYears:0 months:0 days:7];
  
  woy  = [d weekOfYear];
  nowy = [d numberOfWeeksInYear];
  
  if (woy > nowy)
    woy = woy - nowy;
  
  return woy;
}
- (int)nextWeekYear {
  NSCalendarDate *d;
  short woy, nowy;
  
  d = [[self weekStart] dateByAddingYears:0 months:0 days:7];
  woy = [d weekOfYear];
  nowy = [d numberOfWeeksInYear];
  if (woy > nowy) 
    d = [d dateByAddingYears:0 months:0 days:6 hours:23 minutes:0 seconds:0];
  
  return [d yearOfCommonEra];
}

- (int)nextWeekMonth {
  NSCalendarDate *d;
  
  d = [[self weekStart] dateByAddingYears:0 months:0 days:7];
  return [d monthOfYear];
}

- (int)lastWeekNumber {
  NSCalendarDate *d;
  short woy, nowy;
  
  d = [[self weekStart] dateByAddingYears:0 months:0 days:-7];

  woy = [d weekOfYear];
  nowy = [d numberOfWeeksInYear];
  if (woy > nowy)
    woy = woy - nowy;
  
  return woy;
}
- (int)lastWeekYear {
  NSCalendarDate *d;
  short woy, nowy;
  
  d = [[self weekStart] dateByAddingYears:0 months:0 days:-7];
  
  woy = [d weekOfYear];
  nowy = [d numberOfWeeksInYear];
  if (woy > nowy) 
    d = [d dateByAddingYears:0 months:0 days:6 hours:23 minutes:0 seconds:0];
  
  return [d yearOfCommonEra];
}

- (int)lastWeekMonth {
  NSCalendarDate *d;
  
  d = [[self weekStart] dateByAddingYears:0 months:0 days:-7];
  
  return [d monthOfYear];
}

- (int)thisWeekNumber {
  NSCalendarDate *d;
  d = [NSCalendarDate date];
  return [d weekOfYear];
}
- (int)thisWeekYear {
  NSCalendarDate *d;
  d = [NSCalendarDate date];
  return [d yearOfCommonEra];
}
- (int)thisWeekMonth {
  NSCalendarDate *d;
  d = [NSCalendarDate date];
  return [d monthOfYear];
}

- (int)serial {
  extern unsigned getpid(void);
  return getpid() + time(NULL);
}

- (int)nextMonthNumber {
  int m = [self month];
  return (m == 12) ? 1 : m + 1;
}

- (int)nextMonthYear {
  int m = [self month];
  int y = [self year];
  return (m == 12) ? y + 1 : y;
}

- (int)lastMonthNumber {
  int m = [self month];
  return (m == 1) ? 12 : m - 1;
}

- (int)lastMonthYear {
  int m = [self month];
  int y = [self year];
  return (m == 1) ? y - 1 : y;
}

- (int)thisMonthNumber {
  NSCalendarDate *d = [NSCalendarDate date];
  [d setTimeZone:[self timeZone]];
  return [d monthOfYear];
}

- (int)thisMonthYear {
  NSCalendarDate *d = [NSCalendarDate date];
  [d setTimeZone:[self timeZone]];
  return [d yearOfCommonEra];
}

- (int)nextYearNumber {
  return [self year] + 1;
}

- (int)lastYearNumber {
  return [self year] - 1;
}

- (int)thisYearNumber {
  return [[NSCalendarDate date] yearOfCommonEra];
}

- (BOOL)isTimeZoneLicensed {
  return YES;
}

/* building fetchSpecification */

- (NSArray *)resourcesToFetch {
  NSMutableArray *all = [NSMutableArray array];
  NSEnumerator   *res = nil;
  id             obj  = nil;
  if (self->resCache != nil)
    return self->resCache;
  if ([self selectedCategories] != nil) {
    id cats = [self->selectedCategories objectEnumerator];
    id cat;

    while ((cat = [cats nextObject]))
      [all addObjectsFromArray:
           [self runCommand:@"appointmentresource::categories",
                 @"category", cat, nil]];
  }
  
  res = [[self selectedResources] objectEnumerator];
  while ((obj = [res nextObject])) {
    if (![all containsObject:obj])
      [all addObject:obj];
  }
  self->resCache = [all copy];
  return self->resCache;
}
  

- (EOFetchSpecification *)buildFetchSpecification {
  SkyAppointmentQualifier *q   = nil;
  EOFetchSpecification    *s   = nil;
  NSDictionary            *h   = nil;
  NSCalendarDate          *sD  = nil;
  NSCalendarDate          *eD  = nil;
  NSString                *m   = nil;
  static NSArray          *attrs = nil;
  NSArray                 *sO  = nil;
  NSArray                 *resToFetch = nil;

  resToFetch = [self resourcesToFetch];

  if ([resToFetch count] == 0)
    return nil;
  
  if (attrs == nil) {
    attrs =
      [[NSArray alloc] initWithObjects:
                       @"title",
                       @"location",
                       @"startDate",
                       @"endDate",
                       @"globalID",
                       @"ownerId",
                       @"accessTeamId",
                       @"permissions",
                       @"resourceNames",
                       @"participants.companyId",
                       @"participants.globalID",
                       @"participants.login",
                       @"participants.firstname",
                       @"participants.name",
                       @"participants.description",
                       @"participants.isTeam",
                       @"participants.isAccount",
                       nil];
  }

  q = [[[SkyAppointmentQualifier alloc] init] autorelease];
  m = [self mode];
  if ([m isEqualToString:@"dayoverview"]) {
    NSCalendarDate *d = [self day];
    sD = [d beginOfDay];
    eD = [d endOfDay];
  }
  else if ([m isEqualToString:@"weekoverview"]) {
    NSCalendarDate *ws = [self weekStart];
    sD = [ws beginOfDay];
    eD = [[ws dateByAddingYears:0 months:0 days:6] endOfDay];
  }
  else if ([m isEqualToString:@"monthoverview"]) {
    int dif;
    sD = [NSCalendarDate dateWithYear:[self year] month:[self month] day:1
                         hour:0 minute:0 second:0 timeZone:[self timeZone]];
    eD = [[sD lastDayOfMonth] endOfDay];
    
    //    dif = self->firstDayOfWeek - [sD dayOfWeek];
    dif = 1 - [sD dayOfWeek];
    dif = (dif > 0) ? dif - 7 : dif;
    sD  = [sD dateByAddingYears:0 months:0 days:dif];
    
    //    dif = self->firstDayOfWeek - [eD dayOfWeek] -1;
    dif = [eD dayOfWeek];
    dif = (dif < 0) ? dif + 7 : dif;
    eD  = [eD dateByAddingYears:0 months:0 days:dif];
  }
  else {
    sD = [NSCalendarDate dateWithYear:[self year] month:1 day:1
                         hour:0 minute:0 second:0 timeZone:[self timeZone]];
    eD = [[sD dateByAddingYears:1 months:0 days:-1] endOfDay];
  }
  
  [q setStartDate:sD];
  [q setEndDate:eD];
  [q setTimeZone:[self timeZone]];
  [q setCompanies:[NSArray array]];
  [q setResources:resToFetch];
  
  h = [NSDictionary dictionaryWithObjectsAndKeys:
                    attrs, @"attributeKeys",
                    nil];

  sO = [NSArray arrayWithObject:
                [EOSortOrdering sortOrderingWithKey:@"startDate"
                                selector:EOCompareAscending]];
  
  s = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                            qualifier:q
                            sortOrderings:sO];
  [s setHints:h];
  
  return s;
}

- (void)reconfigure {
  if (![self->searchString isEqualToString:@""]) {
    [self setResources:[self fetchResources]];
    [self setSelectedResources:self->resources];
    [self->searchString release];
    self->searchString = @"";
  } 
  else {
    [self setResources:self->selectedResources];
  }
  [self setFetchSpecification:[self buildFetchSpecification]];
  self->reconfigure = NO;
  self->alreadyReconfigured = YES;
}

- (id)show {
  if (self->reconfigure)
    [self reconfigure];
  // internal action (submit button) --> no additional configuration
  self->alreadyReconfigured = YES;
  return nil;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  id tobj = nil;
  
  if ((tobj = [[self session] removeTransferObject])) {
    if ([tobj isKindOfClass:[NSString class]]) {
      if ([(NSString *)tobj hasPrefix:@"resource:"]) {
        NSString *res;

        res = [tobj substringFromIndex:9];
        [self setSelectedResources:[NSArray arrayWithObject:res]];
        [self setSelectedCategories:[NSArray array]];
        self->alreadyReconfigured = NO;
      }
    }
  }
  
  if (([self->selectedCategories count] == 0) &&
      ([self->selectedResources count] > 0))
    [self setIsResCategorySelected:NO];
  else
    [self setIsResCategorySelected:YES];

  // external action proceed (no submit button clicked) --> reconfigure
  if (!self->alreadyReconfigured)
    [self reconfigure];

  self->alreadyReconfigured = NO;

  [super appendToResponse:_response inContext:_ctx];
}

@end /* SkySchedulerResourcePanel */
