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

#import <Foundation/NSObject.h>

@class NSString, NSCalendarDate, NSUserDefaults;
@class SkyAppointmentDataSource;

@interface SkyAptNotify : NSObject
{
  // options
  BOOL           beVerbose;
  
  NSString       *skyrixUser;
  NSString       *skyrixPwd;
  
  NSString       *fromAddress;
  NSString       *sentResourcesFile;
  int            checkprefix; // minutes
  NSString       *defaultTimeZone;
  NSString       *sendmailPath;
  NSString       *sendpagePath;
  NSString       *pagerhost;
  NSString       *sendpageFrom;
  BOOL           sendpageEnabled;
  NSString       *sendpageTitle;
  NSString       *sendpageWith;

  // SKYRIX
  id             ctx;
  NSUserDefaults *ud;
  SkyAppointmentDataSource *aptDataSource;

  // fetching
  NSCalendarDate *start;
  NSCalendarDate *end;
  NSCalendarDate *now;
}

- (NSCalendarDate *)notifyStart;
- (NSCalendarDate *)notifyEnd;
- (id)aptDataSource;
- (id)context;
- (NSUserDefaults *)userDefaults;

- (int)runInExceptionHandler;

@end

#include "common.h"
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <NGExtensions/NSNull+misc.h>
#include <NGExtensions/EODataSource+NGExtensions.h>
#include <NGMail/NGMail.h>
#include <NGMime/NGMime.h>

#include <OGoScheduler/SkyAppointmentDataSource.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <OGoScheduler/SkyAppointmentDocument.h>

@interface SkyAptNotify(PrivateMethods)
- (void)_loadSkyrix;
- (NSArray *)_fetchNotifiedApts;
- (NSArray *)_fetchResourceApts;
- (NSArray *)_fetchAptResources;
- (void)_processApt:(SkyAppointmentDocument *)_apt;
- (id)_processResourceApt:(SkyAppointmentDocument *)_apt
  resourceName:(NSString *)_resourceName
  resource:(NSDictionary *)_resourceDict
  saveDict:(NSDictionary *)_sendResource;
@end /* SkyAptNotify(PrivateMethods) */

@interface SkyAptNotify(SMSMethods)
- (void)_sendSMSForApt:(SkyAppointmentDocument *)_apt
  toAccounts:(NSArray *)_accounts
  participants:(NSArray *)_parts
  owner:(id)_owner
  sms:(id)_sms;
- (NSString *)_buildSMSWithApt:(SkyAppointmentDocument *)_apt
  participants:(NSArray *)_parts;
@end /* SkyAptNotify(SMSMethods) */

@implementation SkyAptNotify

#define CALENDARFORMAT  @"%Y-%m-%d %H:%M (%Z)"
#define CALENDARFORMAT2 @"%Y-%m-%d %H:%M"

static NSString *_msgFormat  = nil;
static NSString *_msgFormat2 = nil;
static NSNumber *noNum       = nil;
static BOOL     coreOnException = NO;

+ (void)initialize {
  NSUserDefaults *udefs = [NSUserDefaults standardUserDefaults];
  NSString *msgtemplate;
  id tmp;

  noNum = [[NSNumber numberWithBool:NO] retain];
  
  msgtemplate = 
    @"Appointment Notification\n"
    @"\n"
    @"  title:        %@\n"
    @"  start-date:   %@\n"
    @"  end-date:     %@\n"
    @"  location:     %@\n"
    @"  resources:    %@\n"
    @"  participants: %@\n"
    @"  comment:\n%@\n";
  
  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  noNum,                        @"AptNotifyBeVerbose",
                  @"root",                      @"AptNotifySkyrixUser",
                  @"",                          @"AptNotifySkyrixPassword",
                  @"ogo@localhost",             @"AptNotifyFromAddress",
                  @"/opt/opengroupware.org/logs/sent-resources",
                  @"AptNotifySentResourcesFile",
                  [NSNumber numberWithInt:600], @"AptNotifyCheckPrefix",
                  @"MET",                       @"AptNotifyDefaultTimeZone",
                  @"/usr/lib/sendmail",         @"AptNotifySendmailPath",
                  @"/usr/lib/sendpage",         @"AptNotifySendpagePath",
                  @"localhost",                 @"AptNotifySendpageHost",
                  @"OpenGroupware.org",         @"AptNotifySendpageFrom",
                  noNum,                        @"AptNotifySendpageEnabled",
                  @"Erinnerung:",               @"AptNotifySendpageTitle",
                  @"mit:",                      @"AptNotifySendpageWith",
                  noNum,                        @"AptNotifySendpageToExternal",
                  noNum,                        @"AptNotifySendmailToExternal",
		  msgtemplate,                  @"AptNotifyMessageFormat",
                  nil];
  [udefs registerDefaults:tmp];
  
  _msgFormat  = nil;
  _msgFormat2 = nil;
  coreOnException = [udefs boolForKey:@"AptNotifyDumpCore"];
}

- (id)init {
  if ((self = [super init])) {
    self->ud = [[NSUserDefaults standardUserDefaults] retain];
    
    self->beVerbose   = [self->ud  boolForKey:@"AptNotifyBeVerbose"];
    self->skyrixUser  = [[self->ud stringForKey:@"AptNotifySkyrixUser"] copy];
    self->skyrixPwd   = 
      [[self->ud stringForKey:@"AptNotifySkyrixPassword"] copy];
    
    self->fromAddress = [[self->ud stringForKey:@"AptNotifyFromAddress"] copy];
    
    self->sentResourcesFile =
      [[self->ud stringForKey:@"AptNotifySentResourcesFile"] copy];
    self->checkprefix = [self->ud integerForKey:@"AptNotifyCheckPrefix"];
    self->defaultTimeZone =
      [[self->ud stringForKey:@"AptNotifyDefaultTimeZone"] copy];
    self->sendmailPath =
      [[self->ud stringForKey:@"AptNotifySendmailPath"] copy];
    
    self->sendpagePath =
      [[self->ud stringForKey:@"AptNotifySendpagePath"] copy];
    self->pagerhost    = 
      [[self->ud stringForKey:@"AptNotifySendpageHost"] copy];
    self->sendpageFrom = 
      [[self->ud stringForKey:@"AptNotifySendpageFrom"] copy];
    self->sendpageEnabled = [self->ud boolForKey:@"AptNotifySendpageEnabled"];

    self->sendpageTitle = 
      [[self->ud stringForKey:@"AptNotifySendpageTitle"] copy];
    self->sendpageWith  =
      [[self->ud stringForKey:@"AptNotifySendpageWith"] copy];
  }
  return self;
}

