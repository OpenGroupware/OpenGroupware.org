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

#ifndef __Projects_SxProjectFolder_H__
#define __Projects_SxProjectFolder_H__

#include <ZSFrontend/SxFolder.h>

/*
  SxProjectFolder

    parent-folder: SxProjectsFolder
    subobjects:    SxDocumentFolder +...
*/

@class NSString, NSException;
@class EOGlobalID;

@interface SxProjectFolder : SxFolder
{
  EOGlobalID *projectGlobalID;
  id         fileManager;
}

/* project information */

- (NSString *)projectNameKey;
- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx;
- (id)fileManagerInContext:(id)_ctx;

/* act as a common operation repository ... */

- (NSException *)moveObject:(id)_source toTarget:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx;
- (NSException *)copyObject:(id)_source toTarget:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx;

@end

#endif /* __Projects_SxProjectFolder_H__ */
