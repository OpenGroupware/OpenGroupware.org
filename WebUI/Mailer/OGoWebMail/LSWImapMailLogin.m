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

#include "LSWImapMailLogin.h"
#include "common.h"

@implementation LSWImapMailLogin

static NSString *FixHost = nil;
static BOOL     IsHostEditable = YES;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id tmp;
  
  tmp = [ud objectForKey:@"imap_host_editable"];
  if (tmp && ![tmp boolValue]) {
    IsHostEditable = NO;
    FixHost        = [[ud objectForKey:@"imap_host"] copy];
  }
  else
    IsHostEditable = YES;
}

- (id)init {
  if ((self = [super init])) {
    self->editable = IsHostEditable;
    self->host     = [FixHost copy];
  }
  return self;
}

- (void)dealloc {
  [self->host     release];
  [self->login    release];
  [self->password release];
  [super dealloc];
}

/* parent actions */

- (id)cancel {
  return [self performParentAction:@"nothing"];
}

- (id)doLogin {
  return [self performParentAction:@"doLogin"];
}
- (id)doLogout {
  return [self performParentAction:@"doLogout"];  
}

- (id)doSend {
  return [self performParentAction:@"sendIm"];
}

/* accessors */

- (BOOL)isLogin {
  return [[self performParentAction:@"isLoginNumber"] boolValue];
}

- (void)setHost:(id)_id {
  if (!self->editable)
    return;
  ASSIGN(self->host, _id);
}
- (id)host {
  return self->host;
}
- (void)setLogin:(id)_id {
  ASSIGN(self->login, _id);
}
- (id)login {
  return self->login;
}

- (void)setPassword:(id)_id {
  ASSIGN(self->password, _id);
}
- (id)password {
  return self->password;
}

- (BOOL)savePassword {
  return self->savePassword;
}
- (void)setSavePassword:(BOOL)_passwd {
  self->savePassword = _passwd;
}

- (BOOL)editable {
  return self->editable;
}

- (void)setIsInEditEditPage:(BOOL)_b {
  self->isInEditEditPage = _b;
}
- (BOOL)isInEditEditPage {
  return self->isInEditEditPage;
}

- (void)setHideSendField:(BOOL)_b {
  self->hideSendField = _b;
}
- (BOOL)hideSendField {
  return self->hideSendField;
}


- (NSString *)valueCellColor {
  // TODO: use CSS
  NSString *key;
  
  key = self->isInEditEditPage ? @"colors_valueCell" : @"colors_subValueCell";
  return [[self valueForKey:@"config"] valueForKey:key];
}

- (NSString *)attributeCellColor {
  // TODO: use CSS
  NSString *key;

  key = self->isInEditEditPage 
    ? @"colors_attributeCell" : @"colors_subAttributeCell";
  return [[self valueForKey:@"config"] valueForKey:key];
}

- (NSString *)loginLabel {
  id l;

  l = [self labels];
  
  if (!self->isInEditEditPage)
    return [l valueForKey:@"login"];
  if (self->hideSendField)
    return [l valueForKey:@"save mail"];
  
  return [l valueForKey:@"save and send"];
}

- (NSString *)loginButtonClass {
  return (self->isInEditEditPage) ? @"button_wide" : @"button_narrow";
}

@end /* LSWImapMailLogin */
