/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2006-2007 Helge Hess

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

#include "LSWAppointmentEditor.h"
#include "LSWAppointmentEditor+Fetches.h"
#include "OGoAppointmentDateFormatter.h"

#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <LSFoundation/LSCommandContext.h>

#include "common.h"
#include <NGMime/NGMime.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include "OGoRecurrenceFormatter.h"

#include <OGoScheduler/OGoAptMailOpener.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoScheduler/SkySchedulerConflictDataSource.h>


// do not include from OGoSchedulerTools, this lives in Logic/LSScheduler at
// (fresh) build time
#include <LSScheduler/OGoCycleDateCalculator.h>

/*
  TODO: this file contains a *LOT* of duplicate code, especially in the
        mail section => cleanup!
        Really messy stuff.
*/

@interface LSWAppointmentEditor(PrivateMethods)
- (void)_updateParticipantList:(NSArray *)_list;
- (void)_setLabelForParticipant:(id)_part;
- (id)appointmentProposal;
- (BOOL)isProfessionalEdition;
- (BOOL)showAMPMDates;
- (int)maxAppointmentCycles;
@end

@interface LSWEditorPage(MailEditorPage)

- (void)setIsAppointmentNotification:(BOOL)_flag;

@end

@interface NSCalendarDate(CycleDateAdder)

- (NSCalendarDate *)dateByAddingValue:(int)_i inUnit:(NSString *)_unit;

@end

@interface WOComponent(PageConstructors)

- (WOComponent *)conflictPageWithDataSource:(id)_ds
  timeZone:(NSTimeZone *)_tz
  action:(NSString *)_action mailOpener:(OGoAptMailOpener *)_opener;

@end

@implementation LSWAppointmentEditor

+ (int)version {
  return [super version] + 2 /* v?? */;
}

static NSNumber   *yesNum    = nil;
static NSNumber   *noNum     = nil;
static NSNumber   *num0      = nil;
static NSNumber   *num1      = nil;
static NSNumber   *num10     = nil;
static NSArray    *idxArray2 = nil;
static NSArray    *idxArray3 = nil;
static NSArray    *Delimiter = nil;
static NSNull     *null      = nil;
static NGMimeType *eoDateType= nil;
static BOOL       debugConstraints = NO;
static NSArray    *extAttrSpec = nil;

// TODO: document those formats
static NSString *DateParseFmt      = @"%Y-%m-%d %H:%M:%S %Z";
static NSString *DateFmt           = @"%Y-%m-%d";
static NSString *CycleDateStringFmt= @"%Y-%m-%d %Z";
static NSString *DayLabelDateFmt   = @"%Y-%m-%d %Z";

+ (void)initialize {
  // TODO: should check parent class version!
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  yesNum = [[NSNumber numberWithBool:YES] retain];
  noNum  = [[NSNumber numberWithBool:NO]  retain];
  num0   = [[NSNumber numberWithInt:0]    retain];
  num1   = [[NSNumber numberWithInt:1]    retain];
  num10  = [[NSNumber numberWithInt:10]   retain];
  null   = [[NSNull null] retain];
  
  if (idxArray2 == nil)
    idxArray2 = [[NSArray alloc] initWithObjects:num0, num1, nil];

  if (idxArray3 == nil) {
    idxArray3 = [[NSArray alloc] initWithObjects:num0, num1, 
                                   [NSNumber numberWithInt:2],
                                   nil];
  }
  if (Delimiter == nil)
    Delimiter = [[ud arrayForKey:@"scheduler_editor_hourdelimiters"] copy];
  if (eoDateType == nil)
    eoDateType = [[NGMimeType mimeType:@"eo" subType:@"date"] copy];

  extAttrSpec = [[ud arrayForKey:@"OGoExtendedAptAttributes"] copy];
  if ([extAttrSpec isNotEmpty])
    NSLog(@"Note(LSWAppointmentEditor): extended apt attrs are configured.");
  else
    extAttrSpec = nil;
}

- (id)init {
  if ((self = [super init]) != nil) {
    NGBundleManager *bm;
    
    // TODO: accessing the session in init is no good, should be setup in awake
    self->defaults = [[[self session] userDefaults] retain];
    
    bm   = [NGBundleManager defaultBundleManager];
    
    self->resources     = [[NSMutableArray alloc] initWithCapacity:4];
    self->participants  = [[NSMutableArray alloc] initWithCapacity:16];
    self->accessMembers = [[NSMutableArray alloc] initWithCapacity:4];
    self->timeInputType = 
      [[self->defaults stringForKey:@"scheduler_time_input_type"] copy];
    self->moreResources = [[NSMutableArray alloc] initWithCapacity:16];

    if (self->timeInputType == nil) 
      self->timeInputType = @"PopUp";

    if ([bm bundleProvidingResource:@"LSWSchedulerPage"
            ofType:@"WOComponents"] != nil)
      self->aeFlags.isSchedulerClassicEnabled = 1;
    
    self->aeFlags.isMailEnabled =
      [NSClassFromString(@"OGoAptMailOpener") isMailEnabled] ? 1 : 0;
    
    self->aeFlags.isAllDayEvent      = 0;
    self->aeFlags.isAllDayEventSetup = 0;
  }
  return self;
}

- (void)dealloc {
  [self->extendedAttributes    release];
  [self->roleMap               release];
  [self->accessTeams           release];
  [self->comment               release];
  [self->searchText            release];
  [self->participants          release];
  [self->selectedAccessTeam    release];
  [self->searchTeam            release];
  [self->timeZone              release];
  [self->startHour             release];
  [self->endHour               release];
  [self->startMinute           release];
  [self->endMinute             release];
  [self->resources             release];
  [self->timeInputType         release];
  [self->notificationTime      release];
  [self->accessMembers         release];
  [self->selectedAccessMembers release];
  [self->defaults              release];
  //[self->aptTypes              release];
  [super dealloc];
}

- (void)clearEditor {
  [self->accessTeams        release]; self->accessTeams        = nil;
  [self->selectedAccessTeam release]; self->selectedAccessTeam = nil;
  [self->searchTeam         release]; self->searchTeam         = nil;
  [self->searchText         release]; self->searchText         = nil;
  [self->comment            release]; self->comment            = nil;
  [self->timeZone           release]; self->timeZone           = nil;
  //[self->aptTypes           release]; self->aptTypes           = nil;
  [super clearEditor];
}

/* "new" activation */

- (NSCalendarDate *)_defaultStartDate {
  NSCalendarDate *date;
  
  date = [NSCalendarDate date];
  [date setTimeZone:[[self session] timeZone]];
  date = [date hour:11 minute:0 second:0];
  return date;
}
- (NSCalendarDate *)_endDateForStartDate:(NSCalendarDate *)date {
  int hour;

  hour = [date hourOfDay];
  if (hour < 23)
    hour = hour + 1;
  
  return [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                         month:       [date monthOfYear]
                         day:         [date dayOfMonth]
                         hour:        hour
                         minute:      [date minuteOfHour]
                         second:      0
                         timeZone:    [date timeZone]];
}

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id             tobj;
  NSCalendarDate *date, *endDate;
  NSArray        *addParticipants;

  addParticipants = nil;
    
  if ((tobj = [[self session] getTransferObject]) == nil) {
    /* no object in pasteboard */
    date = nil;
  }
  else if ([tobj isKindOfClass:[NSDictionary class]]) {
    /* dictionary in pasteboard */
    date            = [(NSDictionary *)tobj objectForKey:@"startDate"];
    addParticipants = [(NSDictionary *)tobj objectForKey:@"participants"];
    [[self session] removeTransferObject];
   }
  else if ([tobj isKindOfClass:[NSCalendarDate class]]) {
    /* calendar-date in pasteboard */
    date = tobj;
    [[self session] removeTransferObject];
  }
  else {
    /* unknown object in pasteboard */
    date = nil;
  }
  
  if (date == nil) date = [self _defaultStartDate];
  endDate = [self _endDateForStartDate:date];
  [[self snapshot] takeValue:date    forKey:@"startDate"];
  [[self snapshot] takeValue:endDate forKey:@"endDate"];
  
  [self->timeZone release]; self->timeZone = nil;
  self->timeZone = [[date timeZone] retain];
  
  NSAssert(self->participants, @"participants array is missing!");
  
  if (addParticipants) {
    NSMutableSet *s;
    
    s = [[NSMutableSet alloc] initWithCapacity:16];
    [s addObject:[[self session] activeAccount]];
    [s addObjectsFromArray:addParticipants];
    [self->participants addObjectsFromArray:[s allObjects]];
    [s release]; s = nil;
  }
  
  // TODO: maybe we should shallow-copy the participants array?
  [self setSelectedParticipants:
	  (self->participants != nil) 
	  ? (NSArray *)self->participants
	  : (NSArray *)[NSArray array]];
  
  [self _fetchEnterprisesOfPersons:self->participants];
  
  /* setup notification-time from default */
  {
    NSString *s;

    s = [[[self session] userDefaults] 
          stringForKey:@"scheduler_defnotifytime"];
    if ([s isNotEmpty] && ![s isEqualToString:@"no-notify"])
      [self setNotificationTime:s];
  }
  
  /* prepare resources */ // TODO: explain those! (how can they be filled?)
  [self->resources     removeAllObjects];
  [self->accessMembers removeAllObjects];
  return YES;
}

