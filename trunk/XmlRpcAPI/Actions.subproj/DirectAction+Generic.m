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

#include "DirectAction.h"
#include "common.h"
#include "EOControl+XmlRpcDirectAction.h"

@implementation DirectAction(Generic)

/* access */


/*
  Returns true or false if the object with url _access has access (_op (rw..))
  to the objects referred as urls in _objs

  Parameters:
    op:     string containing the char flags, eg: 'rw' for read/write
    objs:   array of OGo URLs, eg: ( 10000, 10001 )
    access: OGo URL to the principal to test for (default: login account)
*/
- (id)access_operationAllowedOnObjectsForAccessAction:(id)_op
  :(id)_objs:(id)_access
{
  LSCommandContext *cmdctx;
  SkyAccessManager *accessManager;
  id      docManager, accessId;
  NSArray *objIds;
  BOOL    ok;

  /* handle parameters */
  
  if (_objs == nil || _op == nil)
    return nil;
  
  if (![_objs isKindOfClass:[NSArray class]] &&
      ![_objs isKindOfClass:[NSSet class]]) {
    if ([_objs isKindOfClass:[NSString class]])
      _objs = [_objs componentsSeparatedByString:@","];
  }
  
  /* process */
  
  cmdctx     = [self commandContext];
  docManager = [cmdctx documentManager];
  objIds     = [docManager globalIDsForURLs:_objs];
  if (![_access isNotNull]) {
    accessId = [[cmdctx valueForKey:LSAccountKey] globalID];
  }
  else {
    NSArray *accessArray;
    
    accessArray = [NSArray arrayWithObject:_access];
    accessId    = [[docManager globalIDsForURLs:accessArray] lastObject];
  }

  accessManager = [cmdctx accessManager];
  ok = [accessManager operation:_op
		      allowedOnObjectIDs:objIds
		      forAccessGlobalID:accessId];
  
  return [NSNumber numberWithBool:ok];
}

/*
  Set the access given access right (_op) to the object referred as url
  in _obj to the object _access (also referred as url. Returns true or false
  on success or failed.

  Parameters:
    op:     string containing the char flags, eg: 'rw' for read/write
    obj:    OGo URL of the object (eg: "10000")
    access: OGo URL to the principal to test for (default: login account)
*/
- (id)access_setOperationOnObjectForAccessAction:(id)_op:(id)_obj:(id)_access {
  LSCommandContext *cmdctx;
  SkyAccessManager *accessManager;
  id   docManager, objId, accessId;
  BOOL ok;
  
  if (_op == nil || _obj == nil)
    return nil;
  
  cmdctx     = [self commandContext];
  docManager = [cmdctx documentManager];
  objId      = [[docManager globalIDsForURLs:[NSArray arrayWithObject:_obj]]
                            lastObject];
  if (![_access isNotNull])
    accessId = [[cmdctx valueForKey:LSAccountKey] globalID];
  else {
    accessId   = [[docManager globalIDsForURLs:
                              [NSArray arrayWithObject:_access]] lastObject];
  }
  
  accessManager = [cmdctx accessManager];
  ok = [accessManager setOperation:_op
		      onObjectID:objId
		      forAccessGlobalID:accessId];
  return [NSNumber numberWithBool:ok];
}

@end /* DirectAction(Generic) */
