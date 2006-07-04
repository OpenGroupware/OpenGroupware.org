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

#include "SkyAppointmentFormatter.h"
#include <OGoScheduler/SkyHolidayCalculator.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoScheduler/SkySchedulerConflictDataSource.h>

#include "SkyInlineAptDataSourceView.h"
#include "common.h"
#include <OGoFoundation/OGoFoundation.h>
#include <NGMime/NGMimeType.h>
#include <LSFoundation/LSFoundation.h>
#include <GDLAccess/GDLAccess.h>
#include <NGExtensions/EOCacheDataSource.h>

@interface NSObject(UntimedPalmDate)
- (BOOL)isUntimed;
@end /* NSObject(UntimedPalmDate) */

@implementation SkyInlineAptDataSourceView

static NSArray      *configured      = nil;
static NSDictionary *aptTypeMap      = nil;
static NSArray      *corePersonAttrs = nil;
static NSArray      *coreTeamAttrs   = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  NSArray *tmpAptTypes;
  NSArray *custom;
  NSArray *special; // for palm / private / jobs etc.
  
  if (didInit) return;
  didInit = YES;
  
  corePersonAttrs = [[NSArray alloc] initWithObjects:
				       @"login", @"name", @"firstname", nil];
  coreTeamAttrs   = [[NSArray alloc] initWithObjects:
				       @"description", @"globalID", nil];

  /* configuredAptTypes */
  
  tmpAptTypes = [ud arrayForKey:@"SkyScheduler_defaultAppointmentTypes"];
  if (tmpAptTypes == nil) tmpAptTypes = [NSArray array];
  
  if ((custom = [ud arrayForKey:@"SkyScheduler_customAppointmentTypes"]))
    tmpAptTypes = [tmpAptTypes arrayByAddingObjectsFromArray:custom];
  if ((special = [ud arrayForKey:@"SkyScheduler_specialAppointmentTypes"]))
    tmpAptTypes = [tmpAptTypes arrayByAddingObjectsFromArray:special];

  configured = [tmpAptTypes copy];
  
  /* mappedAptTypes */
  {
    NSEnumerator        *e;
    NSMutableDictionary *md;
    id                  one;
    
    e  = [configured objectEnumerator];
    md = [NSMutableDictionary dictionaryWithCapacity:[configured count]];
    while ((one = [e nextObject]))
      [md setObject:one forKey:[one valueForKey:@"type"]];
    aptTypeMap = [md copy];
  }
}

- (NSUserDefaults *)userDefaults {
  OGoSession *sn;

  // TODO: accessing a session in -init is not recommended
  sn = (OGoSession *)[self session];
  return [sn userDefaults];
}

- (id)init {
  if ((self = [super init])) {
    // TODO: accessing a session in -init is not recommended
    self->hidePropAndNew = 
      [[self userDefaults] boolForKey:
			     @"scheduler_hide_new_proposal_on_rescat"];
    self->yearDirectActionName  = @"viewYear";
    self->weekDirectActionName  = @"viewWeek";
    self->monthDirectActionName = @"viewMonth";
    self->dayDirectActionName   = @"viewDay";
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->cacheDS);
  RELEASE(self->holidays);
  RELEASE(self->appointment);
  RELEASE(self->currentDate);
  RELEASE(self->sortOrderings);

  RELEASE(self->dayDirectActionName);
  RELEASE(self->weekDirectActionName);
  RELEASE(self->monthDirectActionName);
  RELEASE(self->yearDirectActionName);

  RELEASE(self->browserDate);
  RELEASE(self->aptTypes);
  RELEASE(self->allDayApts);
  [super dealloc];
}

/* notifications */

- (void)sleep {
  RELEASE(self->currentDate); self->currentDate = nil;
  RELEASE(self->appointment); self->appointment = nil;
  RELEASE(self->aptTypes);    self->aptTypes    = nil;
  RELEASE(self->allDayApts);  self->allDayApts  = nil;
  [super sleep];
}

