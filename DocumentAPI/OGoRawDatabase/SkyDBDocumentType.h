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

#ifndef __SkyDBDocumentType_H__
#define __SkyDBDocumentType_H__

/**
 * @class SkyDBDocumentType
 * @brief A document type identified by its database
 *        entity name.
 *
 * Extends SkyDocumentType with an entityName property
 * that ties the type to a specific GDLAccess/EOF
 * entity (e.g. "Person", "Enterprise", "Date").
 *
 * Two SkyDBDocumentType instances are considered equal
 * when their entity names match.
 *
 * @see SkyDocumentType
 * @see SkyDBDocument
 * @see SkyDBDataSource
 */

#include <OGoDocuments/SkyDocumentType.h>

@interface SkyDBDocumentType : SkyDocumentType
{
  NSString *entityName;
}

- (void)setEntityName:(NSString *)_eName;
- (id)entityName;

- (BOOL)isEqual:(id)_obj;
- (BOOL)isEqualToDBDocumentType:(SkyDBDocumentType *)_type;

@end /* SkyDocumentType */

#endif
