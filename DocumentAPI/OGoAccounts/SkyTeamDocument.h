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

#ifndef __SkyrixOS_Libraries_SkyAccounts_SkyTeamDocument_H_
#define __SkyrixOS_Libraries_SkyAccounts_SkyTeamDocument_H_

#include <OGoDocuments/SkyDocument.h>

@class EODataSource, EOGlobalID, NSNumber, NSString, NSArray;
@class SkyMemberDataSource;

/**
 * @class SkyTeamDocument
 * @brief Document object representing an OGo team.
 *
 * Wraps a Team EO as a SkyDocument, exposing properties
 * like login, number, info, and email. Supports save and
 * reload operations via its associated datasource.
 *
 * Provides access to the team's members through a
 * SkyMemberDataSource.
 *
 * @see SkyTeamDataSource
 * @see SkyMemberDataSource
 */
@interface SkyTeamDocument : SkyDocument
{
  EODataSource *dataSource;
  EOGlobalID   *globalID;
  id           eo;

  NSString     *login;  
  NSString     *number;
  NSString     *info;
  NSString     *email;
  NSNumber     *objectVersion;
  
  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
}

- (id)initWithTeam:(id)_obj
             globalID:(EOGlobalID *)_gid
           dataSource:(EODataSource *)_ds;
- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds;
- (id)initWithTeam:(id)_account dataSource:(EODataSource *)_ds;

- (void)setInfo:(NSString *)_info;
- (NSString *)info;

- (void)setLogin:(NSString *)_login;
- (NSString *)login;

- (void)setNumber:(NSString *)_number;
- (NSString *)number;

- (void)setEmail:(NSString *)_email;
- (NSString *)email;

- (NSNumber *)objectVersion;


- (id)asEO;

- (SkyMemberDataSource *)memberDataSource;
- (NSArray *)members;

@end

#include <OGoDocuments/SkyDocumentType.h>

/**
 * @class SkyTeamDocumentType
 * @brief Document type descriptor for SkyTeamDocument.
 */
@interface SkyTeamDocumentType : SkyDocumentType
@end /* SkyTeamDocumentType */


#endif /* __SkyrixOS_Libraries_SkyAccounts_SkyTeamDocument_H_ */
