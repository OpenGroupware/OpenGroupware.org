/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "WOResponse+ExtractSID.h"
#include "common.h"

@implementation WOResponse(ExtractSID)

- (NSString *)extractSessionID {
  NSString *s;
  NSRange  r;
  unsigned i;
  
  s = [self contentAsString];
  r = [s rangeOfString:@"wosid="];
  if (r.length == 0) return nil;
  
  r.location += r.length; // skip 'wosid='
  r.length = 0;
  
  for (i = r.location; i < [s length]; i++) {
    unichar c;
    
    c = [s characterAtIndex:i];
    if (!isxdigit(c))
      break;
    
    r.length++;
  }

  if (r.length == 0)
    return nil;
  
  return [s substringWithRange:r];
}

@end /* WOResponse(ExtractSID) */
