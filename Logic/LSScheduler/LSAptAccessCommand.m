/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  takes either a single global-id or multiple gids and returns either
  a single string containing the permissions or a dictionary where the
  key is the gid and the value is the permission-string.
*/

@interface LSAptAccessCommand : LSDBObjectBaseCommand
{
  NSArray *gids;
  BOOL    singleFetch;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSFoundation.h>
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>

@implementation LSAptAccessCommand

- (NSString *)entityName {
  return @"Date";
}

- (void)dealloc {
  [self->gids release];
  [super dealloc];
}

/* execution */

- (void)_executeInContext:(id)_context {
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
  static NSString *right_deluv = @"deluv";
  static NSString *right_luv   = @"luv";
  static NSString *right_lv    = @"lv";
  static NSString *right_l     = @"l";
  static EONull   *null  = nil;
  
  if (null == nil)
    null = [[EONull null] retain];
  
  if ((gidCount = [self->gids count]) == 0) {
    [self setReturnValue:nil];
    return;
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  
  login    = [_context valueForKey:LSAccountKey];
  loginPid = [[login valueForKey:@"companyId"] intValue];

  if (loginPid == 10000) {
    if (self->singleFetch) {
      [self setReturnValue:right_deluv];
    }
    else {
      NSEnumerator *e;
      EOGlobalID *gid;
      
      access = [NSMutableDictionary dictionaryWithCapacity:gidCount];
      
      e = [self->gids objectEnumerator];
      while ((gid = [e nextObject])) {
        [access setObject:right_deluv forKey:gid];
      }
      
      [self setReturnValue:AUTORELEASE([access copy])];
    }
    RELEASE(pool);
    return;
  }
  
  loginTeams = LSRunCommandV(_context,
                             @"account", @"teams",
                             @"object", [login valueForKey:@"globalID"],
                             @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                             nil);
  
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
  
  adCh = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel];
  [self assert:(adCh != nil) reason:@"missing adaptor channel"];
  
  batchSize = gidCount > 200 ? 200 : gidCount;

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
      if ([s length] == 0) {
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
    RELEASE(in); in = nil;
    
    /* select appointment objects */
    
    ok = [adCh selectAttributes:attrs
               describedByQualifier:q
               fetchOrder:nil
               lock:NO];
    RELEASE(q); q = nil;
    
    [self assert:ok format:@"couldn't select objects by gid"];
    
    /* fetch appointment rows */
    
    while ((row = [adCh fetchAttributes:attrs withZone:NULL])) {
      EOGlobalID *gid;
      id ownerId;
      
      gid = [entity globalIDForRow:row];

      ownerId = [row objectForKey:@"ownerId"];
      
      if ([ownerId intValue] == loginPid) {
        /* account is owner */
        [access setObject:right_deluv forKey:gid];
        continue;
      }
      else {
        /* account is not the owner */
        EOGlobalID *accessTeamGid;
        id accessTeamId;
        BOOL isPrivate;
        BOOL hasReadAccess;
        
        isPrivate     = NO;
        hasReadAccess = NO;
        
        accessTeamId = [row objectForKey:@"accessTeamId"];
        if ((accessTeamId == nil) || (accessTeamId == null)) {
          accessTeamGid = nil;
          isPrivate = YES;
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
          id   l              = nil;
          BOOL hasWriteAccess = NO;

          l = [row valueForKey:@"writeAccessList"];

          if (l != null) {
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

            if (l != null && l != nil)
              [writeAccessLists setObject:l forKey:gid];
          }
        }
      }
    }
  }
  
  /* check participants rights */

  if ([readAccessDates count] > 0) {
    NSDictionary        *ps;
    NSEnumerator        *agids;
    EOGlobalID          *gid, *loginGid;
    NSMutableDictionary *teamToPs; /* cache team members */
    
    loginGid = [login valueForKey:@"globalID"];
    
    ps = LSRunCommandV(_context, @"appointment", @"get-participants",
                       @"dates", readAccessDates,
                       @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                       nil);
    
    teamToPs  = nil;
    agids = [readAccessDates objectEnumerator];
    while ((gid = [agids nextObject])) {
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
              id tmp;
              tmp = LSRunCommandV(_context, @"team", @"members",
                                  @"team", pgid,
                                  @"fetchGlobalIDs",
                                  [NSNumber numberWithBool:YES],
                                  nil);
              if (tmp) {
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
        id   l              = nil;

        l = [writeAccessLists objectForKey:gid];

        if (l != null) {
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

            wAccessTeamGid = [EOKeyGlobalID globalIDWithEntityName:@"Team"
                                            keys:&staffPid keyCount:1
                                            zone:NULL];
            wAccessPartGid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                                            keys:&staffPid keyCount:1
                                            zone:NULL];

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
        if (hasWriteAccess) {
          [access setObject:right_deluv forKey:gid];
        }
      }
    }
  }
  
  /* set result */
  
  if (self->singleFetch)
    [self setReturnValue:[access objectForKey:[self->gids lastObject]]];
  else
    [self setReturnValue:AUTORELEASE([access copy])];
  
  RELEASE(pool);
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

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSAptAccessCommand */
