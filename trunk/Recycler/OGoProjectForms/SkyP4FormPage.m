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


#include <OGoFoundation/LSWContentPage.h>
#include <NGExtensions/NGFileManager.h>

@class WOComponent;

@interface SkyP4FormPage : LSWContentPage
{
  id<NSObject,NGFileManager> fileManager;
  WOComponent *form;
}

- (WOComponent *)currentForm;

@end

#include "common.h"

@implementation SkyP4FormPage

- (void)dealloc {
  RELEASE(self->form);
  RELEASE(self->fileManager);
  [super dealloc];
}

/* navigation */

- (NSString *)label {
  return [@"Form:" stringByAppendingString:
           [[[self currentForm] name] lastPathComponent]];
}
- (NSString *)shortTitle {
  NSString *title;

  title = [self label];
  if ([title length] > 15)
    title = [[title substringToIndex:13] stringByAppendingString:@".."];
  return title;
}

/* accessors */

- (void)setFileManager:(id<NSObject,NGFileManager>)_fm {
  if (_fm != self->fileManager) {
    ASSIGN(self->fileManager, _fm);
  }
}
- (id<NSObject,NGFileManager>)fileManager {
  return self->fileManager;
}

- (void)setCurrentForm:(WOComponent *)_form {
  ASSIGN(self->form, _form);
  
  [_form takeValue:[self fileManager] forKey:@"fileManager"];
}
- (WOComponent *)currentForm {
  return self->form;
}

/* actions */

@end /* SkyP4FormPage */
