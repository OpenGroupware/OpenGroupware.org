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
// $Id$

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSUserDefaults, NSTimeZone;
@class SkyHolidayCalculator;

@interface LSWAppointmentMove : LSWEditorPage
{
@private
  id             item;       // non-retained
  BOOL           isMailEnabled;
  
  NSUserDefaults *defaults;
  
  NSTimeZone     *timeZone;
  
  // move fields
  char moveAmount;
  NSString *moveUnit; 
  char moveDirection; // 0=forward, 1=backward

  SkyHolidayCalculator *holidays;
}

// move accessors

- (void)setMoveAmount:(char)_amount;
- (char)moveAmount;
- (void)setMoveUnit:(NSString *)_unit;
- (NSString *)moveUnit;
- (void)setMoveDirection:(char)_direction;
- (char)moveDirection;

@end /* LSWAppointmentMove */

#include "common.h"
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/LSWNavigation.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGMime/NGMimeType.h>
#include "OGoScheduler/SkySchedulerConflictDataSource.h"
#include <WEExtensions/WEClientCapabilities.h>
#include <NGExtensions/NSCalendarDate+misc.h>

#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoScheduler/SkyHolidayCalculator.h>

@interface NSCalendarDate(UnitAdder)
- (NSCalendarDate *)dateByAddingValue:(int)_i inUnit:(NSString *)_unit;
@end

@implementation LSWAppointmentMove

+ (int)version {
  return [super version] + 2;
}

static BOOL       hasLSWImapMailEditor = NO;
static NSArray    *idxArray2 = nil;
static NSArray    *idxArray3 = nil;
static NGMimeType *eoDateType = nil;
static NSDictionary *_bindingForAppointment(id self, id obj);

+ (void)initialize {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  
  if (eoDateType == nil)
    eoDateType = [[NGMimeType mimeType:@"eo" subType:@"date"] retain];
  
  if (idxArray2 == nil) {
    idxArray2 = [[NSArray alloc] initWithObjects:
                                   [NSNumber numberWithInt:0],
                                   [NSNumber numberWithInt:1],
                                   nil];
  }
  if (idxArray3 == nil) {
    idxArray3 = [[NSArray alloc] initWithObjects:
                                   [NSNumber numberWithInt:0],
                                   [NSNumber numberWithInt:1],
                                   [NSNumber numberWithInt:2],
                                   nil];
  }

  hasLSWImapMailEditor = [bm bundleProvidingResource:@"LSWImapMailEditor"
			     ofType:@"WOComponents"] ? YES : NO;
}

- (id)init {
  if ((self = [super init])) {
    self->defaults      = [[[self session] userDefaults] retain];
    self->isMailEnabled = hasLSWImapMailEditor;
  }
  return self;
}

- (void)dealloc {
  [self->item     release];
  [self->timeZone release];
  [self->defaults release];
  [self->moveUnit release];
  [super dealloc];
}

/* clearing */

- (void)clearEditor {
  [self->timeZone release]; self->timeZone = nil;
  [super clearEditor];
}

- (SkyHolidayCalculator *)holidays {
  if (self->holidays == nil) {
    int year = [[[self object] valueForKey:@"startDate"] yearOfCommonEra];
    self->holidays =
      [[SkyHolidayCalculator calculatorWithYear:year
                             timeZone:self->timeZone
                             userDefaults:[[self session] userDefaults]]
                             retain];
  }
  return self->holidays;
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSArray *ps;
  id appointment = [self object];
  id comment;

  NSAssert(appointment, @"no object available");

  ps = [appointment valueForKey:@"participants"];
  if (ps == nil) {
    [self runCommand:@"appointment::get-participants",
          @"appointment", appointment,
          nil];
    ps = [appointment valueForKey:@"participants"];
  }
  [[self snapshot] takeValue:ps forKey:@"participants"];
  NSAssert([ps count], @"no participants available");

  comment = [appointment valueForKey:@"comment"];
  if (comment == nil) {
    comment =
      [[[appointment valueForKey:@"toDateInfo"] valueForKey:@"comment"] copy];
  }
  if (comment)
    [[self snapshot] takeValue:comment forKey:@"comment"];

  // timezone
  self->timeZone = [[[appointment valueForKey:@"startDate"] timeZone] retain];
  
  return YES;
}

