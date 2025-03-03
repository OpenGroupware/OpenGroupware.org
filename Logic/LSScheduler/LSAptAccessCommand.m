/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

/*
  appointment::access (LSAptAccessCommand)
  
  Parameters
  - gid  - EOKeyGlobalID
  or
  - gids - array of EOKeyGlobalID
  
  Takes either a single global-id or multiple gids and returns either
  a single string containing the permissions or a dictionary where the
  key is the gid and the value is the permission-string.

  TODO: better documentation

  TODO: add ability to check permissions of other accounts, not just the
        login user.
*/

@class NSArray;

@interface LSAptAccessCommand : LSDBObjectBaseCommand
{
  NSArray *gids;
  BOOL    singleFetch; /* set if the 'gid' parameter is used */
}
@end

#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@implementation LSAptAccessCommand

static NSString *right_deluv = @"deluv";
static NSString *right_luv   = @"luv";
static NSString *right_lv    = @"lv";
static NSString *right_l     = @"l";
static EONull   *null  = nil;

+ (void)initialize {
  if (null == nil)
    null = [[EONull null] retain];
}

- (NSString *)entityName {
  return @"Date";
}

- (void)dealloc {
  [self->gids release];
  [super dealloc];
}

/* execution */

- (BOOL)isRootAccountPKey:(NSNumber *)_pkey inContext:(id)_ctx {
  return [_pkey intValue] == 10000 ? YES : NO;
}

- (void)setReturnValueToCopyOfValue:(id)_value {
  id copyValue;
  
  copyValue = [_value copy];
  [self setReturnValue:copyValue];
  [copyValue release];
}

- (NSArray *)_fetchTeamGIDsOfAccountWithGID:(EOGlobalID *)_gid
  inContext:(id)_ctx
{
  return LSRunCommandV(_ctx, @"account", @"teams",
		       @"object", _gid,
		       @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
		       nil);
}

- (NSArray *)_fetchMemberGIDsOfTeamWithGID:(EOGlobalID *)_gid
  inContext:(id)_ctx
{
  return LSRunCommandV(_ctx, @"team", @"members",
		       @"team", _gid,
		       @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
		       nil);
}

- (EOKeyGlobalID *)teamGID:(NSNumber *)_pkey {
  if (_pkey == nil) return nil;
  return [EOKeyGlobalID globalIDWithEntityName:@"Team"
			keys:&_pkey keyCount:1 zone:NULL];
}
- (EOKeyGlobalID *)personGID:(NSNumber *)_pkey {
  if (_pkey == nil) return nil;
  return [EOKeyGlobalID globalIDWithEntityName:@"Person"
			keys:&_pkey keyCount:1 zone:NULL];
}

- (void)_executeForRootInContext:(id)_context {
  /* root has access to all operations */
  NSMutableDictionary *access;
  NSEnumerator *e;
  EOGlobalID   *gid;
  
  if (self->singleFetch) {
    [self setReturnValue:right_deluv];
    return;
  }
  
  access = [NSMutableDictionary dictionaryWithCapacity:[self->gids count]];
  e = [self->gids objectEnumerator];
  while ((gid = [e nextObject]) != nil)
    [access setObject:right_deluv forKey:gid];
  
  [self setReturnValueToCopyOfValue:access];
}

- (void)processAppointmentRow:(NSDictionary *)row entity:(EOEntity *)entity
  loginIdValue:(unsigned int)loginPid loginTeams:(NSArray *)loginTeams
  access:(NSMutableDictionary *)access
  readAccessGIDs:(NSMutableArray *)readAccessDates
  writeAccessLists:(NSMutableDictionary *)writeAccessLists
{
  NSNumber   *accessTeamId;
  BOOL       hasReadAccess;
  EOGlobalID *gid;
  NSNumber   *ownerId;
      
  gid     = [entity globalIDForRow:row];
  ownerId = [row objectForKey:@"ownerId"];
  
  if ([ownerId intValue] == loginPid) {
    /* account is owner */
    [access setObject:right_deluv forKey:gid];
    return;
  }

  /* account is not the owner */

  hasReadAccess = NO;
        
  accessTeamId = [row objectForKey:@"accessTeamId"];
  if (![accessTeamId isNotNull]) {
    #if 0 // hh(2024-09-19): unused
    isPrivate = YES;
    #endif
  }
  else {
    EOGlobalID *accessTeamGid;
          
    accessTeamGid = [EOKeyGlobalID globalIDWithEntityName:@"Team"
				   keys:&accessTeamId keyCount:1
				   zone:NULL];
          
    if ([loginTeams containsObject:accessTeamGid]) {
      /* account is in read-access group */
      hasReadAccess = YES;
    }
  }
        
  if (hasReadAccess) {
    id   l;
    BOOL hasWriteAccess = NO;
	  
    l = [row valueForKey:@"writeAccessList"];
	  
    if ([l isNotNull]) {
      NSArray    *acl;
      int        j, cnt;
      EOGlobalID *wAccessTeamGid;

      acl = [l componentsSeparatedByString:@","];
      cnt = [acl count];
            
      for (j = 0; j < cnt; j++) {
	      NSNumber *staffPid;
      
	      staffPid = [NSNumber numberWithInt:
			             [[acl objectAtIndex:j] intValue]];
                    
	      wAccessTeamGid = [EOKeyGlobalID globalIDWithEntityName:@"Team"
					      keys:&staffPid keyCount:1
					      zone:NULL];
      
	      if ([loginTeams containsObject:wAccessTeamGid]) {
	        hasWriteAccess = YES;
	        break;
	      }
	      else if (loginPid == [staffPid intValue]) {
	        hasWriteAccess = YES;
	        break;
	      }
      }
    }
    if (hasWriteAccess) {
      [access setObject:right_deluv forKey:gid];
    }
    else {
      [readAccessDates addObject:gid]; /* check for 'u' later */
      [access setObject:right_lv forKey:gid];
    }
  }
  else {
    [readAccessDates addObject:gid]; /* check for 'u' and 'v' later */
    [access setObject:right_l forKey:gid];
    {
      // write access list may be needed later
      id l = [row valueForKey:@"writeAccessList"];
	    
      if ([l isNotNull])
	      [writeAccessLists setObject:l forKey:gid];
    }
  }
}

