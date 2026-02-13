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

#ifndef __LSLogic_LSSearch_LSFullSearchCommand_H__
#define __LSLogic_LSSearch_LSFullSearchCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSMutableArray, NSString, NSDictionary, NSNumber;

/**
 * @class LSFullSearchCommand
 *
 * Command that performs a fulltext search across all
 * string attributes of an entity and its configured
 * related entities. Uses LSFullSearch to build the SQL
 * qualifiers and executes one or more fetches against
 * the database.
 *
 * Search configuration (which related entities to include
 * and how to group them) is read from the
 * "LSFullSearchConfig" user default. Supports single or
 * multiple search strings; when multiple are given,
 * results can be intersected (AND mode) or merged
 * (OR mode).
 *
 * Results are capped at "LSMaxSearchCount" (or an
 * explicit maxSearchCount) and are filtered through the
 * access manager to enforce read permissions and
 * privacy checks.
 */
@interface LSFullSearchCommand : LSDBObjectBaseCommand
{
@private
  NSDictionary   *searchConfig; // non retained
  id             searchString;
  NSNumber       *maxSearchCount;
  NSMutableArray *searches;
  BOOL           isAndMode;
}

- (void)setSearchString:(NSString *)_searchString;
- (NSString *)searchString;
- (void)setSearchStrings:(NSArray *)_searchStrings;
- (NSArray *)searchStrings;

- (void)setIsAndMode:(BOOL)_andMode;
- (BOOL)isAndMode;

- (EOSQLQualifier *)checkPermissionsFor:(EOSQLQualifier *)qualifier_ 
  context:(id)_ctx;

@end

#endif /* __LSLogic_LSSearch_LSFullSearchCommand_H__ */
