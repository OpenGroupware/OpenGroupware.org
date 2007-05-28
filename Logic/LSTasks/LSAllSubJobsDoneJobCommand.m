/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include <LSFoundation/LSBaseCommand.h>

// TODO: deprecated and should be removed?

@interface LSAllSubJobsDoneJobCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSAllSubJobsDoneJobCommand

static BOOL _checkJobs(id self, id _context, NSArray *_jobs) {
  unsigned int  i, cnt;
  IMP  objAtIdx;
  IMP  eqlStr;
  BOOL isValid;
  
  if (![_jobs isNotNull])
    return YES;

  objAtIdx = [_jobs methodForSelector:@selector(objectAtIndex:)];
  eqlStr   = [LSJobDone methodForSelector:@selector(isEqualToString:)];
  
  isValid = YES;
  for (i = 0, cnt = [_jobs count]; i < cnt; i++) {
    id obj;
    
    obj = [objAtIdx(_jobs, @selector(objectAtIndex:), i)
		   valueForKey:@"jobStatus"];
      
    if (!(isValid = ((BOOL)(long)(eqlStr(LSJobDone,
					 @selector(isEqualToString:), obj)) ||
		     (BOOL)(long)(eqlStr(LSJobArchived,
					 @selector(isEqualToString:), obj)))))
      break;
  }
  return isValid;
}

- (void)_validateKeysForContext:(id)_context {
  if (![[self object] isNotNull]) {
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"no job set!"];
  }
}

- (void)_executeInContext:(id)_context {
  id result;
  
  result = [NSNumber numberWithBool:
		       _checkJobs(self, _context, 
				  [[self object] valueForKey:@"jobs"])];
  [self setReturnValue:result];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"job"])
    [self setObject:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"job"])
    return [self object];

  return [super valueForKey:_key];
}

@end /* LSAllSubJobsDoneJobCommand */
