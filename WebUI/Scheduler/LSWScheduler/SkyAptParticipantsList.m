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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray;

@interface SkyAptParticipantsList : OGoContentPage
{
  id      appointment;
  id      item;
  id      member;
  id      enterprise;
  NSArray *participants;
  BOOL    isPersonAvailable;
  BOOL    isEnterpriseAvailable;
  BOOL    isMailAvailable;
  BOOL    isInternalMailEditor;

  BOOL    showDetails;
  BOOL    expandTeams;
  BOOL    printMode;
}

- (void)_fetchParticipants;
- (BOOL)isEnterpriseAvailable;

@end

#include "common.h"
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <OGoFoundation/OGoSession.h>
#include <EOControl/EOKeyGlobalID.h>
#include <NGMime/NGMimeType.h>

/*
  0 means don't add
  1 means normal participant
  2 means as single person (already in one of the participating teams)
*/
#define APT_INCLUSION_TYPE_ACCOUNT 0
#define APT_INCLUSION_TYPE_MISSING 1
#define APT_INCLUSION_TYPE_INTEAM  2

@implementation SkyAptParticipantsList

static BOOL hasLSWPersons        = NO;
static BOOL hasLSWEnterprises    = NO;
static BOOL hasLSWImapMailEditor = NO;
static NSDictionary *colorMapping = nil;
static NSArray      *defaultAttributes = nil;
static NSArray      *roleAttributes    = nil;
static NSArray      *detailAttributes  = nil;
static NGMimeType   *eoDateType        = nil;

+ (void)initialize {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  hasLSWPersons        = [bm bundleProvidingResource:@"LSWPersons" 
			     ofType:@"WOComponents"] ? YES : NO;
  hasLSWEnterprises    = [bm bundleProvidingResource:@"LSWEnterprises"
			     ofType:@"WOComponents"] ? YES : NO;
  hasLSWImapMailEditor = [bm bundleProvidingResource:@"LSWImapMailEditor"
			     ofType:@"WOComponents"] ? YES : NO;

  colorMapping =
    [[ud dictionaryForKey:@"scheduler_participantStatus_colors"] copy];
  defaultAttributes = 
    [[ud arrayForKey:@"scheduler_participantlist_attrnames"] copy];
  roleAttributes =
    [[ud arrayForKey:@"scheduler_participantlist_roleattrnames"] copy];
  detailAttributes =
    [[ud arrayForKey:@"scheduler_participantlist_detailattrnames"] copy];

  eoDateType = [[NGMimeType mimeType:@"eo" subType:@"date"] retain];
}

- (id)init {
  if ((self = [super init])) {
    // TODO: are ivars required?
    self->isPersonAvailable     = hasLSWPersons;
    self->isEnterpriseAvailable = hasLSWEnterprises;
    self->isMailAvailable       = hasLSWImapMailEditor;
  }
  return self;
}

- (void)dealloc {
  [self->participants release];
  [self->member       release];
  [self->enterprise   release];
  [self->appointment  release];
  [self->item         release];
  [super dealloc];
}

/* user specific defaults */

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (NSString *)configuredMailEditorType {
  return [[self userDefaults] stringForKey:@"mail_editor_type"];
}
- (BOOL)shouldUseInternalMailEditor {
  return [[self configuredMailEditorType] isEqualToString:@"internal"]?YES:NO;
}

- (BOOL)showParticipantRoles {
  return [[self userDefaults] boolForKey:@"scheduler_participantRolesEnabled"];
}

- (NSString *)mailTemplate {
  return [[self userDefaults] stringForKey:@"scheduler_mail_template"];
}
- (NSString *)mailTemplateDateFormat {
  return [[self userDefaults] 
	        stringForKey:@"scheduler_mail_template_date_format"];
}
- (BOOL)shouldAttachAppointmentsToMails {
  return [[self userDefaults] boolForKey:@"scheduler_attach_apts_to_mails"];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->isMailAvailable)
    self->isInternalMailEditor = [self shouldUseInternalMailEditor];
}

/* accessors */

- (BOOL)isPersonAvailable {
  return self->isPersonAvailable && !self->printMode;
}
- (BOOL)isEnterpriseAvailable {
  return self->isEnterpriseAvailable && !self->printMode;
}
- (BOOL)isMailAvailable {
  return self->isMailAvailable && !self->printMode;
}
- (BOOL)isInternalMailEditor {
  return self->isInternalMailEditor && !self->printMode;
}