- (void)syncAwake {
  NSUserDefaults *ud;
  
  [super syncAwake];
  
  ud = [self userDefaults];
  self->showFullNames = [ud boolForKey:@"scheduler_overview_full_names"];
  self->showAMPMDates = [ud boolForKey:@"scheduler_AMPM_dates"];
}

/* accessors */

- (void)setDataSource:(id)_ds {
  ASSIGN(self->dataSource,_ds);
}
- (id)dataSource {
  return self->dataSource;
}

- (id)cacheDataSource {
  if (self->cacheDS == nil) {
    self->cacheDS = [[EOCacheDataSource alloc] initWithDataSource:
                                               [self dataSource]];
  }
  return self->cacheDS;
}

- (BOOL)isResCategorySelected {
  return (self->hidePropAndNew
          && [self->dataSource isResCategorySelected]
          && [[self->dataSource companies] count] == 0);
}

- (void)setHolidays:(id)_days {
  ASSIGN(self->holidays,_days);
}
- (id)holidays {
  SkyHolidayCalculator *c;
  NSCalendarDate       *d;
  
  if (self->holidays)
    return self->holidays;
  if ((d = [self currentDate]) == nil)
    return nil;

  c = [SkyHolidayCalculator calculatorWithYear:[d yearOfCommonEra]
			    timeZone:[d timeZone]
			    userDefaults:[self userDefaults]];
  ASSIGN(self->holidays,c);
  return self->holidays;
}

- (void)setPrintMode:(BOOL)_flag {
  self->printMode = _flag;
}
- (BOOL)printMode {
  return self->printMode;
}

- (void)setAppointment:(id)_apt {
  ASSIGN(self->appointment,_apt);
}
- (id)appointment {
  return self->appointment;
}

- (void)setIndex:(int)_index {
  self->index = _index;
}
- (int)index {
  return self->index;
}

- (void)setCurrentDate:(NSCalendarDate *)_date {
  ASSIGN(self->currentDate,_date);
}
- (NSCalendarDate *)currentDate {
  return self->currentDate;
}

- (NSArray *)sortOrderings {
  if (self->sortOrderings == nil) {
    NSArray *so =
      [NSArray arrayWithObject:
               [EOSortOrdering sortOrderingWithKey:@"startDate"
                               selector:EOCompareAscending]];
    ASSIGN(self->sortOrderings,so);
  }
  return self->sortOrderings;
}

- (BOOL)showFullNames {
  return self->showFullNames;
}
- (BOOL)showAMPMDates {
  return self->showAMPMDates;
}

// direct action support

- (void)setYearDirectActionName:(NSString *)_da {
  ASSIGN(self->yearDirectActionName,_da);
}
- (NSString *)yearDirectActionName {
  return self->yearDirectActionName;
}
- (void)setMonthDirectActionName:(NSString *)_da {
  ASSIGN(self->monthDirectActionName,_da);
}
- (NSString *)monthDirectActionName {
  return self->monthDirectActionName;
}
- (void)setWeekDirectActionName:(NSString *)_da {
  ASSIGN(self->weekDirectActionName,_da);
}
- (NSString *)weekDirectActionName {
  return self->weekDirectActionName;
}
- (void)setDayDirectActionName:(NSString *)_da {
  ASSIGN(self->dayDirectActionName,_da);
}
- (NSString *)dayDirectActionName {
  return self->dayDirectActionName;
}

- (BOOL)isYearDirectActionDisabled {
  return (self->yearDirectActionName == nil)
    ? YES : NO;
}
- (BOOL)isMonthDirectActionDisabled {
  return (self->monthDirectActionName == nil)
    ? YES : NO;
}
- (BOOL)isWeekDirectActionDisabled {
  return (self->weekDirectActionName == nil)
    ? YES : NO;
}
- (BOOL)isDayDirectActionDisabled {
  return (self->dayDirectActionName == nil)
    ? YES : NO;
}

/* additional accessors */

