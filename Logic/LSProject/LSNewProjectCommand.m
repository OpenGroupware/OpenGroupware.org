/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include <LSFoundation/LSDBObjectNewCommand.h>

/*
  project::new command
  
  Parameters:
    url
    accounts
    removedAccounts
    isFake
    ownerId
    teamId
    ...
*/

@class NSString, NSArray;

@interface LSNewProjectCommand : LSDBObjectNewCommand
{
  NSArray  *accounts;
  NSArray  *removedAccounts;
  NSString *comment;
}

@end

#include "common.h"

@implementation LSNewProjectCommand

- (void)dealloc {
  [self->accounts        release];
  [self->removedAccounts release];
  [self->comment         release];
  [super dealloc];
}

/* operations */

- (void)_checkStartDateIsBeforeEndDate {
  NSCalendarDate *startDate, *endDate;
  
  startDate = [self valueForKey:@"startDate"];
  endDate   = [self valueForKey:@"endDate"];
  
  if (![startDate isNotNull] || ![endDate isNotNull])
    return;
  
  if ([startDate compare:endDate] == NSOrderedDescending) {
    [self warnWithFormat:@"enddate before startdate, reversing!"];
    LSCommandSet(self, @"endDate",   startDate);
    LSCommandSet(self, @"startDate", endDate);
  }
}

- (void)_newProjectInfoInContext:(id)_context {
  id           project;
  NSNumber     *pkey;
  EOEntity     *infoEntity;
  id           info;
  NSDictionary *pk;

  project     = [self object];
  pkey        = [project valueForKey:[self primaryKeyName]];
  infoEntity = [[self databaseModel] entityNamed:@"ProjectInfo"];
  pk   = [self newPrimaryKeyDictForContext:_context keyName:@"projectInfoId"];
  info = [self produceEmptyEOWithPrimaryKey:pk entity:infoEntity];

  [info takeValue:[pk valueForKey:@"projectInfoId"] forKey:@"projectInfoId"];
  [info takeValue:pkey forKey:@"projectId"];
  [info takeValue:@"inserted" forKey:@"dbStatus"];  
  
  if (self->comment != nil) 
    [info takeValue:self->comment forKey:@"comment"];

  [self assert:[[self databaseChannel] insertObject:info]
        reason:[dbMessages description]];
}

- (BOOL)_newRootDocumentInContext:(id)_context {
  id           document  = nil;
  NSDictionary *pk       = nil;
  EOEntity     *myEntity;
  id           project;
  NSNumber     *pkey, *ownerPKey;

  myEntity = [[self databaseModel] entityNamed:@"Doc"];
  project   = [self object];
  pkey      = [project valueForKey:[self primaryKeyName]];
  ownerPKey = [project valueForKey:@"ownerId"];

  pk = [self newPrimaryKeyDictForContext:_context keyName:@"documentId"];

  document = [self produceEmptyEOWithPrimaryKey:pk entity:myEntity];
  
  [document takeValue:pkey forKey:@"projectId"];
  [document takeValue:[project valueForKey:@"name"] forKey:@"title"];
  [document takeValue:[project valueForKey:@"startDate"] 
            forKey:@"creationDate"];
  
  [document takeValue:ownerPKey forKey:@"firstOwnerId"];
  [document takeValue:ownerPKey forKey:@"currentOwnerId"];
  
  [document takeValue:[NSNumber numberWithBool:YES] forKey:@"isFolder"];
  [document takeValue:[NSNumber numberWithBool:NO]  forKey:@"isNote"];
  [document takeValue:@"inserted" forKey:@"dbStatus"];
  
  return [[self databaseChannel] insertObject:document];
}

- (void)_autoAssignProjectNumber {
    /* autocreate project number */
    id       obj;
    NSString *nr;
    
    obj = [self object];
    
    nr = [[obj valueForKey:[self primaryKeyName]] stringValue];
    nr = [@"P" stringByAppendingString:nr];
    [obj takeValue:nr forKey:@"number"];
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSString *n;
  
  [self _checkStartDateIsBeforeEndDate];
  [self prepareChangeTrackingFields];

  [super _prepareForExecutionInContext:_context];
  
  n = [self->recordDict valueForKey:@"number"];
  if (![n isNotNull])
    [self _autoAssignProjectNumber];
}

- (void)postProjectDidChange {
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"SkyProjectDidChangeNotification"
    object:nil];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  [self _newProjectInfoInContext:_context];
  [self assert:[self _newRootDocumentInContext:_context]
        reason:[dbMessages description]];    

  LSRunCommandV(_context, @"project",  @"assign-accounts",
                @"project",         [self object],
                @"accounts",        self->accounts,
                @"removedAccounts", self->removedAccounts, nil);
  
  [self postProjectDidChange];
}

/* initialize records */

- (NSString *)entityName {
  return @"Project";
}

/* accessors */

- (void)setAccounts:(id)_accounts {
  ASSIGN(self->accounts, _accounts);
}
- (NSArray *)accounts {
  return self->accounts;
}

- (void)setRemovedAccounts:(NSArray *)_removedAccounts {
  ASSIGN(self->removedAccounts, _removedAccounts);
}
- (NSArray *)removedAccounts {
  return self->removedAccounts;
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"accounts"])
    [self setAccounts:_value];
  else if ([_key isEqualToString:@"removedAccounts"])
    [self setRemovedAccounts:_value];
  else if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"accounts"])
    return [self accounts];
  if ([_key isEqualToString:@"removedAccounts"])
    return [self removedAccounts];
  if ([_key isEqualToString:@"comment"])
    return [self comment];

  return [super valueForKey:_key];
}

@end /* LSNewProjectCommand */
