/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __OGoWebMail_LSWMailList_H__
#define __OGoWebMail_LSWMailList_H__

#include <OGoFoundation/OGoComponent.h>

@protocol LSWMailListSorter < NSObject >

- (NSArray *)sortArray:(NSArray *)_array
  key:(NSString *)_key
  isDescending:(BOOL)_flag;

@end

@interface LSWMailList : OGoComponent
{
@protected
  unsigned        navItemIndex;
  NSArray         *mails;
  NSArray         *filtered;
  id              mail;
  NSArray         *mailListHeaders;
  NSDictionary    *mailListHeader;
  NSDictionary    *mailListEntry;
  NSDictionary    *selectedHeader;

  NSString        *evenRowColor;
  NSString        *oddRowColor;
  unsigned        idx;
  BOOL            isShowAll;
  BOOL            isDescending;

  NSString        *isCheckedKey;
  NSString        *selectAllCheckboxesScript;
  
  id<LSWMailListSorter> sorter;

  int index;
}

@end

#endif /* __OGoWebMail_LSWMailList_H__ */
