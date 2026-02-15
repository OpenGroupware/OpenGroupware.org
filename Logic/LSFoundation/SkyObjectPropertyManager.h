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

#ifndef __OGo_LSFoundation_SkyObjectPropertyManager__
#define __OGo_LSFoundation_SkyObjectPropertyManager__

#import <Foundation/NSObject.h>

@class NSDictionary, NSArray, NSString, NSException, NSMutableArray, NSNumber;
@class NSMutableDictionary, NSSet, NSNotification;
@class EOQualifier, EOGlobalID, EODatabase, EOAdaptorChannel, EOEntity;
@class EOAdaptor;
@class LSCommandContext;

/*
  Exceptions
*/
extern NSString *SkyGlobalIDWasDeleted;
extern NSString *SkyGlobalIDWasCopied;

extern NSString *SkyOPMNoAccessExceptionName;
extern NSString *SkyOPMKeyAlreadyExistExceptionName;
extern NSString *SkyOPMNoPrimaryKeyExceptionName;
extern NSString *SkyOPMCouldntInsertExceptionName;
extern NSString *SkyOPMCouldntUpdateExceptionName;
extern NSString *SkyOPMCouldntDeleteExceptionName;
extern NSString *SkyOPMCouldntSelectExceptionName;
extern NSString *SkyOPMKeyDoesntExistExceptionName;
extern NSString *SkyOPMWrongPropertyKeyExceptionName;

/**
 * @class SkyObjectPropertyManager
 * @brief Manages extended object attributes in the
 *        object_property table.
 *
 * SkyObjectPropertyManager is the primary interface to
 * the extended (custom) attributes system. It reads and
 * writes key-value properties for objects identified by
 * EOGlobalIDs, supports namespaced keys, access-control
 * per property, qualifier-based searches across
 * properties, and bulk copy operations.
 *
 * Properties can be restricted by optional SQL qualifier
 * strings and entity join restrictions for more targeted
 * queries.
 *
 * @see SkyAttributeDataSource
 * @see LSCommandContext
 */
@interface SkyObjectPropertyManager : NSObject
{
@private
  LSCommandContext *context;      /* not retained */
  id               typeManager;   /* not retained */
  id               accessManager; /* not retained */

  NSString *restQualStr;
  NSString *restEntityName;
  NSString *restPKName;

  EOAdaptor        *adaptor;
  EODatabase       *database;
  EOAdaptorChannel *adChannel;
  EOEntity         *entity;
  NSMutableArray   *dbMessages;
  NSString         *defaultNamespace;
  
  NSNumber            *_loginId;
  NSArray             *_groupIds;
  NSMutableDictionary *_maskPropertyCache;
  NSMutableDictionary *_maskObjectCache;
  NSMutableDictionary *_maskAccessCache;

  int identCount;
}

- (id)initWithContext:(LSCommandContext *)_ctx;

/* returns a dictionary with all key-value pairs for the given _obj */
- (NSDictionary *)propertiesForGlobalID:(id)_obj;

/* 
  returns a dictionary with key-value pairs for the given _obj with read 
  access for the given owner (user_id / group_id)
*/
- (NSDictionary *)propertiesForGlobalID:(EOGlobalID *)_gid
  namespace:(NSString *)_namespace;

/*
  returns a dictionary with gids as keys and dictionaries of properties as
  value
*/
- (NSDictionary *)propertiesForGlobalIDs:(NSArray *)_gids
  namespace:(NSString *)_namespace;


- (NSArray *)allKeysForGlobalID:(EOGlobalID *)_gid;

- (NSArray *)allKeysForGlobalID:(EOGlobalID *)_gid
  namespace:(NSString *)_namespace;

/*
  Qualifier looks like:
    1234::color = 'gray' AND count = 5 and oid IN (1,2,3)
   
  Returns an array of EOKeyGlobalIds.
*/
- (NSArray *)globalIDsForQualifier:(EOQualifier *)_propertyQualifier 
  entityName:(NSString *)_name;

/*
  writes the properties for the given object with _owner
  if something failed, an exception is returned
  _access could be a id(read/write) or an access-list
*/
- (NSException *)addProperties:(NSDictionary *)_properties 
  accessOID:(EOGlobalID *)_access
  globalID:(EOGlobalID *)_gid;

/*
  set only keys who exists, otherwise a SkyOPMKeyDoesntExistException
  will be raised
*/
  
- (NSException *)updateProperties:(NSDictionary *)_properties 
  globalID:(EOGlobalID *)_gid;

/*
  Insert new keys and update already existing keys. Delete keys missing in the
  dictionary.
  Set nil (public access) for new entries
*/

- (NSException *)takeProperties:(NSDictionary *)_properties
  globalID:(EOGlobalID *)_gid;

- (NSException *)takeProperties:(NSDictionary *)_properties
  namespace:(NSString *)_namespace
  globalID:(EOGlobalID *)_gid;

- (NSException *)removeProperties:(NSArray *)_keys 
  globalID:(EOGlobalID *)_gid;

- (NSException *)removeProperties:(NSArray *)_keys 
  globalID:(EOGlobalID *)_gid
  checkAccess:(BOOL)_checkAccess;

- (NSException *)removeAllPropertiesForGlobalID:(EOGlobalID *)_gid;

- (NSException *)removeAllPropertiesForGlobalID:(EOGlobalID *)_gid
  checkAccess:(BOOL)_checkAccess;

- (NSException *)setAccessOID:(EOGlobalID *)_access
  propertyKeys:(NSArray *)_keys 
  globalID:(EOGlobalID *)_gid;

- (BOOL)operation:(NSString *)_mask
  allowedOnObjectID:(EOGlobalID *)_objID
  forPropertyKeys:(NSArray *)_keys;

/* sybase notifications */

- (void)gotDBMessage:(NSNotification *)_notification;

/* accessors */

- (EODatabase *)database;
- (EOEntity *)entity;
- (EOAdaptorChannel *)adaptorChannel;

/* this ns will be used if a key has no namespace */

- (void)setDefaultNamespace:(NSString *)_str;
- (NSString *)defaultNamespace;

/* notification name for modify attributes for a global id */
- (NSString *)modifyPropertiesForGIDNotificationName;

/*
  got 2 arrays of GID lists, and copy properties from _source[n] -> _dest[n]
*/

- (BOOL)copyPropertiesFrom:(NSArray *)_source to:(NSArray *)_dest;

/*
  The restriction qualifierstring will be conjoined to the object-property
  qualifier.
  
  if restrictionEntity == nil
    the qualifier must look like 'objId = 123444' or 'objId in (10,22,23).
    The result looks like 'select ... where (...) AND obj_id in (10,22,23)'.
  else
    the qualifier should look like 'projectId = 1000'
    (restrictionEntity must be Doc).
    The result looks like
    'select ... from obj_property t1, doc t2 where (...)
    AND t1.obj_id = t2.documentId // compare pk`s
    AND t2.project_id = 1000'

  If the model doesn`t contains an entry for restrictionEntityName,
  the primary key has to be set.
*/

- (void)setRestrictionPrimaryKeyName:(NSString *)_name;
- (NSString *)restrictionPrimaryKeyName;

- (void)setRestrictionEntityName:(NSString *)_name;
- (NSString *)restrictionEntityName;

- (void)setRestrictionQualifierString:(NSString *)_str;
- (NSString *)restrictionQualifierString;

@end

#endif /* __OGo_LSFoundation_SkyObjectPropertyManager__ */
