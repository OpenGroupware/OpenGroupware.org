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

#include "SxSQLQuery.h"
#include "SxSQLQueryResultEnumerator.h"
#include "NSString+DBName.h"
#include "common.h"

@implementation SxSQLQuery

static BOOL sqlDebugOn = NO;

+ (void)initialize {
  static BOOL didInit = NO;
  if (!didInit) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    sqlDebugOn = [ud boolForKey:@"SxDebugSQL"];
  }
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if ((self = [super init])) {
    self->ctx = [_ctx retain];
  }
  return self;
}
- (id)init {
  return [self initWithContext:nil];
}

- (void)dealloc {
  [self->ctx release];
  [super dealloc];
}

/* database type */

- (BOOL)isPostgreSQL {
  return [[self modelName] isPostgreSQL];
}
- (BOOL)isOracle {
  return [[self modelName] isOracle];
}
- (BOOL)isFrontbase {
  return [[self modelName] isFrontbase];
}
- (BOOL)isSybase {
  return [[self modelName] isSybase];
}

/* low level things */

- (LSCommandContext *)commandContext {
  return self->ctx;
}

- (EOAdaptorChannel *)adaptorChannel {
  return [[[self commandContext] 
	         valueForKey:LSDatabaseChannelKey]
	         adaptorChannel];
}

  
- (id)loginPrimaryKey {
  id tmp;
  tmp = [[[self commandContext] 
	        valueForKey:LSAccountKey] 
	        valueForKey:@"companyId"];
  return tmp;
}

- (NSString *)modelName {
  static NSString *modelName = nil;
  if (modelName == nil) {
    modelName = [[[NSUserDefaults standardUserDefaults]
		                  stringForKey:@"LSModelName"] copy];
    if ([modelName length] == 0)
      modelName = @"PostgreSQL";
  }
  return modelName;
}

- (BOOL)isSQLDebugOn {
  return sqlDebugOn;
}
- (BOOL)isDebuggingEnabled {
  return sqlDebugOn;
}

/* execute the query */

- (SxSQLQueryResultEnumerator *)createFetchEnumerator {
  SxSQLQueryResultEnumerator *e;
  LSCommandContext  *cmdctx;
  EOAdaptorChannel  *ch;
  
  /* setup */
  
  if ((cmdctx = [self commandContext]) == nil) {
    [self debugWithFormat:@"got no command context ..."];
    return nil;
  }
  
  /* begin transaction */
  
  if (![cmdctx isTransactionInProgress]) {
    if (![cmdctx begin]) {
      [self logWithFormat:@"ERROR: could not begin transaction ..."];
      return nil;
    }
  }
  if ((ch = [self adaptorChannel]) == nil) {
    [self logWithFormat:@"ERROR: got no channel ..."];
    if ([cmdctx isTransactionInProgress]) [cmdctx rollback];
    return nil;
  }
  
  /* setup enumerator */
  
  e = [[SxSQLQueryResultEnumerator alloc] initWithSQLQuery:self];
  return [e autorelease];
}

- (BOOL)finalizeFetchEnumerator:(SxSQLQueryResultEnumerator *)_e {
  return YES;
}

- (NSEnumerator *)run {
  SxSQLQueryResultEnumerator *e;
  NSException *error;
  NSString    *sql;

  /* generate sql */
  
  sql = [self generateSQL];
  
  if ([sql length] == 0) {
    [self logWithFormat:@"ERROR: did not generate any SQL ..."];
    return nil;
  }
  
  if ([self isSQLDebugOn])
    [self logWithFormat:@"SQL:\n%@", sql];
  
  /* setup enumerator */
  
  if ((e = [self createFetchEnumerator]) == nil) {
    [self debugWithFormat:@"got no fetch enumerator ..."];
    return nil;
  }
  [self debugWithFormat:@"  Enumerator: %@", e];
  
  /* trigger SQL */
  
  if ((error = [e evaluateSQL:sql])) {
    [self logWithFormat:@"could not evaluate SQL: %@", error];
    return nil;
  }
  
  /* return enumerator */
  return e;
}

