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

#ifndef __LSWebInterface_LSWFoundation_WOComponent_Commands_H__
#define __LSWebInterface_LSWFoundation_WOComponent_Commands_H__

#import <NGObjWeb/WOComponent.h>
#include <LSFoundation/LSBaseCommand.h>

@class NSString, NSException;

/**
 * @category WOComponent(Commands)
 * @brief Execute OGo Logic commands from components.
 *
 * Provides variadic and dictionary-based methods to
 * run Logic commands in the session's command context.
 * Also offers transaction control (commit/rollback)
 * and error handling hooks for failed commands.
 *
 * @see WOSession(Commands)
 * @see NSObject(LSWCommands)
 */
@interface WOComponent(Commands)

// command in 'domain::cmd' form
- (id)runCommand:(NSString *)_command,...;
- (id)runCommand1:(NSString *)_command,...; // OneObject
- (id)runCommandN:(NSString *)_command,...; // ManyObjects
- (id)runCommand:(NSString *)_command object:(id)_object;

- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args;
- (id)runCommandInTransaction:(NSString *)_command,...;
- (id)runCommandInTransaction:(NSString *)_comm arguments:(NSDictionary *)_args;

// Controlling transactions (no begin required)

- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)isTransactionInProgress;

// errors

- (void)handleFailedTransactionCommit;
- (void)handleFailedCommand:(id<LSCommand>)_command;
- (void)handleException:(NSException *)_exc fromCommand:(id<LSCommand>)_command;

@end

#endif /* __LSWebInterface_LSWFoundation_WOComponent_Commands_H__ */
