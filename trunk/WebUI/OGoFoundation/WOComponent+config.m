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

#include "WOComponent+config.h"
#include "OGoConfigHandler.h"
#include "LSWLabelHandler.h"
#include "common.h"

@implementation WOComponent(LSOfficeConfig)

- (id)config {
  return [[[OGoConfigHandler alloc] initWithComponent:self] autorelease];
}

- (id)labels {
  return [[[LSWLabelHandler alloc] initWithComponent:self] autorelease];
}

- (NSString *)labelForKey:(NSString *)_key {
  return [[self labels] valueForKey:_key];
}

- (NSString *)labelForKey:(NSString *)_key defaultKey:(NSString *)_defKey {
  NSString *v;
  
  v = [[self labels] valueForKey:_key];
  if (v == nil) v = [[self labels] valueForKey:_defKey];
  return v;
}

- (BOOL)hasLabelForKey:(NSString *)_key {
  return [[self labels] valueForKey:_key] ? YES : NO;
}

- (BOOL)isComponent {
  return YES;
}

@end /* WOComponent(LSOfficeConfig) */

@implementation NSObject(LSOfficeConfig)

- (BOOL)isComponent {
  return NO;
}

@end /* NSObject(LSOfficeConfig) */

void __link_WOComponent_config(void) {
  __link_WOComponent_config();
}
