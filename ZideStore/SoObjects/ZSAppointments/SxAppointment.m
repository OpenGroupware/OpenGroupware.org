/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "SxAppointment.h"
#include "SxAppointmentMessageParser.h"
#include "SxAppointmentFolder.h"
#include "SxDavAptCreate.h"
#include "SxDavAptChange.h"
#include <ZSFrontend/SxRenderer.h>
#include <ZSFrontend/SxRendererFactory.h>
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <ZSBackend/Appointments/SxAppointmentRenderer.h>
#include <ZSBackend/SxContactManager.h>
#include <ZSBackend/SxAptManager.h>

// TODO: set SxNewObjectID in context for ZideLook

@interface NSObject(UsedPrivates) // TODO: fix that
- (id)rendererWithFolder:(id)_folder inContext:(id)_ctx;
@end

@implementation SxAppointment

static NSNumber *yesNum = nil;
static BOOL createGroupAptsInGroupFolder = NO;
static BOOL logAptChange             = NO;
static BOOL createNewAptWhenNotFound = YES;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  
  createGroupAptsInGroupFolder =
    [ud boolForKey:@"ZLCreateGroupAppointmentsInGroupFolders"];
  logAptChange = [ud boolForKey:@"ZLAptLogChanges"];
  
  if ([ud boolForKey:@"ZLApt404OnMissingPUTTargets"])
    createNewAptWhenNotFound = NO;
}

+ (BOOL)logAptChange {
  return logAptChange; 
}

- (void)dealloc {
  [self->group release];
  [super dealloc];
}

/* backend manager */

- (SxAptManager *)aptManagerInContext:(id)_ctx {
  SxAptManager *am;
  if (_ctx == nil) _ctx = [[WOApplication application] context];
  if ((am = [[self container] aptManagerInContext:_ctx]) == nil) 
    [self logWithFormat:@"WARNING: got no appointment manager !"];
  return am;
}

/* accessors */

- (void)setGroup:(NSString *)_group {
  ASSIGNCOPY(self->group, _group);
}
- (NSString *)group {
  return self->group;
}

/* comment */

- (NSString *)fetchCommentInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  id dateEO;

  /* fetch EO */
  
  if ((dateEO = [self objectInContext:_ctx]) == nil)
    return nil;

  /* fetch comment */
  
  cmdctx = [self commandContextInContext:_ctx];
  [cmdctx runCommand:@"appointment::get-comments", @"object", dateEO, nil];
  return [dateEO valueForKey:@"comment"];
}
- (NSString *)comment {
  return [self fetchCommentInContext:[[WOApplication application] context]];
}

/* Exchange permissions */

- (BOOL)isDeletionAllowed {
  // TODO: use object info to determine this
  NSString *permissions;
  permissions = [[self objectInContext:nil] valueForKey:@"permissions"];
  return (permissions != nil)
    ? (([permissions rangeOfString:@"d"].length > 0) ? YES : NO)
    : YES;
}

- (int)zlGenerationCount {
  return [[[self objectInContext:nil] valueForKey:@"objectVersion"] intValue];
}
- (NSString *)outlookMessageClass {
  return @"IPM.Appointment"; /* email, default class */
}

/* actions */

- (EOKeyGlobalID *)globalIDOfGroupInContext:(id)_ctx {
  NSString *g;
  if ((g = [self group]) == nil) return nil;
  return [[self aptManagerInContext:_ctx] 
                globalIDForGroupWithName:[self group]];
}
- (NSNumber *)pkeyOfGroupInContext:(id)_ctx {
  EOKeyGlobalID *gid;
  
  if ((gid = [self globalIDOfGroupInContext:_ctx]) == nil)
    return nil;
  return [gid keyValues][0];
}
- (id)groupInContext:(id)_ctx {
  id team;

  if ((team = [self pkeyOfGroupInContext:_ctx]) == nil)
    return nil;
  
  team = [[[self commandContextInContext:_ctx]
	         runCommand:@"team::get", @"companyId", team, nil] lastObject];
  return team;
}
- (BOOL)isInOverviewFolder {
  return [[self container] isOverview];
}