- (BOOL)appointmentViewAccessAllowed {
  NSString *perms;
  
  if ((perms = [self->appointment valueForKey:@"permissions"]) != nil)
    return [perms rangeOfString:@"v"].length > 0 ? YES : NO;
  
  return [[self->appointment valueForKey:@"isViewAllowed"] boolValue];
}
- (BOOL)isAppointmentDraggable {
  NSString *perms;
  
  if ((perms = [self->appointment valueForKey:@"permissions"]) == nil)
    return NO;
  if ([perms rangeOfString:@"e"].length == 0)
    return NO;
  
  return YES;
}
- (BOOL)isPrivateAppointment {
  return ((![self appointmentViewAccessAllowed]) &&
          ([self->appointment valueForKey:@"accessTeamId"] == nil));
}

- (NSFormatter *)aptTimeFormatter {
  SkyAppointmentFormatter *format;
  
  format = [SkyAppointmentFormatter formatterWithFormat:@"%S - %E"];
  [format setRelationDate:self->currentDate];
  if ([self showAMPMDates]) [format switchToAMPMTimes:YES];
  return format;
}

- (NSFormatter *)aptTitleFormatter {
  return [SkyAppointmentFormatter formatterWithFormat:@"%T"];
}

- (NSFormatter *)aptParticipantFormatter {
  SkyAppointmentFormatter *format;
  format = [SkyAppointmentFormatter formatterWithFormat:@"%P"];
  [format setShowFullNames:self->showFullNames];
  return format;
}

- (NSFormatter *)aptFullInfoFormatter {
  SkyAppointmentFormatter *f;
  NSMutableString         *format;
  id                      res, loc;

  format = [NSMutableString stringWithCapacity:128];

  res = [self->appointment valueForKey:@"resourceNames"];
  loc = [self->appointment valueForKey:@"location"];
  
  [format appendString:[NSString stringWithFormat:@"%%S - %%E; %%T"]];

  if (loc != nil && [loc length] > 0 && ![loc isEqualToString:@" "])
    [format appendString:[NSString stringWithFormat:@"; %%L"]];

  [format appendString:[NSString stringWithFormat:@"; %%P"]];

  if (res != nil && [res length] > 0 && ![res isEqualToString:@" "])
    [format appendString:[NSString stringWithFormat:@"; %%R"]];
            
  f = [SkyAppointmentFormatter formatterWithFormat:format];
  [f setRelationDate:self->currentDate];
  [f setShowFullNames:self->showFullNames];
  if ([self showAMPMDates]) [f switchToAMPMTimes:YES];

  return f;
}

- (NSString *)fullInfoForApt {
  return [[self aptFullInfoFormatter] stringForObjectValue:self->appointment];
}
- (NSCalendarDate *)referenceDateForFormatter {
  NSLog(@"%s not overwritten!!!", __PRETTY_FUNCTION__);
  return nil;
}
- (NSString *)shortTextForApt {
  SkyAppointmentFormatter *f;
  
  f = [SkyAppointmentFormatter formatterWithFormat:
                               @"%S - %E;\n%T;\n%L;\n%5P;\n%50R"];
  [f setRelationDate:[self referenceDateForFormatter]];
  [f setShowFullNames:self->showFullNames];
  if ([self showAMPMDates]) [f switchToAMPMTimes:YES];

  return [NSString stringWithFormat:@"%@:\n%@",
                   [self aptTypeLabel],
                   [f stringForObjectValue:self->appointment]];
}

- (NSFormatter *)aptContentFormatter {
  return [SkyAppointmentFormatter contentFormatterWithAppointment:
				    self->appointment
				  showFullNames:[self showFullNames]];
}