- (void)dealloc {
  [self->skyrixUser        release];
  [self->skyrixPwd         release];
  [self->fromAddress       release];
  [self->sentResourcesFile release];
  [self->defaultTimeZone   release];
  [self->sendmailPath      release];
  [self->sendpagePath      release];
  [self->pagerhost         release];
  [self->sendpageFrom      release];
  [self->sendpageTitle     release];
  [self->sendpageWith      release];

  [self->ctx release];
  [self->ud  release];
  [self->aptDataSource release];

  [self->start release];
  [self->end   release];
  [self->now   release];
  [super dealloc];
}

/* accessors */

- (id)context {
  if (self->ctx == nil)
    [self _loadSkyrix];
  
  return self->ctx;
}
- (id)aptDataSource {
  if (self->aptDataSource == nil)
    self->aptDataSource =
      [[SkyAppointmentDataSource alloc] initWithContext:[self context]];
  return self->aptDataSource;
}

- (NSUserDefaults *)userDefaults {
  return self->ud;
}
- (NSCalendarDate *)now {
  if (self->now == nil)
    self->now = [[NSCalendarDate date] retain];
  return self->now;
}

- (NSCalendarDate *)notifyStart {
  if (self->start == nil) {
    self->start = [[[self now] dateByAddingYears:0 months:0 days:0 hours:0
                               minutes:-self->checkprefix seconds:0] retain];
  }
  return self->start;
}
- (NSCalendarDate *)notifyEnd {
  if (self->end == nil) {
    self->end = [[[self now] dateByAddingYears:0 months:0 days:10 hours:0
                             minutes:0 seconds:0] retain];
  }
  return self->end;
}

- (NSArray *)notifiedApts {
  return [self _fetchNotifiedApts];
}
- (NSArray *)resourceApts {
  return [self _fetchResourceApts];
}
- (NSArray *)aptResources {
  return [self _fetchAptResources];
}
- (NSDictionary *)mappedAptResources {
  NSArray             *all;
  NSEnumerator        *e;
  id                  one;
  NSMutableDictionary *dict;
  
  all  = [self aptResources];
  dict = [NSMutableDictionary dictionaryWithCapacity:[all count]];
  
  e = [all objectEnumerator];
  while ((one = [e nextObject]))
    [dict setObject:one forKey:[one valueForKey:@"name"]];
  return dict;
}

- (NSArray *)savedSentResources {
  NSString       *contents;
  NSArray        *lines;
  NSEnumerator   *e;
  id             one;
  NSMutableArray *all;
  
  contents = [NSString stringWithContentsOfFile:self->sentResourcesFile];
  lines    = [contents componentsSeparatedByString:@"\n"];
  all = [NSMutableArray array];
  
  e = [lines objectEnumerator];
  while ((one = [e nextObject])) {
    NSNumber *dateId, *version;
    
    one = [one componentsSeparatedByString:@","];
    
    if ([one count] != 3)
      continue;
    
    dateId  = [NSNumber numberWithInt:[[one objectAtIndex:0] intValue]];
    version = [NSNumber numberWithInt:[[one objectAtIndex:1] intValue]];
    one = [[NSDictionary alloc] initWithObjectsAndKeys:
                          dateId,  @"dateId",
                          version, @"objectVersion",
                          [one objectAtIndex:2], @"resourceName",
			nil];
    [all addObject:one];
    [one release];
  }
  return all;
}
- (void)saveSentResources:(NSArray *)_resources {
  NSMutableArray *lines;
  NSEnumerator   *e;
  id             one;
  
  lines = [NSMutableArray array];
  e     = [_resources objectEnumerator];
  while ((one = [e nextObject])) {
    one = [[NSString alloc] initWithFormat:@"%@,%@,%@",
                    [one valueForKey:@"dateId"],
                    [one valueForKey:@"objectVersion"],
                    [one valueForKey:@"resourceName"]];
    [lines addObject:one];
    [one release];
  }
  
  // TODO: no atomically?
  [[lines componentsJoinedByString:@"\n"] 
    writeToFile:self->sentResourcesFile atomically:NO];
}

/* run */

- (void)processNotifyApt:(SkyAppointmentDocument *)one {
  NSCalendarDate *startDate;
  NSNumber       *notifyTime;
  NSCalendarDate *notifyDate;
  NSCalendarDate *earlier;
    
  startDate  = [one startDate];
  notifyTime = [one notificationTime];

  notifyDate = [startDate dateByAddingYears:0 months:0 days:0 hours:0
			  minutes:-[notifyTime intValue] seconds:0];
    
  if ([notifyTime intValue] < 0)
    // invalid notificationTime
    return;

  if (self->beVerbose)
    NSLog(@"comparing now: %@ with %@", [self now], notifyDate);
  
  earlier = (NSCalendarDate *)[[self now] earlierDate:notifyDate];
  if (earlier == notifyDate)
    [self _processApt:one];
}

