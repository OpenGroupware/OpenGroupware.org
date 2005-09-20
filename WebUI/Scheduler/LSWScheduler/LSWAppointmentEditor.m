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
#include <OGoScheduler/SkySchedulerConflictDataSource.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include "OGoRecurrenceFormatter.h"

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
- (BOOL)shouldAttachAppointmentsToMails;
- (NSString *)_personName:(id)_person;

- (NSDictionary *)templateBindingsForAppointment:(id)obj;

@end

@interface LSWEditorPage(MailEditorPage)

- (void)setIsAppointmentNotification:(BOOL)_flag;

@end /* LSWEditorPage(MailEditorPage) */

@interface NSCalendarDate(CycleDateAdder)

- (NSCalendarDate *)dateByAddingValue:(int)_i inUnit:(NSString *)_unit;

@end

@interface WOComponent(PageConstructors)

- (WOComponent *)conflictPageWithDataSource:(id)_ds
  timeZone:(NSTimeZone *)_tz
  action:(NSString *)_action mailContent:(NSString *)_s;

@end

@implementation LSWAppointmentEditor

+ (int)version {
  return [super version] + 2 /* v?? */;
}

static NSString   *AllIntranetTeamName = @"all intranet";
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

    if ([bm bundleProvidingResource:@"LSWImapMailEditor"
            ofType:@"WOComponents"] != nil)
      self->aeFlags.isMailEnabled = 1;
    
    self->aeFlags.isAllDayEvent      = 0;
    self->aeFlags.isAllDayEventSetup = 0;
  }
  return self;
}

- (void)dealloc {
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
  
  [self setSelectedParticipants:
        (self->participants != nil) ? self->participants : [NSArray array]];
  
  [self _fetchEnterprisesOfPersons:self->participants];
  
  /* prepare resources */ // TODO: explain those! (how can they be filled?)
  [self->resources     removeAllObjects];
  [self->accessMembers removeAllObjects];
  return YES;
}

/* "edit" activation */

- (BOOL)_checkEditActivationPreconditions {
  id appointment;

  if ((appointment = [self object]) == nil) {
    [self logWithFormat:@"ERROR: got no object for edit-activation!"];
    return NO;
  }
  if (self->comment != nil || self->selectedAccessTeam != nil) {
    [self logWithFormat:@"ERROR: editor object is mixed up!"];
    return NO;
  }
  if (self->participants == nil) {
    [self logWithFormat:@"ERROR: participants array is not setup!"];
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
  [self setSelectedParticipants:
        [self->participants isNotNull] ? self->participants : [NSArray array]];
  
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
  
  return YES;
}

- (NSString *)defaultWriteAccessList {
  NSMutableArray *wa;
  NSString *list;
  
  wa = [[self defaultWriteAccessAccounts] mutableCopy];
  [wa addObjectsFromArray:[self defaultWriteAccessTeams]];
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
  while ((objId = [enumerator nextObject])) {
    id res;
    
    if ((res = [self _fetchAccountOrTeamForPrimaryKey:objId]))
      [self->accessMembers addObject:res];
  }
}

- (void)_setSelectedAccessTeamToAllIntranetInArray:(NSArray *)_teams {
  /* 
     searches the accessTeams array for all-intranet and sets that as the 
     selected team 
  */
  int i, cnt;
  
  for (i = 0, cnt = [_teams count]; i < cnt; i++) {
    id t;
    
    t = [_teams objectAtIndex:i];
    if ([[t valueForKey:@"login"] isEqualToString:AllIntranetTeamName]) {
      ASSIGN(self->selectedAccessTeam, t);
      break;
    }
  }
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
  
  if ([self isInNewMode])
    [self _setSelectedAccessTeamToAllIntranetInArray:self->accessTeams];
  
  [self _setupStartDate:[snp valueForKey:@"startDate"]
        andEndDate:[snp valueForKey:@"endDate"]];
  
  /* write access accounts */
    
  [self->accessMembers removeAllObjects];
  list = [self isInNewMode]
    ? [self defaultWriteAccessList]
    : [appointment valueForKey:@"writeAccessList"];
      
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
  return ([self->resources count] == 0)
    ? (id)null
    : [self->resources componentsJoinedByString:@", "];
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
  
  return [NSString stringWithFormat:@"%@, %@", day,
                     [date descriptionWithCalendarFormat:DayLabelDateFmt]];
}

/* default accessors */

- (BOOL)shouldAttachAppointmentsToMails {
  id val;
  
  val = [self->defaults valueForKey:@"scheduler_attach_apts_to_mails"];
  if (val == nil) return YES;
  return [val boolValue];
}

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
  [[self snapshot] setObject:(_type ? _type : (id)null) forKey:@"type"];
}
- (NSString *)appointmentType {
  return [[self snapshot] objectForKey:@"type"];
}

