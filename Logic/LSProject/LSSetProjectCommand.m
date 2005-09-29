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

#include <LSFoundation/LSDBObjectSetCommand.h>

@class NSArray;

@interface LSSetProjectCommand : LSDBObjectSetCommand
{
@private  
  NSArray  *accounts;
  NSArray  *removedAccounts;
  NSString *comment;
}

@end

#include "common.h"
#include <GDLAccess/EOEntity+Factory.h>

@interface NSObject(FaultCheck)
- (BOOL)isFault;
@end

@implementation LSSetProjectCommand

- (void)dealloc {
  [self->accounts        release];
  [self->removedAccounts release];
  [self->comment         release];
  [super dealloc];
}

/* operations */

- (id)produceEmptyEOWithPrimaryKey:(NSDictionary *)_pkey 
  entity:(EOEntity *)_entity 
{
  id obj;
  
  obj = [_entity produceNewObjectWithPrimaryKey:_pkey];
  [_entity setAttributesOfObjectToEONull:obj];
  
  return obj;
}

- (NSDictionary *)newPrimaryKeyDictForContext:(id)_ctx
  keyName:(NSString *)_name 
{
  id                     key   = nil;
  id<NSObject,LSCommand> nkCmd;

  nkCmd = LSLookupCommand(@"system", @"newkey");
  [nkCmd takeValue:[self entity] forKey:@"entity"];
  key = [nkCmd runInContext:_ctx];
  [self assert:(key != nil) reason:@"Could not get valid new primary key!\n"];
  return [NSDictionary dictionaryWithObject:key forKey:_name];
}

- (BOOL)_newProjectInfoInContext:(id)_context {
  id           project;
  NSNumber     *pkey;
  EOEntity     *infoEntity;
  id           info        = nil;
  NSDictionary *pk         = nil;
  
  project    = [self object];
  pkey       = [project valueForKey:[self primaryKeyName]];
  infoEntity = [[self databaseModel] entityNamed:@"ProjectInfo"];

  pk   = [self newPrimaryKeyDictForContext:_context keyName:@"projectInfoId"];
  info = [self produceEmptyEOWithPrimaryKey:pk entity:infoEntity];

  [info takeValue:[pk valueForKey:@"projectInfoId"] forKey:@"projectInfoId"];
  [info takeValue:pkey forKey:@"projectId"];
  [info takeValue:@"inserted" forKey:@"dbStatus"];  

  if (self->comment != nil) 
    [info takeValue:self->comment forKey:@"comment"];

  [self assert:[[self databaseChannel] insertObject:info]
        reason:[sybaseMessages description]];

  return YES;
}

- (BOOL)_setProjectInfoInContext:(id)_context {
  BOOL isOk;
  id   genObjInfo;
  id   obj;

  obj        = [self object];
  [self assert:(obj != nil) reason:@"no project object set for operation !"];
  
  genObjInfo = [obj valueForKey:@"toProjectInfo"];

  if ([genObjInfo isFault])
    return [self _newProjectInfoInContext:_context];

  [genObjInfo takeValue:self->comment          forKey:@"comment"];
  [genObjInfo takeValue:[self primaryKeyValue] forKey:@"projectId"];
  [genObjInfo takeValue:@"updated"             forKey:@"status"];

  isOk = [[self databaseChannel] updateObject:genObjInfo];

  return isOk;
}

- (void)_checkForHistoryProject {
  id       obj;
  NSString *pName;
  NSString *pKind;

  obj   = [self object];
  pName = [obj valueForKey:@"name"];
  pKind = [obj valueForKey:@"kind"];

  if ([pName hasPrefix:@"History - "])
    [obj takeValue:@"05_historyProject" forKey:@"kind"];
  else if (pKind != nil && [pKind isEqualToString:@"05_historyProject"])
    [obj takeValue:[EONull null] forKey:@"kind"];
}

- (void)_checkStartDateIsBeforeEndDate {
  NSCalendarDate *startDate, *endDate;
  
  startDate = [self valueForKey:@"startDate"];
  endDate   = [self valueForKey:@"endDate"];
  if ([startDate compare:endDate] == NSOrderedDescending) {
    [self takeValue:startDate forKey:@"endDate"];
    [self takeValue:endDate forKey:@"startDate"];
  }
}

- (BOOL)_updateRootDocumentInContext:(id)_context {
  id project  = [self object];
  id document = nil;
  
  LSRunCommandV(_context, @"project",  @"get-root-document",
                @"object",  project,
                @"relationKey", @"rootDocument", nil);

  document = [project valueForKey:@"rootDocument"];

  [document takeValue:[project valueForKey:@"name"] forKey:@"title"];
  [document takeValue:@"updated" forKey:@"dbStatus"];

  return [[self databaseChannel] updateObject:document];
}

- (void)_prepareForExecutionInContext:(id)_context {
   id       account;
   NSNumber *accountId;

   account   = [_context valueForKey:LSAccountKey];
   accountId = [account valueForKey:@"companyId"];

   [self _checkStartDateIsBeforeEndDate];
   [super _prepareForExecutionInContext:_context];

   [self _checkForHistoryProject];

   if ([accountId isEqual:[[self object] valueForKey:@"ownerId"]] ||
       ([accountId intValue] == 10000))
     return;
   
#if 0 // TODO: explain that!
   {
    NSArray *assignments = nil;
    int     i, cnt;

    assignments = [[self object] valueForKey:@"companyAssignments"];

    for (i = 0, cnt = [assignments count]; i < cnt; i++) {
      id       as  = nil;
      NSString *ac = nil;

      as = [assignments objectAtIndex:i];
      ac = [as valueForKey:@"accessRight"];
      if (![ac isNotNull])
        ac = nil;
      
      if ([accountId isEqual:[as valueForKey:@"companyId"]]) {
        if ([ac indexOfString:@"m"] != NSNotFound) {
          return;
        }
      }
    }
   }
   [self assert:NO reason:@"No permission to edit this project!"];     
#else
   {
     NSArray *res;
     res = LSRunCommandV(_context, @"project",  @"check-write-permission",
                         @"object", [NSArray arrayWithObject:[self object]], 
                         nil);
     [self assert:[res count] == 1
           reason:@"No permission to edit this project!"];     
   }
#endif
}

- (void)postProjectDidChange {
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"SkyProjectDidChangeNotification"
    object:nil];
}

- (void)_executeInContext:(id)_context {
  [self assert:([self object] != nil) reason:@"no project object to act on"];
  
  [super _executeInContext:_context];
  
  if (self->comment)
    [self assert:[self _setProjectInfoInContext:_context]];

  [self assert:[self _updateRootDocumentInContext:_context]
        reason:[sybaseMessages description]];
  
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
  if ([_key isEqualToString:@"accounts"]) {
    [self setAccounts:_value];
    return;
  }
  if ([_key isEqualToString:@"removedAccounts"]) {
    [self setRemovedAccounts:_value];
    return;
  }
  if ([_key isEqualToString:@"comment"]) {
    [self setComment:_value];
    return;
  }

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

@end /* LSSetProjectCommand */
