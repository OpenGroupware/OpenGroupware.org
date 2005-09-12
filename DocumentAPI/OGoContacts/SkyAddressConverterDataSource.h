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

#ifndef __OGoContacts_SkyAddressConverterDataSource_H_
#define __OGoContacts_SkyAddressConverterDataSource_H_

#include <EOControl/EODataSource.h>

/*
  SkyAddressConverterDataSource

  TODO: document
*/

@class EODataSource, EOFetchSpecification;
@class LSCommandContext;

@interface SkyAddressConverterDataSource : EODataSource
{
  EOFetchSpecification *fetchSpecification;
  EODataSource         *source;
  LSCommandContext      *context;
  id                   labels;
}

- (id)initWithDataSource:(EODataSource *)_ds context:(LSCommandContext *)_ctx
  labels:(id)_labels;

@end

#endif /* __OGoContacts_SkyAddressConverterDataSource_H_ */
