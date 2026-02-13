/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#ifndef __LSLogic_LSFoundation_LSDBObjectNewCommand_H__
#define __LSLogic_LSFoundation_LSDBObjectNewCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSString;
@class NSDictionary;
@class EOEntity;

/**
 * @class LSDBObjectNewCommand
 * @brief Base command for creating (inserting) new database
 *   objects.
 *
 * Generates a new primary key via the "system::newkey"
 * command, produces an empty enterprise object, populates it
 * with the values from the record dictionary, and inserts it
 * into the database. After insertion the object is refetched
 * to ensure all database-generated values are current.
 *
 * Subclasses can call -prepareChangeTrackingFields to
 * automatically set objectVersion, creationDate,
 * lastmodifiedDate, and lastModified if the entity defines
 * those attributes.
 *
 * An entry is also inserted into the obj_info table for most
 * entity types (excluding assignments and CompanyValue).
 *
 * @see LSDBObjectBaseCommand
 * @see LSDBObjectSetCommand
 * @see LSDBObjectDeleteCommand
 */
@interface LSDBObjectNewCommand : LSDBObjectBaseCommand
{
}

- (id)produceEmptyEOWithPrimaryKey:(NSDictionary *)_pkey
  entity:(EOEntity *)_entity;

// new Primary Key

- (NSDictionary *)newPrimaryKeyDictForContext:(id)_context
  keyName:(NSString *)_keyName;

- (void)prepareChangeTrackingFields;

@end

#endif /* __LSLogic_LSFoundation_LSDBObjectNewCommand_H__ */
