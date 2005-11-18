/*
  Copyright (C) 2004-2005 Helge Hess

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

#include "EOQualifier+PersonUI.h"
#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation EOQualifier(PersonUI)

+ (EOQualifier *)qualifierForGlobalID:(EOGlobalID *)_gid {
  if (_gid == nil) return nil;
  return [[[EOKeyValueQualifier alloc] initWithKey:@"globalID"
                                       operatorSelector:
                                         EOQualifierOperatorEqual
                                       value:_gid] autorelease];
}

+ (EOQualifier *)qualifierForPersonNameString:(NSString *)_s {
  static NSString *qfmt =
    @"(name LIKE '*%@*') OR (firstname LIKE '*%@*') OR "
    @"(nickname LIKE '*%@*') OR (login LIKE '*%@*')";
  NSMutableString *qs;
  EOQualifier *q;

  _s = [_s stringByTrimmingSpaces];
  
  qs = [[NSMutableString alloc] initWithCapacity:64];
  
  if (![_s isNotEmpty])
    ; /* keep length at 0 */
  else if ([_s rangeOfString:@" "].length == 0)
    [qs appendFormat:qfmt, _s, _s, _s, _s];
  else {
    NSArray  *strings;
    unsigned i, count;
    
    strings = [_s componentsSeparatedByString:@" "];
    for (i = 0, count = [strings count]; i < count; i++) {
      NSString *s;
      
      s = [[strings objectAtIndex:i] stringByTrimmingSpaces];
      if ([s length] == 0) continue;
      
      if ([qs length] > 0) [qs appendString:@" OR "];
      [qs appendFormat:qfmt, s, s, s, s];
    }
  }
  
  if (![qs isNotEmpty])
    [qs setString:@"1=1"];
  
  /* build qualifier */
  q = [EOQualifier qualifierWithQualifierFormat:qs];
  [qs release]; qs = nil;
  return q;
}

+ (EOQualifier *)qualifierForPersonFullSearch:(NSString *)_s {
  EOQualifier *q;
  
  if ([_s isEqualToString:@"%"]) _s = @"";
  
  q = [[EOKeyValueQualifier alloc] initWithKey:@"fullSearchString"
                                   operatorSelector:EOQualifierOperatorLike
                                   value:_s];
  return [q autorelease];
}

+ (EOQualifier *)qualifierForPersonPrimaryKeys:(NSArray *)_pkeys {
  EOQualifier *q;
  
  // TODO: document why we need this fake object
  if ([_pkeys count] == 0) _pkeys = [NSArray arrayWithObject:@"0"];
  
  // TODO: EOQualifierOperatorEqual is wrong, should be "in" or something like
  //       that
  q = [[EOKeyValueQualifier alloc] initWithKey:@"companyId"
                                   operatorSelector:EOQualifierOperatorEqual
                                   value:_pkeys];
  return [q autorelease];
}

@end /* EOQualifier(PersonUI) */
