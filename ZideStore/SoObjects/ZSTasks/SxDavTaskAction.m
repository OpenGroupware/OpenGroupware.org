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
// $Id: SxDavTaskAction.m 1 2004-08-20 11:17:52Z znek $

#include "SxDavTaskAction.h"
#include "SxTask.h"
#include "SxTaskStatus.h"
#include "common.h"

@implementation SxDavTaskAction

static NSArray  *unusedKeys = nil;
// static BOOL debugPatch = YES;

+ (void)initialize {
  static BOOL didInit = NO;
  NSString     *p;
  NSDictionary *plist;
  if (didInit) return;
  
  p = [[NSBundle mainBundle] pathForResource:@"DavTaskChangeSets" 
                             ofType:@"plist"];
  if ((plist = [NSDictionary dictionaryWithContentsOfFile:p]) == nil)
    [self logWithFormat:@"could not load task-change-sets: %@", p];
  
  unusedKeys = [[plist objectForKey:@"unused"] copy];
  
  didInit = YES;
}

- (id)initWithName:(NSString *)_name properties:(NSDictionary *)_props
  forTask:(SxTask *)_task
{
  return [self initWithName:_name properties:_props forObject:_task];
}

- (SxTask *)task {
  return (SxTask *)self->object;
}

- (NSString *)sxStatusForCompletion:(int)_percent {  
  if (_percent < 1)
    return @"00_created";
  else if (_percent < 6)
    return @"05_accepted";
  else if (_percent < 100)
    return @"20_processing";
  return @"25_done";  
}

/* process */

- (NSArray *)unusedKeys {
  //@"cdoPriority", used if priority not set
  //@"importance",used if priority and cdoPriority not set
  return unusedKeys;
}

- (NSString *)expectedMessageClass {
  return @"IPM.Task";
}

- (BOOL)checkRecurring {
  id tmp;
  
  if ((tmp = [self->props objectForKey:@"cdoIsRecurring"]) == nil)
    return NO;
  
  [keys removeObject:@"cdoIsRecurring"];
  if (![tmp boolValue])
    return NO;
  
  /* TODO: add recurring jobs */
  [self logWithFormat:@"ERROR: cannot create recurring jobs !"];
  return YES;
}


- (id)getPriority {
  /*
   * priority:
   * 0 - normal, 1 - high, 2 - low
   *
   * cdoPriority
   * -1 - low, 0 - normal, 1 - high
   *
   * importance:
   * like priority
   * or in evolution:
   * 'low', 'hight' and 'normal'
   */
  id tmp;
  
  [self->keys removeObject:@"priority"];
  [self->keys removeObject:@"cdoPriority"];
  [self->keys removeObject:@"importance"];
  
  tmp = [self->props objectForKey:@"priority"];
  if (tmp) {
    return [self skyrixValueForOutlookPriority:[tmp intValue]];
  }
  
  tmp = [self->props objectForKey:@"cdoPriority"];
  if (tmp) {
    int val = [tmp intValue];
    if (val == -1)
      val = 2;
    return [self skyrixValueForOutlookPriority:val];
  }
  tmp = [self->props objectForKey:@"importance"];
  if (tmp) {
    int val = [tmp intValue];
    if (val == 0) {
      if ([tmp isEqualToString:@"low"])
        val = 2;
      else if ([tmp isEqualToString:@"high"])
        val = 1;
    }
    return [self skyrixValueForOutlookPriority:val];
  }

  return [self skyrixValueForOutlookPriority:0];
}

- (NSString *)getName {
  /*
   * outlook sends the task title
   * in the property 'davDisplayName'
   * 'threadTopic' is also sent, but seems not to be editable
   *
   * evolution sends the task title
   * in 'threadTopic'
   *
   *
   *
   */
  id tmp;
  
  [keys removeObject:@"davDisplayName"];
  [keys removeObject:@"threadTopic"];
  [keys removeObject:@"subject"];

  if ((tmp = [self->props objectForKey:@"subject"]))
    return tmp;
  if ((tmp = [self->props objectForKey:@"davDisplayName"]))
    return tmp;
  if ((tmp = [self->props objectForKey:@"threadTopic"]))
    return tmp;

  [self logWithFormat:@"WARNING[getName]: cannot get name from properties"];
  return nil;  
}

@end /* SxDavTaskAction */