- (void)setAppointment:(id)_apt {
  ASSIGN(self->appointment, _apt);
}
- (id)appointment {
  return self->appointment;
}

- (void)setPrintMode:(BOOL)_flag {
  self->printMode = _flag;
}
- (BOOL)printMode {
  return self->printMode;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)participantRole {
  NSString *v;
  
  v = [self->item valueForKey:@"role"];
  if (![v isNotNull])
    v = @"REQ-PARTICIPANT";
  return v;
}
- (NSString *)participantRoleLabel {
  NSString *status;
  
  if ((status = [self participantRole]) == nil)
    return nil;
  status = [@"partRole_" stringByAppendingString:[status stringValue]];
  return [[self labels] valueForKey:status];
}

- (NSString *)participantStatus {
  NSString *status;
  
  status = [self->item valueForKey:@"partStatus"];
  if (![status isNotNull])
    status = @"NEEDS-ACTION";
  return status;
}
- (NSString *)participantStatusLabel {
  NSString *status;
  
  if ((status = [self participantStatus]) == nil)
    return nil;
  status = [@"partStat_" stringByAppendingString:[status stringValue]];
  return [[self labels] valueForKey:status];
}

- (NSString *)participantStatusColor {
  NSString *color;
  
  color = [colorMapping objectForKey:[self participantStatus]];
  return [color isNotEmpty] ? color : (NSString *)@"black";
}

- (void)setEnterprise:(id)_ep {
  ASSIGN(self->enterprise, _ep);
}
- (id)enterprise {
  return self->enterprise;
}

- (void)setMember:(id)_member {
  ASSIGN(self->member, _member);
}
- (id)member {
  return self->member;
}

- (NSArray *)participants {
  if (self->participants == nil)
    [self _fetchParticipants];
  return self->participants;
}
- (void)resetParticipants {
  [self->participants release]; 
  self->participants = nil;
}

/* commands */

- (id)_fetchAppointmentEOByGlobalID:(EOGlobalID *)_gid {
  return [self runCommand:@"appointment::get-by-globalid", @"gid", _gid, nil];
}

- (NSArray *)_fetchTeamGIDsForAccountGID:(EOGlobalID *)_gid {
  return [self runCommand:@"account::teams",
	         @"account", _gid,
	         @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
	       nil];
}

- (id)_fetchAccountEOByPrimaryKey:(NSNumber *)_cId {
  return [self runCommand:@"account::get", @"companyId", _cId, nil];
}

- (void)_loadExtendedAttributesIntoPersonEOs:(NSArray *)_ps {
  [self runCommand:@"person::get-extattrs",
          @"objects",     _ps,
          @"entityName",  @"Person",
          @"relationKey", @"companyValue", 
	nil];
}

- (NSArray *)_fetchAttributes:(NSArray *)_attrs 
  ofParticipantsOfAppointment:(id)_eo
{
  return [self runCommand:@"appointment::list-participants",
	         @"appointment", _eo,
	         @"attributes", _attrs,
	       nil];
}

/* complex accessors */

- (id)appointmentAsEO {
  id app;

  app = self->appointment;
  
  if ([app isKindOfClass:[NSDictionary class]])
    app = [self _fetchAppointmentEOByGlobalID:[app valueForKey:@"globalID"]];
  
  return app;
}

/* bool accessors */

- (BOOL)showDetails {
  return self->showDetails || self->printMode;
}
- (BOOL)hideDetails {
  return [self showDetails] ? NO : YES;
}
- (BOOL)expandTeams {
  return self->expandTeams || self->printMode;
}
- (BOOL)dontExpandTeams {
  return [self expandTeams] ? NO : YES;
}

- (NSNumber *)tableColumns {
  unsigned cnt = 3;
  if ([self showParticipantRoles])
    cnt += 2;
  if ([self showDetails]) {
    cnt += 3;
    if ([self isEnterpriseAvailable])
      cnt++;
  }
  return [NSNumber numberWithInt:cnt];
}

/* item values */

- (BOOL)isParticipantTeam {
  return [[self->item valueForKey:@"isTeam"] boolValue];
}
- (NSArray *)participantTeamMembers {
  return [self->item valueForKey:@"members"];
}

- (NSString *)itemEmail {
  NSString *email = [self->item valueForKey:@"email1"];

  if (![email isNotNull])
    return @"";
  
  return [@"mailto:" stringByAppendingString:email];
}

- (NSString *)participantLabel {
  return [[self->item valueForKey:@"isTeam"] boolValue]
    ? [self->item valueForKey:@"description"]
    : [self->item valueForKey:@"name"];
}
- (NSString *)teamMemberLabel {
  return [self->member valueForKey:@"name"];
}

/* member values */

- (NSString *)memberEmail {
  NSString *email = [self->member valueForKey:@"email1"];
  if (![email isNotNull]) return @"";
  return [@"mailto:" stringByAppendingString:email];
}

/* permissions */

- (BOOL)isParticipantViewAllowed {
  id   myAccount, accountId, obj;
  BOOL isAllowed, isPrivate;

  myAccount  = [[self session] activeAccount];
  accountId  = [myAccount valueForKey:@"companyId"];
  obj        = self->item;  
  isAllowed  = NO;
  isPrivate  = [[obj valueForKey:@"isPrivate"] boolValue];
  
  isAllowed = ((!isPrivate) || 
               ([accountId isEqual:[obj valueForKey:@"ownerId"]]) ||
               ([accountId intValue] == 10000));

  return isAllowed;
}

- (BOOL)isAddMeToParticipants {
  id       me;
  NSNumber *meId;
  NSArray  *parts;
  NSArray  *partIds;
  
  me    = [[self session] activeAccount];
  meId  = [me valueForKey:@"companyId"];
  parts = [self participants];
  
  partIds = [parts valueForKey:@"companyId"];
  return [partIds containsObject:meId] ? NO : YES;
}

- (unsigned)_checkWithAlreadyFetchedMembers:(NSArray *)parts {
  /*
    Martin writes:
    - members of team already fetched
    - no need to fetch anything further
    - go thru those members
  */
  unsigned i, max;
  NSNumber *meId;

  meId = [[[self session] activeAccount] valueForKey:@"companyId"];
  
  for (i = 0, max = [parts count]; i < max; i++) {
    NSArray *partIds;
    id      participant;
    
    participant = [parts objectAtIndex:i];
    if (![[participant valueForKey:@"isTeam"] boolValue])
      continue;

    partIds = [participant valueForKey:@"members"];
    partIds = [partIds valueForKey:@"companyId"];
    if (![partIds containsObject:meId])
      continue;
    
    /*
      Martin writes:
      me is member of a team which is participant
      can add me as extra participant
    */
    return APT_INCLUSION_TYPE_INTEAM;
  }
  /* did not find login account in a team, add as a regular participant */
  return APT_INCLUSION_TYPE_MISSING; // TODO: replace codes with constants
}

- (unsigned)_fetchAndCheckWithMemberIds:(NSArray *)partIds {
  unsigned i, max;
  NSArray  *myTeams;
  NSNumber *meId;
  id       me;
  
  me   = [[self session] activeAccount];
  meId = [me valueForKey:@"companyId"];
  
  myTeams = [self _fetchTeamGIDsForAccountGID:[me globalID]];
  
  for (i = 0, max = [myTeams count]; i < max; i++) {
    EOKeyGlobalID *tGID;
    NSNumber      *tId;
    
    tGID = [myTeams objectAtIndex:i];
    tId  = [tGID keyValues][0];
    if (![partIds containsObject:tId])
      continue;
    
    /*
      one of my teams participates in this appointment
      add me as single person
    */
    return APT_INCLUSION_TYPE_INTEAM;
  }
  /* did not find login account in a team, add as a regular participant */
  return APT_INCLUSION_TYPE_MISSING; // TODO: replace codes with constants
}

- (unsigned)isAddMeToParticipantsAsSinglePerson {
  id       me;
  NSNumber *meId;
  NSArray  *parts;
  NSArray  *partIds;
  unsigned i, max;
  id       participant = nil;
  BOOL     membersFetched = NO;
  
  me      = [[self session] activeAccount];
  meId    = [me valueForKey:@"companyId"];
  parts   = [self participants];
  partIds = [parts valueForKey:@"companyId"];
  if ([partIds containsObject:meId])
    /* already as an account in participant list => don't show "add me" */
    return APT_INCLUSION_TYPE_ACCOUNT;
  
  // check wether any team in participant list
  max = [parts count];
  for (i = 0; i < max; i++) {
    participant = [parts objectAtIndex:i];
    if ([[participant valueForKey:@"isTeam"] boolValue]) {
      membersFetched = [[participant valueForKey:@"members"] isNotNull];
      break;
    }
  }
  
  if (participant == nil) {
    /*
      Martin writes:
      - did not find me as a regular account and did not find a team in 
        participants
        => me is not participant
        => add me as normal participant
    */
    return APT_INCLUSION_TYPE_MISSING;
  }

  /*
    there are teams in participant list
    check them, whether me is member of any team
  */
  return (membersFetched)
    ? [self _checkWithAlreadyFetchedMembers:parts]
    : [self _fetchAndCheckWithMemberIds:partIds];
}

- (NSString *)addMeToParticipantsActionLabel {
  unsigned type;

  type = [self isAddMeToParticipantsAsSinglePerson];
  if (type == APT_INCLUSION_TYPE_INTEAM)
    return [[self labels] valueForKey:@"addMeAsSinglePerson"];
  
  return [[self labels] valueForKey:@"addMe"];
}

- (BOOL)isRemoveMeFromParticipants {
  NSNumber *myId;
  
  if ([[self participants] count] <= 1)
    return NO;
  
  myId = [[[self session] activeAccount] valueForKey:@"companyId"];
  return [[[self participants] valueForKey:@"companyId"] containsObject:myId];
}


/* extended participant attributes */

- (id)myParticipantSettingsInList:(NSArray *)_parts {
  NSNumber *meId;
  unsigned i, cnt;
  
  meId = [[[self session] activeAccount] valueForKey:@"companyId"];
  
  for (i = 0, cnt = [_parts count]; i < cnt; i++) {
    id part;
    
    part = [_parts objectAtIndex:i];
    if ([[part valueForKey:@"companyId"] isEqual:meId])
      return part;
  }
  return nil;
}
- (id)myParticipantSettings {
  return [self myParticipantSettingsInList:[self participants]];
}

- (NSString *)myParticipantStatus {
  NSString *status;
  id part;

  if ((part = [self myParticipantSettings]) == nil)
    return nil;
  
  status = [part valueForKey:@"partStatus"];
  return [status isNotNull] ? status : (NSString *)@"";
}
- (BOOL)showButtonToSwitchToStatus:(NSString *)_status {
  NSString *status;
  
  if ((status = [self myParticipantStatus]) == nil)
    /* this means, I'm not a participant */
    return NO;
  if (![self showParticipantRoles]) 
    return NO;
  return [status isEqualToString:_status] ? NO : YES;
}

- (BOOL)showAcceptButton {
  return [self showButtonToSwitchToStatus:@"ACCEPTED"];
}

- (BOOL)showDeclineButton {
  return [self showButtonToSwitchToStatus:@"DECLINED"];
}
- (BOOL)showTentativeButton {
  return [self showButtonToSwitchToStatus:@"TENTATIVE"];
}

/* actions */

- (id)mailToItem {
  id mailEditor;

  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:self->item type:@"to"];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[self session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
  }
  return nil;
}

- (id)mailToMember {
  id mailEditor;

  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:self->member type:@"to"];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[self session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
  }
  return nil;
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

