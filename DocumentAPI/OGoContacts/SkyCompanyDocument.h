/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

/*
  KVC:

  addressTypes -> list of address   types
  phoneTypes   -> list of telephone types

  accessing telephon attributes:
    phoneType  -> phone number (string)
    phoneType+"_info ->phone info (string)
    
    (phoneType is element of phoneTypes)
    
  accessing addresses:
    addrType -> addressDocument
    (addrType is element of addressTyps)
    
*/

#ifndef __OGoContacts_SkyCompanyDocument_H_
#define __OGoContacts_SkyCompanyDocument_H_

#include <OGoDocuments/SkyDocument.h>

@class EODataSource, EOGlobalID, NSMutableDictionary, NSArray;
@class NSCalendarDate, NSMutableDictionary, NSMutableArray;
@class NSNumber, NSDictionary, NSData;
@class SkyContactAddressDataSource;

@interface SkyCompanyDocument : SkyDocument
{
  EODataSource        *dataSource;
  EOGlobalID          *globalID;

  NSMutableDictionary *addresses;
  NSMutableDictionary *phones;
  NSMutableArray      *phoneTypes;
  NSMutableDictionary *extendedAttrs;
  NSArray             *extendedKeys;
  NSString            *comment;
  NSString            *keywords;
  BOOL                isReadonly;
  BOOL                isPrivate;
  
  NSData              *imageData;
  NSString            *imageType;
  NSString            *imagePath;

  NSNumber            *objectVersion;

  NSArray             *supportedAttributes;
  NSDictionary        *attributeMap;

  id                  contact;
  id                  owner;
  EOGlobalID          *contactGID;
  EOGlobalID          *ownerGID;

  /* outlook attributes */
  NSString *bossName;
  NSString *department;
  NSString *office;

  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
  
@private
  BOOL                addAsObserver;
}

- (id)initWithEO:(id)_person dataSource:(EODataSource *)_ds;
- (id)initWithCompany:(id)_company
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
  addAsObserver:(BOOL)_addAsObserver;
- (void)invalidate;
- (BOOL)isValid;

// attributes

- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)isComplete;


- (NSArray *)addressTypes;
- (NSArray *)phoneTypes;

// addresses
- (EODataSource *)addressDataSource;

- (id)addressForType:(NSString *)_type;

- (void)setPhoneNumber:(NSString *)_number forType:(NSString *)_type;
- (NSString *)phoneNumberForType:(NSString *)_type;

- (void)setPhoneInfo:(NSString *)_info forType:(NSString *)_type;
- (NSString *)phoneInfoForType:(NSString *)_type;

- (NSNumber *)objectVersion;

// extended attributes
- (NSArray *)extendedKeys;
- (void)setExtendedAttribute:(id)_value forKey:(NSString *)_key;
- (id)extendedAttributeForKey:(NSString *)_key;

// contact
- (void)setContact:(SkyDocument *)_contact;
- (SkyDocument *)contact;

// owner
- (void)setOwner:(SkyDocument *)_owner;
- (SkyDocument *)owner;

// comment
- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

- (void)setKeywords:(NSString *)_keywords;
- (NSString *)keywords;

- (void)setIsReadonly:(BOOL)_isReadonly;
- (BOOL)isReadonly;

- (void)setIsPrivate:(BOOL)_isPrivate;
- (BOOL)isPrivate;

- (NSDictionary *)attributeMap;

- (void)setBossName:(NSString *)_name;
- (NSString *)bossName;
- (void)setDepartment:(NSString *)_dep;
- (NSString *)department;
- (void)setOffice:(NSString *)_office;
- (NSString *)office;


// image
- (void)setImageData:(NSData *)_data filePath:(NSString *)_filePath;
- (NSData *)imageData;
- (NSString *)imageType;

- (NSNumber *)companyId;
- (NSString *)entityName;

// for eo commands
- (NSDictionary *)asDict;
- (void)_setGlobalID:(id)_gid; // assign global id if gid is nil

/* operations */

- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;


/* restricting the support of attributes:
   
  Actually all *common* attributes are supported at any time,
  but you can forbid some types of attributes. Valid attribute types are:
      "telephones",
      "addresses",
      "contact",
      "owner",
      "comment",
      "keywords",
      "image" and
      "extendedAttributes"
*/

- (void)setSupportedAttributes:(NSArray *)_attrs;
- (NSArray *)supportedAttributes;
- (BOOL)isAttributeSupported:(NSString *)_attr;


/* private methods */

- (id)context;
- (EODataSource *)dataSource;

- (void)_loadDocument:(id)_object;

@end /* SkyCompanyDocument */

#endif /* __OGoContacs_SkyCompanyDocument_H_ */
