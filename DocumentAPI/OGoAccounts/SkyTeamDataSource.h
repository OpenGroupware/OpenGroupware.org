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

#ifndef __Skyrix_SkyrixApps_Libraries_SkyAccounts_SkyTeamDataSource_H__
#define __Skyrix_SkyrixApps_Libraries_SkyAccounts_SkyTeamDataSource_H__

#include <EOControl/EODataSource.h>

#define SkyDeletedTeamNotification @"SkyDeletedTeamNotification"
#define SkyUpdatedTeamNotification @"SkyUpdatedTeamNotification"
#define SkyNewTeamNotification     @"SkyNewTeamNotification"

@class NSArray, NSSet;
@class EOQualifier, EOFetchSpecification;

/**
 * @class SkyTeamDataSource
 * @brief EODataSource for fetching and managing teams.
 *
 * Provides a datasource interface for OGo teams. Supports
 * fetching via EOKeyValueQualifier, EOAndQualifier, and
 * EOOrQualifier with extended search across team, address,
 * phone, and company-value records.
 *
 * Posts SkyNewTeamNotification, SkyUpdatedTeamNotification,
 * and SkyDeletedTeamNotification on changes. Fetched EOs
 * are converted to SkyTeamDocument objects.
 *
 * @see SkyTeamDocument
 * @see SkyAccountTeamsDataSource
 */
@interface SkyTeamDataSource : EODataSource
{
  EOFetchSpecification *fetchSpecification;
  id                   context;
}
- (NSSet *)nativeKeys;
@end

/**
 * @class SkyTeamDocumentGlobalIDResolver
 * @brief Resolves Team global IDs to SkyTeamDocuments.
 *
 * Implements the SkyDocumentGlobalIDResolver informal
 * protocol to resolve EOKeyGlobalIDs with entity name
 * "Team" into SkyTeamDocument instances.
 */
@interface SkyTeamDocumentGlobalIDResolver : NSObject
//  <SkyDocumentGlobalIDResolver>
@end

#endif /*__Skyrix_SkyrixApps_Libraries_SkyAccounts_SkyTeamDataSource_H__*/