/* "edit" activation */

- (BOOL)_checkEditActivationPreconditions {
  id appointment;

  if ((appointment = [self object]) == nil) {
    [self errorWithFormat:@"got no object for edit-activation!"];
    return NO;
  }
  if (self->comment != nil || self->selectedAccessTeam != nil) {
    [self errorWithFormat:@"editor object is mixed up!"];
    return NO;
  }
  if (self->participants == nil) {
    [self errorWithFormat:@"participants array is not setup!"];
    return NO;
  }
  
  return YES;
}

- (void)_setupParticipantsForAppointment:(id)appointment {
  NSArray  *ps;
  NSArray  *partInfos;
  unsigned i, count;
  
  ps = [self _fetchParticipantsOfAppointment:appointment force:NO];
  
  [self->participants removeAllObjects];
  [self->participants addObjectsFromArray:ps];

  // TODO: maybe copy the participants array? (see other occurence above)
  [self setSelectedParticipants:
	  [self->participants isNotNull] 
	  ? (NSArray *)self->participants : (NSArray *)[NSArray array]];
  
  // TODO: not always required? (and if required, task of the subcomponent?)
  [self _fetchEnterprisesOfPersons:self->participants];

  /* fill role map */
  
  if (self->roleMap == nil)
    self->roleMap = [[NSMutableDictionary alloc] initWithCapacity:16];
  else
    [self->roleMap removeAllObjects];
  
  partInfos = [self _fetchPartCoreInfoOfAppointment:appointment];
  for (i = 0, count = [partInfos count]; i < count; i++) {
    NSDictionary *partInfo;
    NSString *role;
    
    partInfo = [partInfos objectAtIndex:i];
    role     = [partInfo valueForKey:@"role"];
    if (![role isNotEmpty]) {
      /*
        This happens for 'old' appointments opened with the new editor. The
        'old' participants will be resaved as 'required' ones.
      */
      role = @"REQ-PARTICIPANT";
    }
    [self->roleMap setObject:role forKey:[partInfo valueForKey:@"companyId"]];
  }
}

- (void)_setupResourcesFromSnapshot:(id)_snapshot {
  id rNames;

  rNames = [_snapshot valueForKey:@"resourceNames"];
  [self->resources removeAllObjects];
  if ([rNames isNotNull]) {
    [self->resources addObjectsFromArray:
           [rNames componentsSeparatedByString:@", "]];
  }
}

- (void)_setupNotificationTimeFromAppointment:(id)appointment {
  NSNumber *timeNumber;
  NSString *time;
  
  timeNumber = [appointment valueForKey:@"notificationTime"];
  if (![timeNumber isNotNull])
    return;
  
  time = [timeNumber stringValue];
  
  if ([time isEqualToString:@"10"]) // TODO: what is this good for?
    time = @"10m";
  
  [self setNotificationTime:time];
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSArray *ps;
  id      appointment;
  
  if (![self _checkEditActivationPreconditions])
    return NO;
  
  appointment = [self object];

  [self _setupParticipantsForAppointment:appointment];
  ps = nil;
  
  /* get comment */
  self->comment = [[self _getCommentOfAppointment:appointment] copy];
  
  /* get access team */
  self->selectedAccessTeam = 
    [[appointment valueForKey:@"toAccessTeam"] retain];
  
  /* timezone */
  self->timeZone = [[[appointment valueForKey:@"startDate"] timeZone] retain];
  
  [self _setupResourcesFromSnapshot:[self snapshot]];
  [self _setupNotificationTimeFromAppointment:appointment];
  
  /* load extended attributes */
  
  if ([extAttrSpec isNotEmpty]) { /* only if we have a spec (for speed) */
    SkyObjectPropertyManager *pm;
    
    pm = [[[self session] commandContext] propertyManager];
    self->extendedAttributes =
      [[pm propertiesForGlobalID:[appointment valueForKey:@"globalID"]
	   namespace:XMLNS_OGoExtAttrPropNamespace] mutableCopy];
  }
  
  return YES;
}

- (NSString *)defaultWriteAccessList {
  NSMutableArray *wa;
  NSString *list;
  
  if ((wa = [[self defaultWriteAccessAccounts] mutableCopy]) != nil)
    [wa addObjectsFromArray:[self defaultWriteAccessTeams]];
  else
    wa = [[self defaultWriteAccessTeams] mutableCopy];
  
  list = [wa componentsJoinedByString:@","];
  [wa release]; wa = nil;
  return list;
}
- (BOOL)isFilledWriteAccessList:(NSString *)_list {
  return [_list isNotEmpty]
    ? (![_list isEqualToString:@" "] ? YES : NO)
    : NO;
}

- (void)fillAccessMembersFromWriteAccessList:(NSString *)_list {
  NSEnumerator *enumerator;
  id objId;
  
  if (![self isFilledWriteAccessList:_list]) return;
  
  enumerator = [[_list componentsSeparatedByString:@","] objectEnumerator];
  while ((objId = [enumerator nextObject]) != nil) {
    id res;
    
    if ((res = [self _fetchAccountOrTeamForPrimaryKey:objId]) != nil)
      [self->accessMembers addObject:res];
  }
}

- (NSString *)defaultAccessTeamName {
  return [[[self session] userDefaults] 
                 stringForKey:@"scheduler_default_readaccessteam"];
}

- (void)_setSelectedAccessTeamTo:(NSString *)_teamName
  inArray:(NSArray *)_teams
{
  /* 
     searches the accessTeams array for all-intranet and sets that as the 
     selected team 
  */
  unsigned i, cnt;
  
  for (i = 0, cnt = [_teams count]; i < cnt; i++) {
    id t;
    
    t = [_teams objectAtIndex:i];
    if ([[t valueForKey:@"description"] isEqualToString:_teamName]) {
      ASSIGN(self->selectedAccessTeam, t);
      return;
    }
  }
  [self warnWithFormat:
          @"did not find configured default-access team: %@",
          _teamName];
}

- (NSString *)timeStringForHour:(int)_hour minute:(int)_minute {
  char buf[32];
  
  if ([self showAMPMDates]) {
    BOOL am = YES;
    if (_hour >= 12) am = NO;
    _hour %= 12;
    if (!_hour) _hour = 12;
    snprintf(buf, sizeof(buf), "%02i:%02i %s",
             _hour, _minute, am ? "AM" : "PM");
  }
  else
    snprintf(buf, sizeof(buf), "%02i:%02i", _hour, _minute);
  
  return [NSString stringWithCString:buf];
}

- (void)_setupStartDate:(NSCalendarDate *)sd andEndDate:(NSCalendarDate *)ed {
  int shour, ehour, smin, emin;
  char buf[8];
  
  shour = [sd hourOfDay];
  ehour = [ed hourOfDay];
  smin  = [sd minuteOfHour];
  emin  = [ed minuteOfHour];

  self->startTime = [[self timeStringForHour:shour minute:smin] retain];
  self->endTime   = [[self timeStringForHour:ehour minute:emin] retain];
  
  snprintf(buf, sizeof(buf), "%02i", shour);
  self->startHour   = [[NSString alloc] initWithCString:buf];
  snprintf(buf, sizeof(buf), "%02i", smin);
  self->startMinute = [[NSString alloc] initWithCString:buf];
  snprintf(buf, sizeof(buf), "%02i", ehour);
  self->endHour     = [[NSString alloc] initWithCString:buf];
  snprintf(buf, sizeof(buf), "%02i", emin);
  self->endMinute   = [[NSString alloc] initWithCString:buf];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  // retrieve teams of login account
  NSArray      *teams;
  NSDictionary *snp;
  id           appointment;
  NSString *list;
  BOOL ok;

  ok = [super prepareForActivationCommand:_command
              type:_type
              configuration:_cmdCfg];
  if (!ok) return NO;
  
  snp         = [self snapshot];
  appointment = [self object];
  teams       = [self _fetchTeams];
  
  ASSIGN(self->accessTeams, teams);
  
  if ([self isInNewMode]) {
    [self _setSelectedAccessTeamTo:[self defaultAccessTeamName]
          inArray:self->accessTeams];
  }
  
  [self _setupStartDate:[snp valueForKey:@"startDate"]
        andEndDate:[snp valueForKey:@"endDate"]];
  
  /* write access accounts */
    
  [self->accessMembers removeAllObjects];
  list = [self isInNewMode]
    ? [self defaultWriteAccessList]
    : (NSString *)[appointment valueForKey:@"writeAccessList"];
      
  [self fillAccessMembersFromWriteAccessList:list];
  [self setSelectedAccessMembers:self->accessMembers];

  return YES;
}

