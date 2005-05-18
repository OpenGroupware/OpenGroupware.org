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

#include <LSFoundation/LSBaseCommand.h>

@interface LSDetachProjectFromJobCommand : LSBaseCommand
{
  id       jobId;
  NSString *logText;
}

@end /* LSDetachProjectFromJobCommand */

#include "common.h"

@implementation LSDetachProjectFromJobCommand

- (void)dealloc {
  [self->jobId   release];
  [self->logText release];
  [super dealloc];
}

- (void)_prepareForExecutionInContext:(id)_context {
  [super _prepareForExecutionInContext:_context];
  
  [self assert:(self->jobId != nil)     reason:@"no jobId specified"];
}

- (void)_executeInContext:(id)_context {
  id job;
  job = LSRunCommandV(_context, @"job", @"get",
                      @"jobId", self->jobId, nil);
  job = [job lastObject];

  [self assert:(job != nil)
        reason:[NSString stringWithFormat:@"unable to get job for id %@",
                         self->jobId]];

  [job takeValue:[NSNull null] forKey:@"projectId"];
  job = LSRunCommandV(_context, @"job", @"set", @"object", job, nil);

  if ([self->logText length] > 0) {
    LSRunCommandV(_context,
                  @"job",     @"jobaction",
                  @"object",  job,
                  @"action",  @"comment",
                  @"comment", self->logText,
                  nil);
  }
  [self setReturnValue:job];
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"jobId"]) {
    ASSIGN(self->jobId,_value);
  }
  else if (([_key isEqualToString:@"job"]) ||
           ([_key isEqualToString:@"object"])) {
    _value = [_value valueForKey:@"jobId"];
    ASSIGN(self->jobId,_value);
  }
  else if ([_key isEqualToString:@"logText"]) {
    ASSIGN(self->logText,_value);
  }
  else {
    [self assert:NO
          reason:[NSString stringWithFormat:@"Unknown key: %@",_key]];
  }
}
- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"jobId"]) {
    return self->jobId;
  }
  if ([_key isEqualToString:@"logText"])
    return self->logText;
  return nil;
}

@end /* LSDetachProjectFromJobCommand */