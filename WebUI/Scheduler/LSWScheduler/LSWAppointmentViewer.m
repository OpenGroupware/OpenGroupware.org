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

#include <OGoFoundation/LSWViewerPage.h>

@class NSTimeZone, NSArray, NSMutableString;

@interface LSWAppointmentViewer : LSWViewerPage
{
@private
  id              item;
  NSMutableString *writeAccessList;
  NSTimeZone      *timeZone;
  BOOL            fetchComment;
  NSArray         *aptTypes;
  id              aptType;
}

/* accessors */

- (id)appointment;
- (BOOL)isCyclic;
- (BOOL)isUserOwner;
- (NSString *)startDate;
- (NSString *)startTime;
- (NSString *)endTime;
- (void)setItem:(id)_item;
- (id)item;
- (NSString *)accessTeamLabel;

@end /* LSWAppointmentViewer */

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <NGMime/NGMimeType.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <GDLAccess/EOFault.h>

@interface LSWAppointmentViewer(PrivateMethodes)
- (id)_getOwnerOf:(id)_app;
- (id)_getAccessTeamOf:(id)_app;
- (id)_getAppointmentByGlobalID:(id)_gid;
- (id)_appointmentAsEO;
@end /* LSWAppointmentViewer(PrivateMethodes) */


@interface NSObject(GID)
- (EOGlobalID *)globalID;
- (BOOL)isProfessionalEdition;
- (BOOL)hasLogTab;
@end

@implementation LSWAppointmentViewer

static NSArray  *attrArray       = nil;
static NSArray  *teamAttrNames   = nil;
static NSArray  *personAttrNames = nil;
static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;

+ (int)version {
  return [super version] + 4;
}
+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;

  if (yesNum == nil) yesNum = [NSNumber numberWithBool:YES];
  if (noNum  == nil) noNum  = [NSNumber numberWithBool:NO];

  attrArray       = [[ud arrayForKey:@"scheduler_viewer_fetchattrnames"] copy];
  teamAttrNames   = [[ud arrayForKey:@"scheduler_viewer_teamattrnames"]  copy];
  personAttrNames =[[ud arrayForKey:@"scheduler_viewer_personattrnames"] copy];
}

- (id)init {
  if ((self = [super init])) {
    self->writeAccessList = [[NSMutableString alloc] init];
    [self registerForNotificationNamed:@"LSWNewNote"];
    [self registerForNotificationNamed:@"LSWDeletedNote"];
    [self registerForNotificationNamed:LSWDeletedAppointmentNotificationName];
    [self registerForNotificationNamed:LSWUpdatedAppointmentNotificationName];
    self->aptTypes = nil;
    self->aptType  = nil;
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->timeZone        release];
  [self->item            release];
  [self->writeAccessList release];
  [self->aptTypes        release];
  [self->aptType         release];
  [super dealloc];
}

/* fetching */

- (void)_fetchComment {
  id tmp;
  id obj = [self object];
  
  if ([obj isKindOfClass:[NSDictionary class]]) return;

  [obj run:@"appointment::get-comment", @"relationKey", @"dateInfo", nil];
  tmp = [[obj valueForKey:@"dateInfo"] valueForKey:@"comment"];
  if (tmp) [obj takeValue:tmp forKey:@"comment"];
}

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

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self existingSession] userDefaults];
}
- (BOOL)defaultUseAMPMTimeFormat {
  return [[self userDefaults] boolForKey:@"scheduler_AMPM_dates"];
}
- (NSString *)defaultSchedulerMailTemplateDateFormat {
  return [[self userDefaults] 
                stringForKey:@"scheduler_mail_template_date_format"];
}

/* bindings */

static NSDictionary *_bindingForAppointment(LSWAppointmentViewer *self,id obj){
  /* split up that method */
  // TODO: could that be moved into a "binding" object?
  NSMutableDictionary *bindings = nil;
  id                  c         = nil;
  NSString            *format   = nil;
  NSString            *title    = nil;
  NSString            *location = nil;
  NSString            *resNames = nil;
  NSCalendarDate      *sd       = nil;
  NSCalendarDate      *ed       = nil;
  
  // TODO: a formatter would be better
  format = [self defaultSchedulerMailTemplateDateFormat];
  sd = [obj valueForKey:@"startDate"];
  if (format != nil && [sd isNotNull])
    [sd setCalendarFormat:format];
  ed = [obj valueForKey:@"endDate"];
  if (format != nil && [ed isNotNull])
    [ed setCalendarFormat:format];
  
  bindings = [NSMutableDictionary dictionaryWithCapacity:8];
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
  return bindings;
}

