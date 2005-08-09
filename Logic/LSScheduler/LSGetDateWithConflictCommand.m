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
  appointment::conflicts
  
  This command fetches the appointments conflicting for a certain set of
  people/teams/resources in a certain timeframe.
  It can also fetch the "pending" conflicts for a specific appointment.
  
  The result of the fetch is either a set of appointments, either just the
  EOGlobalID's or the full EOs (as fetched by appointment::get-by-globalid).
  
  Used in:
    ./DocumentAPI/OGoScheduler/SkySchedulerConflictDataSource.m
    ./Recycler/SandStorm/skyaptd/SkyAptAction+Conflicts.m
*/

@class NSArray, NSCalendarDate;

@interface LSGetDateWithConflictCommand : LSDBObjectBaseCommand
{
@private
  NSArray        *staffList;
  NSArray        *resourceList;
  id             appointment;
  NSCalendarDate *begin;
  NSCalendarDate *end;
  BOOL           fetchGlobalIDs;
}

/* accessors */

- (void)setBegin:(NSCalendarDate *)_begin;
- (NSCalendarDate *)begin;
- (void)setEnd:(NSCalendarDate *)_end;
- (NSCalendarDate *)end;
- (void)setStaffList:(NSArray *)_staffList;
- (NSArray *)staffList;
- (void)setResourceList:(NSArray *)_resourceList;
- (NSArray *)resourceList;
- (BOOL)fetchGlobalIDs;

@end

#include "common.h"

@implementation LSGetDateWithConflictCommand

static NSNumber *nYes = nil;
static NSNumber *nNo  = nil;
static NSArray *startDateSortOrderings = nil;

+ (void)initialize {
  if (nYes == nil) nYes = [[NSNumber numberWithBool:YES] retain];
  if (nNo  == nil) nNo  = [[NSNumber numberWithBool:NO]  retain];

  if (startDateSortOrderings == nil) {
    startDateSortOrderings = [[NSArray alloc] initWithObjects:
                               [EOSortOrdering sortOrderingWithKey:@"startDate"
                                               selector:EOCompareAscending],
                              nil];
  }
}

- (void)dealloc {
  [self->begin        release];
  [self->end          release];
  [self->staffList    release];
  [self->resourceList release];
  [self->appointment  release];
  [super dealloc];
}

/* command methods */

- (NSNumber *)pkeyFromCompanyObject:(id)item {
  if ([item isKindOfClass:[EOKeyGlobalID class]])
    return [(EOKeyGlobalID *)item keyValues][0];
  if ([item isKindOfClass:[NSNumber class]])
    return item;
  if ([item isNotNull])
    return [item valueForKey:@"companyId"];
  return nil;
}

- (NSNumber *)pkeyFromAptObject:(id)item {
  if ([item isKindOfClass:[EOKeyGlobalID class]])
    return [(EOKeyGlobalID *)item keyValues][0];
  if ([item isKindOfClass:[NSNumber class]])
    return item;
  if ([item isNotNull])
    return [item valueForKey:@"dateId"];
  return nil;
}

- (NSArray *)_staffIds {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item      = nil;

  idSet    = [NSMutableSet setWithCapacity:16];
  listEnum = [self->staffList objectEnumerator];
  
  while ((item = [listEnum nextObject]) != nil) {
    NSNumber *pKey;
    
    if ([(pKey = [self pkeyFromCompanyObject:item]) isNotNull])
      [idSet addObject:pKey];
    else
      [self logWithFormat:@"ERROR: got a staff-id which is nil!: %@", item];
  }
  return [idSet allObjects];
}

- (BOOL)_hasResourceConflictFor:(id)_appmt {
  NSArray  *res;
  NSArray  *cRes = nil;
  NSString *rN   = nil;
  int      i, j, cnt, cnt2;
  
  res  = self->resourceList;
  rN = [_appmt valueForKey:@"resourceNames"];

  if (rN == nil)
    return NO;

  cRes = [rN componentsSeparatedByString:@", "];

  cnt  = [res count];
  cnt2 = [cRes count];
  
  for  (i = 0; i < cnt; i++) {
    for (j = 0; j < cnt2; j++) {
      if ([[res objectAtIndex:i] isEqualToString:[cRes objectAtIndex:j]])
        return YES;
    }
  }
  return NO;
}

