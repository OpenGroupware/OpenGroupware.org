/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "common.h"
#import <NGObjWeb/WOContext.h>

@interface LSWMailsDockView : LSWComponent
{
  BOOL           hideLink;
  NSDate         *lastCheck;
  NSTimeInterval checkInterval;
  int            count;
  
  BOOL           recheck;
}

@end /* LSWMailsDockView */

@implementation LSWMailsDockView

+ (int)version {
  return 1;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  
  if ((p = [self persistentInstance])) {
    RELEASE(self);
    return RETAIN(p);
  }

  if ((self = [super init])) {
    /* register as persistent component */
    [self registerAsPersistentInstance];

    self->checkInterval = 0.0; // 120s == 2min
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->lastCheck);
  [super dealloc];
}
#endif

- (void)awake {
  [super awake];
  self->recheck = YES;
  
  if (self->checkInterval == 0.0) {
    self->checkInterval =
      [[[self session] userDefaults] integerForKey:@"SkyMailCheckInterval"];
  }
}
- (void)sleep {
  self->recheck = NO;
  [super sleep];
}

- (void)setHideLink:(BOOL)_flag {
  self->hideLink = _flag;
}
- (BOOL)hideLink {
  return self->hideLink;
}

- (BOOL)hasNewMessages {
  LSWSession *sn;
  NSDate     *now;

  now = [NSDate date];

  if (self->lastCheck != nil) {
    if ([self->lastCheck timeIntervalSinceNow] < -(self->checkInterval))
      return NO;
  }

  if (!self->recheck)
    return self->count > 0 ? YES : NO;

  RELEASE(self->lastCheck);
  self->lastCheck = nil;

  sn = (LSWSession *)[self session];
  
  if ([sn isTransactionInProgress]) {
    BOOL result = [sn commitTransaction];

    if (!result) {
      [self logWithFormat:@"tx failed !!!"];
      [[[self context] page] takeValue:@"tx failed" forKey:@"errorString"];
    }
  }
  
  self->count =
    [[sn runCommand:@"emailfolder::count-new-messages", nil]
         intValue];

  if ([sn isTransactionInProgress])
    [sn commitTransaction];
  
  if (self->count == 0) {
    self->lastCheck = RETAIN(now);
  }
#if 0
  else
    [self logWithFormat:@"%i new messages ..", self->count];
#endif
  
  self->recheck = NO;
  
  return self->count > 0 ? YES : NO;
}

- (int)imageBorder {
  return [self hasNewMessages] ? 1 : 0;
}

@end /* LSWMailsDockView */
