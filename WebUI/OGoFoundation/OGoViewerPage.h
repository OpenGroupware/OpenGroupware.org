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

#ifndef __OGoFoundation_OGoViewerPage_H__
#define __OGoFoundation_OGoViewerPage_H__

#include <OGoFoundation/OGoContentPage.h>

/* should inherit from OGoContentPage in the long run ..*/
/**
 * @class OGoViewerPage
 * @brief Base class for read-only object viewer pages.
 *
 * Displays a single object in a detail view. Provides
 * actions to place the object in the clipboard and to
 * switch to the corresponding editor. Supports
 * duplicate detection through isViewerForSameObject:.
 *
 * @see OGoContentPage
 * @see SkyEditorPage
 */
@interface OGoViewerPage : LSWContentPage
{
@protected
  NSString *activationCommand;
  id       object;
}

/* accessors */

- (void)setObject:(id)_object;
- (id)object;

/* actions */

- (id)placeInClipboard;
- (id)edit;

/* navigation */

- (BOOL)isViewerForSameObject:(id)_object;

@end

/**
 * @category OGoContentPage(Viewing)
 * @brief Default implementation of same-object check.
 *
 * Always returns NO; OGoViewerPage overrides this
 * to compare against its current object.
 */
@interface OGoContentPage(Viewing)
- (BOOL)isViewerForSameObject:(id)_object; // always returns NO
@end

/* for compatibility, to be removed */
@interface LSWViewerPage : OGoViewerPage
@end

#endif /* __OGoFoundation_OGoViewerPage_H__ */
