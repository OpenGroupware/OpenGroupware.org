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

#ifndef __LSWebInterface_LSWFoundation_LSWTreeState_H__
#define __LSWebInterface_LSWFoundation_LSWTreeState_H__

#include <Foundation/NSObject.h>
#include <OGoFoundation/WOComponent+Commands.h>

/**
 * @class LSWTreeState
 * @brief Tracks expand/collapse state of tree UI nodes.
 *
 * Maintains a dictionary mapping tree node paths to
 * their expanded/collapsed boolean state. The current
 * node path is resolved dynamically via KVC on the
 * associated component using the configured path key.
 * State can be persisted to and restored from user
 * defaults.
 *
 * @see OGoContentPage
 */
@interface LSWTreeState : NSObject
{
@protected
  WOComponent         *object;        /* non-retained */
  NSString            *pathKey;
  NSMutableDictionary *map;
  BOOL                defaultState;
}

- (id)initWithObject:(id)_object pathKey:(NSString *)_pathKey;

- (BOOL)isExpanded;
- (void)setIsExpanded:(BOOL)_flag;
- (BOOL)defaultState;
- (void)setDefaultState:(BOOL)_flag;
- (NSString *)currentPath;


// --- user default managment --------------------

- (void)read:(NSString *)_name;
- (void)write:(NSString *)_name;

@end

#endif /* __LSWebInterface_LSWFoundation_LSWTreeState_H__ */
