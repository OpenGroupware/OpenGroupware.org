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

#ifndef __Backend_SxBackendMaster_H__
#define __Backend_SxBackendMaster_H__

#import <Foundation/NSObject.h>

/*
  SxBackendMaster

  This is a per-command-context singleton which manages and caches all the 
  different backend managers.
*/

@class LSCommandContext;
@class SxAptManager, SxContactManager, SxTaskManager;

@interface SxBackendMaster : NSObject
{
  LSCommandContext *cmdctx; /* non-retained */
  SxAptManager     *aptManager;
  SxContactManager *contactManager;
  SxTaskManager    *taskManager;
}

+ (id)managerWithContext:(LSCommandContext *)_ctx;
- (id)initWithContext:(LSCommandContext *)_ctx;

/* managers */

- (SxAptManager *)aptManager;
- (SxContactManager *)contactManager;
- (SxTaskManager *)taskManager;

@end

#endif /* __Backend_SxBackendMaster_H__ */
