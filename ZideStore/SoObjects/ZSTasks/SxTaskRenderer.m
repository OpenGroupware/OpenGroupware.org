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

#include "SxTaskRenderer.h"
#include "SxTask.h"
#include "common.h"

@implementation SxTaskRenderer

- (NSString *)skyrixId {
  return [[NSUserDefaults standardUserDefaults] stringForKey:@"skyrix_id"];
}

- (NSString *)vToDoStringForJob:(id)_job {
  /*
    EO attributes:
      category      = "category 1";
      creatorId     = 10130;
      dbStatus      = updated;
      endDate       = "2002-12-31 23:59:59 +0100";
      executantId   = 10130;
      isControlJob  = "";
      isTeamJob     = 0;
      jobId         = 11470;
      jobStatus     = "20_processing";
      keywords      = "";
      kind          = "";
      name          = "test 1";
      notify        = 0;
      objectVersion = 1;
      parentJobId   = "";
      priority      = 3;
      projectId     = "";
      sourceUrl     = "";
      startDate     = "2002-12-27 00:00:00 +0100";
      
    Job Status:
      00_created
      02_rejected
      05_accepted
      10_commented
      15_divided
      20_processing
      25_done
      27_reactivated
      30_archived
  */
  NSMutableString *ms;
  id tmp;
  if (_job == nil) return nil;
  
  ms = [NSMutableString stringWithCapacity:256];
  [ms appendString:@"BEGIN:VTODO\r\n"];
  
  [ms appendString:@"UID:skyrix://"];
  [ms appendString:[self skyrixId]];
  [ms appendString:@"/"];
  [ms appendString:[[_job valueForKey:@"jobId"] stringValue]];
  [ms appendString:@"\r\n"];

  [ms appendFormat:@"SEQUENCE:%i\r\n", [[_job valueForKey:@"objectVersion"]
                                              intValue]];
  [ms appendFormat:@"SUMMARY:%@\r\n",  [_job valueForKey:@"name"]];
  
  // TODO: created, last-modified, dtstamp
  
  if ((tmp = [_job valueForKey:@"executant"])) {
    // TODO: fetch mail of executants !
    NSString *n;
    [ms appendString:@"ORGANIZER"];
    [ms appendString:@";CN="];
    
    n = [tmp valueForKey:@"firstname"];
    if ([n isNotNull]) {
      [ms appendString:n];
      [ms appendString:@" "];
    }
    n = [tmp valueForKey:@"name"];
    if ([n isNotNull]) [ms appendString:n];
    
    [ms appendString:@":skyrix://"];
    [ms appendString:[self skyrixId]];
    [ms appendString:@"/"];
    [ms appendString:[[tmp valueForKey:@"companyId"] stringValue]];
    [ms appendString:@"\r\n"];
  }
  
  if ((tmp = [_job valueForKey:@"endDate"])) {
    static NSTimeZone *gmt = nil;
    if (gmt == nil)
      gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
    [tmp setTimeZone:gmt];
    [ms appendFormat:@"DUE;VALUE=DATE:%04i%02i%02i\r\n",
          [tmp yearOfCommonEra],
          [tmp monthOfYear],
          [tmp dayOfMonth]];
  }

  if ((tmp = [_job valueForKey:@"jobStatus"])) {
    NSString *status = @"NEEDS-ACTION";
    int      pc      = [[_job valueForKey:@"percentComplete"] intValue];
    if ([tmp isEqualToString:@"00_created"]) {
      status = @"NEEDS-ACTION";
    }
    else if ([tmp isEqualToString:@"02_rejected"]) {
      status = @"CANCELLED";
    }
    else if ([tmp isEqualToString:@"05_accepted"]) {
      status = @"IN-PROCESS";
    }
    else if ([tmp isEqualToString:@"10_commented"]) {
      status = @"IN-PROCESS";
    }
    else if ([tmp isEqualToString:@"15_devided"]) {
      status = @"IN-PROCESS";
    }
    else if ([tmp isEqualToString:@"20_processing"]) {
      status = @"IN-PROCESS";
    }
    else if ([tmp isEqualToString:@"25_done"]) {
      status = @"COMPLETED";
      pc = 100;
    }
    else if ([tmp isEqualToString:@"27_reactivated"]) {
      status = @"IN-PROCESS";
    }
    else if ([tmp isEqualToString:@"30_archived"]) {      
      status = @"COMPLETED";
      pc = 100;
    }
    [ms appendFormat:@"PERCENT-COMPLETE:%i\r\n", pc];
    [ms appendFormat:@"STATUS:%@\r\n", status];
  }
  
  [ms appendString:@"CLASS:PUBLIC\r\n"];
  [ms appendFormat:@"PRIORITY:%@\r\n", [_job valueForKey:@"priority"]];
  
  [ms appendString:@"END:VTODO\r\n"];
  return ms;
}

- (NSString *)vToDoStringForTask:(SxTask *)_task {
  return [self vToDoStringForJob:[_task object]];
}

- (NSString *)vCalendarStringForTask:(SxTask *)_task {
  NSMutableString *ms;

  if (_task == nil) return nil;
  
  ms = [NSMutableString stringWithCapacity:256];
  [ms appendString:@"BEGIN:VCALENDAR\r\n"];
  [ms appendString:
        @"PRODID:-//OpenGroupware.org//"
        @"NONSGML ZideStore 1.4//EN\r\n"];
  [ms appendString:@"VERSION:2.0\r\n"];
  [ms appendString:@"METHOD:PUBLISH\r\n"];
  
  [ms appendString:[self vToDoStringForTask:_task]];
  [ms appendString:@"END:VCALENDAR\r\n"];
  return ms;
}

@end /* SxTaskRenderer */
