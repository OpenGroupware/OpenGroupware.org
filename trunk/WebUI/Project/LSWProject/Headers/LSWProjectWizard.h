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

#ifndef __LSWebInterface_LSWProject_LSWProjectWizard_H__
#define __LSWebInterface_LSWProject_LSWProjectWizard_H__

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSMutableArray, NSArray, NSMutableDictionary;

@interface LSWProjectWizard : LSWEditorPage
{
@private
  id              item;
  NSString       *mode;
  NSMutableArray *accounts;
  NSMutableArray *newAccounts;
  NSMutableArray *persons;
  NSMutableArray *enterprises;
  NSMutableArray *newPersons;
  NSMutableArray *newEnterprises;
  NSArray        *accountResultList;
  NSArray        *personResultList;
  NSArray        *enterpriseResultList;
  NSString       *companyTypeSelection;
  id              ownerSelection;
  id              teamSelection;
  id              searchTeam;
  NSString       *searchText;
  NSMutableArray *modeList;
  NSString       *modeItem;
  NSArray        *oldAccounts;
  NSArray        *oldEnterprises;
  NSArray        *oldPersons;

  BOOL            isFinishDisabled;
  BOOL            showExtended;
}

- (void)setCompany:(id)_company;

@end

#endif /* __LSWebInterface_LSWProject_LSWProjectWizard_H__ */
