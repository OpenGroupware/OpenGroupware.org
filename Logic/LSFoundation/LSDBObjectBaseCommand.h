/*
  Copyright (C) 2000-2005 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#ifndef __OGo_LSFoundation_LSDBObjectBaseCommand_H__
#define __OGo_LSFoundation_LSDBObjectBaseCommand_H__

#import  <Foundation/NSNotification.h>
#include <LSFoundation/LSBaseCommand.h>

/**
 * @class LSDBObjectBaseCommand
 * @brief Abstract superclass for database CRUD commands.
 *
 * Extends LSBaseCommand with database access (channel, model,
 * entity, adaptor) and a record dictionary that collects
 * key-value pairs to be applied to the target enterprise
 * object. Provides convenience methods for fetching objects
 * by qualifier, building SQL IN clauses, extracting primary
 * keys from heterogeneous arrays, and validating date-typed
 * command arguments against the EOModel.
 *
 * Concrete subclasses (LSDBObjectNewCommand,
 * LSDBObjectSetCommand, LSDBObjectGetCommand,
 * LSDBObjectDeleteCommand) implement specific CRUD operations.
 *
 * @see LSBaseCommand
 * @see LSDBObjectNewCommand
 * @see LSDBObjectSetCommand
 * @see LSDBObjectGetCommand
 * @see LSDBObjectDeleteCommand
 */

@class NSMutableArray, NSMutableDictionary, NSArray;
@class EOAdaptor, EOModel, EODatabase, EOEntity;
@class EOAttribute, EORelationship, EOSQLQualifier;
@class EODatabaseContext, EODatabaseChannel;
@class LSCommandContext;

/**
 * @protocol LSDBCommand
 * @brief Extension of LSCommand for database-bound commands
 *   that operate on a named entity.
 */
@protocol LSDBCommand < LSCommand >

- (NSString *)entityName;

@end

@interface LSDBObjectBaseCommand : LSBaseCommand < LSDBCommand >
{
@private
  unsigned            returnType;
  NSString            *entityName;
@protected
  NSMutableArray      *dbMessages;
  NSMutableDictionary *recordDict;
}

- (id)initForOperation:(NSString *)_operation 
  inDomain:(NSString *)_domain; // designated initializer
- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
  initDictionary:(NSDictionary *)_dict;

- (void)_validateKeysForContext:(id)_context;

/* accessors */

- (void)setEntityName:(NSString *)_entityName;
- (NSString *)entityName;

- (void)setReturnType:(unsigned)_returnType;
- (unsigned)returnType;

- (void)takeValuesFromDictionary:(NSDictionary *)_dict;

/* database context */

- (EOAdaptor *)databaseAdaptor;
- (EOModel   *)databaseModel;

- (EODatabase        *)database;
- (EODatabaseContext *)databaseContext;
- (EODatabaseChannel *)databaseChannel;

/* context accessors (valid only during run) */

- (EOEntity *)entity;
- (EOAttribute *)attributeNamed:(NSString *)_name;
- (EORelationship *)relationshipNamed:(NSString *)_name;
- (NSString *)primaryKeyName;
- (void)setPrimaryKeyValue:(id)_value;
- (id)primaryKeyValue;

/* convenience methods */

- (NSArray *)extractPrimaryKeysNamed:(NSString *)_pkeyName
  fromObjectArray:(NSArray *)_array
  inContext:(LSCommandContext *)_cmdctx;

- (NSArray *)fetchAllForQualifier:(EOSQLQualifier *)_qualifier
  fetchOrder:(NSArray *)_order;
- (NSArray *)fetchAllForQualifier:(EOSQLQualifier *)_qualifier;

- (NSString *)joinPrimaryKeysFromArrayForIN:(NSArray *)_ids;

- (EOSQLQualifier *)createSqlInQualifierOnEntity:(EOEntity *)_entity
  attributePath:(NSString *)_attrName
  primaryKeys:(NSArray *)_keys;

- (void)calculateCTagInContext:(id)_context;

/* assertions */

- (void)assert:(BOOL)_condition; // raises with dbMessages

@end

#endif /* __OGo_LSFoundation_LSDBObjectBaseCommand_H__ */
