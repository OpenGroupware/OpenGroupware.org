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

#ifndef __OGoFoundation_OGoObjectMailPage_H__
#define __OGoFoundation_OGoObjectMailPage_H__

#include <OGoFoundation/OGoComponent.h>

@class NSDictionary, NSString, NSCalendarDate, NSData;
@class NGMimeType, NGMimeContentDispositionHeaderField;
@class EOGlobalID;

@interface OGoObjectMailPage : OGoComponent
{
@protected
  id   object;
  id   body;
  id   partOfBody;
  BOOL inlineLink;
  BOOL showDirectActionLink;
  BOOL isInForm;
  BOOL attachData;
}

- (void)setGlobalID:(EOGlobalID *)_gid;
- (void)setObject:(id)_obj;
- (id)object;

/* hooks for subclasses */

- (NSString *)entityName;
- (NSString *)getCmdName;
- (NSData *)objectData;
- (NGMimeType *)objectDataType;
- (NGMimeContentDispositionHeaderField *)objectDataContentDisposition;
- (NSString *)objectUrlKey;
- (id)viewObject;

/* accessors */

- (void)setInlineLink:(BOOL)_lnk;
- (void)setShowDirectActionLink:(BOOL)_lnk;
- (void)setIsInForm:(BOOL)_form;
- (void)setAttachData:(BOOL)_data;

@end

#endif /* __OGoFoundation_OGoObjectMailPage_H__ */
