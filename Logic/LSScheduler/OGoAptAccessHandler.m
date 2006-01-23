/*
  Copyright (C) 2006 Helge Hess

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

#include <LSFoundation/OGoAccessHandler.h>

/*
  OGoCompanyAccessHandler
  
  WARNING: this is work in progress!
  
  TODO: document
*/

@interface OGoAptAccessHandler : OGoAccessHandler
@end

#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation OGoAptAccessHandler

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_access
{
  /*
    Note: appointment permissions are 'special', we do not only have 'rw', but
          d - delete
	  e - edit
	  l - list (only freebusy information)
	  u - ?
	  v - view
	  Because of this the method maps 'r' to 'view' and 'e' to 'edit'. This
	  is required by the SkyObjectPropertyManager to decide whether a user
	  may edit a certain property.

    Note: permissions are checked in the interface / commands for calendar
          items. Implementing them in the access manager is "just" an
	  additional measure to provide a "better" API.
    
          Wrong: it does matter if the apt has properties, those will only
                 get fetched with appropriate permissions.
    
    When is this called? For example by the SkyObjectPropertyManager when the
    appointment viewer requests extended attributes for display.
  */
  // TODO: do we need to add caching here?
  NSDictionary *permMap;
  unsigned i, count;
  EOGlobalID *agid;
  
  if ((count = [_oids count]) == 0)
    return YES; /* well, I suppose we can allow ops on empty sets ... */
  if (![_operation isNotEmpty])
    return NO;  /* no point in allowing 'no operation' .. */
  
  /* 
     Note: Our backend currently can only check permissions of the login
           account!
  */
  
  agid = [[[self context] valueForKey:LSAccountKey] valueForKey:@"globalID"];
  if (agid != _access && ![agid isEqual:_access]) {
    [self warnWithFormat:
	    @"attempted to check appointment perms of another user"
	    @" (#gids=%d, perm=%@, login=%@, check-user=%@)",
	    [_oids count], _operation, _access, agid];
    return NO; /* we forbid what we can't check?! */
  }
  
  /* fix up permission chars */
  
  _operation = [_operation stringByReplacingString:@"r" withString:@"v"];
  _operation = [_operation stringByReplacingString:@"w" withString:@"e"];
  
  /* check */
  
  permMap =
    [[self context] runCommand:@"appointment::access", @"gids", _oids, nil];

  [self logWithFormat:@"CHECK: %@", permMap];

  for (i = 0; i < count; i++) {
    NSString *perms;
    
    perms = [permMap objectForKey:[_oids objectAtIndex:i]];
    if (![perms isNotEmpty])
      return NO; /* one object didn't have permissions at all */
    
    // TODO: do we need to compare permission masks?
    if ([perms rangeOfString:_operation].length == 0)
      return NO; /* one object didn't have the required permissions */
  }
  
  return YES; /* everything seems to be fine */
}

#if 0
// TODO: we need to override this for bulk checks (performance!)
- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_pgid
{
}
#endif

@end /* OGoAptAccessHandler */
