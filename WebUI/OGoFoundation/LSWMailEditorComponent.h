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

#ifndef __OGoFoundation_LSWMailEditorComponent_H__
#define __OGoFoundation_LSWMailEditorComponent_H__

#include <OGoFoundation/OGoContentPage.h>

@class NSString;
@class NGMimeType;
@class NSNumber;

/**
 * @protocol LSWMailEditorComponent
 * @brief Protocol for composing and sending email from
 *        OGo pages.
 *
 * Defines the interface for mail editor components that
 * can set a subject, content body (with or without
 * signature), add receivers and attachments, configure
 * template bindings, and send the composed message.
 * Conforms to the OGoContentPage protocol.
 *
 * @see OGoContentPage
 */
@protocol LSWMailEditorComponent < OGoContentPage >

- (void)setSubject:(NSString *)_subject;
- (void)setContent:(NSString *)_content;

/* set content by adding mail-signature */

- (void)setContentWithoutSign:(NSString *)_content;
// addresses

- (void)addReceiver:(id)_person type:(NSString *)_rcvType;
- (void)addReceiver:(id)_person; // type == "to"

// attachements

- (void)addAttachment:(id)_obj type:(NGMimeType *)_type
        sendObject:(NSNumber *)_send;
- (void)addAttachment:(id)_object type:(NGMimeType *)_type;
- (void)addAttachment:(id)_object; // type=[_obj mimeType]

- (void)setBindingDictionary:(NSDictionary *)_dict;
- (void)setBindingLabels:(id)_labels;

- (id)send;

@end

#endif /* __OGoFoundation_LSWMailEditorComponent_H__ */
