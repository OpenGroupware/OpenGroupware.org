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

#ifndef __WebUI_LSWMail_LSWMailEditor_H__
#define __WebUI_LSWMail_LSWMailEditor_H__

#include <OGoFoundation/OGoContentPage.h>
#include <OGoFoundation/LSWMailEditorComponent.h>

@class NGMimeMessage, NGMimeType;

@interface LSWMailEditor : OGoContentPage < LSWMailEditorComponent >
{
@protected
  NSMutableArray *addresses;
  NSMutableArray *mimeParts;
  NSDictionary   *addressEntry;
  NSString       *searchString;
  NSArray        *addressKeys;
  NSString       *mailText;
  NSString       *mailSubject;  
  unsigned       count;
  id             item;
  NSMutableArray *attachments;
  id             attachment;
  int            attachmentIdx;
  id             addressEntryPopupItem;
  BOOL           sendPlainText;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg;

/* actions */
- (id)addAddress;
- (id)send;
- (id)cancel;

/* accessors */

- (void)setSubject:(NSString *)_subject;
- (void)setContent:(NSString *)_content;

/* addresses */

- (void)addReceiver:(id)_person type:(NSString *)_rcvType;
- (void)addReceiver:(id)_person; // type == "to"

/* attachements */

- (void)addAttachment:(id)_object type:(NGMimeType *)_type;
- (void)addAttachment:(id)_object; // type=[_obj mimeType]

@end

#endif /* __WebUI_LSWMail_LSWMailEditor_H__ */