- (void)processNotifyApts {
  SkyAppointmentDocument *one;
  NSEnumerator *e;
  
  e = [[self notifiedApts] objectEnumerator];
  while ((one = [e nextObject]))
    [self processNotifyApt:one];
}

- (id)processResourceApt:(SkyAppointmentDocument *)_apt
  resourceDict:(NSDictionary *)_resource
  toSaveResource:(NSDictionary *)_toSave
{
  NSCalendarDate *startDate;
  NSNumber       *notifyTime;
  NSCalendarDate *notifyDate;
  NSCalendarDate *earlier    = nil;

  startDate  = [_apt startDate];
  notifyTime = [_resource valueForKey:@"notificationTime"];
  notifyDate = [startDate dateByAddingYears:0 months:0 days:0 hours:0
                          minutes:-[notifyTime intValue] seconds:0];
  if ([notifyTime intValue] < 0)
    // invalid notification Time
    return nil;

  earlier = (NSCalendarDate *)[[self now] earlierDate:notifyDate];
  if (earlier == notifyDate)
    return [self _processResourceApt:_apt
                 resourceName:[_resource valueForKey:@"name"]
                 resource:_resource
                 saveDict:_toSave];
  return nil;
}
- (void)saveSentResources:(NSArray *)_toSave
  old:(NSArray *)_saved
  aptIds:(NSArray *)_aptIds
{
  NSMutableArray *merged;
  NSEnumerator   *e;
  id             one;
  
  merged = [NSMutableArray array];
  e = [_saved objectEnumerator];
  while ((one = [e nextObject])) {
    if ([_aptIds containsObject:[one valueForKey:@"dateId"]])
      [merged addObject:one];
  }
  e = [_toSave objectEnumerator];
  while ((one = [e nextObject])) {
    if (([_aptIds containsObject:[one valueForKey:@"dateId"]]))
      [merged addObject:one];
  }
  [self saveSentResources:merged];
}

- (void)processResourceApts {
  // TODO: split this big method
  NSEnumerator *e;
  NSDictionary *aptRes;
  NSArray      *saved;
  id           one;
  NSArray      *resources = nil;
  NSEnumerator *resE      = nil;
  id           res        = nil;
  NSNumber     *ov        = nil;
  NSDictionary *control   = nil;
  NSMutableArray *toSave;
  NSMutableArray *aptIds;

  e      = [[self resourceApts] objectEnumerator];
  aptRes = [self mappedAptResources];
  saved  = [self savedSentResources];
  toSave = [NSMutableArray arrayWithCapacity:4];
  aptIds = [NSMutableArray arrayWithCapacity:4];
  
  // going through apts
  while ((one = [e nextObject])) {
    NSNumber *dateId;
    
    dateId = [(EOKeyGlobalID *)[one globalID] keyValues][0];
    [aptIds addObject:dateId];
    
    resources = [[one resourceNames]
                      componentsSeparatedByString:@","];
    resE      = [resources objectEnumerator];
    // going through resources of apt
    while ((res = [resE nextObject])) {
      res = [res stringByTrimmingWhiteSpaces];
      ov = [one objectVersion];
      if (ov == nil)
        ov = [NSNumber numberWithInt:0];
      control = [[NSDictionary alloc] initWithObjectsAndKeys:
					dateId, @"dateId",
				        ov,     @"objectVersion",
				        res,    @"resourceName",
				      nil];
      if (![saved containsObject:control]) {
        id result;
	
	result = [self processResourceApt:one
		       resourceDict:[aptRes valueForKey:res]
		       toSaveResource:control];
        if (result != nil)
          [toSave addObject:result];
      }
      [control release];
    } // going through resources
  } // going through apts
  [self saveSentResources:toSave old:saved aptIds:aptIds];
}

- (void)run {
  [[self context] begin];
  [self processNotifyApts];
  [self processResourceApts];
  [[self context] commit];
}

- (int)_handleRunException:(NSException *)_exception {
  NSLog(@"SkyAptNotify failed! catched: %@", _exception);
  
  if (coreOnException) {
    NSLog(@"aborting after exception as requested (AptNotifyDumpCore)");
    abort();
  }
  return -1;
}

- (int)runInExceptionHandler {
  int rc = 0;
  
  NS_DURING
    [self run];
  NS_HANDLER
    rc = [self _handleRunException:localException];
  NS_ENDHANDLER;
  return rc;
}

@end /* SkyAptNotify */

@implementation SkyAptNotify(PrivateMethods)

- (void)_loadSkyrix {
  OGoContextManager *app;
  OGoContextSession *sn;
  
  [self->ctx release]; self->ctx = nil;
  
  if ((app = (id)[OGoContextManager defaultManager]) == nil)
    NSAssert(NO, @"Could not start OGoContextManager."
             @"Probably not configured yet");
  
  if (![app isLoginAuthorized:self->skyrixUser password:self->skyrixPwd])
    NSAssert1(NO, @"Login '%@' not authorized", self->skyrixUser);

  if ((sn = [app login:self->skyrixUser password:self->skyrixPwd
                 isSessionLogEnabled:NO]) == nil)
    NSAssert1(NO, @"could not login '%@' into OGo", self->skyrixUser);

  [sn activate];
  
  self->ctx = [[sn commandContext] retain];
}

/* fetching */
- (EOFetchSpecification *)_fetchSpecForNotifiedApts {
  SkyAppointmentQualifier *qual = nil;
  EOFetchSpecification    *fs    = nil;
  
  qual = [[[SkyAppointmentQualifier alloc] init] autorelease];
  [qual setStartDate:[self notifyStart]];
  [qual setEndDate:[self notifyEnd]];
  [qual setOnlyNotified:YES];
  
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                             qualifier:qual sortOrderings:nil];
  return fs;
}
- (NSArray *)_fetchNotifiedApts {
  SkyAppointmentDataSource *ds = [self aptDataSource];
  NSArray                  *rs = nil;
  [ds setFetchSpecification:[self _fetchSpecForNotifiedApts]];
  rs =  [ds fetchObjects];
  if (self->beVerbose)
    NSLog(@"fetched notifiedApts (%d)", [rs count]);
  return rs;
}

