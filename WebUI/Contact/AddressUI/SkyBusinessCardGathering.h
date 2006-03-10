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

#ifndef __AddressUI_SkyBusinessCardGathering_H__
#define __AddressUI_SkyBusinessCardGathering_H__

#include <OGoFoundation/OGoContentPage.h>

/*
  SkyBusinessCardGathering

  This page is a small editor which can be used to create a person and a
  connected enterprise in one run.
*/

@class NSMutableDictionary, NSMutableArray, NSString;

@interface SkyBusinessCardGathering : OGoContentPage
{
  NSMutableDictionary *gatheringPerson;
  NSMutableDictionary *gatheringCompany;
  id             item;
  NSArray        *phones;
  NSMutableArray *otherPhones;
  NSMutableArray *companySearchList;
  NSMutableArray *addedCompanies;
  NSString       *searchCompanyField;
  int            categoryIndex;
  NSMutableArray *categories;
}

@end

#endif /* __AddressUI_SkyBusinessCardGathering_H__*/
