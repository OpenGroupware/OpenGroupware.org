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

#ifndef __SkyMoneyFormatter_H__
#define __SkyMoneyFormatter_H__

#import <Foundation/NSFormatter.h>

@class NSString;

/**
 * @class SkyMoneyFormatter
 * @brief Formats numeric values as currency strings.
 *
 * Converts numbers to strings with two decimal places
 * and an optional currency symbol suffix. Parses
 * currency strings back to NSNumber. Used in
 * financial fields of the OGo WebUI.
 */
@interface SkyMoneyFormatter : NSFormatter
{
  NSString *currencySymbol;
}

- (void)setCurrencySymbol:(NSString *)_symbol;
- (NSString *)currencySymbol;

@end

#endif /* __SkyMoneyFormatter_H__ */
