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

#ifndef __SkyDBDocument_H__
#define __SkyDBDocument_H__

#include <OGoDocuments/SkyDocument.h>

/*
  SkyDBDocument
  
  Represents a database row as fetched from the SkyDBDataSource.
*/

@class NSMutableDictionary, NSDictionary, NSString, NSArray;
@class EOGlobalID;
@class SkyDocumentType, SkyDBDocumentType, SkyDBDataSource;

@interface SkyDBDocument : SkyDocument
{
@protected
  SkyDBDataSource     *dataSource;
  BOOL                hasChanged;
  BOOL                isValid;
  NSMutableDictionary *dict;
  EOGlobalID          *gid;
  NSString            *entityName;
  SkyDBDocumentType   *docType;
  NSArray             *supportedKeys;
}

- (SkyDocumentType *)documentType;

- (BOOL)isComplete;
- (BOOL)isDeletable;
- (BOOL)isNew;

- (EOGlobalID *)globalID;

- (NSArray *)supportedKeys;

- (BOOL)isValid;
- (void)invalidate;

- (id)context;
- (NSString *)entityName;

/* actions */

- (BOOL)save;
- (BOOL)delete;
- (BOOL)revert;

@end

@interface SkyDBDocument(Privates)

- (id)initWithDataSource:(SkyDBDataSource *)_ds
  dictionary:(NSDictionary *)_dict globalID:(EOGlobalID *)_gid
  entityName:(NSString *)_eName;

- (SkyDBDataSource *)dataSource;

@end

#endif /* __SkyDBDocument_H__ */
