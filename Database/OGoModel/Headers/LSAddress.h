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

#ifndef __LSModel_LSLSAddress_H__
#define __LSModel_LSLSAddress_H__

#ifdef USE_EO_RECORDS

#include "LSEOObject.h"

@class NSNumber, NSString;

@interface LSAddress : LSEOObject
{
  NSNumber *addressId;
  NSNumber *companyId;
  NSString *name1;
  NSString *name2;
  NSString *name3;
  NSString *street;
  NSString *zip;
  NSString *country;
  NSString *state;
  NSString *type;
  NSString *dbStatus;
  id       toCompany; /* used by keys: toEnterprise,toPerson,toTeam */
}

@end

#else

#include "LSDatabaseObject.h"

@interface LSAddress : LSDatabaseObject
@end

#endif

#endif /* __LSModel_LSLSAddress_H__ */
