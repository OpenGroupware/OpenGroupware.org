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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command runs queries against the Date entity and returns an
  array of EOGlobalIDs.
  
  You can qualify on a time based range and a company-gid set which is
  evaluated against the participants. When using the fromDate and toDate
  parameters, you have to ensure that these are in the correct timezone.

  Parameters:

    fromDate      - NSCalendarDate
    toDate        - NSCalendarDate
    companies     - Array of Team or Person EOGlobalIds
    resourceNames - Array of Resourcenames
    aptTypes      - Array of AptTypes to fetch
    accessTeams   - Array of Team globalIDs for the accessTeamId field
*/

@class NSCalendarDate, NSMutableSet;

@interface LSQueryAppointments : LSDBObjectBaseCommand
{
  NSCalendarDate *fromDate;
  NSCalendarDate *toDate;
  id             companies;
  id             resourceNames;
  id             aptTypes;
  id             accessTeams;
}

@end

#import <Foundation/Foundation.h>
#import <GDLAccess/GDLAccess.h>
#import <EOControl/EOControl.h>
#import <LSFoundation/LSFoundation.h>
#include <NGExtensions/NSNull+misc.h>

@implementation LSQueryAppointments

static NSNumber *nYes = nil;
static EONull   *null = nil;

+ (void)initialize {
  if (nYes == nil) nYes = [[NSNumber numberWithBool:YES] retain];
  if (null == nil) null = [[EONull null] retain];
}

- (void)dealloc {
  [self->companies     release];
  [self->fromDate      release];
  [self->toDate        release];
  [self->resourceNames release];
  [self->aptTypes      release];
  [self->accessTeams   release];
  [super dealloc];
}

/* preparation */

- (void)_prepareForExecutionInContext:(id)_context {
  /* check date range */
  if ((self->toDate != nil) && (self->fromDate != nil)) {
#if NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
    [self assert:([[self->fromDate earlierDate:self->toDate] 
		                   timeIntervalSince1970] == 
		  [self->fromDate timeIntervalSince1970])
          reason:@"invalid date range"];
#else
    [self assert:([self->fromDate earlierDate:self->toDate] == self->fromDate)
          reason:@"invalid date range"];
#endif
  }
}

