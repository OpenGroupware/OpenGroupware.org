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

#include <OGoFoundation/OGoComponent.h>

@interface SkyPalmStringAttribute : OGoComponent
{
}

@end

#include "common.h"

@implementation SkyPalmStringAttribute

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (NSString *)label {
  return [self valueForBinding:@"label"];
}

- (id)string {
  return [self valueForBinding:@"string"];
}

- (BOOL)hasContent {
  NSString *str = [self string];
  return ([str length])
    ? YES : NO;
}

- (id)insertRow {
  return [self valueForBinding:@"insertRow"];
}
@end /* SkyPalmStringAttribute */
