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

#include <OGoFoundation/LSWContentPage.h>
#include "common.h"

@interface SkyRequestViewer : LSWContentPage
{
  NSString *currentHeaderField;
}

@end

@implementation SkyRequestViewer

- (void)dealloc {
  RELEASE(self->currentHeaderField);
  [super dealloc];
}

- (void)setCurrentHeaderField:(NSString *)_value {
  ASSIGN(self->currentHeaderField, _value);
}
- (NSString *)currentHeaderField {
  return self->currentHeaderField;
}

- (NSArray *)currentHeaderFieldValues {
  NSString *key;
  
  if ((key = [self currentHeaderField]))
    return [[[self context] request] headersForKey:[self currentHeaderField]];

  return nil;
}

@end /* SkyRequestViewer */

@implementation WODirectAction(EchoService)

- (id<WOActionResults>)echoAction {
  return [self pageWithName:@"SkyRequestViewer"];
}

@end /* WODirectAction(EchoService) */
