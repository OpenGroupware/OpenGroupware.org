/*
  Copyright (C) 2000-2008 SKYRIX Software AG
  Copyright (C) 2006-2008 Helge Hess

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray, NSTimeZone;

/*
  This command fetches appointment-objects based on a list of EOGlobalIDs.
  
  Additionally it runs:

    appointment::get-participants
    appointment::get-comments
    appointment::get-access-team-info
  
  Special key for 'attributes' fetches:
    participants. => used when fetching the persons
      .comment
      .extendedAttributes
      .telephones
    comment       => fetch the comment (additionalKeys)
    globalID
    permissions
*/

@interface LSGetAppointmentsForGlobalIDs : LSDBObjectBaseCommand
{
  NSArray    *gids;
  NSArray    *attributes;
  NSTimeZone *timeZone;
  NSArray    *sortOrderings;
  BOOL       singleFetch;
  NSString   *groupBy;
  
  /* transient state */
  NSDictionary *access;
}

@end

#include <LSFoundation/LSCommandKeys.h>
#include <EOControl/EOControl.h>
#include <GDLAccess/GDLAccess.h>
#include <NGExtensions/NSNull+misc.h>
#include "common.h"

@implementation LSGetAppointmentsForGlobalIDs

static BOOL  debugOn       = NO;
static NSSet *AllListAttrs = nil;

+ (void)initialize {
  if (AllListAttrs == nil) {
    AllListAttrs = 
      [[NSSet alloc] initWithObjects: @"dateId", @"parentDateId", @"startDate",
                     @"endDate", @"cycleEndDate", @"ownerId", @"accessTeamId",
                     @"isAttendance", @"isAbsence", @"isViewAllowed",
                     @"isConflictDisabled", @"type", @"notificationTime",
                     @"fbtype", @"busyType",
                     @"dbStatus", @"objectVersion", @"resourceNames", nil];
  }
}

- (NSString *)entityName {
  return @"Date";
}

- (void)dealloc {
  [self->groupBy       release];
  [self->access        release];
  [self->sortOrderings release];
  [self->timeZone      release];
  [self->attributes    release];
  [self->gids          release];
  [super dealloc];
}

/* execution */