- (Class)selfRendererClass {
  /* class to render self propfinds on self */
  static Class RendererClass = Nil;
  static BOOL  didInit = NO;
  
  if (!didInit) {
    didInit = YES;
    
    if ((RendererClass = NSClassFromString(@"SxZLFullAptRenderer")) == Nil) {
      // TODO: fall back to a default renderer?!
      [self logWithFormat:
              @"Note: did not find 'SxZLFullAptRenderer' class, cannot "
              @"render <allprop/>."];
    }
  }
  return RendererClass;
}

- (NSArray *)davQueryOnSelf:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* Note: this is also called for bulk fetches */
  NSDictionary *res;
  id           renderer;
  
  // TODO: check whether are attributes are really requested !!
  
  if ([[self container] doExplainQueries]) {
    [self logWithFormat:@"deliver appointment properties: %@",
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  res = [[self aptManagerInContext:_ctx] 
               zlAppointmentWithID:[self nameInContainer]];
  if (res == nil) {
    [self logWithFormat:@"appointment does not exist: %@", 
            [self nameInContainer]];
    return [NSException exceptionWithHTTPStatus:404 /* not found */
                        reason:@"tried to lookup invalid appointment key"];
  }
  
  /* try to render using renderer */
  
  if ((renderer = [self selfRendererClass]) != Nil) {
    renderer = [renderer rendererWithFolder:[self container] inContext:_ctx ];
    if ((res = [renderer renderEntry:res]) != nil)
      return [NSArray arrayWithObject:res];
  }
  
  /* fallback, return SoObject to SOPE WebDAV layer */
  return [NSArray arrayWithObject:self];
}

- (BOOL)shouldReturn201AfterPUTInContext:(WOContext *)_ctx {
  WEClientCapabilities *cc;
  NSString *ua;
  
  cc = [[(WOContext *)_ctx request] clientCapabilities];
  ua = [cc userAgentType];
  if ([ua isEqualToString:@"Evolution"])
    /* Evo needs 201, otherwise an error will be shown */
    return YES;
  if ([ua isEqualToString:@"ZideLook"])
    return YES;
  
  /* if I remember right, Cadaver complains on 201 */
  return NO;
}

#define SX_NEWKEY(__key__) \
  if ((tmp = [_info valueForKey:__key__])) {\
    [changeSet setObject:tmp forKey:__key__];\
    [keys removeObject:__key__];\
  }

- (id)createAptWithInfo:(NSDictionary *)_info inContext:(id)_ctx {
  // TODO: should we make a redirect to the created file? probably confuses
  //       clients but is likely to be the correct thing to do.
  // TODO: added 
  NSMutableArray      *keys;
  NSMutableDictionary *changeSet;
  NSException    *error;
  NSString       *log, *etag;
  NSMutableArray *participants;
  WOResponse     *r;
  id tmp;
  
  if (logAptChange) [self logWithFormat:@"GOT: %@", _info];
  
  keys = [[[_info allKeys] mutableCopy] autorelease];
  
  /* remove superflous keys */
  [keys removeObject:@"creationDate"]; // unused
  [keys removeObject:@"uid"];          // unused
  [keys removeObject:@"sequence"];     // extracted above
  
  /* TODO: add new columns */
  [keys removeObject:@"lastModified"]; // use for conflict detection ?
  [keys removeObject:@"accessClass"];
  [keys removeObject:@"importance"];
  [keys removeObject:@"priority"];
  
  /* participants */
  participants = [NSMutableArray array];
  if ([self isInOverviewFolder]) {
    id team = [self groupInContext:_ctx];
    if (team)
      [participants addObject:team];
    else
      [participants addObject:
                    [[self commandContextInContext:_ctx]
                           valueForKey:LSAccountKey]];
  }

  tmp = [self fetchParticipantsForPersons:
                [_info objectForKey:@"participants"]
              inContext:_ctx];
  if ([tmp count]) { // if at least one participant
    [participants addObjectsFromArray:tmp];
    [keys removeObject:@"participants"];
  }
  else if (![participants count]) { // if no participants, add current account
    id team;
    
    if ((createGroupAptsInGroupFolder) &&
        ((team = [self groupInContext:_ctx]))) {
      participants = [NSArray arrayWithObject:team];
    }
    else {
      id account;
      
      account = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
      participants = [NSArray arrayWithObject:account];
    }
  }
  
  /* check values */
  
  changeSet = [NSMutableDictionary dictionaryWithCapacity:16];
  
  [changeSet setObject:participants forKey:@"participants"];
  SX_NEWKEY(@"startDate");
  SX_NEWKEY(@"endDate");
  SX_NEWKEY(@"title");
  SX_NEWKEY(@"location");
  SX_NEWKEY(@"comment");
  
  /* read-access-group */
  
  if ((tmp = [self pkeyOfGroupInContext:_ctx]))
    [changeSet setObject:tmp forKey:@"accessTeamId"];
  
  /* conflicts */
  
  [changeSet setObject:yesNum forKey:@"isWarningIgnored"];
  
  /* add log */
  
  if ([keys count] > 0) {
    [self logWithFormat:@"loosing keys: %@", 
	    [keys componentsJoinedByString:@","]];
  }
  
  log = [NSString stringWithFormat:@"created by ZideStore %@ (lost=%@)",
		    [[changeSet allKeys] componentsJoinedByString:@","],
		    [keys componentsJoinedByString:@","]];
  
  /* perform changes */
  
  error = [[self aptManagerInContext:_ctx] 
                 createWithEOAttributes:changeSet log:log];
  if ([error isKindOfClass:[NSException class]])
    return error;
  
  ASSIGN(self->eo, error);
  
  /* setup response */
  
  r = [_ctx response];

  [r setStatus:
       [self shouldReturn201AfterPUTInContext:_ctx]
       ? 201 /* Created */ : 200 /* OK */];

  // TODO: set location header for new appointment
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  return r;
}
#undef SX_NEWKEY

- (void)reloadObjectInContext:(id)_ctx {
  [self->eo release]; self->eo = nil;
  [self objectInContext:_ctx];
}

#define SX_DIFFKEY(__key__) \
  if ((tmp = [_info valueForKey:__key__])) {\
    if (![tmp isEqual:[eo valueForKey:__key__]])\
      [changeSet setObject:tmp forKey:__key__];\
    [keys removeObject:__key__];\
  }

- (id)patchAptWithInfo:(NSDictionary *)_info inContext:(id)_ctx {
  WOResponse          *r;
  NSMutableArray      *keys;
  NSMutableDictionary *changeSet;
  NSException         *error;
  NSString            *log, *etag;
  NSMutableArray      *participants;
  id  obj, tmp;
  int oldVersion, newVersion;
  
  /* fetch EO */
  
  if ((obj = [self objectInContext:_ctx]) == nil) {
    if (createNewAptWhenNotFound) {
      [self logWithFormat:
              @"Note: object not yet available in DB, creating a new one!"];
      return [self createAptWithInfo:_info inContext:_ctx];
    }
    else {
      [self logWithFormat:@"got no EO object !"];
      return [NSException exceptionWithHTTPStatus:404 /* Not Found */
                          reason:@"could not locate database object for ID!"];
    }
  }
  
  /* check version */
  
  oldVersion = [[obj   valueForKey:@"objectVersion"] intValue];
  newVersion = [[_info valueForKey:@"sequence"] intValue];
  [self debugWithFormat:@"patch old=>new %i=>%i", oldVersion, newVersion];
  
  /* maybe we can use the sequence for conflict detection (objversion+1 ?) */
  
  if (logAptChange) [self logWithFormat:@"GOT: %@", _info];
  
  keys = [[[_info allKeys] mutableCopy] autorelease];
  
  /* remove superflous keys */
  [keys removeObject:@"creationDate"]; // unused
  [keys removeObject:@"uid"];          // unused
  [keys removeObject:@"sequence"];     // extracted above
  
  /* TODO: add new columns */
  [keys removeObject:@"lastModified"]; // use for conflict detection ?
  [keys removeObject:@"accessClass"];
  [keys removeObject:@"importance"];
  [keys removeObject:@"priority"];
  
  /* check values */

  changeSet = [NSMutableDictionary dictionaryWithCapacity:16];

  /* conflicts */

  [changeSet setObject:[NSNumber numberWithBool:YES]
	     forKey:@"isWarningIgnored"];
  
  SX_DIFFKEY(@"startDate");
  SX_DIFFKEY(@"endDate");
  SX_DIFFKEY(@"title");
  SX_DIFFKEY(@"location");
  SX_DIFFKEY(@"comment");

  SX_DIFFKEY(@"evoReminder");
  
  participants = [NSMutableArray array];
  if ([self isInOverviewFolder]) {
    id team = [self groupInContext:_ctx];
    if (logAptChange)
      NSLog(@"%s in overview calendar: %@",
            __PRETTY_FUNCTION__, team);
    if (team)
      [participants addObject:team];
    else
      [participants addObject:
                    [[self commandContextInContext:_ctx]
                           valueForKey:LSAccountKey]];
  }
  
  tmp = [self fetchParticipantsForPersons:
              [_info objectForKey:@"participants"]
              inContext:_ctx];
  
  if ([tmp count])
    [participants addObjectsFromArray:tmp];
  
  /* TODO: mh: hack */
  /*
    force reload because of a rollback that occured during loading of
    participants
  */
  [self reloadObjectInContext:_ctx];
  
  if ([participants count] == 0) {
    // if no participants, take current account
    id account;
    
    account = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
    participants = [NSArray arrayWithObject:account];
  }
  
  [keys removeObject:@"participants"];
  participants = (NSMutableArray *)[self checkChangedParticipants:participants
                                         forOldParticipants:
                                         [self->eo
                                              valueForKey:@"participants"]
                                         inContext:_ctx];
  if (participants)
    // participants changed
    [changeSet setObject:participants forKey:@"participants"];
  
  /* add log */
  
  if ([keys count] > 0)
    [self logWithFormat:@"loosing keys: %@",
          [keys componentsJoinedByString:@","]];
  
  log = [NSString stringWithFormat:
                  @"changed by ZideStore (changed=%@,lost=%@)",
                  [[changeSet allKeys] componentsJoinedByString:@","],
                  [keys componentsJoinedByString:@","]];
  
  /* perform changes */
  
  error = [[self aptManagerInContext:_ctx]
                 updateRecordWithPrimaryKey:[self primaryKey]
                 withEOChanges:changeSet
                 log:log];

  if ([error isKindOfClass:[NSException class]])
    return error;

  /* setup response */
  
  r = [_ctx response];

  [r setStatus:
       [self shouldReturn201AfterPUTInContext:_ctx]
       ? 201 /* Created */ : 200 /* OK */];
  
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  return r;
}
#undef SX_DIFFKEY

- (id)_processPUTData:(NSData *)_content
  withParseSelector:(SEL)_parseSel inContext:(id)_ctx
{
  /* request body contains a message/rfc822 */
  SxAppointmentMessageParser *parser;
  NSArray *infos;
  id      info;
  
  if ([_content length] == 0) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"got empty PUT body"];
  }
  
  if ((parser = [SxAppointmentMessageParser parser]) == nil) {
    return [NSException exceptionWithHTTPStatus:500 
                        reason:@"missing MIME/iCal parser !"];
  }
  
  if ((infos = [parser performSelector:_parseSel withObject:_content]) ==nil) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"could not parse submitted data!"];
  }
  if ([infos count] == 0) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"no vevent record found in submitted data!"];
  }
  if ([infos count] > 1) {
    [self logWithFormat:
	    @"WARNING: got more than one ical component, using the first: %@",
	    infos];
  }
  info = [infos objectAtIndex:0];
  
  // read_access_group = $group
  
  return [self isNew]
    ? [self createAptWithInfo:info inContext:_ctx]
    : [self patchAptWithInfo:info  inContext:_ctx];
}

