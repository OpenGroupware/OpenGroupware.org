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

#include <OGoFoundation/SkyMoneyFormatter.h>
#include "common.h"

@implementation SkyMoneyFormatter

- (void)dealloc {
  RELEASE(self->currencySymbol);
  [super dealloc];
}

- (void)setCurrencySymbol:(NSString *)_symbol {
  ASSIGNCOPY(self->currencySymbol, _symbol);
}
- (NSString *)currencySymbol {
  return self->currencySymbol;
}

// object => string

- (NSString *)editingStringForObjectValue:(id)_object {
  NSString *s;

  if (_object == nil)
    return nil;
  if (_object == [NSNull null])
    return nil;
  
  s = [NSString stringWithFormat:@"%.2lf", [_object doubleValue]];
  
  return s;
}

- (NSString *)stringForObjectValue:(id)_object {
  NSMutableString *ms;
  
  if (_object == nil)
    return nil;
  if (_object == [NSNull null])
    return nil;
  
  ms = [NSMutableString stringWithCapacity:16];
  
  if (self->currencySymbol)
    [ms appendString:self->currencySymbol];
  
  [ms appendFormat:@"%.2lf", [_object doubleValue]];
  
  return ms;
}

// string => object

- (BOOL)getObjectValue:(id *)_object
  forString:(NSString *)_string
  errorDescription:(NSString **)_error
{
  double d;
  
  if ([_string length] == 0) {
    /* null string */
    *_object = [NSNull null];
    return YES;
  }
  
  if (sscanf([_string cString], "%lf", &d) == 1) {
    *_object = [NSNumber numberWithDouble:d];
    return YES;
  }
  
  NSLog(@"%s: couldn't convert string '%@' to object using format '%%lf' ..",
        __PRETTY_FUNCTION__,
        _string);
  *_error = @"couldn't convert string to money value";
  
  return NO;
}

@end /* SkyMoneyFormatter */
