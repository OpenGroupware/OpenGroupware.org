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

#ifndef __Skyrix_WebUI_LSWImapMail_SkyImapMailRestrictions_H__
#define __Skyrix_WebUI_LSWImapMail_SkyImapMailRestrictions_H__

#import <Foundation/NSObject.h>

@class NSDictionary, NSNumber, NSArray;

@interface SkyImapMailRestrictions : NSObject
{
@protected
  NSDictionary *restrictionsConfig; // as in MailRestrictions.plist
  NSArray      *restrictions;       // restrictions for account
  BOOL         notRestricted;       // if there is a team with no restiction
  NSNumber     *companyId;          // the wanted account

  id context;                       // LSCommandContext
}

// taking activeAccount as wanted account
- (id)initWithContext:(id)_context;

- (id)initWithContext:(id)_context companyId:(NSNumber *)_cId;

// YES means no restrictions
- (BOOL)emailAddressAllowed:(NSString *)_email;
// the allowed email domains
- (NSArray *)allowedDomains;

@end /* SkyImapMailRestrictions */

#endif /* __Skyrix_WebUI_LSWImapMail_SkyImapMailRestrictions_H__ */
