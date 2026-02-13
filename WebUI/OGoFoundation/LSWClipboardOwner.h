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

#ifndef __OGoFoundation_LSWClipboardOwner_H__
#define __OGoFoundation_LSWClipboardOwner_H__

#include <Foundation/NSObject.h>

@class WOSession;

/**
 * @class LSWClipboardOwner
 * @brief Owner object for the OGo session clipboard
 *        pasteboard.
 *
 * Acts as the pasteboard owner in the OWPasteboard
 * protocol, providing data on demand when the pasteboard
 * contents are requested. Used internally by
 * OGoSession+Clipboard to manage clipboard ownership
 * and lazy data provision.
 *
 * @see OWPasteboard
 * @see OGoClipboard
 */
@interface LSWClipboardOwner : NSObject
{
  WOSession *session; // non-retained;
  id object;
}

+ (id)clipboardOwnerForSession:(WOSession *)_session;
+ (id)clipboardOwnerForSession:(WOSession *)_session object:(id)_object;

@end

#endif /* __OGoFoundation_LSWClipboardOwner_H__ */
