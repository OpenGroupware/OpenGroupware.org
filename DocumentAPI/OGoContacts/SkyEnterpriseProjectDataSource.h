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

#ifndef __SkyEnterpriseProjectDataSource_H__
#define __SkyEnterpriseProjectDataSource_H__

#include "SkyCompanyProjectDataSource.h"

@class EOGlobalID, NSException;

/**
 * @class SkyEnterpriseProjectDataSource
 * @brief Datasource for projects associated with a
 *        specific enterprise.
 *
 * Concrete subclass of SkyCompanyProjectDataSource
 * that fetches projects linked to an enterprise using
 * the enterprise::get and enterprise::get-projects
 * Logic commands.
 *
 * @see SkyCompanyProjectDataSource
 * @see SkyEnterpriseDocument
 */
@interface SkyEnterpriseProjectDataSource : SkyCompanyProjectDataSource
{
}
- (id)initWithContext:(id)_ctx enterpriseId:(EOGlobalID *)_gid;
@end


#endif /* __SkyEnterpriseProjectDataSource_H__ */
