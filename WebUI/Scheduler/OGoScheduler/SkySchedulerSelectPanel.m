/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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
  A component to generate a fetchSpecification for a SkyAptDataSource
  includes input fields for all needed data used in scheduler page. (soon)

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

@class NSTimeZone, NSCalendarDate, NSArray, NSMutableArray, NSUserDefaults;

@interface SkySchedulerSelectPanel : OGoComponent
{
@protected
  NSString *searchString;
  
  NSArray        *accounts;
  NSMutableArray *selectedAccounts;
  NSArray        *selAcCache;
  NSArray        *persons;
  NSMutableArray *selectedPersons;
  NSArray        *selPerCache;
  NSArray        *teams;
  NSMutableArray *selectedTeams;
  NSArray        *selTmCache;
  NSArray        *resources;
  NSArray        *aptTypes;
  NSArray        *selectedAptTypes;
  NSMutableArray *selectedResources;
  NSArray        *selResCache;
  NSUserDefaults *defaults;

  id       item;
  id       selectedCompany;
  id       activeAccount;
  BOOL     fetchMeToo;
  BOOL     isExtended;
  int      maxSearchCount;
  BOOL     reconfigure;
  BOOL     alreadyReconfigured;
}
- (BOOL)hasAccounts;
- (BOOL)hasPersons;
- (BOOL)hasTeams;
- (BOOL)hasResources;

- (NSString *)monthLabel;
- (NSString *)extendButtonImg;
- (NSString *)extendButtonLabel;

- (NSTimeZone *)timeZone;
- (NSCalendarDate *)weekStart;
- (id)show;
- (id)extend;

@end

#include "common.h"
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSCommandContext.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <time.h>

@interface SkySchedulerSelectPanel(PrivateMethods)
- (void)setSelectedCompany:(id)_company;
@end

@implementation SkySchedulerSelectPanel

static NSArray      *aptFetchAttrNames        = nil;
static NSArray      *teamInfoAttrNames        = nil;
static NSArray      *personInfoAttrNames      = nil;
static NSDictionary *aptFetchAttrHints        = nil;
static NSArray      *startDateSortOrderings   = nil;
static NSArray      *descriptionSortOrderings = nil;
static NSArray      *nameFirstNameSortOrderings = nil;
static NSArray      *nameSortOrderings          = nil;
static NSArray      *monthNames                 = nil;
static NSNumber     *yesNum                     = nil;
static BOOL         showOnlyMemberTeams = NO;

+ (int)version {
  return 1; // TODO: looks weird, should be: [super version] + 0 /* v2 */;
}

+ (void)initialize {
  static BOOL didInit = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  EOSortOrdering *so, *so2;
  if (didInit) return;
  didInit = YES;

  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  yesNum = [[NSNumber numberWithBool:YES] retain];

  if ((showOnlyMemberTeams = [ud boolForKey:@"scheduler_memberteams_only"])) {
    NSLog(@"Note: %@ configured to show member-teams only.",
          NSStringFromClass(self));
  }
  
  /* setup sort orderings */
  
  so = [EOSortOrdering sortOrderingWithKey:@"startDate"
		       selector:EOCompareAscending];
  startDateSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];

  so = [EOSortOrdering sortOrderingWithKey:@"description"
		       selector:EOCompareAscending];
  descriptionSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];
  
  so = [EOSortOrdering sortOrderingWithKey:@"name" 
		       selector:EOCompareAscending];
  so2 = [EOSortOrdering sortOrderingWithKey:@"firstname"
			selector:EOCompareAscending];
  nameFirstNameSortOrderings = [[NSArray alloc] initWithObjects:so, so2, nil];

  so = [EOSortOrdering sortOrderingWithKey:@"name" 
		       selector:EOCompareAscending];
  nameSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];

  aptFetchAttrNames = [[ud arrayForKey:@"schedulerselect_fetchkeys"] copy];
  aptFetchAttrHints =
    [[NSDictionary alloc] initWithObjectsAndKeys:
			    aptFetchAttrNames, @"attributeKeys", nil];
  
  teamInfoAttrNames = [[ud arrayForKey:@"schedulerselect_teamfetchkeys"] copy];
  personInfoAttrNames = 
    [[ud arrayForKey:@"schedulerselect_personfetchkeys"] copy];
  
  monthNames = [[ud arrayForKey:@"schedulerselect_months"] copy];
}

