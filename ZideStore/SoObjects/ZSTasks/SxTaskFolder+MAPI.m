/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxTaskFolder.h"
#include "common.h"

@implementation SxTaskFolder(MAPI)

- (int)mapiID_8112_int {
  return 3;
}
- (int)mapiID_8113_int {
  return 1;
}

#if 0
- (int)cdoRights {
  NSLog(@"################ [%s] ###############", __PRETTY_FUNCTION__);
  return 2043;
  /* frightsReadAny          0x001
   * frightsCreate           0x002
   * frightsEditOwned        0x008
   * frightsDeleteOwned      0x010
   * frightsEditAny          0x020
   * frightsDeleteAny        0x040
   * frightsCreateSubfolder  0x080
   * frightsOwner            0x100
   * frightsContact          0x200
   * frightsVisible          0x400
   */
}
#endif

@end /* SxTaskFolder(MAPI) */

#include "SxTask.h"

@implementation SxTask(MAPI)

- (int)cdoAction {
  /* MAPI 10800003 */
  return 1280;
  /* whatever this is and means ... (taken from Apache), also 272 */
}
- (NSString *)mapiID_8112_int {
  return @"2";
}
- (NSString *)mapiID_8113_int {
  return @"1";
}
- (NSString *)mapiID_8123_int {
  return @"-1000";
}
- (NSString *)mapiID_8124_bool {
  return @"0";
}
- (NSString *)mapiID_8129_int {
  return @"0";
}
- (NSString *)mapiID_812A_int {
  return @"0";
}
- (NSString *)mapiID_812C_bool {
  return @"1";
}
- (NSString *)cdoIsRecurring {
  return @"0";
}
- (NSString *)cdoItemIsComplete {
  id jobStatus;

  jobStatus = [[self object] valueForKey:@"jobStatus"];
  if (([jobStatus isEqualToString:@"25_done"]) ||
      ([jobStatus isEqualToString:@"30_archived"]))
    return @"1";
  return @"0";
}

// TODO: cdoEntryID
// TODO: cdoInstanceKey
// TODO: cdoObjectType, cdoSearchKey
// mapiID_8108000B
// mapiID_81050040 (taskCommonEnd)

- (void)setThreadTopic:(NSString *)_tp {
  [self takeValue:_tp forKey:@"subject"];
}
- (NSString *)threadTopic {
  /* subject is created as 'threadTopic' */
  return [self valueForKey:@"subject"];
}

- (id)cdoTrustSender {
  return @"1";
}

- (id)cdoMessageFlags {
  return @"3"; // READ, UNMODIFIED
}
- (id)cdoMessageStatus {
  return @"0";
}

- (int)cdoPriority {
  // see SxDavTaskAction -getPriority for details
  int pri;
  
  pri = [self priority];
  if (pri == 2)
    pri = -1;
  return pri;
}

/* properties set in Apache */

- (int)alternateRecipientAllowed {
  return 1;
}
- (int)originatorDeliveryReportRequested {
  return 0;
}
- (int)readReceiptRequested {
  return 0;
}

- (int)mapi0x1006_int {
  return 0;
}
- (int)mapi0x1007_int {
  return 0;
}
- (int)mapi0x1010_int {
  return 0;
}
- (int)mapi0x1011_int {
  return 0;
}
- (int)mapi0x3FDE_int {
  return 28591;
}

- (NSString *)cdoBody {
  NSString *body;
  static NSString *PrefixStr = @"ZideLook rich-text compressed comment: ";

  body = [[self object] valueForKey:@"comment"];

  if ([body isNotNull]) {
    if ([body length] > [PrefixStr length]) {
      if ([body hasPrefix:PrefixStr]) {
        return nil;
      }
    }
  }
  else {
    body = nil;
  }
  return body;
}

- (int)rtfInSync {
  return 1;
}

- (int)rtfSyncBodyCRC {
  return 0;
}

- (int)rtfSyncBodyCount {
  return 0;
}
- (int)rtfSyncPrefixCount {
  return 0;
}
- (int)rtfSyncTrailingCount {
  return 0;
}

- (int)cdoDepth {
  return 0;
}

- (int)cdoStatus {
  return 0;
}

- (NSString *)rtfCompressed {
  NSString        *body;
  static NSString *PrefixStr = @"ZideLook rich-text compressed comment: ";

  body = [[self object] valueForKey:@"comment"];

  if (![body isNotNull])
    body = @"";
  
  if ([body hasPrefix:PrefixStr])
    body = [body substringFromIndex:[PrefixStr length]];
  else
    body = [[body stringByEncodingRTF] stringByEncodingBase64];
  return body;
}

@end /* SxTask(MAPI) */
