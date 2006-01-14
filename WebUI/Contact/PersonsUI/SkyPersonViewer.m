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

#include <OGoFoundation/OGoViewerPage.h>

@class NSUserDefaults, NSMutableDictionary, NSString, NSArray, NSDictionary;
@class NSMutableArray, NSData;

@interface SkyPersonViewer : OGoViewerPage
{
  /* for tab view */
  NSString       *tabKey;
  BOOL           setViewerTitle;

  NSString       *viewerTitle;

  /* for viewer config */
  NSUserDefaults *defaults;

  /* apt-datasource */
  id             aptsOfPerson;
  NSString       *aptViewKey;

  BOOL           isLDAPEnabled;
  BOOL           isProjectEnabled;

  NSString       *formLetterType;
}

- (NSData *)imageData;

@end /* SkyPersonViewer */

#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOKeyGlobalID.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyAddressConverterDataSource.h>
#include <NGMime/NGMimeType.h>
#include "common.h"

@class NSEnumerator;

@interface SkyPersonViewer(PrivateMethods)
- (void)setTabKey:(NSString *)_key;
- (NSString*)tabKey;
- (BOOL)hasImage;
- (BOOL)isInEnterprise;
- (NSDictionary *)_idDict;
- (BOOL)isProfessionalEdition;
- (BOOL)hasLogTab;
- (NSString *)_personFullName;

@end

@implementation SkyPersonViewer

static BOOL         isLinkEnabled             = NO;
static BOOL         isLogEnabled              = YES;
static BOOL         enableTaskReferredPersons = NO;
static NSArray      *AptAttributeNames        = nil;
static NSDictionary *AptFetchHints            = nil;
static NGMimeType   *eoJobType                = nil;
static BOOL         hasSkyGenericLDAPViewer   = NO;
static BOOL         hasSkyProject4Desktop     = NO;
static NSArray      *formLetterTypes          = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  if (didInit) return;
  didInit = YES;

  if ([bm bundleProvidingResource:@"SkyGenericLDAPViewer"
	  ofType:@"WOComponents"] != nil)
    hasSkyGenericLDAPViewer = YES;
  if ([bm bundleProvidingResource:@"SkyProject4Desktop"
	  ofType:@"WOComponents"] != nil)
    hasSkyProject4Desktop = YES;

  isLinkEnabled             = [ud boolForKey:@"OGoPersonLinksEnabled"];
  enableTaskReferredPersons = [ud boolForKey:@"JobReferredPersonEnabled"];

  if (AptAttributeNames == nil) {
    AptAttributeNames = 
      [[ud arrayForKey:@"person_viewer_aptfetchattrs"] copy];
  }
  if (AptFetchHints == nil) {
    AptFetchHints = [[NSDictionary alloc] 
                      initWithObjectsAndKeys:AptAttributeNames,
                        @"attributeKeys", nil];
  }
  
  formLetterTypes = 
    [[[[ud dictionaryForKey:@"LSPersonFormLetter"] allKeys]
       sortedArrayUsingSelector:@selector(compare:)] copy];
  NSLog(@"SkyPersonViewer: form letter types: %@",
	[formLetterTypes componentsJoinedByString:@", "]);
  
  if (eoJobType == nil)
    eoJobType = [[NGMimeType mimeType:@"eo" subType:@"job"] retain];
}

- (BOOL)isLDAPLicensed {
  // TODO: deprecated, we are OpenSource now !!! :-)
  return YES;
}

- (id)init {
  if ((self = [super init]) != nil) {
    [self registerForNotificationNamed:LSWUpdatedPersonNotificationName];
    
    self->isLDAPEnabled    = hasSkyGenericLDAPViewer;
    self->isProjectEnabled = hasSkyProject4Desktop;
    
    self->defaults = [[[self session] userDefaults] retain];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->formLetterType release];
  [self->tabKey       release];
  [self->viewerTitle  release];
  [self->defaults     release];
  [self->aptViewKey   release];
  [self->aptsOfPerson release];
  [super dealloc];
}

/* misc */

- (NSString *)_personFullName {
  NSMutableString *str;
  id              eo;
  NSString        *fn;

  eo     = [self object];
  str    = [[[NSMutableString alloc] initWithCapacity:30] autorelease];

  [str appendString:[[eo valueForKey:@"name"] stringValue]];

  fn = [eo valueForKey:@"firstname"];
  
  if ([fn isNotNull] && [[fn stringValue] length] > 0) {
    [str appendString:@", "];
    [str appendString:[fn stringValue]];
  }
  return str;
}

