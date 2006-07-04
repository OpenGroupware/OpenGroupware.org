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

#include "XmlRpcAction.h"
#include <NGXmlRpc/NGXmlRpcClient.h>
#include "common.h"

@implementation XmlRpcAction

- (id)init {
  if ((self = [super init])) {
    self->command   = [[NSString alloc] init];
    self->commandArguments = [[NSArray  alloc] init];

    self->hostName = [[NSString alloc] init];
    self->uri      = [[NSString alloc] init];
    self->userName = [[NSString alloc] init];
    self->password = [[NSString alloc] init];
  }
  return self;
}

+ (XmlRpcAction *)actionWithArguments:(NSDictionary *)_args {
  XmlRpcAction *action      = nil;
  NSString     *url         = nil;
  NSString     *hostAndPort = nil;
  
  action = [[self alloc] init];
  [action setCommand:[_args valueForKey:@"xmlrpc_call"]];

  url = [[_args valueForKey:@"url"] substringFromIndex:7];

  hostAndPort = [[url componentsSeparatedByString:@"/"] objectAtIndex:0];
  
  [action setHostName:[[hostAndPort componentsSeparatedByString:@":"]
                                  objectAtIndex:0]];
  action->port = [[[hostAndPort componentsSeparatedByString:@":"]
                              objectAtIndex:1] intValue];

  [action setUri:[[url componentsSeparatedByString:hostAndPort]
                       objectAtIndex:1]];
  
  [action setUserName:[_args valueForKey:@"user"]];
  [action setPassword:[_args valueForKey:@"password"]];
  
  [action setArguments:_args];
  [action setCommandArguments:[_args valueForKey:@"arguments"]];

  return AUTORELEASE(action);
}

- (void)dealloc {
  RELEASE(self->command);
  RELEASE(self->commandArguments);

  RELEASE(self->hostName);
  RELEASE(self->uri);
  RELEASE(self->userName);
  RELEASE(self->password);
  
  [super dealloc];
}

/* accessors */

- (NSString *)command {
  return self->command;
}
- (void)setCommand:(NSString *)_command {
  ASSIGNCOPY(self->command, _command);
}

- (NSArray *)commandArguments {
  return self->commandArguments;
}
- (void)setCommandArguments:(NSArray *)_arguments {
  ASSIGN(self->commandArguments, _arguments);
}

- (NSString *)hostName {
  return self->hostName;
}
- (void)setHostName:(NSString *)_name {
  ASSIGNCOPY(self->hostName, _name);
}

- (NSString *)uri {
  return self->uri;
}
- (void)setUri:(NSString *)_uri {
  ASSIGNCOPY(self->uri, _uri);
}

- (NSString *)userName {
  return self->userName;
}
- (void)setUserName:(NSString *)_name {
  ASSIGNCOPY(self->userName, _name);
}

- (NSString *)password {
  return self->password;
}
- (void)setPassword:(NSString *)_password {
  ASSIGNCOPY(self->password, _password);
}

- (id)run {
  NGXmlRpcClient *client = nil;
  id              result  = nil;

  client = [[NGXmlRpcClient alloc] initWithHost:[self hostName]
                                    uri:[self uri]
                                    port:self->port
                                    userName:[self userName]
                                    password:[self password]];

  result = [client invokeMethodNamed:[self command]
                   parameters:[self commandArguments]];

  RELEASE(client);
  
  return result;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@[0x%p]: xmlrpc: %@>",
                   NSStringFromClass([self class]), self,
                   self->command];
}

@end /* XmlRpcAction */
