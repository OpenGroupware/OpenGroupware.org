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

#ifndef __OGoFoundation_LSWModuleManager_H__
#define __OGoFoundation_LSWModuleManager_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSString, NSArray, NSMutableDictionary;
@class WOComponent;

/**
 * @class OGoModuleManager
 * @brief Manages loading and initialization of OGo bundle
 *        plugins.
 *
 * Acts as a bundle load notification handler for the
 * NGBundleManager. When a bundle is loaded, the module
 * manager registers its default settings from
 * Defaults.plist and ensures that classes provided by
 * the bundle are initialized via the +initialize method.
 *
 * @see NGBundleManager
 */
@interface OGoModuleManager : NSObject
{
}

@end

/**
 * @class LSWModuleManager
 * @brief Deprecated alias for OGoModuleManager.
 *
 * @deprecated Use OGoModuleManager.
 * @see OGoModuleManager
 */
@interface LSWModuleManager : OGoModuleManager
@end

#endif /* __OGoFoundation_LSWModuleManager_H__ */
