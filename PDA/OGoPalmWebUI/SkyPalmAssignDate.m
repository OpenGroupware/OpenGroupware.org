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

#include <OGoPalmUI/SkyPalmAssignEntry.h>

@interface SkyPalmAssignDate : SkyPalmAssignEntry
{
  NSArray  *apts;
  // search dates between fromDate and toDate
  NSString *fromDate;
  NSString *toDate;
  // show date from now for <days> days;
  int      days;

  BOOL     searchApts;  // search dates between fromDate and toDate
  BOOL     onlyMyAppointments;
}

@end /* SkyPalmAssignDate */

#include "common.h"

#include <OGoScheduler/SkyAppointmentDataSource.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoPalm/SkyPalmDateDataSource.h>
#include <OGoPalm/SkyPalmDateDocument.h>

#include <NGExtensions/NSCalendarDate+misc.h>
#include <NGExtensions/EODataSource+NGExtensions.h>

@interface SkyPalmAssignDate(PrivatMethods)
- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc;
@end

@implementation SkyPalmAssignDate

- (id)init {
  if ((self = [super init])) {
    NSCalendarDate *date;
    
    self->days       = 14;  // appointments of next 14 days
    
    date  = [NSCalendarDate date];
    self->fromDate   = [[date descriptionWithCalendarFormat:@"%Y-%m-%d"] copy];
    date = [date dateByAddingYears:0 months:0 days:14];
    self->toDate     = [[date descriptionWithCalendarFormat:@"%Y-%m-%d"] copy];
    
    self->onlyMyAppointments = YES;
  }
  return self;
}

- (void)dealloc {
  [self->apts     release];
  [self->fromDate release];
  [self->toDate   release];
  [super dealloc];
}

/* accessors */

- (EOGlobalID *)allIntranetGID {
  NSArray *allIntra;

  allIntra = [self runCommand:@"team::get", @"login", @"all intranet", nil];
  if ([allIntra count] != 1) {
    NSLog(@"%s didn't find all intranet or more than one team with login (%d)"
          @"'all intranet'", __PRETTY_FUNCTION__, [allIntra count]);
    return nil;
  }
  return [[allIntra lastObject] valueForKey:@"globalID"];
}
- (NSArray *)_companiesToFetchFor {
  EOGlobalID *activeAccount;
  EOGlobalID *aIgid;
  
  activeAccount = [[[self session] activeAccount] valueForKey:@"globalID"];
  aIgid         = (self->onlyMyAppointments) ? nil :[self allIntranetGID];
  return [NSArray arrayWithObjects:activeAccount, aIgid, nil];
}