- (void)processReadAccessDates:(NSArray *)readAccessDates
  loginGID:(EOGlobalID *)loginGid loginTeams:(NSArray *)loginTeams
  access:(NSMutableDictionary *)access
  writeAccessLists:(NSMutableDictionary *)writeAccessLists
  inContext:(id)_ctx
{
  // TODO: explain exactly what this does
  /* check participants rights */
  NSDictionary        *ps;
  NSEnumerator        *agids;
  EOGlobalID          *gid;
  NSMutableDictionary *teamToPs; /* cache team members */

  if (![readAccessDates isNotEmpty])
    return;
  
  ps = LSRunCommandV(_ctx, @"appointment", @"get-participants",
		     @"dates",          readAccessDates,
		     @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
		     nil);
    
  teamToPs  = nil;
  agids = [readAccessDates objectEnumerator];
  while ((gid = [agids nextObject]) != nil) {
    NSArray  *psa;
    unsigned psac;
    BOOL     hasReadAccess  = NO;
    BOOL     hasWriteAccess = NO;
     
    psa  = [ps objectForKey:gid];
    psac = [psa count];
      
    if ([psa containsObject:loginGid]) {
      /* is participant */
      [access setObject:right_luv forKey:gid];
      hasReadAccess = YES;
    }
    else if (psac > 0) {
      unsigned i;
        
      if (teamToPs == nil)
	teamToPs = [NSMutableDictionary dictionaryWithCapacity:32];

      for (i = 0; i < psac; i++) {
	EOGlobalID *pgid;
          
	pgid = [psa objectAtIndex:i];
	  
	if ([[pgid entityName] isEqualToString:@"Team"]) {
	  NSSet *pss;
            
	  if ((pss = [teamToPs objectForKey:pgid]) == nil) {
	    NSArray *tmp;
	      
	    tmp = [self _fetchMemberGIDsOfTeamWithGID:pgid inContext:_ctx];
	    if (tmp != nil) {
	      pss = [NSSet setWithArray:tmp];
	      [teamToPs setObject:pss forKey:pgid];
	    }
	  }
	  if ([pss containsObject:loginGid]) {
	    [access setObject:right_luv forKey:gid];
	    hasReadAccess = YES;
	    break;
	  }
	}
      }
    }
    if (hasReadAccess) {
      // now account has read access
      // maybe also write access
      // --> check writeAccessList
      id l;
	
      if ([(l = [writeAccessLists objectForKey:gid]) isNotNull]) {
	NSArray    *acl;
	int        j, cnt;
	EOGlobalID *wAccessTeamGid;
	EOGlobalID *wAccessPartGid;

	acl = [l componentsSeparatedByString:@","];
	cnt = [acl count];
            
	for (j = 0; j < cnt; j++) {
	  NSNumber *staffPid;
	    
	  staffPid = [NSNumber numberWithInt:
				 [[acl objectAtIndex:j] intValue]];
	    
	  wAccessTeamGid = [self teamGID:staffPid];
	  wAccessPartGid = [self personGID:staffPid];
	  if ([loginTeams containsObject:wAccessTeamGid]) {
	    hasWriteAccess = YES;
	    break;
	  }
	  else if ([loginGid isEqual:wAccessPartGid]) {
	    hasWriteAccess = YES;
	    break;
	  }
	}
      }
      if (hasWriteAccess)
	[access setObject:right_deluv forKey:gid];
    }
  }
}

- (int)batchSize {
  static int batchSize = -1;
  if (batchSize <= 0) { // THREAD
    batchSize = [[NSUserDefaults standardUserDefaults]
                                 integerForKey:@"LSAptAccessBatchSize"];
    if (batchSize < 10) batchSize = 10000;
  }
  return batchSize;
}

