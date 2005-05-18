#include "common.h"
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/LSWContentPage.h>
#include <LSFoundation/OGoContextSession.h>
#include <EOControl/EOKeyGlobalID.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGMime/NGMimeType.h>
#include <OGoFoundation/OGoComponent.h>
#include <OGoFoundation/OGoContentPage.h>


@class NSMutableArray,NSMutableDictionary,NSString;
@interface SkyDelegationList :LSWContentPage
{
	id      appointment;
	id      item;
	id      member;
	id      enterprise;
	//####ADDED BY AO#####
	//BY GLC
	id	selectedSource;
	id	selectedDestination;

	BOOL	flagListSource;
	BOOL	flagListDestination;
	NSMutableDictionary *listSource;
	NSMutableDictionary *listSourceInit;
	NSMutableDictionary *listDestination;
	NSMutableDictionary *listDestinationInit;
	
	NSMutableArray* arraySource;
	NSMutableArray* arrayDestination;
	

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

#define APT_INCLUSION_TYPE_ACCOUNT 0
#define APT_INCLUSION_TYPE_MISSING 1
#define APT_INCLUSION_TYPE_INTEAM  2

@implementation SkyDelegationList

static BOOL hasLSWPersons        = NO;
static BOOL hasLSWEnterprises    = NO;
static BOOL hasLSWImapMailEditor = NO;
static NSDictionary *colorMapping = nil;
static NSArray      *defaultAttributes = nil;
static NSArray      *roleAttributes    = nil;
static NSArray      *detailAttributes  = nil;
static NGMimeType   *eoDateType        = nil;


+ (void)initialize
{
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  
  if (didInit) 
	  return;
  didInit = YES;
  
  hasLSWPersons        = [bm bundleProvidingResource:@"LSWPersons" ofType:@"WOComponents"] ? YES : NO;
  hasLSWEnterprises    = [bm bundleProvidingResource:@"LSWEnterprises" ofType:@"WOComponents"] ? YES : NO;
  hasLSWImapMailEditor = [bm bundleProvidingResource:@"LSWImapMailEditor" ofType:@"WOComponents"] ? YES : NO;

  colorMapping = [[ud dictionaryForKey:@"scheduler_participantStatus_colors"] copy];
  defaultAttributes = [[ud arrayForKey:@"scheduler_participantlist_attrnames"] copy];
  roleAttributes = [[ud arrayForKey:@"scheduler_participantlist_roleattrnames"] copy];
  detailAttributes = [[ud arrayForKey:@"scheduler_participantlist_detailattrnames"] copy];

  eoDateType = [[NGMimeType mimeType:@"eo" subType:@"date"] retain];
}

- (id)init
{
  if ((self = [super init]))
  {
    // TODO: are ivars required?
    self->isPersonAvailable     = hasLSWPersons;
    self->isEnterpriseAvailable = hasLSWEnterprises;
    self->isMailAvailable       = hasLSWImapMailEditor;
	self->flagListSource		= NO;
	self->flagListDestination	= NO;
	self->listSource = nil;
	self->listSourceInit = nil;
	self->listDestination = nil;
	self->listDestinationInit = nil;
	self->arraySource = nil;
	self->arrayDestination = nil;

  }
  return self;
}

- (void)dealloc
{
  [self->participants release];
  [self->member       release];
  [self->enterprise   release];
  [self->appointment  release];
  [self->item         release];
  //###ADDED BY AO###
  //###BY GLC#####
  [self->selectedSource	  	release];
  [self->selectedDestination  	release];
  [self->listSource		release];
  [self->listSourceInit		release];
  [self->listDestination	 release];


  [super dealloc];
}

/* user specific defaults */

- (NSUserDefaults *)userDefaults
{
  return [[self session] userDefaults];
}

- (NSString *)configuredMailEditorType 
{
  return [[self userDefaults] stringForKey:@"mail_editor_type"];
}
- (BOOL)shouldUseInternalMailEditor 
{
  return [[self configuredMailEditorType] isEqualToString:@"internal"]?YES:NO;
}

- (BOOL)showParticipantRoles 
{
  return [[self userDefaults] boolForKey:@"scheduler_participantRolesEnabled"];
}

- (NSString *)mailTemplate 
{
  return [[self userDefaults] stringForKey:@"scheduler_mail_template"];
}
- (NSString *)mailTemplateDateFormat 
{
  return [[self userDefaults] 
	        stringForKey:@"scheduler_mail_template_date_format"];
}
- (BOOL)shouldAttachAppointmentsToMails 
{
  return [[self userDefaults] boolForKey:@"scheduler_attach_apts_to_mails"];
}

/* notifications */

- (void)syncAwake 
{
  [super syncAwake];

  if (self->isMailAvailable)
    self->isInternalMailEditor = [self shouldUseInternalMailEditor];
}

/* accessors */

- (BOOL)isPersonAvailable 
{
  return self->isPersonAvailable && !self->printMode;
}
- (BOOL)isEnterpriseAvailable 
{
  return self->isEnterpriseAvailable && !self->printMode;
}
- (BOOL)isMailAvailable 
{
  return self->isMailAvailable && !self->printMode;
}
- (BOOL)isInternalMailEditor 
{
  return self->isInternalMailEditor && !self->printMode;
}

- (void)setAppointment:(id)_apt 
{
  ASSIGN(self->appointment, _apt);
}
- (id)appointment 
{
  return self->appointment;
}

- (void)setPrintMode:(BOOL)_flag 
{
  self->printMode = _flag;
}
- (BOOL)printMode 
{
  return self->printMode;
}

- (void)setItem:(id)_item 
{
  ASSIGN(self->item, _item);
}
- (id)item 
{
  return self->item;
}

- (NSString *)participantStatus 
{
  NSString *status;
  
  status = [self->item valueForKey:@"partStatus"];
  if (![status isNotNull])
    status = @"NEEDS-ACTION";
  return status;
}
- (NSString *)participantStatusLabel 
{
  NSString *status;
  
  if ((status = [self participantStatus]) == nil)
    return nil;
  status = [@"partStat_" stringByAppendingString:[status stringValue]];
  return [[self labels] valueForKey:status];
}

- (NSString *)participantStatusColor 
{
  NSString *color;
  
  color = [colorMapping objectForKey:[self participantStatus]];
  return [color length] > 0 ? color : @"black";
}

- (void)setEnterprise:(id)_ep 
{
  ASSIGN(self->enterprise, _ep);
}
- (id)enterprise 
{
  return self->enterprise;
}

- (void)setMember:(id)_member 
{
  ASSIGN(self->member, _member);
}
- (id)member 
{
  return self->member;
}

- (NSArray *)participants 
{
  if (self->participants == nil)
    [self _fetchParticipants];
  return self->participants;
}
- (void)resetParticipants 
{
  [self->participants release]; 
  self->participants = nil;
}

/* commands */

- (id)_fetchAppointmentEOByGlobalID:(EOGlobalID *)_gid 
{
  return [self runCommand:@"appointment::get-by-globalid", @"gid", _gid, nil];
}

- (NSArray *)_fetchTeamGIDsForAccountGID:(EOGlobalID *)_gid 
{
  return [self runCommand:@"account::teams",
	         @"account", _gid,
	         @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
	       nil];
}

- (id)_fetchAccountEOByPrimaryKey:(NSNumber *)_cId 
{
  return [self runCommand:@"account::get", @"companyId", _cId, nil];
}

- (void)_loadExtendedAttributesIntoPersonEOs:(NSArray *)_ps 
{
  [self runCommand:@"person::get-extattrs",
          @"objects",     _ps,
          @"entityName",  @"Person",
          @"relationKey", @"companyValue", 
	nil];
}

- (NSArray *)_fetchAttributes:(NSArray *)_attrs ofParticipantsOfAppointment:(id)_eo
{
  return [self runCommand:@"appointment::list-participants",
	         @"appointment", _eo,
	         @"attributes", _attrs,
	       nil];
}

/* complex accessors */

- (id)appointmentAsEO 
{
  id app;

  app = self->appointment;
  
  if ([app isKindOfClass:[NSDictionary class]])
    app = [self _fetchAppointmentEOByGlobalID:[app valueForKey:@"globalID"]];
  
  return app;
}

/* bool accessors */

- (BOOL)showDetails 
{
  return self->showDetails || self->printMode;
}
- (BOOL)hideDetails 
{
  return [self showDetails] ? NO : YES;
}
- (BOOL)expandTeams 
{
  return self->expandTeams || self->printMode;
}
- (BOOL)dontExpandTeams 
{
  return [self expandTeams] ? NO : YES;
}

- (NSNumber *)tableColumns 
{
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

- (BOOL)isParticipantTeam 
{
  return [[self->item valueForKey:@"isTeam"] boolValue];
}
- (NSArray *)participantTeamMembers 
{
  return [self->item valueForKey:@"members"];
}

- (NSString *)itemEmail 
{
  NSString *email = [self->item valueForKey:@"email1"];

  if (![email isNotNull])
    return @"";
  
  return [@"mailto:" stringByAppendingString:email];
}

- (NSString *)participantLabel 
{
  return [[self->item valueForKey:@"isTeam"] boolValue]
    ? [self->item valueForKey:@"description"]
    : [self->item valueForKey:@"name"];
}
- (NSString *)teamMemberLabel 
{
  return [self->member valueForKey:@"name"];
}

/* member values */

- (NSString *)memberEmail 
{
  NSString *email = [self->member valueForKey:@"email1"];
  if (![email isNotNull]) return @"";
  return [@"mailto:" stringByAppendingString:email];
}

/* permissions */

- (BOOL)isParticipantViewAllowed 
{
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

- (BOOL)isAddMeToParticipants 
{
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

- (unsigned)_checkWithAlreadyFetchedMembers:(NSArray *)parts 
{
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

- (unsigned)_fetchAndCheckWithMemberIds:(NSArray *)partIds 
{
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

- (unsigned)isAddMeToParticipantsAsSinglePerson 
{
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

- (NSString *)addMeToParticipantsActionLabel 
{
  unsigned type;

  type = [self isAddMeToParticipantsAsSinglePerson];
  if (type == APT_INCLUSION_TYPE_INTEAM)
    return [[self labels] valueForKey:@"addMeAsSinglePerson"];
  
  return [[self labels] valueForKey:@"addMe"];
}

- (BOOL)isRemoveMeFromParticipants 
{
  NSNumber *myId;
  
  if ([[self participants] count] <= 1)
    return NO;
  
  myId = [[[self session] activeAccount] valueForKey:@"companyId"];
  return [[[self participants] valueForKey:@"companyId"] containsObject:myId];
}


/* extended participant attributes */

- (id)myParticipantSettingsInList:(NSArray *)_parts 
{
  id       me;
  NSNumber *meId;
  unsigned i, cnt;
  id       part;

  me     = [[self session] activeAccount];
  meId   = [me valueForKey:@"companyId"];
  cnt = [_parts count];
  for (i = 0; i < cnt; i++) {
    part = [_parts objectAtIndex:i];
    if ([[part valueForKey:@"companyId"] isEqual:meId])
      return part;
  }
  return nil;
}

- (id)myParticipantSettings 
{
  return [self myParticipantSettingsInList:[self participants]];
}

- (NSString *)myParticipantStatus 
{
  NSString *status;
  id part;

  if ((part = [self myParticipantSettings]) == nil)
    return nil;
  
  status = [part valueForKey:@"partStatus"];
  return [status isNotNull] ? status : (NSString *)@"";
}

- (BOOL)showButtonToSwitchToStatus:(NSString *)_status 
{
  NSString *status;
  
  if ((status = [self myParticipantStatus]) == nil)
    /* this means, I'm not a participant */
    return NO;
  if (![self showParticipantRoles]) 
    return NO;
  return [status isEqualToString:_status] ? NO : YES;
}

- (BOOL)showAcceptButton 
{
  return [self showButtonToSwitchToStatus:@"ACCEPTED"];
}

- (BOOL)showDeclineButton 
{
  return [self showButtonToSwitchToStatus:@"DECLINED"];
}
- (BOOL)showTentativeButton 
{
  return [self showButtonToSwitchToStatus:@"TENTATIVE"];
}

/* actions */

- (id)mailToItem 
{
  id mailEditor;

  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:self->item type:@"to"];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[self session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
  }
  return nil;
}

- (id)mailToMember 
{
  id mailEditor;

  mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:self->member type:@"to"];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[self session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
  }
  return nil;
}

static NSString *_personName(id self, id _person) 
{
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

- (NSDictionary *)_bindingForAppointment:(id)obj 
{
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

- (id)sendMailWithSubject:(NSString *)_subject 
{
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
    while ((rec = [recEn nextObject]))
      [mailEditor addReceiver:rec];
  }
  [self leavePage];
  [self enterPage:mailEditor];
  return nil; // TODO: check whether we can use a simple return
}

- (id)updateParticipants:(NSArray *)_participants ofEO:(id)_eo logText:(NSString *)_logText
{
  id ac;

  ac = [[self session] activeAccount];
  [self logWithFormat:@"######_particpants dans update : %@#######",_participants];  
  [_eo run:@"appointment::set-participants", @"participants",
       _participants, nil];
  if (![self commit]) 
  {
    [self setErrorString:@"Could not commit transaction"];
    [self rollback];
    return nil;
  }

  _logText = [_logText stringByAppendingString:[ac valueForKey:@"name"]];
  [self run:@"object::add-log",
          @"logText",     _logText,
          @"action",      @"05_changed",
          @"objectToLog", _eo, 
	nil];

  [self postChange:LSWUpdatedAppointmentNotificationName
	onObject:_eo];
      
  if ([self isMailAvailable])
    [self sendMailWithSubject:_logText];
  
  return nil;
}

- (id)addMeToParticipants 
{
  NSMutableArray *parts = nil;
  id             ac     = nil;
  id app;

  //  parts = [NSMutableArray arrayWithArray:[self participants]];
  app   = [self appointmentAsEO];
  parts = [NSMutableArray arrayWithArray:[app valueForKey:@"participants"]];
  ac    = [[self session] activeAccount];
  if (![parts containsObject:ac]) {
    [parts addObject:ac];
    [self updateParticipants:parts ofEO:app logText:[[self labels] valueForKey:@"addParticipantLog"]];
    [self->participants release]; self->participants = nil;
  }
  return nil;
}

- (id)removeMeFromParticipants 
{
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

- (id)changeParticipantStateTo:(NSString *)_state logKey:(NSString *)_key 
{
  NSMutableArray *parts;
  id partSettings;
  
  // we need the assignemtn attributes (partStatus, role, ..)
  parts        = [NSMutableArray arrayWithArray:[self participants]];
  partSettings = [self myParticipantSettingsInList:parts];

  if (partSettings == nil)
    return nil;
  if ([[partSettings valueForKey:@"partSettings"] isEqualToString:_state])
    return nil;
  
  [partSettings takeValue:_state forKey:@"partStatus"];  
  [self updateParticipants:parts ofEO:[self appointmentAsEO]
	logText:[[self labels] valueForKey:_key]];
  [self->participants release]; self->participants = nil;
  return nil;
}

- (id)acceptAppointment 
{
  /* set my participant status to ACCEPTED */
  return [self changeParticipantStateTo:@"ACCEPTED"
               logKey:@"acceptAppointmentLog"];
}

- (id)declineAppointment 
{
  /* set my participant status to DECLINED */
  return [self changeParticipantStateTo:@"DECLINED"
               logKey:@"declineAppointmentLog"];
}

- (id)appointmentTentative 
{
  /* set my participant status to TENTATIVE */
  return [self changeParticipantStateTo:@"TENTATIVE"
               logKey:@"appointmentTentativeLog"];
}

/* notifications */

- (void)sleep 
{
  [self resetParticipants];
  RELEASE(self->member);       self->member       = nil;
  RELEASE(self->item);         self->item         = nil;
  [super sleep];
}

/* actions */

- (id)showMembers 
{
  self->expandTeams = YES;
  [self resetParticipants];
  return nil;
}

- (id)hideMembers 
{
  self->expandTeams = NO;
  [self resetParticipants];
  return nil;
}

- (id)enableDetails 
{
  self->showDetails = YES;
  [self resetParticipants];
  return nil;
}

- (id)disableDetails 
{
  self->showDetails = NO;
  [self resetParticipants];
  return nil;
}

/* fetching */

- (NSArray *)attributesToFetch 
{
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

- (void)_fetchParticipants 
{
  NSNumber *oid;
  
  if ((oid = [self->appointment valueForKey:@"dateId"]) == nil)
    /* missing apt */
    return;
  
  [self->participants release]; self->participants = nil;
  
  self->participants = [[self _fetchAttributes:[self attributesToFetch]
			      ofParticipantsOfAppointment:self->appointment]
			      retain];
}

- (BOOL)isArchived 
{
  return [[self->item valueForKey:@"dbStatus"] isEqualToString:@"archived"];
}



/*---------------------------------------------------------------------------------------------------------------------
 
 
 
 15/04/2005 
 Creation de la page de délégation 
 GLC
 
 
 ---------------------------------------------------------------------------------------------------------------------*/
//Page de delegation

//**********************************************************
//
//
//
//
//**********************************************************
- (NSMutableArray*)generateArray : (NSMutableDictionary*) _elem
{
		id object = nil;
		NSEnumerator *enumerateur;
		// TODO : controler que l'on peut pas retourner nil en lieu et place d'un tableau vide !!!!
		NSMutableArray *List = [[NSMutableArray alloc]initWithCapacity:32];
		
		if ((_elem != nil))
		{
			enumerateur = [_elem objectEnumerator];
			while ((object=[enumerateur nextObject]) != nil)
			{
				[List addObject:object];
			}
		}
		return [List autorelease];
}

//**********************************************************
//
//
//
//
//**********************************************************

- (NSMutableDictionary *)listSource
{
 	return self->listSource;
}

- (void)setListSource:(id)_listSource
{
  ASSIGN(self->listSource, _listSource);
}
//**********************************************************
//
//
//
//
//**********************************************************

- (id)selectedSource
{ 
	[self logWithFormat:@"#### method selection:%@",self->selectedSource];
	return self->selectedSource;
}

//**********************************************************
//
//
//
//
//**********************************************************
- (void)setSelectedSource : (id)_selectedSource
{
	[self logWithFormat:@"####### setSelectedSource : class %@, valeurs : %@",[_selectedSource class],_selectedSource ];
	ASSIGN(self->selectedSource,_selectedSource);
}

//**********************************************************
//
//
//
//
//**********************************************************
-(void)setSelectedDestination:(id)_selectedDestination
{
	[self logWithFormat:@"####### setSelectedDestination : class %@, valeurs : %@",[_selectedDestination class],_selectedDestination ];
	ASSIGN(self->selectedDestination,_selectedDestination);
}


//**********************************************************
//
//
//
//
//**********************************************************
- (id)selectedDestination
{ 
	[self logWithFormat:@"#### method selection destination:%@",self->selectedDestination];
	return self->selectedDestination;
}

//**********************************************************
//
//
//
//
//**********************************************************
- (NSMutableDictionary *)listDestination
{
	return self->listDestination;
}

//**********************************************************
//
//
//
//
//**********************************************************
- (void)setListDestination:(id)_listDestination 
{
	ASSIGN(self->listDestination, _listDestination);
}

//**********************************************************
//
//
//
//
//**********************************************************
-(NSMutableDictionary *) initListSource
{
	NSArray* delegatesID;
	NSDictionary* delegationsForUser;
	NSArray* participantsList;	
	NSString* rdvDelegationType;
	id loginAccount;
	id participantCompanyID;
	NSEnumerator* participantsEnumerator;
	NSMutableDictionary* returnDictionary;
	id currentObject;
	
	// on commence par recuperer le type de delegation du rendez-vous : si on a rien, on peut pas vraiment allez plus
	// loin donc on retourne nil;
	rdvDelegationType = [[self appointmentAsEO] valueForKey:@"rdvType"];
	if(rdvDelegationType == nil)
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	// on recupere le login account : si on a rien on retourne nil car on peut rien faire sans !!!
	loginAccount = [[[self session] activeAccount] valueForKey:@"companyId"];
	if(loginAccount == nil)
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	// on recupere les delegations pour l'utilisateur CONNECTE 
	// si rien retourne nil : et on peut dire en plus GROS BUG.
	delegationsForUser = [self runCommand:@"appointment::get-delegation-for-delegate",@"withDelegateId",loginAccount,nil];
	if(delegationsForUser == nil)
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	// si pas de delegation pour ce user, la liste est forcement vide, donc on peut retourner nil tout de suite
	if(([delegationsForUser count] <= 0) )
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	// on recupere le tableau des ids de delegation pour le type rdvDelegationType;
	NSMutableString *typeDeRendezVous = [[NSMutableString alloc]init];
	[typeDeRendezVous appendString:@"id"];
	[typeDeRendezVous appendString:rdvDelegationType];
	[self logWithFormat:@"### typeDeRendezVous: %@",typeDeRendezVous];
	delegatesID = [delegationsForUser valueForKey:typeDeRendezVous];
	
	// si aucun ID dans le tableau, on retourne nil => il n'y a pas de delegation pour le type de rendez-vous
	if([delegatesID count] <= 0)
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	// on recupere la liste des participants. si pas de participants == GROS BUG, mais on degage proprement !!!
	participantsList = [self participants];
	if([participantsList count] <= 0)
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	[self logWithFormat:@"### initListSource : participantsList : %@",participantsList];
	[self logWithFormat:@"### initListSource : delegatesID : %@",delegatesID];
	
	returnDictionary = [[NSMutableDictionary alloc] initWithCapacity:[participantsList count]];
	if(returnDictionary == nil)
	{
		[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	participantsEnumerator = [participantsList objectEnumerator];
	while( (currentObject = [participantsEnumerator nextObject]) != nil )
	{
		participantCompanyID = [currentObject valueForKey:@"companyId"];
		[self logWithFormat:@"### initListSource : %s %d participantCompanyID %@ (class %@)",__FILE__,__LINE__,participantCompanyID,[participantCompanyID class]];
		[self logWithFormat:@"### initListSource : %s %d delegatesID %@ ",__FILE__,__LINE__,delegatesID];
		if(participantCompanyID == nil)
		{
			[self logWithFormat:@"### initListSource : %s %d",__FILE__,__LINE__];
			return nil;
		}
		
		if([delegatesID containsObject:participantCompanyID] == YES)
		{
			[self logWithFormat:@"### initListSource : debut construction du dictionnaire"];
			// Anne a dit : on met Prenom, espace, Nom, c'est plsu joli !!!! A les femmes !!!
			// donc le grouillot de base s'execute !!! 
			NSMutableString* NameAndFirstName = [[NSMutableString alloc] init];
			// prenom
			if([currentObject valueForKey:@"firstname"] == nil)
			{
				[NameAndFirstName appendString:@"NoFirstName"];
			}
			else
			{
				[NameAndFirstName appendString:[currentObject valueForKey:@"firstname"]];
			}
			// ajoute l'espace
			[NameAndFirstName appendString:@" "];
			// ajoute le nom
			if([currentObject valueForKey:@"name"] == nil)
			{
				[NameAndFirstName appendString:@"NoName"];
			}
			else
			{
				[NameAndFirstName appendString:[currentObject valueForKey:@"name"]];
			}
			
			[returnDictionary setObject:NameAndFirstName forKey:[participantCompanyID copy]];
		}
		else
		{
			[self logWithFormat:@"### initListSource : %s %d !!!!!!!!!! LA COMPARAISON A ECHOUE !!!!!!!!!",__FILE__,__LINE__];
		}
	}
	[self logWithFormat:@"### initListSource : fin initListSource"];
	// finalement on retourne le dictionnaire
	return returnDictionary;
}
	
//**********************************************************
//
//
//
//
//**********************************************************
- (NSMutableArray*)loadListSource
{	
	[self logWithFormat:@"### loadListSource : %@",self->listSource];
	// si self->flagListSource == yes, alors cela veut dire que l'on est passe une fois dans CETTE methode
	// et que self->listSourceInit est deja initialisee. Sinon, on doit l'initialiser ici.
	
	if ((self->flagListSource == NO))
	{
		self->flagListSource = YES;
		if(self->listSourceInit != nil)
			[self->listSourceInit release];
		
		self->listSource = [[self initListSource] retain];
		[self logWithFormat:@"### loadListSource : valeur de self->listSource : %@", self->listSource];
		
		self->listSourceInit = [self->listSource copy];
		[self logWithFormat:@"### loadListSource : valeur de self->listSourceInit : %@", self->listSourceInit];
		
	}
	
	if(self->arraySource != nil)
		[self->arraySource release];
	
	self->arraySource = [[self generateArray:self->listSource] retain];
	
	return  self->arraySource;
}

//**********************************************************
//
//
//
//
//**********************************************************
-(NSMutableDictionary *)initListDestination
{
	
	NSArray* delegatesID;
	NSDictionary* delegationsForUser;
	NSString* rdvDelegationType;
	id loginAccount;
	NSString* loginAccountString;
	id currentDelegateID;
	NSEnumerator* delegateParticipantEnumerator;
	NSEnumerator* delegateIDEnumerator;
	NSMutableDictionary* returnDictionary;
	id keyDelegateParticipant;
	id accountWithCompanyID;
	id valueFromObject;
				
	// on commence par recuperer le type de delegation du rendez-vous : si on a rien, on peut pas vraiment allez plus
	// loin donc on retourne nil;
	rdvDelegationType = [[self appointmentAsEO] valueForKey:@"rdvType"];
	if(rdvDelegationType == nil)
		return nil;
	
	// on recupere le login account : si on a rien on retourne nil car on peut rien faire sans !!!
	loginAccount = [[[self session] activeAccount] valueForKey:@"companyId"];
	if(loginAccount == nil)
		return nil;
	
	[self logWithFormat:@"### initListDestination : loginAccount class %@", [loginAccount class]];
	

	loginAccountString = [[[self session] activeAccount] valueForKey:@"companyId"];
	if(loginAccount == nil)
		return nil;
	
	[self logWithFormat:@"### initListDestination : loginAccountString class %@", [loginAccountString class]];
	
	// on recupere les delegations pour l'utilisateur CONNECTE 
	// si rien retourne nil : et on peut dire en plus GROS BUG.
	delegationsForUser = [self runCommand:@"appointment::get-delegation-for-delegate",@"withDelegateId",loginAccount,nil];
	if(delegationsForUser == nil)
		return nil;
	
	// si pas de delegation pour ce user, la liste est forcement vide, donc on peut retourner nil tout de suite
	if(([delegationsForUser count] <= 0) )
		return nil;
	
	// on recupere le tableau des ids de delegation pour le type rdvDelegationType;
	NSMutableString *typeDeRendezVous = [[NSMutableString alloc]init];
	[typeDeRendezVous appendString:@"id"];
	[typeDeRendezVous appendString:rdvDelegationType];
	[self logWithFormat:@"### initListDestination : typedeRendezvous  : %@",rdvDelegationType];
	
	delegatesID = [delegationsForUser valueForKey:typeDeRendezVous];
	// si aucun ID dans le tableau, on retourne nil => il n'y a pas de delegation pour le type de rendez-vous
	if([delegatesID count] <= 0)
	{
		[self logWithFormat:@"### initListDestination : %s %d",__FILE__,__LINE__];
		return nil;
	}
	// on recupere la liste des participants dans la source. 
	if([self->listSource count] <= 0)
	{
	 	[self logWithFormat:@"### initListDestination : %s %d",__FILE__,__LINE__];
	 	return nil;
	}
	
	
	[self logWithFormat:@"### initListDestination : self->listSource : %@",self->listSource];
	[self logWithFormat:@"### initListDestination : delegatesID : %@",delegatesID];
	
	returnDictionary = [[NSMutableDictionary alloc] initWithCapacity:[delegatesID count]];
	if(returnDictionary == nil)
	{
		[self logWithFormat:@"##### initListDestination : %s %d",__FILE__,__LINE__];
		return nil;
	}
	
	// on construit un tableau avec toutes les clezf de listSource
	NSMutableArray* arrayOfKeyFromListSource = [[NSMutableArray alloc]initWithCapacity:[self->listSource count]];
	delegateParticipantEnumerator = [self->listSource keyEnumerator];
	while( (keyDelegateParticipant = [delegateParticipantEnumerator nextObject]) != nil )
	{
		[arrayOfKeyFromListSource addObject:keyDelegateParticipant];
	}
	
	delegateIDEnumerator = [delegatesID objectEnumerator];
	while((currentDelegateID = [delegateIDEnumerator nextObject]) != nil )
	{
		[self logWithFormat:@"### initListDestination : %s %d, currentDelegateID %@ (class %@)",__FILE__,__LINE__,currentDelegateID,[currentDelegateID class]];
		[self logWithFormat:@"### initListDestination : %s %d, arrayOfKeyFromListSource %@ (class %@)",__FILE__,__LINE__,arrayOfKeyFromListSource];
		//on cherche si personne déléguée n'est pas dans la liste participants
		//on ajoute cette personne dans le dictionnaire de destination 
		// if([keyDelegateParticipant intValue] != [currentDelegateID intValue])
			
		if([arrayOfKeyFromListSource containsObject:currentDelegateID] == NO)
		{

			NSMutableArray* attributesArray = [[NSMutableArray alloc] init];
			[attributesArray addObject:@"name"];
			[attributesArray addObject:@"firstname"];
			[attributesArray addObject:@"isAccount"];
			[attributesArray addObject:@"login"];
			[attributesArray addObject:@"companyId"];
			[attributesArray addObject:@"globalID"];
				
			EOKeyGlobalID* gid = [EOKeyGlobalID globalIDWithEntityName:@"Person" keys:&currentDelegateID keyCount:1 zone:nil];
			accountWithCompanyID = [self runCommand:@"person::get-by-globalid",@"gid",gid,@"attributes",attributesArray,nil];
				
			[attributesArray release];
				
			// Anne a dit : on met Prenom, espace, Nom, c'est plsu joli !!!! A les femmes !!!
			// donc le grouillot de base s'execute !!! 
				
			[self logWithFormat:@"### initListDestination : account::get %@",accountWithCompanyID];
			
			NSMutableString* NameAndFirstName = [[NSMutableString alloc] init];
				
			valueFromObject = [accountWithCompanyID valueForKey:@"firstname"];
				
			if(valueFromObject == nil)
				[NameAndFirstName appendString:@"NoFirstName"];
			else
			{
				[self logWithFormat:@"### initListDestination : %s %d valueFromObject = %@",__FILE__,__LINE__,valueFromObject];
				if ([valueFromObject isKindOfClass:[NSArray class]])
					valueFromObject = [valueFromObject lastObject];
				[self logWithFormat:@"### initListDestination : %s %d valueFromObject = %@",__FILE__,__LINE__,valueFromObject];
				[NameAndFirstName appendString:valueFromObject];
			}
				
			[NameAndFirstName appendString:@" "];
					
			valueFromObject = [accountWithCompanyID valueForKey:@"name"];
			if(valueFromObject == nil)
				[NameAndFirstName appendString:@"NoName"];
			else
			{
				[self logWithFormat:@"### initListDestination : %s %d valueFromObject = %@",__FILE__,__LINE__,valueFromObject];
				if ([valueFromObject isKindOfClass:[NSArray class]])
					valueFromObject = [valueFromObject lastObject];
				[self logWithFormat:@"### initListDestination : %s %d valueFromObject = %@",__FILE__,__LINE__,valueFromObject];
				[NameAndFirstName appendString:valueFromObject];
			}
		
			[returnDictionary setObject:NameAndFirstName forKey:[currentDelegateID copy]];
		}
	}
	
	[self logWithFormat:@"### initListDestination : returnDictionary : %@",returnDictionary];
	// finalement on retourne le dictionnaire
	return [returnDictionary autorelease];
}

//**********************************************************
//
//
//
//
//**********************************************************
- (NSMutableArray*)loadListDestination
{
	[self logWithFormat:@"### loadListDestination"];

	if ((self->flagListDestination == NO))
	{
		self->flagListDestination = YES;
		if( self->listDestination != nil)
			[self->listDestination release];
		
		self->listDestination = [[self initListDestination] retain];
		[self logWithFormat:@"### loadListDestination : valeur de self->listDestination : %@", self->listDestination];
		
		self->listDestinationInit = [self->listDestination copy];
		[self logWithFormat:@"### oadListDestination : valeur de self->listDestinationInit : %@", self->listDestinationInit];
	}
	
	if(self->arrayDestination != nil)
		[self->arrayDestination release];
	
	self->arrayDestination = [[self generateArray:self->listDestination] retain];

	return  self->arrayDestination;
}

//**********************************************************
//
//
//
//
//**********************************************************
- (void) checkItemSource:(NSMutableDictionary*)_source toDestination:(NSMutableDictionary *)_destination withObjectSelected:(id)_objectSelected
{
	NSString*		stringSelected		= nil;
	NSNumber*		sourceKey			= nil;
	NSString*		stringItem			= nil;
	NSEnumerator*	listObjectSelected	= nil;
	NSEnumerator*	valueInSource		= nil;
	NSEnumerator*	enumaratorOfObjectToMove = nil;
	NSNumber*		theKeyToMove = nil;
	NSString*		stringToMove = nil;
	NSMutableDictionary* dictionaryOfObjectsToMove = nil;
	
	//On prend la liste des item sélectionné
	
	[self logWithFormat:@"### checkItemSource :  list des objects selectionne :%@",_objectSelected];
	if(_source == nil)
	{
		[self logWithFormat:@"###########################################"];
		[self logWithFormat:@"#### checkItem list _source NIL !!!!!!!!!  "];
		[self logWithFormat:@"###########################################"];
		return;
	}
	if(_destination == nil)
	{
		[self logWithFormat:@"###########################################"];
		[self logWithFormat:@"#### checkItem list _destination NIL !!!!  "];
		[self logWithFormat:@"###########################################"];
		return;
	}
	if(_objectSelected == nil)
	{
		[self logWithFormat:@"###########################################"];
		[self logWithFormat:@"#### checkItem list _objectSelected NIL !  "];
		[self logWithFormat:@"###########################################"];
		return;
	}
	
	dictionaryOfObjectsToMove = [[NSMutableDictionary alloc] init];
	
	listObjectSelected = [_objectSelected objectEnumerator];
	
	while ((stringSelected = [listObjectSelected nextObject])!=nil)
	{       
		valueInSource = [_source keyEnumerator];
		while ((sourceKey = [valueInSource nextObject])!=nil)
		{
			[self logWithFormat:@"### checkItemSource : sourceKey (%@) : %@",[sourceKey class], sourceKey];
			stringItem = [_source objectForKey:sourceKey];
			[self logWithFormat:@"### checkItemSource : valueItem (%@) : %@",[stringItem class], stringItem];
			[self logWithFormat:@"### checkItemSource : valueSelected (%@) : %@",[stringSelected class], stringSelected];
			
			if ([stringItem isEqualToString:stringSelected] == YES)
			{
				// we add strigItem and not stringSelected since stringSelected is born to die.
				// [_destination setObject:[stringItem copy] forKey:sourceKey];
				// [_destination setObject:stringSelected forKey:sourceKey]; NO !!!!!!!!!!!!
				// [_source removeObjectForKey:sourceKey];
				[self logWithFormat:@"### checkItemSource : need to move object %@ for key %@", stringItem, sourceKey];
				[dictionaryOfObjectsToMove setObject:[stringItem copy] forKey:[sourceKey copy]];
			}
		}
	}
	
	// ok now we have in dictionaryOfObjectsToMove what we need to delete from source, and what we must add in destination.
	
	enumaratorOfObjectToMove = [dictionaryOfObjectsToMove keyEnumerator];
	while( (theKeyToMove = [enumaratorOfObjectToMove nextObject]) != nil )
	{
		stringToMove = [dictionaryOfObjectsToMove objectForKey:theKeyToMove];
		// we remove from _source the key.
		[_source removeObjectForKey:theKeyToMove];
		[_destination setObject:[stringToMove copy] forKey:[theKeyToMove copy]];
	}
	
	[dictionaryOfObjectsToMove release];
}

//**********************************************************
//
//
//
//
//**********************************************************
-(NSMutableArray *)returnAttribut:(NSMutableDictionary*)_source
{	
	int j;
	id key;
	NSNumber *numberID;
	EOKeyGlobalID *gid;
	NSEnumerator *enumListSourceKey;
	NSMutableArray *keyArray = [[NSMutableArray alloc]init];
	NSMutableArray *attribut = nil;	
	NSArray			*personInfoAttrNames= nil;
	NSUserDefaults		*ud = [NSUserDefaults standardUserDefaults];
	
	//person Info
	personInfoAttrNames = [[ud arrayForKey:@"schedulerselect_personfetchkeys"] copy];
	
	[self logWithFormat:@"liste du dico pour Destination :%@",_source];
	if ((_source !=nil))
	{
		enumListSourceKey = [_source keyEnumerator];
		while ((key =[enumListSourceKey nextObject])!=nil)
		{	
			[keyArray addObject:key];
			NSMutableArray *globalIds = [NSMutableArray arrayWithCapacity:[keyArray  count]];
			for ( j = 0 ; j < [keyArray  count]; j++)
			{	
				numberID = [NSNumber numberWithUnsignedInt:[[keyArray objectAtIndex:j] intValue]];
				gid = [EOKeyGlobalID globalIDWithEntityName:@"Person" keys:&numberID keyCount:1 zone:nil];
				[self logWithFormat:@"gid Person:%@",gid];
				[globalIds addObject:gid];
				[self logWithFormat:@"#####globalIds :%@#####",globalIds];
			}		
			// attribut = [[NSMutableArray alloc]initWithCapacity:[_source count]];
			attribut = [self runCommand:@"person::get-by-globalid",@"gids",globalIds, @"attributes",personInfoAttrNames, nil];
		}
	}
	
	return attribut;
}
//**********************************************************
//
//
//
//
//**********************************************************
-(NSMutableDictionary*)createDico:(id)_selection dico:(NSMutableDictionary*)_dico
{
	id obj 	   	= nil;
	id dicoKey 	= nil;
	NSEnumerator 	*listObjectSelected;
	NSEnumerator	*valueInDico;
	
	NSMutableDictionary *newDico = [[NSMutableDictionary alloc]init];
	listObjectSelected = [_selection objectEnumerator];
	while ((obj = [listObjectSelected nextObject])!=nil)
	{       
		valueInDico= [_dico keyEnumerator];
		while ((dicoKey = [valueInDico nextObject])!=nil)
		{
			[newDico setObject:obj  forKey:dicoKey];
		}
	}
	return newDico;
}
//**********************************************************
//
//
//
//
//**********************************************************
//Methode pour WOSubmitButton

-(id) addPersonToDestination
{
	[self logWithFormat:@"#### method addPersonToDestination"];	
	[self logWithFormat:@"#### listSource avant check : %@ ",self->listSource];	
	[self logWithFormat:@"#### listDestination avant check : %@",self->listDestination];	
	[self checkItemSource:self->listSource toDestination:self->listDestination withObjectSelected:self->selectedSource];
	[self logWithFormat:@"#### listSource apres check : %@ ",self->listSource];	
	[self logWithFormat:@"#### listDestination apres check : %@",self->listDestination];
	return nil;
}

//**********************************************************
//
//
//
//
//**********************************************************
- (id) delPersonFromDestination
{
	[self logWithFormat:@"#### method delPersonFromDestination"];
	[self logWithFormat:@"#### _destination avant check : %@ ",self->listSource];	
	[self logWithFormat:@"#### _source  avant check : %@",self->listDestination];
	[self logWithFormat:@"#### listDestination avant check : %@",self->selectedDestination];	
	[self checkItemSource:self->listDestination toDestination:self->listSource withObjectSelected:self->selectedDestination];
	[self logWithFormat:@"#### _destinationapres check : %@ ",self->listSource];	
	[self logWithFormat:@"#### _source  apres check : %@",self->listDestination];
	return nil;
}

//**********************************************************
//
//
//
//
//**********************************************************
- (id) saveList
{	
	// TODO : reecrire cette methode !!! 
	[self logWithFormat:@"#####save######"];
	NSEnumerator* enumerSource;
	NSEnumerator* enumerSourceInit;
	NSEnumerator* enumerDestination;
	NSEnumerator* enumerDestinationInit;
	NSEnumerator *enumAjouterParticipant;
	NSEnumerator *enumSupprimerParticipant;
	NSMutableArray* sourceListInit = [[NSMutableArray alloc]init];
	NSMutableArray *destinationListInit = [[NSMutableArray alloc]init];
	
	id key=nil;
	id objetASupprimer=nil;
	id objetAAjouter = nil;
	id attributSupprimerParticipant;
	id attributAjouterParticipant;
	id app = [self appointmentAsEO];
	
	//ce n'est pas logique d'être dans cette page ;-)
	if (( self->listSourceInit == nil) || ( self->listSource == nil) )
		return nil;
	
	if (( self->listDestinationInit == nil) || ( self->listDestination == nil) )
		return nil;
	
	
	// participantRendezVous est le tableau qui v anous servir a finalement mettre a jour les participants du rendez-vous en 
	// fin de fonction.
	// on l'insitialise avec les participants actuels du rendez-vous : c'est voulu.
	// plus tard dans le corp de la fonction, on deletera les participants qui ne doivent plus etre la.
	NSMutableArray* participantRendezVous = [NSMutableArray arrayWithArray:[app valueForKey:@"participants"]];
	
	// Est ce que la liste source peut etre vide : 
	// oui : dans le cas ou parmis les participants au rendez-vous il n'y avait qu'une personne seule personne délégué (elle est participant en plus, bien sure) 
	// et que cette personne fait parti de la liste des délégués. Dans ce cas, l'utilisateur courrant peut supprimer ce participant et donc la liste devient vide.
	
	// RAPPEL : listSource contient à l'origine la liste des délégués participants au rendez-vous. Son état fluctue en fonction des actions de l'utilisateur
	// au moyen des boutons add ou delete. Une copie de listeSource est réalisé au début (après que listSource soit initialise biensure) afin de conserver une trace de ce
	// qu'il y avait dedans au debut. Plus tard, on se sert de la copie et de listSource, pour obtenir les changements survenus suite au modif du user.
	
	// si la liste source est vide cela veut dire que tous les délégués qui étaient participants au rendez vous ont été supprimés. Ces participants doivent donc se
	// retrouver dans le tableau supprimerParticipant
	
	// 
	
	if ( ([self->listSource count] > 0) )
	{
		[self logWithFormat:@"#### listSource (%d) :%@ ",[self->listSource count],self->listSource];
		[self logWithFormat:@"#### listSourceInit (%d) :%@ ",[self->listSourceInit count],self->listSourceInit];
		[self logWithFormat:@"#### listDestination (%d) :%@ ",[self->listDestination count],self->listDestination];
		[self logWithFormat:@"#### listDestinationInit (%d) :%@ ",[self->listDestinationInit count],self->listDestinationInit];
		
		NSMutableArray *ajouterParticipant= [[NSMutableArray alloc]initWithCapacity:16];
		NSMutableArray *supprimerParticipant= [[NSMutableArray alloc]initWithCapacity:16];
		NSEnumerator* testEnumerator = [ajouterParticipant objectEnumerator];
		id object;
		
		while ( (object = [testEnumerator nextObject]) != nil)
		{
			id value = [object valueForKey:@"companyId"];
			[self logWithFormat:@"$$$$$$$$$$  companyId value : %@",value];
		}
		
		//on enumere la listSource 
		enumerSourceInit = [self->listSourceInit keyEnumerator];
		while ((key = [enumerSourceInit nextObject])!=nil)
		{
			[self logWithFormat:@"#### ajoute key = %@ (class %@)dans sourceListInit",key,[key class]];
			[sourceListInit addObject:key];
		}
		
		[self logWithFormat:@"###sourceListInit:%@",sourceListInit];
		//on cherche si dans cette source le participant n'est pas dans le rendez vous
		//on met ce participant dans une liste temporaire pour l'ajout au rendez-vous 
		enumerSource = [self->listSource keyEnumerator];
		while ((key = [enumerSource nextObject])!=nil)
		{	
			[self logWithFormat:@"### key : %@ (class %@)",key,[key class]];
			//[source addObject:key];
			NSNumber* source = [NSNumber numberWithInt: [key intValue]];

			[self logWithFormat:@"###source:%@ (class %@)",source,[source class]];
			if (([sourceListInit containsObject:source] == NO))
			{
				[ajouterParticipant addObject:key];
			}
			else
			{
				[self logWithFormat:@"------------------ reject : %@",source];
			}
				
			[self logWithFormat:@"####ajouterParticipant :%@",ajouterParticipant];
		}
	
		[self logWithFormat:@"delParticipant"];
		
		
		enumerDestinationInit = [self->listDestinationInit keyEnumerator];
		while ((key = [enumerDestinationInit nextObject])!=nil)
		{
			[destinationListInit addObject:key];
		}
		
		if ((self->listDestination !=nil))
		{
			enumerDestination = [self->listDestination keyEnumerator];
			while ((key = [enumerDestination nextObject])!=nil)
			{	
				NSNumber* destination = [NSNumber numberWithInt: [key intValue]];
				[self logWithFormat:@"delParticipant"];
				if (([destinationListInit containsObject:destination]==NO))
				{
					[supprimerParticipant addObject:key];
				}
				else
				{
					[self logWithFormat:@"------------------ reject : %@",destination];
				}
				[self logWithFormat:@"#######supprimerParticipant :%@########",supprimerParticipant];
			}
		}
		
		if (( [ajouterParticipant count] > 0))
		{
			[self logWithFormat:@"#######  ajouterParticipant : %@",ajouterParticipant];
			enumAjouterParticipant = [ajouterParticipant objectEnumerator];
			while ((objetAAjouter = [enumAjouterParticipant nextObject])!=nil)
			{
					
					NSNumber* numberID = [NSNumber numberWithInt: [objetAAjouter intValue]];
					attributAjouterParticipant = [self runCommand:@"account::get",@"companyId",numberID, nil];
					if ( [attributAjouterParticipant isKindOfClass:[NSArray class]] == YES)
					{
						if (([participantRendezVous containsObject:[attributAjouterParticipant lastObject]]==NO))
						{
							[participantRendezVous addObject:[attributAjouterParticipant lastObject]];
						}
					}
					else
					{
						if (([participantRendezVous containsObject:attributAjouterParticipant]==NO))
						{
							[participantRendezVous addObject:attributAjouterParticipant];
						}
					}
			}
			[self logWithFormat:@"#######attributAjouterParticipant avant le add dans attributAjouterParticipant :%@#####",attributAjouterParticipant];
		}
		
		if (([supprimerParticipant  count] > 0))
		{
			[self logWithFormat:@"#######  supprimerParticipant : %@",supprimerParticipant];
			enumSupprimerParticipant = [supprimerParticipant objectEnumerator];
			while ((objetASupprimer = [enumSupprimerParticipant nextObject])!=nil)
			{		
				NSNumber* numberID = [NSNumber numberWithInt: [objetASupprimer intValue]];
				attributSupprimerParticipant = [self runCommand:@"account::get",@"companyId",numberID, nil];
				// ANCIEN
				// if (([participantRendezVous containsObject:attributSupprimerParticipant]==YES))
				// {
				// 	[participantRendezVous removeObject:attributSupprimerParticipant];
				// }
						
						
				/// NOUVEAU
				if ( [attributSupprimerParticipant isKindOfClass:[NSArray class]] == YES)
				{
					if (([participantRendezVous containsObject:[attributSupprimerParticipant lastObject]]==YES))
					{
						[participantRendezVous removeObject:[attributSupprimerParticipant lastObject]];
					}
				}
				else
				{
					if (([participantRendezVous containsObject:attributSupprimerParticipant]==YES))
					{
						[participantRendezVous removeObject:attributSupprimerParticipant];
					}
				}
			}
		}
	}
	else 
	{		
			// marche pas !!!!! 
		[self logWithFormat:@"######remove si listeSource vide"];
		NSMutableArray* source = [[NSMutableArray alloc]initWithCapacity:[self->listSourceInit count]];
		enumerSource = [self->listSourceInit keyEnumerator];
		while ((key = [enumerSource nextObject])!=nil)
		{	
			[source addObject:key];
		}
			
		enumSupprimerParticipant = [source 	objectEnumerator];
		while ((objetASupprimer=[enumSupprimerParticipant nextObject])!=nil)
		{
			NSNumber* numberID = [NSNumber numberWithInt: [objetASupprimer intValue]];
			attributSupprimerParticipant = [self runCommand:@"account::get",@"companyId",numberID, nil];
			if ( [attributSupprimerParticipant isKindOfClass:[NSArray class]] == YES)
			{
				if (([participantRendezVous containsObject:[attributSupprimerParticipant lastObject]]==YES))
				{
					[participantRendezVous removeObject:[attributSupprimerParticipant lastObject]];
				}
			}
			else
			{
				if (([participantRendezVous containsObject:attributSupprimerParticipant]==YES))
				{
					[participantRendezVous removeObject:attributSupprimerParticipant];
				}
			}
		}
	}
	
	
	[self logWithFormat:@"##### participants rdv : %s %d participantRendezVous = %@",__FILE__,__LINE__,participantRendezVous];
	[self updateParticipants:participantRendezVous ofEO:app logText:[[self labels] valueForKey:@"addParticipants"]];
	return nil;
}

@end //SkyDelegationList



//**********************************************************
//
//
//
//
//**********************************************************
/*
static int compareParticipants(id part1, id part2, void *context)
{
	if ([[part1 valueForKey:@"isTeam"] boolValue])
	{
		if (![[part2 valueForKey:@"isTeam"] boolValue])
			return NSOrderedAscending;
		{
			id d1 = [part1 valueForKey:@"description"];
			id d2 = [part2 valueForKey:@"description"];
			
			if (d1 == nil) d1 = @"";
			if (d2 == nil) d2 = @"";
			
			return ([d1 caseInsensitiveCompare:d2]);
		}
	}
	
	if ([[part2 valueForKey:@"isTeam"] boolValue])
		return NSOrderedDescending;
	
	{
		id n1 = [part1 valueForKey:@"name"];
		id n2 = [part2 valueForKey:@"name"];
		
		if (n1 == nil) n1 = @"";
		if (n2 == nil) n2 = @"";
		
		return ([n1 caseInsensitiveCompare:n2]);
	}
}

*/


