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
    (addrType is element of addressTyeps)
    
*/

#ifndef __SkyrixOS_Libraries_SkyEnterprises_SkyEnterpriseDocument_H_
#define __SkyrixOS_Libraries_SkyEnterprises_SkyEnterpriseDocument_H_

#include "SkyCompanyDocument.h"

@class EODataSource, EOGlobalID;

@interface SkyEnterpriseDocument : SkyCompanyDocument
{
  NSString *number;
  NSString *name;
  NSString *priority;
  NSString *salutation;
  NSString *url;
  NSString *bank;
  NSString *bankCode;
  NSString *account;
  NSString *login;
  NSString *email;
  BOOL     isEnterprise;

}

- (id)initWithEnterprise:(id)_obj
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds;
- (id)initWithEnterprise:(id)_enterprise dataSource:(EODataSource *)_ds;
- (id)initWithEO:(id)_enterprise context:(id)_context;
- (id)initWithContext:(id)_context;

/* attributes */

- (void)setNumber:(NSString *)_number;
- (NSString *)number;
 
- (void)setName:(NSString *)_name;
- (NSString *)name;

- (void)setPriority:(NSString *)_priority;
- (NSString *)priority;

- (void)setSalutation:(NSString *)_salutation;
- (NSString *)salutation;

- (void)setUrl:(NSString *)_url;
- (NSString *)url;

- (void)setBank:(NSString *)_bank;
- (NSString *)bank;

- (void)setBankCode:(NSString *)_bankCode;
- (NSString *)bankCode;

- (void)setAccount:(NSString *)_account;
- (NSString *)account;
 
- (void)setLogin:(NSString *)_login;
- (NSString *)login;
 
- (void)setEmail:(NSString *)_email;
- (NSString *)email;

- (void)setIsEnterprise:(BOOL)_isEnterprise;
- (BOOL)isEnterprise;

- (EODataSource *)personDataSource;
- (EODataSource *)projectDataSource;
- (EODataSource *)allProjectsDataSource; // assigned projects + fake project

@end

#include <OGoDocuments/SkyDocumentType.h>

@interface SkyEnterpriseDocumentType : SkyDocumentType
@end /* SkyEnterpriseDocumentType */


#endif /* __SkyrixOS_Libraries_SkyEnterprises_SkyEnterpriseDocument_H_ */
