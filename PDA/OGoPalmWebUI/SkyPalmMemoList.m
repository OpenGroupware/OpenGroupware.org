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

#include <OGoPalmUI/SkyPalmEntryList.h>

/*
  a table view for viewing palm memos

  > subKey       - userDefaultSubKey                      (may be nil)
  > action       - action for single job                  (may be nil)

  < memo         - current memo in iteration

 */

@interface SkyPalmMemoList : SkyPalmEntryList
{}
@end

#include <Foundation/Foundation.h>

@implementation SkyPalmMemoList

// overwriting
- (NSString *)palmDb {
  return @"MemoDB";
}
- (NSString *)itemKey {
  return @"memo";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmMemo";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmMemo";
}
- (NSString *)newNotificationName {
  return @"LSWNewPalmMemo";
}
- (NSString *)newDirectActionName {
  return @"newPalmMemo";
}
- (NSString *)viewDirectActionName {
  return @"viewPalmMemo";
}
- (NSString *)primaryKey {
  return @"palm_memo_id";
}

@end