- (EOFetchSpecification *)_fetchSpecForResourceApts {
  SkyAppointmentQualifier *qual = nil;
  EOFetchSpecification    *fs    = nil;
  
  qual = [[SkyAppointmentQualifier alloc] init];
  [qual setStartDate:[self notifyStart]];
  [qual setEndDate:[self notifyEnd]];
  [qual setOnlyResourceApts:YES];
  AUTORELEASE(qual);

  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                             qualifier:qual sortOrderings:nil];
  return fs;
}
- (NSArray *)_fetchResourceApts {
  SkyAppointmentDataSource *ds = [self aptDataSource];
  NSArray                  *rs = nil;
  [ds setFetchSpecification:[self _fetchSpecForResourceApts]];
  rs =  [ds fetchObjects];
  if (self->beVerbose)
    NSLog(@"fetched resourceApts (%d)", [rs count]);
  return rs;
}

- (EOQualifier *)_qualifierForAptResources {
  EOQualifier *qual = nil;
  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"(NOT ((name=%@ ) "
                      @"OR (name=''))) "
                      @"AND (%@ > -1)",
                      [NSNull null], @"notification_time"];
  return qual;
}
- (NSArray *)_fetchAptResources {
  NSArray *rs;
  
  rs = [[self context] runCommand:@"appointmentresource::get",
                       @"returnType",
                       [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                       nil];
  rs = [rs filteredArrayUsingQualifier:[self _qualifierForAptResources]];
  if (self->beVerbose)
    NSLog(@"fetched aptResources (%d)", [rs count]);
  return rs;
}

/* processing */

- (id)_ownerForApt:(id)_apt {
  NSArray *person;

  person =
    [[self context] runCommand:@"person::get-by-globalid",
                    @"gid", [_apt ownerGID],
                    nil];
  return [person lastObject];
}
- (NSArray *)_participantsForApt:(id)_apt {
  NSArray *parts;

  parts =
    [[self context] runCommand:@"appointment::get-participants",
                    @"object",    [_apt asDict],
                    @"returnType",
                    [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                    nil];
  [[self context] runCommand:@"person::get-extattrs",
                  @"objects", parts,
                  @"relationKey", @"companyValue", nil];
  return parts;
}
- (NSArray *)_membersForTeam:(id)_team {
  return [[self context] runCommand:@"team::members",
                         @"object", _team,
                         @"returnType",
                         [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                         nil];
}
- (id)_creatorOfApt:_apt {
  return [_apt owner];
}
- (void)_extractParticipants:(NSMutableArray *)_parts
  accounts:(NSMutableArray *)_accounts
  fromApt:(id)_apt
  owner:(id *)_owner;
{
  NSArray      *allParts;
  NSEnumerator *e;
  id           one;

  // the owner
  one = [self _ownerForApt:_apt];
  if (one) *_owner = one;

  allParts = [self _participantsForApt:_apt]; 
  e = [allParts objectEnumerator];

  while ((one = [e nextObject])) {
    if ([[one valueForKey:@"isTeam"] boolValue]) {
      NSArray *members = [self _membersForTeam:one];
      NSEnumerator *e2 = [members objectEnumerator];
      while ((one = [e2 nextObject])) {
        // adding team member to accounts
        if (![_accounts containsObject:one])
          [_accounts addObject:one];
        // adding team member to participants
        if (![_parts containsObject:one])
          [_parts addObject:one];
      }
      continue;
    }
    if ([[one valueForKey:@"isAccount"] boolValue]) {
      // adding participant to accounts
      if (![_accounts containsObject:one])
        [_accounts addObject:one];
    }

    // adding participant to participants
    if (![_parts containsObject:one])
      [_parts addObject:one];
  }
}
- (NSString *)_messageFormat {
  if (_msgFormat != nil)
    return _msgFormat;
  
  _msgFormat = [[[NSUserDefaults standardUserDefaults] 
		  stringForKey:@"AptNotifyMessageFormat"] copy];
  return _msgFormat;
}

- (NSString *)_messageFormat2 {
  return
    @"Subject: %@\n"
    @"From: %@\n"
    @"Reply-To:%@\n"
    @"To: %@\n"
    @"Content-Type: %@\n"
    @"\n";
}

- (NSTimeZone *)_timeZoneForAccount:(id)_acc {
  id         tz       = nil;
  NSString   *defpath;
  
  defpath = [[self userDefaults] stringForKey:@"LSAttachmentPath"];
  if (![[_acc valueForKey:@"isAccount"] boolValue])
    return [NSTimeZone timeZoneWithAbbreviation:self->defaultTimeZone];
  
  defpath = 
    [NSString stringWithFormat:@"%@/%@.defaults",
              defpath, [(EOKeyGlobalID *)[_acc globalID] keyValues][0]];
  tz = [NSDictionary dictionaryWithContentsOfFile:defpath];
  tz = [tz objectForKey:@"timezone"];
  if (tz == nil)
    tz = self->defaultTimeZone;
  return [NSTimeZone timeZoneWithAbbreviation:tz];
}

- (NSString *)_stringForParticipant:(id)_part {
  NSString *fn, *ln, *n = nil;
  fn = [_part valueForKey:@"firstname"];
  ln = [_part valueForKey:@"name"];
  if (![ln isNotNull])
    n = [_part valueForKey:@"login"];
  else if (![fn isNotNull])
    n = ln;
  else
    n = [NSString stringWithFormat:@"%@ %@", fn , ln];
  return n;
}

- (NSString *)_buildParticipantString:(NSArray *)_parts {
  NSMutableString *ready;
  NSEnumerator    *e;
  id              one;
  int             more      = 16;
  NSMutableString *lastLine;
  
  ready    = [NSMutableString stringWithCapacity:[_parts count] * 16];
  e        = [_parts objectEnumerator];
  lastLine = [NSMutableString stringWithCapacity:80];
  
  while ((one = [e nextObject])) {
    NSString *tmp;
    
    tmp = [self _stringForParticipant:one];
    if ([tmp length] > 40)
      tmp = [[tmp substringToIndex:38] stringByAppendingString:@".."];
    
    if (([ready length] > 0) || ([lastLine length] > 0))
      [lastLine appendString:@", "];
    
    if (([lastLine length] + [tmp length] + more) > 80) {
      // append lastLine to ready and break line
      [ready appendFormat:@"%@\n", lastLine];
      tmp = [@"                " stringByAppendingString:[tmp description]];
      more = 0;
      [lastLine setString:@""];
    }
    [lastLine appendString:tmp];
  }
  [ready appendString:lastLine];
  return ready;
}

/* delivery */
- (NSString *)_buildMessageForApt:(SkyAppointmentDocument *)_apt
  email:(NSString *)_email
  account:(id)_acc
  participants:(NSArray *)_parts
  subject:(NSString *)_subject
  owner:(id)_owner
  hideInformations:(BOOL)_hide
{
  id         tmp;
  NSString   *format;
  NSString   *startD = nil;
  NSString   *endD   = nil;
  NSTimeZone *tz;
  NSString   *comment = nil;
  NSString   *subject = nil;
  NSString   *location = nil;
  NSString   *resourceNames = nil;
  NSString   *from     = nil;

  format = [self _messageFormat];
  tz     = [self _timeZoneForAccount:_acc];

  tmp    = [_apt startDate];
  [tmp setTimeZone:tz];
  startD = [tmp descriptionWithCalendarFormat:CALENDARFORMAT];
  tmp    = [_apt endDate];
  [tmp setTimeZone:tz];
  endD    = [tmp descriptionWithCalendarFormat:CALENDARFORMAT];

  if (_subject == nil)
    _subject = @"SKYRiX Notification";
  
  if (_hide) {
    subject = [NSString stringWithFormat:@"%@: - %@",
                        _subject, startD];
  }
  else {
    subject = [NSString stringWithFormat:@"%@: '%@' %@",
                        _subject, [_apt title], startD];
  }
  
  comment = [_apt comment];
  if (comment == nil || _hide)
    comment = @"";
  
  location = [_apt location];
  if (location == nil || _hide)
    location = @"";

  resourceNames = [_apt resourceNames];
  if (resourceNames == nil)
    resourceNames = @"";

  from = [_owner valueForKey:@"email1"];
  if (![from length])
    from = [_owner valueForKey:@"email2"];
  if (![from length])
    from = self->fromAddress;

#if 0  
  return [NSString stringWithFormat:format,
                   subject, from, from,
                   _email, @"text/plain",
                   [_apt title],
                   startD, endD,
                   location,
                   resourceNames,
                   (_hide)?@"":[self _buildParticipantString:_parts],
                   comment];
#else
  {
    NGMimeMessage *mime;
    NGMutableHashMap *map;
    NGMimeMessageGenerator *gen;
    NSData           *data;

    map = [NGMutableHashMap hashMapWithCapacity:16];

    [map addObject:subject forKey:@"subject"];
    [map addObject:from forKey:@"from"];
    [map addObject:from forKey:@"reply-to"];
    [map addObject:_email forKey:@"to"];

    [map addObject:[NGMimeType mimeType:@"text" subType:@"plain"]
         forKey:@"content-type"];

    mime = [NGMimeMessage messageWithHeader:map];
    [mime setBody:[NSString stringWithFormat:format,
                            [_apt title],
                            startD, endD,
                            location,
                            _hide?(id)@"":(id)resourceNames,
                            _hide?(id)@"":(id)[self _buildParticipantString:
                                                    _parts],
                            comment]];

    gen  = [[NGMimeMessageGenerator alloc] init];
    data = [gen generateMimeFromPart:mime];
    return [[[NSString alloc] initWithData:data
                               encoding:[NSString defaultCStringEncoding]]
                       autorelease];
  }
#endif
}
- (NSString *)_buildMessageForApt:(SkyAppointmentDocument *)_apt
  email:(NSString *)_email
  account:(id)_acc
  participants:(NSArray *)_parts
  subject:(NSString *)_subject
  owner:(id)_owner
{
  return [self _buildMessageForApt:_apt
               email:_email
               account:_acc
               participants:_parts
               subject:_subject
               owner:_owner
               hideInformations:NO];

}
- (NSString *)_buildMessageForApt2:(SkyAppointmentDocument *)_apt
  email:(NSString *)_email
  account:(id)_acc
  participants:(NSArray *)_parts
  subject:(NSString *)_subject
  owner:(id)_owner
{
  id         tmp;
  NSString   *startD = nil;
  NSTimeZone *tz;
  NSString   *subject = nil;
  NSString   *location;
  NSString   *from     = nil;
  
  location = [_apt location];
  if (location == nil)
    location = @"";

  tz = [self _timeZoneForAccount:_acc];

  tmp    = [_apt startDate];
  [tmp setTimeZone:tz];
  startD = [tmp descriptionWithCalendarFormat:CALENDARFORMAT2];

  subject = [NSString stringWithFormat:@"%@: '%@ --> %@",
                       startD, [_apt title], location];

  from = [_owner valueForKey:@"email1"];
  if ([from length] == 0)
    from = [_owner valueForKey:@"email2"];
  if ([from length] == 0)
    from = self->fromAddress;
#if 0  
  return [NSString stringWithFormat:format,
                   subject, from, from,
                   _email, @"text/plain"];
#else
  {
    NGMimeMessage *mime;
    NGMutableHashMap *map;
    NGMimeMessageGenerator *gen;
    NSData           *data;

    map = [NGMutableHashMap hashMapWithCapacity:16];

    [map addObject:subject forKey:@"subject"];
    [map addObject:from forKey:@"from"];
    [map addObject:from forKey:@"reply-to"];
    [map addObject:_email forKey:@"to"];

    mime = [NGMimeMessage messageWithHeader:map];
    [mime setBody:@""];
    
    gen  = [[NGMimeMessageGenerator alloc] init];
    data = [gen generateMimeFromPart:mime];
    return [[[NSString alloc] initWithData:data
                               encoding:[NSString defaultCStringEncoding]]
                       autorelease];
  }
#endif  
}

- (void)_sendMessageTo:(NSString *)_to content:(NSString *)_message {
  NSString *sendmail = nil;
  FILE     *toMail   = NULL;

  sendmail = [NSString stringWithFormat:
                       @"%@ -f %@ %@", self->sendmailPath, self->fromAddress,
                       _to];
  if ((toMail = popen([sendmail cString], "w")) != NULL) {
    if (fprintf(toMail, "%s", (char *)[_message cString]) < 0) {
      NSLog(@"Couldn't write mail to sendmail!");
      NSLog(@"message: <%s>", [_message cString]);
    }
    if (pclose(toMail) != 0) {
      NSLog(@"Couldn't write mail to sendmail!");
      NSLog(@"message: <%s>", [_message cString]);
    }
  }
  else {
    NSLog(@"Couldn't open sendmail!");
  }

}

- (void)_sendEMailForApt:(SkyAppointmentDocument *)_apt
  toAccount:(id)_account
  participants:(NSArray *)_parts
  owner:(id)_owner
{
  NSString *email;
  NSString *email2;
  
  email  = [_account valueForKey:@"email1"];
  email2 = [_account valueForKey:@"email2"];
  
  if (self->beVerbose) {
    NSLog(@"email for account %@: %@",
          [_account valueForKey:@"login"], email);
    NSLog(@"email2 for account %@: %@",
          [_account valueForKey:@"login"], email2);
  }

  if (email == nil && email2 == nil) {
    if (self->beVerbose)
      NSLog(@"missing email for account: %@", [_account valueForKey:@"login"]);
    return;
  }
  
  if (email != nil) {
    [self _sendMessageTo:email
          content:[self _buildMessageForApt:_apt
                        email:email
                        account:_account
                        participants:_parts
                        subject:nil
                        owner:_owner]];
  }
  if (email2 != nil) {
    [self _sendMessageTo:email2
          content:[self _buildMessageForApt2:_apt
                        email:email2
                        account:_account
                        participants:_parts
                        subject:nil
                        owner:_owner]];
  }
}

- (NSArray *)_notificationDevicesForAccount:(id)_account {
  NSUserDefaults *uds;
  NSArray        *devs;

  if (![[_account valueForKey:@"isAccount"] boolValue]) {
    devs = [NSArray array];
    uds  = [NSUserDefaults standardUserDefaults];
    // external
    if ([uds boolForKey:@"AptNotifySendpageToExternal"])
      devs = [devs arrayByAddingObject:@"sms"];
    if ([uds boolForKey:@"AptNotifySendmailToExternal"])
      devs = [devs arrayByAddingObject:@"email"];
    return devs;
  }

  uds = [self->ctx runCommand:@"userdefaults::get",
             @"user", _account, nil];

  devs = [uds objectForKey:@"SkyAptNotifyDevices"];
  if (![devs count]) devs = [NSArray arrayWithObject:@"email"];
  
  return devs;
}

- (void)_processApt:(SkyAppointmentDocument *)_apt {
  NSUserDefaults *uds = [NSUserDefaults standardUserDefaults];
  NSMutableArray *accounts;
  NSMutableArray *parts;
  NSEnumerator   *e        = nil;
  id             one       = nil;
  id             owner     = nil;
  NSMutableArray *pagers;
  BOOL           sendOnePerPager;
  id             sms       = nil;
  
  accounts = [NSMutableArray arrayWithCapacity:8];
  parts    = [NSMutableArray arrayWithCapacity:8];
  pagers   = [NSMutableArray arrayWithCapacity:8];
  sendOnePerPager = YES;

  [self _extractParticipants:parts accounts:accounts fromApt:_apt
        owner:&owner];

  /* send an email to all accounts */
  if ([uds boolForKey:@"AptNotifySendmailToExternal"] ||
      [uds boolForKey:@"AptNotifySendpageToExternal"])
    e = [parts objectEnumerator];
  else
    e = [accounts objectEnumerator];
  
  while ((one = [e nextObject])) {
    NSArray *devices;
    
    devices = [self _notificationDevicesForAccount:one];
    
    // email
    if ([devices containsObject:@"email"]) {
      [self _sendEMailForApt:_apt toAccount:one
            participants:parts owner:owner];
    }

    if (self->sendpageEnabled) {
      // sms
      if ([devices containsObject:@"sms"]) {
        if (sendOnePerPager) {
          if (sms == nil) sms = [self _buildSMSWithApt:_apt
                                      participants:parts];
          [self _sendSMSForApt:_apt toAccounts:[NSArray arrayWithObject:one]
                participants:parts owner:owner sms:sms];
        }
        else {
          [pagers addObject:one];
        }
      }
    }

    if (self->beVerbose) {
      NSLog(@"%s reseting notificationTime of date '%@' to zero "
            @"(mark that notification has been sent)",
            __PRETTY_FUNCTION__, [_apt title]);
    }
    // mark as send
    [_apt setNotificationTime:(id)[NSNull null]];
    [_apt setSaveCycles:NO];
    [_apt save];
    // still need to add log
    if (self->beVerbose)
      NSLog(@"%s Notification sent to '%@' (%@) for '%@'",
            __PRETTY_FUNCTION__, [one valueForKey:@"login"],
            [devices componentsJoinedByString:@", "], [_apt title]);
  }

  if ((self->sendpageEnabled) && (!sendOnePerPager)) {
    // sms
    if ([pagers count]) {
      [self _sendSMSForApt:_apt toAccounts:pagers
            participants:parts owner:owner sms:nil];
    }
  }
}

- (id)_processResourceApt:(SkyAppointmentDocument *)_apt
  resourceName:(NSString *)_resourceName
  resource:(NSDictionary *)_resourceDict
  saveDict:(NSDictionary *)_sendResource
{
  NSMutableArray *accounts;
  NSMutableArray *parts;
  NSString       *email;
  NSString       *subject;
  id             owner;

  accounts = [NSMutableArray arrayWithCapacity:8];
  parts    = [NSMutableArray arrayWithCapacity:8];
  email    = [_resourceDict valueForKey:@"email"];
  subject  = [_resourceDict valueForKey:@"emailSubject"];

  owner = nil;
  [self _extractParticipants:parts accounts:accounts fromApt:_apt
        owner:&owner];
  
  if (![email isNotNull] || ([email length] == 0)) {
    if (self->beVerbose)
      NSLog(@" email not set for resource '%@'", _resourceName);
    return nil;
  }
  
  if (![subject isNotNull] || ([subject length] == 0))
    subject = @"Resource Notification";
  subject = [NSString stringWithFormat:@"%@ (%@)", subject, _resourceName];
  
  [self _sendMessageTo:email
        content:[self _buildMessageForApt:_apt
                      email:email
                      account:[self _creatorOfApt:_apt]
                      participants:parts
                      subject:subject
                      owner:owner
                      hideInformations:YES]];
  
  if (self->beVerbose) {
    NSLog(@"%s Resource Notification sent to %@ for '%@' with '%@'",
          __PRETTY_FUNCTION__, email, [_apt title], [_apt resourceNames]);
  }
  
  return _sendResource;
}

@end /* SkyAptNotify(PrivateMethods) */

@implementation SkyAptNotify(SMSMethods)

static NSString *SMSSTARTDATEFORMAT = @"%Y-%m-%d %H:%M";
static NSString *SMSENDDATEFORMAT1  = @"%H:%M";
static NSString *SMSENDDATEFORMAT2  = @"%Y-%m-%d %H:%M";
//static NSString *SMSENDDATEFORMAT3  = @" %Z";
static int      SMSMAXCHARS         = 160;

- (NSString *)_smsParticipantsString:(NSArray *)_parts account:(id)_account {
  NSMutableArray *names;
  NSEnumerator   *e;
  id             one;
  
  names = [NSMutableArray arrayWithCapacity:[_parts count]];
  e     = [_parts objectEnumerator];
  while ((one = [e nextObject])) {
    NSString *n;
    
    if ([[one valueForKey:@"isAccount"] boolValue]) {
      [names addObject:[one valueForKey:@"login"]];
      continue;
    }
    
    n = [one valueForKey:@"name"];
    if ([n length] == 0) {
      n = [one valueForKey:@"firstname"];
      if ([n length] == 0) n = [one valueForKey:@"login"];
    }
    [names addObject:n];
  }
  return [names componentsJoinedByString:@","];
}

- (NSString *)_buildSMSWithApt:(SkyAppointmentDocument *)_apt
  participants:(NSArray *)_parts
  forAccount:(id)_account
{
  NSMutableString *text;
  NSString        *tmp;
  
  text = [NSMutableString stringWithCapacity:160];
  [text appendString:self->sendpageTitle]; //   13 chars (max)
  tmp = [_apt title];
  if ([tmp length] > 30) {
    tmp = [[tmp substringToIndex:28] stringByAppendingString:@".."];
  }
  [text appendString:tmp];              // + 30 =  43 chars (max)
  [text appendString:@"\n"];            // +  1 =  44 chars (max)

  // startdate
  tmp = [[_apt startDate] descriptionWithCalendarFormat:SMSSTARTDATEFORMAT];
  if ([tmp length] > 17) {
    tmp = [[tmp substringToIndex:15] stringByAppendingString:@".."];
  }
  [text appendString:tmp];              // + 16 =  60 chars (max)
  [text appendString:@"-"];             // +  1 =  61 chars (max)

  // enddate
  if ([[_apt startDate] isDateOnSameDay:[_apt endDate]])
    tmp = [[_apt endDate] descriptionWithCalendarFormat:SMSENDDATEFORMAT1];
  else
    tmp = [[_apt endDate] descriptionWithCalendarFormat:SMSENDDATEFORMAT2];
  if ([tmp length] > 17) {
    tmp = [[tmp substringToIndex:15] stringByAppendingString:@".."];
  }
  [text appendString:tmp];              // + 16 =  77 chars (max)

  // timezone
  //tmp = [[_apt startDate] descriptionWithCalendarFormat:SMSENDDATEFORMAT3];
  //if ([tmp length] > 8) {
  //  tmp = [[tmp substringToIndex:6] stringByAppendingString:@".."];
  //}
  //[text appendString:tmp];              // +  8 =  87 chars (max)
  [text appendString:@"\n"];            // +  1 =  88 chars (max)

  // location
  if ([(tmp = [_apt location]) length]) {
    if ([tmp length] > 30) {
      tmp = [[tmp substringToIndex:28] stringByAppendingString:@".."];
    }
    [text appendString:tmp];            // + 30 = 118 chars (max)
    [text appendString:@"\n"];          // +  1 = 119 chars (max)
  }

  // participants and comment
  {
    NSString *parts    = [self _smsParticipantsString:_parts account:_account];
    NSString *comment  = [_apt comment];
    int      spaceleft = SMSMAXCHARS - [text length];

    if (spaceleft < 10) {
      if (spaceleft < 0) {
        return [[text substringToIndex:SMSMAXCHARS - 2] 
                      stringByAppendingString:@".."];
      }
      return text;
    }
    
    [text appendString:self->sendpageWith];
    spaceleft -= 5;
      
    if ([parts length] > spaceleft) {
      parts = [[parts substringToIndex:spaceleft - 2]
                      stringByAppendingString:@".."];
      [text appendString:parts];
      return text;
    }

    [text appendString:parts];
    spaceleft -= [parts length];
    if (spaceleft < 5) return text;

    if ([comment length]) {
      [text appendString:@"\n"];
      [text appendString:comment];
    }
  }
  
  if ([text length] > SMSMAXCHARS) {
    return [[text substringToIndex:SMSMAXCHARS - 2] 
                  stringByAppendingString:@".."];
  }
  return text;
}
- (NSString *)_buildSMSWithApt:(SkyAppointmentDocument *)_apt
  participants:(NSArray *)_parts
{
  return [self _buildSMSWithApt:_apt participants:_parts forAccount:nil];
}

- (void)_sendSMS:(NSString *)_text
  from:(NSString *)_from
  to:(NSArray *)_to // array of accounts
{
  NSString *sendpage;
  FILE     *toPage   = NULL;
  NSString *to;

  to    = [_to componentsJoinedByString:@" -p "];
  _text = [[_text componentsSeparatedByString:@"\""]
                  componentsJoinedByString:@"\\\""];
  
  // its piped to support newlines ...
  sendpage = [NSString stringWithFormat:
                       @"echo \"%@\" | %@ -q -f \"%@\" -s \"%@\" -h %@ -p %@",
                       _text, 
                       self->sendpagePath, _from, _from, self->pagerhost,
                       to];
  
  if ((toPage = popen([sendpage cString], "w")) != NULL) {
    if (pclose(toPage) != 0)
      NSLog(@"ERROR: Could not send message to pager: %@", sendpage);
  }
  else {
    NSLog(@"Couldn't open sendpage!");
  }
}

- (NSString *)stripString:(NSString *)_sep outOfString:(NSString *)_s {
  if ([_s rangeOfString:_sep].length == 0)
    return _s;
  
  return [[_s componentsSeparatedByString:_sep] componentsJoinedByString:@""];
}

- (NSString *)_checkPagerId:(NSString *)_pager {
  if ([_pager length] == 0) return nil;
  if ([_pager hasPrefix:@"+"]) {
#if 1
    // TODO: improve
    // cutting country prefix for now
    int idx;
    
    if ((idx = [_pager indexOfString:@"-"]) == NSNotFound) {
      if ((idx = [_pager indexOfString:@"/"]) == NSNotFound) {
        if ((idx = [_pager indexOfString:@" "]) == NSNotFound) {
          NSLog(@"WARNING[%s]: cannot parse pager id %@",
                __PRETTY_FUNCTION__, _pager);
          return nil;
        }
      }
    }
    _pager = [NSString stringWithFormat:@"0%@",
                       [_pager substringFromIndex:idx+1]];
#else
    // this doesn't seem to work with sendpage
    int idx = 1;
    if ([_pager hasPrefix:@"++"]) idx = 2;
    _pager = [NSString stringWithFormat:@"00%@",
                       [_pager substringFromIndex:idx]];
#endif
  }
  _pager = [self stripString:@"-" outOfString:_pager];
  _pager = [self stripString:@"/" outOfString:_pager];
  _pager = [self stripString:@" " outOfString:_pager];
  return _pager;
}

- (NSArray *)_mobilePhoneIDsForAccount:(id)_account {
  NSMutableArray *numbers;
  NSArray        *telephones;
  NSEnumerator   *e;
  id             one;

  numbers    = [NSMutableArray arrayWithCapacity:5];
  telephones = [_account valueForKey:@"telephones"];
  e          = [telephones objectEnumerator];
  
  while ((one = [e nextObject])) {
    if (![[one valueForKey:@"type"] isEqualToString:@"03_tel_funk"])
      continue;
    
    if ([(one = [self _checkPagerId:[one valueForKey:@"number"]]) length]) 
      [numbers addObject:one];
  }
  return numbers;
}

- (void)_sendSMSForApt:(SkyAppointmentDocument *)_apt
  toAccounts:(NSArray *)_accounts
  participants:(NSArray *)_parts
  owner:(id)_owner
  sms:(id)_sms
{
  NSMutableArray *pagers;
  NSEnumerator   *e;
  id             one;

  pagers = [NSMutableArray arrayWithCapacity:4];
  e      = [_accounts objectEnumerator];
  while ((one = [e nextObject])) {
    [pagers addObjectsFromArray:[self _mobilePhoneIDsForAccount:one]];
  }

  if ([pagers count] == 0)
    return;

  if (self->beVerbose) {
    NSLog(@"%s sending pager messages to %@",
	  __PRETTY_FUNCTION__, [pagers componentsJoinedByString:@", "]);
  }
    
  if (_sms == nil) 
    _sms = [self _buildSMSWithApt:_apt participants:_parts];
  
  [self _sendSMS:_sms from:self->sendpageFrom to:pagers];
}

@end /* SkyAptNotify(SMSMethods) */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  SkyAptNotify *notifier;
  int          result = 0;
  
  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc 
		 environment:env];
#endif
  
  notifier = [[SkyAptNotify alloc] init];
  result = [notifier runInExceptionHandler];
  
#if 0 /* don't, we are exiting anyway and this can only result in probs */
  [notifier release];
  [pool release];
#endif
  exit(result);
  return result;
}
