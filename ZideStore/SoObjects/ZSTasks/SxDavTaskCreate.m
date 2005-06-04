/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxDavTaskCreate.h"
#include "SxTask.h"
#include "SxTaskStatus.h"
#include "common.h"

#include <ZSFrontend/NSObject+ExValues.h>
#include <ZSBackend/NSString+rtf.h>
#include <ZSBackend/SxTaskManager.h>
#include <GDLAccess/GDLAccess.h>

@implementation SxDavTaskCreate

static BOOL debugPatch = NO;

+ (void)initialize {
  debugPatch = [[NSUserDefaults standardUserDefaults] 
                                boolForKey:@"SxDebugTaskPatch"];
}

- (BOOL)isDebugEnabled {
  return debugPatch;
}

- (id)teamGIDForGroup:(id)_group inCmdContext:(id)_ctx {
  SxTaskManager *tm;
  EOGlobalID    *gid;
  
  if (_group == nil) return nil;

  tm = [SxTaskManager managerWithContext:_ctx];
  
  if ([_group isKindOfClass:[NSString class]]) {
    gid = [tm globalIDForGroupWithName:_group];
  }
  else if ([_group isKindOfClass:[NSNumber class]])
    gid = [tm globalIDForGroupWithPrimaryKey:_group];
  else if ([_group isKindOfClass:[EOKeyGlobalID class]])
    gid = _group;
  else {
    [self logWithFormat:@"cannot resolve team-id: %@", _group];
    return _group;
  }
  
  if (gid == nil) {
    [self logWithFormat:@"could not resolve team-id: %@", _group];
    return nil;
  }

  return gid;
}

/* process */

