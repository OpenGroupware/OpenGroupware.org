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
// $Id$

#include "SxAppointmentFolder.h"
#include "SxAppointment.h"
#include "SxICalendar.h"
#include "common.h"

#include <Frontend/SxMapEnumerator.h>
#include <Frontend/EOQualifier+Additions.h>
#include <Frontend/NSObject+ExValues.h>
#include <Backend/NSString+rtf.h>
#include <Backend/SxAptManager.h>
#include <Backend/SxContactManager.h>
#include <Backend/SxBackendMaster.h>

// TODO: remove dependency
#include <Backend/Appointments/SxAppointmentRenderer.h>

@interface NSObject(UsedPrivates) // TODO: fix that
- (id)rendererWithFolder:(id)_folder inContext:(id)_ctx;
@end

@interface SxAppointmentFolder(Privates)
- (SxAptManager *)aptManagerInContext:(id)_ctx;
- (id)performZideLookAptQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;
- (id)performZideLookBulkQueryOnGIDs:(NSArray *)_gids inContext:(id)_ctx;
@end

@implementation SxAppointmentFolder

+ (NSString *)entityName {
  return @"Date";
}

- (void)dealloc {
  [self->group release];
  [super dealloc];
}

/* accessors */

- (void)setGroup:(NSString *)_group {
  ASSIGNCOPY(self->group, _group);
}
- (NSString *)group {
  return self->group;
}

- (void)setIsOverview:(BOOL)_flag {
  self->overview = _flag;
}
- (BOOL)isOverview {
  if (!self->overview)
    /* hack to workaround BOOL problem during config evaluation ... */
    self->overview = [[self nameInContainer] isEqualToString:@"Overview"];
  return self->overview;
}

- (BOOL)canHaveOverviewSubfolder {
#if 0
  // TODO: what happens with that code ?
  
  static unsigned showGroupOverviewFolders = -1;

  if (showGroupOverviewFolders == -1) {
    NSUserDefaults *ud;
    
    ud                       = [NSUserDefaults standardUserDefaults];
    showGroupOverviewFolders = [ud boolForKey:@"ZLShowGroupOverviewCalendars"];
  }
  
  if ([self isOverview]) return NO;
  
  if ((self->group != nil) &&
      ((!showGroupOverviewFolders) ||
       ([self->group isEqualToString:@"all intranet"])))
    return NO;
  
  return YES;
#else
  return NO;
#endif
}

/* factory */

- (Class)recordClassForKey:(NSString *)_key {
  [self logWithFormat:@"record class for key: '%@'", _key];
  
  if ([_key length] == 0)
    return [super recordClassForKey:_key];
  
  if (!isdigit([_key characterAtIndex:0])) {
    Class clazz;
    
    [self logWithFormat:@"no digit, ask super for key: '%@'", _key];
    if ((clazz = [super recordClassForKey:_key]))
      return clazz;
    
    [self logWithFormat:@"  no digit super returned no key: '%@'", _key];
    return [SxAppointment class];
  }
  
  [self logWithFormat:@"use SxAppointment for key: '%@'", _key];
  return [SxAppointment class];
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  id obj;
  
  [self logWithFormat:@"childForNewKey: %@", _key];
  
  obj = [[self recordClassForKey:_key] alloc];
  obj = [obj initNewWithName:_key inFolder:self];
  [obj takeValue:[self group] forKey:@"group"];
  return [obj autorelease];
}

- (BOOL)isICalendarName:(NSString *)_name inContext:(id)_ctx {
  if ([_name isEqualToString:@"calendar.ics"])
    return YES;
  if ([_name isEqualToString:@"ics"])
    return YES;
  // only publishing
  if ([_name isEqualToString:@"publish"])
    return YES;
  return NO;
}

- (id)iCalendarForKey:(NSString *)_key inContext:(id)_ctx {
  id obj;
  
  obj = [[SxICalendar alloc] initNewWithName:_key inFolder:self];
  [obj setGroup:[self group]];
  return [obj autorelease];
}

- (id)overviewFolderInContext:(id)_ctx {
  id folder;
  folder = [[NSClassFromString(@"SxAppointmentFolder") alloc] 
	     initWithName:@"Overview" inContainer:self];
  [folder setGroup:[self group]];
  [(SxAppointmentFolder *)folder setIsOverview:YES];
  return [folder autorelease];
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  if ([self isICalendarName:_name inContext:_ctx])
    return [self iCalendarForKey:_name inContext:_ctx];
  
  if ([self canHaveOverviewSubfolder] && [_name isEqualToString:@"Overview"])
    return [self overviewFolderInContext:_ctx];
  
  return [super lookupName:_name inContext:_ctx acquire:_ac];
}

