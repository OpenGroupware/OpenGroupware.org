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

#include "WOComponent+Navigation.h"
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/OGoSession.h>
#include "common.h"

@implementation WOComponent(Navigation)

- (void)enterPage:(id)_page {
  [[(OGoSession *)[self session] navigation] enterPage:_page];
}
- (id)leavePage {
  return (id)[[(OGoSession *)[self session] navigation] leavePage];
}

- (id)backWithCount:(int)_numberOfPages {
  /* leave page _numberOfPages times */
  OGoNavigation *nav;
  
  nav = [(OGoSession *)[self session] navigation];
  
  while (_numberOfPages > 0) {
    [nav leavePage];
    _numberOfPages--;
  }
  return [nav activePage];
}

- (id)back {
  return [self backWithCount:1];
}

/* activation */

- (id)activateObject:(id)_object withVerb:(NSString *)_verb {
  OGoNavigation *nav;
  
  nav = [(OGoSession *)[self session] navigation];
  
  return [nav activateObject:_object withVerb:_verb];
}

@end /* WOComponent(Navigation) */
