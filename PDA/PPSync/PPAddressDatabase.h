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

#ifndef __PPSync_PPAddressDatabase_H__
#define __PPSync_PPAddressDatabase_H__

#include "PPRecordDatabase.h"

@class NSString, NSMutableDictionary;

typedef enum {
  PPAddressPhoneType_work,
  PPAddressPhoneType_home,
  PPAddressPhoneType_fax,
  PPAddressPhoneType_other,
  PPAddressPhoneType_email,
  PPAddressPhoneType_main,
  PPAddressPhoneType_pager,
  PPAddressPhoneType_mobile
} PPAddressPhoneType;

@interface PPAddressDatabase : PPRecordDatabase
{
  BOOL     hasAppInfo;
  int      country;
  BOOL     sortByCompany;
  NSString *labels[22];
  NSString *phoneLabels[8]; /* labels for phone-types */
  BOOL     renamedLabels[19 + 3];
}

- (NSString *)phoneLabelForType:(PPAddressPhoneType)_idx;
- (PPAddressPhoneType)typeOfPhoneLabel:(NSString *)_label;
- (NSArray *)phoneLabels; /* array indexed by type */

- (NSString *)labelAtIndex:(short)_idx;
- (int)indexOfLabel:(NSString *)_label;
- (NSArray *)labels;

@end

@interface PPAddressRecord : PPRecord
{
  NSString            *showPhone;       /* phone visible in Palm overview */
  NSString            *values[19];
  NSString            *phoneLabels[5];
  NSMutableDictionary *phoneValues;
}

@end

#endif /* __PPSync_PPAddressDatabase_H__ */
