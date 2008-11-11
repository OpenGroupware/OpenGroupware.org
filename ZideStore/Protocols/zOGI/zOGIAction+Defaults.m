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
#include "zOGIAction+Object.h"
#include "zOGIAction+Resource.h"

@implementation zOGIAction(Defaults)

- (id)_storeDefaults:(NSDictionary *)_defaults
           withFlags:(NSArray *)_flags
{
  NSUserDefaults *defaults;
  id              tmp;

  defaults = [self _getDefaults];

  /* store time zone if provided */
  if ([[_defaults objectForKey:@"timeZone"] isNotNull]) 
    [defaults setObject:[_defaults objectForKey:@"timeZone"] 
                 forKey:@"timezone"];

  /* store notification cc address if provided */
  if ([[_defaults objectForKey:@"notificationCC"] isNotNull])
    [defaults setObject:[_defaults objectForKey:@"notificationCC"]
                 forKey:@"scheduler_ccForNotificationMails"];

  /* store calendar panel if provided */
  tmp = [_defaults objectForKey:@"calendarPanelObjectIds"];
  if ([tmp isNotNull]) {
    NSEnumerator   *enumerator;
    id              object;
    NSString       *entityName;
    NSMutableArray *accounts, *persons, *resourceNames, *teams;
   
    accounts      = [NSMutableArray arrayWithCapacity:32];
    persons       = [NSMutableArray arrayWithCapacity:32];
    resourceNames = [NSMutableArray arrayWithCapacity:32];
    teams         = [NSMutableArray arrayWithCapacity:32]; 
    enumerator = [tmp objectEnumerator];
    while((object = [enumerator nextObject]) != nil) {
      entityName = [self _getEntityNameForPKey:object];
      if ([entityName isEqualToString:@"Person"]) {
        object = [self _getUnrenderedContactForKey:object];
        if ([object isNotNull]) {
          if ([[object objectForKey:@"isAccount"] intValue]) {
            [accounts addObject:[object objectForKey:@"companyId"]];
          } else {
              [persons addObject:[object objectForKey:@"companyId"]];
            }
        }
      } else if ([entityName isEqualToString:@"Team"]) {
        if ([object isKindOfClass:[NSNumber class]]) {
          [teams addObject:object];
        } else
          [teams addObject:[NSNumber numberWithInt:[object intValue]]];
      } else if ([entityName isEqualToString:@"AppointmentResource"]) {
          object = [self _getUnrenderedResourceForKey:object];
          if ([object isNotNull])
            [resourceNames addObject:[object objectForKey:@"name"]];
          else
            [self warnWithFormat:@"Unable to retrieve resource by objectId"];
      }
    } /* end while */
    [defaults setObject:accounts forKey:@"scheduler_panel_accounts"];
    [defaults setObject:persons forKey:@"scheduler_panel_persons"];
    [defaults setObject:resourceNames forKey:@"scheduler_panel_resourceNames"];
    [defaults setObject:teams forKey:@"scheduler_panel_teams"];
  } /* end store panel */
  [defaults synchronize];
  return [self _getLoginAccount:arg1];
} /* end _storeDefaults */


/* Get the defaults structure from the command context */
- (NSUserDefaults *)_getDefaults
{
  return [[self getCTX] userDefaults];
}

/* Get the specified string value from the defaults */
- (id)_getDefault:(NSString *)_value
{
  id value;

  value = [[self _getDefaults] valueForKey:_value];
  return value;
}

/* Load the defaults file for the specified account (companyId) from
   the filesystem and return it as a dictionary.  If the user has
   noo defaults and empty dictionary is returned */
- (NSDictionary *)_getDefaultsForAccount:(id)_account {
  return [NSDictionary dictionaryWithContentsOfFile:
              [NSString stringWithFormat:@"%@/%@.defaults",
                 [[self _getDefault:@"LSAttachmentPath"] stringValue],
                 [_account stringValue]]];
} /* End _getDefaultsForAccount */

-(NSArray *)_getSchedularPanel {
  id            calendarPanel;
  NSEnumerator *enumerator;
  id            tmp;

  if (([[self _getDefault:@"scheduler_panel_accounts"] isNotNull]) ||
      ([[self _getDefault:@"scheduler_panel_persons"] isNotNull]) ||
      ([[self _getDefault:@"scheduler_panel_teams"] isNotNull])) {
    calendarPanel = [NSMutableArray arrayWithCapacity:32];
    if ([[self _getDefault:@"scheduler_panel_accounts"] isNotNull]) {
      tmp = [self _getDefault:@"scheduler_panel_accounts"];
      enumerator = [tmp objectEnumerator];
      while ((tmp = [enumerator nextObject]) != nil) {
        [calendarPanel addObject:[NSNumber numberWithInt:[tmp intValue]]];
      }
    } /* end accounts-in-panel */
    if ([[self _getDefault:@"scheduler_panel_persons"] isNotNull]) {
      tmp = [self _getDefault:@"scheduler_panel_persons"];
      enumerator = [tmp objectEnumerator];
      while ((tmp = [enumerator nextObject]) != nil) {
        [calendarPanel addObject:[NSNumber numberWithInt:[tmp intValue]]];
      }
    } /* end persons-in-panel */
    if ([[self _getDefault:@"scheduler_panel_teams"] isNotNull]) {
      tmp = [self _getDefault:@"scheduler_panel_teams"];
      enumerator = [tmp objectEnumerator];
      while ((tmp = [enumerator nextObject]) != nil) {
        [calendarPanel addObject:[NSNumber numberWithInt:[tmp intValue]]];
      }
    } /* end teams-in-panel */
    if ([[self _getDefault:@"scheduler_panel_resourceNames"] isNotNull]) {
      tmp = [self _getDefault:@"scheduler_panel_resourceNames"];
      if ([tmp count] > 0) {
        NSEnumerator *enumerator;
     
        enumerator = [tmp objectEnumerator];
        while ((tmp = [enumerator nextObject]) != nil) {
          tmp = [self _getResourceByName:tmp];
          if ([tmp isNotNull])
            [calendarPanel addObject:[tmp objectForKey:@"appointmentResourceId"]];
        } /* end while */
      } /* end array-has-contents */
    } /* end there-are-resources-in-the-panel */
  } else {
      [self logWithFormat:@"sending empty calendar panel - no defaults"];
      calendarPanel = [NSArray arrayWithObjects:nil];
    }
  return calendarPanel;
}

/* Retrieve the time zone for the specified account Id (companyID), this
   method retrieves the time zone from _getDefaultsForAccount; if the
   account has not time zone defined we return GMT. */
- (NSTimeZone *)_getTimeZoneForAccount:(id)_account {
  NSDictionary  *defaults;

  defaults = [self _getDefaultsForAccount:_account];
  if ([[defaults valueForKey:@"timezone"] isNotNull]) {
    return [NSTimeZone timeZoneWithAbbreviation:
              [[defaults valueForKey:@"timezone"] stringValue]];
  }
  return [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
} /* End _getTimeZoneForAccount */

- (NSString *)_getCCAddressForAccount:(id)_account {
  NSDictionary  *defaults;

  defaults = [self _getDefaultsForAccount:_account];
  if ([[defaults objectForKey:@"scheduler_ccForNotificationMails"] isNotNull])
    return [defaults objectForKey:@"scheduler_ccForNotificationMails"];
  return [NSString stringWithString:@""];
} /* End _getCCAddressForAccount */

@end /* end zOGIAction(Defaults) */
