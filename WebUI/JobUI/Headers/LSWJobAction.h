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

#ifndef __OGo_JobUI_LSWJobAction_H__
#define __OGo_JobUI_LSWJobAction_H__

#include <OGoFoundation/LSWViewerPage.h>

@class NSDictionary, NSString, NSArray, NSNumber; 

@interface LSWJobAction : LSWViewerPage
{
@private
  NSArray      *jobHierarchy;
  NSDictionary *selectedAttribute;   
  NSNumber     *jobId;
  NSNumber     *userId;
  NSString     *tabKey;
  NSString     *comment;
  NSString     *action;
  id           subJob;
  id           item;
  id           job;
  id           jobHistory;  
  int          startIndex;
  int          cntJobHierarchy;
  int          repIdx;
  BOOL         isDescending;
}

- (id)job;

- (id)jobCreatorEO;
- (NSNumber *)jobCreatorId;
- (BOOL)isJobCreatorLoginAccount;

@end

#endif /* __OGo_JobUI_LSWJobAction_H__ */