/* notifications */

- (void)syncAwake {
  NSDictionary *snp;

  [super syncAwake];

  snp = [self snapshot];
  [self setErrorString:nil];
  [[snp valueForKey:@"startDate"] setTimeZone:self->timeZone];
  [[snp valueForKey:@"endDate"]   setTimeZone:self->timeZone];

  // this must be run *before* -takeValuesFromRequest:inContext: is called
}

- (void)syncSleep {
  // reset transient variables
  self->item       = nil;
  self->enterprise = nil;
  
  //[self->aptTypes release]; self->aptTypes = nil;
  
  [[[self session] userDefaults] synchronize];
  [super syncSleep];
}

/* action handling */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self _ensureSyncAwake];

  if ([self->timeInputType isEqualToString:@"PopUp"]) {
    [self->startTime release]; self->startTime = nil;
    [self->endTime   release]; self->endTime   = nil;

    self->startTime = [[self timeStringForHour:[self->startHour intValue]
                             minute:[self->startMinute intValue]] retain];
    self->endTime   = [[self timeStringForHour:[self->endHour intValue]
                             minute:[self->endMinute intValue]] retain];
  }
  return [super invokeActionForRequest:_rq inContext:_ctx];
}

/* resources */

- (NSString *)_resourceString {
  return [self->resources isNotEmpty]
    ? [self->resources componentsJoinedByString:@", "]
    : (NSString *)null;
}

/* calendar */

- (NSString *)calendarPageURL {
  WOResourceManager *rm;
  NSString          *url;
  WOSession         *s;

  s   = [self session];
  rm  = [[WOApplication application] resourceManager];
  url = [rm urlForResourceNamed:@"calendar.html"
            inFramework:nil
            languages:[s languages]
            request:[[self context] request]];
  
  if (url == nil) {
    [self debugWithFormat:@"ERROR: could not locate calendar HTML page!"];
    url = @"/OpenGroupware.org.woa/WebServerResources/English.lproj/"
      @"calendar.html";
  }
  return url;
}
- (NSString *)calendarOnClickEventForFormElement:(NSString *)_name {
  /*
    onclick="setDateField(document.editform.endDate);\
      top.newWin = \
      window.open('/Skyrix.woa/WebServerResources/English.lproj/calendar.html',
        'cal','WIDTH=208,HEIGHT=230')";
  */
  return [NSString stringWithFormat:
                   @"setDateField(document.editform.%@);"
                   @"top.newWin=window.open('%@','cal',"
                   @"'WIDTH=208,HEIGHT=230')", _name, [self calendarPageURL]];
}
- (NSString *)startDateOnClickEvent {
  return [self calendarOnClickEventForFormElement:@"startDate"];
}
- (NSString *)endDateOnClickEvent {
  return [self calendarOnClickEventForFormElement:@"endDate"];
}
- (NSString *)cycleEndDateOnClickEvent {
  return [self calendarOnClickEventForFormElement:@"cycleEndDate"];
}

/* labels */

- (NSString *)appointmentDayLabel {
  NSCalendarDate *date, *endDate;
  id             day;

  date    = [[self snapshot] valueForKey:@"startDate"];
  endDate = [[self snapshot] valueForKey:@"endDate"];
  
  // work around, because default time zone is set again
  // if conflicts happened
  
  [date    setTimeZone:self->timeZone];
  [endDate setTimeZone:self->timeZone];
  
  // TODO: rewrite not to use descriptionWithCalendarFormat, but dayOfWeek
  day = [date descriptionWithCalendarFormat:@"%A"];
  day = [[self labels] valueForKey:day];
  
  day = [day stringByAppendingString:@", "];
  return [day stringByAppendingString:
		[date descriptionWithCalendarFormat:DayLabelDateFmt]];
}

/* default accessors */

- (NSArray *)defaultWriteAccessAccounts {
  return [self->defaults arrayForKey:@"scheduler_write_access_accounts"];
}
- (NSArray *)defaultWriteAccessTeams {
  return [self->defaults arrayForKey:@"scheduler_write_access_teams"];
}

- (BOOL)shouldShowPalmDates {
  return [[self->defaults valueForKey:@"scheduler_show_palm_dates"] boolValue];
}

/* accessors */

- (void)setIgnoreConflictsSelection:(NSString *)_ignoreConflicts {
  if ([_ignoreConflicts isEqualToString:@"onlyNow"]) {
    [[self snapshot] setObject:noNum forKey:@"isConflictDisabled"];
    [self setIgnoreConflicts:YES];
  }
  else if ([_ignoreConflicts isEqualToString:@"always"]) {
    [[self snapshot] setObject:yesNum forKey:@"isConflictDisabled"];
    [self setIgnoreConflicts:YES];
  }
  else {
    [[self snapshot] setObject:noNum forKey:@"isConflictDisabled"];
    [self setIgnoreConflicts:NO];
  }
}
- (NSString *)ignoreConflictsSelection {
  if ([[[self snapshot] valueForKey:@"isConflictDisabled"] boolValue]) {
    [self setIgnoreConflicts:YES];
    return @"always";
  }
  if (![[[self snapshot] valueForKey:@"isConflictDisabled"] boolValue] &&
      [self ignoreConflicts]) {
    return @"onlyNow";
  }
#if 0  // nil == nil
  if (![[[self snapshot] valueForKey:@"isConflictDisabled"] boolValue] &&
      ![self ignoreConflicts]) {
    return nil;
  }
#endif  
  return nil;
}

/* conflict-ignore radio button list */
- (void)setIgnoreConflictsButtonSelection:(NSString *)_sel {
  [self setIgnoreConflictsSelection:_sel];
}
- (NSString *)ignoreConflictsButtonSelection {
  NSString *selection;
  selection = [self ignoreConflictsSelection];
  return (selection == nil) ? (NSString *)@"dontIgnore" : selection;
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;
}

