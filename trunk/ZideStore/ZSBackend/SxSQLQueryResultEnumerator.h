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

#ifndef __Contacts_SxSQLQueryResultEnumerator_H__
#define __Contacts_SxSQLQueryResultEnumerator_H__

#import <Foundation/NSEnumerator.h>

@class NSArray, NSException;
@class EOAdaptorChannel;
@class LSCommandContext;
@class SxSQLQuery;

@interface SxSQLQueryResultEnumerator : NSEnumerator
{
  SxSQLQuery        *query;
  EOAdaptorChannel  *ch;
  LSCommandContext  *cmdctx;
  NSArray           *attributes;
  
  struct {
    int commit:1;
    int rollback:1;
    int reserved:30;
  } flags;
}

- (id)initWithSQLQuery:(SxSQLQuery *)_query;

/* accessors */

- (EOAdaptorChannel *)channel;
- (LSCommandContext *)commandContext;

- (void)setAutoCommit:(BOOL)_flag;
- (BOOL)doesAutoCommit;
- (void)setAutoRollback:(BOOL)_flag;
- (BOOL)doesAutoRollback;

/* operations */

- (NSException *)evaluateSQL:(NSString *)_sql;
- (id)nextObject;
- (void)finalize;
- (void)cancelFetch;

@end

#endif /* __Contacts_SxSQLQueryResultEnumerator_H__ */
