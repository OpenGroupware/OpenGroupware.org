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

#include "SkyAptAction.h"
#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>

@implementation SkyAptAction(Logging)

- (BOOL)_addLog:(NSString *)_logText
         action:(NSString *)_action
         toApId:(NSNumber *)_oid
{
  if (![_logText length]) {
    NSLog(@"%s invalid log text: %@", __PRETTY_FUNCTION__, _logText);
    return NO;
  }
  if (![_action length]) {
    NSLog(@"%s invalid action: %@", __PRETTY_FUNCTION__, _action);
    return NO;
  }
  if ([_oid intValue] < 10000) {
    NSLog(@"%s invalid objectId: %@", __PRETTY_FUNCTION__, _oid);
  }
  [[self commandContext] runCommand:@"object::add-log",
                         @"logText", _logText,
                         @"action",  _action,
                         @"oid",     _oid,
                         nil];
  [self _ensureCurrentTransactionIsCommitted];
  return YES;
}

@end /* SkyAptAction(Logging) */
