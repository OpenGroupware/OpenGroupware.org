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
  skydefaults

  A small sample program that can show/edit OGo user defaults from the
  command-line.
*/

@class NSString, NSArray, NSDictionary, NSUserDefaults;
@class OGoContextManager, LSCommandContext;

@interface Defaults : NSObject
{
  OGoContextManager *lso;
  LSCommandContext  *ctx;
  NSString          *login;
  NSString          *password;
  NSString          *command;
  NSUserDefaults    *ud;
}

+ (int)run:(NSArray *)_args;

@end

#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation Defaults

- (void)usage {
  fprintf(stderr,
          "Tool to manipulate the defaults database of a specific OGo user\n"
          "\n"
          "Show all the defaults:\n"
          "        Defaults read\n"
          "Show the defaults for a given key:\n"
          "        Defaults read \"key\"\n"
          "Update the defaults for a given key:\n"
          "        Defaults write \"key\" \"value\"\n"
          "Delete the defaults for a given key:\n"
          "        Defaults delete \"key\"\n"
          "\n"
          "You need to pass in the login credentials to all command calls\n"
          "using -login and -password defaults.\n"
          "\n"
          "Examples:\n"
          "  skydefaults -login donald -password *** read docked_projects\n"
          );
}

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *lud = [NSUserDefaults standardUserDefaults];
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      NSLog(@"ERROR: could not create OGo context manager.");
      [self release];
      return nil;
    }
    
    self->login    = [[lud stringForKey:@"login"]     copy];
    self->password = [[lud stringForKey:@"password"]  copy];
    
    if ([self->login length] == 0) {
      [self usage];
      [self release];
      return nil;
    }
  }
  return self;
}
- (void)dealloc {
  [self->ud       release];
  [self->command  release];
  [self->login    release];
  [self->password release];
  [self->lso      release];
  [super dealloc];
}

/* process */

- (int)read:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSString *key = nil;
  
  if ([_args count] > 2)
    key = [_args objectAtIndex:2];
  
  if ([key length] > 0) {
    id obj;
    
    if ((obj = [ud objectForKey:key]) == nil) {
      NSLog(@"There is no key '%@' in the defaults of the account.", key);
      return 3;
    }
    
    printf("%s\n", [[obj description] cString]);
    return 0;
  }

  {
    NSString     *domainName;
    NSDictionary *domain;
    
    domainName = 
      [[[_ctx valueForKey:LSAccountKey] valueForKey:@"companyId"] stringValue];
    
    /* Note: apparently OGo domains are volatile?! */
    if ((domain = [ud persistentDomainForName:domainName])) {
      printf("%s\n", [[domain description] cString]);
      return 0;
    }
    if ((domain = [ud volatileDomainForName:domainName])) {
      printf("%s\n", [[domain description] cString]);
      return 0;
    }

    NSLog(@"did not find domain '%@'", domainName);
  }
  
  return 2;
}

- (int)write:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  return 2;
}
- (int)delete:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  return 2;
}

- (int)domains:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSLog(@"domains: (account=%@, template=%@) %@", 
        [[_ctx valueForKey:LSAccountKey] valueForKey:@"companyId"],
        [[_ctx valueForKey:LSAccountKey] valueForKey:@"templateUserId"],
        [ud searchList]);
  return 2;
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  int rc;

  /* process arguments */
  if ([_args count] < 2) {
    [self usage];
    return 1;
  }

  self->ud = [[_ctx userDefaults] retain];
  
  self->command = [[_args objectAtIndex:1] copy];
  if ([self->command length] == 0) {
    [self usage];
    return 1;
  }
  
  if ([self->command isEqualToString:@"read"])
    rc = [self read:_args onContext:_ctx];
  else if ([self->command isEqualToString:@"write"])
    rc = [self write:_args onContext:_ctx];
  else if ([self->command isEqualToString:@"delete"])
    rc = [self delete:_args onContext:_ctx];
  else if ([self->command isEqualToString:@"domains"])
    rc = [self domains:_args onContext:_ctx];
  else {
    [self usage];
    return 2;
  }
  
  /* transaction */
  
  if ([_ctx isTransactionInProgress]) {
    if (![_ctx rollback])
      NSLog(@"transaction could not be rolled back!");
  }
  return rc;
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

@end /* Defaults */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  rc = [Defaults run:[[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