/* mark components as non-sync */

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (id)init {
  if ((self = [super init])) {
    id             me;
    EOKeyGlobalID  *gid;
    NSUserDefaults *ud;

    self->maxSearchCount = 20;
    self->reconfigure    = YES;
      
    me = [[self session] activeAccount];
    self->activeAccount = [me retain];
      
    gid = [me valueForKey:@"globalID"];
    
    me = [[self runCommand:@"person::get-by-globalID",
                  @"gids",       gid ? [NSArray arrayWithObject:gid] : nil,
		  @"attributes", personInfoAttrNames,
		nil] lastObject];
    [self setSelectedCompany:me];

    ud = [self runCommand:@"userdefaults::get", @"user", me, nil];
    self->defaults = [ud retain];
  }
  return self;
}

- (void)dealloc {
  [self->activeAccount    release];
  [self->defaults          release];
  [self->searchString      release];
  [self->accounts          release];
  [self->selectedAccounts  release];
  [self->selAcCache        release];
  [self->persons           release];
  [self->selectedPersons   release];
  [self->selPerCache       release];
  [self->teams             release];
  [self->selectedTeams     release];
  [self->selTmCache        release];
  [self->resources         release];
  [self->selectedResources release];
  [self->selResCache       release];
  [self->selectedAptTypes  release];
  [self->aptTypes          release];

  [self->item            release];
  [self->selectedCompany release];
  [super dealloc];
}

/* accessors */

- (void)_setLabelForPerson:(id)_p {
  // TODO: should be a formatter
  id p, d;
  
  p = _p;
  d = nil;

  // TODO: should be a NSFormatter
  if ((d = [p valueForKey:@"name"]) == nil)
    d = [p valueForKey:@"login"];
  else {
    NSString *fd = [p valueForKey:@"firstname"];
    
    if ([fd isNotNull])
      d = [NSString stringWithFormat:@"%@, %@", d, fd];
  }
  [p takeValue:d forKey:@"participantLabel"];
}

- (void)_updatePersonList:(NSArray *)_list {
  NSEnumerator *pEnum;
  id           p;
  
  pEnum =  [_list objectEnumerator];
  while ((p = [pEnum nextObject]))
    [self _setLabelForPerson:p];
}

/* accessors */

- (void)setSearchString:(NSString *)_str {
  ASSIGNCOPY(self->searchString,_str);
}
- (NSString *)searchString {
  return self->searchString;
}

- (void)setAccounts:(NSArray *)_accounts {
  ASSIGN(self->accounts,_accounts);
}
- (NSArray *)accounts {
  return self->accounts;
}

- (void)setSelectedAccounts:(NSArray *)_accounts {
  ASSIGN(self->selectedAccounts, _accounts);
}
- (NSMutableArray *)selectedAccounts {
  if (self->selectedAccounts == nil) 
    return [NSMutableArray array];

  return selectedAccounts;
}

- (void)setPersons:(NSArray *)_persons {
  ASSIGN(self->persons, _persons);
}
- (NSArray *)persons {
  return self->persons;
}

- (void)setSelectedPersons:(NSArray *)_persons {
  ASSIGN(self->selectedPersons, _persons);
}
- (NSMutableArray *)selectedPersons {
  if (self->selectedPersons == nil) 
    return [NSMutableArray array];

  return self->selectedPersons;
}

- (void)setTeams:(NSArray *)_teams {
  ASSIGN(self->teams,_teams);
}
- (NSArray *)teams {
  return self->teams;
}

- (void)setSelectedTeams:(NSArray *)_teams {
  ASSIGN(self->selectedTeams, _teams);
}
- (NSMutableArray *)selectedTeams {
  return (self->selectedTeams == nil)
    ? (NSMutableArray *)[NSMutableArray arrayWithCapacity:4]
    : self->selectedTeams;
}

- (void)setResources:(NSArray *)_resources {
  ASSIGN(self->resources, _resources);
}
- (NSArray *)resources {
  return self->resources;
}

