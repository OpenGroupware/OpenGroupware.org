/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#include "zOGIAction.h"
#include "zOGIAction+Account.h"
#include "zOGIAction+Object.h"

@implementation zOGIAction(Account)

/* Render accounts
   _accounts must be an array of EOGenericRecords of account objects */
-(id)_renderAccounts:(NSArray *)_accounts 
          withDetail:(NSNumber *)_detail 
{
  NSMutableArray      *result;
  NSDictionary        *eoAccount;
  int                  count;

  result = [NSMutableArray arrayWithCapacity:[_accounts count]];
  for (count = 0; count < [_accounts count]; count++) 
  {
    eoAccount = [_accounts objectAtIndex:count];
    [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
       eoAccount, @"*eoObject",
       [eoAccount valueForKey:@"companyId"], @"objectId",
       @"Account", @"entityName",
       [self ZERO:[eoAccount valueForKey:@"objectVersion"]], @"version",
       [eoAccount valueForKey:@"login"], @"login",
       nil]];
    if([_detail intValue] > 0)
      for (count = 0; count < [result count]; count++)
      {  
        [self _addObjectDetails:[result objectAtIndex:count] withDetail:_detail];
      }
    [self _stripInternalKeys:[result objectAtIndex:count]];
  } /* End for-each-account loop */
  return result;
} /* End _renderAccounts */

/* Get specified accounts from logic layer */
-(NSArray *)_getUnrenderedAccountsForKeys:(id)_arg 
{
  NSArray       *accounts;

  accounts = [[[self getCTX] runCommand:@"person::get-by-globalid",
                                        @"gids", [self _getEOsForPKeys:_arg],
                                        nil] retain];
  return accounts;
} /* End _getUnrenderedAccountsForKeys */

/* Get rendered accounts at specified detail level */
-(id)_getAccountsForKeys:(id)_arg withDetail:(NSNumber *)_detail 
{
  return [self _renderAccounts:[self _getUnrenderedAccountsForKeys:_arg] 
                     withDetail:_detail];
} /* End _getAccountsForKeys */

/* Get rendered accounts at default detail level (0) */
-(id)_getAccountsForKeys:(id)_arg 
{
  return [self _renderAccounts:[self _getUnrenderedAccountsForKeys:_arg] 
                     withDetail:[NSNumber numberWithInt:0]];
} /* End _getAccountsForKeys */

/* Get one rendered account at specified detail level */
-(id)_getAccountForKey:(id)_pk withDetail:(NSNumber *)_detail 
{
  return [[self _getAccountsForKeys:_pk withDetail:_detail] objectAtIndex:0];
} /* End _getAccountForKey */

/* Get one rendered account at detail detail level (0) */
-(id)_getAccountForKey:(id)_pk 
{
  return [[self _getAccountsForKeys:_pk] objectAtIndex:0];
} /* End _getAccountForKey */

/* Get rendered account for current account at specified detail level */
-(id)_getLoginAccount:(NSNumber *)_detail 
{
  id       account;

  account   = [[self getCTX] valueForKey:LSAccountKey];
  return [self _getAccountForKey:[account valueForKey:@"companyId"] 
                       withDetail:_detail];
} /* End _getLoginAccount */

@end /* End zOGIAction(Account) */
