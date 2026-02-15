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

#ifndef __OGoContacts_SkyPersonEnterpriseDataSource_H__
#define __OGoContacts_SkyPersonEnterpriseDataSource_H__

#import "SkyCompanyCompanyDataSource.h"

@class EOGlobalID, NSException, SkyEnterpriseDataSource;

/**
 * @class SkyPersonEnterpriseDataSource
 * @brief Datasource for enterprises associated with a
 *        specific person.
 *
 * Fetches SkyEnterpriseDocument objects for the
 * enterprises linked to a person, identified by its
 * global ID. Subclass of SkyCompanyCompanyDataSource
 * that uses enterprise::get-by-globalid and a
 * SkyEnterpriseDataSource internally. Maps the document
 * key "name" to the EO key "description".
 *
 * @see SkyCompanyCompanyDataSource
 * @see SkyEnterpriseDataSource
 * @see SkyPersonDocument
 */
@interface SkyPersonEnterpriseDataSource : SkyCompanyCompanyDataSource
{
  SkyEnterpriseDataSource *enterpriseDS;
}

- (id)initWithContext:(id)_ctx personId:(EOGlobalID *)_gid;

@end

#endif /* __OGoContacts_SkyPersonEnterpriseDataSource_H__ */