- (void)setSelectedResources:(NSArray *)_resources {
  ASSIGN(self->selectedResources,_resources);
}
- (NSArray *)selectedResources {
  return (self->selectedResources == nil)
    ? (NSMutableArray *)[NSMutableArray arrayWithCapacity:4]
    : self->selectedResources;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setSelectedCompany:(id)_company {
  if (![_company isEqual:self->selectedCompany]) {
    ASSIGN(self->selectedCompany,_company);
    self->reconfigure = YES;
  }
}
- (id)selectedCompany {
  return self->selectedCompany;
}

- (void)setFetchMeToo:(BOOL)_flag {
  if (_flag != self->fetchMeToo) {
    self->fetchMeToo = _flag;
    self->reconfigure = YES;
  }
}
- (BOOL)fetchMeToo {
  return self->fetchMeToo;
}

- (void)setIsExtended:(BOOL)_flag {
  self->isExtended = _flag;
}
- (BOOL)isExtended {
  return self->isExtended;
}

/* appointment types */

- (NSArray *)configuredAptTypes {
  // TODO: duplicate code, also in LSWAppointmentViewer
  NSUserDefaults *ud;
  NSArray *configured;
  NSArray *custom     = nil;
  
  ud = [[self session] userDefaults];
  configured = [ud arrayForKey:@"SkyScheduler_defaultAppointmentTypes"];
  if (configured == nil) configured = [NSArray array];
  custom = [ud arrayForKey:@"SkyScheduler_customAppointmentTypes"];
  if (custom != nil)
    configured = [configured arrayByAddingObjectsFromArray:custom];
  return configured;
}
- (NSArray *)aptTypes {
  if (self->aptTypes == nil)
    aptTypes = [[self configuredAptTypes] copy];
  return aptTypes;
}
- (NSString *)aptTypeLabel {
  NSString *label;

  if ((label = [self->item valueForKey:@"label"]))
    return label;
  
  // TODO: should be a formatter?
  label = [[self->item valueForKey:@"type"] stringValue];
  label = [@"aptType_" stringByAppendingString:label];
  return [[self labels] valueForKey:label];
}

/* single mode */
- (void)setSelectedAptType:(id)_type {
  NSString *key;
  
  key = [_type valueForKey:@"type"];
  if ([key isEqual:[self->selectedAptTypes lastObject]])
    return;

  [self->selectedAptTypes release];
  if ((key == nil) || ([key isEqualToString:@"none"])) 
    self->selectedAptTypes = nil;
  else
    self->selectedAptTypes = [[NSArray alloc] initWithObjects:key, nil];
  self->reconfigure = YES;
}
- (id)selectedAptType {
  NSEnumerator *e;
  id           one;
  NSString     *wanted;
  
  e      = [[self aptTypes] objectEnumerator];
  wanted = [self->selectedAptTypes lastObject];
  
  while ((one = [e nextObject]) != nil) {
    NSString *key;
    
    key = [one valueForKey:@"type"];
    if ((![wanted length]) && [key isEqualToString:@"none"])
      return one;
    if ([wanted isEqualToString:key])
      return one;
  }
  return nil;
}

/* binding accessors */

- (void)setRealTimeZone:(NSTimeZone *)_tz {
  if ([_tz isEqual:[self timeZone]])
    return;

  [self setValue:_tz forBinding:@"timeZone"];
  self->reconfigure = YES;
}
- (NSTimeZone *)timeZone {
  return [self valueForBinding:@"timeZone"];
}
- (NSTimeZone *)realTimeZone {
  return [self timeZone];
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
- (BOOL)isResCategorySelected {
  return [[self valueForBinding:@"isResCategorySelected"] boolValue];
}

- (void)setMonth:(int)_m {
  [self setValue:[NSNumber numberWithInt:_m] forBinding:@"month"];
}
- (int)month {
  return [[self valueForBinding:@"month"] intValue];
}

- (void)setWeekStart:(NSCalendarDate *)_ws {
  if (![_ws isEqualToDate:[self weekStart]]) {
    [self setValue:_ws forBinding:@"weekStart"];
    [self setMonth:[_ws monthOfYear]];
    self->reconfigure = YES;
  }
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

/* additional accessors */

- (NSString *)extendButtonLabel {
  NSString *label, *key;
  key = (self->isExtended)
    ? @"unextend"
    : @"extend";
  return ((label = [[self labels] valueForKey:key]))
    ? label
    : key;
}

- (NSString *)extendButtonImg {
  return (self->isExtended)
    ? @"up_icon.gif"
    : @"down_icon.gif";
}

- (NSString *)monthLabel {
  int month;
  
  month = [[self item] intValue];
  // TODO: range check!
  return [[self labels] valueForKey:[monthNames objectAtIndex:(month - 1)]];
}

- (void)setSelMonth:(NSNumber *)_month {
  [self setMonth:[_month intValue]];
}
- (NSNumber *)selMonth {
  return [NSNumber numberWithInt:[self month]];
}

/* conditional */

- (BOOL)hasAccounts {
  return [self->accounts isNotEmpty];
}
- (BOOL)hasPersons {
  return [self->persons isNotEmpty];
}
- (BOOL)hasTeams {
  return [self->teams isNotEmpty];
}
- (BOOL)hasResources {
  return [self->resources isNotEmpty];
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
  int moy, nextYear, thisYear;
  NSCalendarDate *d;

  d = [self weekStart];
  thisYear = [d yearOfCommonEra];
  nextYear = [self nextWeekYear];
  if (nextYear != thisYear)
    moy = 1;
  else {
    d   = [[self weekStart] dateByAddingYears:0 months:0 days:7];
    moy = [d monthOfYear];
  }
  return moy;
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

- (NSDate *)timeZoneReferenceDate {
  NSString *m = [self mode];
  if ([m isEqualToString:@"dayoverview"])
    return [self day];
  else if ([m isEqualToString:@"weekoverview"]) 
    return [self weekStart];
  else if ([m isEqualToString:@"monthoverview"]) 
    return [NSCalendarDate dateWithYear:[self year] month:[self month] day:1
                           hour:0 minute:0 second:0 timeZone:[self timeZone]];
  
  return [NSCalendarDate dateWithYear:[self year] month:1 day:1
                         hour:0 minute:0 second:0 timeZone:[self timeZone]];
}

/* building fetchSpecification */

- (NSArray *)companiesToFetch {
  NSArray *comps;
  
  if (!self->isExtended) {
    if (![self->selectedCompany isKindOfClass:[NSString class]]) {
      comps = [NSArray arrayWithObject:
                       [self->selectedCompany valueForKey:@"globalID"]];
    }
    else
      comps = [NSArray array];
    if (self->fetchMeToo) {
      id me = [(id)[self session] activeAccount];
      comps = [comps arrayByAddingObject:[me valueForKey:@"globalID"]];
    }
  }
  else {
    comps = [NSArray array];
    if ((self->selectedAccounts != nil) &&
        ([self->selectedAccounts count] != 0)) {
      comps = [comps arrayByAddingObjectsFromArray:
                     [self->selectedAccounts valueForKey:@"globalID"]];
    }
    if ((self->selectedPersons != nil) &&
        ([self->selectedPersons count] != 0)) {
      comps = [comps arrayByAddingObjectsFromArray:
                     [self->selectedPersons valueForKey:@"globalID"]];
    }
    if ((self->selectedTeams != nil) &&
        ([self->selectedTeams count] != 0)) {
      comps = [comps arrayByAddingObjectsFromArray:
                     [self->selectedTeams valueForKey:@"globalID"]];
    }
  }
  return comps;
}

- (NSArray *)_fetchResourceGIDsForCategory:(NSString *)s {
  NSArray *tmp;

  tmp = [self runCommand:@"appointmentresource::extended-search",
	        @"fetchGlobalIDs", yesNum,
                @"operator",       @"OR",
                @"category",       s,
                @"maxSearchCount", [NSNumber numberWithInt:1000], nil];
  return tmp;
}
- (NSArray *)_fetchResourceNamesForGIDs:(NSArray *)_gids {
  NSArray *tmp;
  
  tmp = [self runCommand:@"appointmentresource::get-by-globalid",
	        @"gids", _gids,
  	        @"attributes", [NSArray arrayWithObject:@"name"], nil];
  return tmp;
}

- (NSArray *)resourcesToFetch {
  // TODO: split up
  NSArray  *res;
  NSString *l;
  NSString *s;
  NSArray  *tmp;
  id  resSet;

  resSet = [NSMutableSet setWithCapacity:16];

  l = [[self labels] valueForKey:@"resCategory"];

  if (l == nil) l = @"resCategory";

  l = [NSString stringWithFormat:@"(%@)", l];

  [self setIsResCategorySelected:NO];

  // TODO: split into methods
  if (!self->isExtended) {
    if ([self->selectedCompany isKindOfClass:[NSString class]]) {
      id s = self->selectedCompany;

      if ([s hasSuffix:l]) {
        s = [[s componentsSeparatedByString:@" ("] objectAtIndex:0];
	tmp = [self _fetchResourceGIDsForCategory:s];
        if ([tmp count] > 0)
	  tmp = [self _fetchResourceNamesForGIDs:tmp];
	
        if (tmp != nil && [tmp count] > 0) {
          [resSet addObjectsFromArray:[tmp valueForKey:@"name"]];
          [self setIsResCategorySelected:YES];
        }
        res = [resSet allObjects];
      }
      else
        res = [NSArray arrayWithObject:s];
    }
    else
      res = [NSArray array];
  }
  else {
    int i, cnt;

    for (i = 0, cnt = [self->selectedResources count]; i < cnt; i++) {
      id       r;

      r = [self->selectedResources objectAtIndex:i];
      s = [r valueForKey:@"name"];
      if ([s hasSuffix:l]) {
        s = [[s componentsSeparatedByString:@" ("] objectAtIndex:0];
	tmp = [self _fetchResourceGIDsForCategory:s];
        if ([tmp count] > 0)
	  tmp = [self _fetchResourceNamesForGIDs:tmp];
	
        if (tmp != nil && [tmp count] > 0) {
          [self setIsResCategorySelected:YES];
          [resSet addObjectsFromArray:[tmp valueForKey:@"name"]];
        }
      }
      else
        [resSet addObject:[r valueForKey:@"name"]];
    }
    res = [resSet allObjects];
  }
  return res;
}

- (void)_getStartDate:(NSCalendarDate **)_sd andEndDate:(NSCalendarDate **)_ed
  forMode:(NSString *)m
{
  // TODO: can we improve that section? Eg some object representing a given
  //       view?
  NSCalendarDate *sD = nil, *eD = nil;
  
  if (![m isNotNull]) m = @"yearoverview";
  
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
    dif = 0 - [eD dayOfWeek];
    dif = (dif < 0) ? dif + 7 : dif;
    eD  = [eD dateByAddingYears:0 months:0 days:dif];
  }
  else {
    sD = [NSCalendarDate dateWithYear:[self year] month:1 day:1
                         hour:0 minute:0 second:0 timeZone:[self timeZone]];
    eD = [[sD dateByAddingYears:1 months:0 days:-1] endOfDay];
  }
  *_sd = sD;
  *_ed = eD;
}

- (EOFetchSpecification *)buildFetchSpecification {
  SkyAppointmentQualifier *q;
  EOFetchSpecification    *s   = nil;
  NSCalendarDate          *sD  = nil;
  NSCalendarDate          *eD  = nil;
  
  [self _getStartDate:&sD andEndDate:&eD forMode:[self mode]];
  
  q = [[[SkyAppointmentQualifier alloc] init] autorelease];
  [q setStartDate:sD];
  [q setEndDate:eD];
  [q setTimeZone:[self timeZone]];
  [q setCompanies:[self companiesToFetch]];
  [q setResources:[self resourcesToFetch]];
  [q setAptTypes:self->selectedAptTypes];
  
  s = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                            qualifier:q
                            sortOrderings:startDateSortOrderings];
  [s setHints:aptFetchAttrHints];
  
  return s;
}

- (BOOL)needToReconfigure {
  if (self->reconfigure)
    return YES;

  if ((self->selAcCache == nil) && ([[self selectedAccounts] count] > 0))
    return YES;
  if ((self->selAcCache != nil) &&
      (![self->selAcCache isEqualToArray:[self selectedAccounts]])) 
    return YES;
  
  if ((self->selPerCache == nil) && ([[self selectedPersons] count] > 0))
    return YES;
  if ((self->selPerCache != nil) &&
      (![self->selPerCache isEqualToArray:[self selectedPersons]])) 
    return YES;

  if ((self->selTmCache == nil) && ([[self selectedTeams] count] > 0)) 
    return YES;
  if ((self->selTmCache != nil) &&
      (![self->selTmCache isEqualToArray:[self selectedTeams]])) 
    return YES;

  if ((self->selResCache == nil) && ([[self selectedResources] count] > 0))
    return YES;
  if ((self->selResCache != nil) &&
      (![self->selResCache isEqualToArray:[self selectedResources]])) 
    return YES;

  return NO;
}

- (NSNumber *)activeAccountID {
  return [self->activeAccount valueForKey:@"companyId"];
}

- (void)_writePanelResourcesNames:(NSArray *)r {
  [self runCommand:@"userdefaults::write",
          @"key",          @"scheduler_panel_resourceNames",
          @"value",        r,
          @"userdefaults", self->defaults,
          @"userId",       [self activeAccountID], nil];
}
- (void)_writeIDs:(NSArray *)_ids toDefaultNamed:(NSString *)_defName {
  _defName = [@"scheduler_panel_" stringByAppendingString:_defName];
  [self runCommand:@"userdefaults::write",
	  @"key",          _defName,
          @"value",        _ids,
          @"userdefaults", self->defaults,
          @"userId",       [self activeAccountID], nil];
}
- (void)_writeIDsOfCompanyEOs:(NSArray *)_eos toDefaultNamed:(NSString *)_def {
  NSMutableArray *ma;
  unsigned i, count;
  
  count = [_eos count];
  ma = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSNumber *pkey;
    
    pkey = [[_eos objectAtIndex:i] valueForKey:@"companyId"];
    if (![pkey isNotNull]) continue;
    [ma addObject:pkey];
  }
  [self _writeIDs:ma toDefaultNamed:_def];
  [ma release];
}
- (NSArray *)_readGIDsOfEntity:(NSString *)_e fromDefaultNamed:(NSString *)_d {
  NSMutableArray *gids;
  NSArray  *strs;
  unsigned i, count;
  
  _d = [@"scheduler_panel_" stringByAppendingString:_d];
  if ((strs = [self->defaults arrayForKey:_d]) == nil)
    return nil;
  
  count = [strs count];
  gids  = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSNumber      *pkey;
    EOKeyGlobalID *gid;
    
    pkey = [NSNumber numberWithUnsignedInt:[[strs objectAtIndex:i] intValue]];
    if (pkey == nil) continue;
    
    gid  = [EOKeyGlobalID globalIDWithEntityName:_e
			  keys:&pkey keyCount:1 zone:NULL];
    if (gid) [gids addObject:gid];
  }
  return gids;
}

