/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

  This file is part of OpenGroupware.org

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

#ifndef __SkyDocumentIdHandler_H__
#define __SkyDocumentIdHandler_H__

#import <Foundation/NSObject.h>

/*
  SkyDocumentIdHandler
  
  TODO: describe what it does.
*/

@class EOGlobalID;

@interface SkyDocumentIdHandler : NSObject
{
  int *documents;
  int *projects;
  int itemCnt;
  int itemSize;
  int maxId;
  int minId;
}

+ (id)handlerWithContext:(id)_ctx;

/* lookup IDs */

- (EOGlobalID *)projectGIDForDocumentGID:(EOGlobalID *)_gid context:(id)_ctx;

/* reset caches */

- (void)resetData;

@end

#endif /* __SkyDocumentIdHandler_H__ */