- (void)_splitResultGIDs:(NSArray *)gids
  intoPersonGIDs:(NSMutableArray *)personGids
  andTeamGIDs:(NSMutableArray *)teamGids
{
  NSEnumerator  *compEnum;
  EOKeyGlobalID *company;
  
  compEnum   = [gids objectEnumerator];
  while ((company = [compEnum nextObject])) {
    NSString *e;
    
    e = [company entityName];
    if ([e isEqualToString:@"Person"]) {
      [personGids addObject:company];
      continue; // Note: this was 'break' before, which I think is wrong
    }
    if ([e isEqualToString:@"Team"]) {
      [teamGids addObject:company];
      continue; // Note: this was 'break' before, which I think is wrong
    }
    
    [self debugWithFormat:
	    @"Note: unknown entity '%@' in company global-id: %@",
	    e, company];
  }
}

- (NSString *)companyName {
  // TODO: split up
  NSString     *all = nil;
  NSString     *d;
  NSArray      *comps;
  NSMutableArray *personGids;
  NSMutableArray *teamGids;
  
  personGids = [NSMutableArray arrayWithCapacity:4];
  teamGids   = [NSMutableArray arrayWithCapacity:4];
  [self _splitResultGIDs:[[self dataSource] companies]
	intoPersonGIDs:personGids andTeamGIDs:teamGids];
  
  /* fetching persons and appending to name */
  if ([personGids isNotEmpty]) {
    NSEnumerator *compEnum;
    id company;

    comps = [self runCommand:@"person::get-by-globalid",
		  @"gids", personGids, @"attributes", corePersonAttrs, nil];
    
    compEnum = [comps objectEnumerator];
    while ((company = [compEnum nextObject])) {
      all = [all isNotNull]
	? [all stringByAppendingString:@"; "]
        : (NSString *)@"";
	    
      if ((d = [company valueForKey:@"name"]) == nil)
        d = [company valueForKey:@"login"];
      else {
        NSString *fd;
	
        if ((fd = [company valueForKey:@"firstname"]) != nil)
          d = [NSString stringWithFormat:@"%@, %@", d, fd];
      }
      all = [all stringByAppendingString:d];
    }
  }
  if ([teamGids isNotEmpty]) {
    NSEnumerator *compEnum;
    id company;
    
    comps = [self runCommand:@"team::get-by-globalid",
		    @"gids", teamGids, @"attributes", coreTeamAttrs, nil];
    
    compEnum = [comps objectEnumerator];
    while ((company = [compEnum nextObject])) {
      // TODO: is this correct? instead of empty string return all?
      all = [all isNotNull] 
	? [all stringByAppendingString:@"; "] : (NSString *)@"";
      
      all = [all stringByAppendingString:
                 [company valueForKey:@"description"]];
    }
  }
  
  return all;
}

- (NSArray *)currentHolidays {
  return [(SkyHolidayCalculator *)self->holidays
                                  holidaysOfDate:[self currentDate]];
}

- (NSString *)holidayInfo {
  NSArray         *infos;
  NSMutableString *info;

  infos = [self currentHolidays];
  if (![infos count]) return @"";
  
  info  = [NSMutableString stringWithCapacity:20];  
  {
    // append holidays
    unsigned cnt;
    NSString *label;
    
    for (cnt = 0; cnt < [infos count]; cnt++) {
      if ([info isNotEmpty])
        [info appendString:@", "];
      label = [[self labels] valueForKey:[infos objectAtIndex:cnt]];
      label = (label == nil)
        ? (NSString *)[infos objectAtIndex:cnt]
        : label;
      [info appendString:label];
    }
  }
  
  return info;
}
- (NSString *)currentDayInfo {
  return [self holidayInfo];
}

- (void)setAllDayApts:(NSArray *)_allDayApts {
  ASSIGN(self->allDayApts,_allDayApts);
}
- (NSArray *)allDayApts {
  return self->allDayApts;
}

- (BOOL)hasHolidays {
  return ([[self currentHolidays] count]) ? YES : NO;
}
- (BOOL)hasAllDayApts {
  return ([[self allDayApts] count]) ? YES : NO;
}
- (BOOL)hasCurrentDayInfo {
  if ([self hasHolidays]) return YES;
  if ([self hasAllDayApts]) return YES;
  return NO;
}

