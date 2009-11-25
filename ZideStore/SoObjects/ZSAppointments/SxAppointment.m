/*
  Copyright (C) 2002-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess
  
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
static BOOL embedViewURL             = NO;

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
    [self errorWithFormat:@"got no appointment manager !"];
  return am;
}

/* accessors */

- (void)setGroup:(NSString *)_group {
  // TBD: why is that? shouldn't we just ask the container for the group?
  //      => possibly we invoke this object in other contexts
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
  // TODO: DUP in SxAddress (move to SxObject?)
  WEClientCapabilities *cc;
  NSString *ua;
  
  cc = [[(WOContext *)_ctx request] clientCapabilities];
  ua = [cc userAgentType];

  if ([ua isEqualToString:@"Evolution"])
    /* Evo needs 201, otherwise an error will be shown */
    return YES;
  if ([ua isEqualToString:@"ZideLook"])
    return YES;
  if ([ua isEqualToString:@"Sunbird"])
    return YES;

  /*
    According to the RFC 2616, 9.6 PUT:
    "If a new resource is created, the origin server MUST inform the user
     agent via the 201 (Created) response."
     
    We'll keep this since we don't know what else expects a 200. Possibly the
    wrong approach.
  */
  if ([ua isEqualToString:@"Cadaver"]) {
    /* if I remember right, Cadaver complains on 201 */
    return NO;
  }
  
  return NO;
}

#define SX_NEWKEY(__key__) \
  if ((tmp = [_info valueForKey:__key__])) {\
    [changeSet setObject:tmp forKey:__key__];\
    [keys removeObject:__key__];\
  }

- (NSArray *)defaultParticipantsInContext:(id)_ctx {
  /* for new appointments which have no participant set */
  id account, team;
   
  /* if we are in a team folder return the team as the default participant
     TODO: support flattening of teams via ZideStore/WebDAV */ 
  if ((createGroupAptsInGroupFolder) && ((team = [self groupInContext:_ctx])))
    return team ? [NSArray arrayWithObject:team] : nil;
  
  account = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
  /* Create a date-company-assignment record with role and participant
     status for the current user */
  return account ? [NSArray arrayWithObject:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                         [account valueForKey:@"companyId"], @"companyId",
                         intObj(1), @"isAccount",
                         @"NEEDS-ACTION", @"partStatus",
                         @"REQ-PARTICIPANT", @"role",
                         intObj(0), @"rsvp",
                         nil]] : nil;
} /* end defaultParticipantsInContext */

/* How is this different from defaultParticipantsInContext: ? */
- (NSMutableArray *)participantsForCreateInContext:(id)_ctx {
  NSMutableArray *participants;
  id team;

  participants = [NSMutableArray arrayWithCapacity:16];
  if (![self isInOverviewFolder])
    return participants;
    
  if ((team = [self groupInContext:_ctx]) != nil) {
    [participants addObject:team];
  } else {
      id account;
    
      account = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
      [participants addObject:account];
    }
  return participants;
} /* end participantsForCreateInContext: */

- (NSString *)logTextForChangeSet:(NSDictionary *)_cs keys:(NSArray *)_k {
  NSMutableString *log;
  id tmp;
  
  log = [NSMutableString stringWithCapacity:128];
  [log appendString:@"ZS:"];

  tmp = [_cs allKeys];
  if ([tmp containsObject:@"isWarningIgnored"]) {
    tmp = [[tmp mutableCopy] autorelease];
    [tmp removeObject:@"isWarningIgnored"];
  }
  if ([tmp isNotEmpty]) {
    [log appendString:@" "];
    [log appendString:[tmp componentsJoinedByString:@","]];
  }

  if ([_k isNotEmpty]) {
    tmp = [_k componentsJoinedByString:@","];
    [self logWithFormat:@"Note: loosing keys: %@", tmp];
    [log appendString:@" (lost="];
    [log appendString:tmp];
    [log appendString:@")"];
  }
  if ([log length] == 3)
    [log appendString:@" no change detected."];
  return log;
} /* end logTextForChangeSet: */

/* The result of this method, used to create new appointments is a
   WOResponse.  This result is passed directly to the client. */
