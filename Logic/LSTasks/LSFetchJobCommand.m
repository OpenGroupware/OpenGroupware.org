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
#include "common.h"

@interface LSDBFetchRelationCommand(Private)
- (NSArray *)_ids;
@end

@implementation LSFetchJobCommand

static unsigned MaxFetchIdCount = 200;

/* accessors */

- (void)setFetchGlobalIDs:(BOOL)_fetchIds {
  self->fetchGlobalIDs = _fetchIds;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

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

/* fetching */

- (NSArray *)_fetchIds:(id)_context {
  unsigned int cnt, maxSearch;
  EOAdaptorChannel *channel;
  EOSQLQualifier   *qualifier;
  EOEntity         *entity;
  NSArray          *attributes;
  NSMutableArray   *results;
  
  maxSearch = 0; // unused?
  
  channel    = [[self databaseChannel] adaptorChannel];
  qualifier  = [self _qualifier];
  entity     = [qualifier entity];
  attributes = [entity primaryKeyAttributes];

  results    = [NSMutableArray arrayWithCapacity:512];
  
  [self assert:[channel selectAttributes:attributes
                        describedByQualifier:qualifier
                        fetchOrder:nil lock:YES]];
  
  for (cnt = 0; (maxSearch == 0) || (cnt < maxSearch); ) {
    NSDictionary *row;
    EOGlobalID   *gid;
    
    if ((row = [channel fetchAttributes:attributes withZone:NULL]) == nil)
      break;
    
    gid = [entity globalIDForRow:row];
    [results addObject:gid];
    
    cnt = [results count];
    if ((maxSearch != 0) && (cnt >= maxSearch)) {
      [[self databaseChannel] cancelFetch];
      break;
    }
  }
  return results;
}

- (EOSQLQualifier *)_checkConjoinWithQualifier:(EOSQLQualifier *)_qualifier {
  NSArray *array;
  
  array = [self _ids];
  
  // TODO: explain?!
  if ([array count] > MaxFetchIdCount) {
    [self warnWithFormat:@"%s: unexpected number of current ids (>%i) ...",
          __PRETTY_FUNCTION__, MaxFetchIdCount];
  }
  [self setCurrentIds:array];
  
  if ([[self currentIds] isNotEmpty])
    [_qualifier conjoinWithQualifier:[super _qualifier]];
  return _qualifier;
}

- (void)_executeInContext:(id)_context {
  if ([self fetchGlobalIDs])
    [self setReturnValue:[self _fetchIds:_context]];
  else
    [super _executeInContext:_context];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    [self setFetchGlobalIDs:[_value boolValue]];
    return;
  }

  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  return [super valueForKey:_key];
}

@end /* LSFetchJobCommand */
