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
// $Id$

#ifndef __SkyImapContextHandler_H__
#define __SkyImapContextHandler_H__

#import <Foundation/NSObject.h>

@class NGImap4Context, SkyImapMailDataSource;
@class NSString, NGImap4Folder;

@interface SkyImapContextHandler : NSObject
{
}

+ (id)sharedImapContextHandler;
+ (id)imapContextHandlerForSession:(id)_sn;

- (SkyImapMailDataSource *)mailDataSourceWithSession:(id)_session
  folder:(NGImap4Folder *)_folder;

- (NGImap4Context *)sessionImapContext:(id)_session;

- (NGImap4Context *)imapContextWithSession:(id)_session
  errorString:(NSString **)error_;

- (NGImap4Context *)imapContextWithSession:(id)_session
  password:(NSString *)_pwd login:(NSString **)login_
  host:(NSString **)host_ errorString:(NSString **)error_;

- (void)resetImapContextWithSession:(id)_session;

- (void)prepareForLogin:(NSString *)_login passwd:(NSString *)_passwd
  host:(NSString *)_host savePwd:(BOOL)_savePwd session:(id)_session;

@end /* SkyImapContextHandler */

#endif /* __SkyImapContextHandler_H__ */
