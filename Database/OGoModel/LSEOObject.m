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

#include "LSEOObject.h"
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>
#include "common.h"

@implementation LSEOObject

+ (int)version {
  return 1;
}

- (id)initWithPrimaryKey:(NSDictionary *)_pkey entity:(EOEntity *)_entity {
  if ((self = [self init])) {
    NSString *pkeyName;
    
    self->entity = [_entity retain];

    pkeyName = [[self->entity primaryKeyAttributeNames] lastObject];
    [self takeValue:[_pkey objectForKey:pkeyName] forKey:pkeyName];
  }
  return self;
}

- (void)dealloc {
  [self->entity release];
  [super dealloc];
}

/* OSX KVC */

- (id)handleQueryWithUnboundKey:(NSString *)_key {
  /* on OSX this will throw an exception instead of returning nil */
  return nil;
}

/* reflection accessors */

- (EOEntity *)entity {
  return self->entity
    ? self->entity
    : [(EOEntityClassDescription *)[self classDescription] entity];
}

- (EOGlobalID *)globalID {
  EOEntity   *eentity;
  EOGlobalID *gid;
  
  if ((eentity = [self entity]) == nil)
    return nil;

  gid = [eentity globalIDForRow:
                   [self valuesForKeys:[eentity primaryKeyAttributeNames]]];
  
  return gid;
}

@end /* LSEOObject */