- (SkyAppointmentQualifier *)_qualifierFrom:(NSCalendarDate *)_from
  to:(NSCalendarDate *)_to
{
  SkyAppointmentQualifier *qual;
  
  qual = [[[SkyAppointmentQualifier alloc] init] autorelease];
  [qual setStartDate:_from];
  [qual setEndDate:_to];
  [qual setTimeZone:[[self session] timeZone]];
  [qual setCompanies:[self _companiesToFetchFor]];
  [qual setResources:[NSArray array]];
  return qual;
}
- (NSArray *)_attributesWanted {
  return [NSArray arrayWithObjects:
                  @"dateId", @"parentDateId", @"startDate",
                  @"endDate", @"cycleEndDate", @"type", @"aptType", 
                  @"title", @"globalID", @"permissions",
                  @"participants.login", @"comment",
                  @"location", @"accessTeamId", @"writeAccessList",
                  nil];
}
- (NSArray *)_sortOrderings {
  return [NSArray arrayWithObject:
                  [EOSortOrdering sortOrderingWithKey:@"startDate"
                                  selector:EOCompareAscending]];
}
- (NSDictionary *)_hints {
  return [NSDictionary dictionaryWithObjectsAndKeys:
                         [self _attributesWanted], @"attributes",
                       nil];
}
- (EOFetchSpecification *)_fetchSpecFrom:(NSCalendarDate *)_from
  to:(NSCalendarDate *)_to
{
  EOFetchSpecification *fspec =
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Date"
                          qualifier:[self _qualifierFrom:_from to:_to]
                          sortOrderings:[self _sortOrderings]];
  [fspec setHints:[self _hints]];
  return fspec;
}
- (LSCommandContext *)_commandContext {
  return [(id)[self session] commandContext];
}
- (SkyAppointmentDataSource *)_dataSourceFrom:(NSCalendarDate *)_from
                                   to:(NSCalendarDate *)_to
{
  SkyAppointmentDataSource *das;
  das = [(SkyAppointmentDataSource *)[SkyAppointmentDataSource alloc]
                                     initWithContext:[self _commandContext]];
  [das setFetchSpecification:[self _fetchSpecFrom:_from to:_to]];

  return AUTORELEASE(das);
}
- (NSArray *)_searchAptsFrom:(NSCalendarDate *)_from
                          to:(NSCalendarDate *)_to
{
  SkyAppointmentDataSource *das = [self _dataSourceFrom:_from to:_to];
  NSEnumerator             *e   = [[das fetchObjects] objectEnumerator];
  id                       one;
  NSMutableArray           *ma  = [NSMutableArray array];
  NSString                 *perms;

  while ((one = [e nextObject])) {
    perms = [one valueForKey:@"permissions"];
    if (([[one valueForKey:@"title"] length]) ||  // can see title --> allowed
        ((perms) && ([perms indexOfString:@"v"] != NSNotFound)) ||
        ([[one valueForKey:@"isViewAllowed"] boolValue]))
      [ma addObject:one];
  }
  one = [ma copy];
  return AUTORELEASE(one);
}

- (NSCalendarDate *)_stringToDate:(NSString *)_src {
  NSCalendarDate *date = [NSCalendarDate dateWithString:_src
                                         calendarFormat:@"%Y-%m-%d"];
  return (date == nil)
    ? [NSCalendarDate date]
    : date;
}
- (NSCalendarDate *)_fromDateAsDate {
  return [self _stringToDate:self->fromDate];
}
- (NSCalendarDate *)_toDateAsDate {
  return [self _stringToDate:self->toDate];
}

- (EOQualifier *)_qualifierForPalmDS {
  id actualId = [self->doc globalID];

  if (actualId != nil) {
    actualId = [[actualId keyValuesArray] objectAtIndex:0];
  }
  if ((actualId != nil) && ([actualId intValue] > 0)) {
    return [EOQualifier qualifierWithQualifierFormat:
                        @"(skyrix_id > 0) AND (is_deleted=0) AND "
                        @"(is_archived=0) "
                        @"AND NOT (palm_date_id=%@) "
                        @"AND (device_id=%@)", actualId, [self deviceId]];
  }
  return [EOQualifier qualifierWithQualifierFormat:
                      @"(skyrix_id > 0) AND (is_deleted=0) AND (is_archived=0)"
                      @" AND (device_id=%@)", [self deviceId]];
}
- (EOFetchSpecification *)_fetchSpecForPalmDS {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"palm_date"
                               qualifier:[self _qualifierForPalmDS]
                               sortOrderings:nil];
}
- (SkyPalmDateDataSource *)_palmDataSource {
  SkyPalmEntryDataSource *das;
  das = [SkyPalmEntryDataSource dataSourceWithContext:[self _commandContext]
                                forPalmDb:@"DatebookDB"];

  return (SkyPalmDateDataSource *)das;
}
- (NSArray *)_assignedDateIds {
  SkyPalmDateDataSource *das;
  NSEnumerator          *all;
  id                    one;
  NSMutableArray        *dateIds;
  
  das     = [self _palmDataSource];
  [das setFetchSpecification:[self _fetchSpecForPalmDS]];
  all = [[das fetchObjects] objectEnumerator];
  dateIds = [NSMutableArray arrayWithCapacity:64];
  
  while ((one = [all nextObject]) != nil)
    [dateIds addObject:[one skyrixId]];
  
  return dateIds;
}