- (id)appointment {
  return [self snapshot];
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setEnterprise:(id)_ep {
  self->enterprise = _ep;
}
- (id)enterprise {
  return self->enterprise;
}

- (BOOL)isValidYear:(int)year {
  return (!((year >= 2037) || ((year < 1700) && (year != 0)))) ? YES : NO;
}
- (void)checkYearRange:(NSString *)_dateString {
  if ([self isValidYear:[_dateString intValue]]) // expects 2004-xx format
    return;
  
  [self setErrorString:
          [[self labels] valueForKey:@"error_limitedDateRange"]];
}

- (OGoAppointmentDateFormatter *)endDateFormatter {
  OGoAppointmentDateFormatter *fmt;
  
  fmt = [[OGoAppointmentDateFormatter alloc] init];
  [fmt setTimeZone:self->timeZone];
  return [fmt autorelease];
}

- (void)setCycleEndDate:(NSString *)_cDate {
  // TODO: form field should use formatter for parsing?!
  NSCalendarDate *d;
  BOOL ok;
  
  ok = [[self endDateFormatter] getObjectValue:&d 
                                forString:_cDate
                                errorDescription:NULL];
  if (ok && d == nil) {
    [[self snapshot] setObject:null forKey:@"cycleEndDate"];
    return;
  }
  if (!ok) {
    [self checkYearRange:_cDate];
    return;
  }
  [[self snapshot] setObject:d forKey:@"cycleEndDate"];
}

- (NSString *)cycleEndDate {
  NSCalendarDate *d;

  d = [[self snapshot] objectForKey:@"cycleEndDate"];
  if (![d isNotNull])
    return nil;
  
  [d setTimeZone:self->timeZone];
  return [d descriptionWithCalendarFormat:DateFmt];
}
- (NSString *)cycleEndDateString {
  NSCalendarDate *d;
  
  d = [[self snapshot] objectForKey:@"cycleEndDate"];
  return [d descriptionWithCalendarFormat:CycleDateStringFmt];
}

- (void)setAppointmentType:(NSString *)_type {
  [[self snapshot] setObject:(_type ? _type : (NSString*)null) forKey:@"type"];
}
- (NSString *)appointmentType {
  return [[self snapshot] objectForKey:@"type"];
}

- (NSString *)unitLabel { // TODO: maybe we can remove this
  return [[self labels] valueForKey:self->item];
}

- (NSString *)ignoreConflictsLabel {
  return [[self labels] valueForKey:self->item];
}

- (void)setSelectedAccessTeam:(id)_team {
  id pkey;

  if ((pkey = [_team valueForKey:@"companyId"]) == nil)
    pkey = null;
  
  ASSIGN(self->selectedAccessTeam, _team);
  [[self snapshot] takeValue:pkey forKey:@"accessTeamId"];

  if (_team)
    [[self snapshot] takeValue:_team forKey:@"toAccessTeam"];
}
- (id)selectedAccessTeam {
  return self->selectedAccessTeam;
}
- (NSArray *)accessTeams {
  return self->accessTeams;
}

- (void)setSearchTeam:(id)_team {
  ASSIGN(self->searchTeam, _team);
}
- (id)searchTeam {
  return self->searchTeam;
}

- (void)setParticipantsFromGids:(NSArray *)_gids {
  NSMutableArray *pgids, *tgids, *result;
  NSEnumerator   *enumerator;
  EOKeyGlobalID  *gid;

  pgids      = [[NSMutableArray alloc] initWithCapacity:4];
  tgids      = [[NSMutableArray alloc] initWithCapacity:4];
  result     = [[NSMutableArray alloc] initWithCapacity:4];

  enumerator = [_gids objectEnumerator];
  while ((gid = [enumerator nextObject]) != nil) {
    if ([[gid entityName] isEqualToString:@"Person"])
      [pgids addObject:gid];
    else if ([[gid entityName] isEqualToString:@"Team"])
      [tgids addObject:gid];
    else {
      [self warnWithFormat:@"[%s:%d]: unknown gid %@", 
            __PRETTY_FUNCTION__, __LINE__, gid];
    }
  }
  [result addObjectsFromArray:[self _fetchPersonsForGIDs:pgids]];
  [result addObjectsFromArray:[self _fetchTeamsForGIDs:tgids]];
  
  [self->participants addObjectsFromArray:result];
  
  [result release]; result = nil;
  [tgids  release]; tgids  = nil;
  [pgids  release]; pgids  = nil;    
}

- (void)setParticipantsFromProposal:(NSArray *)_part {
  if (_part == self->participants) return;
  [self->participants release];
  self->participants = [_part mutableCopy];
}

- (void)setResources:(NSArray *)_res {
  NSArray *tmp;
  
  if (self->resources == _res) return;
  tmp = self->resources;
  self->resources = [_res mutableCopy];
  [tmp release];
}
- (NSArray *)resources {
  return self->resources;
}

- (void)setRoleMap:(NSMutableDictionary *)_roleMap {
  if (self->roleMap == _roleMap)
    return;
  
  ASSIGN(self->roleMap, _roleMap);
}
- (NSMutableDictionary *)roleMap {
  return self->roleMap;
}

- (void)addParticipant:(id)_participant {
  if ([self->participants containsObject:_participant]) return;
  [self->participants addObject:_participant];
}

- (void)setResourceStrings:(id)_res {
  NSArray      *res;
  NSEnumerator *enumerator;
  id           obj;

  res = [[self session] resources];

  [self->resources removeAllObjects];
  enumerator = [res objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    if (([_res containsObject:[obj valueForKey:@"name"]]))
      [self->resources addObject:obj];
  }
  if ([_res count] != [self->resources count]) {
    [self warnWithFormat:
            @"%s:%d: could not associate all resource names %@ %@",
            __PRETTY_FUNCTION__, __LINE__, _res, self->resources];
  }
}

/* --- notificationTime ------------------------------------------- */

- (void)setNotificationTime:(NSString *)_time {
  ASSIGNCOPY(self->notificationTime, _time);
}
- (NSString *)notificationTime {
  return self->notificationTime;
}

- (void)setMeasure:(NSString *)_measure {
  ASSIGNCOPY(self->measure, _measure);
}
- (NSString *)measure {
  return self->measure;   // "minutes" || "hours" || "days"
}

- (void)setSelectedMeasure:(NSString *)_measure {
  ASSIGNCOPY(self->selectedMeasure, _measure);
}
- (NSString *)selectedMeasure {
  return self->selectedMeasure;
}

- (NSString *)measureLabel {
  return [[self labels] valueForKey:self->measure];
}

- (BOOL)isSchedulerClassicEnabled {
  return self->aeFlags.isSchedulerClassicEnabled ? YES : NO;
}

- (void)setIsParticipantsClicked:(BOOL)_flag {
  self->aeFlags.isParticipantsClicked = _flag ? 1 : 0;
}
- (BOOL)isParticipantsClicked {
  return self->aeFlags.isParticipantsClicked ? YES : NO;
}
- (void)setIsResourceClicked:(BOOL)_flag {
  self->aeFlags.isResourceClicked = _flag ? 1 : 0;
}
- (BOOL)isResourceClicked {
  return self->aeFlags.isResourceClicked ? YES : NO;
}
- (void)setIsAccessClicked:(BOOL)_flag {
  self->aeFlags.isAccessClicked = _flag ? 1 : 0;
}
- (BOOL)isAccessClicked {
  return self->aeFlags.isAccessClicked ? YES : NO;
}

- (BOOL)isMailEnabled {
  return self->aeFlags.isMailEnabled ? YES : NO;
}

- (BOOL)isMailLicensed {
  [self logWithFormat:@"called deprecated method: %s", __PRETTY_FUNCTION__];
  return YES; // DEPRECATED
}
- (BOOL)isAptConflictLicensed {
  [self logWithFormat:@"called deprecated method: %s", __PRETTY_FUNCTION__];
  return YES; // DEPRECATED
}

- (BOOL)isNotificationEnabled {
  [self logWithFormat:@"called deprecated method: %s", __PRETTY_FUNCTION__];
  return YES; // DEPRECATED
}

/* ---------------------------------------------------------------- */

- (void)setParticipants:(id)_part {
  id tmp;

  if (_part == self->participants)
    return;
  
  tmp = self->participants;
  self->participants = [_part mutableCopy];
  [tmp release];
}
- (NSArray *)participants {
  return self->participants;
}

- (void)setSelectedParticipants:(NSArray *)_array {
  /* 
     Those are used as 'participants' in -parseSnapshotValues, its synced up
     from SkyParticipantsSelection/OGoAttendeeSelection.
  */
  ASSIGN(self->selectedParticipants, _array);
}
- (id)selectedParticipants {
  /* Note: this is not used as input in SkyParticipantsSelection */
  return self->selectedParticipants;
}

- (void)setAccessMembers:(id)_part {
  ASSIGN(self->accessMembers, _part);
}
- (NSArray *)accessMembers {
  return self->accessMembers;
}

- (void)setSelectedAccessMembers:(NSArray *)_array {
  ASSIGN(self->selectedAccessMembers, _array);
}
- (id)selectedAccessMembers {
  return self->selectedAccessMembers;
}

- (BOOL)hasParent {
  return [[[self snapshot] valueForKey:@"parentDateId"] isNotNull];
}

- (BOOL)isCyclic {
  return [[[self snapshot] valueForKey:@"type"] isNotEmpty];
}
- (BOOL)isNewOrNotCyclic {
  return ([self isInNewMode] || (![self isCyclic])) ? YES : NO;
}

- (void)setSearchText:(NSString *)_text {
  ASSIGNCOPY(self->searchText, _text);
}
- (NSString *)searchText {
  return self->searchText;
}

- (void)setIgnoreConflicts:(BOOL)_ignoreConflicts {
  self->aeFlags.ignoreConflicts = _ignoreConflicts ? 1 : 0;
}
- (BOOL)ignoreConflicts {
  return self->aeFlags.ignoreConflicts ? YES : NO;
}

- (void)setIsAbsence:(BOOL)_isAbsence {
  [[self snapshot] setObject:(_isAbsence ? yesNum:noNum) forKey:@"isAbsence"];
}
- (BOOL)isAbsence {
  return [[[self snapshot] objectForKey:@"isAbsence"] boolValue];
}

- (void)setIsAttendance:(BOOL)_flag {
  [[self snapshot] setObject:(_flag ? yesNum : noNum) forKey:@"isAttendance"];
}
- (BOOL)isAttendance {
  return [[[self snapshot] objectForKey:@"isAttendance"] boolValue];
}

- (void)setIsConflictDisabled:(BOOL)_isConflictDisabled {
  [[self snapshot] setObject:(_isConflictDisabled ? yesNum: noNum)
                   forKey:@"isConflictDisabled"];
}
- (BOOL)isConflictDisabled {
  return [[[self snapshot] objectForKey:@"isConflictDisabled"] boolValue];
}

// may be HH:MM or HH:MM AM/PM
- (void)setStartTime:(NSString *)_startTime {
  ASSIGN(self->startTime, _startTime);
}
- (NSString *)startTime {
  return self->startTime;
}
- (void)_updateStartTimeWithHour:(int)_hour minute:(int)_minute {
  [self setStartTime:[self timeStringForHour:_hour minute:_minute]];
}

- (void)setEndTime:(NSString *)_endTime {
  ASSIGN(self->endTime, _endTime);
}
- (NSString *)endTime {
  return self->endTime;
}
- (void)_updateEndTimeWithHour:(int)_hour minute:(int)_minute {
  [self setStartTime:[self timeStringForHour:_hour minute:_minute]];
}

- (void)setStartHour:(NSString *)_startHour {
  ASSIGN(self->startHour, _startHour);
}
- (NSString *)startHour {
  return self->startHour;
}

- (void)setEndHour:(NSString *)_endHour {
  ASSIGN(self->endHour, _endHour);
}
- (NSString *)endHour {
  return self->endHour;
}

- (void)setStartMinute:(NSString *)_startMinute {
  ASSIGN(self->startMinute, _startMinute);
}
- (NSString *)startMinute {
  return self->startMinute;
}

- (void)setEndMinute:(NSString *)_endMinute {
  ASSIGN(self->endMinute, _endMinute);
}
- (NSString *)endMinute {
  return self->endMinute;
}

- (void)fillDateField:(NSString *)_key withString:(NSString *)_s {
  NSString       *s;
  NSCalendarDate *d;

  s = [[NSString alloc] initWithFormat:@"%@ 00:00:00 %@",
                        _s, [self->timeZone abbreviation]];
  
  d = [[NSCalendarDate alloc] initWithString:s calendarFormat:DateParseFmt];
  [s release]; s = nil;
  
  if (d != nil) {
    [[self snapshot] takeValue:d forKey:_key];
    [d release];
  }
  else
    [self checkYearRange:_s]; // TODO: what does this do?
}

- (void)setStartDate:(NSString *)_startDate {
  [self fillDateField:@"startDate" withString:_startDate];
}
- (NSString *)startDate {
  NSCalendarDate *d;
  
  if ((d = [[self snapshot] valueForKey:@"startDate"]) == nil)
    return nil;
  
  return [d descriptionWithCalendarFormat:DateFmt];
}

- (void)setEndDate:(NSString *)_endDate {
  [self fillDateField:@"endDate" withString:_endDate];
}
- (NSString *)endDate {
  NSCalendarDate *d;

  if ((d = [[self snapshot] valueForKey:@"endDate"]) == nil)
    return nil;
  
  return [d descriptionWithCalendarFormat:DateFmt];
}

- (void)setIsAllDayEvent:(BOOL)_flag {
  self->aeFlags.isAllDayEvent = (_flag) ? 1 : 0;
}
- (BOOL)isAllDayEvent {
  if (self->aeFlags.isAllDayEventSetup == 0) {
    NSCalendarDate *startDate;
    NSCalendarDate *endDate;
    startDate = [[self snapshot] valueForKey:@"startDate"];
    endDate   = [[self snapshot] valueForKey:@"endDate"];

    if (startDate == nil || endDate == nil)
      return NO;
    
    self->aeFlags.isAllDayEventSetup = 1;
    self->aeFlags.isAllDayEvent =
      (([self->startHour intValue] == 0) &&
       ([self->startMinute intValue] == 0) &&
       ([self->endHour intValue] == 23) &&
       ([self->endMinute intValue] == 59)) ? 1 : 0;
  }
  return self->aeFlags.isAllDayEvent ? YES : NO;
}

- (void)setStartDateFromProposal:(NSCalendarDate *)_date {
  // TODO: using descriptionWithCalendarFormat is inefficient, rewrite
  [self setStartMinute:[_date descriptionWithCalendarFormat:@"%M"]];
  [self setStartHour:[_date descriptionWithCalendarFormat:@"%H"]];
  [self _updateStartTimeWithHour:[_date hourOfDay]minute:[_date minuteOfHour]];
  [self setStartDate:[_date descriptionWithCalendarFormat:DateFmt]];
}
- (void)setEndDateFromProposal:(NSCalendarDate *)_date {
  // TODO: using descriptionWithCalendarFormat is inefficient, rewrite
  [self setEndMinute:[_date descriptionWithCalendarFormat:@"%M"]];
  [self setEndHour:[_date descriptionWithCalendarFormat:@"%H"]];
  [self _updateEndTimeWithHour:[_date hourOfDay] minute:[_date minuteOfHour]];
  [self setEndDate:[_date descriptionWithCalendarFormat:DateFmt]];
}

- (NSArray *)idxArray2 {
  return idxArray2;
}
- (NSArray *)idxArray3 {
  return idxArray3;
}

- (void)setMoveAmount:(char)_amount {
  self->moveAmount = _amount;
}
- (char)moveAmount {
  return self->moveAmount;
}
- (NSString *)moveAmountLabel {
  return [self->item stringValue];
}

- (void)setMoveUnit:(char)_unit {
  self->moveUnit = _unit;
}
- (char)moveUnit {
  return self->moveUnit;
}
- (NSString *)moveUnitLabel {
  switch ([self->item intValue]) {
    case 0: return [[self labels] valueForKey:@"move_unit_days"];
    case 1: return [[self labels] valueForKey:@"move_unit_weeks"];
    case 2: return [[self labels] valueForKey:@"move_unit_months"];
    default: return nil;
  }
}

- (void)setMoveDirection:(char)_direction { // 0=forward, 1=backward
  self->moveDirection = _direction;
}
- (char)moveDirection {
  return self->moveDirection;
}
- (NSString *)moveDirectionLabel {
  switch ([self->item intValue]) {
    case 0: return [[self labels] valueForKey:@"move_direction_forward"];
    case 1: return [[self labels] valueForKey:@"move_direction_backward"];
    default: return nil;
  }
}

- (NSArray *)expandedParticipants {
  NSMutableSet *staffSet;
  unsigned i, cnt;
        
  cnt      = [self->participants count];
  staffSet = [NSMutableSet setWithCapacity:cnt];
        
  for (i = 0; i < cnt; i++) {
    NSArray *members;
    id staff;

    staff = [self->participants objectAtIndex:i];    
    if (![[staff valueForKey:@"isTeam"] boolValue]) {
      [staffSet addObject:staff]; 
      continue;
    }
    
    if ((members = [staff valueForKey:@"members"]) == nil) {
      [self run:@"team::members", @"object", staff, nil];
      members = [staff valueForKey:@"members"];
    }
    [staffSet addObjectsFromArray:members];
  }
  return [staffSet allObjects];
}

#if 0 // TODO: remove when we are sure its not used
- (NSString *)cycleType { // replaced by formatter
  NSString *t;
  
  if ((t = [[self snapshot] valueForKey:@"type"]) == nil)
    return nil;
  
  if ([t hasPrefix:@"RRULE:"]) {
    // TODO: add a rrule formatter
    return [t substringFromIndex:6];
  }
  
  return [[self labels] valueForKey:t];
}
#endif

- (NSString *)timeInputType {
  return self->timeInputType;
}  
- (BOOL)isTimeInputPopUp {
  return [self->timeInputType isEqualToString:@"PopUp"] ? YES : NO;
}

/* actions */

- (BOOL)scanTime:(NSString *)_time hour:(int *)hour_ minute:(int *)minute_
  am:(BOOL *)am_
{
  NSScanner    *scanner;
  NSString     *del;
  NSEnumerator *enumerator;
  
  if (![_time isNotEmpty]) {
    *hour_   = 0;
    *minute_ = 0;
    *am_     = NO;
    return YES;
  }
  
  if ([self showAMPMDates]) {
    *am_ = (([_time rangeOfString:@"am"].length > 0) ||
            ([_time rangeOfString:@"AM"].length > 0))
      ? YES : NO;
  }
  
  enumerator = [Delimiter objectEnumerator];
  while ((del = [enumerator nextObject]) != nil) {
    if ([_time rangeOfString:del].length > 0)
      break;
  }
  scanner = [NSScanner scannerWithString:_time];
  
  if (!del) {
    *minute_ = 0;
    
    return [scanner scanInt:hour_];
  }
  return ([scanner scanInt:hour_]
          && [scanner scanString:del intoString:NULL]
          && [scanner scanInt:minute_]);
}

- (BOOL)scanTo24HourTime:(NSString *)_time
  hour:(int *)hour_ minute:(int *)minute_
{
  int  hour;
  int  minute;
  BOOL am;
  
  if (![self scanTime:_time hour:&hour minute:&minute am:&am])
    return NO;
  
  if ([self showAMPMDates]) {
    if (hour == 12) {
      if (am) hour = 0;
    }
    else if (!am) 
      hour += 12;
  }
  *hour_   = hour;
  *minute_ = minute;
  return YES;
}

- (BOOL)checkConstraints {
  NSDictionary    *appointment;
  NSMutableString *error;
  NSCalendarDate  *begin, *end;
  NSString        *type;
  id              l;
  int             hours, minutes;
  
  if ([[self errorString] isNotEmpty]) {
    if (debugConstraints) [self logWithFormat:@"an error string is set"];
    return YES;
  }
  
  appointment = [self snapshot];
  error       = [NSMutableString stringWithCapacity:128];
  type        = [appointment valueForKey:@"type"];
  l           = [self labels];
  
  if ([self isAllDayEvent]) {
    hours   = 0;
    minutes = 0;
  }
  else {
    BOOL am;
    
    if (![self scanTime:self->startTime hour:&hours minute:&minutes am:&am]) {
      [self setErrorString:[l valueForKey:@"error_starttimeParse"]];
      if (debugConstraints) [self logWithFormat:@"missing start-time"];
      return YES;
    }
    if ([self showAMPMDates]) {
      if (hours == 12) {
        if (am) hours = 0;
      }
      else if (!am) hours += 12;
    }
    if (hours < 0 || hours > 23) {
      [error appendString:[l valueForKey:
                             @"error_starttimeHoursBetween0And23"]];

      if (minutes < 0 || minutes > 59) 
        [error appendString:[l valueForKey:
                               @"error_starttimeMinutesBetween0And59"]];
    }
  }
  if ([error isNotEmpty]) {
    [self setErrorString:error];
    if (debugConstraints) [self logWithFormat:@"contraint(a): %@", error];
    return YES;
  }
  
  {
    NSCalendarDate *d;

    d = [appointment valueForKey:@"startDate"];      
    d = [d hour:hours minute:minutes];
    
    if (d != nil)
      [appointment takeValue:d forKey:@"startDate"];
  }
  
  if ([self isAllDayEvent]) {
    hours   = 23;
    minutes = 59;
  }
  else {
    BOOL am;
    
    if (![self scanTime:self->endTime hour:&hours minute:&minutes am:&am]) {
      [self setErrorString:[l valueForKey:@"error_endtimeParse"]];
      return YES;
    }
    if ([self showAMPMDates]) {
      if (hours == 12) {
        if (am) hours = 0;
      }
      else if (!am) hours += 12;
    }
    if (hours < 0 || hours > 23) {
      NSString *s;

      s = [l valueForKey:@"error_endtimeHoursBetween0And23"];
      [error appendString:s];
      
      if (minutes < 0 || minutes > 59) {
	s = [l valueForKey:@"error_endtimeMinutesBetween0And59"];
        [error appendString:s];
      }
    }
  }
  if ([error isNotEmpty]) {
    [self setErrorString:error];
    if (debugConstraints) [self logWithFormat:@"contraint(b): %@", error];
    return YES;
  }
  
  {
    NSCalendarDate *d;

    d = [appointment valueForKey:@"endDate"];      
    d = [d hour:hours minute:minutes];
    
    if (d != nil)
      [appointment takeValue:d forKey:@"endDate"];
  }
  
  if ([type isNotEmpty]) {
    NSCalendarDate *cDate;
    
    // TODO: fixup enddate for rrules?
    cDate = [appointment valueForKey:@"cycleEndDate"];
    
    if (![cDate isNotNull]) {
      [error appendString:[l valueForKey:@"error_noCycleEndDate"]];
    }
    else {
      NSArray *cycles;
      
      cycles = [OGoCycleDateCalculator cycleDatesForStartDate:
                                         [appointment valueForKey:@"startDate"]
                                       endDate:
                                         [appointment valueForKey:@"endDate"]
                                       type:type
                                       maxCycles:4096 /* arbitary selection */
                                       startAt:1
                                       endDate:cDate
                                       keepTime:YES];
      if ([cycles count] > [self maxAppointmentCycles]) {
	NSString *s;
        
        s = [l valueForKey:@"error_toManyCyclics"];
	[error appendFormat:s, [cycles count]];
      }
    }
  }
  begin = [appointment valueForKey:@"startDate"];
  end   = [appointment valueForKey:@"endDate"];

  if (begin == nil)
    [error appendString:[l valueForKey:@"error_noStartDate"]];
  if (end == nil)
    [error appendString:[l valueForKey:@"error_noEndDate"]];

  if ((begin != nil) && (end != nil)) {
    if ([begin compare:end] == NSOrderedDescending) {
      [error appendFormat:
             [l valueForKey:@"error_endBeforStartFormat"],
             end, begin];
      [appointment takeValue:begin forKey:@"endDate"];
    }
  }

  if (![[appointment valueForKey:@"title"] isNotEmpty])
    [error appendString:[l valueForKey:@"error_noTitle"]];
  
  if (![self->participants isNotEmpty])
    [error appendString:[l valueForKey:@"error_noParticipants"]];
  
  {
    NSScanner *scanner;

    scanner = [NSScanner scannerWithString:self->notificationTime];    
    
    if (![scanner scanInt:NULL] && [self->notificationTime isNotEmpty] &&
        ![self->selectedMeasure isEqualToString:@"-"]) {
      [error appendString:[l valueForKey:@"error_invalidReminder"]];
    }
  }
  
  if ([error isNotEmpty]) {
    [self setErrorString:error];
    if (debugConstraints) [self logWithFormat:@"contraint(c): %@", error];
    return YES;
  }
  
  [self setErrorString:nil];
  return NO;
}

- (BOOL)doesAppointmentConflictFrom:(NSCalendarDate *)_start
  to:(NSCalendarDate *)_to
  participants:(NSArray *)_participants
{
  return NO;
}

/* notifications */

- (NSString *)insertNotificationName {
  NSNotificationCenter *nc;
  
  // TODO: what is this?! Evil!
  nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:SkyNewAppointmentNotification object:nil];

  return LSWNewAppointmentNotificationName;
}
- (NSString *)updateNotificationName {
  NSNotificationCenter *nc;

  // TODO: what is this?! Evil!
  nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:SkyUpdatedAppointmentNotification object:nil];

  return LSWUpdatedAppointmentNotificationName;
}
- (NSString *)deleteNotificationName {
  NSNotificationCenter *nc;
  
  // TODO: what is this?! Evil!
  nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:SkyDeletedAppointmentNotification object:nil];

  return LSWDeletedAppointmentNotificationName;
}