- (BOOL)isThisAllDayApt:(id)_apt {
  Class          palmClass = NULL;
  NSCalendarDate *start;
  NSCalendarDate *end;

  if (palmClass == NULL) {
    palmClass = NSClassFromString(@"SkyPalmDateDocument");
  }
  if ([_apt isKindOfClass:palmClass] && [_apt isUntimed])
    return YES;

  start = [_apt valueForKey:@"startDate"];
  end   = [_apt valueForKey:@"endDate"];
  if (([start hourOfDay] == 0) &&
      ([start minuteOfHour] == 0) &&
      ([start secondOfMinute] == 0) &&
      ((([end hourOfDay] == 0) &&
        ([end minuteOfHour] == 0) &&
        ([end secondOfMinute] == 0)) ||
       (([end hourOfDay] == 23) &&
        ([end minuteOfHour] == 59)
        //&& ([end secondOfMinute] == 59)
        )))
    {
      return YES;
    }
  return NO;
}
- (BOOL)isAllDayApt {
  return [self isThisAllDayApt:self->appointment];
}

// dnd support

- (NSCalendarDate *)droppedAptDateWithOldDate:(NSCalendarDate *)_date {
  NSCalendarDate *toDate = [self currentDate];
  return [NSCalendarDate dateWithYear:[toDate yearOfCommonEra]
                         month:[toDate monthOfYear]
                         day:[toDate dayOfMonth]
                         hour:[toDate hourOfDay]
                         minute:[toDate minuteOfHour]
                         second:[toDate secondOfMinute]
                         timeZone:[_date timeZone]];
}

/* month browser support */

- (void)setBrowserDate:(NSCalendarDate *)_date {
  ASSIGN(self->browserDate, _date);
}
- (NSCalendarDate *)browserDate {
  return self->browserDate;
}

- (void)setBrowserDateInMonth:(BOOL)_flag {
  self->browserDateInMonth = _flag;
}
- (BOOL)browserDateInMonth {
  return self->browserDateInMonth;
}

- (NSString *)browserDayLabel {
  return [NSString stringWithFormat:@"%i", [self->browserDate dayOfMonth]];
}

- (NSString *)browserFontColor {
  // TODO: use CSS
  if (!self->browserDateInMonth)
    return @"#555555";
  return @"#000000";
}

/* date cell support */

- (NSArray *)configuredAptTypes {
  // TODO: is this method still used?
  return configured;
}
// the default apt types plus custom apt types as user defined
- (NSArray *)aptTypes {
  if (self->aptTypes)
    return self->aptTypes;
  
  self->aptTypes = [configured retain];
  return self->aptTypes;
}

- (NSDictionary *)mappedAptTypes {
  /* the apt types mapped by type */
  // TODO: is this method still used?
  return aptTypeMap;
}
- (NSString *)_noneAptType {
  /* the type 'none' which is default type if nothing else is set */
  return @"none";
}
- (NSString *)aptTypeKey {
  /* getting type of apt, if private: '_private_' */
  NSString *key;
  
  if ((key = [self->appointment valueForKey:@"aptType"]) != nil) return key;
  if ([self isPrivateAppointment]) return @"_private_";
  return [self _noneAptType];
}
- (NSDictionary *)aptTypeDict {
  /* getting the config of apt type */
  NSString     *key;
  id           one;  
  static NSDictionary *defaultAppType = nil;
  
  if (defaultAppType == nil)
    defaultAppType = [aptTypeMap valueForKey:[self _noneAptType]];
  
  key = [self aptTypeKey];
  one = [key isNotNull] ? [aptTypeMap valueForKey:key] : nil;
  return (one != nil) ? (NSDictionary *)one : defaultAppType;
}

- (NSString *)aptTypeLabel {
  /* the label from the type-config or for default types from labels */
  NSDictionary *dict;
  NSString     *label;
  
  dict  = [self aptTypeDict];
  label = [dict valueForKey:@"label"];
  if (label != nil) return label;
  
  label = [[dict valueForKey:@"type"] stringValue];
  label = [@"aptType_" stringByAppendingString:label];
  return [[self labels] valueForKey:label];
}

