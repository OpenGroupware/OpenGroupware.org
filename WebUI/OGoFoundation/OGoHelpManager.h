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
// $Id$

#ifndef __HelpUI_OGoHelpManager_H__
#define __HelpUI_OGoHelpManager_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSBundle.h>
#include <NGObjWeb/WOComponent.h>

@class NSArray, NSString, NSURL;
@class WOContext, WOComponent;

@interface OGoHelpManager : NSObject
{
  NSArray *pathes;
}

+ (id)sharedHelpManager;

/* sections */

- (NSArray *)availableSections;

/* operations */

- (NSURL *)helpURLForKey:(NSString *)_key section:(NSString *)_section
  inContext:(WOContext *)_ctx;
- (NSURL *)helpURLForComponent:(WOComponent *)_component;

- (NSString *)shortHelp:(NSString *)_name inComponent:(WOComponent *)_comp;
- (NSString *)fieldHelp:(NSString *)_name inComponent:(WOComponent *)_comp;

@end

@interface WOComponent(HelpMethods)

- (NSString *)helpKey;
- (NSString *)helpSection;

@end

@interface NSBundle(HelpMethods)

- (NSString *)helpSection;

@end

#endif /* __HelpUI_OGoHelpManager_H__ */
