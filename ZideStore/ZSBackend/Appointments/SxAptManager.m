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

#include "SxAptManager.h"
#include "SxAptSetHandler.h"
#include "SxSetCacheManager.h"
#include "NGResourceLocator+ZSB.h"
#include "common.h"
#include <NGObjWeb/NSException+HTTP.h>

#include "SxContactManager.h"
#include <Contacts/SxContactEmailSQLQuery.h>

@implementation SxAptManager

static NSNumber *noNum = nil;
static NSArray  *freeBusyGetAttrs       = nil;
static NSArray  *pkeyAndVersionGetAttrs = nil;
static NSArray  *eoExtractAttrs         = nil;

static BOOL logAptChange                 = NO;
static int  SxAptFolder_MonthsIntoPast   = 2;
static int  SxAptFolder_MonthsIntoFuture = 12;

+ (void)initialize {
  static BOOL didInit = NO;
  NGResourceLocator *locator;
  NSUserDefaults *ud;
  NSDictionary   *plist;
  NSString       *p;
  if (didInit) return;

  noNum = [[NSNumber numberWithBool:NO] retain];
  
  locator = [NGResourceLocator zsbResourceLocator];
  p = [locator lookupFileWithName:@"AptBackendSets.plist"];
  plist = [p length] > 10
    ? [NSDictionary dictionaryWithContentsOfFile:p]
    : nil;
  if (plist == nil)
    [self logWithFormat:@"ERROR: could not load apt-backend plist: %@", p];
  
  freeBusyGetAttrs       = [[plist objectForKey:@"FreeBusyAttrs"]      copy];
  pkeyAndVersionGetAttrs = [[plist objectForKey:@"KeyAndVersionAttrs"] copy];
  eoExtractAttrs         = [[plist objectForKey:@"EOExtractAttrs"]     copy];
  didInit = YES;

  ud = [NSUserDefaults standardUserDefaults];
  logAptChange = [ud boolForKey:@"ZLAptLogChanges"];

  SxAptFolder_MonthsIntoPast = 
    [[ud objectForKey:@"SxAptFolder_MonthsIntoPast"] intValue];
  if (SxAptFolder_MonthsIntoPast == 0) 
    SxAptFolder_MonthsIntoPast = -2;
  else if (SxAptFolder_MonthsIntoPast > 0)
    SxAptFolder_MonthsIntoPast = -SxAptFolder_MonthsIntoPast;

  SxAptFolder_MonthsIntoFuture = 
    [[ud objectForKey:@"SxAptFolder_MonthsIntoFuture"] intValue];
  if (SxAptFolder_MonthsIntoFuture == 0) 
    SxAptFolder_MonthsIntoFuture = 12;
  else if (SxAptFolder_MonthsIntoFuture < 0)
    SxAptFolder_MonthsIntoFuture = -SxAptFolder_MonthsIntoFuture;
}

- (void)dealloc {
  [self->setIdToHandler release];
  [super dealloc];
}

/* set-handler */

- (SxAptSetHandler *)handlerForSet:(SxAptSetIdentifier *)_set {
  SxAptSetHandler *cm;
  
  if (self->setIdToHandler == nil)
    self->setIdToHandler = [[NSMutableDictionary alloc] init];
  else if ((cm = [self->setIdToHandler objectForKey:_set]))
    return cm;
  
  if ((cm = [[SxAptSetHandler alloc] initWithSetId:_set manager:self])== nil) {
    [self logWithFormat:@"could not create handler for set: %@", _set];
    return nil;
  }
  [self->setIdToHandler setObject:cm forKey:_set];
  return [cm autorelease];
}
- (SxSetCacheManager *)cacheManagerForSet:(SxAptSetIdentifier *)_set {
  return [[self handlerForSet:_set] cacheManager];
}

/* common */

- (NSArray *)globalIDsForLoginAccount {
  EOGlobalID *gid;
  
  if ((gid = [self globalIDForLoginAccount]) == nil)
    return nil;
  return [NSArray arrayWithObject:gid];
}

