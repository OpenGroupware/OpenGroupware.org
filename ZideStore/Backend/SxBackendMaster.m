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

#include "SxBackendMaster.h"
#include "common.h"

#include "SxAptManager.h"
#include "SxContactManager.h"
#include "SxTaskManager.h"

@implementation SxBackendMaster

+ (id)managerWithContext:(LSCommandContext *)_ctx {
  SxBackendMaster *master;

  if (_ctx == nil) return nil;
  
  if ((master = [_ctx valueForKey:@"SxBackendMaster"]))
    return master;
  
  if ((master = [(SxBackendMaster *)[self alloc] initWithContext:_ctx]))
    [_ctx takeValue:master forKey:@"SxBackendMaster"];
  
  return [master autorelease];
}
- (id)initWithContext:(LSCommandContext *)_ctx {
  if (_ctx == nil) {
    [self logWithFormat:@"ERROR: could not create backend master, "
            @"missing OGo command context object!"];
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->cmdctx = _ctx;
  }
  return self;
}
- (void)dealloc {
  [self->contactManager release];
  [self->taskManager    release];
  [self->aptManager     release];
  [super dealloc];
}

/* accessors */

- (LSCommandContext *)commandContext {
  return self->cmdctx;
}

- (NSString *)modelName {
  static NSString *modelName = nil;
  if (modelName == nil) {
    modelName = [[[NSUserDefaults standardUserDefaults]
		   stringForKey:@"LSModelName"] copy];
  }
  return modelName;
}

/* managers */

- (SxAptManager *)aptManager {
  if (self->aptManager == nil)
    self->aptManager = [[SxAptManager managerWithContext:self->cmdctx] retain];
  return self->aptManager;
}

- (SxContactManager *)contactManager {
  if (self->contactManager == nil) {
    self->contactManager =
      [[SxContactManager managerWithContext:self->cmdctx] retain];
  }
  return self->contactManager;
}

- (SxTaskManager *)taskManager {
  if (self->taskManager == nil) {
    self->taskManager = 
      [[SxTaskManager managerWithContext:self->cmdctx] retain];
  }
  return self->taskManager;
}

@end /* SxBackendMaster */