- (id)putMessageAction:(id)_ctx {
  return [self _processPUTData:[[(WOContext *)_ctx request] content]
               withParseSelector:@selector(parseMessageData:)
               inContext:_ctx];
}
- (id)putICalendarAction:(id)_ctx {
  return [self _processPUTData:[[(WOContext *)_ctx request] content]
               withParseSelector:@selector(parseICalendarData:)
               inContext:_ctx];
}

- (id)PUTAction:(id)_ctx {
  NSException *error;
  NSString *ctype;

  if ((error = [self matchesRequestConditionInContext:_ctx]) != nil)
    return error;
  
  if ([self isNew]) {
    WEClientCapabilities *cc;
    
    cc = [[(WOContext *)_ctx request] clientCapabilities];
    if ([[cc userAgentType] isEqualToString:@"ZideLook"]) {
      [self logWithFormat:@"fake new ZideLook apt ..."];
      [[(WOContext *)_ctx response] setStatus:201 /* created */];
      return [(WOContext *)_ctx response];
    }
  }
  
  ctype = [[(WOContext *)_ctx request] headerForKey:@"content-type"];

  if ([ctype hasPrefix:@"message/rfc822"])
    return [self putMessageAction:_ctx];
  
  if ([ctype hasPrefix:@"text/calendar"])
    return [self putICalendarAction:_ctx];
  
  if ([ctype length] == 0) {
    // TODO: what clients do that?
    static NSData *iCalSignature = nil;
    NSData *data;

    if (iCalSignature == nil) {
      iCalSignature = [[NSData alloc] initWithBytes:@"BEGIN:VCALENDAR" 
                                      length:15];
    }
    
    [self logWithFormat:@"Note: client submitted no content-type!"];
    data = [[(WOContext *)_ctx request] content];
    if ([data hasPrefix:iCalSignature]) {
      [self logWithFormat:
              @"request seems to contain iCalendar data, try that."];
    }
    return [self putICalendarAction:_ctx];
  }
  
  [self logWithFormat:@"Note: does not accept PUTs of type: '%@'", ctype];
  return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                      reason:@"invalid format for PUT (not a message/rfc822)"];
}

