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
#include "AsteriskConnection.h"

@interface Client : NSObject
{
  AsteriskConnection *asterisk;
}
- (void)run; 

@end

#include "common.h"

@implementation Client

- (id)init {
  self->asterisk = [[AsteriskConnection alloc] init];
  [[self->asterisk notificationCenter]
               addObserver:self selector:@selector(asteriskEvent:)
               name:nil object:self->asterisk];
  return self;
}
- (void)dealloc {
  [[self->asterisk notificationCenter]
               removeObserver:asterisk];
  RELEASE(self->asterisk);
  [super dealloc];
}

- (void)asteriskEvent:(NSNotification *)_event {
  NSLog(@"Asterisk: %@", _event);
}

- (void)run {
  NSUserDefaults *ud;
  NSString *device;
  NSString *call;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  device = [ud stringForKey:@"device"];
  call   = [ud stringForKey:@"call"];
  
  if (![asterisk loginToAsterisk]) {
    NSLog(@"couldn't login to Asterisk '%@' ...", device);
    exit(1);
  }
  NSLog(@"I am able to login to the asterisk '%@' ..", device);
  
  if ([call isNotEmpty]) {
    if (![asterisk makeCallTo:call fromDevice:device]) 
      NSLog(@"could not call device: %@", call);
  }
  
  [[NSRunLoop currentRunLoop] run];
  
  [asterisk bye];
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