/* qualifier construction */
- (NSArray *)_buildQualifierInContext:(id)_ctx
  companyQuerySet:(id)_compGids
  resourceQuerySet:(id)_resourceNames
  accessTeams:(id)_accessTeams
{
  // TODO: split up this HUGE method
  NSString        *fmtFromDate  = nil;
  NSString        *fmtToDate    = nil;
  EOAdaptor       *adaptor;
  EOEntity        *entity;
  EOAttribute     *fmtAttribute, *strAttribute;
  EOSQLQualifier  *q            = nil;
  EOSQLQualifier  *tq           = nil;
  NSMutableString *in           = nil;
  NSMutableArray  *ins          = nil;
  NSEnumerator    *enumerator   = nil;
  NSEnumerator    *ine          = nil;
  id              obj           = nil;
  NSMutableArray  *qualifiers   = nil;

  adaptor      = [self databaseAdaptor];
  entity       = [[self database] entityNamed:@"Date"];
  /* can be any date-attr */
  fmtAttribute = [entity attributeNamed:@"startDate"]; 
  strAttribute = [entity attributeNamed:@"resourceNames"];
  [self assert:(fmtAttribute != nil) reason:@"missing fmt attribute"];
  
  /* format date attributes */

  fmtFromDate = self->fromDate
    ? [adaptor formatValue:self->fromDate forAttribute:fmtAttribute]
    : nil;
  fmtToDate = self->toDate
    ? [adaptor formatValue:self->toDate forAttribute:fmtAttribute]
    : nil;

  /* create IN string for company */
  {
      unsigned i;
      const int batchSize = 200;
    
      ins        = [NSMutableArray arrayWithCapacity:16];
      in         = [NSMutableString stringWithCapacity:256];
      enumerator = [_compGids objectEnumerator];

      i = 0;
      while ((obj = [enumerator nextObject])) {
        NSString *pkey;
      
        if (i != 0) [in appendString:@","];

        pkey = [[obj keyValues][0] stringValue];
      
        [in appendString:pkey];
        i++;
      
        if (i == batchSize) {
          [ins addObject:[[in copy] autorelease]];
          [in setString:@""];
          i = 0;
        }
      }
      if ([in length] > 0) {
        [ins addObject:in];
      }
    }
  
    /* build qualifiers */
  
    qualifiers = [NSMutableArray arrayWithCapacity:[ins count]];
    if ([ins count] > 0)
      ine = [ins objectEnumerator];
    else
      ine = [[NSArray arrayWithObject:null] objectEnumerator];
    
    while ((in = [ine nextObject])) {
      if (in != (id)null) {
        if ([in length] > 0) {
          tq = [[EOSQLQualifier alloc]
                                initWithEntity:entity
                                qualifierFormat:
                                @"%A IN (%@)",
                                @"toDateCompanyAssignment.companyId", in];
          if (q == nil)
            q = tq;
          else {
            [q conjoinWithQualifier:tq];
            [tq release]; tq = nil;
          }
        }
      }
    
      /* create qualifier for resourceNames */
      enumerator = [_resourceNames objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        EOSQLQualifier *qual = nil;
        id             tmp1, tmp2, tmp3, tmp4;

        tmp1 = [adaptor formatValue:obj forAttribute:strAttribute];
	
        tmp2 = [adaptor formatValue:[NSString stringWithFormat:@"%@,%%", obj]
                        forAttribute:strAttribute];
	
        tmp3 = [adaptor formatValue:[NSString stringWithFormat:@"%%, %@", obj]
                        forAttribute:strAttribute];

        tmp4 = [adaptor formatValue:[NSString stringWithFormat:@"%%, %@,%%",
                                              obj]
                        forAttribute:strAttribute]; 
       
        
        qual = [[EOSQLQualifier alloc]
                                initWithEntity:entity
                                qualifierFormat:
                                @"((%A LIKE %@) OR (%A LIKE %@) "
                                @"OR (%A LIKE %@) OR (%A LIKE %@))",
                                @"resourceNames", tmp1, @"resourceNames", tmp2,
                                @"resourceNames", tmp3, @"resourceNames", tmp4,
                                nil];
        
        if (q == nil)
          q = qual;
        else {
          [q disjoinWithQualifier:qual];
          RELEASE(qual); qual = nil;
        }
      }
  
      if (fmtFromDate) {
        tq = [[EOSQLQualifier alloc]
                              initWithEntity:entity
                              qualifierFormat:@"%A > %@", @"endDate",
                              fmtFromDate];
        if (q == nil) {
          q = tq;
        }
        else {
          [q conjoinWithQualifier:tq];
          RELEASE(tq); tq = nil;
        }
      }
      if (fmtToDate) {
        tq = [[EOSQLQualifier alloc]
                              initWithEntity:entity
                              qualifierFormat:@"%A < %@", @"startDate",
                              fmtToDate];
        if (q == nil) q = tq;
        else {
          [q conjoinWithQualifier:tq];
          [tq release]; tq = nil;
        }
      }

      // appointment types
      if ([self->aptTypes count]) {
        EOSQLQualifier *qual     = nil;
        EOSQLQualifier *typeQual = nil;
        enumerator = [self->aptTypes objectEnumerator];
        while ((obj = [enumerator nextObject])) {
          qual = [[EOSQLQualifier alloc]
                                  initWithEntity:entity
                                  qualifierFormat:@"%A = '%@'",
                                  @"aptType", obj, nil];
        
          if (typeQual == nil) typeQual = qual;
          else {
            [typeQual disjoinWithQualifier:qual];
            RELEASE(qual);
          }
        }
        [q conjoinWithQualifier:typeQual];
        RELEASE(typeQual);
      }

      // access team ids
      if ([_accessTeams count]) {
        // array of gids
        if ([_accessTeams count] > 200) {
          NSLog(@"WARNING[%s]: more than 200 access teams per query "
                @"not supported", __PRETTY_FUNCTION__);
        }
        else {
          EOSQLQualifier *qual        = nil;
          unsigned       i            = 0;
          BOOL           fetchPrivate = NO;

          in         = [NSMutableString stringWithCapacity:256];
          enumerator = [_accessTeams objectEnumerator];
          while ((obj = [enumerator nextObject])) {
            if ([obj isNotNull]) {
              NSString *pkey;
              if (i != 0) [in appendString:@","];
                
              pkey = [[obj keyValues][0] stringValue];                
              [in appendString:pkey];
              i++;
            }
            else {
              fetchPrivate = YES;
            }
          }
	  // TODO: move qualifiers to methods
          if (fetchPrivate) {
            id accountId;
	    
            accountId = [[_ctx valueForKey:LSAccountKey]
                               valueForKey:@"companyId"];
            if (i) 
              qual = [[EOSQLQualifier alloc]
                                      initWithEntity:entity
                                      qualifierFormat:
                                      @"(%A IN (%@)) OR "
                                      @"((%A IS NULL) AND (%A = %@))",
                                      @"accessTeamId", in,
                                      @"accessTeamId",
                                      @"ownerId", accountId,
                                      nil];
            else 
              qual = [[EOSQLQualifier alloc]
                                      initWithEntity:entity
                                      qualifierFormat:
                                      @"((%A IS NULL) AND (%A = %@))",
                                      @"accessTeamId",
                                      @"ownerId", accountId,
                                      nil];
          }
          else 
            // i must be > 0
            qual = [[EOSQLQualifier alloc]
                                    initWithEntity:entity
                                    qualifierFormat:
                                    @"%A IN (%@)",
                                    @"accessTeamId", in, nil];
          if (q != nil) {
            [q conjoinWithQualifier:qual];
            [qual release];
          }
          else {
            q = qual;
          }
        }
      }
      
      [q setUsesDistinct:YES];
      if (q != nil) [qualifiers addObject:q];
      [q release]; q = nil;
    }
    return qualifiers;
}
  /* execute query */

