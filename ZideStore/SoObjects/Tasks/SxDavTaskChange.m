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
// $Id: SxDavTaskChange.m 1 2004-08-20 11:17:52Z znek $

#include "SxDavTaskChange.h"
#include "SxTask.h"
#include "SxTaskStatus.h"
#include "common.h"
#include <GDLAccess/GDLAccess.h>
#include <Frontend/NSObject+ExValues.h>
#include <Backend/NSString+rtf.h>

@implementation SxDavTaskChange

static inline void __handleValue(SxDavTaskChange *self,
                                 id _val,                                 
                                 id _key,
                                 id _propKey,
                                 id _object,
                                 NSMutableDictionary *_changes)
{
  id other;
  
  if (_val == nil)
    return;
  
  other = [_object valueForKey:_key];
  if ([_val isKindOfClass:[NSString class]] &&
      [other isKindOfClass:[NSNumber class]])
    // to make it comparable
    other = [other stringValue];

  if ((([other isNotNull]) || ([[_val stringValue] length])) &&
      (![other isEqual:_val]))
    [_changes setObject:_val forKey:_key];
  if (_propKey)
    [self->keys removeObject:_propKey];
}

- (id)runInContext:(id)_ctx {
  // TODO: if action on a group job, move it to private jobs ...
  // TODO: fix this method ...
  LSCommandContext    *cmdctx;
  NSMutableDictionary *changes;
  NSException  *error = nil;
  SxTaskStatus *status;
  id tmp;
  id obj;

  if ((cmdctx = [[self task] commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: did not find command context ..."];
    return [NSException exceptionWithHTTPStatus:500];
  }
  if ((obj = [[self task] objectInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: did not find EO ..."];
    return [NSException exceptionWithHTTPStatus:500];
  }
  
  [self debugWithFormat:@"UPDATE: %@ vs %@", self->props, obj];

  [self removeUnusedKeys];
  [self checkMessageClass];
  
  changes = [NSMutableDictionary dictionaryWithCapacity:16];
  
  if ([self checkRecurring]) {
    return [NSException exceptionWithHTTPStatus:501 /* Not Implemented */
                        reason:@"ZideStore does not support recurring jobs"];
  }
  if ((tmp = [self->props objectForKey:@"isTeamTask"])) {
    if ([tmp boolValue])
      [self logWithFormat:@"WARNING: marked as team task, ignored."];
    [keys removeObject:@"isTeamTask"]; // ?? 0 - unused
  }
  
  /* title */
  __handleValue(self, [self getName], @"name", nil, obj, changes);
  
  
  if ((tmp = [self->props objectForKey:@"taskCommonStart"])) {
    if (![tmp isKindOfClass:[NSDate class]])
      tmp = [NSCalendarDate dateWithExDavString:[tmp stringValue]];
  }
  __handleValue(self, tmp,
                @"startDate", @"taskCommonStart", obj, changes);
  
  if ((tmp = [self->props objectForKey:@"taskCommonEnd"])) {
    if (![tmp isKindOfClass:[NSDate class]])
      tmp = [NSCalendarDate dateWithExDavString:[tmp stringValue]];
  }
  __handleValue(self, tmp,
                @"endDate", @"taskCommonEnd", obj, changes);  
  
  status = [SxTaskStatus statusWithDavProps:self->props];
  //[changes setObject:[status sxActionForCompletion] forKey:@"action"];

  __handleValue(self, [self->props objectForKey:@"actualWorkInMinutes"],
                @"actualWork", @"actualWorkInMinutes", obj, changes);

  __handleValue(self, [self->props objectForKey:@"totalWorkInMinutes"],
                @"totalWork", @"totalWorkInMinutes", obj, changes);
  
  if ((tmp = [self->props objectForKey:@"agingDontAgeMe"])) {
    if ([tmp intValue] == 0)
      [keys removeObject:@"agingDontAgeMe"];
  }

  __handleValue(self, [self getPriority], @"priority", nil, obj, changes);
  __handleValue(self, [self->props objectForKey:@"keywords"],
                @"keywords", @"keywords", obj, changes);
  
  // 0: public, 1: confidential, 2: public
  __handleValue(self, [self->props objectForKey:@"sensitivity"],
                @"sensitivity", @"sensitivity", obj, changes);
  
  if ([(tmp = [self->props objectForKey:@"taskCompletionDate"]) length]) {
    /* completionDate */
    if (![tmp isKindOfClass:[NSDate class]])
      tmp = [NSCalendarDate dateWithExDavString:[tmp stringValue]];
    [changes setObject:tmp forKey:@"completionDate"];
  }
  else if ([[obj valueForKey:@"completionDate"] isNotNull])
    [changes setObject:[NSNull null] forKey:@"completionDate"];
  [keys removeObject:@"taskCompletionDate"];

  if ([self->keys containsObject:@"taskCompletion"]) {
    tmp = [NSNumber numberWithFloat:[status completionInPercent]];
    __handleValue(self , tmp, @"percentComplete", nil, obj, changes);
  }

  if ([self->keys containsObject:@"taskStatus"]) {
    tmp = [status sxStatusForStatus];
    __handleValue(self , tmp, @"jobStatus", nil, obj, changes);
  }
  
  __handleValue(self, [self->props objectForKey:@"travelDistance"],
                @"kilometers", @"travelDistance", obj, changes);
  __handleValue(self, [self->props objectForKey:@"associatedContacts"],
                @"associatedContacts", @"associatedContacts", obj, changes);
  __handleValue(self, [self->props objectForKey:@"associatedCompanies"],
                @"associatedCompanies", @"associatedCompanies", obj, changes);

  __handleValue(self, [self->props objectForKey:@"accountingInfo"],
                @"accountingInfo", @"accountingInfo", obj, changes);

  {
    NSString *comment;
    int length;

    comment = [self->props objectForKey:@"rtfCompressed"];
    length = [comment length];
    
    if (length > 0) {
      EOModel     *model;
      NSNumber    *width;
      
      model = [[[[[self task] commandContextInContext:_ctx]
                        valueForKey:LSDatabaseKey] adaptor] model];
      width = [[[model entityNamed:@"Job"] attributeNamed:@"comment"]
                       valueForKey:@"width"];

      if ([width intValue] >= length) {
        NSString *s;

        s = [[comment stringByDecodingBase64] plainTextStringByDecodingRTF];

        if (![s length]) {
          s = [@"ZideLook rich-text compressed comment: "
                stringByAppendingString:comment];
        }
        __handleValue(self, s,
                      @"comment", @"rtfCompressed", obj, changes);
      }
      else
        [self logWithFormat:
              @"WARNING: losing comment, too long for DB field"
              @" (comment: %i - db: %@)", length, width];
    }
  }
  
  [status removeExtractedDavPropsFromArray:self->keys];
  
#if 0
  mapi0x0000811c = 1;
  sensitivity = 0;
  taskStatus = 2;
#endif
  // TODO: how is this covered ?
  //   taskCompletionDate = "2003-02-19T00:25:48Z";

  [self logRemainingKeys];
  
  if ([changes count]) {
    [changes setObject:obj forKey:@"object"];
  
    // log changes
    //    [changes setObject:@"ZideStore" forKey:@"comment"];
    
    [self debugWithFormat:@"  UPDATE: %@", changes];

    *(&error) = nil;
    NS_DURING {
      //[cmdctx runCommand:@"job::jobaction" arguments:changes];
      [cmdctx runCommand:@"job::set" arguments:changes];
      [cmdctx commit];
    }
    NS_HANDLER {
      error = [localException retain];
    }
    NS_ENDHANDLER;
  }
  else {
    [self debugWithFormat:@"  UPDATE: nothing to update"];
  }
  
  return [error autorelease];
}

@end /* SxDavTaskChange */
