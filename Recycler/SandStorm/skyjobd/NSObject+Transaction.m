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

#include "NSObject+Transaction.h"
#include "common.h"
#include <OGoDaemon/SDXmlRpcFault.h>

@interface NSObject(CommandContext)
- (id)commandContext;
@end /* NSObject(CommandContext) */

@implementation NSObject(Transaction)

- (BOOL)isCurrentTransactionCommitted {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    if ([ctx isTransactionInProgress]) {
      if (![ctx commit]) {  
        [self logWithFormat:@"couldn't commit transaction ..."];
        return NO;
        //return [SDXmlRpcFault couldntCommitTransactionFault];
      }
    }
  }
  return YES;
}

- (NSString *)_urlStringForGlobalId:(id)_gid {
  return [[[[self commandContext] documentManager]
                  urlForGlobalID:_gid] absoluteString];
}

@end /* NSObject(Transaction) */
