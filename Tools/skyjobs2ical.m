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

#import <Foundation/NSObject.h>

/*
  skyjobs2ical

  A small sample program that fetches tasks from the OGo database and renders
  the tasks as iCalendar vtodo records on stdout.
*/

@class NSArray;
@class OGoContextManager, LSCommandContext;

@interface Jobs2ICal : NSObject
{
  OGoContextManager *lso;
  LSCommandContext  *ctx;
  NSString          *sxid;
  NSString          *login;
  NSString          *password;
}

+ (int)run:(NSArray *)_args;

@end

#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation Jobs2ICal

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    self->lso      = [[OGoContextManager defaultManager] retain];
    self->login    = [[ud stringForKey:@"login"]     copy];
    self->password = [[ud stringForKey:@"password"]  copy];
    self->sxid     = [[ud stringForKey:@"skyrix_id"] copy];
  }
  return self;
}
- (void)dealloc {
  [self->sxid     release];
  [self->login    release];
  [self->password release];
  [self->lso      release];
  [super dealloc];
}

/* render as iCal */

- (int)percentCompleteForJobStatus:(NSString *)_status {
  int pc = 0;
  
  if ([_status isEqualToString:@"00_created"])
    pc = 0;
  else if ([_status isEqualToString:@"02_rejected"])
    pc = 0;
  else if ([_status isEqualToString:@"05_accepted"])
    pc = 5;
  else if ([_status isEqualToString:@"10_commented"])
    pc = 10;
  else if ([_status isEqualToString:@"15_devided"])
    pc = 15;
  else if ([_status isEqualToString:@"20_processing"])
    pc = 20;
  else if ([_status isEqualToString:@"25_done"])
    pc = 100;
  else if ([_status isEqualToString:@"27_reactivated"])
    pc = 27;
  else if ([_status isEqualToString:@"30_archived"])
    pc = 100;
  return pc;
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
  [ms appendString:self->sxid];
  [ms appendString:@"/"];
  [ms appendString:[[_job valueForKey:@"jobId"] stringValue]];
  [ms appendString:@"\r\n"];
  [ms appendFormat:@"SEQUENCE:%@\r\n", [_job valueForKey:@"objectVersion"]];
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
    [ms appendString:self->sxid];
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
    [ms appendFormat:@"PERCENT-COMPLETE:%i\r\n", 
	  [self percentCompleteForJobStatus:tmp]];
  }
  
  [ms appendString:@"CLASS:PUBLIC\r\n"];
  [ms appendFormat:@"PRIORITY:%@\r\n", [_job valueForKey:@"priority"]];
  
  [ms appendString:@"END:VTODO\r\n"];
  return ms;
}

- (void)outputJobsAsVToDos:(NSArray *)_jobs {
  NSEnumerator *e;
  id job;
  
  printf("BEGIN:VCALENDAR\r\n");
  printf("PRODID:-//SKYRIX groupware server//"
         "NONSGML skyjobs2ical 1.0.0//EN\r\n");
  printf("VERSION:2.0\r\n");
  printf("METHOD:PUBLISH\r\n");
  
  e = [_jobs objectEnumerator];
  while ((job = [e nextObject])) {
    NSString *s;
    
    if ((s = [self vToDoStringForJob:job])) {
      NSData *data;
      
      data = [s dataUsingEncoding:NSUTF8StringEncoding];
      fwrite([data bytes], [data length], 1, stdout);
    }
  }
  
  printf("END:VCALENDAR\r\n");
}

/* process */

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  /*
    job types:
      job::get-todo-jobs
      job::get-control-jobs
      job::get-delegated-jobs
      job::get-archived-jobs
      job::get-palm-jobs
  */
  NSArray *jobs;
  
  /* fetch jobs */
  jobs = [_ctx runCommand:@"job::get-todo-jobs", 
                 @"object", [_ctx valueForKey:LSAccountKey], 
                 nil];
  
  if ([jobs count] > 0) {
    /* to fill jobs with executant info */
    [_ctx runCommand:@"job::get-job-executants",
          @"objects", jobs,
          @"relationKey", @"executant", 
          nil];
  }
  
  [self outputJobsAsVToDos:jobs];
  return 0;
}

- (int)run:(NSArray *)_args {
  id sn;
  
  sn = [self->lso login:self->login password:self->password
                  isSessionLogEnabled:NO];
  if (sn == nil) {
    [self logWithFormat:@"could not login user '%@'", self->login];
    return 1;
  }
  ASSIGN(self->ctx, [sn commandContext]);
  
  return [self run:_args onContext:self->ctx];
}

+ (int)run:(NSArray *)_args {
  return [[[[self alloc] init] autorelease] run:_args];
}

@end /* Jobs2ICal */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  rc = [Jobs2ICal run:[[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
