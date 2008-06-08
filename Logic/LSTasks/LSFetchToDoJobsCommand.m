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

#include "LSFetchJobCommand.h"

@class NSCalendarDate;

@interface LSFetchToDoJobsCommand : LSFetchJobCommand
{
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSString       *accountId;
}

@end

#include "common.h"

@implementation LSFetchToDoJobsCommand

- (void)dealloc {
  [self->startDate release];
  [self->endDate   release];
  [self->accountId release];
  [super dealloc];
}

/* accessors */

- (void)setStartDate:(NSCalendarDate *)_startDate {
  ASSIGNCOPY(self->startDate, _startDate);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_endDate {
  ASSIGNCOPY(self->endDate, _endDate);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setAccountId:(NSString *)_accountId {
  ASSIGNCOPY(self->accountId, _accountId);
}
- (NSString *)accountId {
  return self->accountId;
}

- (NSString *)destinationKey {
  return @"executantId";
}

/* operation */

- (NSString *)_idString {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item;
  
  // Note: the 'object' is an array, this is done in LSDBFetchRelationCommand
  idSet    = [NSMutableSet setWithCapacity:16];
  listEnum = [[self object] objectEnumerator];
  
  while ((item = [listEnum nextObject]) != nil) {
    NSNumber *pKey;
    NSArray  *gr;

    pKey = [item valueForKey:[self sourceKey]];
    [self assert:(pKey != nil) reason:@"found foreign key which is nil !"];
    
    if (![pKey isNotNull])
      continue;
    
    [idSet addObject:pKey];

    // getGroups
    gr = [[item valueForKey:@"groups"]
	        map:@selector(valueForKey:)
                with:@"companyId"];
    [idSet addObjectsFromArray:gr];
  }
  return [[idSet allObjects] componentsJoinedByString:@","];
  
}

- (void)_prepareForExecutionInContext:(id)_context {
  [self setAccountId:[[_context valueForKey:LSAccountKey] valueForKey:@"companyId"]];
  [super _prepareForExecutionInContext:_context];
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier;
  NSString *s;
  
  s = [self _idString];
  
  qualifier = [EOSQLQualifier alloc];
  if ([self->startDate isNotNull] && [self->endDate isNotNull]) {
    id             formattedBegin = nil;
    id             formattedEnd   = nil;
    EOAdaptor      *adaptor       = [self databaseAdaptor];
    EOEntity       *myEntity      = [self destinationEntity];
    EOAttribute    *startDateAttr = [myEntity attributeNamed:@"startDate"];
    EOAttribute    *endDateAttr   = [myEntity attributeNamed:@"endDate"];

    formattedBegin = [adaptor formatValue:self->startDate
                              forAttribute:startDateAttr];
    formattedEnd   = [adaptor formatValue:self->endDate
                              forAttribute:endDateAttr];

    qualifier = [qualifier initWithEntity:[self destinationEntity]
			   qualifierFormat:
                                 @"((%A <> '%@') AND ((%A <> '%@') OR "
                                 @"(%A = %@)) AND "
                                 @"(%A IN (%@)) AND "
                                 @"(((%A > %@) OR (%A = '%@')) AND "
                                 @"(%A < %@)))",
                                 @"jobStatus", LSJobArchived,
                                 @"jobStatus", LSJobDone,
                                 @"creatorId", [self accountId],
                                 @"executantId", s,
                                 @"endDate",   formattedBegin,
                                 @"jobStatus", LSJobCreated,
                                 @"endDate",   formattedEnd, nil];
  } else {
      qualifier = [qualifier initWithEntity:[self destinationEntity]
                            qualifierFormat:
                              @"((%A <> '%@') AND "
                              @" ((%A <> '%@') OR(%A = %@)) AND "
                              @" (%A IN (%@)))",
                              @"jobStatus", LSJobArchived,
                              @"jobStatus", LSJobDone,
                              @"creatorId", [self accountId],
                              @"executantId", s,
                              nil];
     }
  return [qualifier autorelease];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"startDate"]) {
    [self setStartDate:_value];
    return;
  }
  if ([_key isEqualToString:@"endDate"]) {
    [self setEndDate:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"startDate"])
    return [self startDate];
  if ([_key isEqualToString:@"endDate"])
    return [self endDate];
  
  return [super valueForKey:_key];
}

@end /* LSFetchToDoJobsCommand */
