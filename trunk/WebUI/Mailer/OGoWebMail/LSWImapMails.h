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

#ifndef __WebUI_OGoWebMail_LSWImapMails_H__
#define __WebUI_OGoWebMail_LSWImapMails_H__

#include <OGoFoundation/OGoContentPage.h>

@class NGImap4Folder, NGImap4Context, NSArray, NSMutableArray, NSDictionary;
@class NSMutableDictionary, NSString;
@class SkyImapMailDataSource, SkyImapMailListState;

@interface LSWImapMails : OGoContentPage
{
@protected
  NGImap4Context *imapContext;
  NGImap4Folder  *rootFolder;
  NGImap4Folder  *selectedFolder;
  
  NSMutableDictionary   *note; // notifications
  NSString              *tabKey;
  SkyImapMailDataSource *mailDataSource;
  SkyImapMailListState  *mailListState;
  
  BOOL isDescending;
  
  // filter
  NSArray      *filterList;
  NSDictionary *filter;
  unsigned     startIndex;
  BOOL         isDescendingForFilterList;
  BOOL         newFilterList;
  NSDictionary *selectedAttribute; // used only by mailFilterList

  NSString *login;
  NSString *passwd;
  NSString *host;
  BOOL     savePasswd;

  BOOL loginFailed;
  BOOL inboxFolderFailed;
  BOOL trashFolderFailed;

  NSArray *toDeletedMails;
}

- (NGImap4Context *)imapContext;
- (void)setSelectedFolder:(id)_selectedFolder;
- (void)setTabKey:(NSString *)_key;

@end

#include "LSWImapBuildFolderDict.h"

#endif /* __WebUI_OGoWebMail_LSWImapMails_H__ */
