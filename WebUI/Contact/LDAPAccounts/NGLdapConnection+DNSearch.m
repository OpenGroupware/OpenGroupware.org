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

#include "NGLdapConnection+DNSearch.h"
#include "common.h"
#include <EOControl/EOQualifier.h>
#include <NGLdap/NGLdapEntry.h>

@implementation NGLdapConnection(DNSearch)

- (NSString *)dnForUID:(NSString *)_uid atBase:(NSString *)_base {
  static NSArray *uidAttrs = nil;
  EOQualifier *q;
  NSString    *loginDN;
  id          e;

  if (_uid == nil)
    return nil;   

  if (uidAttrs == nil)
    uidAttrs = [[NSArray alloc] initWithObjects:@"uid", nil];

  q = [EOQualifier qualifierWithQualifierFormat:@"uid=%@", _uid];
  e = [self deepSearchAtBaseDN:_base qualifier:q attributes:uidAttrs];

  if (e == nil) {
    NSLog(@"%s: couldn't search LDAP server for uid %@.",
          __PRETTY_FUNCTION__, _uid);
    return nil;                      
  }
   
  loginDN = [[e nextObject] dn];

  if (loginDN == nil) {
    NSLog(@"%s: couldn't find DN for uid '%@' at base '%@'",
          __PRETTY_FUNCTION__, _uid, _base);
    return nil;                             
  }
   
  if (([e nextObject])) {
    NSLog(@"%s: found more than one LDAP records for uid %@ !!!",
          __PRETTY_FUNCTION__, _uid);
    return nil;                      
  }
   
  return loginDN;
}

@end /* NGLdapConnection(DNSearch) */
