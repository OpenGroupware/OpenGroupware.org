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

#ifndef __SxTaskFolder_H__
#define __SxTaskFolder_H__

#include <ZSFrontend/SxFolder.h>

// TODO: detect the parent folder to determine the scope !
//   group => group todos
//   home  => home  todos

@class NSString;
@class SxTaskManager;

@interface SxTaskFolder : SxFolder
{
  NSString *type;  /* todo, delegated, archived */
  NSString *group; /* group or nil */
  // add: include-self
  
  /* caches */
  NSString *idsAndVersions;
  int      contentCount;
}

/* accessors */

- (NSString *)group;
- (NSString *)type;

- (SxTaskManager *)taskManagerInContext:(id)_ctx;

@end /* SxTaskFolder */

#endif /* __SxTaskFolder_H__ */
