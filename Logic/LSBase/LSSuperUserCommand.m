// $Id$

#include <LSFoundation/LSBaseCommand.h>

@interface LSSuperUserCommand : LSBaseCommand
{
 @private
  NSString *login;
  BOOL isSessionLogEnabled;
}

@end /* LSSuperUserCommand */

#import "common.h"

@implementation LSSuperUserCommand

- (void)dealloc {
  [self->login release];
  [super dealloc];
}

/* accessors */

- (NSString *)login {
  return self->login;
}
- (void)setLogin:(NSString *)_login {
  ASSIGN(self->login,_login);
}

- (BOOL)isSessionLogEnabled {
  return self->isSessionLogEnabled;
}
- (void)setIsSessionLogEnabled:(BOOL)_flag {
  self->isSessionLogEnabled = _flag;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id account;
  account = [_context valueForKey:LSAccountKey];
  [self assert:(account != nil)
        reason:@"missing super user account"];
  [self assert:([[account valueForKey:@"companyId"] intValue] == 10000)
        reason:@"active user has no super user access"];
}

- (void)_executeInContext:(id)_context {
  [self setReturnValue:
        [_context su_contextForLogin:[self login]
                  isSessionLogEnabled:[self isSessionLogEnabled]]];
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"login"])
    [self setLogin:_value];
  else if ([_key isEqualToString:@"isSessionLogEnabled"])
    [self setIsSessionLogEnabled:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"login"])
    return [self login];
  else if ([_key isEqualToString:@"isSessionLogEnabled"])
    return [NSNumber numberWithBool:[self isSessionLogEnabled]];
  else
    return [super valueForKey:_key];
}
  

@end /* LSSuperUserCommand */