- (NSArray *)globalIDsForGroupWithPrimaryKey:(NSNumber *)_group {
  static NSMutableDictionary *pkeyToGID = nil;
  id gid;
    
  if (pkeyToGID == nil) 
    pkeyToGID = [[NSMutableDictionary alloc] init];
  else if ((gid = [pkeyToGID objectForKey:_group]))
    /* cached */
    return gid;
  
  gid = [self globalIDForGroupWithPrimaryKey:_group];
  
  gid = [NSArray arrayWithObject:gid];
  [pkeyToGID setObject:gid forKey:_group];
  return gid;
}

- (NSArray *)globalIDsForGroupWithName:(NSString *)_group {
    static NSMutableDictionary *nameToGID = nil;
    id gid;
    
    if (nameToGID == nil) 
      nameToGID = [[NSMutableDictionary alloc] init];
    else if ((gid = [nameToGID objectForKey:_group]))
      /* cached */
      return gid;
    
    // TODO: cache non-existence ?
    if ((gid = [self globalIDForGroupWithName:_group])) {
      gid = [NSArray arrayWithObject:gid];
      [nameToGID setObject:gid forKey:_group];
    }
    return gid;
}

- (NSArray *)globalIDsForGroup:(id)_group {
  if (![_group isNotNull])
    return nil;
  
  if ([_group isKindOfClass:[NSNumber class]])
    return [self globalIDsForGroupWithPrimaryKey:_group];
  
  if ([_group isKindOfClass:[NSString class]])
    return [self globalIDsForGroupWithName:_group];
  
  [self logWithFormat:@"cannot process group id: %@ (%@)", _group,
	  NSStringFromClass([_group class])];
  return nil;
}

- (NSCalendarDate *)defaultStartDate {
  // TODO: Attention: the server must be restarted now and then !!!
  static NSCalendarDate *date;
  if (date == nil) {
    NSCalendarDate *now;
    int monthDiff;
    
    now = [NSCalendarDate calendarDate];
    monthDiff = SxAptFolder_MonthsIntoPast;
    
    date = [[now dateByAddingYears:0 months:monthDiff days:0
                 hours:0 minutes:0 seconds:0]
                 retain];
    [self logWithFormat:@"appointment range start: %@", date];
  }
  return date;
}
- (NSCalendarDate *)defaultEndDate {
  // Attention: the server must be restarted now and then !!!
  static NSCalendarDate *date;
  if (date == nil) {
    NSCalendarDate *now;
    int monthDiff;
    
    now = [NSCalendarDate calendarDate];
    monthDiff = SxAptFolder_MonthsIntoFuture;
    date = [[now dateByAddingYears:0 months:monthDiff days:0
                 hours:0 minutes:0 seconds:0]
                 retain];
    [self logWithFormat:@"appointment range start: %@", date];
  }
  return date;
}

/* queries */

- (NSEnumerator *)listAccountsWithEmail:(NSString *)_eml {
  SxContactEmailSQLQuery *query;
  
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmail:_eml];
  [query makeAccountQuery];
  return [query runAndRollback];
}
- (NSEnumerator *)listPublicPersonsWithEmail:(NSString *)_eml {
  SxContactEmailSQLQuery *query;
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmail:_eml];
  [query makePublicQuery];
  return [query runAndRollback];
}
- (NSEnumerator *)listPrivatePersonsWithEmail:(NSString *)_eml {
  SxContactEmailSQLQuery *query;
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmail:_eml];
  return [query runAndRollback];
}

- (id)_searchEmail:(NSString *)_email {
  NSEnumerator *e;
  id           result;
  id           tmp;

  e = [self listAccountsWithEmail:_email];
  if ((result = [e nextObject]) == nil) {
    e = [self listPrivatePersonsWithEmail:_email];
    if ((result = [e nextObject]) == nil) {
      e = [self listPublicPersonsWithEmail:_email];
      if ((result = [e nextObject]) == nil) {
        [self logWithFormat:@"failed to fetch account for email: %@", _email];
        return nil;
      }
    }
  }

  if ((tmp = [e nextObject]) != nil) {
    [self logWithFormat:@"email isn't unique in database: %@. found: %@",
            _email, [NSArray arrayWithObjects:result, tmp, @"...", nil]];
  }
  while ((tmp = [e nextObject])) {}

  return result;
}

