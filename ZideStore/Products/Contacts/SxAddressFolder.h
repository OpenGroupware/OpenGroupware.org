/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#ifndef __sxdavd_SxAddressFolder_H__
#define __sxdavd_SxAddressFolder_H__

#include <Frontend/SxFolder.h>

/*
  SxAddressFolder
  
  An abstract superclass for contact folders. Concrete subclasses include
  the SxPersonFolder, SxEnterpriseFolder or SxGroupsFolder.
*/

@class NSEnumerator, NSString;
@class EOFetchSpecification;
@class SxContactManager, SxContactSetIdentifier;

@interface SxAddressFolder : SxFolder
{
  NSString *type; /* private,public,account [depends on subclass] */
}

/* accessors */

- (void)setType:(NSString *)_type;
- (NSString *)type;

- (NSString *)entity;

/* queries */

- (SxContactSetIdentifier *)contactSetID;
- (SxContactManager *)contactManagerInContext:(id)_ctx;
- (NSEnumerator *)runListQueryWithContactManager:(SxContactManager *)_cm;

/* DAV queries */

- (id)performListQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;

@end

#endif /* __sxdavd_SxAddressFolder_H__ */
