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

#include "SkySystemAction.h"
#include "SkySystemApplication.h"
#include "TaskComponent.h"
#include "common.h"
#include <EOControl/EOControl.h>
#include <NGXmlRpc/WODirectAction+XmlRpcIntrospection.h>

@implementation SkySystemAction

- (NSString *)xmlrpcComponentName {
  return @"system";
}

- (NSString *)methodNameWithoutPrefix:(NSString *)_methodName {
  NSString *result;

  result = [_methodName stringWithoutPrefix:
                          [self xmlrpcComponentNamespacePrefix]];
  result = [result stringWithoutPrefix:@"."];
  return result;
}

- (id)handleSystemMethod:(NSString *)_name parameters:(NSArray *)_params {
  NSString *selectorName;
  NSString *methodName;
  SkySystemApplication *app;
  int i;
  
  app = (SkySystemApplication *)[WOApplication application];
  
  selectorName = [NSString stringWithFormat:@"system_%@Action", _name];

  for (i = 0; i < [_params count]; i++) {
    selectorName = [selectorName stringByAppendingString:@":"];
  }
  
  if (![self respondsToSelector:NSSelectorFromString(selectorName)]) {
    return [NSException exceptionWithName:@"MissingMethod"
                        reason:[NSString stringWithFormat:
                          @"system method '%@' not found", _name]
                        userInfo:nil];
  }
  
  if ([_name isEqualToString:@"listMethods"])
    return [app listMethods:[self xmlrpcComponentNamespacePrefix]];
  
  methodName = [self methodNameWithoutPrefix:[_params objectAtIndex:0]];
  
  if ([_name isEqualToString:@"methodSignature"])
    return [app methodSignature:methodName];
  else if ([_name isEqualToString:@"methodHelp"])
    return [app methodHelp:methodName];
  else {
    return [NSException exceptionWithName:@"MissingMethod"
                        reason:[NSString stringWithFormat:
                          @"system method '%@' not found", _name]
                        userInfo:nil];
  }
}

- (id)performMethodNamed:(NSString *)_name
  ofComponentNamed:(NSString *)_cname
  parameters:(NSArray *)_params 
{
  TaskComponent *tc;
  NSString      *componentPrefix;
  
  /* filter out system introspection methods */
  if ([_cname isEqualToString:@"system"])
    return [self handleSystemMethod:_name parameters:_params];
  
#if 0 /* hh: Bjoern, what's that ? weird. (only look a the last part?) */
  NSArray       *separatedComp;
  separatedComp = [_cname componentsSeparatedByString:@"."];
  if ([[separatedComp objectAtIndex:[separatedComp count] - 1]
                      isEqualToString:@"system"]) {
    id result = nil;
    if ((result = [self handleSystemMethod:_name parameters:_params]) != nil)
      return result;
  }
#endif
  
  /* cut the default namespace prefix */
  if ((componentPrefix = [self xmlrpcComponentNamespacePrefix]) == nil)
    componentPrefix = @"";

  if ([_cname hasPrefix:componentPrefix]) {
    NSString *prefix;

    prefix = [NSString stringWithFormat:@"%@.", componentPrefix];
    _cname = [_cname stringWithoutPrefix:prefix];
  }
  
  if ((tc = [(id)[WOApplication application] componentNamed:_cname]))
    return [tc callMethodNamed:_name parameters:_params];
  
  [self logWithFormat:@"did not find component named: %@", _cname];
  return [NSException exceptionWithName:@"MissingComponent"
                      reason:[NSString stringWithFormat:
                        @"did not find component named: %@", _cname]
                      userInfo:nil];
}

- (id)performActionNamed:(NSString *)_name
  parameters:(NSArray *)_params 
{
  NSRange  r;
  unsigned idx;
  NSString *comp, *method;
  
  r = [_name rangeOfString:@"." options:NSBackwardsSearch];
  if (r.length == 0) return nil;
  idx = r.location;
  
  comp   = [_name substringToIndex:idx];
  method = [_name substringFromIndex:(idx + 1)];
  
  return [self performMethodNamed:method
               ofComponentNamed:comp
               parameters:_params];
}

- (BOOL)authIsValid {
  NSString       *credentials;
  NSRange        r;
  NSArray        *creds;
  NSString       *user;
  NSString       *password;
  NSUserDefaults *ud;
  NSDictionary   *account;
  
  credentials = [[self request] headerForKey:@"authorization"];
  
  r = [credentials rangeOfString:@" " options:NSBackwardsSearch];

  if(r.length == 0) {
    NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
    return NO;
  }

  credentials = [credentials substringFromIndex:(r.location + r.length)];
  credentials = [credentials stringByDecodingBase64];
  creds       = [credentials componentsSeparatedByString:@":"];
  user        = [creds objectAtIndex:0];
  password    = [creds objectAtIndex:1];

  ud = [NSUserDefaults standardUserDefaults];

  if ((account = [ud objectForKey:@"SkyDBDAccount"]) == nil) {
    NSLog(@"%s: no SkyDBDAccount found in userDefaults",__PRETTY_FUNCTION__);
    return NO;
  }
  
  if (![[account objectForKey:@"username"] isEqualToString:user]) {
    NSLog(@"%s: invalid username", __PRETTY_FUNCTION__);
    return NO;
  }

  if (![[account objectForKey:@"password"] isEqualToString:password]) {
    NSLog(@"%s: invalid password", __PRETTY_FUNCTION__);
    return NO;
  }
  return YES;
}

@end /* SkySystemAction */

@interface DirectAction : SkySystemAction
@end

@implementation DirectAction
@end /* DirectAction */
