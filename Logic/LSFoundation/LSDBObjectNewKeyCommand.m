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

#include "LSDBObjectNewKeyCommand.h"
#include "common.h"
#include <unistd.h>

@interface LSDBObjectNewKeyCommand(PrivateMethods)
- (EOAdaptorChannel *)databaseAdaptorChannel;
@end

@implementation LSDBObjectNewKeyCommand

+ (int)version {
  return 1;
}

- (void)dealloc {
  [self->entity release];
  [super dealloc];
}

/* accessors */

- (void)setEntity:(EOEntity *)_entity {
  ASSIGN(self->entity, _entity);
}
- (EOEntity *)entity {
  return self->entity;
}

/* ops */

- (void)_prepareForExecutionInContext:(id)_context {
}

- (void)_validateKeysForContext:(id)_context {
  [self assert:(self->entity != nil)
        reason:@"no entity set for primary key generation"];
}

- (void)_executeInContext:(id)_context {
  EOAdaptorChannel *adChannel = [self databaseAdaptorChannel];
  NSDictionary     *pkey      = nil;
  int              cntPk      = 1;

#if 1
  while (YES) {
    if (cntPk > 1)
      NSLog(@"WARNING: get primary key record failed %d times", cntPk);

    pkey = [adChannel primaryKeyForNewRowWithEntity:[self entity]];
    if (pkey != nil)
      break;
    
    sleep(cntPk);
    [self assert:(cntPk != 100)
          reason:@"failed after 100 to get primary key record"];
    cntPk++;
  }
#else  
  pkey = [adChannel primaryKeyForNewRowWithEntity:[self entity]];
  [self assert:(pkey != nil)       reason:@"got no primary key record."];
#endif  
  [self assert:([pkey count] == 1) reason:@"generated invalid primary key."];

  [self setReturnValue:[[pkey objectEnumerator] nextObject]];
}

- (void)_executeCommandsInContext:(id)_context {
}

- (void)_validateInContext:(id)_context {
}

// database stuff

- (EODatabaseChannel *)databaseChannel {
  return [activeContext valueForKey:LSDatabaseChannelKey];
}

- (EOAdaptorChannel *)databaseAdaptorChannel {
  return [[self databaseChannel] adaptorChannel];
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  [self assert:(_key != nil) 
        reason:@"passed invalid key to -takeValue:forKey:"];
  
  if ([_key isEqualToString:@"entity"])
    [self setEntity:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  [self assert:(_key != nil) reason:@"passed invalid key to -valueForKey:"];

  if ([_key isEqualToString:@"entity"])
    return [self entity];

  return [super valueForKey:_key];
}

@end /* LSDBObjectNewKeyCommand */
