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

#ifndef __SkyrixOS_SkyDocument_SkyDocument_JS_H_
#define __SkyrixOS_SkyDocument_SkyDocument_JS_H__

#include <OGoDocuments/SkyDocument.h>

/*
  supported JS properties:
  
    String     baseURL     - readonly

    bool       isReadable  - readonly
    bool       isWriteable - readonly
    bool       isRemovable - readonly
    bool       isNew       - readonly
    bool       isEdited    - readonly
  
  supported JS functions:
    
    Object     getDocumentType()
    EOGlobalID getGlobalID()
    String     getDocumentURL()
    bool       supportsFeature(feature[,...feature])

    bool       hasAttribute(attributeName)
    Object     getAttribute(attributeName)
    bool       setAttribute(attributeName, attributeValue)
    bool       removeAttribute(attributeName)
    
    bool       remove()
    bool       save()
    bool       reload()

    -> those return NO or nil if string-blobs aren't supported by the doc
    bool        setContent(String)
    String      getContent()
    
    bool        setContentAsDOM(dom)
    DOMDocument getContentAsDOM()
*/

@class NSArray;

@interface SkyDocument(JSSupport)

/* properties */

- (id)_jsprop_isReadable;
- (id)_jsprop_isWriteable;
- (id)_jsprop_isRemovable;
- (id)_jsprop_isNew;
- (id)_jsprop_isEdited;

/* functions */

- (id)_jsfunc_getDocumentType:(NSArray *)_args;
- (id)_jsfunc_getGlobalID:(NSArray *)_gids;
- (id)_jsfunc_getDocumentURL:(NSArray *)_args;
- (id)_jsfunc_supportsFeature:(NSArray *)_args;

/* attribute methods */

- (id)_jsfunc_getAttribute:(NSArray *)_args;
- (id)_jsfunc_hasAttribute:(NSArray *)_args;
- (id)_jsfunc_setAttribute:(NSArray *)_args;
- (id)_jsfunc_removeAttribute:(NSArray *)_args;

/* saving and deleting */

- (id)_jsfunc_remove:(NSArray *)_args;
- (id)_jsfunc_save:(NSArray *)_args;
- (id)_jsfunc_reload:(NSArray *)_args;

@end /* SkyDocument(JSSupport) */

#endif /* __SkyrixOS_SkyDocument_SkyDocument_JS_H__ */