- (void)_executeInContext:(id)_context {
  // TODO: split up this big method
  NSAutoreleasePool *pool;
  NSMutableSet      *teamGids   = nil;
  NSMutableSet      *personGids = nil;
  NSMutableSet      *queryGids  = nil;
  NSEnumerator      *e          = nil;
  EOKeyGlobalID     *gid        = nil;
  EOSQLQualifier    *q          = nil;
  NSArray           *gids       = nil;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  /* sort company gids by type */
  
  teamGids   = [NSMutableSet setWithCapacity:16];
  personGids = [NSMutableSet setWithCapacity:16];

  e = [self->companies objectEnumerator];
  while ((gid = [e nextObject])) {
    NSString *eName;
    
    eName = [gid entityName];
    
    if ([eName isEqualToString:@"Team"])
      [teamGids addObject:gid];
    else if ([eName isEqualToString:@"Person"])
      [personGids addObject:gid];
    else {
      NSLog(@"WARNING: %s ignored gid %@ (wrong type)",
            __PRETTY_FUNCTION__, gid);
    }
  }
  
  /* allocate query set */
  queryGids = [NSMutableSet setWithCapacity:200];

  /* add person gids */
  [queryGids unionSet:personGids];
  
  /* expand team gids (include members into query set) */
  if ([teamGids count] > 0) {
    id members;
    
    /* fetch members */
    members = LSRunCommandV(_context,
                            @"team", @"members",
                            @"groups",         [teamGids allObjects],
                            @"fetchGlobalIDs", nYes,
                            nil);
    /* add result to set */
    if ([teamGids count] > 1) {
      NSEnumerator *e;
      NSArray      *member;
      
      e = [members objectEnumerator];
      while ((member = [e nextObject]))
        [queryGids addObjectsFromArray:member];
    }
    else
      [queryGids addObjectsFromArray:members];
  }
  
  /* expand persons (query) gids (include teams of person into query set) */
  if ([queryGids count] > 0) {
    id teams;
    
    /* first add the persons themselves */
    [queryGids unionSet:personGids];
    
    /* fetch the teams of the persons */
    teams = LSRunCommandV(_context,
                          @"account", @"teams",
                          @"members",        [queryGids allObjects],
                          @"fetchGlobalIDs", nYes,
                          nil);
    
    /* add team-ids to set */
    if ([queryGids count] > 1) {
      NSEnumerator *e;
      NSArray      *team;
      
      e = [teams objectEnumerator];
      while ((team = [e nextObject]))
        [queryGids addObjectsFromArray:team];
    }
    else
      /* single-fetch */
      [queryGids addObjectsFromArray:teams];
  }
  
  /* add team root gids */
  [queryGids unionSet:teamGids];
  
  /* build qualifiers and fetch gids */
  {
    NSEnumerator *qs;
    NSMutableArray *mgids;
    id tmp;

    tmp = [self _buildQualifierInContext:_context
                companyQuerySet:queryGids
                resourceQuerySet:self->resourceNames
                accessTeams:self->accessTeams];
    
    qs = [tmp objectEnumerator];
    mgids = [NSMutableArray arrayWithCapacity:200];

    while ((q = [qs nextObject])) {
      /* 
	 ordering for Ids is redundant FB 1.x allows no ordering for attributes
         which are not in select list
     
         sortOrderings = [NSArray arrayWithObject:
         [EOSortOrdering sortOrderingWithKey:@"startDate"
         selector:EOCompareAscending]];
      */
      
      gids = [[self databaseChannel]
                    globalIDsForSQLQualifier:q
                    sortOrderings:nil];
      q = nil;
      [self assert:(gids != nil) reason:@"could not get date ids"];
      
      [mgids addObjectsFromArray:gids];
    }
    gids = [[mgids copy] autorelease];
  }
  
  [self setReturnValue:gids];
  
  [pool release];
}

