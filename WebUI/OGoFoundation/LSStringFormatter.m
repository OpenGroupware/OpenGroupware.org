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

#import "common.h"
#import "LSStringFormatter.h"
#include <GDLAccess/EONull.h>

@implementation LSStringFormatter

// object => string

- (NSString *)editingStringForObjectValue:(id)_object {
  return [_object isNotNull]
    ? [_object stringValue] : (NSString *)@"";
}
- (NSString *)stringForObjectValue:(id)_object {
  return [_object isNotNull]
    ? [_object stringValue] : (NSString *)@"";
}

// string => object

- (BOOL)getObjectValue:(id *)_object
  forString:(NSString *)_string
  errorDescription:(NSString **)_error {

  *_object = ([_string length] == 0) ? [EONull null] : (id)_string;

  return YES;
}

@end
