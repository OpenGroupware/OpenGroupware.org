/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#ifndef __Skyrix_SkyrixApps_Libraries_SkyProject_SkyAttributeDataSource_H__
#define __Skyrix_SkyrixApps_Libraries_SkyProject_SkyAttributeDataSource_H__

#import <EOControl/EODataSource.h>

@class NSSet, NSMutableDictionary, NSString;
@class EOFetchSpecification, EODataSource;

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

- (NSArray *)fetchObjects;

/*
  hints:
    -restrictionQualifierString
    -restrictionPrimaryKeyName
    -restrictionEntityName
       --> look at SkyObjectPropertyManager.h

    -namespaces  --> NSSet of namespaces for the objects
*/

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

/*
  If the fetchSpecification qualifier contains attributes
  (like "name like '*.gif" AND {http://www.skyrix.com}versionCount > 100")
  then the SkyPropertyManager fetch the matching object ids.
  Now the SkyAttributeDataSource build an or-qualifier (with globaIdKey)
  to fetch the objects from the source. If globaIdKey is not set,
  SkyAttributeDataSource try to get it from the model.
*/
- (NSString *)globalIDKey;
- (void)setGlobalIDKey:(NSString *)_gidKey;

/*
  If verifyIds is set, then all globalIds from the SkyPropertyManager will
  be verify with the source (or-qualifier with ids). Else fetchObjects will
  sometimes returns the expected objects (like from the source) or only globaIDs.
  Source must support the fetchSpec hint 'fetch_primary_key_qualifier'
  (primary_key in (1, 2, 3)) and must return objects which support -globaID
  or -valueForKey:@"globaID"
*/
- (BOOL)verifyIds;
- (void)setVerifyIds:(BOOL)_bool;

/*
  if dbKeys is set, all non-dbKeys in the qualifier without namespace got the
  defaultNamespace
*/

- (void)setDbKeys:(NSArray *)_keys;
- (NSArray *)dbKeys;

- (void)setDefaultNamespace:(NSString *)_ns;
- (NSString *)defaultNamespace;

 @end

#endif /* __Skyrix_SkyrixApps_Libraries_SkyProject_SkyAttributeDataSource_H__ */
