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

#include "SxUserHomePage.h"
#include "common.h"
#include <LSFoundation/LSFoundation.h>

@implementation SxUserHomePage

- (void)dealloc {
  [self->team release];
  [super dealloc];
}

/* accessors */

- (void)setTeam:(id)_team {
  ASSIGN(self->team, _team);
}
- (id)team {
  return self->team;
}
- (NSString *)teamID {
  id d;
  
  d = [[self team] valueForKey:@"description"];
  return [d isNotNull] ? [d stringValue] : nil;
}

- (NSString *)title {
  return [NSString stringWithFormat:
                   @"User Homepage of Account '%@'",
                   [[self account] valueForKey:@"login"]];
}

- (NSArray *)teamsForCurrentAccount {
  id acc;

  if ((acc = [self account]) != nil) {
    LSCommandContext *cmdctx;

    if ((cmdctx = [self commandContext]) != nil) {
      return [cmdctx runCommand:@"account::teams",
                     @"account", acc, nil];
    }
  }
  return nil;
}

/* URL generation */

- (NSString *)webCalURLBase {
  NSString *base;
  
  base = [self zsBaseURL];
  
  base = [base stringByReplacingString:@"http://"  withString:@"webcal://"];
  return [base stringByReplacingString:@"https://" withString:@"webcals://"];
}

- (NSString *)teamURLiCal {
  NSString *base;
  
  base = [self webCalURLBase];
  base = [base stringByAppendingPathComponent:@"Groups"];
  base = [base stringByAppendingPathComponent:
                [[[self team] valueForKey:@"login"] stringByEscapingURL]];
  base = [base stringByAppendingPathComponent:@"Calendar"];
  base = [base stringByAppendingPathComponent:@"calendar.ics"];
  return base;
}

- (NSString *)teamURLHTTP {
  NSString *base;
  
  base = [self zsBaseURL];
  base = [base stringByAppendingPathComponent:@"Groups"];
  base = [base stringByAppendingPathComponent:
                [[self teamID] stringByEscapingURL]];
  base = [base stringByAppendingPathComponent:@"Calendar"];
  base = [base stringByAppendingPathComponent:@"calendar.ics"];
  return base;
}

- (NSString *)teamURLRSS {
  NSString *base;
  
  base = [self zsBaseURL];
  base = [base stringByAppendingPathComponent:@"Groups"];
  base = [base stringByAppendingPathComponent:
                [[self teamID] stringByEscapingURL]];
  base = [base stringByAppendingPathComponent:@"Calendar"];
  base = [base stringByAppendingPathComponent:@"calendar.rss"];
  return base;
}

- (NSString *)pCalURLHTTP {
  NSString *base;

  base = [self zsBaseURL];
  base = [base stringByAppendingPathComponent:@"Calendar"];
  return [base stringByAppendingPathComponent:@"calendar.ics"];
}

- (NSString *)pCalURLRSS {
  NSString *base;

  base = [self zsBaseURL];
  base = [base stringByAppendingPathComponent:@"Calendar"];
  return [base stringByAppendingPathComponent:@"calendar.rss"];
}

- (NSString *)pCalURLiCal {
  NSString *base;
  
  base = [self webCalURLBase];

  base = [base stringByAppendingPathComponent:@"Calendar"];
  base = [base stringByAppendingPathComponent:@"calendar.ics"];
  return base;
}

- (NSString *)teamDescription {
  return [NSString stringWithFormat:@"iCal calendar for team '%@'",
                     [self teamID]];
}

- (NSDictionary *)settings {
  NSDictionary *set;

  set =  [NSDictionary dictionaryWithObjectsAndKeys:
                        [[self zsBaseURL]
                               stringByAppendingPathComponent:@"settings"],
                        @"Settings",
                        nil];

  return [NSArray arrayWithObject:set];
}

@end /* SxUserHomePage */