- (id)createAptWithInfo:(NSDictionary *)_info inContext:(id)_ctx {
  // TODO: should we make a redirect to the created file? probably confuses
  //       clients but is likely to be the correct thing to do.
  // TODO: added 
  NSMutableArray      *keys;
  NSMutableDictionary *changeSet;
  NSException         *error;
  NSString            *etag;
  NSMutableArray      *participants;
  WOResponse          *r;
  NSString            *url;
  id                   tmp;
  
  if (logAptChange) [self logWithFormat:@"GOT: %@", _info];
  
  keys = [[[_info allKeys] mutableCopy] autorelease];
  
  /* remove superflous keys */
  [keys removeObject:@"creationDate"]; // unused
  [keys removeObject:@"uid"];          // unused
  [keys removeObject:@"sequence"];     // extracted above
  
  /* TODO: add new columns */
  [keys removeObject:@"priority"];
  
  /* participants */

  participants = [NSMutableArray arrayWithCapacity:64];
  if ([[_info objectForKey:@"participants"] isNotNull]) {
    /* fetchParticipantsForPersons: comes from the Participants category */
    tmp = [self fetchParticipantsForPersons:
                  [_info objectForKey:@"participants"]
                inContext:_ctx];
    if ([tmp isNotEmpty]) {
      [participants addObjectsFromArray:tmp];
    }
  }
  /* if we got zero participants from the submission then we add
     the default participants from the current context */
  if ([participants count] == 0) {
    tmp = [self defaultParticipantsInContext:_ctx];
    [participants addObjectsFromArray:tmp];
  }
  [keys removeObject:@"participants"];
  
  /* check values */
  
  changeSet = [NSMutableDictionary dictionaryWithCapacity:16];
  
  [changeSet setObject:participants forKey:@"participants"];
  
  SX_NEWKEY(@"startDate");
  SX_NEWKEY(@"endDate");
  SX_NEWKEY(@"title");
  SX_NEWKEY(@"location");
  SX_NEWKEY(@"comment");
  SX_NEWKEY(@"importance");
  SX_NEWKEY(@"lastModified");
  SX_NEWKEY(@"sensitivity");
  SX_NEWKEY(@"evoReminder");
  SX_NEWKEY(@"fbtype");
  SX_NEWKEY(@"isConflictDisabled");

  /* read-access-group */
  
  if ([(tmp = [self pkeyOfGroupInContext:_ctx]) isNotNull]) {
    [changeSet setObject:tmp forKey:@"accessTeamId"];
  } else {
      if ([[self container] isOverview]) {
        tmp = [[self container] defaultReadAccessInContext:_ctx];
        if (tmp != nil) { 
          [changeSet setObject:tmp forKey:@"accessTeamId"];
        } 
      }
    }
  
  /* write access */
  
  tmp = [[self container] defaultWriteAccessListInContext:_ctx];
  if ([tmp isNotEmpty])
    [changeSet setObject:tmp forKey:@"writeAccessList"];

  /* conflicts */
  
  [changeSet setObject:yesNum forKey:@"isWarningIgnored"];

  /* perform changes */
  
  error = [[self aptManagerInContext:_ctx] 
                 createWithEOAttributes:changeSet
	         log:[self logTextForChangeSet:changeSet keys:keys]];
  if ([error isKindOfClass:[NSException class]])
    return error;
  
  ASSIGN(self->eo, error);
  
  /* setup response */
  
  r = [(WOContext *)_ctx response];

  [r setStatus:
       [self shouldReturn201AfterPUTInContext:_ctx]
       ? 201 /* Created */ : 200 /* OK */];

  /* set etag header */
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  /* set location header (TODO: DUP in SxAddress) */
  if ([(tmp = [self->eo valueForKey:@"dateId"]) isNotNull]) {
    if (![[tmp stringValue] isEqualToString:[self nameInContainer]]) {
      /* only set 'location' if it actually changed (on creation) */
      url = [[self container] baseURLInContext:_ctx];
      if (![url hasSuffix:@"/"]) url = [url stringByAppendingString:@"/"];
    
      tmp = [tmp stringValue];
      tmp = [tmp stringByAppendingString:@".ics"];
    
      [r setHeader:[url stringByAppendingString:tmp] forKey:@"location"];
    }
  }
  else {
    [self logWithFormat:
	    @"WARNING: cannot set location header, missing new object id!"];
  }
  return r;
}
#undef SX_NEWKEY

- (void)reloadObjectInContext:(id)_ctx {
  [self->eo release]; self->eo = nil;
  [self objectInContext:_ctx];
  /* Note: apparently 'participants' is not set after this? */
}