- (void)_setViewerTitle {
  // TODO: use a formatter for that
  NSMutableString *str;
  id              eo;
  NSString        *labels;

  str    = [NSMutableString stringWithCapacity:128];
  eo     = [self object];
  labels = [self labels];

  /* the name of the person */
  [str appendString:[self _personFullName]];

  /* add private info */
  if ([[eo valueForKey:@"isPrivate"] boolValue]) {
    [str appendString:@" ("];
    [str appendString:[labels valueForKey:@"private"]];
    [str appendString:@")"];
  }

  /* add read-only info */
  if ([[eo valueForKey:@"isReadonly"] boolValue]) {
    [str appendString:@" ("];
    [str appendString:[labels valueForKey:@"readonly"]];
    [str appendString:@")"];
  }

  /* add account info */
  if ([[eo valueForKey:@"isAccount"] boolValue]) {
    [str appendString:@" ("];
    [str appendString:[labels valueForKey:@"skyrixUser"]];
    [str appendString:@")"];
  }
  ASSIGN(self->viewerTitle, str);
}

- (void)_loadTabKey {
  NSString *tabKeyStr;

  tabKeyStr = [self->defaults stringForKey:@"persons_sub_view"];
  
  if ((tabKeyStr == nil) ||
      (([tabKeyStr isEqualToString:@"picture"]) && (![self hasImage]))) {
    [self setTabKey:@"attributes"];
  }
  else if ([tabKeyStr isEqualToString:@"mailing"] && [self isInEnterprise]) {
    [self setTabKey:@"enterprises"];
  }
  else if (([tabKeyStr isEqualToString:@"enterprises"]) &&
             (![self isInEnterprise])){
    [self setTabKey:@"mailing"];
  }
  else {
    [self setTabKey:tabKeyStr];
  }
  [self->defaults setObject:[self tabKey] forKey:@"persons_sub_view"];
}

/* notifications */

- (id)person {
  return [self object];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWUpdatedPersonNotificationName]) {
    self->setViewerTitle = YES;
    [self setTabKey:@"attributes"];
  }
  else if ([_cn isEqualToString:LSWDeletedAccountNotificationName]) {
    if ([[_object globalID] isEqual:[[self person] globalID]]) {
      self->setViewerTitle = YES;
      [[self person] reload];
    }
  }
  else if ([_cn isEqualToString:LSWUpdatedAccountNotificationName]) {
    if ([[_object globalID] isEqual:[[self person] globalID]]) {
      self->setViewerTitle = YES;
      [[self person] reload];
    }
  }
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id obj;
  
  if (![super prepareForActivationCommand:_command type:_type
              configuration:_cmdCfg]) 
    return NO;
  
  if ((obj = [self object]) == nil)
    return NO;
  
  if (![obj isKindOfClass:[SkyPersonDocument class]]) {
    id ctx;
    
    if ([obj isKindOfClass:[EOKeyGlobalID class]]) {
      obj = [[self runCommand:@"object::get-by-globalID",
                                @"gid", obj, nil] lastObject];
    }
    else {
      // should be an eo (activated by LSWViewAction/viewPerson)
      if ([obj valueForKey:@"comment"] == nil) {
          [self runCommand:@"person::get-comment",
                @"object",      obj,
                @"relationKey", @"comment",
                nil];
      }
    }
    ctx = [(OGoSession *)[self session] commandContext];
    obj = [[SkyPersonDocument alloc] initWithEO:obj context:ctx];
    [self setObject:obj];
    [obj release]; obj = nil;
  }
  self->setViewerTitle = YES;
  [self _loadTabKey];
  return YES;
}

/* accessors */

