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

#ifndef __LSWebInterface_SkyPalm_SkyPalmEntryListState_H__
#define __LSWebInterface_SkyPalm_SkyPalmEntryListState_H__

#include "SkyPalmDataSourceViewerState.h"

/*
  ListState for SkyPalmEntryList and subClasses
  Values for constructor:
   _ud      - UserDefaults to store values
   _comp    - CompanyId
   _subKey  - SubKey for UserDefaults - keys
   _palmDb  - Name Of Palm DB

   UserDefaultKeys:
   SkyPalm{$LISTKEY}List_{$SUBKEY}_{$KEY}  = <value>

   $LISTKEY depends on subclass: Address|Date|Job|Memo
   $SUBKEY is _subKey
   $KEY     are the following:
       BlockSize       // INT    : block size of shown records
       SortOrder       // BOOL   : isDescending
       SortKey         // STRING : sorted key
       Attributes      // ARRAY  : shown attributes

 */

@class NSUserDefaults, NSNumber, EOFetchSpecification;

@interface SkyPalmEntryListState : SkyPalmDataSourceViewerState
{
  NSString       *subKey;
  NSUserDefaults *defaults;
  NSNumber       *companyId;
  unsigned       currentBatch;

  EOFetchSpecification *fetchSpec;
}

+ (SkyPalmEntryListState *)listStateWithDefaults:(NSUserDefaults *)_ud
  companyId:(NSNumber *)_comp
  subKey:(NSString *)_subKey
  forPalmDb:(NSString *)_palmDb;

- (void)synchronize;
- (void)setHideDeleted:(BOOL)_hide;
- (BOOL)hideDeleted;
- (BOOL)isDescending;
- (NSString *)sortedKey;

- (int)selectedCategory;
- (NSString *)selectedDevice;

// overwrite these methods
- (NSString *)entityName;
- (NSArray *)defaultAttributes;
- (NSString *)listKey;  // Address / Date / Memo / Job
- (NSString *)defaultSortKey;
- (NSString *)palmDb;
// til here

@end

#endif /* __LSWebInterface_SkyPalm_SkyPalmEntryListState_H__ */
