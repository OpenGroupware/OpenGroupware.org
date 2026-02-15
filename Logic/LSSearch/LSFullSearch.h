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

#ifndef __LSLogic_LSSearch_LSFullSearch_H__
#define __LSLogic_LSSearch_LSFullSearch_H__

#include <LSSearch/LSBaseSearch.h>

/**
 * @class LSFullSearch
 *
 * Constructs EOSQLQualifier format strings for fulltext
 * searches. A fulltext search matches a search string
 * against every string attribute of an EOEntity and its
 * related entities, using LIKE/ILIKE expressions.
 *
 * The actual database fetch is performed by the command
 * (LSFullSearchCommand); this class is only responsible
 * for building the qualifier expression.
 *
 * Key properties:
 *  - entity: the primary EOEntity to search.
 *  - relatedEntities: additional entities whose string
 *    attributes are included in the search.
 *  - searchString: the user-supplied search text; '*'
 *    wildcards are converted to SQL '%' patterns.
 *  - includesOwnAttributes: whether to search the
 *    primary entity's own attributes (default YES).
 *  - furtherSearches: nested LSFullSearch instances for
 *    compound (multi-hop) relationship searches.
 *  - foreignAttributes: the computed set of attributes
 *    belonging to related entities.
 */

@class NSArray, NSString, EOSQLQualifier, NSMutableArray;

@interface LSFullSearch : LSBaseSearch
{
  EOEntity       *entity;
  NSArray        *relatedEntities;
  NSString       *searchString;
  NSArray        *furtherSearches;
  NSMutableArray *foreignAttributes;
  NSMutableArray *searchAttributes;
  BOOL           includesOwnAttributes;
  BOOL           didCompute;
}

- (id)initWithEntity:(EOEntity *)_entity
  andEntities:(NSArray *)_relatedEntities;

/* accessors */

- (EOEntity *)entity;
- (EOSQLQualifier *)qualifier;

- (void)setIncludesOwnAttributes:(BOOL)_flag;
- (BOOL)includesOwnAttributes;

/* accessors */

- (void)setSearchString:(NSString *)_searchString;
- (NSString *)searchString;
- (void)setFurtherSearches:(NSArray *)_furtherSearches;

- (NSArray *)foreignAttributes;

@end

#endif /* __LSLogic_LSSearch_LSFullSearch_H__ */