/* key-value coding */

- (NSCalendarDate *)_parseCalendarDate:(NSString *)_value {
  return [[NSCalendarDate alloc] initWithString:_value
				 calendarFormat:@"%Y-%m-%d %H:%M %Z"];
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"fromDate"]) {
    if ([_value isKindOfClass:[NSString class]]) {
      [self->fromDate release]; self->fromDate = nil;
      self->fromDate = [self _parseCalendarDate:_value];
    }
    else {
      ASSIGN(self->fromDate, _value);
    }
    return;
  }
  if ([_key isEqualToString:@"toDate"]) {
    if ([_value isKindOfClass:[NSString class]]) {
      [self->toDate release]; self->toDate = nil;
      self->toDate = [self _parseCalendarDate:_value];
    }
    else {
      ASSIGN(self->toDate, _value);
    }
    return;
  }
  if ([_key isEqualToString:@"companies"]) {
    ASSIGN(self->companies, _value);
    return;
  }
  if ([_key isEqualToString:@"resourceNames"]) {
    ASSIGN(self->resourceNames, _value);
    return;
  }
  if ([_key isEqualToString:@"aptTypes"]) {
    ASSIGN(self->aptTypes, _value);
    return;
  }
  if ([_key isEqualToString:@"accessTeam"]) {
    NSArray *ats;
    if (_value == nil) _value = [NSNull null];
    ats = [NSArray arrayWithObject:_value];
    ASSIGN(self->accessTeams,ats);
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"fromDate"])
    v = self->fromDate;
  else if ([_key isEqualToString:@"toDate"])
    v = self->toDate;
  else if ([_key isEqualToString:@"companies"])
    v = self->companies;
  else if ([_key isEqualToString:@"resourceNames"])
    v = self->resourceNames;
  else if ([_key isEqualToString:@"aptTypes"])
    v = self->aptTypes;
  else if ([_key isEqualToString:@"accessTeams"])
    v = self->accessTeams;
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSQueryAppointments */
