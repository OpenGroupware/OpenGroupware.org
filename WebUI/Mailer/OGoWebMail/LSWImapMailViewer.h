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

#ifndef __OGoWebMail_LSWImapMailViewer_H__
#define __OGoWebMail_LSWImapMailViewer_H__

#include <OGoFoundation/LSWViewerPage.h>

@class NSString, NSData;
@class SkyImapMailListState, NGImap4Context;
@class LSWMailViewerURLState;

@interface LSWImapMailViewer : LSWViewerPage
{
@private
  SkyImapMailListState *state;
  NGImap4Context       *imapContext;
  NSData               *mailSource;
  NSString             *tabKey;
  NSString             *mailSourceString;
  NSString             *to;
  NSString             *cc;
  NSString             *bcc;
  NSString             *dispositionNotificationTo;
  id                   mailDS;
  id                   emailContent;
  BOOL                 isToCollapsed;
  BOOL                 isCcCollapsed;
  BOOL                 askToReturnReceipt;
  BOOL                 messageWasUnread;
  BOOL                 viewSourceEnabled;

  id                   downloadAllItem;
  NSArray              *downloadAllObjs;

  LSWMailViewerURLState *url;
}

- (void)setTabKey:(NSString *)_tabKey;
- (NSString *)tabKey;

/* send Message Disposition Notification */
- (id)sendMDN;

@end

@interface LSWMailViewerURLState : NSObject
{
@public
  NSString *next;
  NSString *prev;
  NSString *nextUnread;
  NSString *prevUnread;
  BOOL     nextCalled;
  BOOL     prevCalled;
  BOOL     nextUnreadCalled;
  BOOL     prevUnreadCalled;
}

- (void)reset;
- (void)applyNext:(NSString *)_s;
- (void)applyPrev:(NSString *)_s;

@end

#endif /* __OGoWebMail_LSWMailViewer_H__ */
