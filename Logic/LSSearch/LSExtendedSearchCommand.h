/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#ifndef __LSLogic_LSSearch_LSExtendedSearchCommand_H__
#define __LSLogic_LSSearch_LSExtendedSearchCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  LSExtendedSearchCommand

  (Abstract?) Superclass for eg LSExtendedSearchPersonCommand.
*/

@class NSArray, NSString, NSNumber, NSMutableDictionary;
@class EOSQLQualifier;
@class LSExtendedSearch;

@interface LSExtendedSearchCommand : LSDBObjectBaseCommand
{
@private
  LSExtendedSearch    *extendedSearch;
  NSArray             *searchRecordList;
  NSString            *operator;
  NSMutableDictionary *searchKeys;
  NSNumber            *maxSearchCount;
  NSNumber            *fetchIds;
  BOOL                fetchGlobalIDs;
}

- (void)setSearchRecordList:(NSArray *)_searchRecordList;
- (NSArray *)searchRecordList;

- (void)setFetchGlobalIDs:(BOOL)_fetchGlobalIDs;
- (BOOL)fetchGlobalIDs;

- (NSString *)operator;

/* qualifier */

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context;
- (BOOL)isNoMatchSQLQualifier:(EOSQLQualifier *)_q;

- (LSExtendedSearch *)extendedSearch;

/* support for person/enterprise */

- (id)_checkRecordsForCSVAttribute:(NSString *)_attrName;

@end

#import <Foundation/NSString.h>

@interface NSString(SQLPatterns)
- (NSString *)stringByDeletingSQLKeywordPatterns;
@end

#endif /* __LSLogic_LSSearch_LSExtendedSearchCommand_H__ */