- (BOOL)showCalendarPopUp {
  WEClientCapabilities *cc;
  
  if ((cc = [[[self context] request] clientCapabilities]) == nil)
    return NO;
  
  if (![cc isJavaScriptBrowser])  return NO;
  if ([cc isNetscape6])           return NO;
  
  if (![[[self session] valueForKey:@"isJavaScriptEnabled"] boolValue])
    return NO;
  
  return YES;
}

/* user specific defaults */

- (NSUserDefaults *)userDefaults {
  return self->defaults;
}

- (BOOL)showAMPMDates {
  return [[self userDefaults] boolForKey:@"scheduler_AMPM_dates"];
}

- (BOOL)isShowIgnoreConflicts {
  return ![[self userDefaults] boolForKey:@"scheduler_hide_ignore_conflicts"];
}

- (int)maxAppointmentCycles {
  int maxCycles;
  
  maxCycles = [[self userDefaults] integerForKey:@"LSMaxAptCycles"];
  if (maxCycles < 1)
    maxCycles = 100;
  return maxCycles;
}

- (int)noOfCols {
  int n;
  
  n = [[self userDefaults] integerForKey:@"scheduler_no_of_cols"];
  return (n > 0) ? n : 2;
}

- (NSString *)defaultTimeZone {
  NSString *tzs;
  
  if ((tzs = [[self userDefaults] stringForKey:@"timezone"]) == nil)
    tzs = @"MET";
  return tzs;
}

