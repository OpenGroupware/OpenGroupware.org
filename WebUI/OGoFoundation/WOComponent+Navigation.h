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

#ifndef __LSWebInterface_LSWFoundation_WOComponent_Navigation_H__
#define __LSWebInterface_LSWFoundation_WOComponent_Navigation_H__

#include <NGObjWeb/WOComponent.h>
#include <OGoFoundation/LSWContentPage.h>

/**
 * @category WOComponent(Navigation)
 * @brief Page navigation convenience methods.
 *
 * Delegates to the session's OGoNavigation to push
 * and pop content pages, navigate back by a given
 * count, and activate objects with a verb.
 *
 * @see OGoNavigation
 * @see OGoContentPage
 */
@interface WOComponent(Navigation)

- (void)enterPage:(id)_page;
- (id)leavePage;

- (id)backWithCount:(int)_numberOfPages;
- (id)back;

/* activation */

- (id)activateObject:(id)_object withVerb:(NSString *)_verb;

@end

#endif /* __LSWebInterface_LSWFoundation_WOComponent_Navigation_H__ */
