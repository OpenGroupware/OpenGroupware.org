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

#import <Foundation/NSObject.h>
#include "STLIConnection.h"

@interface Client : NSObject
{
  STLIConnection *stli;
}

@end

#include "common.h"

@implementation Client

- (id)init {
  self->stli = [[STLIConnection alloc] init];
  [[self->stli notificationCenter]
               addObserver:self selector:@selector(stliEvent:)
               name:nil object:self->stli];
  return self;
}
- (void)dealloc {
  [[self->stli notificationCenter]
               removeObserver:self];
  RELEASE(self->stli);
  [super dealloc];
}

- (void)stliEvent:(NSNotification *)_event {
  NSLog(@"STLI: %@", _event);
}

- (void)run {
  NSUserDefaults *ud;
  NSString *device;
  NSString *call;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  device = [ud stringForKey:@"device"];
  call   = [ud stringForKey:@"call"];
  
  if (![stli startMonitoringDevice:device]) {
    NSLog(@"couldn't monitor '%@' ...", device);
    exit(1);
  }
  NSLog(@"monitoring device '%@' ..", device);
  
  if ([call isNotEmpty]) {
    if (![stli makeCallFromLocalDevice:device toDevice:call]) 
      NSLog(@"could not call device: %@", call);
  }
  
  [[NSRunLoop currentRunLoop] run];
  
  [stli stopMonitoringDevice:device];
}

@end

int main(int argc, char **argv, char **env) {
  Client *c;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  c = [[Client alloc] init];
  [c run];
  RELEASE(c);
  
  return 0;
}