/* actions */

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

- (NSString *)_accessList {
  // DEPRECATED: now directly available in set/new commands
  NSMutableString *accessList;
  NSEnumerator    *enumerator;
  id              obj;
  BOOL            isFirst;
  
  if (![self->selectedAccessMembers isNotEmpty])
    return nil;
  
  // TODO: just:
  //  [[self->selectedAccessMembers valueForKeyPath:@"companyId.stringValue"]
  //   componentsJoinedByString:@","
  // ... or at least move to some array method
  
  isFirst    = YES;
  accessList = [NSMutableString stringWithCapacity:128];
  enumerator = [self->selectedAccessMembers objectEnumerator];
  
  while ((obj = [enumerator nextObject]) != nil) {
    if (isFirst)
      isFirst = NO;
    else
      [accessList appendString:@","];
    [accessList appendString:[[obj valueForKey:@"companyId"] stringValue]];
  }
  return accessList;
}

- (NSArray *)participantsInfoChanges:(NSArray *)_partEOs {
  /*
    This calculates the records for the appointment::set-participants command.
    It includes just the required info (id + role), not the full EOs.
  */
  static NSArray *copyKeys = nil;
  NSMutableArray *partInfos;
  unsigned i, count;
  
  if (copyKeys == nil) {
    /* 
       Those are keys which are set in the participant array of the snapshot,
       which in turn is used in subsequent pages! (eg the
       SkySchedulerConflictPage reuses that array)
    */
    copyKeys = [[NSArray alloc] initWithObjects:@"companyId",
                                @"globalID", @"description", @"login",
                                @"name", @"firstname", @"isTeam", @"isAccount",
                                @"isPerson", nil];
  }
  
  if ((count = [_partEOs count]) == 0)
    return [NSArray array];

  partInfos = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSMutableDictionary *partInfo;
    NSString *role;
    
    partInfo =
      [[[_partEOs objectAtIndex:i] valuesForKeys:copyKeys] mutableCopy];
    
    role = [self->roleMap objectForKey:[partInfo objectForKey:@"companyId"]];
    if ([role isNotEmpty])
      [partInfo setObject:role forKey:@"role"];
    
    [partInfos addObject:partInfo];
    [partInfo release];
  }
  return partInfos;
}