- (NSString *)dateCellIcon {
  /* the icon from type-config */
  return [[self aptTypeDict] valueForKey:@"icon"];
}

- (NSString *)aptTitleCellClass {
  return ([[self appointment] valueForKey:@"accessTeamId"] != nil)
    ? @"skydatecell_title" : @"skydatecell_titlePrivate";
}

- (BOOL)useDirectActionForView {
  // TODO: in which case do we miss a global-id?
  /* action */
  if ([[self->appointment valueForKey:@"dateId"] isNotNull])
    return YES;
  if ([[self->appointment valueForKey:@"globalID"] isNotNull])
    return YES;
  return NO;
}
- (id)appointmentOID {
  EOKeyGlobalID *gid;
  id oid;
  
  oid = [self->appointment valueForKey:@"dateId"];
  if ([oid isNotNull])
    return oid;
  
  gid = [self->appointment valueForKey:@"globalID"];
  if ([gid isNotNull])
    return [[gid keyValuesArray] componentsJoinedByString:@"-"];
  
  return nil;
}
- (id)appointmentEntity {
  static SEL gidSel = NULL;
  static SEL entSel = NULL;
  EOGlobalID *gid;
  
  if (gidSel == NULL) gidSel = @selector(globalID);
  if (entSel == NULL) entSel = @selector(entityName);

  gid = [self->appointment valueForKey:@"globalID"];
  
  if (gid == nil) {
    if ([self->appointment respondsToSelector:gidSel])
      gid = [self->appointment globalID];
  }
  if (gid != nil) return [gid entityName];
  
  if ([self->appointment respondsToSelector:entSel])
    return [self->appointment entityName];
  return nil;
}

- (id)viewAppointment {
  WOComponent *c;
  
  /*
   * doesn't work with TableMatrix, which doesn't support
   * invokeActionForRequest
   */

  if (self->appointment == nil)
    /* no appointment is set */
    return nil;
  
  c = [[(id)[self session] navigation]
                  activateObject:[self appointment]
                  withVerb:@"view"];

  if (c == nil) {
    c = [[(id)[self session] navigation]
                    activateObject:[[self appointment] valueForKey:@"globalID"]
                    withVerb:@"view"];

    /* pass timezone in context */
    [[self context]
           takeValue:[[self dataSource] timeZone]
           forKey:@"SkySchedulerTimeZone"];
  }
  return c;
}

- (id)personWasDropped:(id)_person {
  /* if person is dropped, make new apt with person as participant */
  NSDictionary *d;
  NSCalendarDate *toDate;
  
  toDate = [self currentDate];
  
  d = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSArray arrayWithObjects:&_person count:1],
                      @"participants",
                      toDate, @"startDate",
                      nil];
  
  [[self session] transferObject:d owner:self];
  
  return [[self session] instantiateComponentForCommand:@"new"
                         type:[NGMimeType mimeType:@"eo/date"]];
}

