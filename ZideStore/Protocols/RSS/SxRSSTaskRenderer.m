/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id: SxRSSTaskRenderer.m 1 2004-08-20 11:17:52Z znek $

#include "SxRSSTaskRenderer.h"
#include "common.h"
#include <Frontend/SxFolder.h>
#include <Backend/SxTaskManager.h>

#include <EOControl/EOGenericRecord.h>

@interface SxFolder(TaskFolderProps)
- (NSString *)group;
- (NSString *)type;
@end


@implementation SxRSSTaskRenderer

static int MAX_ELEMENTS = 10;

int sortByPriority(id task1, id task2, void *context) {
  NSNumber *tmpprio;
  int prio1, prio2;

  prio1 = ((tmpprio = [task1 valueForKey:@"priority"]) != nil)
    ? [tmpprio intValue]
    : 3;

  prio2 = ((tmpprio = [task2 valueForKey:@"priority"]) != nil)
    ? [tmpprio intValue]
    : 3;

  if (prio1 > prio2)
    return NSOrderedAscending;
  else if (prio1 < prio2)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

- (NSString *)title {
  return @"Task Overview";
}

- (NSString *)info {
  // TODO: its not the responsibility of a renderer to sort objects,
  //       it just renders a sequence? Hm.
  return @"This RSS feed shows your tasks ordered by priority";
}

- (NSString *)viewURI {
  return @"viewJob?jobId";
}

- (NSString *)jobStatusForTask:(EOGenericRecord *)_task {
  NSString *jobStatus;

  jobStatus = [_task valueForKey:@"jobStatus"];
  return [jobStatus substringWithRange:
                    NSMakeRange(3,[jobStatus length]-3)];
}

- (NSString *)descriptionForTask:(EOGenericRecord *)_task {
  NSMutableString *d;

  d = [NSMutableString stringWithCapacity:256];
  
  [d appendFormat:@"Title: <b>%@</b><br>",
     [_task valueForKey:@"name"]];

  [d appendFormat:@"Status: %@<br>", [self jobStatusForTask:_task]];
  
  [d appendFormat:@"Start date: %@<br>",
     [[_task valueForKey:@"startDate"]
             descriptionWithCalendarFormat:@"%Y-%m-%d"
             timeZone:nil locale:nil]];

  [d appendFormat:@"End date: %@<br>",
     [[_task valueForKey:@"endDate"]
             descriptionWithCalendarFormat:@"%Y-%m-%d"
             timeZone:nil locale:nil]];

  return [d stringByEscapingHTMLString];
}

/* rendering */

- (NSString *)renderTask:(EOGenericRecord *)_task inContext:(id)_ctx {
  NSMutableString *ms;
  NSString *tmp;
  
  tmp = [_task valueForKey:@"name"];

  ms = [NSMutableString stringWithCapacity:256];
  [ms appendString:[self itemHeader]];
  [ms appendString:@"<title>"];
  [ms appendString:tmp];
  [ms appendString:@"</title>\n<description>"];

  [ms appendString:[self descriptionForTask:_task]];
  [ms appendString:@"</description>\n"];

  if ((tmp = [self skyrixLinkForEO:_task]) != nil) {
    [ms appendString:@"<link>"];
    [ms appendString:tmp];
    [ms appendString:@"</link>"];
  }
  [ms appendString:[self itemFooter]];
  return ms;
}

- (SxTaskManager *)taskManagerInCommandContext:(LSCommandContext *)_ctx {
  SxTaskManager *m;
  m = [SxTaskManager managerWithContext:_ctx];
  if (m == nil)
    [self logWithFormat:@"got no task manager for context: %@", _ctx];
  return m;
}

- (NSString *)rssStringForFolder:(SxFolder *)_folder inContext:(id)_ctx {
  NSMutableString *s;
  NSArray         *tasks;
  NSEnumerator    *taskEnumerator;
  EOGenericRecord *taskEO;
  
  tasks = [[self taskManagerInCommandContext:
                   [_folder commandContextInContext:_ctx]]
            fetchTasksOfGroup:[_folder group]
            type:[_folder type]];

  [(NSMutableArray *)tasks sortUsingFunction:sortByPriority context:nil];

  if ([tasks count] > MAX_ELEMENTS)
    tasks = [tasks subarrayWithRange:NSMakeRange(0,MAX_ELEMENTS)];
  
  s = [NSMutableString stringWithCapacity:1024];
  [s appendString:[self rssHeader]];

  taskEnumerator = [tasks objectEnumerator];
  while ((taskEO = [taskEnumerator nextObject])) {
    NSString *ts;

    if ((ts = [self renderTask:taskEO inContext:_ctx]) != nil)
      [s appendString:ts];
  }
  
  [s appendString:[self rssFooter]];
  return s;
}

@end /* SxRSSTaskRenderer */
