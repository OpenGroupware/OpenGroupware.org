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
#import "LSNewJobHistoryCommand.h"

@implementation LSNewJobHistoryCommand

- (void)dealloc {
  [self->comment release];

  [super dealloc];
}

- (BOOL)_newJobHistoryInfoInContext:(id)_context {
  id           jobHistoryInfo = nil;
  NSDictionary *pk            = nil;
  EOEntity     *myEntity = [[self databaseModel] entityNamed:@"JobHistoryInfo"];
  id           pkey      = [[self object] valueForKey:[self primaryKeyName]];

  pk = [self newPrimaryKeyDictForContext:_context keyName:@"jobHistoryInfoId"];

  jobHistoryInfo = [self produceEmptyEOWithPrimaryKey:pk entity:myEntity];
  
  if ([self comment]) 
    [jobHistoryInfo takeValue:[self comment] forKey:@"comment"];

  [jobHistoryInfo takeValue:pkey forKey:@"jobHistoryId"];
  [jobHistoryInfo takeValue:@"inserted" forKey:@"dbStatus"];

  return [[self databaseChannel] insertObject:jobHistoryInfo];
}

- (void)_executeInContext:(id)_context {
  BOOL isOk = NO;

  [super _executeInContext:_context];
  isOk = [self _newJobHistoryInfoInContext:_context];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];    
}

- (void)setComment:(NSString *)_comment {
  ASSIGN(comment, _comment);
}
- (NSString *)comment {
  return comment;
}

// initialize records

- (NSString *)entityName {
  return @"JobHistory";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"comment"])
    return [self comment];
  else
    return [super valueForKey:_key];
}

@end
