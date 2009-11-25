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
  NSString       *idString;
}

@end

#include "common.h"

@implementation LSFetchToDoJobsCommand

- (void)dealloc {
  [self->startDate release];
  [self->endDate   release];
  [self->accountId release];
  [self->idString  release];
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

- (void)setIdString:(NSString *)_idString {
  ASSIGNCOPY(self->idString, _idString);
}
- (NSString *)idString {
  return self->idString;
}

/* operation */

- (NSString *)_buildIdString:(id)_context {
  NSArray         *teams;
  NSEnumerator    *enumerator;
  NSMutableArray  *idSet;
  id              tmp;

  idSet = [NSMutableArray arrayWithCapacity:64];
  [idSet addObject:[self accountId]];
  teams = [_context runCommand:@"companyassignment::get",
                               @"subCompanyId", [self accountId],
                               @"returnType", intObj(LSDBReturnType_ManyObjects),
                               nil];
  enumerator = [teams objectEnumerator];
  while ((tmp = [enumerator nextObject]) != nil) {
    [idSet addObject:[tmp valueForKey:@"companyId"]];
  }
  return [idSet componentsJoinedByString:@","];
}

- (void)_prepareForExecutionInContext:(id)_context {
  [self setAccountId:[[_context valueForKey:LSAccountKey] valueForKey:@"companyId"]];
  [self setIdString:[self _buildIdString:_context]];
  [super _prepareForExecutionInContext:_context];
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier;
  
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
                                 @"ownerId", [self accountId],
                                 @"executantId", [self idString],
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
                              @"ownerId", [self accountId],
                              @"executantId", [self idString],
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
