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

#ifndef __OGoWebMail_LSWImapMailList_H__
#define __OGoWebMail_LSWImapMailList_H__

#include <OGoFoundation/OGoComponent.h>

@class NSArray, NSMutableArray, NSDictionary, NSString;
@class NGImap4Message, NGImap4Folder;

@protocol LSWImapMailListSorter < NSObject >

- (NSArray *)sortArray:(NSArray *)_array
  key:(NSString *)_key
  isDescending:(BOOL)_flag;

@end

@interface LSWImapMailList : OGoComponent
{
@protected
  NSArray        *messages;
  NSArray        *mailListHeaders;
  NSDictionary   *mailListHeader;
  NSDictionary   *mailListEntry;
  NSDictionary   *selectedHeader;
  NGImap4Message *message;
  unsigned        navItemIndex;  
  NSString        *evenRowColor;
  NSString        *oddRowColor;
  int             index;
  BOOL            isShowAll;
  BOOL            isDescending;
  BOOL            useFilter;
  NSMutableArray  *selectedMessages;

  id<LSWImapMailListSorter> sorter;
  NSString       *selectAllCheckboxesScript;  
  NSMutableArray *identifier;
  BOOL           shouldSort;

  NGImap4Folder *folder;
}

@end

#endif /* __OGoWebMail_LSWImapMailList_H__ */
