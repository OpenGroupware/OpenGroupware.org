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
#import <LSFoundation/LSDBFetchRelationCommand.h>

@class NSCalendarDate;

@interface LSFetchToDoJobsCommand : LSDBFetchRelationCommand
{
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
}
@end

@implementation LSFetchToDoJobsCommand

// accessors

- (void)setStartDate:(NSCalendarDate *)_startDate {
  ASSIGN(self->startDate, _startDate);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_endDate {
  ASSIGN(self->endDate, _endDate);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

//

- (NSString *)entityName {
  return @"Person";
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"Job"];
}
 
- (BOOL)isToMany {
  return YES; 
}
 
- (NSString *)sourceKey {
  return @"companyId";
}

- (NSString *)destinationKey {
  return @"executantId";
}

- (NSString *)_idString {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item;

  idSet    = [NSMutableSet set];
  listEnum = [[self object] objectEnumerator];
  
  while ((item = [listEnum nextObject])) {
    id pKey = [item valueForKey:[self sourceKey]];
    
    [self assert:(pKey != nil) reason:@"found foreign key which is nil !"];

    if (pKey != nil) {
      [idSet addObject:pKey];
      { // getGroups
        NSArray *gr = [[item valueForKey:@"groups"]
                             map:@selector(valueForKey:)
                             with:@"companyId"];
        [idSet addObjectsFromArray:gr];
      }
      
    }
  }
  return [[idSet allObjects] componentsJoinedByString:@","];
  
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier = nil;
  NSString *s = [self _idString];

  if ((self->startDate != nil) && (self->endDate != nil)) {
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

    qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                               initWithEntity:[self destinationEntity]
                               qualifierFormat:
                             @"((%A <> '%@') AND ((%A <> '%@') OR "
                             @"(%A IN (%@))) AND ((%A IS NULL) OR (%A = 0)) "
                             @"AND (%A IN (%@)) AND (%A IS NULL)"
                             @"AND (((%A > %@) OR (%A = '%@')) AND (%A < %@)))",
                             @"jobStatus", LSJobArchived,
                             @"jobStatus", LSJobDone,
                             @"creatorId", s,
                             @"isControlJob", @"isControlJob",
                             @"executantId", s,
                             @"kind",
                             @"endDate",   formattedBegin,
                             @"jobStatus", LSJobCreated,
                             @"endDate",   formattedEnd, nil];
  }
  else {
    qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                               initWithEntity:[self destinationEntity]
                               qualifierFormat:
                               @"((%A <> '%@') AND ((%A <> '%@') OR "
                               @"(%A IN (%@))) AND ((%A IS NULL) OR (%A = 0)) "
                               @"AND (%A IN (%@)) AND (%A IS NULL))",
                               @"jobStatus", LSJobArchived,
                               @"jobStatus", LSJobDone,
                               @"creatorId", s,
                               @"isControlJob", @"isControlJob",
                               @"executantId", s,
                               @"kind", nil];
  }
  return AUTORELEASE(qualifier);
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"startDate"]) {
    [self setStartDate:_value];
    return;
  }
  else if ([_key isEqualToString:@"endDate"]) {
    [self setEndDate:_value];
    return;
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"startDate"])
    return [self startDate];
  if ([_key isEqualToString:@"endDate"])
    return [self endDate];
  return [super valueForKey:_key];
}

@end
