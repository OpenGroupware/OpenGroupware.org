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

#ifndef __OGoWebMail_LSWPartBodyViewer_H__
#define __OGoWebMail_LSWPartBodyViewer_H__

#include <OGoFoundation/OGoComponent.h>
#import <NGObjWeb/WOSession.h>

@class NGMimeType;

@interface LSWPartBodyViewer : OGoComponent
{
  id   body;
  id   partOfBody;
  int  nestingDepth;
  BOOL printMode;
  id   source;
}

- (id)activateObject:(id)_obj verb:(NSString *)_verb type:(NGMimeType *)_type;

- (NSDictionary *)bodyDescription;

- (void)setBody:(id)_body;
- (id)body;

- (BOOL)isDownloadable;

- (void)setPartOfBody:(id)_part;
- (id)partOfBody;

- (BOOL)printMode;
- (void)setPrintMode:(BOOL)_print;

- (NSString *)encoding;
- (id)source;

@end

@interface LSWTextPlainBodyViewer : LSWPartBodyViewer
{
@private
  id item;
}

@end

@class NGMimeType;

@interface LSWImageBodyViewer : LSWPartBodyViewer
{
  NGMimeType *mimeType;
}
@end

@interface LSWInlineBodyViewer : LSWPartBodyViewer
@end

@interface LSWAppOctetBodyViewer : LSWPartBodyViewer
@end

@interface LSWMultipartBodyViewer : LSWPartBodyViewer
{
@protected
  id      currentPart;
}

- (NSArray *)parts;

- (void)setCurrentPart:(id)_part;
- (id)currentPart;

- (WOComponent *)currentPartViewerComponent;

@end

@interface LSWMultipartMixedBodyViewer : LSWMultipartBodyViewer
@end

@interface LSWMultipartAlternativeBodyViewer : LSWMultipartBodyViewer
{
  id part;
}
@end

@interface LSWEnterpriseObjectBodyViewer : LSWPartBodyViewer
@end
#endif /* __OGoWebMail_LSWPartBodyViewer_H__ */