- (void)_executeInContext:(id)_ctx {
  // TODO: split up this HUGE method
  NSAutoreleasePool     *pool;
  EOEntity              *entity;
  NSArray               *attrs;
  EOAdaptorChannel      *adCh;
  NSString              *pkeyAttrName;
  unsigned              i, gidCount, batchSize;
  NSMutableDictionary   *access;
  NSMutableDictionary   *writeAccessLists;
  NSMutableArray        *readAccessDates;
  id                    login;
  int                   loginPid;
  NSArray               *loginTeams;
  
  if ((gidCount = [self->gids count]) == 0) {
    [self setReturnValue:nil];
    return;
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  
  login    = [_ctx valueForKey:LSAccountKey];
  
  if ([self isRootAccountPKey:[login valueForKey:@"companyId"] 
	    inContext:_ctx]) {
    [self _executeForRootInContext:_ctx];
    [pool release];
    return;
  }
  
  loginPid = [[login valueForKey:@"companyId"] intValue];

  loginTeams = [self _fetchTeamGIDsOfAccountWithGID:
		       [login valueForKey:@"globalID"] inContext:_ctx];
  
  access          = [NSMutableDictionary dictionaryWithCapacity:gidCount];
  writeAccessLists= [NSMutableDictionary dictionaryWithCapacity:gidCount];
  readAccessDates = [NSMutableArray arrayWithCapacity:gidCount];

  entity = [self entity];
  pkeyAttrName = [[entity primaryKeyAttributeNames] objectAtIndex:0];
  attrs = [NSArray arrayWithObjects:
                     [entity attributeNamed:pkeyAttrName],
                     [entity attributeNamed:@"ownerId"],
                     [entity attributeNamed:@"accessTeamId"],
                     [entity attributeNamed:@"writeAccessList"],
                     nil];
  
  adCh = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  [self assert:(adCh != nil) reason:@"missing adaptor channel"];
  
  batchSize = gidCount > [self batchSize] ? [self batchSize] : gidCount;

  for (i = 0; i < gidCount; i += batchSize) {
    /* fetch in IN batches */
    EOSQLQualifier  *q;
    NSMutableString *in;
    NSDictionary    *row;
    unsigned j, addCount;
    BOOL     ok, isFirst;
    

    /* build qualifier */

    isFirst = YES;
    in      = [[NSMutableString alloc] initWithCapacity:batchSize * 4];
    [in appendString:@"%@ IN ("];
    
    for (j = i, addCount = 0; (j < (i+batchSize)) && (j < gidCount); j++) {
      EOKeyGlobalID *gid;
      NSString *s;
      
      gid = [self->gids objectAtIndex:j];
      
      if (!isFirst)
        [in appendString:@","];
      
      s = [[gid keyValues][0] stringValue];
      if (![s isNotEmpty]) {
        [self logWithFormat:@"weird GID for IN query: %@ ('%@')", gid, s];
        continue;
      }
      
      [in appendString:s];
      isFirst = NO;
      addCount++;
    }
    
    [in appendString:@")"];
    
    if (addCount == 0)
      [self logWithFormat:@"did not add any GID to IN query !"];
    
    q = [[EOSQLQualifier alloc] initWithEntity:entity
                                qualifierFormat:in, pkeyAttrName];
    [in release]; in = nil;
    
    /* select appointment objects */
    
    ok = [adCh selectAttributes:attrs
               describedByQualifier:q
               fetchOrder:nil
               lock:NO];
    [q release]; q = nil;
    
    [self assert:ok format:@"couldn't select objects by gid"];
    
    /* fetch appointment rows */
    
    while ((row = [adCh fetchAttributes:attrs withZone:NULL]) != nil) {
      [self processAppointmentRow:row entity:entity
	    loginIdValue:loginPid loginTeams:loginTeams
	    access:access readAccessGIDs:readAccessDates
	    writeAccessLists:writeAccessLists];
    }
  }
  
  /* check participants rights */
  [self processReadAccessDates:readAccessDates 
	loginGID:[login valueForKey:@"globalID"] loginTeams:loginTeams
	access:access writeAccessLists:writeAccessLists
	inContext:_ctx];
  
  /* set result */
  
  if (self->singleFetch)
    [self setReturnValue:[access objectForKey:[self->gids lastObject]]];
  else
    [self setReturnValueToCopyOfValue:access];
  
  [pool release];
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  id tmp;
  if (self->gids == _gids) return;
  tmp = self->gids;
  self->gids = [_gids copy];
  [tmp release];
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  NSArray *a;
  a = _gid ? [[NSArray alloc] initWithObjects:&_gid count:1] : nil;
  [self setGlobalIDs:a];
  [a release];
  self->singleFetch = YES;
}
- (EOGlobalID *)globalID {
  return [self->gids lastObject];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    return [self globalID];
  
  if ([_key isEqualToString:@"gids"])
    return [self globalIDs];

  return [super valueForKey:_key];
}

@end /* LSAptAccessCommand */