- (NSString *)defaultMethodNameInContext:(id)_ctx {
  if ([[self soClass] hasKey:@"weekoverview" inContext:_ctx])
    return @"weekoverview";
  
  return nil;
}

/* DAV properties */

- (BOOL)davHasSubFolders {
  /* old: appointment folders currently never have child folders */
  /* new: appointment folders has overview folder as subfolder */
  return [self canHaveOverviewSubfolder];
}

- (NSArray *)toOneRelationshipKeys {
  static NSArray *keys = nil;
  if (keys == nil)
    keys = [[NSArray alloc] initWithObjects:@"Overview", nil];
  
  return [self canHaveOverviewSubfolder] ? keys : nil;
}


/* Exchange properties */

- (NSString *)outlookFolderClass {
  return @"IPF.Appointment";
}

- (NSString *)fileExtensionForFileSystem {
  return @"ics"; /* contains iCalendar objects */
}

/* iCalendar / MIME */

- (id)renderAppointmentAsICal:(id)_eo timezone:(NSTimeZone *)_tz
  inContext:(id)_ctx
{
  id am = [self aptManagerInContext:_ctx];
  return [am renderAppointmentAsICal:_eo timezone:_tz];
  // deprecated
  //SxAppointmentRenderer *renderer = [SxAppointmentRenderer renderer];
  //return [renderer renderAppointmentAsICal:_eo timezone:_tz];
}

- (id)renderAppointmentAsMIME:(id)_eo timezone:(NSTimeZone *)_tz
  inContext:(id)_ctx
{
  id am = [self aptManagerInContext:_ctx];
  return [am renderAppointmentAsICal:_eo timezone:_tz];
  // depcrecated
  // SxAppointmentRenderer *renderer = [SxAppointmentRenderer renderer];
  // return [renderer renderAppointmentAsMIME:_eo timezone:_tz];
}

/* DAV Queries (the hard part[y]) */

- (SxAptManager *)aptManagerInContext:(id)_ctx {
  id ctx;
  if ((ctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"no command context !"];
    return nil;
  }
  return [[SxBackendMaster managerWithContext:ctx] aptManager];
}

- (NSString *)uidForPrimaryKey:(id)_pkey url:(NSString *)_url {
  // TODO: use SKYRiX URL ?
  return [_pkey stringValue];
}

- (NSCalendarDate *)defaultStartDate {
  static NSCalendarDate *date;
  if (date == nil) {
    date = [[NSCalendarDate dateWithYear:1998 month:12 day:12
                            hour:12 minute:0 second:0
                            timeZone:nil] retain];
  }
  return date;
}
- (NSCalendarDate *)defaultEndDate {
  static NSCalendarDate *date;
  if (date == nil) {
    date = [[NSCalendarDate dateWithYear:2020 month:12 day:12
                            hour:12 minute:0 second:0
                            timeZone:nil] retain];
  }
  return date;
}

- (SxAptSetIdentifier *)aptSetID {
  NSString *g;
  
  g = [self group];
  return [g length] > 0 
    ? ([self isOverview]
       ? [SxAptSetIdentifier overviewSetForGroup:g]
       : [SxAptSetIdentifier aptSetForGroup:g])
    : ([self isOverview]
       ? [SxAptSetIdentifier privateOverviewSet]
       : [SxAptSetIdentifier privateAptSet]);
}

- (int)zlGenerationCount {
  /* the folder version */
  return [[self aptManagerInContext:nil] 
                generationOfAppointmentSet:[self aptSetID]];
}
- (int)cdoContentCount {
  /* the folder count */
  int count;

  count = [[self aptManagerInContext:nil] 
                 countOfAppointmentSet:[self aptSetID]];
  if (count == -1) {
    [self logWithFormat:@"failed to fetch number of appointments .."];
    return 0;
  }
  if ([self doExplainQueries])
    [self logWithFormat:@"fetched apt count (got %i)", count];
  return count;
}

