/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "SkyRegistryApplication.h"
#include "common.h"
#include "RegistryEntry.h"

@implementation SkyRegistryApplication(PrivateMethods)

- (void)_setupDefaults {
  static int didInitDefs = NO;
  if (!didInitDefs) {
    NSUserDefaults *ud;
    NSDictionary *defs;
    didInitDefs = YES;

    defs = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:300],
                         @"SRNamespaceTimeout",
                         nil];
    
    ud = [NSUserDefaults standardUserDefaults];
    [ud registerDefaults:defs];
  }
}

- (void)_checkDefaultSettings {
  NSUserDefaults *ud;
  NSString       *compReg = nil;
  
  ud = [self userDefaults];

  if ((compReg = [ud valueForKey:@"SxComponentRegistryURL"]) != nil) {
    NSURL *url;

    if ((url = [NSURL URLWithString:compReg]) != nil) {
      NSString *portString;
      NSNumber *woPort;
      NSHost   *host;
      
      portString = [[[ud objectForKey:@"WOPort"]
                         componentsSeparatedByString:@":"]
                         lastObject];
      
      /* check port setting */
      woPort = [NSNumber numberWithInt:[portString intValue]];
      if (![woPort isEqualToNumber:[url port]])
        [self logWithFormat:
              @"WARNING: WOPort != port of SxComponentRegistryURL (%@)",
              [url port]];
      
      /* check host settings */
      
      host = [NSHost hostWithName:[url host]];
      if (![host isEqualToHost:[NSHost hostWithName:@"localhost"]]) {
        if (![host isEqualToHost:[NSHost currentHost]])
          [self logWithFormat:
                  @"WARNING: current host (%@) != "
                  @"host of SxComponentRegistryURL (%@)",
                  [[NSHost currentHost] name], [host name]];
      }
      
      /* check scheme */
      if (![[url scheme] isEqualToString:@"http"])
        [self logWithFormat:
                @"WARNING: scheme of SxComponentRegistryURL is not 'http'"];
    }
    else
      [self logWithFormat:
              @"WARNING: Default SxComponentRegistryURL is not a valid URL"];
  }
  else
    [self logWithFormat:@"WARNING: Default SxComponentRegistryURL is not set"];
}

- (void)_setComponent:(NSString *)_component
  config:(NSDictionary *)_dict
{
  RegistryEntry *regEntry;

  regEntry = [[RegistryEntry alloc] initWithName:_component
                                    dictionary:_dict];

  [self logWithFormat:@"registering namespace '%@' for '%@'",
        _component, [_dict objectForKey:@"url"]];

  [[self registry] setObject:regEntry forKey:_component];
  RELEASE(regEntry);
}

@end /* SkyRegistryApplication(PrivateMethods) */