- (EOSQLQualifier *)sqlQualifierToCheckResourceName:(NSString *)res
  formattedStartDate:(NSString *)_from formattedEndDate:(NSString *)_to
  adaptor:(EOAdaptor *)adaptor
{
  static EOAttribute *strAttribute = nil; // THREAD
  EOSQLQualifier *qualifier;
  NSString *s;
  NSString *tmp1, *tmp2, *tmp3, *tmp4;
  
  if (strAttribute == nil) {
    /* Note: we can do this because we use just one model */
    strAttribute = [[[self entity] attributeNamed:@"resourceNames"] copy];
  }
  
  tmp1 = [adaptor formatValue:res forAttribute:strAttribute];
  s    = [res stringByAppendingString:@",%"];
  tmp2 = [adaptor formatValue:s forAttribute:strAttribute];
  s    = [@"%, " stringByAppendingString:res];
  tmp3 = [adaptor formatValue:s forAttribute:strAttribute];
  s    = [s stringByAppendingString:@",%"];
  tmp4 = [adaptor formatValue:s forAttribute:strAttribute]; 
  
  qualifier =
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:
                              @"%A > %@ AND %A < %@ AND "
                              @"(%A LIKE %@ OR  %A LIKE %@ "
                              @"OR (%A LIKE %@)"
                              @"OR (%A LIKE %@))"
                              @"AND (%A = 0 OR %A IS NULL) "
                              @"AND (%A = 0 OR %A IS NULL)",
                              /* Note: end start/end reverse is intentional! */
                              @"endDate",   _from,
                              @"startDate", _to,
                              @"resourceNames", tmp1, @"resourceNames", tmp2,
                              @"resourceNames", tmp3, @"resourceNames", tmp4,
                              @"isAttendance", @"isAttendance",
                              @"isConflictDisabled", @"isConflictDisabled"];
  return qualifier;
}

- (NSArray *)_resourceConflicts {
  static EOAttribute *startDateAttr = nil, *endDateAttr = nil; // THREAD
  NSString          *formattedBegin = nil;
  NSString          *formattedEnd   = nil;
  EOAdaptor         *adaptor;
  EODatabaseChannel *channel;
  NSArray           *gids;
  int               resCnt;
  int               cnt;
  
  if (startDateAttr == nil) {
    startDateAttr = [[[self entity] attributeNamed:@"startDate"] retain];
    endDateAttr   = [[[self entity] attributeNamed:@"endDate"] retain];
  }
  
  adaptor = [self databaseAdaptor];
  channel = [self databaseChannel];
  
  formattedBegin= [adaptor formatValue:self->begin forAttribute:startDateAttr];
  formattedEnd  = [adaptor formatValue:self->end   forAttribute:endDateAttr];

  resCnt = [self->resourceList count];
  gids   = [NSArray array];

  for (cnt = 0; cnt < resCnt; cnt++) {
    EOSQLQualifier *qualifier;
    NSArray  *tgids;
    NSString *res;

    res = [self->resourceList objectAtIndex:cnt];
    
    qualifier = [self sqlQualifierToCheckResourceName:res
                      formattedStartDate:formattedBegin
                      formattedEndDate:formattedEnd
                      adaptor:adaptor];
    
    if ([self->appointment isNotNull]) {
      EOSQLQualifier *selfQual = nil;
      
      selfQual = [[EOSQLQualifier alloc] 
                   initWithEntity:[self entity]
                   qualifierFormat:@"%A <> %@",
                   @"dateId", [self pkeyFromAptObject:self->appointment]];
      [qualifier conjoinWithQualifier:selfQual];
      [selfQual release]; selfQual = nil;
    }
    [qualifier setUsesDistinct:YES];
    
    tgids = [channel globalIDsForSQLQualifier:qualifier
                     sortOrderings:nil];

    [qualifier release]; qualifier = nil;
    
    if ([tgids count] > 0)
      gids = [gids arrayByAddingObjectsFromArray:tgids];
  }

  return gids;
}