- (id)performDavURLQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* 
     A query for just the IDs.

     We currently ignore qualifier and sort-orderings, Evo queries that:
     ---
     davLastModified > 1970-01-01T00:00:00Z AND 
     davContentClass = 'urn:content-classes:appointment' AND 
     (exInstanceType = 0 OR exInstanceType = 1))
     ---
  */
  EOQualifier *q;
  NSArray     *dateGIDs;
  
  if ([self doExplainQueries]) {
    [self logWithFormat:@"EXPLAIN: fetching date IDs (qualifier ignored)."];
    if ((q = [_fs qualifier]))
      [self logWithFormat:@"  ignoring qualifier: %@", q];
  }
  
  dateGIDs = [[self aptManagerInContext:_ctx] 
                    gidsOfAppointmentSet:[self aptSetID]];
  if ([self doExplainQueries])
    [self logWithFormat:@"EXPLAIN: processing %i IDs ...", [dateGIDs count]];
  
  return [self davURLRecordsForChildGIDs:dateGIDs inContext:_ctx];
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

- (id)performInitialKOrgExchangeQuery:(EOFetchSpecification *)_fs 
  inContext:(id)_ctx 
{
  // TODO1: fetch proper range, fetch instanceType
  // TODO2: fetch for UID: davUid = 'KOrganizer-554321468.1073'
  EOQualifier *q;
  id tmp;
  
  [self logWithFormat:@"KOrganizer Ex Query: %@", _fs];
  if ((tmp = [self performDavURLQuery:_fs inContext:_ctx]) == nil)
    return nil;
  
  if ([tmp isKindOfClass:[NSEnumerator class]])
    tmp = [[[NSArray alloc] initWithObjectsFromEnumerator:tmp] autorelease];
  
  if ((q = [_fs qualifier])) {
    // TODO: HACK HACK HACK
    if ([q isKindOfClass:[EOKeyValueQualifier class]])
      tmp = [tmp filteredArrayUsingQualifier:q];
  }
  return [tmp objectEnumerator];
}

- (id)performEvoBulkQueryOnGIDs:(NSArray *)_gids inContext:(id)_ctx {
  LSCommandContext *cmdctx;
  NSArray        *apts;
  NSMutableArray *result;
  unsigned i, count;
  NSString *folderURL, *ext;
  NSTimeZone *tz;
  NSString *tzName;

  // TODO: use AptManager's -pkeysAndModDatesAndICalsForGlobalIDs
  // TODO: need to wrap iCal data in MIME
  
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:500
			reason:@"missing command context"];
  }
  [self logWithFormat:@"ctx: %@", cmdctx];
  
  [self logWithFormat:@"bulk: process %i gids ...", [_gids count]];
  apts = [cmdctx runCommand:@"appointment::get-by-globalid",
		   @"gids", _gids,
		   nil];
  
  [[self aptManagerInContext:_ctx]
         fetchParticipantsForAppointments:apts];
  
  count = [apts count];
  [self logWithFormat:@"  fetched %i apts ...", count];
  
  folderURL = [self baseURLInContext:_ctx];
  if (![folderURL hasSuffix:@"/"])
    folderURL = [folderURL stringByAppendingString:@"/"];
  ext = [self fileExtensionForChildrenInContext:_ctx];
  
  // TODO: move rendering of iCals to Backend !!
  //       why? because the icals can be cached in a useful way based on the id
  //       backend method already available
  
  cmdctx = [self commandContextInContext:_ctx];
  tzName = [[cmdctx userDefaults] stringForKey:@"timezone"];
  tz     = ([tzName length])
    ? [NSTimeZone timeZoneWithAbbreviation:tzName] : nil;

  result = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString     *entryName, *url;
    NSDictionary *values;
    id apt, pkey;
    id icaldata;
    NSString *keys[5];
    id  vals[5];
    int p;
    
    apt = [apts objectAtIndex:i];
    
    /* first get key */
    
    pkey = [apt valueForKey:@"dateId"];
    entryName = [pkey stringValue];
    if (ext) {
      entryName = [entryName stringByAppendingString:@"."];
      entryName = [entryName stringByAppendingString:ext];
    }
    url = [folderURL stringByAppendingString:entryName];
    if (url == nil) {
      [self logWithFormat:@"could not process key of apt: %@", apt];
      continue;
    }
    
    /* render iCalendar MIME message */
    [self fetchOwnerForAppointment:apt inContext:_ctx];
    
    icaldata = [self renderAppointmentAsMIME:apt timezone:tz inContext:_ctx];
    icaldata = [icaldata exDavBase64Value];
    
    /* create entry */

    p = 0;
    keys[p] = @"davUid"; vals[p] = [self uidForPrimaryKey:pkey url:url]; p++;
    keys[p] = @"{DAV:}href";           vals[p] = url;  p++;
    keys[p] = @"exInstanceType";       vals[p] = @"0"; p++; // TODO
    keys[p] = @"exMIMERepresentation"; vals[p] = icaldata; p++;
    
    values = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
    [result addObject:values];
    [values release];
  }
  
  [cmdctx rollback];
  
  return result;
}

