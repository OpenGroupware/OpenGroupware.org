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

#include "common.h"

@implementation WODirectAction(SkyDockActions)

- (id<WOActionResults>)activePageAction {
  WOSession   *sn;
  WOComponent *page;
  
  if ((sn = [self existingSession]) == nil) {
    [self logWithFormat:@"no session is active for action!"];
    return [self pageWithName:@"Main"];
  }
  if ((page = [[sn navigation] activePage]) == nil) {
    [self logWithFormat:@"no active page?! returning main page."];
    return [self pageWithName:@"Main"];
  }
  [page ensureAwakeInContext:[self context]];
  return page;
}
- (id<WOActionResults>)leavePageAction {
  WOSession   *sn;
  WOComponent *page;
  
  if ((sn = [self existingSession]) == nil) {
    [self logWithFormat:@"no session is active for action !"];
    return [self pageWithName:@"Main"];
  }
  if ((page = [[sn navigation] leavePage]) == nil) {
    [self logWithFormat:
            @"no page left in the navigation?! returning active page"];
    return [self activePageAction];
  }
  [page ensureAwakeInContext:[self context]];
  return page;
}

- (id<WOActionResults>)dockAction {
  WOSession   *sn;
  NSString    *pageName;
  WOComponent *page;
  
  if ((pageName = [[self request] formValueForKey:@"page"]) == nil) {
    NSString *dockKey;

    if ((dockKey = [[self request] formValueForKey:@"key"]) == nil)
      [self logWithFormat:@"missing page parameter in dock action!"];
    else {
      // TODO: lookup pageName by 'dockable page name' (key)
      [self errorWithFormat:@"'key' form parameter not yet implemented!"];
    }
    return [self pageWithName:@"Main"];
  }

  if ((sn = [self existingSession]) == nil) {
    [self logWithFormat:@"no session is active for dock action !"];
    return [self pageWithName:@"Main"];
  }

  if ((page = [self pageWithName:pageName]) == nil) {
    [self logWithFormat:@"couldn't create page %@", pageName];
    return nil;
  }
  [[sn navigation] enterPage:page];
  return page;
}

@end /*  WODirectAction(SkyDockActions) */
