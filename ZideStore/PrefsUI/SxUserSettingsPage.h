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

#ifndef __Frontend_SxUserSettingsPage_H__
#define __Frontend_SxUserSettingsPage_H__

#include "SxPage.h"

@class NSString, NSArray;

@interface SxUserSettingsPage : SxPage
{
  NSString *password;
  NSString *selectedTimeZone;
  NSString *email;

  NSString *message;

  NSArray *groups;
  id      group;
}

- (void)setPassword:(NSString *)_password;
- (NSString *)password;

- (void)setSelectedTimeZone:(NSString *)_timeZone;
- (NSString *)selectedTimeZone;

- (void)setEmail:(NSString *)_email;
- (NSString *)email;

- (void)setMessage:(NSString *)_message;
- (NSString *)message;

- (BOOL)hasMessage;

/* actions */
- (NSArray *)groups;

- (id)saveSettingsAction;
- (id)setPasswordAction;

@end /* SxUserSettingsPage */

#endif /* __Frontend_SxUserSettingsPage_H__ */