- (NSEnumerator *)runAndCommit {
  SxSQLQueryResultEnumerator *e;
  e = (id)[self run];
  [e setAutoCommit:YES];
  return e;
}
- (NSEnumerator *)runAndRollback {
  SxSQLQueryResultEnumerator *e;
  e = (id)[self run];
  [e setAutoRollback:YES];
  return e;
}

/* SQL generation */

- (void)regenerateSQL {
  /* SQL could be cached ... */
}

- (void)generateSelect:(NSMutableString *)_sql {
}
- (void)generateFrom:(NSMutableString *)_sql {
}

- (BOOL)shouldGenerateWhere {
  return NO;
}
- (void)generateWhere:(NSMutableString *)_sql {
}

- (BOOL)shouldGenerateOrderBy {
  return NO;
}
- (void)generateOrderBy:(NSMutableString *)_sql {
}

- (void)generateSQL:(NSMutableString *)_sql {
  [_sql appendString:@"SELECT "];
  [self generateSelect:_sql];
  [_sql appendString:@" FROM "];
  [self generateFrom:_sql];
  
  if ([self shouldGenerateWhere]) {
    [_sql appendString:@" WHERE "];
    [self generateWhere:_sql];
  }
  if ([self shouldGenerateOrderBy]) {
    [_sql appendString:@" ORDER BY "];
    [self generateOrderBy:_sql];
  }
  
  // TODO: if not Sybase ..
  if ([self isPostgreSQL])
    [_sql appendString:@";"];
}

- (NSString *)generateSQL {
  NSMutableString *ms;
  NSString *s;
  
  ms = [[NSMutableString alloc] init];
  [self generateSQL:ms];
  s = [ms copy];
  [ms release];
  return [s autorelease];
}

/* model specialties */

- (NSString *)nameColumn {
  if ([self isPostgreSQL])
    return @"name";

  if (([self isOracle]) ||
      ([self isFrontbase]))
    return @"fname";
  
  return @"name";
}

- (BOOL)isNumberReserved {
  /* whether "number" is a reserved word */
  if ([self isOracle])
    return YES;
  return NO;
}

- (BOOL)dbHasAnsiOuterJoins {
  /*
    check whether DB supports outer joins in FROM clause,
    eg: LEFT OUTER JOIN company_value email1
             ON (email1.company_id = c1.company_id AND 
                 email1.attribute = 'email1')
  */
  if ([self isPostgreSQL])
    return YES;
  
  return NO;
}

/* basic generation */

- (void)addFirstColumn:(NSString *)_c as:(NSString *)_a 
  to:(NSMutableString *)_sql 
{
  [_sql appendString:_c];
  [_sql appendString:@" AS "];
  [_sql appendString:_a];
}
- (void)addColumn:(NSString *)_c as:(NSString *)_a to:(NSMutableString *)_sql {
  [_sql appendString:@", "];
  [self addFirstColumn:_c as:_a to:_sql];
}
- (void)addColumn:(NSString *)_c of:(NSString *)_table
  as:(NSString *)_a to:(NSMutableString *)_sql 
{
  [_sql appendString:@", "];
  [_sql appendString:_table];
  [_sql appendString:@"."];
  [_sql appendString:_c];
  [_sql appendString:@" AS "];
  [_sql appendString:_a];
}

- (void)addLeftOuterJoin:(NSString *)_name toFromOn:(NSString *)_table 
  query:(NSString *)_query to:(NSMutableString *)_sql
{
  [_sql appendString:@" LEFT OUTER JOIN "];
  [_sql appendString:_table];
  [_sql appendString:@" "];
  [_sql appendString:_name];
  [_sql appendString:@" ON ("];
  [_sql appendString:_query];
  [_sql appendString:@")"];
}

- (void)addStringValue:(NSString *)_str to:(NSMutableString *)_sql
{
  if ([_str rangeOfString:@"'"].length > 0)
    _str = [_str stringByReplacingString:@"'" withString:@"\\'"];
  [_sql appendString:_str];
}

@end /* SxSQLQuery */