/* notifications */

- (void)syncSleep {
  // reset transient variables
  self->item       = nil;
  
  [[[self session] userDefaults] synchronize];  
  [super syncSleep];
}

/* accessors */

- (id)appointment {
  return [self snapshot];
}
- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}
- (NSString *)unitLabel {
  return [[self labels] valueForKey:item];
}

- (NSString *)moveAppointmentLabel {
  return [NSString stringWithFormat:@"%@ '%@'",
                   [[self labels] valueForKey:@"moveAppointment"],
                   [[self appointment] valueForKey:@"title"]];
}

- (BOOL)isMailEnabled {
  return self->isMailEnabled;
}

- (BOOL)isMailLicensed {
  return YES;
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

- (void)setMoveUnit:(NSString *)_unit {
  ASSIGN(self->moveUnit,_unit);
}
- (NSString *)moveUnit {
  return self->moveUnit;
}
- (NSString *)moveUnitLabel {
  return [[self labels]
                valueForKey:
                [NSString stringWithFormat:@"move_unit_%@", self->item]];
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

/* notifications */

- (NSString *)insertNotificationName {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyNewAppointmentNotification object:nil];

  return LSWNewAppointmentNotificationName;
}
- (NSString *)updateNotificationName {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyUpdatedAppointmentNotification object:nil];

  return LSWUpdatedAppointmentNotificationName;
}
- (NSString *)deleteNotificationName {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyDeletedAppointmentNotification object:nil];

  return LSWDeletedAppointmentNotificationName;
}

/* actions */

- (NSDictionary *)conflictCheckApt {
  NSMutableDictionary *md;
  id apt;
  id tmp;
  
  apt = [self snapshot];
  md  = [NSMutableDictionary dictionaryWithCapacity:14];
  if ((tmp = [apt valueForKey:@"newStartDate"]))
    [md setObject:tmp forKey:@"startDate"];
  if ((tmp = [apt valueForKey:@"newEndDate"]))
    [md setObject:tmp forKey:@"endDate"];
  if ((tmp = [apt valueForKey:@"type"]))
    [md setObject:tmp forKey:@"type"];
  if ((tmp = [apt valueForKey:@"cycleEndDate"]))
    [md setObject:tmp forKey:@"cycleEndDate"];
  if ((tmp = [apt valueForKey:@"dateId"]))
    [md setObject:tmp forKey:@"dateId"];
  if ((tmp = [apt valueForKey:@"setAllCyclic"]))
    [md setObject:tmp forKey:@"setAllCyclic"];
  if ((tmp = [apt valueForKey:@"cycles"]))
    [md setObject:tmp forKey:@"cycles"];
  if ((tmp = [apt valueForKey:@"isConflictDisabled"]))
    [md setObject:tmp forKey:@"isConflictDisabled"];
  if ((tmp = [apt valueForKey:@"isWarningIgnored"]))
    [md setObject:tmp forKey:@"isWarningIgnored"];
  if ((tmp = [apt valueForKey:@"resourceNames"]))
    [md setObject:tmp forKey:@"resourceNames"];
  if ((tmp = [apt valueForKey:@"participants"]))
    [md setObject:tmp forKey:@"participants"];
  if ((tmp = [apt valueForKey:@"title"]))
    [md setObject:tmp forKey:@"title"];
  if ((tmp = [apt valueForKey:@"location"]))
    [md setObject:tmp forKey:@"location"];
  return md;
}

- (id)_pageForConflictsInDataSource:(SkySchedulerConflictDataSource *)ds 
  action:(NSString *)_action
{
  WOComponent *page;
  NSString    *template;
    
  page = [self pageWithName:@"SkySchedulerConflictPage"];
  [page takeValue:ds forKey:@"dataSource"];
  
  if (_action == nil)
    return page;

  [page takeValue:_action forKey:@"action"];
  [page takeValue:[NSNumber numberWithBool:YES] forKey:@"sendMail"];

  template = [self->defaults valueForKey:@"scheduler_mail_template"];

  if ([template isNotNull]) {
	    NSString *s;
	    
	    s = [template stringByReplacingVariablesWithBindings:
			    _bindingForAppointment(self, [self snapshot])
			  stringForUnknownBindings:@""];
            [page takeValue:s forKey:@"mailContent"];
  }
  else {
    [page takeValue:@"" forKey:@"mailContent"];
  }
  return page;
}

