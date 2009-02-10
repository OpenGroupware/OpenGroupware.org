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
#include "zOGIAction+Contact.h"
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Team.h"
#include "zOGIAction+Object.h"

@implementation zOGIAction(Account)

/* Render accounts
   _accounts must be an array of EOGenericRecords of account objects */
-(id)_renderAccounts:(NSArray *)_accounts withDetail:(NSNumber *)_detail {
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
    {
      [self _addObjectDetails:[result objectAtIndex:count] 
                   withDetail:_detail];
      if ([_detail intValue] & zOGI_INCLUDE_MEMBERSHIP)
      {
        [[result objectAtIndex:count] 
            setObject:[self _searchForTeams:@"mine" 
                                 withDetail:[NSNumber numberWithInt:128]
                                  withFlags:nil]
               forKey:@"_TEAMS"];
      }
    }
    [self _stripInternalKeys:[result objectAtIndex:count]];
  } /* End for-each-account loop */
  return result;
} /* end _renderAccounts */

/* Get specified accounts from Logic */
-(NSArray *)_getUnrenderedAccountsForKeys:(id)_arg {
  NSArray       *accounts;

  accounts = [[[self getCTX] runCommand:@"person::get-by-globalid",
                                        @"gids", [self _getEOsForPKeys:_arg],
                                        nil] retain];
  return accounts;
} /* end _getUnrenderedAccountsForKeys */

/* Get rendered accounts at specified detail level */
-(id)_getAccountsForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderAccounts:[self _getUnrenderedAccountsForKeys:_arg] 
                     withDetail:_detail];
} /* end _getAccountsForKeys */

/* Get rendered accounts at default detail level (0) */
-(id)_getAccountsForKeys:(id)_arg {
  return [self _renderAccounts:[self _getUnrenderedAccountsForKeys:_arg] 
                     withDetail:[NSNumber numberWithInt:0]];
} /* end _getAccountsForKeys */

/* Get one rendered account at specified detail level */
-(id)_getAccountForKey:(id)_pk withDetail:(NSNumber *)_detail {
  return [[self _getAccountsForKeys:_pk withDetail:_detail] objectAtIndex:0];
} /* end _getAccountForKey */

/* Get one rendered account at detail detail level (0) */
-(id)_getAccountForKey:(id)_pk {
  return [[self _getAccountsForKeys:_pk] objectAtIndex:0];
} /* end _getAccountForKey */

/* Get rendered account for current account at specified detail level */
-(id)_getLoginAccount:(NSNumber *)_detail {
  NSMutableDictionary     *account;
  NSMutableDictionary     *defaults;
  NSUserDefaults          *ud;
  id                       tmp;

  if ([_detail intValue] & zOGI_INCLUDE_CONTACTS)
  {
    account = [self _getContactForKey:[self _getCompanyId]
                           withDetail:_detail];
  } else
    {
      account = [self _getAccountForKey:[self _getCompanyId]
                             withDetail:_detail];
    }

  /* TODO: Implement returning the user's defaults
     [account setObject:[self _getDefaults] forKey:@"_DEFAULTS"];
     This fails because SOPE cannot encode the LSUserDefaults
     class;  perhaps we can add an encoding category? */

  ud = [self _getDefaults];
 
  defaults = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                [self _getCompanyId], @"accountObjectId",
                @"defaults", @"entityName",
                nil]; 
  if ([[self _getTimeZone] isNotNull]) {
    [defaults setObject:[[self _getTimeZone] abbreviation]
                 forKey:@"timeZone"];
    [defaults setObject:intObj([[self _getTimeZone] secondsFromGMT])
                 forKey:@"secondsFromGMT"];
    [defaults setObject:intObj([[self _getTimeZone] isDaylightSavingTime])
                 forKey:@"isDST"];
    [defaults setObject:[self _getTimeZone] forKey:@"timeZoneName"];
    [defaults setObject:intObj(1) forKey:@"isTimeZoneSet"];
  } else {
      [defaults setObject:@"GMT" forKey:@"timeZone"];
      [defaults setObject:intObj(0)
                   forKey:@"secondsFromGMT"];
      [defaults setObject:intObj(0)
                   forKey:@"isDST"];
      [defaults setObject:@"GMT" forKey:@"timeZoneName"];
      [defaults setObject:intObj(0) forKey:@"isTimeZoneSet"];
    }

  [defaults setObject:[self _getSchedularPanel]
               forKey:@"calendarPanelObjectIds"];

  if ((tmp = [self _getDefault:@"scheduler_ccForNotificationMails"]) != nil)
    [defaults setObject:tmp forKey:@"notificationCC"];
  else [defaults setObject:@"" forKey:@"notificationCC"];

  /* default read access */
  tmp = intObj([ud integerForKey:@"scheduler_default_readaccessteam"]);
  [defaults setObject:intObj([tmp intValue]) 
               forKey:@"appointmentReadAccessTeam"];

  /* default write access */
  [defaults setObject:[self _getDefaultWriteAccessFromDefaults:ud]
               forKey:@"appointmentWriteAccess"];

  [account setObject:defaults forKey:@"_DEFAULTS"];
  return account;
} /* end _getLoginAccount */

@end /* end zOGIAction(Account) */
