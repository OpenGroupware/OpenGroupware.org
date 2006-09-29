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

/*
  supports following hints:

    fetchIds:               YES|NO (default: No)
    fetchGlobalIDs:         YES|NO (default: No)
    addDocumentsAsObserver: YES|NO (default: YES)
    
    attributes: (NSArray)
                describes the keys to fetch
                possible keys are:
                    "telephones",
                    "addresses",
                    "comment",
                    "keywords"
                    "contact",
                    "owner",
                    "extendedAttributes",

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