- (NSArray *)_filterAptsWithoutBindings:(NSArray *)_src {
  NSArray        *assignedIds;
  NSEnumerator   *all;
  id             one;
  NSMutableArray *filtered;

  assignedIds = [self _assignedDateIds];
  all      = [_src objectEnumerator];
  filtered = [NSMutableArray arrayWithCapacity:64];
  
  while ((one = [all nextObject])) {
    NSNumber *dateId;
    
    dateId = [one hasParentDate]
      ? [one parentDateId]
      : [one valueForKey:@"dateId"];
    if (dateId == nil) {
      dateId =
        [[[one valueForKey:@"globalID"] keyValuesArray] objectAtIndex:0];
      if (dateId == nil) {
        NSLog(@"%s couldn't get dateId of record", __PRETTY_FUNCTION__,
              one);
        continue;
      }
    }
    if ([assignedIds containsObject:dateId])
      continue;
    
    [filtered addObject:one];
  }
  return filtered;
}

- (NSArray *)_filterRepetitionApts:(NSArray *)_src {
  NSMutableArray *filtered;
  NSMutableArray *repIds;
  NSEnumerator   *e;
  id             one;
  NSNumber       *parentDateId;

  e        = [_src objectEnumerator];
  filtered = [NSMutableArray array];
  repIds   = [NSMutableArray array];
  
  while ((one = [e nextObject])) {
    if ([one hasParentDate]) 
      parentDateId = [one parentDateId];    
    else
      parentDateId = [one valueForKey:@"dateId"];
    if (parentDateId == nil)
      parentDateId =
        [(EOKeyGlobalID *)[one valueForKey:@"globalID"] keyValues][0];
    
    if ([repIds containsObject:parentDateId]) continue;
    [repIds addObject:parentDateId];
    [filtered addObject:one];
  }
  return filtered;  
}

- (void)_searchApts {
  NSArray        *as   = nil;
  NSCalendarDate *from = nil;
  NSCalendarDate *to   = nil;

  from = [self _fromDateAsDate];
  to   = [self _toDateAsDate];

  as   = [self _searchAptsFrom:from to:to];
  as   = [self _filterAptsWithoutBindings:as];
  as   = [self _filterRepetitionApts:as];

  ASSIGN(self->apts,as);
}

- (void)_fetchAptsOfRange {
  NSArray        *as   = nil;
  NSCalendarDate *from = nil;
  NSCalendarDate *to   = nil;

  from = [[NSCalendarDate date] beginOfDay];
  to   = [from dateByAddingYears:0 months:0 days:self->days];

  as   = [self _searchAptsFrom:from to:to];
  as   = [self _filterAptsWithoutBindings:as];
  as   = [self _filterRepetitionApts:as];

  ASSIGN(self->apts,as);
}

- (void)_fetchApts {
  if (self->searchApts)
    [self _searchApts];
  else
    [self _fetchAptsOfRange];
}

- (NSArray *)apts {
  if (self->apts == nil)
    [self _fetchApts];
  return self->apts;
}

- (void)setDeviceId:(NSString *)_deviceId {
  if (![_deviceId isEqualToString:self->deviceId]) {
    [super setDeviceId:_deviceId];
    RELEASE(self->apts); self->apts = nil;
  }
}

- (NSString *)_searchAptsTitle {
  id l = [self labels];
  return [NSString stringWithFormat:@"%@ %@ %@ %@ %@",
                   [l valueForKey:@"label_skyrixAppointments"],
                   [l valueForKey:@"from"], self->fromDate,
                   [l valueForKey:@"to"],   self->toDate];
}
- (NSString *)_showAptsTitle {
  id l = [self labels];
  return [NSString stringWithFormat:@"%@ %@ %d %@",
                   [l valueForKey:@"label_skyrixAppointments"],
                   [l valueForKey:@"forTheNext"],
                   self->days, [l valueForKey:@"label_days"]];
}
- (NSString *)aptsTitle {
  if (self->searchApts)
    return [self _searchAptsTitle];
  return [self _showAptsTitle];
}

