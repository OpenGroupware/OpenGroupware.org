/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OpenGroupware.org

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

#include <LSFoundation/LSBaseCommand.h>

@interface LSAllSubJobsDoneJobCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSAllSubJobsDoneJobCommand

static BOOL _checkJobs(id self, id _context, NSArray *_jobs) {
  id   obj       = nil;  
  IMP  objAtIdx;
  IMP  eqlStr;
  int  i,cnt;
  BOOL isValid   = YES;  

  if ([_jobs isNotNull]) {
    objAtIdx = [_jobs methodForSelector:@selector(objectAtIndex:)];
    eqlStr   = [LSJobDone methodForSelector:@selector(isEqualToString:)];
    
    for (i = 0, cnt = [_jobs count]; i < cnt; i++) {
      obj = [objAtIdx(_jobs, @selector(objectAtIndex:), i)
                     valueForKey:@"jobStatus"];
      
      if (!(isValid = ((BOOL)(long)(eqlStr(LSJobDone,
                                           @selector(isEqualToString:), obj)) ||
                       (BOOL)(long)(eqlStr(LSJobArchived,
                                           @selector(isEqualToString:), obj)))))
        break;
    }
  }
  return isValid;
}

- (void)_validateKeysForContext:(id)_context {
  if ([self object] == nil) 
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"no job set!"];
}

- (void)_executeInContext:(id)_context {
  [self setReturnValue:[NSNumber numberWithBool:
                                 _checkJobs(self, _context, [[self object]
                                                   valueForKey:@"jobs"])]];
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"job"])
    [self setObject:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"job"])
    return [self object];
  else
    return [super valueForKey:_key];
}


@end
