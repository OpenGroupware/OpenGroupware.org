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

#ifndef __SkyCompanyProjectDataSource_H__
#define __SkyCompanyProjectDataSource_H__

/*
  This datasource manages the projects associated with a company/account.
  
  This datasource should fetch the associated company project global-ids and
  use the SkyProjectDataSource to turn those gids into SkyProject-Documents.

  Currently it returns EO objects returned by company::get-projects
 */

#import <EOControl/EODataSource.h>

@class EOGlobalID, NSException, EOFetchSpecification;

@interface SkyCompanyProjectDataSource : EODataSource
{
  id                   context;
  EOGlobalID           *companyId;
  NSException          *lastException;
  EOFetchSpecification *fetchSpecification;
}

- (id)initWithContext:(id)_ctx companyId:(EOGlobalID *)_gid;

- (id)context;
- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

@end


@interface SkyCompanyProjectDataSource(CommandNames)
- (NSString *)nameOfCompanyGetCommand;
- (NSString *)nameOfCompanyProjectCommand;
- (NSString *)nameOfCompanyEntity;
@end

#endif /* __SkyCompanyProjectDataSource_H__ */