- (NSArray *)expandedParticipants {
  int      i, cnt;
  id       staffSet;
  NSArray  *ps;
  
  ps       = [[self object] valueForKey:@"participants"];
  cnt      = [ps count];
  staffSet = [NSMutableSet setWithCapacity:6];
  
  for (i = 0; i < cnt; i++) {
    id staff = [ps objectAtIndex:i];

    if ([[staff valueForKey:@"isTeam"] boolValue]) {
      NSArray *members = [staff valueForKey:@"members"];

      if (members == nil) {
        [self run:@"team::members", @"object", staff, nil];
        members = [staff valueForKey:@"members"];
      }
      [staffSet addObjectsFromArray:members];
    }
    else {
      [staffSet addObject:staff]; 
    }
  }
  staffSet = [staffSet allObjects];

  return staffSet;
}

- (id)mailObject {
  id<LSWMailEditorComponent> mailEditor;
  NGMimeType     *type = nil;
  NSUserDefaults *defs = nil;
  id       obj;
  NSArray  *ps;
  NSString *tmp;
  NSString *template;

  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
  obj        = [self _appointmentAsEO];
  ps         = [self runCommand:@"appointment::get-participants",
                     @"appointment", obj, nil];
  //ps       = [[self object] valueForKey:@"participants"];

  if (mailEditor == nil)
    return nil;

  defs = [[self session] userDefaults];
  
  tmp = [[NSString alloc] initWithFormat:@"%@: '%@'",
			  [[self labels] valueForKey:@"appointment"],
			  [obj valueForKey:@"title"]];
  [mailEditor setSubject:tmp];
  [tmp release];
  
  /* add template */
  
  template = [defs valueForKey:@"scheduler_mail_template"];
  
  if (![template isNotNull])
    [mailEditor setContentWithoutSign:@""];
  else {
    tmp = [template stringByReplacingVariablesWithBindings:
		      _bindingForAppointment(self, obj)
		    stringForUnknownBindings:@""];
    [mailEditor setContentWithoutSign:tmp];
  }
  
  /* add default receivers */
  {
      NSEnumerator *recEn = [ps objectEnumerator];
      id           rec    = nil;
      BOOL         first  = YES;
          
      while ((rec = [recEn nextObject])) {
        if (first) {
          [mailEditor addReceiver:rec];
          first = NO;
        }
        else 
          [mailEditor addReceiver:rec type:@"cc"];
      }
  }
  type = [NGMimeType mimeType:@"eo"
		     subType:[[[obj entity] name] lowercaseString]];
  
#if 0 // HH: someone explain that?!
  if ([[defs valueForKey:@"LSMailsSendMailsWithoutSkyrixPart"]
               boolValue]) {
      [mailEditor addAttachment:obj type:type
                  sendObject:[NSNumber numberWithBool:NO]];
  }
  else
#endif      
  {
    NSNumber *n;
    BOOL     attach;
    
    template = [defs valueForKey:@"scheduler_mail_template"];
    
    template = [template stringByReplacingString:@" " withString:@""];
    attach   = [[defs valueForKey:@"scheduler_attach_apts_to_mails"]
                        boolValue];
      
    n = (([template length] > 0) && !attach) ? noNum : yesNum;
    
    [mailEditor addAttachment:obj type:type sendObject:n];
  }
  [self enterPage:(id<LSWContentPage>)mailEditor];
  return mailEditor;
}

