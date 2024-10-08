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

#ifndef __PreferencesUI_LSWPreferencesEditor_H__
#define __PreferencesUI_LSWPreferencesEditor_H__

#include <OGoFoundation/LSWEditorPage.h>

/*
  LSWPreferencesEditor
  
  Note: this is actually the account editor!
*/

@class NSString, NSMutableArray, NSArray, NSDictionary;
@class NSUserDefaults, NSNumber;

@interface LSWPreferencesEditor : LSWEditorPage
{
@private
  id             data;
  NSString       *filePath;
  NSMutableArray *categories;
  NSMutableArray *teams;
  NSArray        *editableDefaults;
  id             item;
  int            idx;
  id             popupItem;
  NSMutableArray *selectedTeams;
  BOOL           newMode;
  NSDictionary   *templateUsers;
  NSUserDefaults *defaults;
  NSArray        *localDomains;
}

@end

#endif /* __PreferencesUI_LSWPreferencesEditor_H__*/
