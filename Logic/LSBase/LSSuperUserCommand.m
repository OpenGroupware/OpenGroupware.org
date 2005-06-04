
#include <LSFoundation/LSBaseCommand.h>

@interface LSSuperUserCommand : LSBaseCommand
{
 @private
  NSString *login;
  BOOL isSessionLogEnabled;
}

@end /* LSSuperUserCommand */

#include "common.h"

@implementation LSSuperUserCommand

- (void)dealloc {
  [self->login release];
  [super dealloc];
}

/* accessors */

- (void)setLogin:(NSString *)_login {
  ASSIGNCOPY(self->login,_login);
}
- (NSString *)login {
  return self->login;
}

- (void)setIsSessionLogEnabled:(BOOL)_flag {
  self->isSessionLogEnabled = _flag;
}
- (BOOL)isSessionLogEnabled {
  return self->isSessionLogEnabled;
}

/* run command */

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

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"login"])
    [self setLogin:_value];
  else if ([_key isEqualToString:@"isSessionLogEnabled"])
    [self setIsSessionLogEnabled:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"login"])
    return [self login];
  if ([_key isEqualToString:@"isSessionLogEnabled"])
    return [NSNumber numberWithBool:[self isSessionLogEnabled]];

  return [super valueForKey:_key];
}

@end /* LSSuperUserCommand */
