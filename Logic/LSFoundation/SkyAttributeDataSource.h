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

#ifndef __LSFoundation_SkyAttributeDataSource_H__
#define __LSFoundation_SkyAttributeDataSource_H__

#import <EOControl/EODataSource.h>

@class NSSet, NSMutableDictionary, NSString;
@class EOFetchSpecification, EODataSource;

/**
 * @class SkyAttributeDataSource
 * @brief DataSource that merges extended properties into
 *        fetched objects.
 *
 * SkyAttributeDataSource wraps a "primary" EODataSource
 * and augments its fetched objects with extended
 * attributes from SkyObjectPropertyManager. Qualifiers
 * on the fetch specification may reference both regular
 * database keys and namespaced property keys.
 *
 * Fetch specification hints:
 * - restrictionQualifierString
 * - restrictionPrimaryKeyName
 * - restrictionEntityName (--> look at SkyObjectPropertyManager.h)
 * - namespaces (NSSet of property namespaces)
 *
 * @see SkyObjectPropertyManager
 * @see EODataSource
 */
@interface SkyAttributeDataSource : EODataSource
{
@protected
  id                   context;
  EOFetchSpecification *fetchSpecification;
  NSSet                *namespaces;
  EODataSource         *source;
  NSMutableDictionary  *_gid2ObjCache;
  NSString             *globalIdKey;
  BOOL                 verifyIds;
  NSArray              *dbKeys;
  NSString             *defaultNamespace;
  NSMutableDictionary  *_evaluateAttributeQualifierCache;
  NSMutableDictionary  *_evaluateDBQualifierCache;
  NSMutableDictionary  *_evaluateQualifierCache;
}

- (id)initWithDataSource:(EODataSource *)_ds context:(id)_context;

/* operation */

- (NSArray *)fetchObjects;

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

/*
  If the fetchSpecification qualifier contains attributes
  (like "name LIKE '*.gif" AND {http://www.skyrix.com}versionCount > 100")
  then the SkyPropertyManager fetches the matching object ids.
  Now the SkyAttributeDataSource build an OR-qualifier (with globaIdKey)
  to fetch the objects from the source. If globaIdKey is not set,
  SkyAttributeDataSource try to get it from the model.
*/
- (void)setGlobalIDKey:(NSString *)_gidKey;
- (NSString *)globalIDKey;

/*
  If verifyIds is set, then all globalIds from the SkyPropertyManager will
  be verify with the source (or-qualifier with ids). Else fetchObjects will
  sometimes returns the expected objects (like from the source) or only 
  globaIDs.
  Source must support the fetchSpec hint 'fetch_primary_key_qualifier'
  (primary_key in (1, 2, 3)) and must return objects which support -globaID
  or -valueForKey:@"globaID"
*/
- (void)setVerifyIds:(BOOL)_bool;
- (BOOL)verifyIds;

/*
  if dbKeys is set, all non-dbKeys in the qualifier without namespace got the
  defaultNamespace
*/
- (void)setDbKeys:(NSArray *)_keys;
- (NSArray *)dbKeys;

- (void)setDefaultNamespace:(NSString *)_ns;
- (NSString *)defaultNamespace;

 @end

#endif /* __LSFoundation_SkyAttributeDataSource_H__ */