- (EOSQLQualifier *)_qualifier:(NSArray *)_ids {
  id             formattedBegin = nil;
  id             formattedEnd   = nil;
  EOSQLQualifier *qualifier     = nil;
  EOAdaptor      *adaptor;
  EOEntity       *myEntity;
  EOAttribute    *startDateAttr;
  EOAttribute    *endDateAttr;
  
  adaptor       = [self databaseAdaptor];
  myEntity      = [self entity];
  startDateAttr = [myEntity attributeNamed:@"startDate"];
  endDateAttr   = [myEntity attributeNamed:@"endDate"];

  formattedBegin =
    [adaptor formatValue:self->begin forAttribute:startDateAttr];
  formattedEnd   =
    [adaptor formatValue:self->end   forAttribute:endDateAttr];
  
  if ([self->staffList count] > 0) { // TODO: should be "[in length] > 0"?
    NSString *in;
    
    in = [self joinPrimaryKeysFromArrayForIN:_ids];
    qualifier = [[EOSQLQualifier alloc] initWithEntity:myEntity
                                        qualifierFormat:
                                        @"(%A > %@) AND (%A < %@) "
                                        @"AND (%A = 0 OR %A IS NULL) "
                                        @"AND (%A = 0 OR %A IS NULL) "
                                        @"AND (%A IN (%@))",
                                        @"endDate",   formattedBegin,
                                        @"startDate", formattedEnd,
                                        @"isAttendance",
                                        @"isAttendance",
                                        @"isConflictDisabled",
                                        @"isConflictDisabled",
                                        @"toDateCompanyAssignment.companyId",
                                        in];
  }
  else {
    qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:myEntity
                                 qualifierFormat:
                                 @"(%A > %@) AND (%A < %@) "
                                 @"AND (%A=0 OR %A IS NULL) "
                                 @"AND (%A=0 OR %A IS NULL) ",
                                 @"endDate",   formattedBegin,
                                 @"startDate", formattedEnd,
                                 @"isAttendance",
                                 @"isAttendance",
                                 @"isConflictDisabled",
                                 @"isConflictDisabled"];
  }
  if (self->appointment != nil) {
    EOSQLQualifier *selfQual = nil;
    
    selfQual = [[EOSQLQualifier alloc] initWithEntity:myEntity
                 qualifierFormat:
                 @"%A <> %@",
                 @"dateId",                      
                 [self->appointment valueForKey:@"dateId"]];
    [qualifier conjoinWithQualifier:selfQual];
    [selfQual release]; selfQual = nil;
  }
  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];
}

- (void)_addMembersOfTeam:(id)staff toStaffSet:(NSMutableSet *)staffSet
  inContext:(LSCommandContext *)_ctx
{
  NSArray *members;

  if ([staff isKindOfClass:[EOGlobalID class]]) {
    [self errorWithFormat:@"%s: cannot process EOGlobalIDs yet: %@",
          __PRETTY_FUNCTION__, staff];
    return;
  }
  
  if ((members = [staff valueForKey:@"members"]) == nil) {
    LSRunCommandV(_ctx, @"team", @"members", @"object", staff, nil);
    //was: [staff call:@"team::members", nil];
    members = [staff valueForKey:@"members"];
  }
  [staffSet addObjectsFromArray:members];
}

- (void)_addTeamsOfAccount:(id)staff toStaffSet:(NSMutableSet *)staffSet
  inContext:(LSCommandContext *)_ctx
{
  NSArray *groups;
      
  if ((groups = [staff valueForKey:@"groups"]) == nil) {
    LSRunCommandV(_ctx, @"account", @"teams", @"object", staff, nil);
    //was: [staff call:@"account::teams", nil];
    groups = [staff valueForKey:@"groups"];
  }
  [staffSet addObjectsFromArray:groups];
}

- (BOOL)isTeamStaffObject:(id)_object {
  if (![_object isNotNull])
    return NO;

  if ([_object isKindOfClass:[EOGlobalID class]])
    return [[_object entityName] isEqualToString:@"Team"];
  
  return [[_object valueForKey:@"isTeam"] boolValue];
}

- (BOOL)isAccountStaffObject:(id)_object {
  if (![_object isNotNull])
    return NO;

  if ([_object isKindOfClass:[EOGlobalID class]]) {
    if (![[_object entityName] isEqualToString:@"Person"])
      return NO;
    
    // TODO: fetch isAccount flag to check whether the GID is an account
  }
  
  return [[_object valueForKey:@"isAccount"] boolValue];
}

- (void)_prepareForExecutionInContext:(id)_context {
  int          i, cnt;
  NSMutableSet *staffSet = nil;
  NSArray      *newStaff = nil;
  
  cnt      = [self->staffList count];
  staffSet = [NSMutableSet setWithCapacity:cnt];
  
  for (i = 0; i < cnt; i++) {
    id staff;
    
    staff = [self->staffList objectAtIndex:i];
    
    [staffSet addObject:staff];
    
    /*
      If you check whether a team is 'available', you need to know whether
      all of the members are available.
      
      If you check whether an account is 'available', you need to know whether
      any of the teams the account is in are booked.
    */
    if ([self isTeamStaffObject:staff])
      [self _addMembersOfTeam:staff toStaffSet:staffSet inContext:_context];
    else if ([self isAccountStaffObject:staff])
      [self _addTeamsOfAccount:staff toStaffSet:staffSet inContext:_context];
  }
  
  newStaff = [staffSet allObjects];
  ASSIGN(self->staffList, newStaff);
}

