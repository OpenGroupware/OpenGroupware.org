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

#ifndef __LSLogic_LSFoundation_LSSystemCtxTransferCommand_H__
#define __LSLogic_LSFoundation_LSSystemCtxTransferCommand_H__

#include <LSFoundation/LSBaseCommand.h>
#include <LSFoundation/LSCommand.h>

/**
 * @class LSSystemCtxTransferCommand
 *
 * Transfers key/value pairs from an LSCommandContext to
 * a target command, then runs that command. The keys to
 * transfer are configured by setting key/value pairs on
 * this command (where each key names a context key and
 * each value names the corresponding target key on the
 * wrapped command).
 *
 * Does not require a database channel or transaction.
 */

@class NSString, NSMutableDictionary;

@interface LSSystemCtxTransferCommand : LSBaseCommand
{
@protected
  id<NSObject,LSCommand> command;
  NSMutableDictionary    *keysToTransfer;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain;

/* command methods */

- (void)_executeInContext:(id)_context;

/* accessors */

- (void)setCommand:(id<NSObject,LSCommand>)_command;
- (id<NSObject,LSCommand>)command;

@end

#endif /* __LSLogic_LSFoundation_LSSystemCtxTransferCommand_H__ */
