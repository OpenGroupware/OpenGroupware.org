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

#include <OGoFoundation/OGoComponent.h>

/*
  Example:
  
  WarningMode : SkyWarningMode {
    isInWarningMode = notOk;    // default: NO
    phrase          = "there was an error";
    onOk            = "ok";     // default: "ok"
    onCancel        = "cancel"; // default: "cancel"
  }

  <#WarningMode>
    <!-- some stuff -->
  </#WarningMode>
*/

@class NSString;

@interface SkyWarningMode : OGoComponent 
{
  BOOL     isInWarningMode;
  NSString *phrase;
  NSString *onOk;
  NSString *onCancel;
}

@end /* SkyWarningMode */

#include "common.h"

@implementation SkyWarningMode

- (id)init {
  if ((self = [super init])) {
    self->onOk     = @"ok";
    self->onCancel = @"cancelDelete";
  }
  return self;
}

- (void)dealloc {
  [self->phrase   release];
  [self->onOk     release];
  [self->onCancel release];
  [super dealloc];
}

- (void)setIsInWarningMode:(BOOL)_warning {
  self->isInWarningMode = _warning;
}
- (BOOL)isInWarningMode {
  return self->isInWarningMode;
}

- (void)setPhrase:(NSString *)_phrase {
  ASSIGNCOPY(self->phrase, _phrase);
}
- (NSString *)phrase {
  return self->phrase;
}

- (void)setOnOk:(NSString *)_onOk {
  ASSIGNCOPY(self->onOk, _onOk);
}
- (NSString *)onOk {
  return self->onOk;
}

- (void)setOnCancel:(NSString *)_onCancel {
  ASSIGNCOPY(self->onCancel, _onCancel);
}
- (NSString *)onCancel {
  return self->onCancel;
}

/* actions */

- (id)ok {
  return [self performParentAction:self->onOk];
}
- (id)cancel {
  return [self performParentAction:self->onCancel];
}

@end /* SkyWarningMode */
