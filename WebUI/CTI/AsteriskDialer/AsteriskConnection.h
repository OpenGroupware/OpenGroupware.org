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

#ifndef __AsteriskConnection_H__
#define __AsteriskConnection_H__

#import <Foundation/NSObject.h>

@class NSString, NSException, NSArray, NSNotificationCenter;
@class NGCTextStream,NSDictionary,NSNumber;

@interface AsteriskConnection : NSObject
{
  NSString      *hostName;
  NSString	*context;
  NSDictionary  *asteriskCommands;
  unsigned int  port;
  
  id            socket;
  NGCTextStream *io;
  
  NSException   *lastException;
}

- (id)initWithHost:(NSString *)_hostName onPort:(unsigned int)_port;

/* accessors */

- (NSException *)lastException;
- (void)setAsteriskCommands:(NSDictionary *)_commands;
- (NSDictionary *)asteriskCommands;
- (void)setContext:(NSString *)_context;
- (NSString *)context;

/* connection */

- (BOOL)connect;
- (void)bye;

/* events */

- (NSNotificationCenter *)notificationCenter;

/* generic commands */

- (NSException *)sendCommand:(NSString *)_command withParameters:(NSDictionary *)_parameters expectResult:(NSString *)_result;

/* concrete commands */

- (BOOL)loginToAsterisk;
- (BOOL)pingAsterisk;
- (BOOL)makeCallTo:(NSString *)_number fromDevice:(NSString *)_device; 

@end /* AsteriskConnection */

#endif /* __AsteriskConnection_H__ */