- (void)setOnlyMyAppointments:(BOOL)_flag {
  self->onlyMyAppointments = _flag;
}
- (BOOL)onlyMyAppointments {
  return self->onlyMyAppointments;
}

- (void)setDays:(int)_days {
  self->days = _days;
}
- (int)days {
  return self->days;
}

- (void)setFromDate:(NSString *)_date {
  ASSIGN(self->fromDate,_date);
}
- (NSString *)fromDate {
  return self->fromDate;
}

- (void)setToDate:(NSString *)_date {
  ASSIGN(self->toDate,_date);
}
- (NSString *)toDate {
  return self->toDate;
}

- (id)appointment {
  return [self skyrixRecord];
}

// conditionionals

- (BOOL)hasAppointment {
  return ([self appointment] != nil)
    ? YES : NO;
}
- (BOOL)hasAppointments {
  return ([[self skyrixRecords] count] > 0)
    ? YES : NO;
}

- (BOOL)searchAppointmentsCond {
  if ([self hasAppointment])
    return NO;
  if ([self hasAppointments])
    return NO;
  if ([self createNewRecord])
    return NO;
  return YES;
}

- (BOOL)showSearchResultCond {
  return [self searchAppointmentsCond];
}

- (BOOL)canSave {
  return (([self hasAppointment])  ||
          ([self hasAppointments]) ||
          ([self createNewRecord]))
    ? YES : NO;
}

- (BOOL)isSkyrixRecordEditable {
  NSString *perm;
  if (![self hasAppointment]) return NO;
  if ((perm = [[self appointment] permissions])) {
    if ([perm indexOfString:@"e"] != NSNotFound) // edit
      return YES;
  }
  return NO;
}

// calendar support
- (NSString *)calendarPageURL {
  WOResourceManager *rm;
  NSString *url;
  
  rm = [(id)[WOApplication application] resourceManager];
  
  url = [rm urlForResourceNamed:@"calendar.html"
            inFramework:nil
            languages:[[self session] languages]
            request:[[self context] request]];
  
  if (url == nil) {
    [self debugWithFormat:@"couldn't locate calendar page"];
    url = @"/Skyrix.woa/WebServerResources/English.lproj/calendar.html";
  }

  return url;
}
- (NSString *)_dateOnClickEvent:(NSString *)_date {
  return
    [NSString stringWithFormat:
              @"setDateField(document.editform.%@);"
              @"top.newWin=window.open('%@','cal','WIDTH=208,HEIGHT=230')",
              _date,
              [self calendarPageURL]];
}
- (NSString *)fromOnClickEvent {
  return [self _dateOnClickEvent:@"from"];
}
- (NSString *)toOnClickEvent {
  return [self _dateOnClickEvent:@"to"];
}

// appointment display

