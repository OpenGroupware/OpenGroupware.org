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

#include "LSDatabaseObject.h"
#import <GDLAccess/EOEntity.h>
#import <GDLAccess/EOGenericRecord.h>

@implementation LSDatabaseObject

+ (int)version {
  return 1;
}

/* OSX KVC */

- (id)handleQueryWithUnboundKey:(NSString *)_key {
  /* on OSX this will throw an exception instead of returning nil */
  return nil;
}

/* global ID */

- (EOGlobalID *)globalID {
  EOEntity   *eentity;
  EOGlobalID *gid;
  
  if ((eentity = [self entity]) == nil)
    return nil;
  
  gid = [eentity globalIDForRow:
                   [self valuesForKeys:[eentity primaryKeyAttributeNames]]];
  
  return gid;
}

@end /* LSDatabaseObject */
