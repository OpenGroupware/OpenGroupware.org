/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#ifndef __Contacts_SxSQLQuery_H__
#define __Contacts_SxSQLQuery_H__

#import <Foundation/NSObject.h>

@class NSString, NSMutableString, NSEnumerator;
@class EOAdaptorChannel;
@class LSCommandContext;

@interface SxSQLQuery : NSObject
{
  LSCommandContext *ctx;
}

- (id)initWithContext:(LSCommandContext *)_ctx;

/* low level things */

- (LSCommandContext *)commandContext;
- (EOAdaptorChannel *)adaptorChannel;
- (id)loginPrimaryKey;
- (NSString *)modelName;

/* execute the query */

- (NSEnumerator *)run;
- (NSEnumerator *)runAndCommit;
- (NSEnumerator *)runAndRollback;

/* SQL generation */

- (NSString *)generateSQL;
- (void)regenerateSQL;

- (void)generateSQL:(NSMutableString *)_sql;
- (void)generateSelect:(NSMutableString *)_sql;
- (void)generateFrom:(NSMutableString *)_sql;
- (void)generateWhere:(NSMutableString *)_sql;
- (void)generateOrderBy:(NSMutableString *)_sql;
- (BOOL)shouldGenerateWhere;
- (BOOL)shouldGenerateOrderBy;

/* model specialties */

- (NSString *)nameColumn;
- (BOOL)isNumberReserved;
- (BOOL)dbHasAnsiOuterJoins;

/* basic generation */

// add: "$_c AS $_a"
- (void)addFirstColumn:(NSString *)_c as:(NSString *)_a 
  to:(NSMutableString *)_sql;

// add: ", $_c AS $_a"
- (void)addColumn:(NSString *)_c as:(NSString *)_a to:(NSMutableString *)_sql;

// add: ", $_table.$_c AS $_a"
- (void)addColumn:(NSString *)_c of:(NSString *)_table
  as:(NSString *)_a to:(NSMutableString *)_sql;

// add: " LEFT OUTER JOIN $table $name ON ($query)"
- (void)addLeftOuterJoin:(NSString *)_name toFromOn:(NSString *)_table 
  query:(NSString *)_query to:(NSMutableString *)_sql;

// add string value to string
// checks for quotes (') and replaces them with (\')
- (void)addStringValue:(NSString *)_str to:(NSMutableString *)_sql;

@end

#endif /* __Contacts_SxSQLQuery_H__ */