- (id)saveAndGoBackWithCount:(int)_backCount action:(NSString *)_action {
  // TODO: cleanup!
  /* checking conflicts */
  SkySchedulerConflictDataSource *ds;
  NSUserDefaults                 *ud;
  Class                          c;
  EODataSource                   *pds;
  
  ud = [[self session] userDefaults];
  ds = [[[SkySchedulerConflictDataSource alloc] init] autorelease];
  [ds setContext:[(id)[self session] commandContext]];
  [ds setAppointment:[self conflictCheckApt]];
  
  // add a palmdatedatasource to also check for conflicting palm dates
  if ([[ud valueForKey:@"scheduler_show_palm_dates"] boolValue]) {
    if ((c = NSClassFromString(@"SkyPalmDateDataSource"))) {
      // TODO: fix type casts
      pds = [(SkyAccessManager *)[c alloc] initWithContext:
				   (id)[[self session] commandContext]];
      [ds addDataSource:pds];
      [pds release];
    }
    else
      [self debugWithFormat:@"Note: missing SkyPalmDateDataSource"];
  }
  
  if ([ds hasConflicts])
    [self _pageForConflictsInDataSource:ds action:_action];
  
  return [super saveAndGoBackWithCount:_backCount];
}

- (id)saveAndGoBackWithCount:(int)_backCount {
  return [self saveAndGoBackWithCount:_backCount action:nil];
}

- (id)updateObject {
  return [self runCommand:@"appointment::move" arguments:[self snapshot]];
}

- (NSCalendarDate *)_moveDate:(NSCalendarDate *)_date
  forUnit:(NSString *)_unit
  amount:(int)_amount
{
  return [_date dateByAddingValue:_amount inUnit:_unit];
}