- (id)performBulkQuery:(EOFetchSpecification *)_fs
  onGlobalIDs:(NSArray *)_gids
  inContext:(id)_ctx 
{
  static NSSet *evoICalSet = nil;
  static NSSet *zlAptSet   = nil;
  NSSet *propNames;

  if (evoICalSet == nil)
    evoICalSet = [[self propertySetNamed:@"EvoAptICalQuerySet"] copy];
  if (zlAptSet == nil)
    zlAptSet = [[self propertySetNamed:@"ZideLookAptQuery"] copy];
    
  if ([_gids count] == 0)
    return [NSArray array];

  propNames = [NSSet setWithArray:[_fs selectedWebDAVPropertyNames]];
  
  if ([propNames isSubsetOfSet:evoICalSet]){
    if ([self doExplainQueries]) {
      [self logWithFormat:@"perform Evo apt bulk query: %@",
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
    }
    return [self performEvoBulkQueryOnGIDs:_gids inContext:_ctx];
  }
  
  if ([propNames isSubsetOfSet:zlAptSet]){
    if ([self doExplainQueries]) {
      [self logWithFormat:@"perform ZideLook apt bulk query: %@",
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
    }
    
    return [self performZideLookBulkQueryOnGIDs:_gids inContext:_ctx];
  }
  
  /* unknown bulk query */
  {
    NSString *ua =
      [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];

    [self logWithFormat:@"unknown apt bulk query for(%@): %@", ua,
          [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  
    if ([ua hasPrefix:@"Evolution"])
      return [self performEvoBulkQueryOnGIDs:_gids inContext:_ctx];
    
    return [self performZideLookBulkQueryOnGIDs:_gids inContext:_ctx];
  }
}

- (id)renderListGIDEntry:(EOKeyGlobalID *)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.vcf?sn=$sn$</key>
    <key name="davDisplayName">$sn$, $givenname$</key>
    TODO: <key name="davContentType">text/vcalendar</key> 
  */
  NSMutableDictionary *record;
  NSString *url, *pkey;
  
  if (_entry == nil)
    return nil;
  
  record = [NSMutableDictionary dictionaryWithCapacity:4];
  
  pkey = [[_entry keyValues][0] stringValue];
  url = [[NSString alloc] initWithFormat:@"%@%@.ics", [self baseURL], pkey];
  [record setObject:url  forKey:@"{DAV:}href"];
  [record setObject:pkey forKey:@"davDisplayName"];
  [url release];
  return record;
}

- (id)performListQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  NSArray *gids;
  
  gids = [[self aptManagerInContext:_ctx] 
                gidsOfAppointmentSet:[self aptSetID]];
  
  return [SxMapEnumerator enumeratorWithSource:[gids objectEnumerator]
			  object:self selector:@selector(renderListGIDEntry:)];
}

- (id)getIDsAndVersionsAction:(id)_ctx {
  SxAptManager *am;
  NSString     *csv;
  WOResponse   *response;
  
  am = [self aptManagerInContext:_ctx];
  
  if ((csv = [am idsAndVersionsCSVForAppointmentSet:[self aptSetID]]) == nil) {
    [self logWithFormat:@"could not fetch appointment set ?!"];
    return nil;
  }
  response = [(WOContext *)_ctx response];
  [response setStatus:200 /* OK */];
  [response setHeader:@"text/plain" forKey:@"content-type"];
  [response setHeader:@"close"      forKey:@"connection"];
  
  [response appendContentString:csv];
  
  return response;
}

- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)propNames
  inContext:(id)_ctx
{
  static NSSet *cadaverSet = nil;
  static NSSet *korgExSet  = nil;
  static NSSet *zlAptSet   = nil;
  SEL handler = NULL;
  
  if (cadaverSet == nil)
    cadaverSet = [[self propertySetNamed:@"CadaverListSet"] copy];
  if (korgExSet == nil)
    korgExSet = [[self propertySetNamed:@"KOrgExInitialAptQuerySet"] copy];
  if (zlAptSet == nil)
    zlAptSet = [[self propertySetNamed:@"ZideLookAptQuery"] copy];
  
  if ([propNames count] == 1) {
    NSString *propName;
    
    propName = [propNames anyObject];
    if ([propName isEqualToString:@"davURL"])
      return @selector(performDavURLQuery:inContext:);
  }
  else if ([propNames count] == 2) {
    if ([propNames containsObject:@"davUid"] &&
        [propNames containsObject:@"davLastModified"]) {
      return @selector(performDavUidAndModDateQuery:inContext:);
    }
  }
  if ([propNames isSubsetOfSet:korgExSet])
    return @selector(performInitialKOrgExchangeQuery:inContext:);
  if ([propNames isSubsetOfSet:cadaverSet])
    return @selector(performListQuery:inContext:);
  
  handler = [super fetchSelectorForQuery:_fs onAttributeSet:propNames
                   inContext:_ctx];
  if (handler) return handler;
  
  /* ZideLook */
  if ([propNames isSubsetOfSet:zlAptSet])
    handler = @selector(performZideLookAptQuery:inContext:);
  
  return handler;
}

- (SEL)defaultFetchSelectorForZLQuery {
  return @selector(performZideLookAptQuery:inContext:);
}
- (SEL)defaultFetchSelectorForEvoQuery {
  // TODO: maybe not a clever choice ...
  return @selector(performDavUidAndModDateQuery:inContext:);
}

- (NSString *)folderAllPropSetName {
  return @"DefaultAptFolderProps";
}
- (NSString *)entryAllPropSetName {
  return @"DefaultAppointmentProperties";
}

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  /* overridden for efficiency (caches array in static var) */
  static NSArray *defFolderNames = nil;
  static NSArray *defEntryNames  = nil;
  
  if (defFolderNames == nil) {
    defFolderNames =
      [[[self propertySetNamed:[self folderAllPropSetName]] allObjects] copy];
  }
  if (defEntryNames == nil) {
    defEntryNames =
      [[[self propertySetNamed:[self entryAllPropSetName]] allObjects] copy];
  }
  return [self isBulkQueryContext:_ctx] ? defEntryNames : defFolderNames;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  if (self->group) [ms appendFormat:@" group=%@", self->group];
  [ms appendString:@">"];
  return ms;
}