- (void)writePanelItemsToDefaults {
  NSEnumerator   *enumerator;
  NSMutableArray *r;
  NSString       *n;
  NSString       *s;
  NSArray        *resNames;

  resNames = [self->resources valueForKey:@"name"];
  s = [[self labels] valueForKey:@"resCategory"];
  if (s == nil) s = @"resCategory";
    
  s = [NSString stringWithFormat:@"(%@)", s];
  r = [NSMutableArray arrayWithCapacity:8];
    
  enumerator = [resNames objectEnumerator];
  while ((n = [enumerator nextObject])) {
      if ([n hasSuffix:s]) {
        n = [[n  componentsSeparatedByString:@" ("] objectAtIndex:0];
	n = [n stringByAppendingString:@" (resCategory)"];
        [r addObject:n];
      }
      else 
        [r addObject:n];
  }
  [self _writePanelResourcesNames:r];
  
  [self _writeIDsOfCompanyEOs:self->persons  toDefaultNamed:@"persons"];
  [self _writeIDsOfCompanyEOs:self->accounts toDefaultNamed:@"accounts"];
  [self _writeIDsOfCompanyEOs:self->teams    toDefaultNamed:@"teams"];
}

- (void)reconfigure {
  [self debugWithFormat:@"Note: reconfiguring datasource"];

  [self setFetchSpecification:[self buildFetchSpecification]];
  self->reconfigure = NO;
  self->alreadyReconfigured = YES;

  if (self->isExtended)
    [self writePanelItemsToDefaults];
}