- (void)parseSnapshotValues {
  /* 
     Called by -saveAndGoBackWithCount:action:. The 'snapshot' is not a real
     snapshot but a set of parameters passed to the 'appointment::insert' or
     'appointment::update' command.
     Some of the parameters are directly bound in the template, but some are
     just setup here.
  */
  id apmt = [self snapshot];
  
  /* write access rights */
  
  [apmt takeValue:([self->selectedAccessMembers isNotEmpty]
		   ? (id)self->selectedAccessMembers : (id)[NSNull null])
	forKey:@"writeAccessList"];
  
  /* transfer participants */

#if 0 // (required for some code sections, eg conflicts?)
  [apmt takeValue:self->selectedParticipants forKey:@"participants"];
#else
  /* this can conflict with code which expects EOs in the snapshot */
  [apmt takeValue:[self participantsInfoChanges:self->selectedParticipants]
        forKey:@"participants"];
#endif
  
  /* whether to ignore conflicts */
  
  [apmt takeValue:(self->aeFlags.ignoreConflicts ? yesNum : noNum)
        forKey:@"isWarningIgnored"];

  /* setup resources */
  
  [apmt takeValue:[self _resourceString] forKey:@"resourceNames"];

  /* transfer comment */

  if (self->comment != nil)
    [apmt takeValue:self->comment forKey:@"comment"];

  /* fixup notification time */
  
  [apmt takeValue:null forKey:@"notificationTime"];
  if ([self->notificationTime isNotEmpty]) {
    NSNumber *time;
    
    // TODO: what is this '10m' special case?
    time = [self->notificationTime isEqualToString:@"10m"]
      ? num10
      : [NSNumber numberWithInt:[self->notificationTime intValue]];

    [apmt takeValue:time forKey:@"notificationTime"];
  }
  
  /* add creator */

  if ([self isInNewMode]) {
    if (![[apmt valueForKey:@"ownerId"] isNotNull]) {
      [apmt takeValue:[[[self session] activeAccount] valueForKey:@"companyId"]
	    forKey:@"ownerId"];
    }
  }
  
  /* copy extendedAttributes */
  if ([extAttrSpec isNotEmpty])
    [apmt takeValue:self->extendedAttributes forKey:@"customAttributes"];
}

- (void)_correctSnapshotTimeZone {
  [[[self snapshot] valueForKey:@"startDate"] setTimeZone:self->timeZone];
  [[[self snapshot] valueForKey:@"endDate"]   setTimeZone:self->timeZone];
}

- (id)_addExtraDataSourcesToConflictDS:(SkySchedulerConflictDataSource *)_ds {
  // add a palmdatedatasource to also check for conflicting palm dates
  EODataSource *pds;
  Class c;
  
  if (![self shouldShowPalmDates])
    return _ds;

  if ((c = NSClassFromString(@"SkyPalmDateDataSource")) == Nil) {
    static BOOL didLog = NO;
    if (!didLog) {
      [self logWithFormat:@"Note: missing SkyPalmDateDataSource class"];
      didLog = YES;
    }
    return _ds;
  }
  
  pds = [(SkyAccessManager *)[c alloc] initWithContext:
			       (id)[[self session] commandContext]];
  [_ds addDataSource:pds];
  [pds release]; pds = nil;
  
  return _ds;
}

- (id)_handleConflictsInConflictDS:(SkySchedulerConflictDataSource *)_ds 
  action:(NSString *)_action
{
  OGoAptMailOpener *opener;
  
  [self _correctSnapshotTimeZone];
  [[[_ds appointment] valueForKey:@"startDate"] setTimeZone:self->timeZone];
  [[[_ds appointment] valueForKey:@"endDate"]   setTimeZone:self->timeZone];
  
  if ([_action isNotNull]) {
    opener = [NSClassFromString(@"OGoAptMailOpener")
			       mailOpenerForObject:[self snapshot] 
			       action:_action
			       page:self];
  }
  else
    opener = nil;
  
  return [self conflictPageWithDataSource:_ds timeZone:self->timeZone
               action:_action mailOpener:opener];
}

- (id)saveAndGoBackWithCount:(int)_backCount action:(NSString *)_action {
  SkySchedulerConflictDataSource *ds;
  
  if (![self checkConstraintsForSave]) {
    // TODO: place after parseSnapshotValues??
    if (debugConstraints)
      [self logWithFormat:@"abort with: %@", [self errorString]];
    return nil;
  }
  
  [self parseSnapshotValues];
  [self _correctSnapshotTimeZone];
  
  /* checking conflicts */
  /* 
     Note: we use SkySchedulerConflictDataSource here because the command
           doesn't check for palm conflicts (_addExtraDataSourcesToConflictDS)
  */
  
  ds = [SkySchedulerConflictDataSource alloc];
  ds = [[ds initWithContext:[[self session] commandContext]] autorelease];
  [ds setAppointment:[self snapshot]];
  ds = [self _addExtraDataSourcesToConflictDS:ds];
  
  // TODO: do we need caching here? (if so, add it by using an EOCacheDS)
  // TODO: DUP in LSWAppointmentMove?
  if ([[ds fetchObjects] isNotEmpty]) {
    [self debugWithFormat:@"handle conflicts .."];
    return [self _handleConflictsInConflictDS:ds action:_action];
  }
  
  /* return */
  
  [self _correctSnapshotTimeZone]; // again?
  return [super saveAndGoBackWithCount:_backCount]; // call into LSWEditorPage
}

- (id)saveAndGoBackWithCount:(int)_backCount {
  return [self saveAndGoBackWithCount:_backCount action:nil];
}

- (id)insertObject {
  /* called by -_performOpInTransaction: */
  return [self runCommand:@"appointment::new" arguments:[self snapshot]];
}

- (id)updateObject {
  /* called by -_performOpInTransaction: */
  return [self runCommand:@"appointment::set" arguments:[self snapshot]];
}

- (id)deleteObject {
  return [self runCommand:
               @"appointment::delete",
               @"object",          [self object],
               @"deleteAllCyclic", 
	       (self->aeFlags.deleteAllCyclic ? yesNum : noNum),
               @"reallyDelete",    yesNum,
               nil];
}

- (NSString *)windowTitle {
  // TODO: move to a formatter
  NSMutableString *ms;
  NSString *s;
  id labels;
  
  labels = [self labels];
  ms = [NSMutableString stringWithCapacity:96];
  [ms appendString:[labels valueForKey:@"appointmentOnLabel"]];
  [ms appendString:@" "];
  [ms appendString:[self appointmentDayLabel]];
  
  s = [self isInNewMode]
    ? (NSString *)nil
    : [[self recurrenceFormatter] stringForObjectValue:[self snapshot]];
  
  if ([s isNotEmpty]) {
    [ms appendString:@" ("];
    [ms appendString:s];
    [ms appendString:@")"];
  }
  return ms;
}

- (id)reallyDelete {
  [self deleteAndGoBackWithCount:2];
  
  // TODO: document this check
  if ([[self navigation] activePage] == self)
    return nil;

  return [NSClassFromString(@"OGoAptMailOpener")
			   mailEditorForObject:[self object]
			   action:@"removed" page:self];
}

- (id)saveAndSendMail {
  /* TODO: this method is *far* too long, split it up! */
  NSArray *ps;
  id      obj;
  id      mailEditor;
  id      page, l;
  
  l    = [self labels];
  page = [self saveAndGoBackWithCount:1
               action:([self isInNewMode] ? @"created" : @"edited")];
  
  /* if the save resulted in a conflict, we enter the conflict page */
  if ([page isKindOfClass:NSClassFromString(@"SkySchedulerConflictPage")])
    return page;
  
  if (![self isMailEnabled]) {
    [self warnWithFormat:@"mail is not enabled, not entering the editor .."];
    return nil;
  }
  // TODO: document this
  if ([[self navigation] activePage] == self) {
    [self logWithFormat:@"staying on editor page (active-page==self)"];
    [self logWithFormat:@"  active-page: %@",[[self navigation] activePage]];
    [self logWithFormat:@"  page:        %@", page];
    return nil;
  }

  /*
    Undoing changes is currently only possible if we're
    in new mode, not while being in edit mode, because
    then we have to restore an earlier state and so we just
    delete the unneeded appointment. Maybe later.
  */
  
  /* fetch object, configure editor */
  
  obj = [self object];
  ps  = [self _fetchParticipantsOfAppointment:obj force:YES];
  [self setParticipants:ps];

  [self setErrorString:nil];
  
  mailEditor = [NSClassFromString(@"OGoAptMailOpener")
				 mailEditorForObject:obj
				 action:
				   [self isInNewMode] ? @"created" : @"edited"
				 page:self];
  if (mailEditor == nil) {
    [self setErrorString:@"Could not load mail editor!"];
    [self warnWithFormat:@"could not instantiate mail editor!"];
    return nil;
  }
  
  /* the following is required for no known reason (OGo Bug #1!) */
  [[self navigation] enterPage:mailEditor];
  return mailEditor;
}

