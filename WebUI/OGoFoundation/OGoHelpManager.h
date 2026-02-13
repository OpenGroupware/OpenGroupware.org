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

#ifndef __HelpUI_OGoHelpManager_H__
#define __HelpUI_OGoHelpManager_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSBundle.h>
#include <NGObjWeb/WOComponent.h>

@class NSArray, NSString, NSURL;
@class WOContext, WOComponent;

/**
 * @class OGoHelpManager
 * @brief Singleton that resolves help URLs and tooltip
 *        strings for OGo components.
 *
 * Searches the filesystem for installed OGo documentation
 * in standard Library/Documentation paths. Provides help
 * URL generation for components and named keys within
 * sections, as well as short and field-level help text
 * lookups.
 *
 * @see WOComponent(HelpMethods)
 * @see NSBundle(HelpMethods)
 */
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

/**
 * @category WOComponent(HelpMethods)
 * @brief Help-related convenience methods for
 *        WOComponent.
 *
 * Returns the help key (defaults to the class name) and
 * help section (derived from the bundle) for use with
 * OGoHelpManager URL generation.
 */
@interface WOComponent(HelpMethods)

- (NSString *)helpKey;
- (NSString *)helpSection;

@end

/**
 * @category NSBundle(HelpMethods)
 * @brief Help section lookup for NSBundle.
 *
 * Returns the help section name for a bundle, derived
 * from the bundle path or its principal class.
 */
@interface NSBundle(HelpMethods)

- (NSString *)helpSection;

@end

#endif /* __HelpUI_OGoHelpManager_H__ */
