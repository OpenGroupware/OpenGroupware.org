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

#ifndef __Frontend_NSString_csv_H__
#define __Frontend_NSString_csv_H__

#import <Foundation/NSString.h>

@class NSArray;

@interface NSString(CommaSeparatedValues)

- (NSArray *)parsedCSV;
// calls parsedCSVLineWithSeparator:quotes:'\'','\"' quotesCount:2
- (NSArray *)parsedCSVWithSeparator:(char)_separator;

- (NSArray *)parsedCSVWithSeparator:(char)_separator
                             quotes:(char *)_quotes
                        quotesCount:(unsigned)_quoteCount;

- (NSString *)csvStringWithQuotes:(char)_quote;

@end /* NSString(CommaSeparatedValues) */

#import <Foundation/NSArray.h>

@interface NSArray(CommaSeparatedValues)

// assumes, that this instance is a line of a table
- (NSString *)csvStringWithSeparator:(char)_separator
                              quote:(char)_quote;

- (NSString *)csvString; // uses ',' as separator and '\'' as quote

@end /* NSArray(CommaSeparatedValues) */

#endif /* __Frontend_NSString_csv_H__ */
