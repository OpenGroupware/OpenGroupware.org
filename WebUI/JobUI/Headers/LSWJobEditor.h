/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __OGo_JobUI_LSWJobEditor_H__
#define __OGo_JobUI_LSWJobEditor_H__

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSArray, NSMutableArray, NSDictionary;

@interface LSWJobEditor : LSWEditorPage
{
@protected
  id             item;
  int            idx;
  id             parentJob;
  id             project;
  BOOL           notifyExecutant;
  BOOL           isImportMode;
  BOOL           isProjectLinkMode;
  BOOL           isEnterpriseLinkMode;  
  NSArray        *notifyList;
  NSArray        *teams;

  id             team;
  id             executantSelection;
  
  NSMutableArray *resultList;

  NSString       *searchAccount;

  NSDictionary   *snapshotCopy;
  NSArray        *notifyLabels;

  BOOL           isProjectEnabled;
  NSString       *accountLabelFormat;
  int            noOfCols;

  id             referredPerson;

  NSArray        *selPrefAccounts;
}

- (void)setProject:(id)_project;
- (id)project;

@end

#endif /* __OGo_JobUI_LSWJobEditor_H__ */
