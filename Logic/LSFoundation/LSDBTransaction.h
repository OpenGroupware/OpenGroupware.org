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

#ifndef __LSLogic_LSFoundation_LSDBTransaction_H__
#define __LSLogic_LSFoundation_LSDBTransaction_H__

#import <Foundation/NSObject.h>

@class EODatabaseContext, EODatabaseChannel;

/**
 * @class LSDBTransaction
 * @brief Lightweight wrapper around an EODatabaseContext for
 *   transaction management.
 *
 * Provides -beginTransaction, -commitTransaction, and
 * -rollbackTransaction by delegating to the underlying
 * EODatabaseContext. Used by LSDBObjectTransactionCommand to
 * bracket sub-command execution in a database transaction.
 *
 * @see LSDBObjectTransactionCommand
 */
@interface LSDBTransaction : NSObject
{
@private
  EODatabaseContext *databaseContext;
  EODatabaseChannel *databaseChannel;
}

- (id)initWithDatabaseContext:(EODatabaseContext *)_databaseContext
  andDatabaseChannel:(EODatabaseChannel *)_databaseChannel;

- (BOOL)beginTransaction;
- (BOOL)commitTransaction;
- (BOOL)rollbackTransaction;

//accessors

- (void)setDatabaseContext:(EODatabaseContext *)_databaseContext;
- (EODatabaseContext *)databaseContext;

- (void)setDatabaseChannel:(EODatabaseChannel *)_databaseChannel;
- (EODatabaseChannel *)databaseChannel;

@end

#endif /* __LSLogic_LSFoundation_LSDBTransaction_H__ */