- (NSString *)unitLabel {
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
    [self logWithFormat:
            @"WARNING[%s:%d]: couldn`t associate all resource names %@ %@",
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
  return YES;
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

- (NSString *)cycleType {
  NSString *t;
  
  if ((t = [[self snapshot] valueForKey:@"type"]) == nil)
    return nil;
  
  if ([t hasPrefix:@"RRULE:"]) {
    // TODO: add a rrule formatter
    return [t substringFromIndex:6];
  }
  
  return [[self labels] valueForKey:t];
}

- (NSString *)timeInputType {
  return self->timeInputType;
}  
- (BOOL)isTimeInputPopUp {
  return [self->timeInputType isEqualToString:@"PopUp"] ? YES : NO;
}

/* actions */

- (unsigned)countCyclesWithStartDate:(NSCalendarDate *)_start
  type:(NSString *)_type
  cycleEndDate:(NSCalendarDate *)_cycleDate
{
  int  cnt, i;
  BOOL cycleEnd, isWeekend;

  cnt       = 0;
  i         = 0;
  cycleEnd  = NO;
  isWeekend = NO;
  
  while (!cycleEnd) {
    NSCalendarDate *newStartDate;

    newStartDate = [_start dateByAddingValue:i inUnit:_type];
    
    if ([newStartDate compare:_cycleDate] == NSOrderedAscending) {
      if ([_type isEqual:@"weekday"]) {
        int day;
        
        day = [newStartDate dayOfWeek];
        isWeekend = (day > 0 && day < 6) ? NO : YES;
      }
      
      if (!isWeekend)
        cnt++;
      i++;
    }
    else {
      cycleEnd = YES;
    }
#if 0 // hh asks: why is this commented out?
    if (cnt > 100) { 
      cycleEnd = YES;
    }
#endif
  }
  return cnt;
}

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

  if ([[self errorString] isNotEmpty]) return YES;  
  
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
    return YES;
  }
  
  {
    NSCalendarDate *d;

    d = [appointment valueForKey:@"endDate"];      
    d = [d hour:hours minute:minutes];
    
    if (d != nil)
      [appointment takeValue:d forKey:@"endDate"];
  }
  
  if ([type isNotNull]) {
    NSCalendarDate *cDate;
    unsigned       cycleCnt, maxCycles;
    
    cDate     = [appointment valueForKey:@"cycleEndDate"];
    maxCycles = [self maxAppointmentCycles];
    
    if (![cDate isNotNull]) {
      [error appendString:[l valueForKey:@"error_noCycleEndDate"]];
    }
    else {
      cycleCnt = [self countCyclesWithStartDate:
			 [appointment valueForKey:@"startDate"]
		       type:type cycleEndDate:cDate];
      if (cycleCnt > maxCycles) {
	NSString *s;

	s = [NSString stringWithFormat:
			[l valueForKey:@"error_toManyCyclics"], cycleCnt];
	[error appendString:s];
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

- (NSString *)ccForNotificationMails {
  return [[self userDefaults]
	        objectForKey:@"scheduler_ccForNotificationMails"];
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

- (NSString *)mailTemplate {
  return [[self userDefaults] stringForKey:@"scheduler_mail_template"];
}
- (NSString *)mailTemplateDateFormat {
  return [[self userDefaults] 
	        stringForKey:@"scheduler_mail_template_date_format"];
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
  NSMutableString *accessList;
  NSEnumerator    *enumerator;
  id              obj;
  BOOL            isFirst;
  
  if ([self->selectedAccessMembers count] == 0)
    return nil;

  isFirst    = YES;
  accessList = [NSMutableString stringWithCapacity:128];
  enumerator = [self->selectedAccessMembers objectEnumerator];

  while ((obj = [enumerator nextObject])) {
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
  NSString *accessList;
  id       apmt;
  
  apmt = [self snapshot];
  
  /* write access rights */
  
  if ((accessList = [self _accessList]) != nil)
    [apmt takeValue:accessList forKey:@"writeAccessList"];
  
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

- (NSString *)mailContentForAppointment:(id)_appointmentOrSnapshot {
  NSString *s;
  
  if (_appointmentOrSnapshot == nil)
    return nil;
  
  s = [self mailTemplate];
  if (![s isNotNull])
    return @"";
  
  s = [s stringByReplacingVariablesWithBindings:
           [self templateBindingsForAppointment:_appointmentOrSnapshot]
         stringForUnknownBindings:@""];
  return s;
}

- (id)_handleConflictsInConflictDS:(SkySchedulerConflictDataSource *)_ds 
  action:(NSString *)_action
{
  NSString *s;
  
  [self _correctSnapshotTimeZone];
  [[[_ds appointment] valueForKey:@"startDate"] setTimeZone:self->timeZone];
  [[[_ds appointment] valueForKey:@"endDate"]   setTimeZone:self->timeZone];
  
  s = (_action)
    ? [self mailContentForAppointment:[self snapshot]]
    : @"";
  
  return [self conflictPageWithDataSource:_ds timeZone:self->timeZone
               action:_action mailContent:s];
}

- (id)saveAndGoBackWithCount:(int)_backCount action:(NSString *)_action {
  SkySchedulerConflictDataSource *ds;
  
  if (![self checkConstraintsForSave]) {
    // TODO: place after parseSnapshotValues??
    [self debugWithFormat:@"save constraint check failed"];
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
  if ([[ds fetchObjects] isNotEmpty])
    return [self _handleConflictsInConflictDS:ds action:_action];

  [self logWithFormat:@"NO CONFLICTS, GO ON .."];
  
  /* return */
  
  [self _correctSnapshotTimeZone]; // again?
  return [super saveAndGoBackWithCount:_backCount]; // call into LSWEditorPage
}

- (id)saveAndGoBackWithCount:(int)_backCount {
  return [self saveAndGoBackWithCount:_backCount action:nil];
}

- (id)insertObject {
  /* called by -_performOpInTransaction: */
#if 1
  return [self runCommand:@"appointment::new" arguments:[self snapshot]];
#else // moved to snapshot
  NSMutableDictionary *args;
  
  // Note: this code is in here because the 'snapshot' is used in other
  //       contexts and the 'reduced' participants hurt in such case
  // TODO: better enumerate all transfered keys in the command call?
  args = [[[self snapshot] mutableCopy] autorelease];
  [args setObject:[self participantsInfoChanges:self->selectedParticipants]
        forKey:@"participants"];  
  return [self runCommand:@"appointment::new" arguments:args];
#endif
}

- (id)updateObject {
  /* called by -_performOpInTransaction: */
#if 1
  return [self runCommand:@"appointment::set" arguments:[self snapshot]];
#else // moved to snapshot
  NSMutableDictionary *args;
  
  args = [[[self snapshot] mutableCopy] autorelease];
  [args setObject:[self participantsInfoChanges:self->selectedParticipants]
        forKey:@"participants"];  
  return [self runCommand:@"appointment::set" arguments:args];
#endif
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
    ? nil
    : [[self recurrenceFormatter] stringForObjectValue:[self snapshot]];
  
  if ([s isNotEmpty]) {
    [ms appendString:@" ("];
    [ms appendString:s];
    [ms appendString:@")"];
  }
  return ms;
}

- (NSString *)appointmentRemovedSubjectWithTitle:(NSString *)_title {
  NSMutableString *ms;
  id l;
  
  l = [self labels];
  ms = [NSMutableString stringWithCapacity:80];
  [ms appendString:[l valueForKey:@"appointment"]];
  [ms appendString:@": '"];
  [ms appendString:_title];
  [ms appendString:@"' "];
  [ms appendString:[l valueForKey:@"removed"]];
  return ms;
}

- (id)reallyDelete {
  id<LSWMailEditorComponent, OGoContentPage> mailEditor;
  NSArray      *ps;
  NSString     *title, *cc, *tmp;
  NGMimeType   *t;
  NSEnumerator *recEn;
  id           rec;
  BOOL         first;
  BOOL         attach;
  id obj;
  id l;

  l = [self labels];
  
  [self deleteAndGoBackWithCount:2];
  
  if (![self isMailEnabled])
    return nil;
  
  if ([[self navigation] activePage] == self)
    return nil;

  obj        = [self object];
  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
    
  if (mailEditor == nil)
    return nil;
  
  ps    = self->participants; 
  title = [[self object] valueForKey:@"title"];

  /* set default cc */
  cc = [self ccForNotificationMails];
  if (cc) [mailEditor addReceiver:cc type:@"cc"];
  
  t      = eoDateType;
  attach = [self shouldAttachAppointmentsToMails];
  [mailEditor addAttachment:obj type:t sendObject:(attach ? yesNum : noNum)];
  
  tmp = [self appointmentRemovedSubjectWithTitle:title];
  [mailEditor setSubject:tmp];
  [mailEditor setContentWithoutSign:[self mailContentForAppointment:obj]];
  
  recEn = [ps objectEnumerator];
  first = YES;
          
  while ((rec = [recEn nextObject])) {
    if (first) {
      [mailEditor addReceiver:rec];
      first = NO;
    }
    else 
      [mailEditor addReceiver:rec type:@"cc"];
  }
  return mailEditor;
}

- (NSException *)handleMailTemplateException:(NSException *)_exception {
  [self logWithFormat:
          @"WARNING: exception during mail-template evaluation: %@",
          _exception];
  return nil;
}

- (void)_addParticipants:(NSArray *)_ps toMailEditor:(id)mailEditor {
  NSEnumerator *recEn;
  id           rec;
  BOOL         first;
  
  recEn = [_ps objectEnumerator];
  first = YES;
          
  while ((rec = [recEn nextObject])) {
    if (first) {
      [mailEditor addReceiver:rec];
      first = NO;
    }
    else 
      [mailEditor addReceiver:rec type:@"cc"];
  }
}

- (id)saveAndSendMail {
  /* TODO: this method is *far* too long, split it up! */
  NSArray    *ps;
  NSString   *str, *title, *template;
  NSString   *cc;
  id         obj;
  id         mailEditor;
  id         page, l;
  NGMimeType *t;
  BOOL       attach;
  
  l    = [self labels];
  page = [self saveAndGoBackWithCount:1
               action:([self isInNewMode] ? @"created" : @"edited")];
  
  /* if the save resulted in a conflict, we enter the conflict page */
  if ([page isKindOfClass:NSClassFromString(@"SkySchedulerConflictPage")])
    return page;
  
  if (![self isMailEnabled]) {
    [self logWithFormat:
            @"WARNING: mail is not enabled, not entering the editor .."];
    return nil;
  }
  if ([[self navigation] activePage] == self) {
    [self logWithFormat:@"staying on editor page (active-page==self)"];
    [self logWithFormat:@"  active-page: %@",[[self navigation] activePage]];
    [self logWithFormat:@"  page:        %@", page];
    return nil;
  }
  if ((mailEditor = [self pageWithName:@"LSWImapMailEditor"]) == nil) {
    [self logWithFormat:@"WARNING: could not instantiate mail editor!"];
    return nil;
  }
  
  /*
    Undoing changes is currently only possible if we're
    in new mode, not while being in edit mode, because
    then we have to restore an earlier state and so we just
    delete the unneeded appointment. Maybe later.
  */
      
  if ([self isInNewMode])
    [mailEditor setIsAppointmentNotification:YES];

  /* fetch object, configure editor */
  
  obj   = [self object];
  title = [obj valueForKey:@"title"];
  
  ps = [self _fetchParticipantsOfAppointment:obj force:YES];
  [self setParticipants:ps];

  /* set default cc */
  
  cc = [self ccForNotificationMails];
  if (cc) [mailEditor addReceiver:cc type:@"cc"];

  /* set subject */
  
  str = [self isInNewMode] ? @"created" : @"edited";
  str = [[NSString alloc] initWithFormat:@"%@: '%@' %@",
                            [l valueForKey:@"appointment"], 
                            title,
                            [l valueForKey:str]];
  [mailEditor setSubject:str];
  [str release]; str = nil;

  /* setup mail template */
  
  template = [self mailTemplate];
  if ([template isNotNull]) {
    [self setErrorString:nil];
    NS_DURING {
      template = [template stringByReplacingVariablesWithBindings:
			     [self templateBindingsForAppointment:obj]
			   stringForUnknownBindings:@""];
    }
    NS_HANDLER
      [[self handleMailTemplateException:localException] raise];
    NS_ENDHANDLER;
  }
  else
    template = @"";
  
  [mailEditor setContentWithoutSign:template];
  
  t      = eoDateType;
  attach = [self shouldAttachAppointmentsToMails];
  if (!attach) {
    str = [template stringByTrimmingWhiteSpaces];
    [mailEditor addAttachment:obj type:t
                sendObject:[str length] > 0 ? noNum : yesNum];
  }
  else 
    [mailEditor addAttachment:obj type:t];
  
  [self _addParticipants:ps toMailEditor:mailEditor];
  [self debugWithFormat:@"returning mail editor: %@", mailEditor];
  
  /* the following is required for no known reason (OGo Bug #1!) */
  [[self navigation] enterPage:mailEditor];
  return mailEditor;
}

- (id)moveAppointment {
  id l;

  l = [self labels];
  
  if (self->moveAmount == 0) {
    // not to be moved, stay on page
    [self setErrorString:
          [[self labels] valueForKey:@"error_specifyMoveAmount"]];
    return nil;
  }
  else {
    NSMutableDictionary *appointment;
    NSCalendarDate      *start, *end, *oldStart, *oldEnd;
    int                 amount;

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
      id page;
      
      [appointment takeValue:oldStart forKey:@"oldStartDate"];
      page = [self saveAndGoBackWithCount:2 action:@"moved"];
      if ([page isKindOfClass:NSClassFromString(@"SkySchedulerConflictPage")])
        return page;
    }
    if ([self isMailEnabled]) {
      if ([[self navigation] activePage] != self) {
        id<LSWMailEditorComponent, OGoContentPage> mailEditor;

        mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];

        if (mailEditor) {
          NSArray  *ps;
          NSString *title, *s;

          ps    = self->participants; 
          title = [[self object] valueForKey:@"title"];

          [[self object] takeValue:oldStart forKey:@"oldStartDate"];

          { // set default cc
            NSString *cc;

            if ((cc = [self ccForNotificationMails]))
              [mailEditor addReceiver:cc type:@"cc"];
          }
	  s = [[NSString alloc] initWithFormat:@"%@: '%@' %@",
				  [l valueForKey:@"appointment"],
				  title,
				  [l valueForKey:@"moved"]];
          [mailEditor setSubject:s];
	  [s release]; s = nil;
          {
            NGMimeType *t;
            BOOL       attach;

            t      = [NGMimeType mimeType:@"eo" subType:@"date"];
            attach = [self shouldAttachAppointmentsToMails];
            [mailEditor addAttachment:[self object] type:t
                        sendObject:(attach ? yesNum : noNum)];
          }
            
          s = [self mailContentForAppointment:[self object]];
          [mailEditor setContentWithoutSign:s];
          
          {
            NSEnumerator *recEn;
            id           rec;  
            BOOL         first;

            recEn = [ps objectEnumerator];
            first = YES;
            
            while ((rec = [recEn nextObject])) {
              if (first) {
                [mailEditor addReceiver:rec];
                first = NO;
              }
              else 
                [mailEditor addReceiver:rec type:@"cc"];
            }
          }
          [self enterPage:mailEditor];
        }
        return nil;
      }
      [self enterPage:self];
      [appointment takeValue:oldStart forKey:@"startDate"];
      [appointment takeValue:oldEnd forKey:@"endDate"];
    }
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
                               type:[NGMimeType mimeType:@"eo/date"]];  
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
    hour+= 1; minute = 0;
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
  
  if ((fd = [p valueForKey:@"firstname"]))
    d = [NSString stringWithFormat:@"%@, %@", d, fd];
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

- (NSString *)_personName:(id)_person {
  // TODO: this should be a formatter!
  NSString *n, *f;
  
  if (_person == nil)
    return @"";
  if ([[_person valueForKey:@"isTeam"] boolValue])
    return [_person valueForKey:@"description"];
  
  n = [_person valueForKey:@"name"];
  f = [_person valueForKey:@"firstname"];
  if ([n isNotNull] && [f isNotNull]) {
    NSMutableString *str;
    
    str = [NSMutableString stringWithCapacity:64];
    [str appendString:f];
    [str appendString:@" "];
    [str appendString:n];
    return str;
  }
  
  if ([n isNotNull]) return n;
  if ([f isNotNull]) return f;
  return @"";
}

- (NSString *)stringByJoiningParticipantNames:(NSArray *)_parts {
  NSEnumerator    *enumerator;
  id              part;
  NSMutableString *str;
  
  if (![_parts isNotNull]) return nil;
  
  str        = nil;
  enumerator = [_parts objectEnumerator];
  
  while ((part = [enumerator nextObject])) {
    if (str == nil)
      str = [NSMutableString stringWithCapacity:128];
    else
      [str appendString:@", "];
      
    [str appendString:[self _personName:part]];
  }
  return str;
}

- (NSDictionary *)templateBindingsForAppointment:(id)obj {
  /* TODO: move to method, split up */
  NSMutableDictionary *bindings;
  id                  c;
  NSString            *format, *title, *location, *resNames;
  NSCalendarDate      *sd, *ed;

  format = [self mailTemplateDateFormat];
  
  sd = [obj valueForKey:@"startDate"];
  if (format != nil && [sd isNotNull]) {
    [sd setCalendarFormat:format];
  }
  ed = [obj valueForKey:@"endDate"];
  if (format != nil && [ed isNotNull]) {
    [ed setCalendarFormat:format];
  }
  
  bindings = [NSMutableDictionary dictionaryWithCapacity:8];
  [bindings setObject:sd forKey:@"startDate"];
  [bindings setObject:ed forKey:@"endDate"];

  if ((title = [obj valueForKey:@"title"]))
    [bindings setObject:title forKey:@"title"];
  if ((location = [obj valueForKey:@"location"]))
    [bindings setObject:location forKey:@"location"];
  if ((resNames = [obj valueForKey:@"resourceNames"]))
    [bindings setObject:resNames forKey:@"resourceNames"];        
  if ((c = [self comment]))
    [bindings setObject:c forKey:@"comment"];
  else
    [bindings setObject:@"" forKey:@"comment"];
          
  /* set creator */
  
  c = [self _fetchAccountForPrimaryKey:[obj valueForKey:@"ownerId"]];
  [bindings setObject:[self _personName:c] forKey:@"creator"];
  
  { /* set participants */
    NSString *str;
    
    str = [self stringByJoiningParticipantNames:
                  [obj valueForKey:@"participants"]];
    if (str) [bindings setObject:str forKey:@"participants"];
  }
  return bindings;
}

@end /* LSWAppointmentEditor */


@implementation WOComponent(PageConstructors)

- (WOComponent *)conflictPageWithDataSource:(id)_ds
  timeZone:(NSTimeZone *)_tz
  action:(NSString *)_action mailContent:(NSString *)_s
{
  WOComponent *page;
  
  page = [self pageWithName:@"SkySchedulerConflictPage"];
  [page takeValue:_ds forKey:@"dataSource"];
  [page takeValue:_tz forKey:@"timeZone"];
  
  if (_action == nil)
    return page;
  
  [page takeValue:_action forKey:@"action"];
  [page takeValue:yesNum  forKey:@"sendMail"];
  [page takeValue:_s      forKey:@"mailContent"];
  
  return page;
}

@end /* WOComponent(PageConstructors) */
