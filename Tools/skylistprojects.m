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

#import <Foundation/NSObject.h>

/*
  skylistprojects

  A small sample program that fetches basic project information and prints that
  out in CSV format on stdout.
*/

@class NSArray;
@class OGoContextManager, LSCommandContext;

@interface ListProjects : NSObject
{
  OGoContextManager *lso;
  LSCommandContext  *ctx;
  NSString          *sxid;
  NSString          *login;
  NSString          *password;
  BOOL              withArchived;
}

+ (int)run:(NSArray *)_args;

@end

#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation ListProjects

- (void)usage {
  NSLog(@"skylistprojects -login <login> -password <pwd> [-archived YES]");
}

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      NSLog(@"ERROR: could not create OGo context manager.");
      [self release];
      return nil;
    }
    
    self->login    = [[ud stringForKey:@"login"] copy];
    self->password = [[ud stringForKey:@"password"]  copy];
    self->sxid     = [[ud stringForKey:@"skyrix_id"] copy];
    self->withArchived = [ud boolForKey:@"archived"];
    
    if ([self->login length] == 0) {
      [self usage];
      [self release];
      return nil;
    }
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

/* process */

- (void)printProjectEOs:(NSArray *)_projects {
  /* 
     Note: EOs are considered deprecated .. 

     Keys:
       projectId
       name
       number
       kind
       ownerId
       teamId
       status
       startDate
       endDate
       
       dbStatus
       isFake
       url
  */
  NSEnumerator *e;
  id project;

  printf("id;name;number;kind;ownerid;teamid;status\n");
  
  e = [_projects objectEnumerator];
  while ((project = [e nextObject])) {
    NSString *tmp;
    
    if ((tmp = [[project valueForKey:@"projectId"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");

    if ((tmp = [[project valueForKey:@"name"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");

    if ((tmp = [[project valueForKey:@"number"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");

    if ((tmp = [[project valueForKey:@"kind"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");

    if ((tmp = [[project valueForKey:@"ownerId"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");
    if ((tmp = [[project valueForKey:@"teamId"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");

    if ((tmp = [[project valueForKey:@"status"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");
    if ((tmp = [[project valueForKey:@"startDate"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");
    if ((tmp = [[project valueForKey:@"endDate"] stringValue]))
      printf("%s", [tmp cString]);
    printf(";");

    if ([project valueForKey:@"isFake"])
      printf("fake");
    printf(";");
    
    if ((tmp = [[project valueForKey:@"url"] stringValue]))
      printf("%s", [tmp cString]);
    printf("\n");
  }
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSArray *projects;
  
  if (self->withArchived) {
    projects = [_ctx runCommand:@"person::get-projects",
		     @"object",       [_ctx valueForKey:LSAccountKey], 
		     @"withArchived", [NSNumber numberWithBool:YES],
		     nil];
  }
  else {
    projects = [_ctx runCommand:@"person::get-projects",
		     @"object", [_ctx valueForKey:LSAccountKey], 
		     nil];
  }
  [self printProjectEOs:projects];
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

@end /* ListProjects */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  rc = [ListProjects run:
		       [[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
