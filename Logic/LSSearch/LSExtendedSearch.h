/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#ifndef __LSLogic_LSSearch_LSExtendedSearch_H__
#define __LSLogic_LSSearch_LSExtendedSearch_H__

#include <LSSearch/LSBaseSearch.h>

@class LSGenericSearchRecord, NSArray, NSString, EOEntity, EOSQLQualifier;

@interface LSExtendedSearch : LSBaseSearch
{
@private
  LSGenericSearchRecord *searchRecord;
  NSArray               *relatedRecords;
  NSString              *operator;
}

- (id)initWithSearchRecord:(LSGenericSearchRecord *)_searchRecord
  andRelatedRecords:(NSArray *)_relatedRecords;
  
- (EOSQLQualifier *)qualifier;
- (EOEntity *)entity;

//accessors

- (NSString *)operator;
- (void)setOperator:(NSString *)_operator;
- (void)setSearchRecord:(LSGenericSearchRecord *)_searchRecord;
- (LSGenericSearchRecord *)searchRecord;
- (void)setRelatedRecords:(NSArray *)_relatedRecords;
- (NSArray *)relatedRecords;

@end

#endif /* __LSLogic_LSSearch_LSExtendedSearch_H__ */