- (NSException *)runInContext:(id)_ctx {
  NSException  *error;
  SxTaskStatus *status;
  NSString     *log;
  id tmp;
  
  [self removeUnusedKeys];
  [self checkMessageClass];
  
  if ([self checkRecurring]) {
    return [NSException exceptionWithHTTPStatus:501 /* Not Implemented */
                        reason:@"ZideStore does not support recurring jobs"];
  }
  
  if ([(tmp = [self->props objectForKey:@"rtfCompressed"]) isNotNull]) {
    int length;

    length = [tmp length];
    
    if (length > 0) {
      EOModel     *model;
      NSNumber    *width;
      
      model = [[[[[self task] commandContextInContext:_ctx]
                        valueForKey:LSDatabaseKey] adaptor] model];
      width = [[[model entityNamed:@"Job"] attributeNamed:@"comment"]
                       valueForKey:@"width"];

      if ([width intValue] >= length) {
        NSString *s;

        s = [[tmp stringByDecodingBase64] plainTextStringByDecodingRTF];

        if (![s length]) {
          s = [@"ZideLook rich-text compressed comment: "
                stringByAppendingString:tmp];
        }
        [self->changeSet setObject:s forKey:@"comment"];
      }
      else {
        [self logWithFormat:
              @"WARNING: losing comment, too long for DB field"
              @" (comment: %i - db: %@)", length, width];
      }
    }
  }
  
  if ((tmp = [self->props objectForKey:@"isTeamTask"])) {
    if ([tmp boolValue])
      [self logWithFormat:@"WARNING: marked as team task, ignored."];
    [keys removeObject:@"isTeamTask"]; // ?? 0 - unused
  }
  if ((tmp = [self->props objectForKey:@"locationURL"])) {
    if ([tmp length] > 0)
      [self logWithFormat:@"WARNING: loosing locationURL, set by ZideStore."];
    [keys removeObject:@"locationURL"]; // ?? 0 - unused
  }
  
  /* extract used values */
  
  status = [SxTaskStatus statusWithDavProps:self->props];
  [status removeExtractedDavPropsFromArray:keys];
  
  /* TODO: handle new columns */

  if ((tmp = [self->props objectForKey:@"actualWorkInMinutes"])) {
    [self->changeSet setObject:tmp forKey:@"actualWork"];
    [keys removeObject:@"actualWorkInMinutes"];
  }
  if ((tmp = [self->props objectForKey:@"totalWorkInMinutes"])) {
    [self->changeSet setObject:tmp forKey:@"totalWork"];
    [keys removeObject:@"totalWorkInMinutes"];
  }
  if ((tmp = [self->props objectForKey:@"agingDontAgeMe"])) {
    if ([tmp intValue] == 0)
      [keys removeObject:@"agingDontAgeMe"];
  }

  [self->changeSet setObject:[self getPriority] forKey:@"priority"];

  // 0: public, 1: confidential, 2: public
  [changeSet setObject:[self->props objectForKey:@"sensitivity"]
             forKey:@"sensitivity"];
  [keys removeObject:@"sensitivity"];
    
  if ((tmp = [self->props objectForKey:@"keywords"])) {
    // TODO: parse this
    // "<V:v xmlns:V=\"xml:\">Holiday</V:v><V:v xmlns:V=\"xml:\">Ideas</V:v>"
    [self->changeSet setObject:tmp forKey:@"keywords"];
  }

  /* title */
  if ((tmp = [self getName])) {
    [self->changeSet setObject:tmp forKey:@"name"];
  }
  
  if ((tmp = [self->props objectForKey:@"taskCommonStart"])) {
    /* start-date */
    if (![tmp isKindOfClass:[NSDate class]])
      tmp = [NSCalendarDate dateWithExDavString:[tmp stringValue]];
    [changeSet setObject:tmp forKey:@"startDate"];
    [keys removeObject:@"taskCommonStart"];
  }
  else
    [changeSet setObject:[NSCalendarDate calendarDate] forKey:@"startDate"];
  
  if ((tmp = [self->props objectForKey:@"taskCommonEnd"])) {
    /* due-date */
    if (![tmp isKindOfClass:[NSDate class]])
      tmp = [NSCalendarDate dateWithExDavString:[tmp stringValue]];
    [changeSet setObject:tmp forKey:@"endDate"];
    [keys removeObject:@"taskCommonEnd"];
  }
  else {
    NSCalendarDate *date;
    date = [changeSet objectForKey:@"startDate"];
    date = [date dateByAddingYears:4 months:0 days:0 
		 hours:0 minutes:0 seconds:0];
    [changeSet setObject:date forKey:@"endDate"];
  }

  if ([(tmp = [self->props objectForKey:@"taskCompletionDate"]) length]) {
    /* completionDate */
    if (![tmp isKindOfClass:[NSDate class]])
      tmp = [NSCalendarDate dateWithExDavString:[tmp stringValue]];
    [changeSet setObject:tmp forKey:@"completionDate"];
  }
  [keys removeObject:@"taskCompletionDate"];

  if ((tmp = [self->props objectForKey:@"travelDistance"])) {
    [self->changeSet setObject:tmp forKey:@"kilometers"];
    [keys removeObject:@"travelDistance"];
  }

  if ((tmp = [self->props objectForKey:@"associatedContacts"])) {
    [self->changeSet setObject:tmp forKey:@"associatedContacts"];
    [keys removeObject:@"associatedContacts"];
  }
  if ((tmp = [self->props objectForKey:@"associatedCompanies"])) {
    [self->changeSet setObject:tmp forKey:@"associatedCompanies"];
    [keys removeObject:@"associatedCompanies"];
  }
  if ((tmp = [self->props objectForKey:@"accountingInfo"])) {
    [self->changeSet setObject:tmp forKey:@"accountingInfo"];
    [keys removeObject:@"accountingInfo"];
  }
  
  tmp = [NSNumber numberWithFloat:[status completionInPercent]];
  [self->changeSet setObject:tmp forKey:@"percentComplete"];
  
  tmp = [status sxStatusForStatus];
  [self->changeSet setObject:tmp forKey:@"jobStatus"];

  tmp = [[self task] group];
  if (tmp) {
    tmp = [self teamGIDForGroup:tmp
                inCmdContext:[[self task] commandContextInContext:_ctx]];
    if (tmp) {
      [changeSet setObject:[tmp keyValues][0] forKey:@"executantId"];
      [changeSet setObject:[NSNumber numberWithBool:YES]
                 forKey:@"isTeamJob"];
    }
  }
  
  /* add log */
  [self logRemainingKeys];
  
  log = [self createdLogText];
  
  /* perform changes */
  
  [self debugWithFormat:@"CREATE: %@", changeSet];
  
  error = [[self task] createWithChanges:changeSet log:log inContext:_ctx];
  if ([error isKindOfClass:[NSException class]]) {
    [self logWithFormat:@"ERROR: task creation failed: %@", error];
    return error;
  }
  
  /* set SxNewObjectID in context for ZideLook */
  if ((tmp = [error valueForKey:@"jobId"])) {
    [self debugWithFormat:@"deliver new job-id: %@", tmp];
    [(WOContext *)_ctx setObject:tmp forKey:@"SxNewObjectID"];
  }
  else
    [self logWithFormat:@"ERROR: missing jobId !"];
  
  /* apply status changes */

#if 0
  if ([status sxNeedsActionAfterCreate]) {
    // TODO: mark done, taskCompletion, taskStatus
    [self logWithFormat:@"ERROR: need action after create: %@ !", status];
  }
#endif
  
  return nil; /* nil says everything OK to DAV dispatcher */
}

@end /* SxDavTaskCreate */
