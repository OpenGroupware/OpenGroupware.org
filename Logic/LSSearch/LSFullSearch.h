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
// $Id$

#ifndef __LSLogic_LSSearch_LSFullSearch_H__
#define __LSLogic_LSSearch_LSFullSearch_H__

#include <LSSearch/LSBaseSearch.h>

/*
  LSFullSearch

  TODO: explain much more
  
  LSFullSearch is used to construct qualifiers for fulltext searches. A 
  fulltext search is a search on every string attribute of an EOEntity.

  Note that the search itself is done by the command, this object is only
  used to construct the required SQL expression.
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