- (void)_processWriteAccessString:(NSString *)_acl 
  andAddTeamGIDsToArray:(NSMutableArray *)_teamIds
  andAddPersonGIDsToArray:(NSMutableArray *)_personIds
{
  NSEnumerator *enumerator;
  id objId;
  
  if (![_acl isNotNull])
    return;
  if ([_acl isEqualToString:@" "]) // hack for Sybase (empty string is ' ')
    return;
  
  enumerator = [[_acl componentsSeparatedByString:@","] objectEnumerator];

  while ((objId = [enumerator nextObject])) {
    // TODO: this is somewhat weird - constructs two GIDs for one pkey
    NSNumber      *pkey;
    EOKeyGlobalID *oid;
    
    pkey = [NSNumber numberWithInt:[objId intValue]];
    
    oid  = [EOKeyGlobalID globalIDWithEntityName:@"Person" 
			  keys:&pkey keyCount:1 zone:NULL];
    if (oid) [_personIds addObject:oid];
    
    oid  = [EOKeyGlobalID globalIDWithEntityName:@"Team" 
			  keys:&pkey keyCount:1 zone:NULL];
    if (oid) [_teamIds addObject:oid];
  }
}

- (NSArray *)_fetchPersonGIDs:(NSArray *)_gids {
  NSArray *tmp;

  if ([_gids count] == 0)
    return [NSArray array];
  
  tmp = [self runCommand:@"person::get-by-globalid",
                @"gids",       _gids,
                @"attributes", personAttrNames,
	      nil];
  return tmp;
}

- (NSArray *)_fetchTeamGIDs:(NSArray *)_gids {
  NSArray *tmp;

  if ([_gids count] == 0)
    return [NSArray array];
  
  tmp = [self runCommand:@"team::get-by-globalid",
                @"gids",       _gids,
                @"attributes", teamAttrNames,
	      nil];
  return tmp;
}

- (void)_setWriteACLStringUsingRecords:(NSArray *)_records {
  int i, cnt;
  
  [self->writeAccessList setString:@""];
    
  for (i = 0, cnt = [_records count]; i < cnt; i++) {
    NSDictionary *o;
    NSString     *eName;

    o      = [_records objectAtIndex:i];
    eName = [[o valueForKey:@"globalID"] entityName];

    if (i > 0)
      [self->writeAccessList appendString:@", "];

    if ([eName isEqualToString:@"Person"])
      [self->writeAccessList appendString:[o valueForKey:@"login"]];
    else
      [self->writeAccessList appendString:[o valueForKey:@"description"]];
  }
}

