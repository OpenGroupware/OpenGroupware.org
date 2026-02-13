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

#ifndef __OGoFoundation_OGoNavigation_H__
#define __OGoFoundation_OGoNavigation_H__

#import <Foundation/NSObject.h>
#import <NGObjWeb/WOActionResults.h>

@class NSMutableArray, NSArray, NSString;
@class OGoSession, OGoContentPage;

/**
 * @class OGoNavigation
 * @brief Manages the page navigation stack in OGo.
 *
 * Tracks the user's navigation through OGo content
 * pages using an internal stack with duplicate
 * detection. Pages are pushed via enterPage: and
 * popped via leavePage. Conforms to WOActionResults
 * so it can be returned directly from action methods.
 *
 * Enable the "OGoDebugNavigation" user default for
 * debug logging.
 *
 * @see OGoContentPage
 * @see OGoSession
 */
@interface OGoNavigation : NSObject < WOActionResults >
{
@private
  OGoSession     *session; // non-retained
  struct {
    OGoContentPage **elements;
    short index;
    short count;
    short size;
  } pages;
}

- (id)initWithSession:(OGoSession *)_sn;

/* query */

- (id)activePage;
- (NSArray *)pageStack;
- (BOOL)containsPages;

/* actions */

- (void)enterPage:(id)_page;
- (id)leavePage;

@end

/**
 * @category OGoNavigation(Activation)
 * @brief Object activation via verb-based dispatch.
 *
 * Activates an object by looking up and entering the
 * appropriate viewer or editor component for the
 * given verb (e.g. "view", "edit").
 */
@interface OGoNavigation(Activation)

- (id)activateObject:(id)_object withVerb:(NSString *)_verb;

@end

/* for compatibility, to be removed */
@interface LSWNavigation : OGoNavigation
@end

#endif /* __LSWFoundation_OGoNavigation_H__ */
