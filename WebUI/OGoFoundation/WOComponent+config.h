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

#ifndef __LSWebInterface_LSWFoundation_WOComponent_config_H__
#define __LSWebInterface_LSWFoundation_WOComponent_config_H__

#import <NGObjWeb/WOComponent.h>

/**
 * @category WOComponent(LSOfficeConfig)
 * @brief Configuration and label access for
 *        components.
 *
 * Provides access to the component's configuration
 * handler and label handler, with convenience methods
 * for looking up localized label strings by key.
 *
 * @see OGoConfigHandler
 * @see LSWLabelHandler
 */
@interface WOComponent(LSOfficeConfig)

- (id)config;
- (id)labels;
- (BOOL)isComponent; // YES

/*
  these methods does roughly the following:

    [[[self config] valueForKey:@"labels"] valueForKey:_key]

  .. to be changed.
*/
- (NSString *)labelForKey:(NSString *)_key;
- (NSString *)labelForKey:(NSString *)_key defaultKey:(NSString *)_defKey;
- (BOOL)hasLabelForKey:(NSString *)_key;

@end

/**
 * @category WOElement(LSOfficeConfig)
 * @brief Distinguishes elements from components.
 *
 * Returns NO for isComponent, allowing code to
 * distinguish between WOElement and WOComponent.
 */
@interface WOElement(LSOfficeConfig)

- (BOOL)isComponent; // NO

@end

#endif /* __LSWebInterface_LSWFoundation_WOComponent_config_H__ */