- (void)_fetchWriteAccessList {
  NSString       *list = nil;
  EOGlobalID     *oid  = nil;
  NSNumber       *pkey = nil;
  NSMutableArray *personIds;
  NSMutableArray *teamIds;
  NSMutableArray *result;


  personIds = [[NSMutableArray alloc] init];
  teamIds   = [[NSMutableArray alloc] init];
  result    = [[NSMutableArray alloc] init];

  pkey = [[self object] valueForKey:@"ownerId"];
  oid  = [EOKeyGlobalID globalIDWithEntityName:@"Person" 
                          keys:&pkey keyCount:1 zone:NULL];
  [personIds addObject:oid];
  
  list = [[self object] valueForKey:@"writeAccessList"];
  [self _processWriteAccessString:list
	andAddTeamGIDsToArray:teamIds
	andAddPersonGIDsToArray:personIds];
  
  [result addObjectsFromArray:[self _fetchPersonGIDs:personIds]];
  [result addObjectsFromArray:[self _fetchTeamGIDs:teamIds]];
  
  [self _setWriteACLStringUsingRecords:result];
  
  [personIds release]; personIds = nil;
  [teamIds   release]; teamIds   = nil;
  [result    release]; result    = nil;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id appointment;
  NSTimeZone *tz;

  if (![super prepareForActivationCommand:_command
	      type:_type configuration:_cmdCfg])
    return NO;

  if ((tz = [[self context] valueForKey:@"SkySchedulerTimeZone"]) == nil)
    tz = [[self session] timeZone];

  self->timeZone = [tz retain];
    
  appointment = [self object];

  if ([[_type type] isEqualToString:@"eo-gid"]) {
    if (![[_type subType] isEqualToString:@"date"])
      return NO;

    appointment = [self _getAppointmentByGlobalID:appointment];
      
    [self setObject:appointment];
  }
  else if (![[appointment valueForKey:@"comment"] isNotNull]) {
    id tmp;

    [appointment run:@"appointment::get-comment",
		 @"relationKey", @"dateInfo",
		 nil];
    tmp = [[appointment valueForKey:@"dateInfo"] valueForKey:@"comment"];
    if (tmp) [appointment takeValue:tmp forKey:@"comment"];
  }

  if (appointment == nil) {
    [self logWithFormat:@"WARNING: %s No appointment can be set!!!", 
  	    __PRETTY_FUNCTION__];
    return NO;
  }
  
  /* refetch owner */
  
  if (![[appointment valueForKey:@"owner"] isNotNull]) {
    id owner;
    
    owner = [self _getOwnerOf:appointment];
    if (owner)
      [appointment takeValue:owner forKey:@"owner"];
  }
  [self _fetchWriteAccessList];
  
  return YES;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchComment) {
    [self _fetchComment];
    [self _fetchWriteAccessList];
    self->fetchComment = NO;
  }
  
  [[[self object] valueForKey:@"startDate"] setTimeZone:self->timeZone];
  [[[self object] valueForKey:@"endDate"]   setTimeZone:self->timeZone];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:@"LSWNewNote"] ||
      [_cn isEqualToString:@"LSWDeletedNote"]) {
    [[self appointment] takeValue:[NSNull null] forKey:@"toNote"];
  }
  if ([_cn isEqualToString:LSWDeletedAppointmentNotificationName]) {
    if ([[self object] isEqual:_object]) {
      [self setObject:nil];
    }
  }
  else if ([_cn isEqualToString:LSWUpdatedAppointmentNotificationName]) {
    id app;

    app = [self object];
    if ([app isKindOfClass:[NSDictionary class]]) {
      app = [self _getAppointmentByGlobalID:[app valueForKey:@"globalID"]];
      [self setObject:app];
      if ([app valueForKey:@"owner"] == nil) {
        id owner;

        owner = [self _getOwnerOf:app];
        if (owner)
          [app takeValue:owner forKey:@"owner"];
      }
    }
    self->fetchComment = YES;
  }
}

- (void)sleep {
  [super sleep];
  [self->aptTypes release]; self->aptTypes = nil;
  [self->aptType  release]; self->aptType  = nil;
}
 
/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (id)appointment {
  return [self object];
}

- (NSString *)loginPermissions {
  NSString *perms;
  
  if ((perms = [[self object] valueForKey:@"permissions"]))
    return perms;

  perms = [self runCommand:@"appointment::access",
                  @"gid", [[self object] valueForKey:@"globalID"],
                  nil];
  if (perms == nil) {
    [self setErrorString:@"couldn't get permissions for appointment !"];
    return @"";
  }

  [[self object] takeValue:perms forKey:@"permissions"];
  return perms;
}
- (BOOL)hasLoginEditAccess {
  return [[self loginPermissions] rangeOfString:@"e"].length > 0 ? YES : NO;
}
- (BOOL)hasLoginDeleteAccess {
  return [[self loginPermissions] rangeOfString:@"d"].length > 0 ? YES : NO;
}

- (BOOL)isLogTabEnabled {
  return [[self application] hasLogTab];
}

- (BOOL)isUserOwner {
  return [self hasLoginEditAccess];
}

- (NSString *)dateTimeTZFormat {
  // TODO: move format to default
  NSString *format = nil;
  BOOL showAMPMDates =
    [[[self session] userDefaults] boolForKey:@"scheduler_AMPM_dates"];
  format = showAMPMDates ? @"%Y-%m-%d %I:%M %p %Z" : @"%Y-%m-%d %H:%M %Z";
  format = [format retain];
  return format;
}
- (NSString *)timeTZFormat {
  return [self defaultUseAMPMTimeFormat] ? @"%I:%M %p %Z" : @"%H:%M %Z";
}

- (NSString *)startDate {
  // TODO: do not use descriptionWithCalendarFormat, use a formatter
  NSString       *ds, *ts;
  NSCalendarDate *date;
  NSString       *day;
  
  date = [[self appointment] valueForKey:@"startDate"];
  day  = [date descriptionWithCalendarFormat:@"%A"];
  
  ds = [[self labels] valueForKey:day];
  ts = [date descriptionWithCalendarFormat:[self dateTimeTZFormat]];
  return [NSString stringWithFormat:@"%@, %@", ds, ts];
}