- (void)fetchOwnerForAppointment:(id)_apt inContext:(id)_ctx {
  id ownerId = [_apt valueForKey:@"ownerId"];
  id ids[1];
  id gid;
  if (ownerId != nil) {
    SxContactManager *cm =
      [SxContactManager managerWithContext:
                        [self commandContextInContext:_ctx]];
    ids[0] = ownerId;
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                         keys:ids keyCount:1 zone:NULL];

    gid = [cm accountForGlobalID:gid];
    if (gid != nil)
      [_apt takeValue:gid forKey:@"owner"];
  }
}

- (id)context {
  // hack
  return [[WOApplication application] context];
}

- (NSString *)iCalVEventString {
  // deprecated
  //SxAppointmentRenderer *renderer = [SxAppointmentRenderer renderer];
  id obj;
  id am;

  am = [self aptManagerInContext:[self context]];
  
  if ((obj = [self objectInContext:[self context]]) == nil)
    return nil;
  
  //return [renderer renderAppointmentAsICal:obj timezone:nil];
  return [am renderAppointmentAsICal:obj timezone:nil];
}
- (NSString *)iCalString {
  NSMutableString *m;
  NSString *ical;
    
  // TODO: tz
  if ((ical = [self iCalVEventString]) == nil)
    return nil;
  
  m = [NSMutableString stringWithCapacity:[ical length] + 256];
  [m appendString:@"BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nPRODID:"];
  [m appendString:OGo_ZS_PRODID];
  [m appendString:@"\r\nVERSION:2.0\r\n"];
  [m appendString:ical];
  [m appendString:@"END:VCALENDAR"];
  return m;
}

