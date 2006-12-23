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

#include <OGoRawDatabase/SkyDBDocument.h>

/*
  supported JS properties:
    BOOL   isVersioned  (readonly)
    BOOL   isReadable   (readonly)
    BOOL   isWriteable  (readonly)
    BOOL   isRemovable  (readonly)
    BOOL   isEdited     (readonly)
    BOOL   isNew        (readonly)

  supported JS functions:

    Object getAttribute(name [,ns-uri])
    BOOL   hasAttribute(name [,ns-uri])
    BOOL   setAttribute(name [,ns-uri], value)
    BOOL   removeAttribute(name [,ns-uri])

    BOOL   save()
    BOOL   reload()
*/

#include "common.h"

@implementation SkyDBDocument(JSSupport)

- (id)_jsprop_isVersioned {
  return [NSNumber numberWithBool:NO];
}

- (id)_jsprop_isReadable {
  return [NSNumber numberWithBool:YES];
}
- (id)_jsprop_isWriteable {
  return [NSNumber numberWithBool:YES];
}
- (id)_jsprop_isRemovable {
  return [NSNumber numberWithBool:[self isDeletable]];
}
- (id)_jsprop_isEdited {
  return [self valueForKey:@"isEdited"];
}
- (id)_jsprop_isNew {
  return [NSNumber numberWithBool:[self isNew]];
}

- (id)_jsfunc_getAttribute:(NSArray *)_args {
  unsigned count;
  
  if ((count = [_args count]) == 0)
    return nil;
  else if (count == 1)
    return [self valueForKey:[[_args objectAtIndex:0] stringValue]];
  else
    return nil;
}

- (id)_jsfunc_hasAttribute:(NSArray *)_args {
  return [NSNumber numberWithBool:([self _jsfunc_getAttribute:_args] != nil)];
}

- (id)_jsfunc_setAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  id       value;
  BOOL     result;
  
  if ((count = [_args count]) < 2) {
    return [NSNumber numberWithBool:NO];
  }
  else if (count == 2) {
    key   = [_args objectAtIndex:0];
    value = [_args objectAtIndex:1];
  }
  else {
    return [NSNumber numberWithBool:NO];
  }
  
  result = YES;
  NS_DURING
    [self takeValue:value forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return [NSNumber numberWithBool:result];
}

- (id)_jsfunc_removeAttribute:(NSArray *)_args {
  return [NSNumber numberWithBool:NO];
}

- (id)_jsfunc_save:(NSArray *)_args {
  return [NSNumber numberWithBool:[self save]];
}
- (id)_jsfunc_remove:(NSArray *)_args {
  return [NSNumber numberWithBool:[self delete]];
}
- (id)_jsfunc_revert:(NSArray *)_args {
  return [NSNumber numberWithBool:[self revert]];
}

@end /* SkyDBDocument */