- (NSArray *)appendItems:(NSArray *)_items toArray:(NSArray *)_array {
  int i, cnt;
  id  obj;
  NSMutableArray *ma = [_array mutableCopy];
  if (ma == nil)
    ma = [[NSMutableArray alloc] init];

  i = 0; cnt = [_items count];
  
  while (i < cnt) {
    obj = [_items objectAtIndex:i++];
    if ((_array == nil) || ![_array containsObject:obj])
      [ma addObject:obj];
  }
  return AUTORELEASE(ma);
}

- (void)_initializePreSelectedItems {
  // TODO: split up this huge method
  id tmp = nil;
  id res = nil;
  
  tmp = [self _readGIDsOfEntity:@"Team" fromDefaultNamed:@"teams"];
  if ([tmp count] > 0) {
    NSArray *t;
    
    res = [self runCommand:@"team::get-by-globalID",
                  @"gids",       tmp,
                  @"attributes", teamInfoAttrNames,
                  @"groupBy",    @"globalID",
		nil];
    res = [res allValues];

    t = [res sortedArrayUsingKeyOrderArray:descriptionSortOrderings];
    [self->selectedTeams release]; self->selectedTeams = nil;
    self->selectedTeams = [t mutableCopy];
    [self->teams release]; self->teams = nil;
    self->teams = [self->selectedTeams copy];
  }
  
  /* fetch accounts */
  
  tmp = [self _readGIDsOfEntity:@"Person" fromDefaultNamed:@"accounts"];
  if ([tmp count] > 0) {
    NSArray *ac;
    
    res = [self runCommand:@"person::get-by-globalID",
                  @"gids",       tmp,
		  @"attributes", personInfoAttrNames,
                  @"groupBy",    @"globalID",
                  nil];
    res = [res allValues];
	
    ac = [res sortedArrayUsingKeyOrderArray:nameFirstNameSortOrderings];
    [self->selectedAccounts release]; self->selectedAccounts = nil;
    self->selectedAccounts = [ac mutableCopy];
    [self->accounts release]; self->accounts = nil;
    self->accounts = [self->selectedAccounts copy];
  }
  
  /* fetch persons */
  
  tmp = [self _readGIDsOfEntity:@"Person" fromDefaultNamed:@"persons"];
  if ([tmp count] > 0) {
    NSArray *ps;
    
    res = [self runCommand:@"person::get-by-globalID",
                  @"gids",       tmp,
		  @"attributes", personInfoAttrNames,
                  @"groupBy",    @"globalID",
		nil];
    res = [res allValues];
    
    ps = [res sortedArrayUsingKeyOrderArray:nameFirstNameSortOrderings];
    [self->selectedPersons release];
    self->selectedPersons = [ps mutableCopy];
    [self->persons release];
    self->persons = [self->selectedPersons copy];
  }

  /* resource names */

  tmp = [self->defaults arrayForKey:@"scheduler_panel_resourceNames"];
  {
    NSEnumerator   *enumerator = nil;
    NSMutableArray *r          = nil;
    NSString       *n          = nil;
    NSString       *s          = nil;

    s = [[self labels] valueForKey:@"resCategory"];
    if (s == nil) s = @"resCategory";
    
    r = [NSMutableArray arrayWithCapacity:8];
    
    enumerator = [tmp objectEnumerator];

    while ((n = [enumerator nextObject])) {
      if ([n hasSuffix:@"(resCategory)"]) {
        n = [[n  componentsSeparatedByString:@" ("] objectAtIndex:0];
        [r addObject:[NSString stringWithFormat:@"%@ (%@)", n, s]];
      }
      else 
        [r addObject:n];
    }
    ASSIGN(self->resources, r);
  }

  {
    NSEnumerator   *enumerator = nil;
    NSMutableArray *r          = nil;
    NSString       *n          = nil;
    NSString       *s          = nil;

    s = [[self labels] valueForKey:@"resCategory"];
    if (s == nil) s = @"resCategory";
    
    r = [NSMutableArray arrayWithCapacity:8];
    
    enumerator = [tmp objectEnumerator];

    while ((n = [enumerator nextObject])) {
      NSMutableDictionary *rD;

      rD = [NSMutableDictionary dictionaryWithCapacity:1];
      
      if ([n hasSuffix:@"(resCategory)"]) {
        n = [[n  componentsSeparatedByString:@" ("] objectAtIndex:0];
	n = [[NSString alloc] initWithFormat:@"%@ (%@)", n, s];
        [rD setObject:n forKey:@"name"];
	[n release]; n = nil;
      }
      else {
        [rD setObject:n forKey:@"name"];
      }
      [r addObject:rD];
    }    
    [self setSelectedResources:r];
    [self->resources release]; self->resources = nil;
    self->resources = [self->selectedResources copy];
  }
}

