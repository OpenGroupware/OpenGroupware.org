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

#include "SkyCurrencyFormatter.h"
#import <Foundation/Foundation.h>

@implementation SkyCurrencyFormatter

- (id)init {
  if ((self = [super init])) {
    self->formatter = [[NSNumberFormatter alloc] init];
    [self setCurrency:@"EUR"];
    self->showCurrencyLabel = NO;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->formatter);
  RELEASE(self->currency);
  [super dealloc];
}
#endif

// accessors
- (void)setCurrency:(NSString *)_currency {
  ASSIGN(self->currency,_currency);
}
- (NSString *)currency {
  return self->currency;
}

- (void)setShowCurrencyLabel:(BOOL)_flag {
  self->showCurrencyLabel = _flag;
}
- (BOOL)showCurrencyLabel {
  return self->showCurrencyLabel;
}

- (void)setThousandSeparator:(NSString *)_sep {
  [self->formatter setThousandSeparator:_sep];
}
- (void)setDecimalSeparator:(NSString *)_sep {
  [self->formatter setDecimalSeparator:_sep];
}
- (void)setFormat:(NSString *)_format {
  [self->formatter setFormat:_format];
}

// comverting
// DEM --> EUR   // <- old database
// EUR --> DEM   // -> new database ...
- (double)_factorForCurrency {
  if ([self->currency isEqualToString:@"EUR"])
    //    return 0.511291881196; // DEM * x = EUR
    //  return 1.0; // DEM * 1.0 = DEM
    return 1.0; // EUR * 1.0 = EUR
  return 1.95583; // EUR * 1.95583 = DEM
}
// DEM --> EUR
- (double)_factor2ForCurrency {
  if ([self->currency isEqualToString:@"EUR"])
    //    return 1.95583; // EUR * x = DEM
    //  return 1.0; // DEM * 1.0 = DEM
    return 1.0;  // EUR * 1.0 = EUR;
  return 0.511291881196;  // DEM * x = EUR
}
- (NSString *)_labelForCurrency {
  if ([self->currency isEqualToString:@"DEM"])
    return @"DM";
  return self->currency;
}

- (NSString *)stringForObjectValue:(id)_val {
  NSString *str = nil;
  double factor = [self _factorForCurrency];
  if (factor != 1.0) {
    double d = [_val doubleValue] * factor;
    str = [self->formatter stringForObjectValue:
                [NSNumber numberWithDouble:d]];
  }
  else {
    str = [self->formatter stringForObjectValue:_val];
  }
  if (self->showCurrencyLabel) {
    return [str stringByAppendingFormat:@" %@", [self _labelForCurrency]];
  }
  return str;
}

- (BOOL)getObjectValue:(id *)_object
  forString:(NSString *)_string
  errorDescription:(NSString **)_error
{
  if ([self->formatter getObjectValue:_object forString:_string
           errorDescription:_error])
    {
      double factor = [self _factor2ForCurrency];
      if (factor != 1.0) {
        NSNumber *number = *_object;

        number = [NSNumber numberWithDouble:[number doubleValue] * factor];
        *_object = number;
      }

      return YES;
    }
  return NO;
}


@end /* SkyCurrencyFormatter */