- (NSString *)iCalMailString {
  // deprecated
  // SxAppointmentRenderer *renderer = [SxAppointmentRenderer renderer];
  id obj;
  id am;

  am = [self aptManagerInContext:[self context]];
  
  if ((obj = [self objectInContext:[self context]]) == nil)
    return nil;
  
  //return [renderer renderAppointmentAsMIME:obj timezone:nil];
  return [am renderAppointmentAsMIME:obj timezone:nil];
}

- (id)GETAction:(id)_ctx {
  WOResponse *r;
  WORequest  *rq;
  id obj;
  NSTimeZone *tz;
  id        cmdctx; 
  NSString *tzName, *etag;

  cmdctx = [self commandContextInContext:_ctx];
  tzName = [[cmdctx userDefaults] stringForKey:@"timezone"];
  tz     = ([tzName length])
    ? [NSTimeZone timeZoneWithAbbreviation:tzName] : nil;
  
  if ((obj = [self objectInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
                        reason:@"did not find EO"];
  }
  
  // TODO: add a cusotm viewer (component) for browsers
  
  // need owner information
  [self fetchOwnerForAppointment:obj inContext:_ctx];
  
  rq = [(WOContext *)_ctx request];
  r  = [(WOContext *)_ctx response];
  if ([[rq uri] hasSuffix:@".ics"] || 
      [[rq headerForKey:@"accept"] hasPrefix:@"text/calendar"]) {
    NSString *ical;
    
    // TODO: tz
    if ((ical = [self iCalString]) == nil) {
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"could not render EO as iCalendar"];
    }
    
    [r setHeader:@"text/calendar" forKey:@"content-type"];
    [r appendContentString:ical];
  }
  else {
    NSString *mime;
    
    // TODO: tz
    if ((mime = [self iCalMailString]) == nil) {
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"could not render EO as MIME"];
    }
    
    [r setHeader:@"message/rfc822" forKey:@"content-type"];
    [r appendContentString:mime];
  }
  
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  return r;
}