- (id)moveAppointment {
  // TODO: cleanup this huge method
  // TODO: might be duplicate code for templates?
  NSMutableDictionary *appointment;
  NSCalendarDate      *start, *end, *oldStart, *oldEnd;
  int                 amount;
  
  if (self->moveAmount == 0) {
    // not to be moved, stay on page
    [self setErrorString:@"Specify move amount."];
    return nil;
  }

  appointment = [self snapshot];
  start    = [[self object] valueForKey:@"startDate"];
  end      = [[self object] valueForKey:@"endDate"];
  oldStart = [[start copy] autorelease]; 
  oldEnd   = [[end   copy] autorelease];
  amount   = self->moveAmount;

  if (self->moveDirection != 0) // backward (1)
    amount = -amount;

  [self setErrorString:nil];

  start = [self _moveDate:start forUnit:self->moveUnit amount:amount];
  end   = [self _moveDate:end   forUnit:self->moveUnit amount:amount];

  [appointment takeValue:start forKey:@"newStartDate"];
  [appointment takeValue:end   forKey:@"newEndDate"];
  {
      OGoContentPage *page;
      
      [appointment takeValue:oldStart forKey:@"oldStartDate"];
      page = [self saveAndGoBackWithCount:2 action:@"moved"];
      if ([page isKindOfClass:NSClassFromString(@"SkySchedulerConflictPage")])
        return page;
  }

  if (![self isMailEnabled])
    // TODO: is this correct, shouldn't that return leavePage?
    return nil;
  
  if ([[self navigation] activePage] == self) {
    [appointment takeValue:oldStart forKey:@"startDate"];
    [appointment takeValue:oldEnd   forKey:@"endDate"];
    return self;
  }

  {
    id<LSWMailEditorComponent,OGoContentPage> mailEditor;
    NSString *cc = nil;
    NSArray  *ps;
    NSString *title;
    NSString *s;

    if ((mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"]) == nil)
      return nil;

    ps    = [[self object] valueForKey:@"participants"];
    title = [[self object] valueForKey:@"title"];

    [[self object] takeValue:oldStart forKey:@"oldStartDate"];

    /* set default cc */

    cc = [self->defaults objectForKey:@"scheduler_ccForNotificationMails"];
    if (cc != nil)
      [mailEditor addReceiver:cc type:@"cc"];
        
    s = [NSString stringWithFormat:@"%@: '%@' %@",
			  [[self labels] valueForKey:@"appointment"],
			  title,
			  [[self labels] valueForKey:@"moved"]];
    [mailEditor setSubject:s];
    {
      BOOL attach;

      attach =
	[[self->defaults valueForKey:@"scheduler_attach_apts_to_mails"]
	  boolValue];

      [mailEditor addAttachment:[self object] type:eoDateType
		  sendObject:[NSNumber numberWithBool:attach]];
    }
    {
      NSString *template = nil;

      template = [self->defaults valueForKey:@"scheduler_mail_template"];
      
      if ([template isNotNull]) {
	template = [template stringByReplacingVariablesWithBindings:
			       _bindingForAppointment(self, [self object])
			     stringForUnknownBindings:@""];
	[mailEditor setContentWithoutSign:template];
      }
      else {
	[mailEditor setContentWithoutSign:@""];
      }
    }
    {
      NSEnumerator *recEn;
      id           rec;
      BOOL         first  = YES;
          
      recEn = [ps objectEnumerator];
      while ((rec = [recEn nextObject])) {
	if (first) {
	  [mailEditor addReceiver:rec];
	  first = NO;
	}
	else 
	  [mailEditor addReceiver:rec type:@"cc"];
      }
    }
    return mailEditor;
  }
}

- (id)moveAptAction {
  [self setMoveUnit:[self->item valueForKey:@"unit"]];
  [self setMoveAmount:[[self->item valueForKey:@"amount"] intValue]];
  [self setMoveDirection:0]; // forward

  return [self moveAppointment];
}

/* move */
- (NSString *)movePrefix {
  NSString *prefix = [self->item valueForKey:@"prefix"];
  if ([prefix length]) return prefix;
  prefix = [self->item valueForKey:@"prefixKey"];
  if ([prefix length]) return [[self labels] valueForKey:prefix];
  return @"";
}
- (NSString *)moveLabel {
  NSString *label = [self->item valueForKey:@"label"];
  if ([label length]) return label;
  label = [self->item valueForKey:@"labelKey"];
  if ([label length]) return [[self labels] valueForKey:label];
  return @"";
}
- (NSString *)moveSuffix {
  NSString *suffix = [self->item valueForKey:@"suffix"];
  if ([suffix length]) return suffix;
  suffix = [self->item valueForKey:@"suffixKey"];
  if ([suffix length]) return [[self labels] valueForKey:suffix];
  return @"";
}

- (BOOL)showAMPMDates {
  static int showAMPMDates = -1;
  if (showAMPMDates == -1) {
    id ud = [[self session] userDefaults];
    showAMPMDates = [ud boolForKey:@"scheduler_AMPM_dates"] ? 1 : 0;
  }
  return showAMPMDates ? YES : NO;
}

- (NSString *)timeFormat {
  return [self showAMPMDates] ? @"%I:%M %p" : @"%H:%M";
}
- (NSString *)dateTimeTZFormat {
  return [self showAMPMDates] ? @"%Y-%m-%d %I:%M %p %Z" : @"%Y-%m-%d %H:%M %Z";
}

- (NSString *)moveExampleString {
  NSString       *day;
  NSString       *example;
  NSArray        *hol;
  NSCalendarDate *start = [[self object] valueForKey:@"startDate"];
  NSCalendarDate *date  =
    [self _moveDate:start
          forUnit:[self->item valueForKey:@"unit"]
          amount:[[self->item valueForKey:@"amount"] intValue]];

  if ([start isDateOnSameDay:date])
    return [date descriptionWithCalendarFormat:[self timeFormat]];
  else {
    day =
      [[self labels] valueForKey:[date descriptionWithCalendarFormat:@"%A"]];
    example =
      [NSString stringWithFormat:@"%@, %@", day,
                [date descriptionWithCalendarFormat:[self dateTimeTZFormat]]];
  }

  hol = [[self holidays] holidaysOfDate:date];
  if ([hol count]) {
    unsigned        i, cnt;
    NSMutableString *info;
    NSString        *label;

    cnt  = [hol count];
    info = [NSMutableString stringWithCapacity:20];
    [info appendString:example];
    [info appendString:@" ("];
    for (i = 0; i < cnt; i++) {
      if (i) [info appendString:@", "];
      label = [hol objectAtIndex:i];
      label =
        [[self labels] valueForKey:[NSString stringWithFormat:@"holiday_%@",
                                             label]];
      if (label == nil) label = [hol objectAtIndex:cnt];
      [info appendString:label];
    }
    [info appendString:@")"];
    return info;
  }
  return example;
}

- (NSString *)niceStartDate {
  NSString       *day;
  NSCalendarDate *date;
  date = [[self object] valueForKey:@"startDate"];
  day = [[self labels] valueForKey:[date descriptionWithCalendarFormat:@"%A"]];
  return
    [NSString stringWithFormat:@"%@, %@", day,
              [date descriptionWithCalendarFormat:[self dateTimeTZFormat]]];
}
- (NSString *)niceEndDate {
  NSString       *day;
  NSCalendarDate *date;
  date = [[self object] valueForKey:@"endDate"];
  day = [[self labels] valueForKey:[date descriptionWithCalendarFormat:@"%A"]];
  return
    [NSString stringWithFormat:@"%@, %@", day,
              [date descriptionWithCalendarFormat:[self dateTimeTZFormat]]];
}

// 15 minutes
- (NSString *)moveForwardLabel {
  return [[self labels] valueForKey:@"move_forward"];
}
- (NSString *)moveBackwardLabel {
  return [[self labels] valueForKey:@"move_backward"];
}
- (NSString *)move15minPrefix {
  return [[self labels] valueForKey:@"move_by15Minutes"];
}
- (NSDictionary *)move15minForwardItem {
  static NSDictionary *move15minForward = nil;
  if (move15minForward == nil)
    move15minForward = 
      [[NSDictionary dictionaryWithObjectsAndKeys:
                     @"minutes", @"unit",
                     @"15",      @"amount", nil] copy];
  return move15minForward;
}
- (NSDictionary *)move15minBackwardItem {
  static NSDictionary *move15minBackward = nil;
  if (move15minBackward == nil)
    move15minBackward = 
      [[NSDictionary dictionaryWithObjectsAndKeys:
                     @"minutes", @"unit",
                     @"-15",     @"amount", nil] copy];
  return move15minBackward;
}
- (NSString *)move15minForwardExample {
  [self setItem:[self move15minForwardItem]];
  return [self moveExampleString];
}
- (NSString *)move15minBackwardExample {
  [self setItem:[self move15minBackwardItem]];
  return [self moveExampleString];
}
- (id)move15minForwardAction {
  [self setItem:[self move15minForwardItem]];
  return [self moveAptAction];
}
- (id)move15minBackwardAction {
  [self setItem:[self move15minBackwardItem]];
  return [self moveAptAction];
}


// 30 minutes
- (NSString *)move30minPrefix {
  return [[self labels] valueForKey:@"move_by30Minutes"];
}
- (NSDictionary *)move30minForwardItem {
  static NSDictionary *move30minForward = nil;
  if (move30minForward == nil)
    move30minForward = 
      [[NSDictionary dictionaryWithObjectsAndKeys:
                     @"minutes", @"unit",
                     @"30",      @"amount", nil] copy];
  return move30minForward;
}
- (NSDictionary *)move30minBackwardItem {
  static NSDictionary *move30minBackward = nil;
  if (move30minBackward == nil)
    move30minBackward = 
      [[NSDictionary dictionaryWithObjectsAndKeys:
                     @"minutes", @"unit",
                     @"-30",     @"amount", nil] copy];
  return move30minBackward;
}
- (NSString *)move30minForwardExample {
  [self setItem:[self move30minForwardItem]];
  return [self moveExampleString];
}
- (NSString *)move30minBackwardExample {
  [self setItem:[self move30minBackwardItem]];
  return [self moveExampleString];
}
- (id)move30minForwardAction {
  [self setItem:[self move30minForwardItem]];
  return [self moveAptAction];
}
- (id)move30minBackwardAction {
  [self setItem:[self move30minBackwardItem]];
  return [self moveAptAction];
}

// 1 hour
- (NSString *)move1hourPrefix {
  return [[self labels] valueForKey:@"move_by1hour"];
}
- (NSDictionary *)move1hourForwardItem {
  static NSDictionary *move1hourForward = nil;
  if (move1hourForward == nil)
    move1hourForward = 
      [[NSDictionary dictionaryWithObjectsAndKeys:
                     @"hours", @"unit",
                     @"1",     @"amount", nil] copy];
  return move1hourForward;
}
- (NSDictionary *)move1hourBackwardItem {
  static NSDictionary *move1hourBackward = nil;
  if (move1hourBackward == nil)
    move1hourBackward = 
      [[NSDictionary dictionaryWithObjectsAndKeys:
                     @"hours", @"unit",
                     @"-1",    @"amount", nil] copy];
  return move1hourBackward;
}
- (NSString *)move1hourForwardExample {
  [self setItem:[self move1hourForwardItem]];
  return [self moveExampleString];
}
- (NSString *)move1hourBackwardExample {
  [self setItem:[self move1hourBackwardItem]];
  return [self moveExampleString];
}
- (id)move1hourForwardAction {
  [self setItem:[self move1hourForwardItem]];
  return [self moveAptAction];
}
- (id)move1hourBackwardAction {
  [self setItem:[self move1hourBackwardItem]];
  return [self moveAptAction];
}


// binding

static NSString *_personName(id self, id _person) {
  NSMutableString *str   = nil;

  str = [NSMutableString stringWithCapacity:64];    

  if (_person != nil) {
    id n = [_person valueForKey:@"name"];
    id f = [_person valueForKey:@"firstname"];

    if (f != nil) {
      [str appendString:f];
       [str appendString:@" "];
    }
    if (n != nil) {
      [str appendString:n];
    }
  }
  return str;
}

static NSDictionary *_bindingForAppointment(id self, id obj) {
  NSMutableDictionary *bindings = nil;
  id                  c         = nil;
  NSString            *format   = nil;
  NSString            *title    = nil;
  NSString            *location = nil;
  NSString            *resNames = nil;
  NSCalendarDate      *sd       = nil;
  NSCalendarDate      *ed       = nil;

  format = [[[self session] userDefaults]
                   stringForKey:@"scheduler_mail_template_date_format"];

  sd = [obj valueForKey:@"startDate"];
  if (format != nil && [sd isNotNull]) {
    [sd setCalendarFormat:format];
  }
  ed = [obj valueForKey:@"endDate"];
  if (format != nil && [ed isNotNull]) {
    [ed setCalendarFormat:format];
  }

  bindings = [[NSMutableDictionary alloc] initWithCapacity:8];
  [bindings setObject:sd forKey:@"startDate"];
  [bindings setObject:ed forKey:@"endDate"];

  if ((title = [obj valueForKey:@"title"]))
    [bindings setObject:title forKey:@"title"];
  if ((location = [obj valueForKey:@"location"]))
    [bindings setObject:location forKey:@"location"];
  if ((resNames = [obj valueForKey:@"resourceNames"]))
    [bindings setObject:resNames forKey:@"resourceNames"];        
  if ((c = [obj valueForKey:@"comment"]))
    [bindings setObject:c forKey:@"comment"];
  else
    [bindings setObject:@"" forKey:@"comment"];
          
  { /* set creator */
    id cId = [obj valueForKey:@"ownerId"];

    if (cId != nil) {
      id c = [self runCommand:@"account::get", @"companyId", cId, nil];
      if ([c isKindOfClass:[NSArray class]])
        c = [c lastObject];
      [bindings setObject:_personName(self, c) forKey:@"creator"];
    }
  }
  { /* set participants */
    NSEnumerator    *enumerator = [[obj valueForKey:@"participants"]
                                        objectEnumerator];
    id              part        = nil;
    NSMutableString *str        = nil;
          
    while ((part = [enumerator nextObject])) {
      if (str == nil)
        str = [[NSMutableString alloc] initWithCapacity:128];
      else
        [str appendString:@", "];

      if ([[part valueForKey:@"isTeam"] boolValue])
        [str appendString:[part valueForKey:@"description"]];
      else
        [str appendString:_personName(self, part)];
    }
    if (str != nil) {
      [bindings setObject:str forKey:@"participants"];
      [str release]; str = nil;
    }
  }
  return [bindings autorelease];
}

@end /* LSWAppointmentMove */
