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

#include "common.h"

@implementation NSObject(SkyProjectSelectionLabel)

- (NSString *)skyProjectSelectionLabel {
  // TODO: this should be called by a formatter (if the object responds to the
  //       message), not by the .wod file
  NSString *s;
  
  if ([[self entityName] isEqualToString:@"Enterprise"]) {
    NSMutableString *ms;
    
    s = [self valueForKey:@"description"];
    if (![s isNotNull]) return nil;

    ms = [NSMutableString stringWithCapacity:([s length] + 4)];
    [ms appendString:@"<"];
    [ms appendString:s];
    [ms appendString:@">"];
    
    return ms;
  }
  
  s = [self valueForKey:@"name"];
  return [s isNotNull] ? s : nil;
}

@end /* NSObject(SkyProjectSelectionLabel) */
