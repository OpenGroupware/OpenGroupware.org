/*
  Copyright (C) 2000-2006 SKYRIX Software AG

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

#include "AsteriskConnection.h"
#include <NGStreams/NGStreams.h>
#include <NGStreams/NGNet.h>
#include "common.h"

NSString *AsteriskExceptionName = @"AsteriskExceptioName";

@interface AsteriskConnection(Privates)
- (void)_disconnect;
- (BOOL)_connect;
@end

@implementation AsteriskConnection

+ (void)initialize {
  static BOOL isInitialized = NO;
  if (!isInitialized) {
    isInitialized = YES;
    
  }
}

- (id)initWithHost:(NSString *)_hostName onPort:(unsigned int)_port {
  if ((self = [super init])) {
    self->hostName = [_hostName copy];
    self->port     = _port;
  }
  return self;
}
- (id)init {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  [self setAsteriskCommands:[ud dictionaryForKey:@"AsteriskCommands"]];
  return [self initWithHost:[[ud dictionaryForKey:@"OGoAsteriskConnectionDictionary"] objectForKey:@"hostName"]
               onPort:[[[ud dictionaryForKey:@"OGoAsteriskConnectionDictionary"] objectForKey:@"port"] intValue]];
}

- (void)dealloc {
  [self _disconnect];
  RELEASE(self->hostName);
  RELEASE(self->context);
  RELEASE(self->asteriskCommands);
  RELEASE(self->socket);
  RELEASE(self->io);
  [super dealloc];
}

/* socket connection */

- (BOOL)_connect {
  id<NGSocketAddress> address;
  [self _disconnect];
  
#if DEBUG
  NSAssert(self->socket == nil, @"socket still available after disconnect");
  NSAssert(self->io == nil,     @"IO stream still available after disconnect");
#endif
  
  address = [NGInternetSocketAddress addressWithPort:self->port
                                     onHost:self->hostName];
  if (address == nil)
    return NO;

  NS_DURING
    self->socket = [NGActiveSocket socketConnectedToAddress:address];
  NS_HANDLER {
    fprintf(stderr, "couldn't create socket: %s\n",
            [[localException description] cString]);
    self->socket = nil;
  }
  NS_ENDHANDLER;
  
  if (self->socket == nil)
    return NO;
  
  RETAIN(self->socket);
  self->io = [[NGCTextStream alloc] initWithSource:self->socket];

  [[NSNotificationCenter defaultCenter]
                         addObserver:self selector:@selector(eventPending:)
                         name:NSFileObjectBecameActiveNotificationName
                         object:self->socket];
  [[NSRunLoop currentRunLoop]
              addFileObject:self->socket
              activities:NSPosixReadableActivity
              forMode:NSDefaultRunLoopMode];
  if (![self loginToAsterisk]) {
    [self _disconnect];
    return NO;
  }

  return YES;
}
- (void)_disconnect {
  if (self->socket) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSRunLoop currentRunLoop]
                removeFileObject:self->socket
                forMode:NSDefaultRunLoopMode];
  }
  
  RELEASE(self->io); self->io = nil;
  
  NS_DURING
    [self->socket shutdown];
  NS_HANDLER {}
  NS_ENDHANDLER;
  
  RELEASE(self->socket); self->socket = nil;
}

- (BOOL)_ensureConnection {
  if (self->socket == nil) {
    return [self _connect];
  }
  return YES;
}

/* accessors */

- (NSException *)lastException {
  return self->lastException;
}

/* connection */

- (BOOL)connect {
  return [self _ensureConnection];
}
- (void)bye {
  [self _disconnect];
}

- (void)setAsteriskCommands:(NSDictionary *)_commands {
  ASSIGN(self->asteriskCommands, _commands);
}
- (NSDictionary *)asteriskCommands {
  return self->asteriskCommands;
}

- (void)setContext:(NSString *)_context {
  ASSIGN(self->context, _context);
}
- (NSString *)context {
  return self->context;
}

/* async events */

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

/* error indicator lines */

- (NSString *)reasonForCode:(NSString *)_code {
  if ([_code isEqualToString:@"INVALCMD"])
    return @"invalid command issued";
  if ([_code isEqualToString:@"INVALIDAGENTSTATE"])
    return @"invalid agent state";
  if ([_code isEqualToString:@"INVALIDDEVICEFEATURE"])
    return @"invalid device feature";
  if ([_code isEqualToString:@"INVALIDFORWARDINGFEATURE"])
    return @"invalid forwarding feature";
  if ([_code isEqualToString:@"INVALNUMPARAM"])
    return @"invalid number of parameters";
  return _code;
}

