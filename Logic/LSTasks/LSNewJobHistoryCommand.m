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

#include "LSNewJobHistoryCommand.h"
#include "common.h"

@implementation LSNewJobHistoryCommand

- (void)dealloc {
  [self->comment release];
  [super dealloc];
}

/* execute */

- (BOOL)_newJobHistoryInfoInContext:(id)_context {
  id           jobHistoryInfo;
  NSDictionary *pk;
  EOEntity     *myEntity;
  NSNumber     *pkey;
  
  myEntity = [[self databaseModel] entityNamed:@"JobHistoryInfo"];
  pkey      = [[self object] valueForKey:[self primaryKeyName]];
  
  pk = [self newPrimaryKeyDictForContext:_context keyName:@"jobHistoryInfoId"];

  jobHistoryInfo = [self produceEmptyEOWithPrimaryKey:pk entity:myEntity];
  
  if ([self comment] != nil) 
    [jobHistoryInfo takeValue:[self comment] forKey:@"comment"];

  [jobHistoryInfo takeValue:pkey forKey:@"jobHistoryId"];
  [jobHistoryInfo takeValue:@"inserted" forKey:@"dbStatus"];

  return [[self databaseChannel] insertObject:jobHistoryInfo];
}

- (void)_prepareForExecutionInContext:(id)_context {
  [self takeValue:[NSNumber numberWithInt:1] forKey:@"objectVersion"];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  BOOL isOk;
  

  [super _executeInContext:_context];
  isOk = [self _newJobHistoryInfoInContext:_context];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[dbMessages description]];    
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(comment, _comment);
}
- (NSString *)comment {
  return comment;
}

/* initialize records */

- (NSString *)entityName {
  return @"JobHistory";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"comment"])
    return [self comment];

  return [super valueForKey:_key];
}

@end /* LSNewJobHistoryCommand */