- (NSString *)_timeStrForApt:(id)_apt {
  NSCalendarDate *start = [_apt valueForKey:@"startDate"];
  NSCalendarDate *end   = [_apt valueForKey:@"endDate"];

  if ([start isDateOnSameDay:end])
    return [NSString stringWithFormat:@"%@ - %@",
                     [start descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"],
                     [end descriptionWithCalendarFormat:@"%H:%M"]];
  if ([start yearOfCommonEra] == [end yearOfCommonEra])
    return [NSString stringWithFormat:@"%@ - %@",
                     [start descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"],
                     [end descriptionWithCalendarFormat:@"%m-%d %H:%M"]];
  return [NSString stringWithFormat:@"%@ - %@",
                   [start descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"],
                   [end descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"]];
}

- (NSString *)aptTimeString {
  return [self _timeStrForApt:[self appointment]];
}
- (NSString *)itemTimeString {
  return [self _timeStrForApt:[self item]];
}
- (NSString *)palmDateTimeString {
  return [self _timeStrForApt:[self doc]];
}

// repeat type checking
// waiting for needed code of SkyAppointmentDocument

// actions
- (id)changeAppointment {
  [self setSkyrixRecord:nil];
  [self->skyrixRecords removeAllObjects];
  return nil;
}

- (id)selectAppointment {
  [self setSkyrixRecord:self->item];
  return nil;
}
- (id)selectAppointments {
  return nil;
}

- (id)searchAppointments {
  self->searchApts = YES;
  RELEASE(self->apts); self->apts = nil;
  return [self changeAppointment];
}
- (id)showAppointments {
  self->searchApts = NO;
  RELEASE(self->apts); self->apts = nil;
  return [self changeAppointment];
}

// overwriting

- (id)_checkSkyrixRecord:(SkyAppointmentDocument *)_rec {
  if ([_rec hasParentDate])
    return [_rec parentDate];
  return _rec;
}
- (NSMutableArray *)_checkSkyrixRecords:(NSArray *)_recs {
  NSMutableArray *checked = [NSMutableArray array];
  NSEnumerator   *e       = [_recs objectEnumerator];
  id             one      = nil;

  while ((one = [e nextObject])) {
    one = [self _checkSkyrixRecord:one];
    if (![checked containsObject:one])
      [checked addObject:one];
  }
  return checked;
}

- (id)save {

  if ([self isSingleSelection]) {
    if ([self createFromRecord]) {
      NSCalendarDate *date = [NSCalendarDate date];
      [date setTimeZone:[[self session] timeZone]];
      [(SkyPalmDateDocument *)self->doc setStartdate:date];
      [self setSkyrixRecord:[self _checkSkyrixRecord:[self skyrixRecord]]];
    }

    else if ([self createNewRecord]) {
      [self setSkyrixRecord:[self newSkyrixRecordForPalmDoc:[self doc]]];
    }
  }  
  else {
    // multiple selection
    if (![self createNewRecord]) {
      [self setSkyrixRecords:[self _checkSkyrixRecords:[self skyrixRecords]]];
    }
  }
  return [super save];
}

- (id)fetchSkyrixRecord {
  return [[self doc] skyrixRecord];
}
- (NSString *)primarySkyKey {
  return @"dateId";
}
- (SkyPalmDateDocument *)newPalmDoc {
  NSCalendarDate      *date   = [NSCalendarDate date];
  SkyPalmDateDocument *newDoc =
    (SkyPalmDateDocument *)[[self dataSource] newDocument];

  [date setTimeZone:[[self session] timeZone]];
  [newDoc setStartdate:date];
  return newDoc;
}

- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc {
  id                       ctx  = nil;
  SkyAppointmentDataSource *das = nil;
  id                       rec  = nil;
  NSArray        *writeAccess;
  id             readAccess;
  id tmp;
  NSUserDefaults *ud;

  ctx = [(id)[self session] commandContext];
  das = [(SkyAppointmentDataSource *)[SkyAppointmentDataSource alloc]
                                     initWithContext:ctx];

  /* loading access defaults */
  ud  = [ctx userDefaults];
  writeAccess =
    [ud arrayForKey:@"ogopalm_default_scheduler_write_access_accounts"];
  tmp = 
    [ud arrayForKey:@"ogopalm_default_scheduler_write_access_teams"];

  if (tmp == nil) {
    if (writeAccess == nil) writeAccess = [NSArray array];
  }
  else {
    if (writeAccess == nil) writeAccess = tmp;
    else writeAccess = [writeAccess arrayByAddingObjectsFromArray:tmp];
  }
  readAccess = [ud stringForKey:@"ogopalm_default_scheduler_read_access_team"];
  readAccess = [readAccess length]
    ? [NSNumber numberWithInt:[readAccess intValue]]
    : nil;    
    
  
  rec = [das createObject];
  [rec setWriteAccess:writeAccess];
  [rec setAccessTeamId:readAccess];
  [_doc putValuesToSkyrixRecord:rec];
  [(SkyAppointmentDocument *)rec save];

  RELEASE(das);
  return rec;
}

@end /* SkyPalmAssignDate */
