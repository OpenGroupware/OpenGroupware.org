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

#ifndef __LSWebInterface_SkyPalm_SkyPalmEntryList_H__
#define __LSWebInterface_SkyPalm_SkyPalmEntryList_H__

/*

  superclass for table views for palm database entries
  only use subclasses

  > subKey             // userDefaultSubKey for State
                       //                        (optional)
                       // or use
  > state              // SkyPalmEntryListState for storing state of table
                       // and generating fetchSpecification
                       //                        (optional)
  < selections         // selected entries
  > hideTitle          // hide title
  > hideButton         // hide buttons
  > hideCheckboxes     // hide checkboxes

  + bindings supportet in superclass
 */

#include "SkyPalmDataSourceViewer.h"

@class SkyPalmEntryListState, NSMutableArray, NSArray;

@interface SkyPalmEntryList : SkyPalmDataSourceViewer
{
@protected
  int                   index;       // index of current record
  id                    item;        // attribute iteration
  NSMutableArray        *selections; // selected entries
  id                    clickKey;    // key of row to click
  NSArray               *possibleKeys; // possible click keys
  BOOL                  hasDescAttr;  // hasDescriptionAttribute
}

/*
 * overwrite these methods:
 * - (NSString *)palmDb;
 * - (NSString *)itemKey;  // address | date | memo | job
 * - (NSString *)updateNotificationName;
 * - (NSString *)deleteNotificationName;
 * - (NSString *)newNotificationName;
 *
 */

- (id)item;
- (SkyPalmEntryListState *)state;
- (void)clearSelections;

@end

#endif /* __LSWebInterface_SkyPalm_SkyPalmEntryList_H__ */
