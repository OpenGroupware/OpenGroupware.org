/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id: DirectAction+System.m 1 2004-08-20 11:17:52Z znek $

#include <EOControl/EOControl.h>
#include <NGStreams/NGStreams.h>
#include <NGStreams/NGActiveSocket.h>
#include <NGStreams/NGNet.h>
#include "EOControl+XmlRpcDirectAction.h"
#include "Session.h"
#include "DirectAction.h"
#include "common.h"

@implementation DirectAction(System)

#if 0
- (NSString *)system_lsAction:(id)_path {
  NSTask *lsTask = [[NSTask alloc] init];
  NSPipe *lsPipe = [NSPipe pipe];
  NSMutableArray *args = [NSMutableArray array];

  NSString *command = @"/bin/ls";
  NSData *data = nil;

  [args addObject:[_path stringValue]];

  [lsTask setStandardOutput:lsPipe];
  
  [lsTask setLaunchPath:[command stringValue]];
  [lsTask setArguments:args];
   
  [lsTask launch];
  
  data = [[lsPipe fileHandleForReading] availableData];
  return [[NSString alloc] initWithData:data 
                           encoding:[NSString defaultCStringEncoding]];

  [lsTask release];
}

- (int)searchNextFreePortFrom:(int)_from to:(int)_to{
  NGInternetSocketAddress *a;
  NGActiveSocket          *socket;
  int                     i;

  for (i = _from; i <= _to; i++) {
    a = [NGInternetSocketAddress addressWithPort:i onHost:@"localhost"];
    NS_DURING {
      NSLog(@"check for port %d", i);
      socket = [NGPassiveSocket socketBoundToAddress:a];
    }
    NS_HANDLER {
      socket = nil;
    }
    NS_ENDHANDLER;
    if (socket)
      break;
  }
  if (socket) {
    [socket close];
    return i;
  }
  return 0;
}

- (id)system_startProjectDaemonAction:(id)_projectID {
  NSTask *lsTask = [[NSTask alloc] init];
  int    port; 
  NSMutableArray *args = [NSMutableArray array];
  NSString       *command;
  
  port = [self searchNextFreePortFrom:10810 to:10910];

  if (!port) {
    NSLog(@"%s: missing port", __PRETTY_FUNCTION__);
    return nil;
  }
  command = @"../skyprojectd/skyprojectd.woa/ix86/linux-gnu/"
            @"gnu-fd-nil-nil/skyprojectd";

  [args addObject:@"-project"];
  [args addObject:[_projectID stringValue]];
  [args addObject:@"-SkyProjectFileManagerUseSessionCache"];
  [args addObject:@"NO"];
  [args addObject:@"-SkyProjectFileManagerClickTimeout"];
  [args addObject:@"10"];
  [args addObject:@"-WODefaultSessionTimeout"];
  [args addObject:@"1"];
  [args addObject:@"-WOPort"];
  [args addObject:[NSString stringWithFormat:@"*:%d", port]];

  [lsTask setLaunchPath:command];
  [lsTask setArguments:args];

  [lsTask launch];
  [lsTask release];

  return [NSNumber numberWithInt:port];
}
#endif
 
- (NSString *)system_getHostNameAction:(id)_arg {
  return [[NSHost currentHost] name];
}

- (NSDate *)system_getServerTimeAction:(id)_arg {
  return [NSCalendarDate date];
}

- (NSString*)system_getServerTimeZoneAction:(id)_arg {
  return [[NSTimeZone defaultTimeZone] stringValue];
}

@end /* DirectAction(Server) */

