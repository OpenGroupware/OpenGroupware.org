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

#ifndef __OGoContacts_SkyPersonDocument_H_
#define __OGoContacts_SkyPersonDocument_H_

#include "SkyCompanyDocument.h"

@class EODataSource, EOGlobalID, NSCalendarDate, SkyPersonEnterpriseDataSource;

@interface SkyPersonDocument : SkyCompanyDocument
{
  NSString       *firstname;
  NSString       *middlename;
  NSString       *name;
  NSString       *number;
  NSString       *nickname;
  NSString       *salutation;
  NSString       *degree;
  NSString       *url;
  NSString       *gender;
  NSCalendarDate *birthday;
  EODataSource   *enterpriseDataSource;

  BOOL           isAccount;
  BOOL           isPerson;
  
  // account attributes
  NSString       *login;

  /* outlook attributes */
  NSString *partnerName;
  NSString *assistantName;
  NSString *occupation;
  NSString *imAddress;
  NSString *associatedCompany;
  
}

- (id)initWithContext:(id)_context;
- (id)initWithPerson:(id)_obj
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds;
- (id)initWithPerson:(id)_person dataSource:(EODataSource *)_ds;
- (id)initWithEO:(id)_person context:(id)_context;

/* attributes */

- (void)setFirstname:(NSString *)_firstName;
- (NSString *)firstname;

- (void)setMiddlename:(NSString *)_middlename;
- (NSString *)middlename;

- (void)setName:(NSString *)_name;
- (NSString *)name;

- (void)setNumber:(NSString *)_number;
- (NSString *)number;

- (void)setNickname:(NSString *)_nickname;
- (NSString *)nickname;

- (void)setSalutation:(NSString *)_salutation;
- (NSString *)salutation;

- (void)setDegree:(NSString *)_degree;
- (NSString *)degree;

- (void)setBirthday:(NSCalendarDate *)_birthday;
- (NSCalendarDate *)birthday;

- (void)setUrl:(NSString *)_url;
- (NSString *)url;

- (void)setGender:(NSString *)_gender;
- (NSString *)gender;

- (void)setIsAccount:(BOOL)_isAccount;
- (BOOL)isAccount;

- (void)setIsPerson:(BOOL)_isPerson;
- (BOOL)isPerson;

- (void)setLogin:(NSString *)_login;
- (NSString *)login;


- (void)setPartnerName:(NSString *)_name;
- (NSString *)partnerName;
- (void)setAssistantName:(NSString *)_name;
- (NSString *)assistantName;
- (void)setOccupation:(NSString *)_oc;
- (NSString *)occupation;
- (void)setImAddress:(NSString *)_address;
- (NSString *)imAddress;
- (void)setAssociatedCompany:(NSString *)_company;
- (NSString *)associatedCompany;

- (EODataSource *)enterpriseDataSource;
- (EODataSource *)projectDataSource;
- (EODataSource *)jobDataSource;

@end

#include <OGoDocuments/SkyDocumentType.h>

@interface SkyPersonDocumentType : SkyDocumentType
@end /* SkyPersonDocumentType */


#endif /* __OGoContacts_SkyPersonDocument_H_ */