- (NSException *)_exceptionWithCode:(NSString *)_code {
  NSMutableDictionary *ui;
  NSException *exc;

  ui = [NSMutableDictionary dictionaryWithCapacity:16];
  
  if (self->hostName)
    [ui setObject:self->hostName forKey:@"hostName"];
  [ui setObject:[NSNumber numberWithInt:self->port] forKey:@"port"];
  [ui setObject:self  forKey:@"connection"];
  [ui setObject:_code forKey:@"code"];
  
  exc = [NSException exceptionWithName:AsteriskExceptionName
                     reason:[self reasonForCode:_code]
                     userInfo:ui];
#if DEBUG
  NSLog(@"%s: made exception for code %@", __PRETTY_FUNCTION__, _code);
#endif
  return exc;
}

- (NSException *)exceptionForErrorIndicatorLine:(NSString *)_line {
  NSArray  *lineComponents;
  unsigned count;
  NSString *code;
  
  if (![_line hasPrefix:@"error_ind "])
    return nil;
  if ([_line hasPrefix:@"error_ind SUCCESS"])
    return nil;
  
  lineComponents = [_line componentsSeparatedByString:@" "];
  
  if ((count = [lineComponents count]) < 2)
    return [self _exceptionWithCode:@"INVALIDCMD"];
  
  code = [lineComponents objectAtIndex:1];
  
  return [self _exceptionWithCode:code];
}

/* generic commands */

- (NSException *)sendCommand:(NSString *)_command withParameters:(NSDictionary *)_parameters expectResult:(NSString *)_result {
  NSException *exc;
  if (![self _ensureConnection])
    return [self _exceptionWithCode:@"COULDNTCONNECT"];
  *(&exc) = nil;

  NS_DURING {
    NSString *line;
    NSEnumerator *keys, *values;
    id parameterkey;
    id parametervalue;

    /* send request */
    [self->io writeString:[NSString stringWithFormat:@"Action: %@\r\n", _command]];
    keys = [_parameters keyEnumerator];
    values = [_parameters objectEnumerator];
    while ((parameterkey = [keys nextObject], parametervalue = [values nextObject])) {
      line = [NSString stringWithFormat:@"%@: %@\r\n", parameterkey, parametervalue];
      [self->io writeString:line];
    }
    [self->io writeString:@"\r\n"];
    [self->io flush];
    
    /* receive error indicator */
    
    while ((line = [self->io readLineAsString])) {
      if ([line hasPrefix:@"Response: "]) {
	if (![line hasSuffix:_result]) {
	  line = [self->io readLineAsString];
          exc = [[self exceptionForErrorIndicatorLine:line] retain];
          break;
        }
      }
      else if ([line length] == 0)
	break;
    }

  }
  NS_HANDLER {
    exc = RETAIN(localException);
  }
  NS_ENDHANDLER;
  
  return AUTORELEASE(exc);
}

/* concrete commands */

- (BOOL)loginToAsterisk {
  NSException *exc;
  if ((exc = [self sendCommand:@"Login" 
		withParameters:[[[self asteriskCommands] objectForKey:@"Login"] objectForKey:@"Parameters"] 
		expectResult:[[[self asteriskCommands] objectForKey:@"Login"] objectForKey:@"ExpectedResult"]])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)pingAsterisk {
  NSException *exc;
  if ((exc = [self sendCommand:@"Ping"
                withParameters:nil
                expectResult:[[[self asteriskCommands] objectForKey:@"Ping"] objectForKey:@"ExpectedResult"]])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)makeCallTo:(NSString *)_number fromDevice:(NSString *)_device {
  NSException *exc;

  [[[[self asteriskCommands] objectForKey:@"Originate"] objectForKey:@"Parameters"] takeValue:_number forKey:@"Exten"];
  [[[[self asteriskCommands] objectForKey:@"Originate"] objectForKey:@"Parameters"] takeValue:_device forKey:@"Channel"];
  [[[[self asteriskCommands] objectForKey:@"Originate"] objectForKey:@"Parameters"] takeValue:[self context] forKey:@"Context"]; 
  if ((exc = [self sendCommand:@"Originate"
                withParameters:[[[self asteriskCommands] objectForKey:@"Originate"] objectForKey:@"Parameters"]
                expectResult:[[[self asteriskCommands] objectForKey:@"Originate"] objectForKey:@"ExpectedResult"]])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

@end /* AsteriskConnection */
