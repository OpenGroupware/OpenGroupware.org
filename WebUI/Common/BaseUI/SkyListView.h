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

#ifndef __BaseUI_SkyListView_H__
#define __BaseUI_SkyListView_H__

#include <OGoFoundation/OGoComponent.h>

/*
  Usage:

    Attribute-Keys:

      key       - value to get (from object via -valueForKey:)
      prefix    - prefix for each item i.e. "("
      suffix    - suffix for each item i.e. "), "
      separator - separator for arrays i.e. enterprises

    ListView: SkyListView {
      list            = session.accounts;
      item            = account;
      columns         = 4;
      sortHorizontal  = YES; // default: NO
      selectInverse   = YES; // default: NO
      useRadioButtons = YES; // default: NO
      nilString       = labels.nilString;
          // if useRadioButtons, string for selecting none object
      selectedItems   = selecetedAccounts;
      showTableTag    = NO;  // default: NO
      attributes = (
        { key = "login"; suffix = "("; prefix=", ";   },
        { key = "name";  prefix = ")";                },
        { key = "enterprises.description";  separator = ", ";},
      );
      //
      // new: instead of attributes:
      itemTemplate = "$login$ ($lastname$, $firstname$)";
    }
*/

@class NSNumber, NSDictionary, NSString, NSArray, NSMutableArray;

@interface SkyListView : OGoComponent
{
@private
  NSNumber     *row;
  NSNumber     *column;
  NSDictionary *attribute;
  NSString     *groupName;
  
@protected
  NSString       *action;          // API
  NSString       *nilString;       // API
  NSString       *popUpValueKey;   // API
  NSArray        *attributes;      // API
  NSArray        *list;            // API
  NSArray        *labels;          // API
  id              item;            // API
  id              popUpItem;       // API
  NSMutableArray *selectedItems;   // API
  BOOL            sortHorizontal;  // API
  int             columns;         // API
  BOOL            selectInverse;   // API
  BOOL            useRadioButtons; // API
  BOOL            usePopUp;        // API
  NSArray         *popUpList;      // API
  BOOL            showTableTag;
  NSString        *itemTemplate;   // API
}

@end

#endif /* __BaseUI_SkyListView_H__ */