- (void)fetchOwnerForAppointment:(id)_apt {
  id ownerId = [_apt valueForKey:@"ownerId"];
  id ids[1];
  id gid;
  if (ownerId != nil) {
    SxContactManager *cm;
    cm     = [SxContactManager managerWithContext:[self commandContext]];
    ids[0] = ownerId;
    gid    = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                            keys:ids keyCount:1 zone:NULL];

    gid = [cm accountForGlobalID:gid];
    if (gid != nil)
      [_apt takeValue:gid forKey:@"owner"];
  }
}

- (id)accountForLoginEmail:(NSString *)_login {
  NSString *user;

  user = _login;
  if ([user hasPrefix:@"SMTP:"])
    user = [user substringFromIndex:5];

  if (![user length]) {
    [self logWithFormat:@"invalid user for freebusy: %@", _login];
    return nil;
  }
      
  return [self _searchEmail:user];
}
- (EOGlobalID *)globalIDFromAccountInfo:(id)_info {
  id pkey;
  
  pkey = [_info valueForKey:@"pkey"];
  return [EOKeyGlobalID globalIDWithEntityName:@"Person"
                        keys:&pkey keyCount:1 zone:NULL];
}

- (NSArray *)freeBusyDataForUser:(id)_user
  from:(NSDate *)_from to:(NSDate *)_to
{
  id      account;
  NSArray *dates;
  id ctx;
  
  if ((account = [self accountForLoginEmail:_user]) == nil)
    return nil;
  account = [self globalIDFromAccountInfo:account];
  
  ctx = [self commandContext];
  dates = [ctx runCommand:@"appointment::query",
                 @"fromDate",  _from,
                 @"toDate",    _to,
                 @"companies", [NSArray arrayWithObject:account],
               nil];
  if ([dates count] == 0) {
    [self rollback];
    return [NSArray array];
  }
  
  dates = [ctx runCommand:@"appointment::get-by-globalid",
                 @"gids", dates, @"attributes", freeBusyGetAttrs, nil];
  [self rollback];
  return dates;
}

- (NSArray *)pkeysAndModDatesOfSet:(SxAptSetIdentifier *)_sid 
  from:(NSDate *)_from to:(NSDate *)_to 
{
  NSArray *infos;
  
  infos = [[self handlerForSet:_sid] fetchPkeysAndModDatesFrom:_from to:_to];
  if (![self rollback])
    [self logWithFormat:@"ERROR: could not rollback transaction !"];
  
  return infos;
}

#if 0
- (NSArray *)pkeysAndVersionsForGlobalIDs:(NSArray *)_gids {
  NSArray        *apts;
  NSMutableArray *ma;
  unsigned       max, i;
  
  apts = [[self commandContext]
                runCommand:@"appointment::get-by-globalid",
                @"gids", _gids,
                @"attributes", pkeyAndVersionGetAttrs,
                nil];
  
  if ((max = [apts count]) == 0) return [NSArray array];
  
  ma = [NSMutableArray arrayWithCapacity:(max + 1)];

  for (i = 0; i < max; i++) {
    NSDictionary  *entry;
    id date;
    id keys[2], vals[2];
    
    date    = [apts objectAtIndex:i];
    
    keys[0] = @"pkey";    vals[0] = [date valueForKey:@"dateId"];
    keys[1] = @"version"; vals[1] = [date valueForKey:@"objectVersion"];
    
    entry = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:2];
    [ma addObject:entry];
    [entry release];
  }
  
  return ma;
}
#endif