- (id)droppedAppointment {
  // TODO: split up this huge method
  NSCalendarDate *toDate, *oldStart;
  id apt, obj;
  
  obj = [self appointment];
  
  if ([obj isKindOfClass:[EOGenericRecord class]]) {
    NSString *entityName = [[obj entity] name];

    if ([entityName isEqualToString:@"Person"])
      return [self personWasDropped:obj];
  }
  
  apt       = obj;
  
  toDate   = [self currentDate];
  oldStart = [apt valueForKey:@"startDate"];
  
#if 0
  NSLog(@"dropped apt\n  '%@'\n  %@\n  weekday: %@",
        [apt valueForKey:@"title"],
        oldStart,
        toDate);
#endif

  if (toDate == nil)
    return nil;
  
  if (apt != nil) {
    NSTimeInterval duration;
    NSCalendarDate *newStart, *newEnd;
    
    duration = [[apt valueForKey:@"endDate"] timeIntervalSinceDate:oldStart];

    newStart = [self droppedAptDateWithOldDate:oldStart];
    newEnd   = [[NSCalendarDate alloc]
                                initWithTimeInterval:duration
                                sinceDate:newStart];
    [newEnd setTimeZone:[newStart timeZone]];

    AUTORELEASE(newEnd);
    

#if 0
    NSLog(@"new from %@ to %@", newStart, newEnd);
#endif
    
    /* get full EO object */
    apt = [self runCommand:@"appointment::get-by-globalid",
                  @"gid",      [apt valueForKey:@"globalID"],
                  @"timeZone", [[self dataSource] timeZone],
                  nil];
    if ((apt != nil) && ([apt valueForKey:@"participants"] == nil)) {
      [self runCommand:@"appointment::get-participants",
              @"appointment", apt, nil];
    }
    if ((apt != nil) && ([apt valueForKey:@"comment"] == nil)) {
      NSString *c;
      c = [[apt valueForKey:@"toDateInfo"] valueForKey:@"comment"];
      if (c) [apt takeValue:c forKey:@"comment"];
    }
    if ((apt != nil) && ([apt valueForKey:@"owner"] == nil)) {
      id            c;
      EOKeyGlobalID *gid;

      c = [apt valueForKey:@"ownerId"];

      if ([c isNotNull]) {
        gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                             keys:&c keyCount:1 zone:NULL];

        c = [self runCommand:@"person::get-by-globalid",
                  @"gid", gid, nil];
	
        if ([c isKindOfClass:[NSArray class]])
          c = [c isNotEmpty] ? [c lastObject] : nil;
      
        if (c != nil)
          [apt takeValue:c forKey:@"owner"];
      }
    }
    
    /* perform move */
    
    if (![apt isNotNull]) {
      [self errorWithFormat:@"Could not fetch appointment."];
    }
    else {
      static NSString *errStringKey = @"errorString";
      [apt takeValue:newStart forKey:@"startDate"];
      [apt takeValue:newEnd   forKey:@"endDate"];

      /* checking conflicts */
      {
        SkySchedulerConflictDataSource *ds;

        ds = [SkySchedulerConflictDataSource alloc];
        ds = [ds initWithContext:[(id)[self session] commandContext]];
        [ds setAppointment:apt];
        
        // TODO: wrap in a cache datasource instead of relying on SCDS!
        if ([[ds fetchObjects] count] > 0) {
          WOComponent *page;
          
          page = [self pageWithName:@"SkySchedulerConflictPage"];
          [page takeValue:ds forKey:@"dataSource"];
          [ds release]; ds = nil;
          return page;
        }
        [ds release]; ds= nil;
      }

      NS_DURING {
        [self runCommand:@"appointment::set",
                @"object",       apt,
                @"participants", [apt valueForKey:@"participants"],
                nil];
      }
      NS_HANDLER {
        // move failed
        [[[self context] page]
                takeValue:[localException description]
                forKey:errStringKey];
        [[(OGoSession *)[self session] commandContext] rollback];
      }
      NS_ENDHANDLER;
    }
    
    //    [[self dataSource] clear];
    [[self cacheDataSource] clear];
  }
  return nil;
}

/* k/v coding */

- (void)takeValue:(id)_val forKey:(NSString *)_key {
  if ([_key isEqualToString:@"dataSource"]) 
    [self setDataSource:_val];
  else if ([_key isEqualToString:@"printMode"])
    self->printMode = [_val boolValue];
  else if ([_key isEqualToString:@"holidays"])
    [self setHolidays:_val];
  else
    [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"dataSource"]) 
    return [self dataSource];
  if ([_key isEqualToString:@"holidays"]) 
    return [self holidays];
  if ([_key isEqualToString:@"printMode"])
    return [NSNumber numberWithBool:self->printMode];

  return [super valueForKey:_key];
}

@end /* SkyInlineAptDataSourceView */