- (void)setTabKey:(NSString *)_key {
  ASSIGNCOPY(self->tabKey, _key);
  [self->defaults setObject:_key forKey:@"persons_sub_view"];
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (NSString *)imageType {
  return [[self person] imageType];
}

- (BOOL)hasImage {
  return [[self imageData] length] > 0;
}

- (BOOL)isLDAPEnabled {
  return self->isLDAPEnabled;
}

- (BOOL)isProjectEnabled {
  return self->isProjectEnabled;
}

- (BOOL)isEditDisabled {
  id am;
  
  am = [[[self session] valueForKey:@"commandContext"] accessManager];
  return ![am operation:@"w" 
              allowedOnObjectID:[[self object] valueForKey:@"globalID"]];
  
}

- (BOOL)isLogTabEnabled {
  return isLogEnabled && [[self application] hasLogTab];
}
- (BOOL)isLinkTabEnabled {
  return isLinkEnabled;
}

- (BOOL)isInEnterprise {
  /* 
     TODO: this should be replace with a *much* shorter command call which
           checks the assignment table
  */
  return ([[[[self person] enterpriseDataSource] fetchObjects] count] > 0)
    ? YES
    : NO;
}
- (BOOL)isPersonNotRoot {
  // TODO: should use some command to determine root?
  NSNumber *cid;
  
  cid = [[self person] valueForKey:@"companyId"];
  if (![cid isNotNull]) return YES;
  return ([cid intValue] == 10000) ? NO : YES;
}

- (BOOL)isPersonLoggedInAccount {
  return [[self object] isEqual:[[self session] activeAccount]];
}

- (BOOL)isEditEnabled {
  return ![self isEditDisabled];
}

- (BOOL)canMakeAccountFromPerson {
  if ([LSCommandContext useLDAPAuthorization]) return NO;
  if (![[self session] activeAccountIsRoot]) return NO;
  return ([[[self object] valueForKey:@"isAccount"] boolValue])
    ? NO : YES;
}

- (BOOL)objectIsAccountButNotRoot {
  if (![[self session] activeAccountIsRoot]) return NO;
  return ([[[self object] valueForKey:@"isAccount"] boolValue])
    ? YES : NO;
}

- (BOOL)canViewAccount {
  return [self objectIsAccountButNotRoot];
}

- (BOOL)canEditAccount {
  return [self objectIsAccountButNotRoot];
}

- (NSString *)objectUrlKey {
  return [NSString stringWithFormat:
                     @"wa/activate?oid=%@",
                     [[self object] valueForKey:@"companyId"]];
}

- (NSString *)viewerTitle {
  return self->viewerTitle;
}

- (NSData *)imageData {
  return [[self person] imageData];
}

- (NSString *)privateLabel {
  NSString *l;

  l = [[self labels] valueForKey:@"privateLabel"];

  return (l != nil) ? l : @"private";
}

- (BOOL)showLDAPInfo {
  NSUserDefaults *ud;
  NSString *tmp;
  
  if (!self->isLDAPEnabled)
    return NO;

  ud = [NSUserDefaults standardUserDefaults];

  tmp = [ud stringForKey:@"LSAuthLDAPServer"];
  if ([tmp length] == 0)
    return NO;
  tmp = [ud stringForKey:@"LSAuthLDAPServerRoot"];
  if ([tmp length] == 0)
    return NO;
  
  if (([[[self object] valueForKey:@"isAccount"] boolValue]))
    return YES;
  
  return NO;
}

/* actions */

- (void)syncAwake {
  [super syncAwake];

  [self _loadTabKey];
  
  if (self->setViewerTitle) {
    [self _setViewerTitle];
    self->setViewerTitle = NO;
  }
}

- (void)syncSleep {
  [self->defaults synchronize];
  [self->formLetterType release]; self->formLetterType = nil;
  [super syncSleep];
}

/* downloads */

- (id)formLetterTarget {
  return [[self context] contextID];
}

- (NSArray *)formLetterTypes {
  return formLetterTypes;
}

- (void)setFormLetterType:(NSString *)_ft {
  ASSIGNCOPY(self->formLetterType, _ft);
}
- (NSString *)formLetterType {
  return self->formLetterType;
}

/* private methods */

- (NSDictionary *)_idDict {
  NSMutableDictionary *result;
  id                  compId;

  result = [NSMutableDictionary dictionary];
  compId = [[self object] valueForKey:@"companyId"];
  
  [result setObject:compId                 forKey:@"companyId"];
  [result setObject:[[self object] entity] forKey:@"entity"];

  return result;
}

/* appointmentViewer support */

- (void)setAptViewKey:(NSString *)_key {
  ASSIGN(self->aptViewKey,_key);
}
- (NSString *)aptViewKey {
  if (self->aptViewKey == nil)
    [self setAptViewKey:@"list"];
  return self->aptViewKey;
}

- (NSCalendarDate *)weekStart {
  return [[NSCalendarDate date] mondayOfWeek];
}

- (EODataSource *)aptsOfPerson {
  // TODO: this should be moved out
  EOFetchSpecification    *s     = nil;
  SkyAppointmentQualifier *q;
  NSCalendarDate          *sd, *ed;
  id person;
  
  if (self->aptsOfPerson)
    return self->aptsOfPerson;
  
  // TODO: need a date selection over here
  sd = [[self weekStart] beginOfDay];
  ed = [[sd dateByAddingYears:0 months:1 days:-1] endOfDay];
  q  = [[[SkyAppointmentQualifier alloc] init] autorelease];
  [q setStartDate:sd];
  [q setEndDate:ed];
  [q setTimeZone:[[self session] timeZone]];
  person = [[self person] valueForKey:@"globalID"];
  [q setCompanies:[NSArray arrayWithObject:person]];
  [q setResources:[NSArray array]];
    
  s = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                            qualifier:q sortOrderings:nil];
  [s setHints:AptFetchHints];
  
  self->aptsOfPerson = [[SkyAptDataSource alloc] init];
  [(SkyAptDataSource *)self->aptsOfPerson 
		       setContext:[(id)[self session] commandContext]];
  [(SkyAptDataSource *)self->aptsOfPerson
                       setFetchSpecification:s];
  return self->aptsOfPerson;
}