- (void)_prepareForExecutionInContext:(id)_context {
  NSEnumerator *e;
  EOGlobalID   *gid;
  
  /* ensure that all gid's are LSDate gid's */
  
  e = [self->gids objectEnumerator];
  while ((gid = [e nextObject]) != nil) {
    NSString *eName;
    
    eName = [(EOKeyGlobalID *)gid entityName];
    if (![eName isEqualToString:@"Date"]) {
      [self assert:NO
            format:@"globalID %@ is illegal for command "
            @"(only accepts LSDate's)", gid];
    }
  }
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_correctTimeZoneOfAppointment:(NSDictionary *)_apt {
  /* this works for dicts as well as for EOs */
  NSCalendarDate *d;
  
  if (self->timeZone == nil)
    return; /* cannot correct */

  [[_apt objectForKey:@"startDate"] setTimeZone:self->timeZone];
  [[_apt objectForKey:@"endDate"]   setTimeZone:self->timeZone];
  
  d = [_apt objectForKey:@"cycleEndDate"];
  if ([d isNotNull]) [d setTimeZone:self->timeZone];
}

- (void)_setupAttributesArray:(NSMutableArray **)attrs 
  listAttributes:(NSMutableArray **)listAttrs
  participantKeys:(NSMutableArray **)participantKeys
  additionalKeys:(NSMutableArray **)additionalKeys
  makeMutable:(BOOL *)makeMutable
  fetchPermissions:(BOOL *)getPerms
  fetchGlobalIDs:(BOOL *)getGids
{
  // TODO: move to own object?
  /*
    Keys:
    - participants.
  */
  EOEntity *entity;
  unsigned i, count;

  *additionalKeys  = nil;
  *participantKeys = nil;
  *makeMutable = NO;
  *getGids     = NO;
  *getPerms    = NO;
  
  entity     = [self entity];
  *attrs     = [NSMutableArray arrayWithCapacity:16];
  *listAttrs = [NSMutableArray arrayWithCapacity:16];
  
  for (i = 0, count = [self->attributes count]; i < count; i++) {
    NSString    *attrName;
    EOAttribute *attr;
      
    attrName = [self->attributes objectAtIndex:i];
    attr     = [entity attributeNamed:attrName];
    
    if (attr != nil) {
      [*attrs addObject:attr];
      if ([AllListAttrs containsObject:attrName])
	[*listAttrs addObject:attr];
      continue;
    }
      
    if ([attrName isEqualToString:@"globalID"]) {
      *getGids     = YES;
      *makeMutable = YES;
      continue;
    }
    if ([attrName isEqualToString:@"permissions"]) {
        *getPerms    = YES;
        *makeMutable = YES;
        continue;
    }
    if ([attrName hasPrefix:@"participants."]) {
      if (*participantKeys == nil)
	*participantKeys = [NSMutableArray arrayWithCapacity:8];
      
      *makeMutable = YES;
      [*participantKeys addObject:[attrName substringFromIndex:13]];
      continue;
    }
    
    if (*additionalKeys == nil)
      *additionalKeys = [NSMutableArray arrayWithCapacity:8];
    [*additionalKeys addObject:attrName];
  }
  
  if (![self->attributes containsObject:@"dateId"]) {
    [*attrs     addObject:[entity attributeNamed:@"dateId"]];
    [*listAttrs addObject:[entity attributeNamed:@"dateId"]];
  }
}

- (void)_addFetchedRow:(NSDictionary *)row
  toResults:(NSMutableArray *)results
  andToResultGIDs:(NSMutableArray *)resultGids
  gidToApt:(NSMutableDictionary *)gidToApt
  makeMutable:(BOOL)makeMutable
  fetchPermissions:(BOOL)getPerms
  fetchGlobalIDs:(BOOL)getGids
{
  EOGlobalID *gid;
  
  gid = [[self entity] globalIDForRow:row];
      
  /* correct timezone */
  [self _correctTimeZoneOfAppointment:row];
  
  if (makeMutable) // be careful, is released below
    row = [row mutableCopy];
  
  if (getGids)
    [(NSMutableDictionary *)row setObject:gid forKey:@"globalID"];
  
  if (getPerms) {
    NSString *permissions;
    
    permissions = [self->access objectForKey:gid];
    [(NSMutableDictionary *)row setObject:permissions forKey:@"permissions"];
  }
  
  [results    addObject:row];
  [resultGids addObject:gid];
  [gidToApt setObject:row forKey:gid];
      
  if (makeMutable)
    [row release]; row = nil;
}

- (void)appendGID:(EOKeyGlobalID *)gid toInString:(NSMutableString **)_in_ {
  NSString *k;
        
  k = [[gid keyValues][0] stringValue];
  if ([k length] == 0) {
    [self logWithFormat:@"got invalid GID for permission: %@", gid];
    return;
  }
  
  if (*_in_ == nil) {
    *_in_ = [[NSMutableString alloc] initWithCapacity:256];
    [*_in_ appendString:@"%@ IN ("];
  }
  else
    [*_in_ appendString:@","];
  [*_in_ appendString:k];
}

- (void)_associateCompaniesWithAppointments:(NSArray *)results 
  withGIDs:(NSArray *)resultGids
  personGIDs:(NSDictionary *)pgids
  persons:(NSDictionary *)persons teams:(NSDictionary *)teams
{
  unsigned i, count;

  for (i = 0, count = [results count]; i < count; i++) {
    NSMutableDictionary *apt        = nil;
    EOGlobalID          *agid       = nil;
    NSArray             *pgida      = nil;
    NSString            *aptPerms   = nil;
    BOOL                viewAllowed = NO;
    unsigned            psCount     = 0;      
    id       *ps;
    NSArray  *a;        
    unsigned j, k;
      
    apt         = [results    objectAtIndex:i];
    agid        = [resultGids objectAtIndex:i];
    pgida       = [pgids objectForKey:agid];
    aptPerms    = [self->access objectForKey:agid];
    viewAllowed = [aptPerms rangeOfString:@"v"].length > 0 ? YES : NO;
      
    if ((psCount = [pgida count]) == 0)
      continue;

    k  = 0;
    a  = nil;
    ps = calloc(psCount + 2, sizeof(id));
    NSAssert(ps, @"calloc() failed ..");

      for (j = 0, k = 0; j < psCount; j++) {
          EOGlobalID *pgid = nil;
          
          pgid = [pgida objectAtIndex:j];
          
          ps[j] = [teams objectForKey:pgid];
          if (ps[j] == nil) {
            ps[j] = [persons objectForKey:pgid];
            if (ps[j] && !viewAllowed &&
                ![[ps[j] valueForKey:@"isAccount"] boolValue]) {
              id  gid, pid, keys[2], values[2];
              int n;
              
              gid = [ps[j] valueForKey:@"globalID"];
              pid = [ps[j] valueForKey:@"companyId"];
              
              n = 0;
              if (gid) {
                keys[n]   = @"globalID";
                values[n] = gid;
                n++;
              }
              if (pid) {
                keys[n]   = @"companyId";
                values[n] = pid;
                n++;
              }
              ps[j] =
                [NSDictionary dictionaryWithObjects:values forKeys:keys
                              count:n];
            }
          }
          
          if (!ps[j])
            ps[j] = [NSDictionary dictionary];
      }
      a = [[NSArray alloc] initWithObjects:ps count:j];
      if (ps != NULL) free(ps); ps = NULL;
      
      [apt setObject:a forKey:@"participants"];
      [a release]; a = nil;
  }
}

- (NSDictionary *)_fetchTeamsForGIDs:(NSSet *)teamGids 
  participantKeys:(NSArray *)participantKeys
  inContext:(id)_context
{
  EOEntity *teamEntity = nil;
  NSArray  *teamAttrs  = nil;
  unsigned i, count, count2;
  id       *objs;
  
  if ([teamGids count] == 0)
    return nil;

  teamEntity = [[self database] entityNamed:@"Team"];
  count      = [participantKeys count];
  objs       = calloc(count + 1, sizeof(id));
  for (i = 0, count2=0; i < count; i++) {
        NSString *key;

        key = [participantKeys objectAtIndex:i];
        if ([teamEntity attributeNamed:key]) {
          objs[count2] = key;
          count2++;
        }
  }
  objs[count2] = @"dbStatus"; count2++;
      
  teamAttrs = [NSArray arrayWithObjects:objs count:count2];
  if (objs != NULL) free(objs);
  
  return LSRunCommandV(_context, @"team", @"get-by-globalid",
		       @"gids",       teamGids,
		       @"groupBy",    @"globalID",
		       @"attributes", teamAttrs,
		       @"fetchArchivedTeams", [NSNumber numberWithBool:YES],
		       nil);
}

- (NSDictionary *)_fetchParticipantGIDsForAptGIDs:(NSArray *)_resultGids
  inContext:(id)_context
{
  return LSRunCommandV(_context, @"appointment", @"get-participants",
		       @"appointments",   _resultGids,
		       @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
		       nil);
}

- (void)_addCompanyGIDs:(NSArray *)participants 
  toPersonGIDs:(NSMutableSet *)personGids_
  andTeamGIDs:(NSMutableSet *)teamGids_
{
  unsigned i, count;

  for (i = 0, count = [participants count]; i < count; i++) {
    EOKeyGlobalID *pgid;
    
    pgid = [participants objectAtIndex:i];
    if ([[pgid entityName] isEqualToString:@"Person"])
      [personGids_ addObject:pgid];
    else
      [teamGids_ addObject:pgid];
  }
}

- (NSDictionary *)_fetchPersonEOsForGIDs:(NSSet *)personGids
  attributes:(NSArray *)personAttrs
  inContext:(id)_context
{
  return LSRunCommandV(_context, @"person", @"get-by-globalid",
		       @"gids",       personGids,
		       @"groupBy",    @"globalID",
		       @"attributes", personAttrs,
		       @"fetchArchivedPersons", [NSNumber numberWithBool:YES],
		       nil);
}

- (NSString *)buildInFormatForGIDs:(NSArray *)_gids fromIndex:(unsigned)i
  batchSize:(unsigned)batchSize gidCount:(unsigned)gidCount
{
  NSMutableString *in;
  unsigned j, addCount;

  in = [NSMutableString stringWithCapacity:batchSize * 4];
  [in appendString:@"%@ IN ("];
    
  for (j = i, addCount = 0; (j < (i + batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid;
      NSString      *s;
      
      gid = [_gids objectAtIndex:j];
      s   = [[gid keyValues][0] stringValue];
      
      if ([s length] == 0) {
        [self logWithFormat:@"got weird GID: %@ (str=%@)", gid, s];
        continue;
      }
      
      if (addCount != 0)
        [in appendString:@","];
      
      [in appendString:s];
      addCount++;
  }
  [in appendString:@")"];
    
  if (addCount == 0)
    [self logWithFormat:@"did not add any GID to IN query !"];
  
  return addCount == 0 ? (NSMutableString *)nil : in;
}

- (id)_fetchAttributesInContext:(id)_context gids:(NSArray *)_gids {
  // TODO: split up this HUGE method
  NSMutableDictionary *gidToApt = nil;
  NSMutableArray      *results, *resultGids;
  NSMutableArray      *attrs, *additionalKeys, *participantKeys, *listAttrs;
  EOAdaptorChannel    *adCh;
  NSString            *pkeyAttrName;
  EOEntity            *entity;
  unsigned            gidCount, batchSize, i;
  BOOL                getGids, getPerms, makeMutable;
  static Class        NSArrayClass = Nil;

  if (NSArrayClass == Nil)
    NSArrayClass = [NSArray class];
  
  if ((gidCount = [_gids count]) == 0)
    return [NSArrayClass array];
  
  entity          = [self entity];
  pkeyAttrName    = [[entity primaryKeyAttributeNames] objectAtIndex:0];
  adCh            = [[_context valueForKey:LSDatabaseChannelKey]
                               adaptorChannel];
  if (adCh == nil)
    [self assert:NO reason:@"missing adaptor channel"];
  
  /* setup attributes array */
  [self _setupAttributesArray:&attrs listAttributes:&listAttrs
	participantKeys:&participantKeys additionalKeys:&additionalKeys
	makeMutable:&makeMutable fetchPermissions:&getPerms
	fetchGlobalIDs:&getGids];
  if ([participantKeys isNotEmpty])
    gidToApt = [NSMutableDictionary dictionaryWithCapacity:256];
  
  *(&batchSize) = gidCount > 200 ? 200 : gidCount;
  
  results    = [NSMutableArray arrayWithCapacity:gidCount];
  resultGids = [NSMutableArray arrayWithCapacity:gidCount];
  
  for (*(&i) = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    EOSQLQualifier  *q, *listQ;
    NSMutableString *in, *listIn;
    NSEnumerator    *allFetched;
    unsigned     j;
    BOOL         ok;
    NSDictionary *row;
    
    /* build qualifier */

    in     = nil;
    listIn = nil;
    q      = nil;
    listQ  = nil;
    
    for (j = i; (j < (i + batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid;
      NSString      *perm;
      
      gid  = [_gids objectAtIndex:j];
      perm = [self->access objectForKey:gid];
      
      if ([perm rangeOfString:@"v"].length > 0)
	[self appendGID:gid toInString:&in];
      else if ([perm rangeOfString:@"l"].length > 0)
	[self appendGID:gid toInString:&listIn];
    }
    if ([in length] > 0) {
      [in appendString:@")"];
      q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                  qualifierFormat:in, pkeyAttrName];
      [in release]; in = nil;
    }
    if ([listIn length] > 0) {
      [listIn appendString:@")"];
      listQ = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                      qualifierFormat:listIn, pkeyAttrName];
      [listIn release]; listIn = nil;
    }
    
    /* select appointment objects */
    
    {
      NSMutableArray *all;
      
      *(&all) = [NSMutableArray arrayWithCapacity:64];

      /* objs with full view access */
      if (q != nil) {
        ok = [adCh selectAttributes:attrs
                   describedByQualifier:q
                   fetchOrder:nil
                   lock:NO];
        [q release]; q = nil;
        
        if (!ok) [self assert:ok format:@"could not select objects by gid"];
        /* fetch appointment rows */
        while ((row = [adCh fetchAttributes:attrs withZone:NULL]) != nil)
          [all addObject:row];
      }

      /* objs with list view access */
      if (listQ != nil) {
        ok = [adCh selectAttributes:listAttrs
                   describedByQualifier:listQ
                   fetchOrder:nil
                   lock:NO];
        
        [listQ release]; listQ = nil;
        
        if (!ok) [self assert:ok format:@"couldn't select objects by gid"];
        /* fetch appointment rows */
        while ((row = [adCh fetchAttributes:listAttrs withZone:NULL]))
          [all addObject:row];
      }
      if ([self->sortOrderings count] > 0) {
	// TODO: what is the exception handler good for ?
	
        NS_DURING {
          all = (id)
            [all sortedArrayUsingKeyOrderArray:self->sortOrderings];
        }
        NS_HANDLER
          printf("LSGetAppointmentsForGlobalIDs: "
                 "%s\n", [[localException description] cString]);
        NS_ENDHANDLER;
      }
      allFetched = [all objectEnumerator];
    }
    
    while ((row = [allFetched nextObject]) != nil) {
      [self _addFetchedRow:row 
	    toResults:results andToResultGIDs:resultGids gidToApt:gidToApt
	    makeMutable:makeMutable
	    fetchPermissions:getPerms fetchGlobalIDs:getGids];
    }
  }
  
  /* fetch participant info */
  if (([participantKeys count] > 0) && ([results count] > 0)) {
    NSDictionary *pgids;
    NSArray      *participants;
    NSMutableSet *teamGids, *personGids;
    NSDictionary *teams = nil, *persons = nil;
    NSEnumerator *e;
    
    NSAssert(makeMutable, @"should be 'makeMutable' ..");
    
    pgids = [self _fetchParticipantGIDsForAptGIDs:resultGids 
		  inContext:_context];
    
    /* collect and separate company gids for fetch */
    
    teamGids   = [NSMutableSet setWithCapacity:128];
    personGids = [NSMutableSet setWithCapacity:128];
    teams      = nil;
    persons    = nil;
    
    e = [pgids objectEnumerator];
    while ((participants = [e nextObject]) != nil) {
      [self _addCompanyGIDs:participants 
	    toPersonGIDs:personGids andTeamGIDs:teamGids];
    }
    
    /* fetch teams */
    
    if ([teamGids isNotEmpty]) {
      teams = [self _fetchTeamsForGIDs:teamGids 
		    participantKeys:participantKeys
		    inContext:_context];
    }
    else
      teamGids = nil;
    
    /* fetch persons */
    
    if ([personGids isNotEmpty]) {
      EOEntity *personEntity; 
      NSArray  *personAttrs;
      unsigned i, count, count2;
      id       *objs;
      
      personEntity = [[self database] entityNamed:@"Person"];
      count        = [participantKeys count];
      objs         = calloc(count + 4, sizeof(id));
      
      for (i = 0, count2 = 0; i < count; i++) {
        NSString *key;
	
        key = [participantKeys objectAtIndex:i];
        if ([personEntity attributeNamed:key] != nil) {
          objs[count2] = key;
          count2++;
        }
	else {
	  /* special keys */
	  if ([key isEqualToString:@"comment"]) {
	    objs[count2] = key;
	    count2++;
	  }
	  else if ([key isEqualToString:@"extendedAttributes"]) {
	    objs[count2] = key;
	    count2++;
	  }
	  else if ([key isEqualToString:@"telephones"]) {
	    objs[count2] = key;
	    count2++;
	  }
	}
      }
      objs[count2] = @"dbStatus"; count2++;
      personAttrs  = [NSArrayClass arrayWithObjects:objs count:count2];
      if (objs != NULL) free(objs); objs = NULL;

      persons = [self _fetchPersonEOsForGIDs:personGids 
		      attributes:personAttrs inContext:_context];
    }
    else
      persons = nil;
    
    /* associate companies with appointments */
    [self _associateCompaniesWithAppointments:results withGIDs:resultGids
	  personGIDs:pgids persons:persons teams:teams];
  }

  if ([additionalKeys containsObject:@"comment"]) {
    LSRunCommandV(_context,
                  @"appointment", @"get-comments",
                  @"objects", results, nil);
  }

  return results;
}

- (NSException *)_handleEOSortException:(NSException *)_exception {
  [self errorWithFormat:@"sort failed: %@", _exception];
  return nil;
}

- (NSArray *)_sortResultEOs:(NSArray *)results {
  if ((self->sortOrderings != nil) && [self->sortOrderings count] > 0) {
    NS_DURING {
      results = (id)
        [results sortedArrayUsingKeyOrderArray:self->sortOrderings];
    }
    NS_HANDLER
      [[self _handleEOSortException:localException] raise];
    NS_ENDHANDLER;
  }
  else {
    results = [[results copy] autorelease];
  }
  return results;
}

- (void)_fetchParticipantsIntoAppointmentEOs:(NSArray *)_e inContext:(id)_ctx {
  LSRunCommandV(_ctx, @"appointment", @"get-participants", 
		@"appointments", _e, nil);
}

- (void)_fetchCommentsIntoAppointmentEOs:(NSArray *)_eos inContext:(id)_ctx {
  LSRunCommandV(_ctx, @"appointment", @"get-comments", @"objects", _eos, nil);
}
- (void)_fetchTeamInfoIntoAppointmentEOs:(NSArray *)_eos inContext:(id)_ctx {
  LSRunCommandV(_ctx, @"appointment", @"get-access-team-info",
                @"appointments", _eos, nil);
}

- (id)_fetchEOsInContext:(id)_context gids:(NSArray *)_gids {
  NSMutableArray    *results;
  EODatabaseChannel *dbCh;
  unsigned          gidCount, batchSize, i;
  
  if ((gidCount = [_gids count]) == 0)
    return [NSArray array];
  
  if ((dbCh = [_context valueForKey:LSDatabaseChannelKey]) == nil)
    [self assert:(dbCh != nil) reason:@"missing database channel"];

  batchSize = gidCount > 200 ? 200 : gidCount;

  //  nonEOgids = [NSMutableArray array];
  
  *(&results) = nil;
  for (i = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    EOSQLQualifier *q;
    NSString       *in;
    BOOL           ok;
    id             eo;
    
    in = [self buildInFormatForGIDs:gids fromIndex:i batchSize:batchSize
	       gidCount:gidCount];
    if (in == nil) {
      [self logWithFormat:@"did not add any GID to IN query !"];
      continue;
    }
    
    q = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                qualifierFormat:in,
                                  [[[self entity]
                                          primaryKeyAttributeNames]
                                          objectAtIndex:0]];
    /* select objects */
    
    ok = [dbCh selectObjectsDescribedByQualifier:q fetchOrder:nil];
    [q release]; q = nil;
    
    if (!ok) [self assert:ok format:@"couldn't select objects by gid"];

    if (results == nil)
      results = [NSMutableArray arrayWithCapacity:gidCount];
    
    /* fetch objects */
    
    while ((eo = [dbCh fetchWithZone:NULL]) != nil) {
      EOGlobalID *gid;
      NSString   *permissions;
      
      gid         = [eo valueForKey:@"globalID"];
      permissions = [self->access objectForKey:gid];
      
      if (permissions != nil)
        [eo takeValue:permissions forKey:@"permissions"];
      
      [results addObject:eo];
      
      /* correct timezone */
      [self _correctTimeZoneOfAppointment:eo];
    }
  }
  
  /* sort result */
  
  results = (id)[self _sortResultEOs:results];
  
  /* fetch additional info */
  [self _fetchParticipantsIntoAppointmentEOs:results inContext:_context];
  [self _fetchCommentsIntoAppointmentEOs:results     inContext:_context];
  [self _fetchTeamInfoIntoAppointmentEOs:results     inContext:_context];
  
  return results;
}

- (NSDictionary *)_groupResults:(NSArray *)results {
  unsigned            i, count;
  NSMutableDictionary *mapped;
  
  if (self->groupBy == nil)
    return (id)results; // hack
  
  count  = [results count];
  mapped = [[NSMutableDictionary alloc] initWithCapacity:count];
    
  for (i = 0; i < count; i++) {
    id obj, key;
      
    obj = [results objectAtIndex:i];
    key = [obj valueForKey:self->groupBy];
    if (key == nil) key = [NSNull null];
    
    [mapped setObject:obj forKey:key];
  }
  results = [mapped copy];
  [mapped release]; mapped = nil;
  
  return [results autorelease];
}

- (NSArray *)_fetchAccessInfoForGlobalIDs:(NSArray *)_gids inContext:(id)_ctx {
  return LSRunCommandV(_ctx, @"appointment", @"access", @"gids", _gids, nil);
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  id                results;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  self->access = 
    [[self _fetchAccessInfoForGlobalIDs:self->gids inContext:_context] retain];

  if (debugOn) [self logWithFormat:@"ACCESS: %@", self->access];
  
  results = (self->attributes == nil)
    ? [self _fetchEOsInContext:_context        gids:self->gids]
    : [self _fetchAttributesInContext:_context gids:self->gids];
  
  if (self->singleFetch)
    results = [results count] > 0 ? [results objectAtIndex:0] : nil;
  
  if (self->groupBy)
    results = [self _groupResults:results];
  
  [self setReturnValue:results];
  
  [pool release]; pool = nil;
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  ASSIGNCOPY(self->gids, _gids);
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:_gid ? [NSArray arrayWithObject:_gid] : nil];
  self->singleFetch = YES;
}
- (EOGlobalID *)globalID {
  return [self->gids lastObject];
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone, _tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setSortOrderings:(NSArray *)_orderings {
  ASSIGN(self->sortOrderings, _orderings);
}
- (NSArray *)sortOrderings {
  return self->sortOrderings;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:([_value isNotNull] ? _value : nil)];
  else if ([_key isEqualToString:@"groupBy"]) {
    ASSIGN(self->groupBy, _value);
  }
  else if ([_key isEqualToString:@"sortOrderings"])
    [self setSortOrderings:_value];
  else if ([_key isEqualToString:@"sortOrdering"])
    [self setSortOrderings:[NSArray arrayWithObject:_value]];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_value];
  else if ([_key isEqualToString:@"timeZoneName"]) {
    id tz;
    tz = _value != nil
      ? [NSTimeZone timeZoneWithAbbreviation:_value] : (NSTimeZone *)nil;
    [self setTimeZone:tz];
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"groupBy"])
    v = self->groupBy;
  else if ([_key isEqualToString:@"sortOrderings"])
    v = [self sortOrderings];
  else if ([_key isEqualToString:@"sortOrdering"]) {
    v = [self sortOrderings];
    v = [v objectAtIndex:0];
  }
  else if ([_key isEqualToString:@"timeZone"])
    v = [self timeZone];
  else if ([_key isEqualToString:@"timeZoneName"])
    v = [[self timeZone] abbreviation];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetAppointmentsForGlobalIDs */
