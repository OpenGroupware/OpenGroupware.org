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

#include "SkyCompanyDocument.h"

/*
  supported JS properties:

    BOOL   isReadable   (readonly)
    BOOL   isWriteable  (readonly)
    BOOL   isRemovable  (readonly)
    BOOL   isNew        (readonly)

  supported JS functions:
    
    Object     getAttribute(key [,ns])
    Address    getAddress([type])
    
    bool       remove()
    bool       save()
*/

#include "common.h"
#include "SkyAddressDocument.h"
#include <NGExtensions/EOCacheDataSource.h>

@implementation SkyCompanyDocument(JSSupport)

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
  return yesNum;
}
- (id)_jsprop_isRemovable {
  _ensureBools();
  return yesNum;
}

- (id)_jsprop_isNew {
  _ensureBools();
  return [self isNew] ? yesNum : noNum;
}

- (id)_jsprop_isEdited {
  _ensureBools();
  return [self isEdited] ? yesNum : noNum;
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
    
    key = [ns isNotEmpty]
      ? (NSString *)[NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
    
    return [self valueForKey:key];
  }
}

- (id)_jsfunc_hasAttribute:(NSArray *)_args {
  _ensureBools();
  return ([self _jsfunc_getAttribute:_args] != nil)
    ? yesNum : noNum;
}

- (id)_jsfunc_setAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  id   value;
  BOOL result;
  _ensureBools();
  
  if ((count = [_args count]) < 2) {
    return noNum;
  }
  else if (count == 2) {
    key   = [_args objectAtIndex:0];
    value = [_args objectAtIndex:1];
  }
  else {
    NSString *ns;
    
    key   = [_args objectAtIndex:0];
    ns    = [_args objectAtIndex:1];
    value = [_args objectAtIndex:2];
    
    key = [ns isNotEmpty]
      ? (NSString *)[NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
  }

  result = YES;
  NS_DURING
    [self takeValue:value forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return result ? yesNum : noNum;
}

- (id)_jsfunc_removeAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  BOOL result;
  _ensureBools();
  
  if ((count = [_args count]) == 0)
    return noNum;
  else if (count == 1)
    key = [_args objectAtIndex:0];
  else {
    NSString *ns;
    
    key = [_args objectAtIndex:0];
    ns  = [_args objectAtIndex:1];
    
    key = [ns isNotEmpty]
      ? (NSString *)[NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
  }

  result = YES;
  NS_DURING
    [self takeValue:nil forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return result ? yesNum : noNum;
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

- (NSString *)_defaultAddressType {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (id)_jsfunc_getAddress:(NSArray *)_args {
  unsigned           count;
  NSString           *ctype;
  SkyAddressDocument *address;
  
  if ((count = [_args count]) == 0)
    ctype = [self _defaultAddressType];
  else
    ctype = [[_args objectAtIndex:0] stringValue];
  
  NS_DURING
    address = [self addressForType:ctype];
  NS_HANDLER
    *(&address) = nil;
  NS_ENDHANDLER;
  
  if (address == nil) {
#if DEBUG
    NSLog(@"%s: got no address for type '%@'", __PRETTY_FUNCTION__, ctype);
#endif
    return nil;
  }
  
  return address;
}

@end /* SkyCompanyDocument(JSSupport) */
