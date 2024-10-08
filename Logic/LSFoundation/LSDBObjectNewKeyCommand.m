/*
  Copyright (C) 2000-2007 SKYRIX Software AG

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

- (unsigned int)keyBatchSize {
  return 10; // IMPORTANT: this MUST match the key generator algorithm!!
}

- (void)_executeInContext:(id)_context {
  EOAdaptorChannel *adChannel;
  NSDictionary     *pkey      = nil;
  int              cntPk      = 1;
  int              avail      = 0;
  NSNumber         *baseKey   = nil;
  
  /* check key cache for more keys */
  
  if ((baseKey = [_context valueForKey:@"__sysNewKey_base"]) != nil) {
    avail = [[_context valueForKey:@"__sysNewKey_avail"] intValue];
    if (avail > 0) {
      unsigned int value = [baseKey unsignedIntValue];
      value += [self keyBatchSize] - avail;
      
      /* reduce availability */
      avail--;
      if (avail > 0) {
	[_context takeValue:[NSNumber numberWithInt:avail] 
		  forKey:@"__sysNewKey_avail"];
      }
      else {
	[_context takeValue:nil forKey:@"__sysNewKey_base"];
	[_context takeValue:nil forKey:@"__sysNewKey_avail"];
      }
      
      [self setReturnValue:[NSNumber numberWithUnsignedInt:value]];
      return;
    }
    
    [_context takeValue:nil forKey:@"__sysNewKey_base"];
    [_context takeValue:nil forKey:@"__sysNewKey_avail"];
    baseKey = nil;
  }
  
  /* retrieve new keys from adaptor */
  
  adChannel = [self databaseAdaptorChannel];
#if 1
  // TBD: why is that?
  while (YES) {
    if (cntPk > 1)
      [self warnWithFormat:@"get primary key record failed %d times!", cntPk];
    
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

  baseKey = [[pkey objectEnumerator] nextObject];
  [self setReturnValue:baseKey];
  
  
  /* cache base key sequence for subsequent calls */
  
  avail = [self keyBatchSize] - 1;
  if (avail > 0) {
    // Note: at least on PG we don't need to care about ROLLBACKs, the sequence
    //       is serialized across transactions
    [_context takeValue:baseKey forKey:@"__sysNewKey_base"];
    [_context takeValue:[NSNumber numberWithInt:avail] 
	      forKey:@"__sysNewKey_avail"];
  }
}

- (void)_executeCommandsInContext:(id)_context {
}

- (void)_validateInContext:(id)_context {
}

/* database stuff */

- (EODatabaseChannel *)databaseChannel {
  return [activeContext valueForKey:LSDatabaseChannelKey];
}

- (EOAdaptorChannel *)databaseAdaptorChannel {
  return [[self databaseChannel] adaptorChannel];
}

/* KVC */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"entity"])
    [self setEntity:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"entity"])
    return [self entity];

  return [super valueForKey:_key];
}

@end /* LSDBObjectNewKeyCommand */
