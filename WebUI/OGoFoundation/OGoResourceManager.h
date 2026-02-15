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

#ifndef __OGoFoundation_OGoResourceManager_H__
#define __OGoFoundation_OGoResourceManager_H__

#import <NGObjWeb/OWResourceManager.h>

@class NSArray, NSMutableDictionary;
@class OGoStringTableManager, OGoResourceKey;

/**
 * @class OGoResourceManager
 * @brief Custom resource manager for locating OGo
 *        templates, web resources, and localized strings.
 *
 * Extends the SOPE OWResourceManager to search OGo-
 * specific directory layouts (GNUstep and FHS) for
 * components, WebServerResources, and string tables.
 * Supports theme-based template overrides and caches
 * lookup results for component paths, resource paths,
 * and resource URLs. Also provides localized label
 * lookups via the OGoStringTableManager.
 *
 * @see OWResourceManager
 * @see OGoStringTableManager
 * @see OGoResourceKey
 */
@interface OGoResourceManager : OWResourceManager
{
@private
  NSMutableDictionary   *keyToComponentPath;
  NSMutableDictionary   *keyToURL;
  NSMutableDictionary   *keyToPath;
  OGoStringTableManager *labelManager;
  OGoResourceKey        *cachedKey;
}

+ (NSArray *)rootPathesInGNUstep; /* GNUSTEP_PATHLIST */
+ (NSArray *)rootPathesInFHS;     /* /usr/local, /usr */
+ (NSArray *)availableOGoThemes;

@end

#endif /* __OGoFoundation_OGoResourceManager_H__ */
