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
// $Id: SkyTool.m 1 2004-08-20 11:17:52Z znek $

#include "common.h"
#import  "SkyTool.h"

/*
  Exit codes:
  1 - missing login
  2 - wrong passwor or user
  3 - root login required

*/

@implementation SkyTool

- (void)dealloc {
  [self->commandContext release];
  [super dealloc];
}

- (BOOL)onlyRoot {
  return NO;
}

- (LSCommandContext *)commandContext {
  if (!self->commandContext) {
    NSUserDefaults *def;
    NSString       *login, *pwd;

    def = [NSUserDefaults standardUserDefaults];

    login = [def objectForKey:@"l"];
    pwd   = [def objectForKey:@"p"];

    if (!pwd)
      pwd = @"";

    if (![login length]) {
      NSLog(@"Missing login.");
      exit(1);
    }
    [self logFormat:@"Using login: %@", login];

    // TODO: shouldn't that use the OGoContextFactory?
    self->commandContext = [[LSCommandContext alloc] init];

    if (![self->commandContext login:login password:pwd]) {
      NSLog(@"Couldn`t login %@, wrong password or user\n", login);
      exit(2);
      [self->commandContext release]; self->commandContext = nil;
    }
  }
  return self->commandContext;
}

- (void)logFormat:(NSString *)_format,... {
  NSString *reason;
  va_list  ap;

  if (![self verbose])
    return;
  
  va_start(ap, _format);
  reason = [[[NSString alloc] initWithFormat:_format arguments:ap]
                       autorelease];
  va_end(ap);
  [self logString:reason];
}

- (void)logString:(NSString *)_str {
  if ([self verbose])
    NSLog(@"%@", _str);
}

- (BOOL)verbose {
  return self->verbose;
}

/* argument processing */

- (NSString *)additionalSwitches {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  NSLog(@"ERROR(%s): method is supposed to be overridden by subclass!");
  return nil;
#endif
}

- (NSString *)toolName {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  NSLog(@"ERROR(%s): method is supposed to be overridden by subclass!");
  return nil;
#endif
}

- (NSString *)toolDescription {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  NSLog(@"ERROR(%s): method is supposed to be overridden by subclass!");
  return nil;
#endif
}

- (NSString *)versionInformation {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  NSLog(@"ERROR(%s): method is supposed to be overridden by subclass!");
  return nil;
#endif
}

/* usage */

- (void)version {
  printf("%s version: %s\n", [[self toolName] cString],
         [[self versionInformation] cString]);
}

- (void)usage {
  printf("Usage: %s [OPTIONS]...\n", [[self toolName] cString]);
  printf("%s\n", [[self toolDescription] cString]);
  printf("Arguments:\n");
  printf("\t-h, --help\tdisplay this help\n");
  printf("\t--version\toutput version informantion\n");
  printf("\t-v, --verbose\tenter verbose mode\n");
  printf("\t-l\t\tlogin name\n");
  printf("\t-p\t\tpassword\n");
  printf("%s\n", [[self additionalSwitches] cString]);
}

- (int)runWithArguments:(NSArray *)_args {

  self->verbose = NO;

  if ([_args containsObject:@"--help"] ||
      [_args containsObject:@"-h"] ||
      [_args count] < 2) {
    [self usage];
    return 1;
  }
  if ([_args containsObject:@"--version"]) {
    [self version];
    return 1;
  }
  if ([_args containsObject:@"--verbose"] ||
      [_args containsObject:@"-v"]) {
    self->verbose = YES;
  }

  if ([self onlyRoot]) {
    LSCommandContext *ctx;

    ctx = [self commandContext];

    [self logFormat:@"login: %@", [ctx valueForKey:LSAccountKey]];

    if ([[[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"]
             intValue] != 10000) {
      NSLog(@"Root login is required");
      exit(3);
    }
  }
  return 0;
}

@end /* SkyTool */
