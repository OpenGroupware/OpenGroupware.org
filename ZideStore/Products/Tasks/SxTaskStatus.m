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

#include "SxTaskStatus.h"
#include "common.h"

@implementation SxTaskStatus

- (id)initWithDavProps:(NSDictionary *)_props {
  if ((self = [super init])) {
    id tmp;
    
    if ((tmp = [_props valueForKey:@"taskCompletion"])) {
      // Evolution seems to send float values as strings according to
      // the clients' locale settings, e.g. with german settings the
      // float string is "0,09" instead of "0.09"
      if ([tmp rangeOfString:@","].length != 0)
        tmp = [tmp stringByReplacingString:@"," withString:@"."];

      self->completion = [tmp floatValue];
    }

    if ((tmp = [_props valueForKey:@"taskStatus"]))
      self->status = [tmp intValue];
    if ((tmp = [_props valueForKey:@"cdoItemIsComplete"]))
      self->isDone = [tmp boolValue];
  }
  return self;
}
- (id)initWithSxStatus:(NSString *)_status
       percentComplete:(NSNumber *)_percent
{
  if (_status == nil) {
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->sxStatus   = [_status copy];
    self->completion = [_percent doubleValue] * .01;
    
    if ([_status isEqualToString:@"00_created"])
      self->status = 0;
    else if ([_status isEqualToString:@"02_rejected"])
      self->status = 4;
    else if ([_status isEqualToString:@"05_accepted"]) {
      self->status = 1;
    }
    else if ([_status isEqualToString:@"10_commented"])
      self->status = 1;
    else if ([_status isEqualToString:@"15_devided"])
      self->status = 3;
    else if ([_status isEqualToString:@"20_processing"]) {
      self->status     = 1;
    }
    else if ([_status isEqualToString:@"25_done"]) {
      self->status     = 2;
      self->isDone     = YES;
    }
    else if ([_status isEqualToString:@"27_reactivated"])
      self->status = 3;
    else if ([_status isEqualToString:@"30_archived"]) {
      self->status = 2;
      self->isDone = YES;
    }
  }
  return self;
}

+ (id)statusWithDavProps:(NSDictionary *)_props {
  return [[[self alloc] initWithDavProps:_props] autorelease];
}
+ (id)statusWithSxStatus:(NSString *)_status
         percentComplete:(NSNumber *)_percent
{
  return [[[self alloc] initWithSxStatus:_status
                        percentComplete:_percent] autorelease];
}
+ (id)statusWithSxObject:(id)_object {
  return [self statusWithSxStatus:[_object valueForKey:@"jobStatus"]
               percentComplete:[_object valueForKey:@"percentComplete"]];
}

- (void)dealloc {
  [self->sxStatus release];
  [super dealloc];
}

- (void)removeExtractedDavPropsFromArray:(NSMutableArray *)_keys {
  [_keys removeObject:@"cdoItemIsComplete"];
  [_keys removeObject:@"taskCompletion"];
  [_keys removeObject:@"taskStatus"];
}

/* accessors */

- (BOOL)isDone {
  return self->isDone;
}
- (int)status {
  return self->status;
}
- (float)completion {
  return self->completion;
}

/* calculated accessors */

- (float)completionInPercent {
  return [self completion] * 100.0;
}

- (NSString *)sxStatusForCompletion {
  int value;
  
  if (self->sxStatus)
    return self->sxStatus;
  
  value = [self completionInPercent];
  if (value < 1)
    self->sxStatus = @"00_created";
  else if (value < 6)
    self->sxStatus = @"05_accepted";
  else if (value < 100)
    self->sxStatus = @"20_processing";
  else
    self->sxStatus = @"25_done";
  
  return self->sxStatus;
}

- (NSString *)sxStatusForStatus {
  if (self->status == 0)
    return @"00_created";
  else if (self->status == 4)
    return @"02_rejected";
  else if (self->status == 1)
    return @"20_processing";
  else if (self->status == 3)
    return @"15_devided";
  else if (self->status == 2)
    return @"25_done";

  NSLog(@"WARNING[%s] unknown task status: %d",
        __PRETTY_FUNCTION__, self->status);
  return  @"20_processing";
}

#if 0
- (NSString *)sxActionForCompletion {
  /*
    This calculates the action we need to reach the Evo completion as
    set in the ivars.
  */
  NSString *action;
  float value;
  
  // TODO: check whether the mapping makes sense ..., eg only accept
  //       if the job isn't already accepted ...
  value = [self completionInPercent];
  if (value < 6.00)
    action = @"accept";
  else if (value < 100.00)
    //    action = @"annotate";
    action = @"comment";
  else
    action = @"done";
  
  return action;
}

- (BOOL)sxNeedsActionAfterCreate {
  if (self->isDone)           return YES;
  if (self->status != 0)      return YES;
  if (self->completion > 0.0) return YES;
  return NO;
}
#endif

@end /* SxTaskStatus */
