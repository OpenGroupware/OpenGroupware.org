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

#ifndef __SkyContactDaemon_SkyContactAction_Conversion_H__
#define __SkyContactDaemon_SkyContactAction_Conversion_H__

#include "SkyContactAction.h"

@class NSArray, NSDictionary;
@class EOGlobalID;

@interface SkyContactAction(Conversion)

- (NSArray *)dictionariesForContactRecords:(NSArray *)_records
  withEnterprises:(BOOL)_withEnterprises;
- (NSArray *)dictionariesForEnterpriseRecords:(NSArray *)_records;
- (NSDictionary *)teamDictionaryForTeam:(EOGlobalID *)_teamGID
  withMembers:(NSArray *)_members
  fromLookupCache:(NSDictionary *)_lookupCache;

@end /* SkyContactAction(Conversion) */

#endif /* __SkyContactDaemon_SkyContactAction_Conversion_H__ */
