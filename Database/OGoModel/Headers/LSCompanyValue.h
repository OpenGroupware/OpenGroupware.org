/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#ifndef __LSModel_LSLSCompanyValue_H__
#define __LSModel_LSLSCompanyValue_H__

#ifdef USE_EO_RECORDS

#include "LSEOObject.h"

@class NSNumber, NSString;

@interface LSCompanyValue : LSEOObject
{
  NSNumber *companyValueId;
  NSString *attribute;
  NSString *value;
  NSNumber *isEnum;
  NSString *dbStatus;
  NSNumber *uid;
  NSNumber *type;
  NSString *label;
  NSNumber *isLabelLocalized;
  NSNumber *companyId;
  id       toCompany;
}

@end

#else

#include "LSDatabaseObject.h"

@interface LSCompanyValue : LSDatabaseObject
@end

#endif

#endif /* __LSModel_LSLSCompanyValue_H__ */