- (NSArray *)distinctCategories:(NSArray *)_items {
  int i, cnt;
  id  obj;
  NSMutableArray *ma;
  NSString *l;

  ma = [NSMutableArray arrayWithCapacity:8];
  l = [[self labels] valueForKey:@"resCategory"];

  if (l == nil) l = @"resCategory";
  
  i = 0; cnt = [_items count];
  
  while (i < cnt) {
    NSMutableDictionary *rD;
    NSString            *s;

    obj = [_items objectAtIndex:i++];
    
    s = [NSString stringWithFormat:@"%@ (%@)",
                  [obj valueForKey:@"category"], l];
    rD = [NSMutableDictionary dictionaryWithCapacity:1];
    [rD setObject:s forKey:@"name"];

    if (![ma containsObject:rD])
      [ma addObject:rD];
  }
  return ma;
}

- (void)computeSearchString {
  if (!self->isExtended)
    return;
  
  if ((self->searchString == nil) ||
      ([self->searchString isEqualToString:@""])) {
    [self setTeams:self->selectedTeams];
    [self setResources:self->selectedResources];
    [self setAccounts:self->selectedAccounts];
    [self setPersons:self->selectedPersons];
  }
  else {
    id  res;
    int cnt;
    int max = self->maxSearchCount;

    // teams
    res = self->selectedTeams;
    cnt = (res) ? [res count] : 0;
    res = [self runCommand:@"team::extended-search",
                @"fetchGlobalIDs", yesNum,
                @"operator",       @"OR",
                @"description",    self->searchString,
                @"maxSearchCount", [NSNumber numberWithInt:(max - cnt)],
                @"onlyTeamsWithAccount", 
                 (showOnlyMemberTeams
                  ? [[self session] activeAccount] : (id)[NSNull null]),
                nil];
    if (res != nil) {
      res = [self runCommand:@"team::get-by-globalID",
                  @"gids",       res,
                  @"attributes", [NSArray arrayWithObject:@"description"],
                  @"groupBy",    @"globalID",
                  nil];
      res = [res allValues];
      {
        NSArray *t;

        t = [self appendItems:res toArray:self->selectedTeams];
        t = [t sortedArrayUsingKeyOrderArray:descriptionSortOrderings];
        [self setTeams:t];
      }
    }
    // accounts
    res = self->selectedAccounts;
    cnt = (res) ? [res count] : 0;
    res = [self runCommand:@"account::extended-search",
                @"fetchGlobalIDs", yesNum,
                @"operator",       @"OR",
                @"name",           self->searchString,
                @"firstname",      self->searchString,
                @"description",    self->searchString,
                @"login",          self->searchString,
                @"maxSearchCount", [NSNumber numberWithInt:(max - cnt)],
                nil];
    if (res != nil) {
      res = [self runCommand:@"person::get-by-globalID",
                  @"gids",       res,
                  @"attributes", personInfoAttrNames,
                  @"groupBy",    @"globalID",
                  nil];
      res = [res allValues];
      {
        NSArray *ac;

        ac = [self appendItems:res toArray:self->selectedAccounts];
        ac = [ac sortedArrayUsingKeyOrderArray:nameFirstNameSortOrderings];
        [self setAccounts:ac];
      }
    }
    // persons
    res = self->selectedPersons;
    cnt = (res) ? [res count] : 0;
    res = [self runCommand:@"person::extended-search",
                @"fetchGlobalIDs",  yesNum,
                @"operator",        @"OR",
                @"name",            self->searchString,
                @"firstname",       self->searchString,
                @"description",     self->searchString,
                @"login",           self->searchString,
                @"withoutAccounts", yesNum,
                @"maxSearchCount",  [NSNumber numberWithInt:(max - cnt)],
                nil];
    if (res != nil) {
      res = [self runCommand:@"person::get-by-globalID",
                  @"gids",       res,
                  @"attributes", personInfoAttrNames,
                  @"groupBy",    @"globalID",
                  nil];
      res = [res allValues];
      {
        NSArray *p;

        p = [self appendItems:res toArray:self->selectedPersons];
        p = [p sortedArrayUsingKeyOrderArray:nameFirstNameSortOrderings];
        [self setPersons:p];
      }
    }
    // resources
    {
      NSArray *r = nil;

      res = self->selectedResources;
      cnt = (res) ? [res count] : 0;
      res = [self runCommand:@"appointmentresource::extended-search",
                  @"fetchGlobalIDs",  yesNum,
                  @"operator",        @"OR",
                  @"category",        self->searchString,
                  @"maxSearchCount",  [NSNumber numberWithInt:(max - cnt)],
                  nil];
      if (res != nil) {
        res = [self runCommand:@"appointmentresource::get-by-globalID",
                    @"gids",         res,
                    @"attributes",   [NSArray arrayWithObject:@"category"],
                    nil];
        r = [self distinctCategories:res];
        r = [self appendItems:r toArray:self->resources];
	r = [r sortedArrayUsingKeyOrderArray:nameSortOrderings];
	if (r != nil) [self setResources:r];
      }

      res = [self runCommand:@"appointmentresource::extended-search",
                  @"fetchGlobalIDs",  yesNum,
                  @"operator",        @"OR",
                  @"name",            self->searchString,
                  @"maxSearchCount",  [NSNumber numberWithInt:(max - cnt)],
                  nil];
      if (res != nil) {
        res = [self runCommand:@"appointmentresource::get-by-globalID",
                    @"gids",         res,
                    @"attributes",   [NSArray arrayWithObject:@"name"],
                    nil];

        if (res != nil)
          r = [res sortedArrayUsingKeyOrderArray:nameSortOrderings];
	
        r = [self appendItems:res toArray:self->resources];
      }
      if (r != nil)
        [self setResources:r];
    }
  }
  [self setSearchString:@""];
}

