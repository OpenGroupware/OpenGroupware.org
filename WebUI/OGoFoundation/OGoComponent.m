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

#include "OGoComponent.h"
#include "OGoConfigHandler.h"
#include "LSWLabelHandler.h"
#include "common.h"
#include "OGoSession.h"

@implementation OGoComponent

static BOOL debugOn = NO;

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (id)init {
  if ((self = [super init])) {
    [[self notificationCenter]
      addObserver:self selector:@selector(resetSession:)
      name:@"OGoSessionFinalizing" object:[self session]];
  }
  return self;
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  [self->labelHandler  release];
  [self->configHandler release];
  [super dealloc];
}

- (void)resetSession:(NSNotification *)_notification {
  self->session     = nil;
  self->application = nil;
  self->context     = nil;
}

/* notifications */

- (void)syncAwake {
  if (debugOn) [self debugWithFormat:@"%@ ..", NSStringFromSelector(_cmd)];
}
- (void)syncSleep {
  if (debugOn) [self debugWithFormat:@"%@ ..", NSStringFromSelector(_cmd)];
}

- (void)_ensureSyncAwake {
  if (self->lswComponentFlags.isAwake == 0) {
    [self syncAwake];
    self->lswComponentFlags.isAwake = 1;
  }
}

- (void)sleep {
  [self syncSleep];
  self->lswComponentFlags.isAwake = 0;
  
#if 0
  [self->configHandler release]; self->configHandler = nil;
  [self->labelHandler  release]; self->labelHandler = nil;
#endif
}

/* config stuff */

- (id)config {
  if (self->configHandler == nil)
    self->configHandler = [[OGoConfigHandler alloc] initWithComponent:self];
  return self->configHandler;
}

- (id)labels {
  if (self->labelHandler == nil) {
    self->labelHandler =
      [[LSWLabelHandler alloc] initWithComponent:self];
  }
  return self->labelHandler;
}

/* responder */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  if (self->lswComponentFlags.isAwake == 0) {
    [self syncAwake];
    self->lswComponentFlags.isAwake = 1;
  }
  [super takeValuesFromRequest:_rq inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  if (self->lswComponentFlags.isAwake == 0) {
    [self syncAwake];
    self->lswComponentFlags.isAwake = 1;
  }
  return [super invokeActionForRequest:_rq inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  if (self->lswComponentFlags.isAwake == 0) {
    [self syncAwake];
    self->lswComponentFlags.isAwake = 1;
  }
  [super appendToResponse:_r inContext:_ctx];
}

/* pages */

- (WOComponent *)pageWithName:(NSString *)_name {
  /* support for persistent components */
  OGoSession *sn;
  id         p;
  
  if ((sn = (OGoSession *)[self session]) != nil) {
    if ((p = [[sn pComponents] valueForKey:_name]) != nil) {
      [p ensureAwakeInContext:[self context]];
      return p;
    }
  }
  return [super pageWithName:_name];
}

@end /* OGoComponent */