- (void)_executeInContext:(id)_context {
  NSMutableArray    *gids;
  NSMutableArray    *currentIds;
  EODatabaseChannel *channel;
  NSArray           *idTmp;
  NSArray           *gidsTmp;
  int cnt    = 0;
  int cntIds = 0;
  int max    = 0;
  
  channel    = [self databaseChannel];
  gids       = [[NSMutableArray alloc] initWithCapacity:16];
  currentIds = [[NSMutableArray alloc] initWithCapacity:16];
  
  [currentIds addObjectsFromArray:[self _staffIds]];

  max    = 240;
  cntIds = [currentIds count];

  while (cntIds > 0) {
    if (cntIds > max) {
      idTmp = [currentIds subarrayWithRange:NSMakeRange(cnt, max)];
      cntIds = cntIds - max;
      cnt   += 240;
    }
    else {
      idTmp  = [currentIds subarrayWithRange:NSMakeRange(cnt , cntIds)];
      cntIds = 0;
    }

    gidsTmp = [channel globalIDsForSQLQualifier:[self _qualifier:idTmp]
                       sortOrderings:nil];

    if (gidsTmp == nil)
      [self assert:NO reason:[sybaseMessages description]];

    [gids addObjectsFromArray:gidsTmp];
  }
  
  if (self->resourceList != nil) {
    if (![self->resourceList isNotNull]) {
#if DEBUG
      [self debugWithFormat:@"WARNING: self->resourceList is NSNull .."];
#endif
      ;
    }
    else {
      if ([self->resourceList count] > 0)
        [gids addObjectsFromArray:[self _resourceConflicts]];
    }
  }
  
  if (!self->fetchGlobalIDs) {
    NSArray *eos;
    
    /* fetch objects */
    eos = LSRunCommandV(_context,
                        @"appointment", @"get-by-globalid",
                        @"gids",          gids,
                        @"sortOrderings", startDateSortOrderings,
                        nil);
    [self setReturnValue:eos];
  }
  else {
    [self setReturnValue:gids];
  }
  [gids       release]; gids       = nil;  
  [currentIds release]; currentIds = nil;  
}


/* record initializer */

- (NSString *)entityName {
  return @"Date";
}


/* accessors */

- (void)setBeginFromString:(NSString *)_beginString {
  NSCalendarDate *myDate = nil;
  
  myDate = [NSCalendarDate dateWithString:_beginString
                           calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  [self setBegin:myDate];
}

- (void)setBegin:(NSCalendarDate *)_begin {
  ASSIGNCOPY(self->begin, _begin);
}
- (NSCalendarDate *)begin {
  return self->begin;
}

- (void)setEndFromString:(NSString *)_endString {
  NSCalendarDate *myDate = nil;
  
  myDate = [NSCalendarDate dateWithString:_endString
                           calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  [self setEnd:myDate];
}

- (void)setEnd:(NSCalendarDate *)_end {
  ASSIGNCOPY(self->end, _end);
}
- (NSCalendarDate *)end {
  return self->end;
}

- (void)setStaffList:(NSArray *)_staffList {
  ASSIGN(self->staffList, _staffList);
}
- (NSArray *)staffList {
  return self->staffList ;
}

- (void)setAppointment:(id)_apt {
  ASSIGN(self->appointment, _apt);
}
- (id)appointment {
  return self->appointment ;
}

- (void)setResourceList:(NSArray *)_resourceList {
  if (![_resourceList isNotNull]) {
    //[self logWithFormat:@"ERROR: resourcelist is null !"];
    _resourceList = nil;
  }
  
  ASSIGN(self->resourceList, _resourceList);
}
- (NSArray *)resourceList {
  return self->resourceList ;
}

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"begin"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [self setBegin:_value];
    else
      [self setBeginFromString:[_value stringValue]];      
  }
  else if ([_key isEqualToString:@"end"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [self setEnd:_value];
    else
      [self setEndFromString:[_value stringValue]];
  }
  else if ([_key isEqualToString:@"appointment"]) 
    [self setAppointment:_value];
  else if ([_key isEqualToString:@"staffList"])
    [self setStaffList:_value];
  else if ([_key isEqualToString:@"resourceList"])
    [self setResourceList:_value];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    [self setFetchGlobalIDs:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"begin"])
    return [self begin];
  if ([_key isEqualToString:@"end"])
    return [self end];
  if ([_key isEqualToString:@"appointment"])
    return [self appointment];
  if ([_key isEqualToString:@"staffList"])
    return [self staffList];
  if ([_key isEqualToString:@"resourceList"])
    return [self resourceList];
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];

  return [super valueForKey:_key];
}

@end /* LSGetDateWithConflictCommand */