- (BOOL)isTimeZoneLicensed {
  return YES;
}

- (id)reallyShow {
  self->reconfigure = YES;
  return [self show];
}

- (id)show {
  [self computeSearchString];

  if ([self needToReconfigure])
    [self reconfigure];
  // internal action --> no additional configuration
  self->alreadyReconfigured = YES;
  return nil;
}

- (id)extend {
  EOKeyGlobalID *gid;
  id me;

  me = [(id)[self session] activeAccount];
  gid = [me valueForKey:@"globalID"];

  me = [[self runCommand:@"person::get-by-globalID",
              @"gids",       [NSArray arrayWithObject:gid],
              @"attributes",
              [NSArray arrayWithObjects:@"companyId", @"name", @"firstname",
                       @"isAccount", @"login", @"globalID", nil],
              nil] lastObject];

  self->isExtended = (self->isExtended) ? NO : YES;

  if (self->isExtended) {
    [self _initializePreSelectedItems];
    [self reconfigure];
    return nil;
  }
  else {
    [self setSearchString:@""];
    [self setAccounts:nil];
    [self setSelectedAccounts:nil];
    [self setPersons:nil];
    [self setSelectedPersons:nil];
    [self setTeams:nil];
    [self setSelectedTeams:nil];
    [self setResources:nil];
    [self setSelectedResources:nil];
    [self setSearchString:@""];
  }
  return [self show];
}

- (void)_updateCaches {
  [self->selAcCache release];
  self->selAcCache  = [self->selectedAccounts copy];
  [self->selPerCache release];
  self->selPerCache = [self->selectedPersons copy];
  [self->selTmCache release];
  self->selTmCache  = [self->selectedTeams copy];
  [self->selResCache release];
  self->selResCache = [self->selectedResources copy];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self _updateCaches];
  
  if (!self->alreadyReconfigured) 
    [self reconfigure];
  self->alreadyReconfigured = NO;
  
  [super appendToResponse:_response inContext:_ctx];
}

@end /* SkySchedulerSelectPanel */