@end /* SxAppointmentFolder */

@implementation SxAppointmentFolder(ZideLookQueries)

- (id)zideLookRendererInContext:(id)_ctx {
  static Class RendererClass = NULL;

  if (RendererClass == NULL) {
    RendererClass = NSClassFromString(@"SxZLAptRenderer");

    if (RendererClass == NULL) {
      [self logWithFormat:@"try to instantiate 'SxZLAptRenderer'"];
      return nil;
    }
  }
  return [RendererClass rendererWithFolder:self inContext:_ctx];
}

- (id)performZideLookBulkQueryOnGIDs:(NSArray *)_gids inContext:(id)_ctx {
  NSArray *dateInfos;
  
  dateInfos = [[self aptManagerInContext:_ctx]
                     coreInfoOfAppointmentsWithGIDs:_gids
                     inSet:[self aptSetID]];
  if ([self doExplainQueries]) {
    [self logWithFormat:@"delivering %i core date infos (bulk) ...", 
            [dateInfos count]];
  }
  
  return [SxMapEnumerator enumeratorWithSource:[dateInfos objectEnumerator]
			  object:[self zideLookRendererInContext:_ctx]
			  selector:@selector(renderEntry:)];
}

- (id)performZideLookAptQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  NSArray *dateInfos;

  if ([self doExplainQueries]) {
    [self logWithFormat:@"perform ZideLook apt query: %@",
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  
  dateInfos = [[self aptManagerInContext:_ctx] 
		     coreInfoForAppointmentSet:[self aptSetID]];
  if ([self doExplainQueries]) {
    [self logWithFormat:@"delivering %i core date infos (whole set) ...", 
            [dateInfos count]];
  }
  
  return [SxMapEnumerator enumeratorWithSource:[dateInfos objectEnumerator]
			  object:[self zideLookRendererInContext:_ctx]
			  selector:@selector(renderEntry:)];
}

- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the second query by ZideLook, get basic message infos */
  /*
    davDisplayName,davResourceType,davDisplayName,outlookMessageClass,
    cdoDisplayType,davDisplayName
  */
  [self logWithFormat:@"ZL Messages Query [depth=%@] (return aptinfo): %@",
          [[(WOContext *)_ctx request] headerForKey:@"depth"],
          [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  return [self performZideLookAptQuery:_fs inContext:_ctx];
}

@end /* SxAppointmentFolder(ZideLookQueries) */
