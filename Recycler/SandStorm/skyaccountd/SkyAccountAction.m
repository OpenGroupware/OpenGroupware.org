/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "SkyAccountAction.h"
#include "SkyAccountApplication.h"
#include "NSObject+EKVC.h"
#include "common.h"
#include <OGoIDL/NGXmlRpcAction+Introspection.h>

@interface SkyAccountAction(Misc)

- (void)setAccountValues:(id)_account toDBObj:(id)_dbObj;
- (NSMutableDictionary *)_buildAccountFromDB:(id)_account;
- (id)_getAccountById:(NSString *)_uid;
- (id)_getGroupById:(NSString *)_uid;
- (void)setGroupValues:(id)_group toDBObj:(id)_dbObj;
- (NSMutableDictionary *)_buildGroupFromDB:(id)_group;
@end /* DirectAction(Misc) */

@implementation SkyAccountAction

static NSArray *DBKeys      = nil;
static NSArray *AccountKeys = nil;
static NSArray *GroupKeys   = nil;

+ (void)initialize {
  if (DBKeys == nil) {
    DBKeys      = [[NSArray alloc] initWithObjects:
                                   @"login", @"companyId", @"name",
                                   @"firstname", nil];
  }
  if (AccountKeys == nil) {
    AccountKeys = [[NSArray alloc] initWithObjects:
                                   @"login", @"uid", @"name",
                                   @"firstname", nil];
  }
  if (GroupKeys == nil) {
    GroupKeys = [[NSArray alloc] initWithObjects:
                                 @"description", @"isLocationTeam", nil];
  }
}

- (NSBundle *)bundleForClass {
  return [NSBundle bundleForClass:[self class]];
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;

    path = [[self bundleForClass] pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

- (void)dealloc {
  [self->login release];
  [super dealloc];
}

/* accessors */

- (BOOL)isRoot {
  return ([self loginId] == 10000) ? YES : NO;
}

- (int)loginId {
  if (!self->loginId) {
    self->loginId = [[[[self commandContext] valueForKey:LSAccountKey]
                             valueForKey:@"companyId"] intValue];
  }
  return self->loginId;
}

- (NSString *)login {
  if (self->login == nil) {
    self->login = [[[[self commandContext] valueForKey:LSAccountKey]
		           valueForKey:@"login"] copy];
  }
  return self->login;
}

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObject:@"accounts"];
}

- (NSString *)xmlrpcComponentName {
  return @"accounts";
}

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_call {
  NSString *nameSpacePrefix;

  nameSpacePrefix = [[self xmlrpcComponentNamespace]
                           stringByAppendingString:@"."];
  
  _call = [_call stringWithoutPrefix:nameSpacePrefix];

  if ([_call isEqualToString:@"authenticate"])
    return NO;
  if ([_call hasPrefix:@"system."])
    return NO;
  
  return YES;
}

- (NSException *)buildExceptonWithNumber:(int)_number
  reason:(NSString *)_reason
  command:(char *)_funtction
{
  NSLog(@"WARNING[%s]: exception[%d]: %@",
        _funtction, _number, _reason);
  return [NSException exceptionWithName:[[NSNumber numberWithInt:_number]
                                                   stringValue]
                      reason:_reason userInfo:nil];
}

- (id)application {
  return [WOApplication application];
}

- (NSArray *)groupKeys {
  return GroupKeys;
}
- (NSArray *)accountKeys {
  return AccountKeys;
}

- (NSArray *)dbKeys {
  return DBKeys;
}

@end /* SkyAccountAction(Misc) */

@interface DirectAction : SkyAccountAction
@end

@implementation DirectAction
@end
