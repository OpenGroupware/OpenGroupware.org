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

#ifndef __LSFoundation_LSTypeManager_H__
#define __LSFoundation_LSTypeManager_H__

#import <Foundation/NSObject.h>

@class NSArray;
@class EOGlobalID, EOClassDescription;
@class LSCommandContext;

/**
 * @protocol LSTypeManager
 * @brief Resolves entity names and global IDs for objects.
 *
 * The LSTypeManager protocol provides methods to
 * determine the entity name for a given object or
 * EOGlobalID, and to convert primary keys into
 * EOGlobalIDs. It is used throughout the Logic layer
 * for type introspection and GID resolution.
 *
 * @see LSCommandContext
 */
@protocol LSTypeManager

/* entity names */

- (NSArray *)entityNamesForObjects:(NSArray *)_objects;
- (NSArray *)entityNamesForGlobalIDs:(NSArray *)_gids;
- (NSString *)entityNameForObject:(id)_object;
- (NSString *)entityNameForGlobalID:(EOGlobalID *)_globalId;

/*
  this is for *backwards* compatibility only, you should use EOGlobalID's
  wherever possible
*/
- (EOGlobalID *)globalIDForPrimaryKey:(id)_pkey;
- (NSArray *)globalIDsForPrimaryKeys:(NSArray *)_pkeys;

@end

#endif /* __LSFoundation_LSTypeManager_H__ */