- (id)moveAppointment {
  NSMutableDictionary *appointment;
  NSCalendarDate      *start, *end, *oldStart, *oldEnd;
  int                 amount;
  id l;

  l = [self labels];
  
  if (self->moveAmount == 0) {
    // not to be moved, stay on page
    [self setErrorString:
          [[self labels] valueForKey:@"error_specifyMoveAmount"]];
    return nil;
  }

  appointment = [self snapshot];
  start       = [appointment valueForKey:@"startDate"];
  end         = [appointment valueForKey:@"endDate"];
  oldStart    = [[start copy] autorelease];
  oldEnd      = [[end   copy] autorelease]; 
  amount      = self->moveAmount;

  if (self->moveDirection != 0) // backward (1)
    amount = -amount;

  [self setErrorString:nil];
    
  switch (self->moveUnit) {
  case 0: // days
    start = [start dateByAddingYears:0 months:0 days:amount
		   hours:0 minutes:0 seconds:0];
    end   = [end   dateByAddingYears:0 months:0 days:amount
		   hours:0 minutes:0 seconds:0];
    break;
  case 1: // weeks
    start = [start dateByAddingYears:0 months:0 days:(amount * 7)
		   hours:0 minutes:0 seconds:0];
    end   = [end   dateByAddingYears:0 months:0 days:(amount * 7)
		   hours:0 minutes:0 seconds:0];
    break;
  case 2: // months
    start = [start dateByAddingYears:0 months:amount days:0
		   hours:0 minutes:0 seconds:0];
    end   = [end   dateByAddingYears:0 months:amount days:0
		   hours:0 minutes:0 seconds:0];
    break;

  default:
    [self setErrorString:[l valueForKey:@"error_invalidMoveAmount"]];
    return nil;
  }
  [appointment takeValue:start forKey:@"startDate"];
  [appointment takeValue:end   forKey:@"endDate"];

  {
    OGoContentPage *page;
      
    [appointment takeValue:oldStart forKey:@"oldStartDate"];
    page = [self saveAndGoBackWithCount:2 action:@"moved"];
    if ([page isKindOfClass:NSClassFromString(@"SkySchedulerConflictPage")])
      return page;
  }

  /* mail section ... */
  
  if ([self isMailEnabled]) {
    if ([[self navigation] activePage] != self) {
      id<LSWMailEditorComponent, OGoContentPage> mailEditor;
      
      [[self object] takeValue:oldStart forKey:@"oldStartDate"];
      
      mailEditor = [NSClassFromString(@"OGoAptMailOpener")
				     mailEditorForObject:[self object]
				     action:@"moved"
				     page:self];
      if (mailEditor != nil)
	[self enterPage:mailEditor];
      return nil; /* TODO: hm, even if we have no mail editor? */
    }
    
    [self enterPage:self];
    [appointment takeValue:oldStart forKey:@"startDate"];
    [appointment takeValue:oldEnd   forKey:@"endDate"];
  }
  return nil;
}

- (id)saveAllCyclic {
  NSArray  *cyclics;
  NSNumber *pId;
  
  [[self snapshot] takeValue:yesNum forKey:@"setAllCyclic"];

  if ((pId = [[self object] valueForKey:@"parentDateId"])) {
    NSMutableArray *c;
    id             firstCyclic;

    c           = [NSMutableArray array];
    firstCyclic = [self _fetchAppointmentForPrimaryKey:pId];
    [c addObject:firstCyclic];
    [c addObjectsFromArray:
           [self _fetchCyclicAppointmentsOfAppointment:firstCyclic]];
    cyclics = c;
  }
  else {
    cyclics = [self _fetchCyclicAppointmentsOfAppointment:[self object]];
  }
  [[self snapshot] takeValue:cyclics forKey:@"cyclics"];

  return [self saveAndGoBackWithCount:2];
}

- (id)deleteAllCyclic {
  self->aeFlags.deleteAllCyclic = 1;
  return [self delete];
}

- (id)appointmentProposal {
  NSMutableArray *r;
  NSCalendarDate *start, *end;
  NSString       *tzs;
  NSEnumerator   *enumerator;
  id             ct, obj, sn;
  int            hour = 11, minute = 0;
  NSString       *s;

  sn         = [self snapshot];
  ct         = [[self session] instantiateComponentForCommand:@"proposal"
                               type:eoDateType];
  r          = [[NSMutableArray alloc] init];
  enumerator = [self->resources objectEnumerator];
  
  while ((obj = [enumerator nextObject])) {
    id n;
    
    if ((n = [obj valueForKey:@"name"]) != nil)
      [r addObject:n];
  }
  
  tzs = [self defaultTimeZone];
  
  // TODO: replace that junk with something better!
  if (![self scanTo24HourTime:self->startTime hour:&hour minute:&minute]) {
    hour = 11; 
    minute = 0;
  }
  s = [NSString stringWithFormat:@"%@ %02i:%02i:00 %@",
		  [self startDate], hour, minute, tzs];
  start = [NSCalendarDate dateWithString:s
                          calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  
  if (![self scanTo24HourTime:self->endTime hour:&hour minute:&minute]) {
    hour   += 1;
    minute = 0;
  }
  s = [NSString stringWithFormat:@"%@ %02i:%02i:00 %@",
		  [self endDate], hour, minute, tzs];
  end = [NSCalendarDate dateWithString:s
                        calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  
  [r removeObject:@""];
  [sn takeValue:self->participants forKey:@"participants"];
  [sn takeValue:r                  forKey:@"resources"];
  [ct takeValue:sn                 forKey:@"appointment"];
  [ct takeValue:self               forKey:@"editor"];
  [ct takeValue:start              forKey:@"startDate"];
  [ct takeValue:end                forKey:@"endDate"];
  [ct takeValue:self->resources    forKey:@"resources"];
  [ct takeValue:self->participants forKey:@"participants"];
  
  [self enterPage:ct];
  [r release]; r = nil;
  return nil;
}

/* PrivateMethodes */

- (void)_updateParticipantList:(NSArray *)_list {
  NSEnumerator *partEnum;
  id           part;
  
  partEnum =  [_list objectEnumerator];
  while ((part = [partEnum nextObject]))
    [self _setLabelForParticipant:part];
}

- (NSString *)_labelForTeamEO:(id)_t {
  return [@"Team: " stringByAppendingString:[_t valueForKey:@"description"]];
}
- (NSString *)_labelForPersonEO:(id)p {
  NSString *d, *fd;
  
  if ((d = [p valueForKey:@"name"]) == nil)
    return [p valueForKey:@"login"];
  
  if ((fd = [p valueForKey:@"firstname"]) != nil) {
    d = [[d stringValue] stringByAppendingString:@", "];
    d = [d stringByAppendingString:[fd stringValue]];
  }
  return d;
}

- (void)_setLabelForParticipant:(id)_part {
  NSString *d;
  
  d = [[_part valueForKey:@"isTeam"] boolValue]
    ? [self _labelForTeamEO:_part]
    : [self _labelForPersonEO:_part];
  
  // TODO: doesn't look too good?
  [_part takeValue:d forKey:@"participantLabel"];
}

- (void)setMoreResources:(NSArray *)_res {
  ASSIGN(self->moreResources, _res);
}
- (NSArray *)moreResources {
  return self->moreResources;
}

/* extended apt attributes (properties) */

- (BOOL)showProperties {
  return [extAttrSpec isNotEmpty];
}
- (NSArray *)extendedAttributeSpec {
  return extAttrSpec;
}

- (NSMutableDictionary *)extendedAttributes {
  if (self->extendedAttributes == nil) {
    self->extendedAttributes =
      [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  return self->extendedAttributes;
}

@end /* LSWAppointmentEditor */


@implementation WOComponent(PageConstructors)

- (WOComponent *)conflictPageWithDataSource:(id)_ds
  timeZone:(NSTimeZone *)_tz
  action:(NSString *)_action mailOpener:(OGoAptMailOpener *)_opener
{
  WOComponent *page;
  
  page = [self pageWithName:@"SkySchedulerConflictPage"];
  [page takeValue:_ds forKey:@"dataSource"];
  [page takeValue:_tz forKey:@"timeZone"];
  
  if (_action == nil)
    return page;
  
  [page takeValue:_action forKey:@"action"];
  [page takeValue:yesNum  forKey:@"sendMail"];
  [page takeValue:_opener forKey:@"mailOpener"];
  
  return page;
}

@end /* WOComponent(PageConstructors) */
