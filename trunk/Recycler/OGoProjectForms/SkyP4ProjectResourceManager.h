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

#ifndef __SkyP4ProjectResourceManager_H__
#define __SkyP4ProjectResourceManager_H__

#include <NGObjWeb/WOResourceManager.h>

@class NSMutableDictionary;
@class SkyP4ViewerFormComponent;

@interface SkyP4ProjectResourceManager : WOResourceManager
{
  SkyP4ViewerFormComponent *formComponent; // non-retained
  WOResourceManager *parentRM;

  NSMutableDictionary *cache;
}

- (id)initWithFormComponent:(SkyP4ViewerFormComponent *)_form;

@end

#endif /* __SkyP4ProjectResourceManager_H__ */
