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

#import <LSFoundation/LSBaseCommand.h>

@interface LSProjectStatusCommand : LSBaseCommand
@end

#import "common.h"

@implementation LSProjectStatusCommand

- (void)_computeProjectStatus:(id)_project {
  NSString *status   = nil;
  NSString *dbStatus = [_project valueForKey:@"dbStatus"];

  if ([dbStatus isEqualToString:@"archived"]) {
    status = @"30_archived";
  }
  else {
    NSCalendarDate *start = [_project valueForKey:@"startDate"];
    NSCalendarDate *end   = [_project valueForKey:@"endDate"];
    
    if (start == nil || end == nil) {
      status =  @"99_undefined";
      [self logWithFormat:@"WARNING: got project with null start or end date !"];
    }
    else {
      NSCalendarDate *sToday = [NSCalendarDate calendarDate];
      NSCalendarDate *eToday = [NSCalendarDate calendarDate];

      [sToday setTimeZone:[start timeZone]];
      [sToday setTimeZone:[end timeZone]];
      
      start  = [start beginOfDay];
      end    = [end   beginOfDay];
      sToday = [sToday beginOfDay];
      eToday = [eToday beginOfDay];

      if (([start compare:sToday] == NSOrderedAscending ||
           [start compare:sToday] == NSOrderedSame ) &&
          ([eToday compare:end]   == NSOrderedAscending ||
           [eToday compare:end]   == NSOrderedSame))
        status = @"05_processing";
      else if ([start compare:sToday] == NSOrderedDescending) 
        status = @"00_sleeping";
      else if ([end compare:eToday] == NSOrderedAscending) 
        status = @"10_out_of_date";
    }
  }
  
  if (status == nil)
    status = @"99_undefined";

  [_project takeValue:status forKey:@"status"];
}

- (void)_validateKeysForContext:(id)_context {
  if ([self object] == nil) 
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"no project(s) set!"];
}

- (void)_executeInContext:(id)_context {
  int i, cnt = [[self object] count];

  for (i = 0; i < cnt; i++) {
    id myProject = [[self object] objectAtIndex:i];

    [self _computeProjectStatus:myProject];
  }
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"] || 
      [_key isEqualToString:@"object"]) {
    [self setObject:[NSArray arrayWithObject:_value]];
    return;
  }
  else if ([_key isEqualToString:@"projects"]) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"] || 
      [_key isEqualToString:@"object"])
    return [[self object] lastObject];
  else if ([_key isEqualToString:@"projects"])
    return [self object];
  return [super valueForKey:_key];  
}

@end
