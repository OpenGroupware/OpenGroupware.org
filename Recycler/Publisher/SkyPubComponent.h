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

#ifndef __SkyPubComponent_H__
#define __SkyPubComponent_H__

#include <NGObjWeb/WOComponent.h>

/*
  The component class for SkyPublisher documents/templates.
*/

@class NSMutableArray;
@class WOResourceManager;
@class SkyPubLinkManager, SkyPubFileManager, SkyDocument;

@interface SkyPubComponent : WOComponent
{
  SkyPubFileManager *fileManager;
  SkyDocument       *document;
  SkyPubLinkManager *linkManager;
  BOOL              isTemplate;
  WOResourceManager *rm;
  WOElement         *template;
  
  /* JavaScript eval */
  id   shadow;
  BOOL didEvaluate;

  /* cursor stack (so that we do not need to store it in the shadow */
  NSMutableArray *cursorStack;
}

- (id)initWithFileManager:(SkyPubFileManager *)_fm
  document:(SkyDocument *)_doc;

/* accessors */

- (SkyPubFileManager *)fileManager;
- (SkyDocument *)document;
- (SkyDocument *)componentDocument;
- (SkyPubLinkManager *)linkManager;

- (void)setResourceManager:(WOResourceManager *)_rm;

- (void)setIsTemplate:(BOOL)_flag;
- (BOOL)isTemplate;

@end

#endif /* __SkyPubComponent_H__ */
