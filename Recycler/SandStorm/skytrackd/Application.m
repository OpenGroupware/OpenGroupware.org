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

#include "Application.h"
#include "SkyProjectFileManager+MD5.h"
#include "ProjectChannel.h"
#include "ChannelRegistry.h"
#include "common.h"
#include "SkyTrackAction.h"

@interface DirectAction : SkyTrackAction
@end /* DirectAction */

@implementation Application

- (id)init {
  if ((self = [super init])) {
    NSFileManager  *fileManager   = nil;
    NSUserDefaults *ud            = nil;
    NSString       *userDir       = nil;
    int            updateInterval = 0;
    
    ud          = [NSUserDefaults standardUserDefaults];    
    fileManager = [NSFileManager defaultManager];

    userDir        = [ud stringForKey:@"SkyTrackDaemonUserHome"];
    updateInterval = [[ud stringForKey:@"SkyTrackUpdateInterval"] intValue];
    
    if (userDir == nil) {
      userDir = [[[NSProcessInfo processInfo]
                                 environment]
                                 objectForKey:@"GNUSTEP_USER_ROOT"];
      userDir = [userDir stringByAppendingPathComponent:@"trackdata"];
    }
    
    if (![fileManager fileExistsAtPath:userDir]) {
      NSLog(@"%s: data directory %@ not found, creating",
            __PRETTY_FUNCTION__, userDir);
      [fileManager createDirectoryAtPath:userDir attributes:nil];
    }
    
    self->channelRegistry = [[ChannelRegistry alloc] init];
    [self->channelRegistry initChannelRegistry:userDir];
    
    self->runTimer = [[NSTimer scheduledTimerWithTimeInterval:updateInterval
                              target:self
                              selector:@selector(trackChannels:)
                              userInfo:nil
                              repeats:YES] retain];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->runTimer);
  RELEASE(self->channelRegistry);
  [super dealloc];
}
#endif

/* accessors */

- (ChannelRegistry *)channelRegistry {
  return self->channelRegistry;
}

- (void)trackChannels:(NSTimer *)_timer {
  [self->channelRegistry trackObjects];
}

@end /* Application */

@implementation DirectAction

- (id)defaultAction {
  return [super RPC2Action];
}

@end /* DirectAction */
