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

#ifndef __WebUI_OGoFoundation_OGoConfigHandler_H__
#define __WebUI_OGoFoundation_OGoConfigHandler_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class WOComponent;

/**
 * @class OGoConfigHandler
 * @brief Caching proxy for per-component configuration
 *        value lookups.
 *
 * Provides KVC-based access to configuration values for
 * a WOComponent. On first access for a given key, the
 * value is fetched from the session's configuration
 * system and then cached in an internal hash table for
 * fast repeated lookups. Used as the backing object for
 * the 'config' binding in OGo component templates.
 *
 * @see LSWLabelHandler
 * @see WOComponent(OGoConfig)
 */
@interface OGoConfigHandler : NSObject
{
@protected
  WOComponent *component; // non-retained

@private
  /* hash-table */
  struct _NSMapNode  **nodes;
  unsigned int       hashSize;
  unsigned int       itemsCount;
}

- (id)initWithComponent:(WOComponent *)_component;

- (id)valueForKey:(NSString *)_key;

@end

#endif /* __WebUI_OGoFoundation_OGoConfigHandler_H__ */