- (NSArray *)coreInfoForAppointmentSet:(SxAptSetIdentifier *)_set {
  // returns: title, location, end/startdate, sensitivity
  NSArray *infos;
  
  infos = [[self handlerForSet:_set] fetchCoreInfo];
  [self rollback];
  return infos;
}
- (NSArray *)coreInfoOfAppointmentsWithGIDs:(NSArray *)_gids 
  inSet:(SxAptSetIdentifier *)_set
{
  // returns: title, location, end/startdate, sensitivity
  NSArray *infos;
  
  infos = [[self handlerForSet:_set] fetchCoreInfoForGIDs:_gids];
  [self rollback];
  return infos;
}

/* the new set-queries */

- (NSArray *)gidsOfAppointmentSet:(SxAptSetIdentifier *)_set {
  NSArray *gids;
  
  gids = [[self handlerForSet:_set] fetchGIDs];
  [self rollback];
  return gids;
}
- (NSArray *)gidsOfAppointmentSet:(SxAptSetIdentifier *)_set 
  from:(NSDate *)_from to:(NSDate *)_to
{
  NSArray *gids;
  
  gids = [[self handlerForSet:_set] fetchGIDsFrom:_from to:_to];
  [self rollback];
  return gids;
}

- (int)generationOfAppointmentSet:(SxAptSetIdentifier *)_set {
  /* 
     This is used by ZideLook to track folder changes.
     TODO: implement folder-change detection ... (snapshot of last
     id/version set contained in the folder)
  */
  int i;
  i = [[self handlerForSet:_set] generationOfSet];
  [self rollback];
  return i;
}

- (NSString *)idsAndVersionsCSVForAppointmentSet:(SxAptSetIdentifier *)_set {
  NSString *s;
  s = [[self handlerForSet:_set] idsAndVersionsCSV];
  [self rollback];
  return s;
}
- (int)countOfAppointmentSet:(SxAptSetIdentifier *)_set {
  int count;
  count = [[self handlerForSet:_set] fetchCount];
  [self rollback];
  return count;
}

- (NSDictionary *)zlAppointmentWithID:(id)_aid {
  // returns: full info for appointment
  // TODO: add cache based on key+version+user
  NSMutableDictionary *record;
  EOKeyGlobalID *gid;
  id date;
  
  if (_aid == nil)
    return nil;
  
  if ([_aid isKindOfClass:[EOKeyGlobalID class]])
    gid = _aid;
  else {
    if (![_aid isKindOfClass:[NSNumber class]])
      _aid = [NSNumber numberWithInt:[_aid intValue]];
    
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
                         keys:&_aid keyCount:1 zone:NULL];
  }
  
  date = [[self commandContext] runCommand:@"appointment::get-by-globalid",
                                  @"gid", gid, nil];

  if (date == nil) {
    [self logWithFormat:@"found no date for GID: %@", gid];
    return nil;
  }
  {
    NSString *perm;
    if (((perm = [date valueForKey:@"permissions"]) == nil) ||
        ([perm rangeOfString:@"v"].length == 0)) {
      [self logWithFormat:@"permission denied for GID: %@", gid];
      return nil;
    }
  }

  [[self commandContext] runCommand:@"appointment::get-comments",
                         @"object", date, nil];
  
  /* extract EO attributes */
  
  record = [NSMutableDictionary dictionaryWithCapacity:64];
  [record addEntriesFromDictionary:[date valuesForKeys:eoExtractAttrs]];
  
  // TODO: fetch participants, resources, ...

  [self fetchParticipantsForAppointments:[NSArray arrayWithObject:record]];
  
  /* rollback */
  [self rollback];
  
  return record;
}
- (NSArray *)zlAppointmentsWithIDs:(NSArray *)_ids {
  // TODO: use a SKYRiX bulk-query !
  NSMutableArray *ma;
  unsigned i, count;
  
  if (_ids == nil) return nil;
  if ((count = [_ids count]) == 0) return [NSArray array];
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSDictionary *zlRecord;
    id aid;
    
    aid      = [_ids objectAtIndex:i];
    zlRecord = [self zlAppointmentWithID:aid];
    
    if (zlRecord == nil) zlRecord = (id)[NSNull null];
    [ma addObject:zlRecord];
  }
  return ma;
}

