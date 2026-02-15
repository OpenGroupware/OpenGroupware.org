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

#ifndef __OGoAccounts_SkyAccountDataSource_H__
#define __OGoAccounts_SkyAccountDataSource_H__

#include <EOControl/EODataSource.h>

#define SkyDeletedAccountNotification @"SkyDeletedAccountNotification"
#define SkyUpdatedAccountNotification @"SkyUpdatedAccountNotification"
#define SkyNewAccountNotification     @"SkyNewAccountNotification"

@class NSArray, NSSet;
@class EOQualifier, EOFetchSpecification;
@class LSCommandContext;

/**
 * @class SkyAccountDataSource
 * @brief EODataSource for fetching and managing user accounts.
 *
 * Provides a datasource interface for OGo user accounts
 * (Person entities marked as accounts). Supports fetching
 * via EOKeyValueQualifier, EOAndQualifier, and
 * EOOrQualifier, extended search across company, address,
 * phone, and company-value records.
 *
 * Posts SkyNewAccountNotification,
 * SkyUpdatedAccountNotification, and
 * SkyDeletedAccountNotification on changes.
 *
 * Fetched EOs are converted to SkyAccountDocument objects.
 *
 * @see SkyAccountDocument
 * @see SkyMemberDataSource
 */
@interface SkyAccountDataSource : EODataSource
{
  EOFetchSpecification *fetchSpecification;
  id                   context;
}

- (id)initWithContext:(LSCommandContext *)_context; // designated initializer

- (NSSet *)nativeKeys;

- (id)context;

@end

/**
 * @class SkyAccountDocumentGlobalIDResolver
 * @brief Resolves Account global IDs to SkyAccountDocuments.
 *
 * Implements the SkyDocumentGlobalIDResolver informal
 * protocol to resolve EOKeyGlobalIDs with entity name
 * "Account" into SkyAccountDocument instances.
 */
@interface SkyAccountDocumentGlobalIDResolver : NSObject
//  <SkyDocumentGlobalIDResolver>
@end

#endif /*__OGoAccounts_SkyAccountDataSource_H__*/