#define SX_DIFFKEY(__key__) \
  if ((tmp = [_info valueForKey:__key__])) {\
    if (![tmp isEqual:[eo valueForKey:__key__]])\
      [changeSet setObject:tmp forKey:__key__];\
    [keys removeObject:__key__];\
  }

/* This method performs updates,  the result value is a WOResponse */
- (id)patchAptWithInfo:(NSDictionary *)_info inContext:(id)_ctx {
  WOResponse          *r;
  NSMutableArray      *keys;
  NSMutableDictionary *changeSet;
  NSException         *error;
  NSString            *etag;
  NSMutableArray      *participants;
  id  obj, tmp;
  int oldVersion, newVersion;
  
  /* fetch EO */
  
  if ((obj = [self objectInContext:_ctx]) == nil) {
    /* By default ZideLook will create a new appointment if it cannot find an
       appointment to update.  However, this behaviour can be disabled by
       setting the ZLApt404OnMissingPUTTargets default to YES in which case
       a 404 error will be returned. */
    if (createNewAptWhenNotFound) {
      [self logWithFormat:
              @"Note: object not yet available in DB, creating a new one!"];
      return [self createAptWithInfo:_info inContext:_ctx];
    } else {
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
  [keys removeObject:@"uid"];          // unused => TODO: check that!
  [keys removeObject:@"sequence"];     // extracted above
  [keys removeObject:@"creator"];      // extracted above
  
  // TODO: add a column for this field (TODO: when is it used? valid in iCal?)
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
  SX_DIFFKEY(@"lastModified");
  SX_DIFFKEY(@"importance");
  SX_DIFFKEY(@"sensitivity");
  SX_DIFFKEY(@"evoReminder");
  SX_DIFFKEY(@"fbtype");
  SX_DIFFKEY(@"isConflictDisabled");
  
  participants = [NSMutableArray arrayWithCapacity:1];
  /*
  if ([self isInOverviewFolder]) {
    id team = [self groupInContext:_ctx];
    if (logAptChange) {
      [self logWithFormat:@"%s in overview calendar: %@",
            __PRETTY_FUNCTION__, team];
    }
    if ([team isNotNull])
      [participants addObject:team];
    else {
      id loginEO;
      
      loginEO = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
      [participants addObject:loginEO];
    }
  } */

  /* fetchParticipantsForPersons: comes from the Participants category */ 
  tmp = [self fetchParticipantsForPersons:[_info objectForKey:@"participants"]
              inContext:_ctx];
  
  if ([tmp isNotEmpty]) {
    [participants addObjectsFromArray:tmp];
  } else {
      /* update contains no participants! */
      /* TODO: add user */
    }
  
  /* TODO: mh: hack */
  /*
    force reload because of a rollback that occured during loading of
    participants
  */
  [self reloadObjectInContext:_ctx];
  
  if (![participants isNotEmpty]) {
    // if no participants, take current account
    id account;
    
    account = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
    participants = account != nil ? [NSArray arrayWithObject:account] : nil;
  }
  
  /* ensure that EO participants are fetched */

  tmp = [[self commandContextInContext:_ctx]
	  runCommand:@"appointment::list-participants",
	  @"appointment", self->eo,
	  nil];
  
  /* compare participants */
  
  [keys removeObject:@"participants"];
  participants = (NSMutableArray *)[self checkChangedParticipants:participants
                                         forOldParticipants:tmp
                                         inContext:_ctx];
  if ([participants isNotEmpty]) {
    /* participants changed */
    [changeSet setObject:participants forKey:@"participants"];
  }
  
  /* perform changes */

  if ([changeSet count] < 2) {
    /* no change (just isWarningIgnored) */
    error = nil;
  }
  else {
    error = [[self aptManagerInContext:_ctx]
                 updateRecordWithPrimaryKey:[self primaryKey]
                 withEOChanges:changeSet
                 log:[self logTextForChangeSet:changeSet keys:keys]];
  }
  
  if ([error isKindOfClass:[NSException class]])
    return error;

  /* setup response */
  
  r = [(WOContext *)_ctx response];

#if 0 /* thats wrong in any case? 201 is only returned for _new_ resources */
  [r setStatus:
       [self shouldReturn201AfterPUTInContext:_ctx]
       ? 201 /* Created */ : 200 /* OK */];
#else
  /* 
     Hopefully we don't confuse clients by not returning 200, but 204 is
     required by Sunbird 0.3.
  */
  [r setStatus:204 /* No Content */];
#endif
  
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  return r;
}
#undef SX_DIFFKEY

- (id)_processPUTData:(NSData *)_content
  withParseSelector:(SEL)_parseSel inContext:(id)_ctx
{
  /* request body contains a message/rfc822 or a text/calendar */
  SxAppointmentMessageParser *parser;
  NSArray *infos;
  id      info;
  
  if (![_content isNotEmpty]) {
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
  if (![infos isNotEmpty]) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"no vevent record found in submitted data!"];
  }
  if ([infos count] > 1) {
    [self warnWithFormat:
	    @"got more than one ical component, using the first: %@",
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
  
  if (![ctype isNotEmpty]) {
    // TODO: which clients do that? (eg when editing in Cadaver)
    // DUP in SxTask.m
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
                      reason:@"invalid format for PUT (not a text/calendar)"];
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
  return [(WOApplication *)[WOApplication application] context];
}

- (NSString *)hackVEvent:(NSString *)_vevent {
  NSString *hackSig = @"END:VEVENT\r\n";
  NSMutableString *s;
  
  if (!embedViewURL || ![_vevent hasSuffix:hackSig])
    return _vevent;
  
  /* header */
  s = [[_vevent substringToIndex:[_vevent length] - [hackSig length]] 
        mutableCopy];
  s = [s autorelease];
  
  /* hack */
  [s appendString:@"ATTACH"];
  [s appendString:@";FMTTYPE=text/html;X-CONTENT-DISPOSITION=inline"];
  [s appendString:@";X-LABEL=OGo"];
  [s appendString:@":"];
  [s appendString:
       [[self baseURLInContext:
		[(WOApplication *)[WOApplication application] context]]
	      stringByAppendingString:@"/view"]];
  [s appendString:@"\r\n"];
  
  /* footer */
  [s appendString:hackSig];
  return s;
}

- (NSString *)iCalVEventString {
  NSString *ical;
  SxAptManager *am;
  id obj;
  
  am = [self aptManagerInContext:[self context]];
  
  if ((obj = [self objectInContext:[self context]]) == nil)
    return nil;
  
  // TODO: use command?!
  ical = [am renderAppointmentAsICal:obj timezone:nil];
  return [self hackVEvent:ical];
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
  SxAptManager *am;
  id obj;
  
  am = [self aptManagerInContext:[self context]];
  if ((obj = [self objectInContext:[self context]]) == nil)
    return nil;
  
  return [am renderAppointmentAsMIME:obj timezone:nil];
}

- (id)GETAction:(WOContext *)_ctx {
  NSException *error;
  WOResponse  *r;
  WORequest   *rq;
  id          obj;
  NSTimeZone  *tz;
  id          cmdctx; 
  NSString    *tzName, *etag;

  if ((error = [self matchesRequestConditionInContext:_ctx]) != nil)
    return error;

  cmdctx = [self commandContextInContext:_ctx];
  tzName = [[cmdctx userDefaults] stringForKey:@"timezone"];
  tz     = [tzName isNotEmpty]
    ? (id)[NSTimeZone timeZoneWithAbbreviation:tzName] : nil;
  
  if ((obj = [self objectInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
                        reason:@"did not find EO"];
  }
  
  // TODO: add a cusotm viewer (component) for browsers
  
  // need owner information
  [self fetchOwnerForAppointment:obj inContext:_ctx];
  
  rq = [(WOContext *)_ctx request];
  r  = [(WOContext *)_ctx response];
  [r setContentEncoding:NSUTF8StringEncoding];
  if ([[rq uri] hasSuffix:@".ics"] || 
      [[rq headerForKey:@"accept"] hasPrefix:@"text/calendar"]) {
    NSString *ical;
    
    // TODO: tz
    if ((ical = [self iCalString]) == nil) {
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"could not render EO as iCalendar"];
    }
    
    [r setHeader:@"text/calendar; charset=utf-8" forKey:@"content-type"];
    [r appendContentString:ical];
  } else {
      NSString *mime;
    
      // TODO: tz
      if ((mime = [self iCalMailString]) == nil) {
        return [NSException exceptionWithHTTPStatus:500
                            reason:@"could not render EO as MIME"];
      }
    
      [r setHeader:@"message/rfc822; charset=utf-8" forKey:@"content-type"];
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
  /* Note: Sunbird 0.3 expects a 204 after a delete */
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