/* update/create operations */

- (id)eoForPrimaryKey:(NSNumber *)_key {
  /* should not be used by frontend ... */
  LSCommandContext *ctx;
  id o;
  
  ctx = [self commandContext];
  o = [ctx runCommand:@"appointment::get",  @"dateId", _key, nil];
  if (o == nil) {
    [self logWithFormat:@"appointment::get returned no result for pkey %@",
            _key];
    return nil;
  }
  if (![self commit]) {
    [self logWithFormat:@"could not commit transaction !"];
    [self rollback];
  }
  
  o = ([o isKindOfClass:[NSArray class]])
    ? [[o lastObject] retain]
    : [o retain];
  
  // fetch needed attributes of participants 
  if (o)
    [self fetchParticipantsForAppointments:[NSArray arrayWithObject:o]];
  
  return o;
}

- (NSString *)fetchPermissionsForApt:(id)_apt {
  NSString *perm;
  if ((perm = [_apt valueForKey:@"permissions"]) == nil) {
    perm =
      [[self commandContext] runCommand:@"appointment::access",
                             @"gid", [_apt valueForKey:@"globalID"],
                             nil];
  }
  return perm;
}

- (id)updateParticipant:(id)_part forEO:(id)_eo
            allowAppend:(BOOL)_allowAppend
{
  NSMutableArray *participants;
  NSException    *error = nil;
  unsigned int i, cnt;
  id companyId;
  BOOL found = NO;

  // get old participants and find matching entry
  participants =
    [[[_eo valueForKey:@"participants"] mutableCopy] autorelease];

  if (![participants count]) {
    [self logWithFormat:@"got no old participants object !"];
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"could not locate participants for object!"];
  }

  companyId = [_part valueForKey:@"companyId"];
  if (companyId != nil) {
    cnt = [participants count];
    for (i = 0; i < cnt; i++) {
      if ([[[participants objectAtIndex:i] valueForKey:@"companyId"]
                          isEqual:companyId]) {
        // found corresponding participant entry
        [participants replaceObjectAtIndex:i withObject:_part];
        found = YES;
        break;
      }
    }
  }

  // check if no matching entry allowed
  if ((!found) && (!_allowAppend)) {
    return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			reason:@"cannot add participant to appointment!"];
  }

  if (!found) {
    // append as new entry
    [participants addObject:_part];
  }

  error = nil;
  NS_DURING {
    _eo = [[self commandContext]
                 runCommand:@"appointment::set-participants",
                 @"object", _eo,
                 @"participants", participants,
                 nil];
    
    if (![self commit]) {
      error = [[NSException exceptionWithHTTPStatus:409 /* Conflict */
			    reason:@"could not commit transaction !"] retain];
    }
  }
  NS_HANDLER {
    error = [localException retain];
  }
  NS_ENDHANDLER;
  error = [error autorelease];
  
  if (error) {
    [self rollback];
    return error;
  }
  return _eo;
}