- (NSDictionary *)_bindingForAppointment:(id)obj {
  /* TODO: this needs to be moved to a separate object! DUP CODE */
  NSMutableDictionary *bindings = nil;
  id                  c         = nil;
  NSString            *title    = nil;
  NSString            *location = nil;
  NSString            *resNames = nil;
  NSString            *format   = nil;
  NSCalendarDate      *sd       = nil;
  NSCalendarDate      *ed       = nil;
  
  format = [self mailTemplateDateFormat];
  sd = [obj valueForKey:@"startDate"];
  if (format != nil && sd != nil && [sd isNotNull])
    [sd setCalendarFormat:format];
  ed = [obj valueForKey:@"endDate"];
  if (format != nil && ed != nil && [ed isNotNull])
    [ed setCalendarFormat:format];
  
  bindings = [NSMutableDictionary dictionaryWithCapacity:8];
  [bindings setObject:sd forKey:@"startDate"];
  [bindings setObject:ed forKey:@"endDate"];
  
  if ((title = [obj valueForKey:@"title"]))
    [bindings setObject:title forKey:@"title"];
  if ((location = [obj valueForKey:@"location"]))
    [bindings setObject:location forKey:@"location"];
  if ((resNames = [obj valueForKey:@"location"]))
    [bindings setObject:resNames forKey:@"resourceNames"];        

  if ((c = [obj valueForKey:@"comment"]))
    [bindings setObject:c forKey:@"comment"];
  else
    [bindings setObject:@"" forKey:@"comment"];
  
  { /* set creator */
    NSNumber *cId;
    
    if ((cId = [obj valueForKey:@"ownerId"]) != nil) {
      id c;
      
      c = [self _fetchAccountEOByPrimaryKey:cId];
      if ([c isKindOfClass:[NSArray class]])
        c = [c lastObject];
      [bindings setObject:_personName(self, c) forKey:@"creator"];
    }
  }
  { /* set participants */
    NSEnumerator    *enumerator;
    id              part        = nil;
    NSMutableString *str        = nil;
          
    enumerator = [[obj valueForKey:@"participants"] objectEnumerator];
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
    if (str) {
      [bindings setObject:str forKey:@"participants"];
      [str release]; str = nil;
    }
  }
  return bindings;
}

- (id)sendMailWithSubject:(NSString *)_subject {
  /* TODO: this needs to be moved to a separate object! DUP CODE */
  id<LSWMailEditorComponent, OGoContentPage> mailEditor;
  id       app;
  NSArray  *ps;
  NSString *title;
  NSString *str;
  BOOL     attach;
  NSString *template;

  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
  if (mailEditor == nil) {
    [self debugWithFormat:@"did not find mail editor component!"];
    return nil;
  }
  
  app    = [self appointmentAsEO];
  ps    = [app valueForKey:@"participants"];

  [self _loadExtendedAttributesIntoPersonEOs:ps];

  title = [app valueForKey:@"title"];
  str = [NSString stringWithFormat:@"%@: '%@' %@",
                    [[self labels] valueForKey:@"appointment"],
                    title,
                    _subject];
  [mailEditor setSubject:str];

  attach = [self shouldAttachAppointmentsToMails];
  [mailEditor addAttachment:app type:eoDateType
	      sendObject:[NSNumber numberWithBool:attach]];
      
  template = [self mailTemplate];
  if ([template isNotNull]) {
    NS_DURING {
      template = [template stringByReplacingVariablesWithBindings:
			     [self _bindingForAppointment:app]
			   stringForUnknownBindings:@""];
    }
    NS_HANDLER {
      // TODO: whats that!!!
    }
    NS_ENDHANDLER;
  }
  else
    template = @"";
        
  [mailEditor setContentWithoutSign:template];

  {
    NSEnumerator *recEn;
    id           rec;
        
    recEn = [ps objectEnumerator];
    while ((rec = [recEn nextObject]) != nil)
      [mailEditor addReceiver:rec];
  }
  [self leavePage];
  [self enterPage:mailEditor];
  return nil; // TODO: check whether we can use a simple return
}

- (id)updateParticipants:(NSArray *)_participants ofEO:(id)_eo 
  logText:(NSString *)_logText
{
  // TODO: this should live in a command and get triggered by a DA
  id ac;

  ac = [[self session] activeAccount];
  
  [self runCommand:@"appointment::set-participants", 
	  @"object", _eo,
	  @"participants", _participants, 
	nil];
  
  if (![self commit]) {
    [self setErrorString:@"Could not commit transaction"];
    [self rollback];
    return nil;
  }
  
  _logText = [_logText stringByAppendingString:[ac valueForKey:@"name"]];
  [self runCommand:@"object::add-log",
          @"objectToLog", _eo, 
          @"logText",     _logText,
          @"action",      @"05_changed",
	nil];

  [self postChange:LSWUpdatedAppointmentNotificationName
	onObject:_eo];
  
  if ([self isMailAvailable])
    [self sendMailWithSubject:_logText];
  
  return nil;
}

