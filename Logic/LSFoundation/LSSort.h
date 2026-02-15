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

#ifndef __LSLogic_LSFoundation_LSSort_H__
#define __LSLogic_LSFoundation_LSSort_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/**
 * @file LSSort.h
 * @brief Sort ordering types and array sorting utilities.
 *
 * Defines the LSOrdering enum for ascending/descending
 * sort order, a category on NSString for sort-friendly
 * string normalization (German umlaut expansion), and
 * the LSSort class for KVC-based array sorting.
 */

typedef enum {
    LSAscendingOrder  = -1,
    LSDescendingOrder =  1
} LSOrdering;

/**
 * @category NSString(SortMiscStrings)
 * @brief Normalizes strings for locale-aware sorting.
 *
 * Expands German umlauts and sharp-s into their ASCII
 * equivalents (e.g. "ae" for U+00E4) so that
 * case-insensitive comparison produces a natural sort
 * order.
 */
@interface NSString(SortMiscStrings)

- (NSString *)sortString;

@end

/**
 * @class LSSort
 * @brief Sorts arrays of KVC-compliant objects by key.
 *
 * LSSort sorts an array of objects using key-value coding
 * to extract sort values. It supports ascending and
 * descending ordering, simple key sorting, and
 * relationship-key sorting where a related object's
 * attribute is used as the comparison value.
 *
 * @see LSSortCommand
 */
@interface LSSort : NSObject
{
  NSArray    *sortArray;
  LSOrdering ordering;
  id         sortContext;
}

+ (id)sortWithArray:(NSArray *)_sortArray andContext:_sortContext;

- (id)initWithArray:(NSArray *)_sortArray andContext:_sortContext;

- (void)setSortArray:(NSArray *)_sortArray;
- (void)setSortContext:(id)_sortContext;
- (void)setOrdering:(LSOrdering)_ordering;
- (LSOrdering)ordering;

- (NSArray *)sortedArray;

// sorting

- (NSArray *)sortArray:(NSArray *)_array
  inContext:(id)_context
  ordering:(LSOrdering)_ordering;
/* _context = <key> */

- (NSArray *)sortArrayWithRelKey:(NSArray *)_array
  inContext:(id)_context
  ordering:(LSOrdering)_ordering;
/*  _context = {
 *    key    = <key>
 *    relKey = <relKey>
 *  }
 */

@end

#endif /* __LSLogic_LSFoundation_LSSort_H__ */
