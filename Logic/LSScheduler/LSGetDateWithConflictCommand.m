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

#import "common.h"
#include <LSFoundation/LSDBObjectBaseCommand.h>

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

// accessors

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

@implementation LSGetDateWithConflictCommand

static NSNumber *nYes = nil;
static NSNumber *nNo  = nil;

+ (void)initialize {
  if (nYes == nil) nYes = [[NSNumber numberWithBool:YES] retain];
  if (nNo  == nil) nNo  = [[NSNumber numberWithBool:NO]  retain];
}

- (void)dealloc {
  RELEASE(self->begin);
  RELEASE(self->end);
  RELEASE(self->staffList);
  RELEASE(self->resourceList);
  RELEASE(self->appointment);
  [super dealloc];
}

// command methods

- (NSArray *)_staffIds {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item      = nil;

  idSet    = [NSMutableSet set];
  listEnum = [self->staffList objectEnumerator];

  while ((item = [listEnum nextObject])) {
    id pKey;

    pKey = [item valueForKey:@"companyId"];
    
    [self assert:(pKey != nil) reason:@"found foreign key which is nil !"];

    if (pKey != nil) [idSet addObject:pKey];
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

- (NSArray *)_resourceConflicts {
  id                  formattedBegin = nil;
  id                  formattedEnd   = nil;
  EOSQLQualifier      *qualifier     = nil;
  EOAdaptor           *adaptor;
  EODatabaseChannel   *channel;
  EOEntity            *myEntity;
  EOAttribute         *startDateAttr, *endDateAttr, *strAttribute;
  NSArray             *gids;
  id                  res;
  int                 resCnt;
  int                 cnt;

  adaptor       = [self databaseAdaptor];
  channel       = [self databaseChannel];
  myEntity      = [self entity];
  startDateAttr = [myEntity attributeNamed:@"startDate"];
  endDateAttr   = [myEntity attributeNamed:@"endDate"];
  strAttribute  = [myEntity attributeNamed:@"resourceNames"];
  
  formattedBegin= [adaptor formatValue:self->begin forAttribute:startDateAttr];
  formattedEnd  = [adaptor formatValue:self->end   forAttribute:endDateAttr];

  resCnt = [self->resourceList count];
  gids   = [NSArray array];

  for (cnt = 0; cnt < resCnt; cnt++) {
    id tmp1, tmp2, tmp3, tmp4;

    res = [self->resourceList objectAtIndex:cnt];
    
    tmp1 = [adaptor formatValue:res forAttribute:strAttribute];

    tmp2 = [adaptor formatValue:[NSString stringWithFormat:@"%@,%%", res]
                    forAttribute:strAttribute];

    tmp3 = [adaptor formatValue:[NSString stringWithFormat:@"%%, %@", res]
                    forAttribute:strAttribute];

    tmp4 = [adaptor formatValue:[NSString stringWithFormat:@"%%, %@,%%",
                                          res]
                    forAttribute:strAttribute]; 
    qualifier =
      [[EOSQLQualifier alloc] initWithEntity:myEntity
                              qualifierFormat:
                              @"%A > %@ AND %A < %@ AND "
                              @"(%A LIKE %@ OR  %A LIKE %@ "
                              @"OR %A LIKE %@ "
                              @"OR %A LIKE %@)"
                              @"AND (%A = 0 OR %A is null) "
                              @"AND (%A = 0 OR %A is null)",
                              @"endDate",   formattedBegin,
                              @"startDate", formattedEnd,
                              @"resourceNames", tmp1, @"resourceNames", tmp2,
                              @"resourceNames", tmp3, @"resourceNames", tmp4,
                              @"isAttendance", @"isAttendance",
                              @"isConflictDisabled", @"isConflictDisabled"];

    if (self->appointment != nil) {
      EOSQLQualifier *selfQual = nil;

      selfQual = [[EOSQLQualifier alloc] initWithEntity:myEntity
                   qualifierFormat:
                   @"%A <> %@",
                   @"dateId",
                   [self->appointment valueForKey:@"dateId"]];
      [qualifier conjoinWithQualifier:selfQual];
      RELEASE(selfQual); selfQual = nil;
    }
    [qualifier setUsesDistinct:YES];
    
    gids = [gids arrayByAddingObjectsFromArray:
                 [channel globalIDsForSQLQualifier:qualifier
                          sortOrderings:nil]];
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

- (void)_prepareForExecutionInContext:(id)_context {
  int          i, cnt;
  NSMutableSet *staffSet = nil;
  NSArray      *newStaff = nil;
  
  cnt = [self->staffList count];
  staffSet = [NSMutableSet set];
 
  for (i = 0; i < cnt; i++) {
    id staff = [self->staffList objectAtIndex:i];

    if ([[staff valueForKey:@"isTeam"] boolValue]) {
      NSArray *members = [staff valueForKey:@"members"];
      
      if (members == nil) {
        LSRunCommandV(_context, @"team", @"members", @"object", staff, nil);
        //was: [staff call:@"team::members", nil];
        members = [staff valueForKey:@"members"];
      }
      [staffSet addObject:staff];
      [staffSet addObjectsFromArray:members];
    }
    else if ([[staff valueForKey:@"isAccount"] boolValue]) {
      NSArray *groups = [staff valueForKey:@"groups"];

      if (groups == nil) {
        LSRunCommandV(_context, @"account", @"teams", @"object", staff, nil);
        //was: [staff call:@"account::teams", nil];
        groups = [staff valueForKey:@"groups"];
      }
      [staffSet addObject:staff];
      [staffSet addObjectsFromArray:groups];
    }
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
  gids       = [[NSMutableArray alloc] init];
  currentIds = [[NSMutableArray alloc] init];

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
    NSArray *sortOrderings;

    sortOrderings = [NSArray arrayWithObject:
                               [EOSortOrdering sortOrderingWithKey:@"startDate"
                                               selector:EOCompareAscending]];

    /* fetch objects */
    eos = LSRunCommandV(_context,
                        @"appointment", @"get-by-globalid",
                        @"gids",          gids,
                        @"sortOrderings", sortOrderings,
                        nil);
    [self setReturnValue:eos];
  }
  else {
    [self setReturnValue:gids];
  }
  RELEASE(gids);       gids       = nil;  
  RELEASE(currentIds); currentIds = nil;  
}

// record initializer

- (NSString *)entityName {
  return @"Date";
}

// accessors

- (void)setBeginFromString:(NSString *)_beginString {
  NSCalendarDate *myDate = nil;
  
  myDate = [NSCalendarDate dateWithString:_beginString
                           calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
  [self setBegin:myDate];
}

- (void)setBegin:(NSCalendarDate *)_begin {
  ASSIGN(self->begin, _begin);
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
  ASSIGN(self->end, _end);
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

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
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

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"begin"])
    return [self begin];
  else if ([_key isEqualToString:@"end"])
    return [self end];
  else if ([_key isEqualToString:@"appointment"])
    return [self appointment];
  else if ([_key isEqualToString:@"staffList"])
    return [self staffList];
  else if ([_key isEqualToString:@"resourceList"])
    return [self resourceList];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];

  return [super valueForKey:_key];
}

@end /* LSGetDateWithConflictCommand */