- (id)davCreateObject:(NSString *)_name properties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  SxDavAptCreate *creator;

  creator = [[[SxDavAptCreate alloc] 
                              initWithName:_name properties:_props
                              forAppointment:self] autorelease];
  return [creator runInContext:_ctx];
}
- (NSException *)davSetProperties:(NSDictionary *)_setProps
  removePropertiesNamed:(NSArray *)_delProps
  inContext:(id)_ctx
{
  SxDavAptChange *updater;
  
  if ([self isNew]) {
    return [self davCreateObject:[self nameInContainer] properties:_setProps
		 inContext:_ctx];
  }
  
  updater = [[[SxDavAptChange alloc] 
                              initWithName:[self nameInContainer]
                              properties:_setProps
                              forAppointment:self] autorelease];
  return [updater runInContext:_ctx];
}

/* hooks of SxObject */

+ (NSString *)primaryKeyName {
  return @"dateId";
}
+ (NSString *)entityName {
  return @"Date";
}

+ (NSString *)getCommandName {
  return @"appointment::get";
}
+ (NSString *)deleteCommandName {
  return @"appointment::delete";
}
+ (NSString *)newCommandName {
  return @"appointment::new";
}
+ (NSString *)setCommandName {
  return @"appointment::set";
}

- (id)objectInContext:(id)_ctx {
  if (self->eo) 
    return self->eo;
  self ->eo = [[[self aptManagerInContext:_ctx] 
                      eoForPrimaryKey:[self primaryKey]] retain];
  return self->eo;
}

- (id)primaryDeleteObjectInContext:(id)_ctx {
  NSException *error;

  error = [[self aptManagerInContext:_ctx] 
                 deleteRecordWithPrimaryKey:[self primaryKey]];
  return error;
}

/* DAV default attributes (allprop queries by ZideLook ;-) */

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  static NSMutableArray *defNames = nil;
  if (defNames == nil) {
    defNames = [[[self propertySetNamed:@"DefaultAppointmentProperties"] 
		       allObjects] copy];
  }
  return defNames;
}

/* RSS */

- (NSString *)rssTitleInContext:(WOContext *)_ctx {
  // TODO: we might want to add stuff like startDate/endDate
  id dateEO;
  
  if ((dateEO = [self objectInContext:nil]) == nil)
    return nil;
  return [dateEO valueForKey:@"title"];
}

- (NSString *)rssDescriptionInContext:(WOContext *)_ctx {
  // TODO: I guess we want to embed more information
  return [self fetchCommentInContext:_ctx];
}

@end /* SxAppointment */