- (id)addMeToParticipants {
  NSMutableArray *parts = nil;
  id             ac     = nil;
  id app;

  //  parts = [NSMutableArray arrayWithArray:[self participants]];
  app   = [self appointmentAsEO];
  parts = [NSMutableArray arrayWithArray:[app valueForKey:@"participants"]];
  ac    = [[self session] activeAccount];

  if (![parts containsObject:ac]) {
    [parts addObject:ac];

    [self updateParticipants:parts ofEO:app
          logText:[[self labels] valueForKey:@"addParticipantLog"]];
    
    [self->participants release]; self->participants = nil;
  }
  return nil;
}

- (id)removeMeFromParticipants {
  NSMutableArray *parts;
  id ac, app;
  
  app   = [self appointmentAsEO];
  parts = [NSMutableArray arrayWithArray:[app valueForKey:@"participants"]];
  ac    = [[self session] activeAccount];

  if (![parts containsObject:ac])
    return nil;
  
  while ([parts containsObject:ac])
    [parts removeObject:ac];
  
  app = [self appointmentAsEO];
  [self updateParticipants:parts ofEO:app
	logText:[[self labels] valueForKey:@"removeParticipantLog"]];

  [self->participants release]; self->participants = nil;
  return nil;
}

- (id)changeParticipantStateTo:(NSString *)_state logKey:(NSString *)_key {
  // TODO: this should live in a command and get triggered by a DA
  NSMutableArray *parts;
  id partSettings;
  
  // we need the assignment attributes (partStatus, role, ..)
  parts        = [NSMutableArray arrayWithArray:[self participants]];
  partSettings = [self myParticipantSettingsInList:parts];
  
  if (partSettings == nil)
    return nil;
  if ([[partSettings valueForKey:@"partSettings"] isEqualToString:_state])
    return nil;
  
  if (![partSettings isKindOfClass:[NSMutableDictionary class]]) {
    if ([partSettings isKindOfClass:[NSDictionary class]]) {
      id oldpart = partSettings;
      partSettings = [[partSettings mutableCopy] autorelease];
      
      [parts removeObject:oldpart];
      [parts addObject:partSettings];
    }
  }

  [partSettings takeValue:_state forKey:@"partStatus"];  
  
  [self updateParticipants:parts ofEO:[self appointmentAsEO]
	logText:[[self labels] valueForKey:_key]];
  [self->participants release]; self->participants = nil;
  return nil;
}

- (id)acceptAppointment {
  /* set my participant status to ACCEPTED */
  return [self changeParticipantStateTo:@"ACCEPTED"
               logKey:@"acceptAppointmentLog"];
}
- (id)declineAppointment {
  /* set my participant status to DECLINED */
  return [self changeParticipantStateTo:@"DECLINED"
               logKey:@"declineAppointmentLog"];
}
- (id)appointmentTentative {
  /* set my participant status to TENTATIVE */
  return [self changeParticipantStateTo:@"TENTATIVE"
               logKey:@"appointmentTentativeLog"];
}

/* notifications */

- (void)sleep {
  [self resetParticipants];
  [self->member release]; self->member = nil;
  [self->item   release]; self->item   = nil;
  [super sleep];
}

/* actions */

- (id)showMembers {
  self->expandTeams = YES;
  [self resetParticipants];
  return nil;
}
- (id)hideMembers {
  self->expandTeams = NO;
  [self resetParticipants];
  return nil;
}

- (id)enableDetails {
  self->showDetails = YES;
  [self resetParticipants];
  return nil;
}
- (id)disableDetails {
  self->showDetails = NO;
  [self resetParticipants];
  return nil;
}

/* fetching */

- (NSArray *)attributesToFetch {
  NSMutableArray *attrs;
  
  attrs = [[defaultAttributes mutableCopy] autorelease];
  if ([self showParticipantRoles])
    [attrs addObjectsFromArray:roleAttributes];
  if ([self showDetails])
    [attrs addObjectsFromArray:detailAttributes];
  if ([self expandTeams])
    [attrs addObject:@"team.members"];

  return attrs;
}

- (void)_fetchParticipants {
  NSNumber *oid;
  
  if ((oid = [self->appointment valueForKey:@"dateId"]) == nil)
    /* missing apt */
    return;
  
  [self->participants release]; self->participants = nil;
  
  self->participants = [[self _fetchAttributes:[self attributesToFetch]
			      ofParticipantsOfAppointment:self->appointment]
			      retain];
}

- (BOOL)isArchived {
  return [[self->item valueForKey:@"dbStatus"] isEqualToString:@"archived"];
}

@end /* SkyAptParticipantsList */
