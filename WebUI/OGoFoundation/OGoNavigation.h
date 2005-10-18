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

/*
  OGoNavigation
  
  This objects tracks the navigation through OGo. It does some clever detection
  of duplicates (TODO: document).
  
  You can debug operation by enabling the 'OGoDebugNavigation' bool default.
  
  TODO: explain more.
*/

@class NSMutableArray, NSArray, NSString;
@class OGoSession, OGoContentPage;

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

@interface OGoNavigation(Activation)

- (id)activateObject:(id)_object withVerb:(NSString *)_verb;

@end

/* for compatibility, to be removed */
@interface LSWNavigation : OGoNavigation
@end

#endif /* __LSWFoundation_OGoNavigation_H__ */
