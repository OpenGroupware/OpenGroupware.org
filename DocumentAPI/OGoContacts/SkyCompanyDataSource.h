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

#ifndef __OGoContacts_SkyCompanyDataSource_H__
#define __OGoContacts_SkyCompanyDataSource_H__

/**
 * @class SkyCompanyDataSource
 * @brief Abstract base datasource for fetching company
 *        contacts (persons and enterprises).
 *
 * Provides the common fetch, insert, update, and delete
 * logic for company entities. Subclasses
 * (SkyPersonDataSource, SkyEnterpriseDataSource) supply
 * entity-specific details such as the document class,
 * entity name, native keys, and notification names.
 *
 * Supports EOKeyValueQualifier, EOOrQualifier, and
 * EOAndQualifier for searches, including full-text
 * search via the "fullSearchString" key.
 *
 * Fetch specification hints:
 *   - fetchIds: YES|NO (default: NO)
 *   - fetchGlobalIDs: YES|NO (default: NO)
 *   - addDocumentsAsObserver: YES|NO (default: YES)
 *   - attributes: NSArray of keys to fetch
 *     (telephones, addresses, comment, keywords,
 *      contact, owner, extendedAttributes)
 *
 * @see SkyPersonDataSource
 * @see SkyEnterpriseDataSource
 * @see SkyCompanyDocument
 */

#import <EOControl/EODataSource.h>

@class NSArray, NSSet, NSNotificationCenter;
@class EOQualifier, EOFetchSpecification;
@class LSCommandContext;

@interface SkyCompanyDataSource : EODataSource
{
@protected
  id                   context;
  EOFetchSpecification *fetchSpecification;
}

- (id)initWithContext:(LSCommandContext *)_context;

/* accessors */

- (id)context;

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

- (NSNotificationCenter *)notificationCenter;

@end

@class EOKeyValueQualifier;

/**
 * @category SkyCompanyDataSource(Privates)
 * @brief Internal fetch and search methods used by
 *        the datasource implementation.
 */
@interface SkyCompanyDataSource(Privates)

- (NSArray *)_performFullTextSearch:(NSString *)_txt fetchLimit:(int)_limit;
- (NSArray *)_performFullTextSearches:(NSArray *)_txts
  isAndMode:(BOOL)_isAndMode fetchLimit:(int)_limit;

- (NSArray *)searchRecordsFromQualifier:(EOQualifier *)_qualifier 
  fullTextSearchValues:(NSArray **)fullText_;
- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids;
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;

- (NSArray *)_fetchCompaniesWithQualifier:(EOQualifier *)_qual
  operator:(NSString *)_operator
  fetchLimit:(unsigned int)_fetchLimit;

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids;
- (NSArray *)_fetchObjectsWithKeyValueQualifier:(EOKeyValueQualifier *)_q;
- (NSArray *)_makeGIDsFromIDs:(NSArray *)_ids;
- (NSArray *)_getEOsFromGIDs:(NSArray *)_gids attributes:(NSArray *)_attrs;
- (NSArray *)_attributes;

@end

/**
 * @category SkyCompanyDataSource(ConcretePrivates)
 * @brief Methods that concrete subclasses must override
 *        to provide entity-specific behavior.
 */
@interface SkyCompanyDataSource(ConcretePrivates)

- (Class)documentClass;
- (NSSet *)nativeKeys;

- (NSString *)_mapKeyFromEOToDoc:(NSString *)_key;
- (NSString *)_mapKeyFromDocToEO:(NSString *)_key;

- (NSString *)nameOfEntity;

- (NSString *)nameOfNewCompanyNotification;
- (NSString *)nameOfUpdatedCompanyNotification;
- (NSString *)nameOfDeletedCompanyNotification;

@end

#endif /* __OGoContacts_SkyCompanyDataSource_H__ */
