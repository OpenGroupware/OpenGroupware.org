/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyWizardViewer.h"
#include "OGoSession.h"
#include "common.h"

@implementation SkyWizardViewer

- (void)dealloc {
  [self->object   release];
  [self->snapshot release];
  [super dealloc];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command 
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if ([_command isEqualToString:@"wizard-view"]) {
    [self setObject:[(OGoSession *)[self session] getTransferObject]];
    [self buildSnapshot];
  }
  return YES;
}

- (void)buildSnapshot {
  if (self->snapshot != nil) RELEASE(self->snapshot);
  self->snapshot = [self->object mutableCopyWithZone:[self zone]];
}

- (id)object {
  return self->object;
}
- (void)setObject:(id)_object {
  ASSIGN(self->object, _object);
}

- (id)snapshot {
  return self->snapshot;
}
- (void)setSnapshot:(id)_snap {
  ASSIGN(self->snapshot, _snap);
}
                   
@end
