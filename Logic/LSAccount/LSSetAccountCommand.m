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

#include <LSSetCompanyCommand.h>

@class NSArray, NSData, NSString;

@interface LSSetAccountCommand : LSSetCompanyCommand
{
@protected
  NSArray  *teams;
  NSData   *data;
  NSData   *filter;  
  NSString *filePath;
}

@end

#import "common.h"

@implementation LSSetAccountCommand

- (void)dealloc {
  [self->teams release];
  [self->data release];
  [self->filter release];
  [self->filePath release];
  [super dealloc];
}

- (void)_setStaffInContext:(id)_context {
  id staff   = nil;
  id account = [self object];
  
  [self assert:(account != nil) reason:@"no account object for staff update"];

  staff = [[account valueForKey:@"toStaff"] lastObject];

  [self assert:(staff != nil) reason:@"no staff object for account update"];
  
  [staff takeValue:[account valueForKey:@"login"]       forKey:@"login"];
  [staff takeValue:[account valueForKey:@"password"]    forKey:@"password"];
  [staff takeValue:[account valueForKey:@"description"] forKey:@"description"];
  [staff takeValue:[NSNumber numberWithBool:YES]        forKey:@"isAccount"];
  [staff takeValue:[NSNumber numberWithBool:NO]         forKey:@"isTeam"];
  [staff takeValue:@"updated"                           forKey:@"dbStatus"];

  [self assert:(staff != nil) reason:@"no staff object to update !"];
  [self assert:[[self databaseChannel] updateObject:staff]];
}

#if 0 // debugging code
- (void)setObject:(id)_object {
  NSLog(@"set object to %@", _object);
  [super setObject:_object];
}
- (void)setReturnValue:(id)_object {
  NSLog(@"set return value to %@", _object);
  [super setReturnValue:_object];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  id obj            = [self object];
  id isExtraAccount = [obj valueForKey:@"isExtraAccount"];
  id account        = [_context valueForKey:LSAccountKey];

  [self assert:([[account valueForKey:@"companyId"] intValue] == 10000)
        reason:@"Only root can change accounts"];

  if ([isExtraAccount boolValue]) {
    [obj takeValue:[NSNumber numberWithBool:NO] forKey:@"isIntraAccount"];
    [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isExtraAccount"];    
  }
  else {
    [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isIntraAccount"];
    [obj takeValue:[NSNumber numberWithBool:NO] forKey:@"isExtraAccount"];
  }
  [super _prepareForExecutionInContext:_context];
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"LSUseLowercaseLogin"]) 
    [obj takeValue:[[obj valueForKey:@"login"] lowercaseString]
         forKey:@"login"];

  LSRunCommandV(_context, @"sessionlog", @"add",
                @"accountId", [obj valueForKey:@"companyId"],
                @"action",    @"Account Changed",
                nil);

}

- (void)_executeInContext:(id)_context {
  [self assert:([self object] != nil) reason:@"no account object to act on"];
  [super _executeInContext:_context];
  [self _setStaffInContext:_context];

  if (self->teams != nil) {
    LSRunCommandV(_context, @"account", @"setgroups",
                  @"member", [self object],
                  @"groups", self->teams, nil);
  }
  // save attachement

  if (self->data != nil && self->filePath != nil && [self->data length] > 0) {
    BOOL     isOk;
    NSString *path     = nil;
    NSString *fileName = nil;

    path = [[_context userDefaults] stringForKey:@"LSAttachmentPath"];

    fileName = [[[[_context valueForKey:LSAccountKey]
                            valueForKey:@"companyId"] stringValue]
                            stringByAppendingPathExtension:@"html"];
    fileName = [path stringByAppendingPathComponent:fileName];
    
    isOk = [self->data writeToFile:fileName atomically:YES];
    [self assert:isOk reason:@"error during save of attachment"];
  }

  // save Filter

  if ((self->filter != nil) && ([self->filter length] > 0)) {
    BOOL     isOk;
    NSString *path     = nil;
    NSString *fileName = nil;

    path = [[_context userDefaults] stringForKey:@"LSAttachmentPath"];
    
    fileName = [[[[_context valueForKey:LSAccountKey]
                            valueForKey:@"companyId"] stringValue]
                            stringByAppendingPathExtension:@"filter"];
    fileName = [path stringByAppendingPathComponent:fileName];

    isOk = [self->filter writeToFile:fileName atomically:YES];
    [self assert:isOk reason:@"error during save of filter"];
  }
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

// accessors

- (void)setData:(NSData *)_data {
  ASSIGN(self->data, _data);
}
- (NSData *)data {
  return self->data;
}

- (void)setFilter:(id)_filter {
  ASSIGN(self->filter, _filter);
}
- (id)filter {
  return self->filter;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGN(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

- (void)setTeams:(NSArray *)_teams {
  ASSIGN(self->teams, _teams);
}

- (NSArray *)teams {
  return self->teams;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"teams"] ||
      [_key isEqualToString:@"toGroup"] ||
      [_key isEqualToString:@"groups"]) {
    [self setTeams:_value];
    return;
  }
  else if ([_key isEqualToString:@"data"]) {
    [self setData:_value];
    return;
  }
  else if ([_key isEqualToString:@"filter"]) {
    [self setFilter:_value];
    return;
  }
  else if ([_key isEqualToString:@"filePath"]) {
    [self setFilePath:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"teams"] ||
      [_key isEqualToString:@"toGroup"] ||
      [_key isEqualToString:@"groups"])
    return [self teams];
  else if ([_key isEqualToString:@"data"])
    return [self data];
  else if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  else if ([_key isEqualToString:@"filter"])
    return [self filter];

  return [super valueForKey:_key];
}

@end
