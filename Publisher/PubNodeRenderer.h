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

#ifndef __SKYNodeRenderer_H__
#define __SKYNodeRenderer_H__

#include <NGObjDOM/ODNodeRenderer.h>

@class NSString;
@class WOContext, WOResponse;
@class SkyDocument;

/*
  The common superclass of all renderers trying to render SKY tags.
*/

@interface SKYNodeRenderer : ODNodeRenderer

- (id)contextValueWithName:(NSString *)_npsname inContext:(WOContext *)_ctx;
- (SkyDocument *)_folderDocumentInContext:(WOContext *)_ctx;

- (void)addUnsupportedNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

- (id)_nextDocumentInContext:(WOContext *)_ctx;
- (id)_previousDocumentInContext:(WOContext *)_ctx;
- (id)_parentDocumentInContext:(WOContext *)_ctx;

@end

#endif /* __SKYNodeRenderer_H__ */