- (id)switchToAptView {
  [self setAptViewKey:@"view"];
  return nil;
}

- (id)switchToAptList {
  [self setAptViewKey:@"list"];
  return nil;
}

- (NSArray *)accessChecks {
  static NSArray *accessChecks = nil;
  
  if (accessChecks == nil)
    accessChecks = [[NSArray alloc] initWithObjects:@"r", @"w", nil];
  
  return accessChecks;
}

- (BOOL)isAccessRightEnabled {
  // TODO: deprecated, we are OpenSource now !!! :-)
  // Note: it might make sense to disabled extended access rights nevertheless
  //       because it complicates UI and adds a performance hit!
  return YES;
}

- (id)editAccess {
  WOComponent *page;
  
  if (![self isAccessRightEnabled]) {
    [self setErrorString:@"access editor is disabled."];
    return nil;
  }
  
  if ((page = [self pageWithName:@"SkyCompanyAccessEditor"]) == nil) {
    static BOOL didLog = NO;
    [self setErrorString:@"did not find the access editor!"];
    if (!didLog) {
      [self logWithFormat:
              @"Note: access rights enabled, but "
              @"SkyCompanyAccessEditor component could not be found!"];
      didLog = YES;
    }
  }
  [page takeValue:[[self person] globalID] forKey:@"globalID"];
  [page takeValue:[self accessChecks]      forKey:@"accessChecks"];
  return page;
}

- (id)accessIds {
  // TODO: I don't get this, what about the denied operations?
  return [[[(id)[self session] commandContext] accessManager]
                      allowedOperationsForObjectId:[[self person] globalID]];
}

- (id)eoForPerson {
  return [[self runCommand:@"object::get-by-globalID",
                @"gid", [[self object] globalID], nil] lastObject];
}

- (id)personToAccount {
  id eo = [self eoForPerson];
  
  [self runCommand:@"person::toaccount", @"object", eo, nil];
  [[self person] reload];
  // TODO: shouldn't such notifications be posted by the command?! probably!
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:SkyUpdatedPersonNotification
                         object:[self person]];
  [self _setViewerTitle];
  return nil;
}

- (id)viewAccount {
  id eo = [self eoForPerson];
  return [[[self session] navigation] activateObject:eo
                                      withVerb:@"viewPreferences"];
}

- (id)editAccount {
  id eo = [self eoForPerson];
  return [[[self session] navigation] activateObject:eo
                                      withVerb:@"editPreferences"];
}

/* "referred-person-jobs" */

- (id)newJob {
  // TODO: this should use regular activation?
  id page;
  
  page = [self pageWithName:@"LSWJobEditor"];
  
  [page takeValue:[self object] forKey:@"referredPerson"];
  [page prepareForActivationCommand:@"new"
        type:eoJobType configuration:nil];
  
  return page;
}

- (BOOL)hasNewJob {
  return enableTaskReferredPersons;
}

@end /* SkyPersonViewer */
