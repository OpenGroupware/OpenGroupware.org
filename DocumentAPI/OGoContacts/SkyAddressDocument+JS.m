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

#include "SkyAddressDocument.h"

/*
  supported JS properties:

    BOOL   isReadable   (readonly)
    BOOL   isWriteable  (readonly)
    BOOL   isRemovable  (readonly)

  supported JS functions:
    
    Object     getAttribute(key [,ns])
*/

#include "common.h"

@implementation SkyAddressDocument(JSSupport)

static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;

static void _ensureBools(void) {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];
}

- (id)_jsprop_isReadable {
  _ensureBools();
  return yesNum;
}
- (id)_jsprop_isWriteable {
  _ensureBools();
  return noNum;
}
- (id)_jsprop_isRemovable {
  _ensureBools();
  return noNum;
}

/* attribute methods */

- (id)_jsfunc_getAttribute:(NSArray *)_args {
  unsigned count;

  if ((count = [_args count]) == 0)
    return nil;
  else if (count == 1)
    return [self valueForKey:[_args objectAtIndex:0]];
  else {
    NSString *key;
    NSString *ns;
    
    key = [_args objectAtIndex:0];
    ns  = [_args objectAtIndex:1];
    
    key = [ns length] > 0
      ? [NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
    
    return [self valueForKey:key];
  }
}

/* methods */

- (id)_jsfunc_remove:(NSArray *)_args {
  _ensureBools();
#if 0
  return [self delete] ? yesNum : noNum;
#endif
  return noNum;
}

- (id)_jsfunc_save:(NSArray *)_args {
  //unsigned count;
  _ensureBools();
#if 0
  if ((count = [_args count]) == 0) {
    if ([self save])
      return yesNum;
    
    return noNum;
  }
#endif
  return noNum;
}

@end /* SkyAddressDocument(JSSupport) */