- (NSString *)endDate {
  id date, day;
  
  date = [[self appointment] valueForKey:@"endDate"];
  day  = [date descriptionWithCalendarFormat:@"%A"];
  
  day  = [[self labels] valueForKey:day];
  date = [date descriptionWithCalendarFormat:[self dateTimeTZFormat]];
  
  return [NSString stringWithFormat:@"%@, %@", day, date];
}

- (NSString *)cycleEndDateString {
  NSCalendarDate *d = [[self object] valueForKey:@"cycleEndDate"];
  if (d == nil) return nil;
  return [d descriptionWithCalendarFormat:@"%Y-%m-%d %Z"];
}

- (NSString *)startTime {
  return [[[self appointment]
                 valueForKey:@"startDate"]
                 descriptionWithCalendarFormat:[self timeTZFormat]];
}
- (NSString *)endTime {
  return [[[self appointment]
                 valueForKey:@"endDate"]
                 descriptionWithCalendarFormat:[self timeTZFormat]];
}

/* appointment types */

- (NSArray *)configuredAptTypes {
  // TODO: improve
  NSUserDefaults *ud;
  NSArray *configured = nil;
  NSArray *custom     = nil;

  ud = [self userDefaults];
  configured = [ud arrayForKey:@"SkyScheduler_defaultAppointmentTypes"];
  if (configured == nil) configured = [NSArray array];
  custom = [ud arrayForKey:@"SkyScheduler_customAppointmentTypes"];
  if (custom != nil)
    configured = [configured arrayByAddingObjectsFromArray:custom];
  return configured;
}
- (NSArray *)aptTypes {
  if (self->aptTypes == nil)
    self->aptTypes = [[self configuredAptTypes] copy];
  return self->aptTypes;
}

- (id)_appointmentType {
  NSEnumerator *e;
  id           one;
  NSString     *wanted;
  if (self->aptType)
    return self->aptType;

  e      = [[self aptTypes] objectEnumerator];
  wanted = [[self appointment] valueForKey:@"aptType"];
  if (![wanted isNotNull]) wanted = nil;
  
  while ((one = [e nextObject])) {
    NSString *key;
    
    key = [one valueForKey:@"type"];
    
    if ((![wanted length]) && [key isEqualToString:@"none"])
      self->aptType = [one retain];
    else if ([wanted isEqualToString:key])
      self->aptType = [one retain];;
      
    if (self->aptType)
      return self->aptType;
  }
  return self->aptType;
}

- (NSString *)aptTypeLabel {
  id       type;
  NSString *label;
  
  type = [self _appointmentType];
  if ((label = [type valueForKey:@"label"]))
    return label;
  
  label = [type valueForKey:@"type"];
  label = [@"aptType_" stringByAppendingString:[label stringValue]];
  return [[self labels] valueForKey:label];
}

- (NSString *)accessTeamLabel {
  id accessTeam;

  accessTeam = [self _getAccessTeamOf:[self appointment]];
  
  return ([accessTeam isNotNull])
    ? [accessTeam valueForKey:@"description"]
    : nil;
}

- (NSString *)ignoreConflicts {
  return ([[[self object] valueForKey:@"isConflictDisabled"] boolValue])
    ? [[self labels] valueForKey:@"yes"]
    : [[self labels] valueForKey:@"no"];
}

- (NSString *)objectUrlKey {
  return [NSString stringWithFormat:
                     @"wa/activate?oid=%@&verb=view",
                     [[self object] valueForKey:@"dateId"]];
}

- (NSString *)notificationTime {
  NSString *timeNumber = nil;
  
  timeNumber = [[[self object] valueForKey:@"notificationTime"] stringValue];
  
  if ([timeNumber isEqualToString:@"10"]) timeNumber = @"10m";
  
  if (timeNumber != nil) {
    return [NSString stringWithFormat:@"%@ %@",
                     [[self labels] valueForKey:timeNumber],
                     [[self labels] valueForKey:@"before"]];
  }

  return [[self labels] valueForKey:@"notSet"];
}

