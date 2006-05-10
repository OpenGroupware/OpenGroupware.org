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

#ifndef __STLIConnection_H__
#define __STLIConnection_H__

#import <Foundation/NSObject.h>

@class NSString, NSException, NSArray, NSNotificationCenter;
@class NGCTextStream;

@interface STLIConnection : NSObject
{
  NSString      *hostName;
  unsigned int  port;
  
  id            socket;
  NGCTextStream *io;
  
  NSException   *lastException;
}

- (id)initWithHost:(NSString *)_hostName onPort:(unsigned int)_port;

/* accessors */

- (NSException *)lastException;

/* connection */

- (BOOL)connect;
- (void)bye;

/* events */

- (NSNotificationCenter *)notificationCenter;

- (void)supressDeviceInformation;
- (void)standardDeviceInformation;
- (void)extendedDeviceInformation;

/* generic commands */

- (NSException *)sendCommand:(NSString *)_command parameters:(NSArray *)_args;
- (NSException *)sendCommand:(NSString *)_command,...;

/* concrete commands */

- (BOOL)startMonitoringDevice:(NSString *)_localDevice;
- (BOOL)stopMonitoringDevice:(NSString *)_localDevice;

- (BOOL)makeCallFromLocalDevice:(NSString *)_callingDevice
  toDevice:(NSString *)_targetDevice;

- (BOOL)answerCallOnLocalDevice:(NSString *)_calledLocalDevice;

- (BOOL)clearConnectionOnLocalDevice:(NSString *)_localDevice;

- (BOOL)redirectCallOnLocalDevice:(NSString *)_localDevice
  toDevice:(NSString *)_targetDevice;
- (BOOL)conferenceCallOnLocalDevice:(NSString *)_localDevice;

- (BOOL)alternateCallOnLocalDevice:(NSString *)_localDevice;
- (BOOL)holdCallOnLocalDevice:(NSString *)_localDevice;
- (BOOL)reconnectCallOnLocalDevice:(NSString *)_localDevice;
- (BOOL)retrieveCallOnLocalDevice:(NSString *)_localDevice;
- (BOOL)transferCallOnLocalDevice:(NSString *)_localDevice;

@end

#endif /* __STLIConnection_H__ */
