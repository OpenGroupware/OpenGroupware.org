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

#include <LSFoundation/LSDBObjectSetCommand.h>

@interface LSChangeLoginStatusCommand : LSDBObjectSetCommand
{
  BOOL loginStatus;
}

@end

#include <GDLAccess/EOEntity+Factory.h>
#import "common.h"

@implementation LSChangeLoginStatusCommand

- (id)_produceEmptyEOWithPrimaryKey:(NSDictionary *)_pkey
  entity:(EOEntity *)_entity 
{
  id obj;

  obj = [_entity produceNewObjectWithPrimaryKey:_pkey];
  [_entity setAttributesOfObjectToEONull:obj];

  return obj;
}

// create new Primary Key

- (NSDictionary *)_newPrimaryKeyDictForContext:(id)_ctx
  keyName:(NSString *)_name{
  id                     key   = nil;
  id<NSObject,LSCommand> nkCmd = LSLookupCommand(@"system", @"newkey");

  [nkCmd takeValue:[self entity] forKey:@"entity"];
  key = [nkCmd runInContext:_ctx];
  [self assert:(key != nil) reason:@"Could not get valid new primary key!\n"];
  return [NSDictionary dictionaryWithObject:key forKey:_name];
}

- (void)_newStaffInContext:(id)_context {
  BOOL         isOk         = NO;
  id           account      = [self object];
  id           pkey         = [account valueForKey:[self primaryKeyName]];
  EOEntity     *staffEntity = [[self databaseModel] entityNamed:@"Staff"];
  id           staff        = nil;
  NSDictionary *pk          = nil;


  pk    = [self _newPrimaryKeyDictForContext:_context keyName:@"staffId"];
  staff = [self _produceEmptyEOWithPrimaryKey:pk entity:staffEntity];
  
  [staff takeValue:[pk valueForKey:@"staffId"]          forKey:@"staffId"];
  [staff takeValue:pkey                                 forKey:@"companyId"];
  [staff takeValue:[account valueForKey:@"login"]       forKey:@"login"];
  [staff takeValue:[NSNumber numberWithBool:YES]        forKey:@"isAccount"];
  [staff takeValue:[NSNumber numberWithBool:NO]         forKey:@"isTeam"];
  [staff takeValue:@"inserted"                          forKey:@"dbStatus"];
  [staff takeValue:[account valueForKey:@"description"] forKey:@"description"];

  isOk = [[self databaseChannel] insertObject:staff];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
}

- (void)_setStaffInContext:(id)_context {
  id staff   = nil;
  id account = [self object];
  
  [self assert:(account != nil) reason:@"no account object for staff update"];

  if (!(staff = [[account valueForKey:@"toStaff"] lastObject])) {
    [self _newStaffInContext:_context];
  } else {
    [staff takeValue:[account valueForKey:@"login"]       forKey:@"login"];
    [staff takeValue:[account valueForKey:@"password"]    forKey:@"password"];
    [staff takeValue:[account valueForKey:@"description"]
           forKey:@"description"];
    [staff takeValue:[NSNumber numberWithBool:YES]        forKey:@"isAccount"];
    [staff takeValue:[NSNumber numberWithBool:NO]         forKey:@"isTeam"];
    [staff takeValue:@"updated"                           forKey:@"dbStatus"];

    [self assert:[[self databaseChannel] updateObject:staff]];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  id obj  = nil;
  id user = nil;
  NSString *prefix;

  obj  = [self object];
  user = [_context valueForKey:LSAccountKey];

  [self assert:([[user valueForKey:@"companyId"] intValue] == 10000)
        reason: @"Only root can change login status!"];

  prefix = [NSString stringWithFormat:@"SKY%@",
                     [obj valueForKey:@"companyId"]];

  if (self->loginStatus) {
    NSString *login = [obj valueForKey:@"login"];
    if ([login hasPrefix:prefix] && [login length] > [prefix length])
      [obj takeValue:[login substringFromIndex:[prefix length]]
           forKey:@"login"];
    [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isIntraAccount"];
    [obj takeValue:[NSNumber numberWithBool:NO]  forKey:@"isExtraAccount"];
    [obj takeValue:[NSNumber numberWithBool:NO]  forKey:@"isLocked"];
    [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isAccount"];
  }
  else {
    NSString *s = [obj valueForKey:@"login"];
    if (![s hasPrefix:prefix]) {
      s = [NSString stringWithFormat:@"%@%@", prefix, s];
      [obj takeValue:s forKey:@"login"];
    }
    [obj takeValue:[NSNumber numberWithBool:NO]  forKey:@"isIntraAccount"];
    [obj takeValue:[NSNumber numberWithBool:NO]  forKey:@"isExtraAccount"];
    [obj takeValue:[NSNumber numberWithBool:NO]  forKey:@"isAccount"];
    [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isLocked"];
  }

  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {

  [super _executeInContext:_context];
  [self _setStaffInContext:_context];

  if (!self->loginStatus) {
    LSRunCommandV(_context, @"account", @"setgroups",
                  @"member", [self object],
                  @"groups", [NSArray array], nil);
  }
 }
// record initializer

- (NSString *)entityName {
  return @"Person";
}

// accessors

- (void)setLoginStatus:(BOOL)_status {
  self->loginStatus = _status;
}

- (BOOL)loginStatus {
  return self->loginStatus;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"loginStatus"]) {
    [self setLoginStatus:[_value boolValue]];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"loginStatus"]) {
    return [NSNumber numberWithBool:[self loginStatus]];
  }
  return [super valueForKey:_key];
}

@end
