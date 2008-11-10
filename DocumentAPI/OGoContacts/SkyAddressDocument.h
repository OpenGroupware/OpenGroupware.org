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

#ifndef __SkyAddressDocument_H__
#define __SkyAddressDocument_H__

#include <OGoDocuments/SkyDocument.h>

@class EOGlobalID, NSString, NSNumber;

/*
  attributes:

  name1      -> string
  name2      -> string
  name3      -> string
  street     -> string
  zip        -> string
  city       -> string
  country    -> string
  state      -> string
  type       -> string
  objectVersion    -> number
*/

@class SkyContactAddressDataSource;

@interface SkyAddressDocument : SkyDocument
{
  NSString *name1;
  NSString *name2;
  NSString *name3;
  NSString *street;
  NSString *zip;
  NSString *city;
  NSString *country;
  NSString *state;
  NSString *type;
  NSNumber *companyId;
  NSNumber *objectVersion;

  // TODO: make it a bitset-struct
  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
  
  EOGlobalID *globalID;
  SkyContactAddressDataSource *dataSource;
  
@private
  BOOL     addAsObserver;
}

- (id)initWithObject:(id)_address
  globalID:(EOGlobalID *)_gid
  dataSource:(SkyContactAddressDataSource *)_ds
  addAsObserver:(BOOL)_addAsObserver;

- (id)initWithObject:(id)_address
  globalID:(EOGlobalID *)_gid
  dataSource:(SkyContactAddressDataSource *)_ds;

- (id)initWithObject:(id)_address
  dataSource:(SkyContactAddressDataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid
  dataSource:(SkyContactAddressDataSource *)_ds;

- (id)initWithGlobalID:(EOGlobalID *)_gid context:(id)_context;
- (id)initWithContext:(id)_context;

/* accessors */

- (void)setName1:(NSString *)_name;
- (NSString *)name1;

- (void)setName2:(NSString *)_name;
- (NSString *)name2;

- (void)setName3:(NSString *)_name;
- (NSString *)name3;

- (void)setStreet:(NSString *)street;
- (NSString *)street;

- (void)setZip:(NSString *)zip;
- (NSString *)zip;

- (void)setCity:(NSString *)city;
- (NSString *)city;

- (void)setCountry:(NSString *)country;
- (NSString *)country;

- (void)setState:(NSString *)state;
- (NSString *)state;

- (void)setType:(NSString *)type;
- (NSString *)type;

- (void)setObjectVersion:(NSNumber *)objectVersion;
- (NSNumber *)objectVersion;

- (void)invalidate;
- (BOOL)isValid;

- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)isComplete; /* is no if doc is initialize with attrs, use reload */

- (id)asDict;

@end

@interface SkyAddressDocument(ConvenienceMethods)

- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;

@end

#endif /* __SkyAddressDocument_H__ */
