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

#ifndef __SkyContacts_SkyCompanyCompanyDataSource_H__
#define __SkyContacts_SkyCompanyCompanyDataSource_H__

/*
  This datasource manages the company associated with a company, e.g.
  persons of an enterprise object or enterprises of a person.
  
  It returns SkyCompanyDocuments.

  hints:
  
    addDocumentsAsObserver: (YesNumber or NoNumber) (default: YES)
  
*/

#import <EOControl/EODataSource.h>

@class EOGlobalID, NSException, EOFetchSpecification;

@interface SkyCompanyCompanyDataSource : EODataSource
{
  id                   context;
  EOFetchSpecification *fetchSpecification;
  EOGlobalID           *companyId;
  NSException          *lastException;
}

- (id)initWithContext:(id)_ctx companyId:(EOGlobalID *)_gid;

- (id)context;
- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

@end

@interface SkyCompanyCompanyDataSource(CommandNames)
- (NSString *)destinyEntityName;
- (EODataSource *)companyDataSource;
- (NSString *)_mapKeyFromDocToEO:(NSString *)_key;
@end

#endif /* __SkyContacts_SkyCompanyCompanyDataSource_H__ */
