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

#ifndef __LSFoundation_H__
#define __LSFoundation_H__

#import <Foundation/NSObject.h>

@class NSArray, NSMutableSet, NSCalendarDate;
@class EOAdaptor, EOModel, EOAdaptorChannel, EOAdaptorContext, EOEntity;
@class OGoContextSession;

/*
  Defaults:

    LSAttachmentPath:  "/home/siteadm/attachments"
    LSTimeZones:       ( "MET", "GMT", "PST", "EST", "CET" )
    LSOfficeModel:     "lso3dev"
*/

@interface OGoContextManager : NSObject
{
@private
  EOAdaptor        *adaptor;
  EOModel          *model;
  id               cmdFactory;

  EOAdaptorContext *adContext;
  EOAdaptorChannel *adChannel;
  EOEntity         *personEntity;
  NSArray          *authAttributes;
  NSString         *lastAuthorized;
}

+ (id)defaultManager;

// authorization

/* obsolete */
- (BOOL)isLoginAuthorized:(NSString *)_login password:(NSString *)_password;

- (BOOL)isLoginAuthorized:(NSString *)_login password:(NSString *)_pwd
  isCrypted:(BOOL)_crypted;
// opening session

/* obsolete */
- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password;
- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  isSessionLogEnabled:(BOOL)_isSessionLogEnabled;
- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  crypted:(BOOL)_crypted;
- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled;

/* logging */

- (void)logWithFormat:(NSString *)_format, ...;
- (void)debugWithFormat:(NSString *)_format, ...;

/* startup */

- (BOOL)canConnectToDatabase;
- (NSString *)loginOfRoot; // the login-name of root account (id=10000)

@end

@interface OGoContextManager(PrivateMethods)

- (EOAdaptor *)adaptor;
- (EOModel *)model;
- (id)commandFactory;

@end

#endif /* __LSFoundation_H__ */
