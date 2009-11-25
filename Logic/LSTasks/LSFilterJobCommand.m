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

#include "LSFilterJobCommand.h"
#include "common.h"

@implementation LSFilterJobCommand

- (void)dealloc {
  [self->jobList     release];
  [self->creatorId   release];
  [self->ownerId     release];
  [self->executantId release];
  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  [self setReturnValue:[self filter]];
}

- (id)filter {
  [self warnWithFormat:
	  @"%s: subclass should override this method!", __PRETTY_FUNCTION__];
  return nil;
}

/* accessors */

- (void)setJobList:(NSArray *)_jobList {
  ASSIGN(self->jobList, _jobList);
}
- (NSArray *)jobList {
  return self->jobList;
}

- (void)setExecutantId:(NSNumber *)_executantId {
  ASSIGNCOPY(self->executantId, _executantId);
}
- (NSNumber *)executantId {
  return self->executantId;
}

- (void)setCreatorId:(NSNumber *)_creatorId {
  ASSIGNCOPY(self->creatorId, _creatorId);
}
- (NSNumber *)creatorId {
  return self->creatorId;
}

- (void)setOwnerId:(NSNumber *)_ownerId {
  ASSIGNCOPY(self->ownerId, _ownerId);
}
- (NSNumber *)ownerId {
  return self->ownerId;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"jobList"]) {
    [self setJobList:_value];
    return;
  }
  if ([_key isEqualToString:@"executantId"]) {
    [self setExecutantId:_value];
    return;
  }
  if ([_key isEqualToString:@"creatorId"]) {
    [self setCreatorId:_value];
    return;
  }
  if ([_key isEqualToString:@"ownerId"]) {
    [self setOwnerId:_value];
    return;
  }

  [LSDBObjectCommandException raiseOnFail:NO object:self
			      reason:
                                [NSString stringWithFormat:
                                          @"key: %@ is not valid in"
                                          @"domain '%@' for operation '%@'.",
                                          _key, [self domain],
                                          [self operation]]];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"jobList"])
    return [self jobList];
  if ([_key isEqualToString:@"creatorId"])
    return [self creatorId];
  if ([_key isEqualToString:@"ownerId"])
    return [self ownerId];
  if ([_key isEqualToString:@"executantId"])
    return [self executantId];
  return nil; // TODO: intentional?
}

@end /* LSFilterJobCommand */
