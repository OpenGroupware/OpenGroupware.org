/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#ifndef __LSLogic_LSSearch_LSExtendedSearch_H__
#define __LSLogic_LSSearch_LSExtendedSearch_H__

#include <LSSearch/LSBaseSearch.h>

@class LSGenericSearchRecord, NSArray, NSString, EOEntity, EOSQLQualifier;

/**
 * @class LSExtendedSearch
 *
 * Builds an EOSQLQualifier from a primary search record
 * and a set of related search records. Each
 * LSGenericSearchRecord maps entity attribute names to
 * search values; this class iterates over those
 * key/value pairs and constructs a combined SQL
 * qualifier format string.
 *
 * The operator property (default "AND") controls how
 * individual attribute conditions are joined within and
 * across records. The resulting qualifier uses DISTINCT
 * to avoid duplicate rows from joined entities.
 *
 * Used by LSExtendedSearchCommand to perform multi-field
 * searches on persons, enterprises, and other entities.
 */
@interface LSExtendedSearch : LSBaseSearch
{
@private
  LSGenericSearchRecord *searchRecord;
  NSArray               *relatedRecords;
  NSString              *operator;
}

- (id)initWithSearchRecord:(LSGenericSearchRecord *)_searchRecord
  andRelatedRecords:(NSArray *)_relatedRecords;

/* accessors */
  
- (EOSQLQualifier *)qualifier;
- (EOEntity *)entity;

/* accessors */

- (void)setOperator:(NSString *)_operator;
- (NSString *)operator;

- (void)setSearchRecord:(LSGenericSearchRecord *)_searchRecord;
- (LSGenericSearchRecord *)searchRecord;
- (void)setRelatedRecords:(NSArray *)_relatedRecords;
- (NSArray *)relatedRecords;

@end

#endif /* __LSLogic_LSSearch_LSExtendedSearch_H__ */
