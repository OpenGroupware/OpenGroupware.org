/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#ifndef __Tasks_SxDavTaskAction_H__
#define __Tasks_SxDavTaskAction_H__

#include <ZSFrontend/SxDavAction.h>

/*
  SxDavTaskAction
  
  Common superclass for SxDavTaskChange and SxDavTaskCreate.
  
  TODO:
    x0037001E davDisplayName [subject?] TestJob edited
    x0070001E threadTopic               TestJob
    x0E1D001E subject                   TestJob
    x3001001E davDisplayName [uid??]    TestJob
*/

@class NSString, NSNumber, NSDictionary;
@class SxTask;

@interface SxDavTaskAction : SxDavAction
{
}

- (id)initWithName:(NSString *)_name properties:(NSDictionary *)_props
  forTask:(SxTask *)_task;

- (SxTask *)task;

- (NSString *)sxStatusForCompletion:(int)_percent;
/* processors */

// check whether a recurring task is requested
- (BOOL)checkRecurring;

// get the priority out of the properties
- (id)getPriority;
// get the task title out of the properties
- (NSString *)getName;

@end

#endif /* __Tasks_SxDavTaskAction_H__ */