- (BOOL)isCyclic {
  return [[[self object] valueForKey:@"type"] isNotNull];
}

- (NSString *)cycleType {
  return [[self labels] valueForKey:[[self object] valueForKey:@"type"]];
}

- (NSString *)writeAccessList {
  return self->writeAccessList;
}

- (BOOL)isOwnerArchived {
  return [[[self->object valueForKey:@"owner"]
                         valueForKey:@"dbStatus"]
                         isEqualToString:@"archived"];
}

/* label generation */

- (NSString *)objectLabel {
  // Note: need to override this because -object of this viewer is a NSDict
  return [[self object] valueForKey:@"title"];
}

/* actions */

- (id)printApt {
  WOResponse *r;
  id obj;
  id page;

  obj = [self _appointmentAsEO];
  [[self session] transferObject:obj owner:nil];
  page = [[self session] instantiateComponentForCommand:@"print"
                         type:[NGMimeType mimeType:@"eo" subType:@"date"]
                         object:obj];
  r = [page generateResponse];
  [r setHeader:@"text/html" forKey:@"Content-Type"];
  return r;
}

- (id)delete {
  OGoContentPage *component;
  
  // TODO: activation by GID would be better
  component = [self activateObject:[self _appointmentAsEO] withVerb:@"delete"];
  [component takeValue:@"2" forKey:@"goBackWithCount"];

  return component;
}
- (id)move {
  // TODO: activation by GID would be better
  return [self activateObject:[self _appointmentAsEO] withVerb:@"move"];
}
- (id)edit {
  // TODO: activation by GID would be better
  return [self activateObject:[self _appointmentAsEO] withVerb:@"edit"];
}

/* PrivateMethodes */

- (id)_getOwnerOf:(id)_app {
  NSString *ownerId;
  id theOwner;
  
  theOwner = [_app valueForKey:@"toOwner"];
  if (theOwner && ![EOFault isFault:theOwner])
    return [theOwner valueForKey:@"toPerson"];
  
#if DEBUG && 0 /* a fault is passed in when a mail-DA is activated! */
  if ([EOFault isFault:theOwner]) {
    [self logWithFormat:
	    @"WARNING: the owner of appointment %@ is a fault for class %@",
	    _app, NSStringFromClass([EOFault targetClassForFault:theOwner])];
  }
#endif
  
  ownerId = [_app valueForKey:@"ownerId"];
  if (![ownerId isNotNull])
    return nil;
  
  return [[self runCommand:@"person::get", @"companyId", ownerId, nil]
                lastObject];
}

- (id)_getAccessTeamOf:(id)_app {
  NSString *accessTeamId;
  id theAccessTeam;

  if ((theAccessTeam = [_app valueForKey:@"toAccessTeam"]))
    return theAccessTeam;

  accessTeamId = [_app valueForKey:@"accessTeamId"];
  
  theAccessTeam = ([accessTeamId isNotNull])
    ? [[self runCommand:@"team::get", @"companyId", accessTeamId, nil]
               lastObject]
    : nil;
  if (theAccessTeam != nil)
    [_app takeValue:theAccessTeam forKey:@"toAccessTeam"];
  
  return theAccessTeam;
}

- (id)_getAppointmentByGlobalID:(id)_gid {
  id result;
  
  if (_gid == nil) return nil;
  
  result = [self run:@"appointment::get-by-globalid",
                 @"gids",       [NSArray arrayWithObject:_gid],
                 @"timeZone",   self->timeZone,
                 @"attributes", attrArray,
                 nil];
  return [result lastObject];
}

- (id)_appointmentAsEO {
  EOGlobalID *gid;
  id app;

  app = [self appointment];
  if (![app isKindOfClass:[NSDictionary class]])
    return app;

  gid = [app valueForKey:@"globalID"];
  app = [self runCommand:@"appointment::get-by-globalid",
                @"gid", gid,
                @"timeZone", self->timeZone,
                nil];
  return app;
}

@end /* LSWAppointmentViewer(PrivateMethodes) */
