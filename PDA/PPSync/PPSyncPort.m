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
// $Id$

#include "PPSyncPort.h"
#include "PPSyncContext.h"
#include "common.h"

NSString *PPSynchronizePDANotificationName = @"PPSynchronizePDANotification";

@implementation PPSyncPort

static PPSyncPort *defaultPort = nil;

+ (id)defaultPilotSyncPort {
  if (defaultPort == nil)
    defaultPort = [[PPSyncPort alloc] init];
  return defaultPort;
}
#if !defined(__APPLE__)
- (id)init {
  struct pi_sockaddr piaddr;
  
  //if ((self->sd = pi_socket(PI_AF_SLP, PI_SOCK_STREAM, PI_PF_PADP)) <= 0) {
  if ((self->sd = pi_socket(PI_AF_PILOT, PI_SOCK_STREAM, PI_PF_PADP)) <= 0) {
    RELEASE(self); self = nil;
    [NSException raise:@"PPSocketException"
                 format:@"Couldn't setup pi_socket: %s", strerror(errno)];
  }
  
  /* address for local IP port for Network HotSync */
  piaddr.pi_device[0] = '.';
  piaddr.pi_device[1] = '\0';
  //piaddr.pi_family    = PI_AF_SLP;
  piaddr.pi_family    = PI_AF_PILOT;

  if (pi_bind(self->sd, (void*)&piaddr, sizeof(piaddr)) < 0) {
    RELEASE(self); self = nil;
    [NSException raise:@"PPSocketException"
                 format:@"Couldn't bind socket to '.': %s", strerror(errno)];
  }

  /* listen */

  if (pi_listen(self->sd, 1) < 0) {
    RELEASE(self); self = nil;
    [NSException raise:@"PPSocketException"
                 format:@"Couldn't listen on socket '.': %s", strerror(errno)];
  }

  self->pisock = find_pi_socket(self->sd);
  self->fsd    = ((struct pi_socket *)self->pisock)->sd;

  [[NSNotificationCenter defaultCenter]
                         addObserver:self selector:@selector(accept:)
                         name:NSFileObjectBecameActiveNotificationName
                         object:nil];
  [[NSRunLoop currentRunLoop]
              addFileObject:self
              activities:NSPosixReadableActivity
              forMode:NSDefaultRunLoopMode];
  
  return self;
}

- (void)dealloc {
  [[NSRunLoop currentRunLoop]
              removeFileObject:self
              forMode:NSDefaultRunLoopMode];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (self->sd != -1)
    pi_close(self->sd);
  [super dealloc];
}

/* accessors */

- (int)fileDescriptor {
  return self->fsd;
}

/* notifications */

- (void)accept {
  [self accept:nil];
}

- (void)accept:(NSNotification *)_notification {
  int csd;
  PPSyncContext *ctx;
  NSAutoreleasePool *pool;
  
  if ((csd = pi_accept(self->sd, 0, 0)) < 0) {
    NSLog(@"%@: Couldn't accept client socket ..", self);
    return;
  }

  pool = [[NSAutoreleasePool alloc] init];
  
  ctx = [[PPSyncContext alloc] initWithDescriptor:csd];
  AUTORELEASE(ctx);

  NSLog(@"preparing context ..");
  [ctx prepare];

  NSLog(@"start sync ..");
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:PPSynchronizePDANotificationName
                         object:ctx];

  NSLog(@"finishing context ..");
  [ctx finish];

  RELEASE(pool); pool = nil;
}

#endif
@end /* PPSyncPort */
