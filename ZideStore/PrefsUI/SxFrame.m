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

#include "SxFrame.h"
#include "common.h"

@implementation SxFrame

- (void)dealloc {
  [self->title release];
  [self->settings release];
  [self->setting release];

  [super dealloc];
}

/* accessors */

- (NSString *)resourcePath {
  return @"/ZideStore.woa/WebServerResources/";
}

- (NSString *)favIconPath {
  return [[self resourcePath] stringByAppendingPathComponent:@"favicon.ico"];
}

- (NSString *)cssPath {
  return [[self resourcePath] stringByAppendingPathComponent:@"site.css"];
}

- (void)setTitle:(NSString *)_s {
  ASSIGNCOPY(self->title, _s);
}
- (NSString *)title {
  return self->title;
}

- (void)setSettings:(NSArray *)_settings {
  ASSIGN(self->settings, _settings);
}
- (NSArray *)settings {
  return self->settings;
}

- (void)setSetting:(id)_setting {
  ASSIGN(self->setting, _setting);
}
- (id)setting {
  return self->setting;
}

- (NSString *)settingName {
  return [[[self setting] allKeys] objectAtIndex:0];
}

- (NSString *)settingURL {
  return [[[self setting] allValues] objectAtIndex:0];
}


@end /* SxFrame */
