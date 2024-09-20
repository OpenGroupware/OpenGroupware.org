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

#include "STLIConnection.h"
#include <NGStreams/NGStreams.h>
#include <NGStreams/NGNet.h>
#include "common.h"

NSString *STLIExceptioName = @"STLIExceptioName";

@interface STLIConnection(Privates)
- (void)_disconnect;
- (BOOL)_connect;
@end

@implementation STLIConnection

+ (void)initialize {
  static BOOL isInitialized = NO;
  if (!isInitialized) {
    NSDictionary *events = nil;
    isInitialized = YES;
    
    events =
      [NSDictionary dictionaryWithContentsOfFile:@"STLIEventKeys.plist"];
    
    [[NSUserDefaults standardUserDefaults]
                     registerDefaults:
                       [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"26535",     @"STLIPort",
                                       @"localhost", @"STLIHost",
                                       events,       @"STLIEventParameters",
                                       nil]];
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
  return [self initWithHost:[ud stringForKey:@"STLIHost"]
               onPort:[[ud objectForKey:@"STLIPort"] intValue]];
}

- (void)dealloc {
  [self _disconnect];
  RELEASE(self->hostName);
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
  
  if ([self sendCommand:@"STLI;Version=2", nil]) {
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
  
  if (self->io)
    [self sendCommand:@"BYE" parameters:nil];
  
  RELEASE(self->io); self->io = nil;
  
  NS_DURING
    [self->socket shutdown];
  NS_HANDLER {}
  NS_ENDHANDLER;
  
  RELEASE(self->socket); self->socket = nil;
}

- (BOOL)_ensureConnection {
  if (self->socket == nil)
    return [self _connect];
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

/* async events */

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (BOOL)isCallEvent:(NSString *)_eventName {
  static NSArray *callEvents = nil;
  
  if (callEvents == nil) {
    callEvents = [[[[NSUserDefaults standardUserDefaults]
                                    dictionaryForKey:@"STLIEventParameters"]
                                    objectForKey:@"STLICallEvents"]
                                    copy];
  }
  
  return [callEvents containsObject:_eventName];
}

- (NSNotification *)notificationForEvent:(NSString *)_event
  parameterLine:(NSString *)_line
  deviceInfo:(NSString *)_diline
{
  NSNotification      *n;
  NSString            *nName;
  NSMutableDictionary *ui;
  
  if ([_event length] == 0)
    return nil;
  
  nName = [@"STLI_" stringByAppendingString:_event];

  ui = [NSMutableDictionary dictionaryWithCapacity:8];
  [ui setObject:self   forKey:@"connection"];
  [ui setObject:_event forKey:@"STLIEvent"];

  if ([_line length] > 0) {
    NSArray  *comps;
    unsigned count;
    
    comps = [_line componentsSeparatedByString:@" "];
    if ((count = [comps count]) > 0) {
      NSDictionary *eventParas;
      NSArray      *mappings;
      unsigned     i, mcount;
      
      eventParas = [[NSUserDefaults standardUserDefaults]
                                    dictionaryForKey:@"STLIEventParameters"];
      mappings = [eventParas objectForKey:_event];

      for (i = 0, mcount = [mappings count]; i < mcount && i < count; i++) {
        NSString *key;
        id value;
        
        key   = [mappings objectAtIndex:i];
        value = [comps    objectAtIndex:i];
        if (key == nil || value == nil) continue;

        if ([value isEqualToString:@"\"\""])
          value = @"";
        else if ([value hasPrefix:@"\""] && [value hasSuffix:@"\""]) {
          value = [value substringFromIndex:1];
          value = [value substringToIndex:([value length] - 1)];
        }
        
        [ui setObject:value forKey:key];
      }
    }
    
    [ui setObject:_line forKey:@"STLIParameterLine"];
  }

  if (_diline)
    [ui setObject:_diline forKey:@"STLIDeviceInfoLine"];
  
  n = [NSNotification notificationWithName:nName
                      object:self
                      userInfo:ui];
  return n;
}

- (void)_queueEventLine:(NSString *)_line {
  NSNotification *stliEvent;
  NSString   *eventName;
  NSString   *devInfo;
  NSUInteger idx;

  if ([_line length] == 0) return;
  
  if ((idx = [_line indexOfString:@" "]) == NSNotFound) {
    eventName = _line;
    _line     = nil;
  }
  else {
    eventName = [_line substringToIndex:idx];
    _line     = [_line substringFromIndex:(idx + 1)];
  }
  
  /* check for call events and read associated device info */
  
  if ([self isCallEvent:eventName])
    devInfo = [self->io readLineAsString];
  else
    devInfo = nil;

  /* construct event notification */
  
  stliEvent = [self notificationForEvent:eventName
                    parameterLine:_line
                    deviceInfo:devInfo];
  
  if (stliEvent)
    [[self notificationCenter] postNotification:stliEvent];
}

- (void)eventPending:(NSNotification *)_notification {
  NSString *line;
  
  while (([self->socket numberOfAvailableBytesForReading] > 0)) {
    line = [self->io readLineAsString];
    [self _queueEventLine:line];
  }
}

- (void)supressDeviceInformation {
  [self sendCommand:@"STLI;DeviceInformation=Off" parameters:nil];
}
- (void)standardDeviceInformation {
  [self sendCommand:@"STLI;DeviceInformation=Standard" parameters:nil];
}
- (void)extendedDeviceInformation {
  [self sendCommand:@"STLI;DeviceInformation=Extended" parameters:nil];
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
  
  exc = [NSException exceptionWithName:STLIExceptioName
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

- (NSException *)sendCommand:(NSString *)_command parameters:(NSArray *)_args {
  NSException *exc;
  unsigned i, count;

  if (![self _ensureConnection])
    return [self _exceptionWithCode:@"COULDNTCONNECT"];
  
  *(&exc) = nil;
  NS_DURING {
    NSString *line;
    
    /* send request */
    [self->io writeString:_command];
    for (i = 0, count = [_args count]; i < count; i++) {
      [self->io writeString:@" "];
      [self->io writeString:[[_args objectAtIndex:i] stringValue]];
    }
    [self->io writeString:@"\r\n"];
    [self->io flush];
    
    /* receive error indicator */
    
    while ((line = [self->io readLineAsString])) {
      if ([line hasPrefix:@"error_ind "]) {
        exc = [[self exceptionForErrorIndicatorLine:line] retain];
        break;
      }
      else if ([line length] > 0)
        [self _queueEventLine:line];
    }
  }
  NS_HANDLER {
    exc = RETAIN(localException);
  }
  NS_ENDHANDLER;
  
  return AUTORELEASE(exc);
}

- (NSException *)sendCommand:(NSString *)_command, ... {
  NSMutableArray *args;
  va_list list;
  id      item;
  
  args = [NSMutableArray arrayWithCapacity:8];
  
  va_start(list, _command);
  while ((item = va_arg(list, id)))
    [args addObject:item];
  va_end(list);
  
  return [self sendCommand:_command parameters:args];
}

/* concrete commands */

- (BOOL)startMonitoringDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"MonitorStart", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}
- (BOOL)stopMonitoringDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"MonitorStop", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)makeCallFromLocalDevice:(NSString *)_callingDevice
  toDevice:(NSString *)_targetDevice
{
  NSException *exc;
  if ((exc=[self sendCommand:@"MakeCall",_callingDevice,_targetDevice,nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)answerCallOnLocalDevice:(NSString *)_calledLocalDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"AnswerCall", _calledLocalDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)clearConnectionOnLocalDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"ClearConnection", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)redirectCallOnLocalDevice:(NSString *)_localDevice
  toDevice:(NSString *)_targetDevice
{
  NSException *exc;
  
  exc = [self sendCommand:@"ConsultationCall", _localDevice,_targetDevice,nil];
  if (exc) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)conferenceCallOnLocalDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"ConferenceCall", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

- (BOOL)alternateCallOnLocalDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"AlternateCall", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}
- (BOOL)holdCallOnLocalDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"HoldCall", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}
- (BOOL)reconnectCallOnLocalDevice:(NSString *)_localDevice {
  /* at least one connection must be on hold */
  NSException *exc;
  if ((exc = [self sendCommand:@"ReconnectCall", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}
- (BOOL)retrieveCallOnLocalDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"RetrieveCall", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}
- (BOOL)transferCallOnLocalDevice:(NSString *)_localDevice {
  NSException *exc;
  if ((exc = [self sendCommand:@"TransferCall", _localDevice, nil])) {
    ASSIGN(self->lastException, exc);
    return NO;
  }
  else
    return YES;
}

@end /* STLIConnection */
