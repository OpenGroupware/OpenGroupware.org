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

#ifndef __EnterprisesUI_LSWEnterprises_H__
#define __EnterprisesUI_LSWEnterprises_H__

#include <OGoFoundation/OGoContentPage.h>

@class NSArray, NSString, NSDictionary, EOCacheDataSource;

@interface LSWEnterprises : OGoContentPage
{
  NSString          *maxSearchCount;
  EOCacheDataSource *dataSource;
  unsigned          currentBatch;
  id                enterprise;
  id                item;          // non-retained
  int               itemIdx;
  BOOL              hasSearched;

  // for tab view
  NSString     *tabKey;
  BOOL         isDescending;
  
  NSString     *searchText;
  NSString     *searchTitle;
}

/* actions */

- (WOComponent *)tabClicked;
- (WOComponent *)fullSearch;
- (WOComponent *)advancedSearch;

@end

#endif /* __EnterprisesUI_LSWEnterprises_H__ */