- (id)updateRecordWithPrimaryKey:(NSNumber *)_key
  withEOChanges:(NSMutableDictionary *)_record log:(NSString *)_log 
{
  NSException *error = nil;
  id          object = nil;
  NSString    *perm;

  if (logAptChange)
    [self logWithFormat:@"PATCH: %@", _record];
  
  /* fetch EO */
  
  if ((object = [self eoForPrimaryKey:_key]) == nil) {
    [self logWithFormat:@"got no EO object !"];
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"could not locate SKYRiX object for ID !"];
  }
  
  /* check preconditions */
  
  if ([_record count] == 0) {
    return [NSException exceptionWithHTTPStatus:200 /* OK */
			reason:@"got no attributes to update"];
  }

  /* check access */
  
  perm = [self fetchPermissionsForApt:object];
  if ([perm rangeOfString:@"e"].length == 0) {
    NSArray *participants;
    
    // no edit allowed.
    // --> check wheter login is participant and may
    //     edit his participant status

    participants = [_record valueForKey:@"participants"];
    if ([participants count]) {
      unsigned int cnt, i;
      id currentId;
      currentId = [[[self commandContext] valueForKey:LSAccountKey]
                          valueForKey:@"companyId"];
      cnt = [participants count];
      for (i = 0; i < cnt; i++) {
        if ([[[participants objectAtIndex:i] valueForKey:@"companyId"]
                            isEqual:currentId]) {
          [self logWithFormat:@"appointment edit is not allowed. "
                @"only updating participant information."];
          return [self updateParticipant:[participants objectAtIndex:i]
                       forEO:object allowAppend:NO];
        }
      }
    }
      
    return
      [NSException exceptionWithHTTPStatus:403 /* forbidden */
                   reason:@"you have no edit-access for this appointment"];
  }
  
  /* add log */
  
  if ([_log length] > 0)
    [_record setObject:_log forKey:@"logText"];
  
  /* execute */
  
  [_record setObject:object forKey:@"object"];
  error = nil;
  NS_DURING {
    object = [[self commandContext]
               runCommand:@"appointment::set" arguments:_record];
    
    if (![self commit]) {
      error = [[NSException exceptionWithHTTPStatus:409 /* Conflict */
			    reason:@"could not commit transaction !"] retain];
    }
  }
  NS_HANDLER {
    error = [localException retain];
  }
  NS_ENDHANDLER;
  error = [error autorelease];

  /* handle errors and return */
  
  if (error) {
    [self rollback];
    return error;
  }
  return object;
}

- (id)createWithEOAttributes:(NSMutableDictionary *)_record 
  log:(NSString *)_log
{
  NSException *error = nil;
  id          object = nil;
  
  if ([_record count] == 0) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
			reason:@"missing properties for apt to create !"];
  }
  
  /* add log */
  
  if ([_log length] > 0)
    [_record setObject:_log forKey:@"logText"];
  
  /* execute */
  
  error = nil;
  NS_DURING {
    object = [[self commandContext]
               runCommand:@"appointment::new" arguments:_record];
    
    if (![self commit]) {
      error = [[NSException exceptionWithHTTPStatus:409 /* Conflict */
			    reason:@"could not commit transaction !"] retain];
    }
  }
  NS_HANDLER {
    error = [localException retain];
  }
  NS_ENDHANDLER;
  error = [error autorelease];
  
  /* handle errors and return */
  
  if (error) {
    [self rollback];
    return error;
  }
  return object;
}

- (NSException *)deleteRecordWithPrimaryKey:(NSNumber *)_key {
  NSException *error;
  
  error = nil;
  NS_DURING {
    id obj;
    NSString *perm;
    if ((obj = [self eoForPrimaryKey:_key]) == nil) {
      [self logWithFormat:@"got no EO object !"];
      return [NSException exceptionWithHTTPStatus:404 /* Not Found */
                          reason:@"could not locate SKYRiX object for ID !"];
    }

    perm = [self fetchPermissionsForApt:obj];
    if ([perm rangeOfString:@"d"].length == 0) {
      [self logWithFormat:@"got no delete permissions for date !"];
      error = [[NSException exceptionWithHTTPStatus:403 /* forbidden */
                            reason:@"date deletion is not allowed"] retain];
    }
    else {
      [[self commandContext]
             runCommand:@"appointment::delete", @"object", obj, 
             @"checkPermissions", noNum, nil];
      if (![self commit]) {
        error =[[NSException exceptionWithHTTPStatus:409 /* Conflict */
                             reason:@"could not commit transaction !"] retain];
      }
    }
  }
  NS_HANDLER
    error = [localException retain];
  NS_ENDHANDLER;
  error = [error autorelease];
  
  if (error != nil) {
    [self logWithFormat:@"delete failed: %@", error];
    [self rollback];
  }
  return error;
}

@end /* SxAptManager */
