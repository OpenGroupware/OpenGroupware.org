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

#ifndef __SkyrixOS_Libraries_SkyAccounts_SkyAccountDocument_H_
#define __SkyrixOS_Libraries_SkyAccounts_SkyAccountDocument_H_

#include <OGoDocuments/SkyDocument.h>

@class EODataSource, EOGlobalID, NSNumber, NSString, NSArray;
@class SkyAccountTeamsDataSource;

@interface SkyAccountDocument : SkyDocument
{
  EODataSource *dataSource;
  EOGlobalID   *globalID;
  id           eo;

  NSString     *firstname;
  NSString     *middlename;
  NSString     *name;
  NSString     *nickname;
  NSString     *login;  
  NSString     *password;
  NSString     *number;
  NSNumber     *objectVersion;
  BOOL         isLocked;
  BOOL         isExtraAccount;
  
  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
}

- (id)initWithAccount:(id)_obj
             globalID:(EOGlobalID *)_gid
           dataSource:(EODataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds;
- (id)initWithAccount:(id)_account dataSource:(EODataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid context:(id)_ctx;

- (void)setFirstname:(NSString *)_firstName;
- (NSString *)firstname;

- (void)setMiddlename:(NSString *)_middlename;
- (NSString *)middlename;

- (void)setName:(NSString *)_name;
- (NSString *)name;

- (void)setNickname:(NSString *)_nickname;
- (NSString *)nickname;

- (void)setPassword:(NSString *)_password;
- (NSString *)password;

- (void)setLogin:(NSString *)_login;
- (NSString *)login;

- (void)setNumber:(NSString *)_number;
- (NSString *)number;

- (NSNumber *)objectVersion;
- (BOOL)isLocked;
- (BOOL)isExtraAccount;

- (id)asEO;

- (SkyAccountTeamsDataSource *)teamsDataSource;
- (NSArray *)teams;

@end

#include <OGoDocuments/SkyDocumentType.h>

@interface SkyAccountDocumentType : SkyDocumentType
@end /* SkyAccountDocumentType */


#endif /* __SkyrixOS_Libraries_SkyAccounts_SkyAccountDocument_H_ */
