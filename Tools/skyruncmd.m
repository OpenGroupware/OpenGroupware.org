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
  skyruncmd

  A small sample program that can run or list arbitary OGo Logic commands.
*/

@class NSString, NSArray, NSDictionary;
@class OGoContextManager, LSCommandContext;

@interface RunCmd : NSObject
{
  OGoContextManager *lso;
  LSCommandContext  *ctx;
  NSString          *login;
  NSString          *password;
  NSString          *command;
  NSDictionary      *args;
}

+ (int)run:(NSArray *)_args;

- (void)printResult:(id)_result;

@end

#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation RunCmd

- (void)usage {
  fprintf(stderr,
          "skyruncmd "
          "-login <login> -password <pwd> "
          "<cmd> [(<key> <value>)*]\n\n"
          "  examples:\n"
	  "    skyruncmd -login donald -password x person::get  login donald\n"
	  "    skyruncmd -login donald -password x project::get number SALES\n"
	  "    skyruncmd -login donald -password x job::get-todo-jobs\n"
	  "\n"
	  "  special keys:\n"
	  "    returnType - to return 'many' objects, use 2\n"
	  "\n");
}

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      NSLog(@"ERROR: could not create OGo context manager.");
      [self release];
      return nil;
    }
    
    self->login    = [[ud stringForKey:@"login"]     copy];
    self->password = [[ud stringForKey:@"password"]  copy];
    
    if ([self->login length] == 0) {
      [self usage];
      [self release];
      return nil;
    }
  }
  return self;
}
- (void)dealloc {
  [self->command  release];
  [self->args     release];
  [self->login    release];
  [self->password release];
  [self->lso      release];
  [super dealloc];
}

/* process */

- (int)listCommands {
  // TODO: implement
  NSArray  *a;
  unsigned i, count;

  [self usage];
  
  printf("Available Commands:");
  fflush(stdout);
  a = [[[NGBundleManager defaultBundleManager] 
                         providedResourcesOfType:@"LSCommands"]
                         valueForKey:@"name"];
  count = [a count];
  printf(" (%i commands)\n", count);
  a = [a sortedArrayUsingSelector:@selector(compare:)];
  for (i = 0 ; i < count; i++)
    printf("%s\n", [[[a objectAtIndex:i] stringValue] cString]);
  
  return 1;
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  id result;

  /* process arguments */
  
  if ([_args count] < 1) {
    [self usage];
    return 1;
  }
  if ([_args count] < 2) 
    return [self listCommands];
  
  self->command = [[_args objectAtIndex:1] copy];
  if ([self->command length] == 0)
    return [self listCommands];
  
  if ([_args count] > 2) { /* collect parameters */
    NSMutableDictionary *md;
    NSEnumerator *e;
    NSString     *key;
    
    e = [_args objectEnumerator];
    [e nextObject]; // skip toolname
    [e nextObject]; // skip commandname
    
    md = [NSMutableDictionary dictionaryWithCapacity:16];
    while ((key = [e nextObject])) {
      NSString *value;

      if ((value = [e nextObject]) == nil) {
        NSLog(@"missing value for key: '%@' ?", key);
        continue;
      }
      [md setObject:value forKey:key];
    }
    self->args = [md copy];
  }

  /* run */
  
  NSLog(@"RUN: %@", self->command);

  NS_DURING
    result = [_ctx runCommand:self->command arguments:self->args];
  NS_HANDLER
    result = [[localException retain] autorelease];
  NS_ENDHANDLER;
  
  if (result) {
    [self printResult:result];
  }
  else {
    NSLog(@"no result was returned by command!");
  }
  
  /* transaction */
  
  if ([_ctx isTransactionInProgress]) {
    if (![_ctx commit]) {
      NSLog(@"transaction could not be committed!");
      [_ctx rollback];
    }
  }
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

/* output handling */

- (void)printException:(NSException *)_exception {
  NSLog(@"EXCEPTION:\n  name:   %@\n  reason: %@\n  info: %@", 
	[_exception name], [_exception reason], [_exception userInfo]);
}

- (void)printArrayResult:(NSArray *)_array {
  unsigned len;
  
  if ((len = [_array count]) == 0) {
    printf("[empty array]\n");
    return;
  }
  else if (len == 1) {
    printf("[single object array]\n");
    [self printResult:[_array objectAtIndex:0]];
    return;
  }
  else {
    unsigned i;

    printf("[array result: %i records]\n\n", len);
    
    for (i = 0; i < len; i++) {
      printf("[  result entry %i of %i]\n\n", i+1, len);
      
      [self printResult:[_array objectAtIndex:i]];
    }
  }
}

- (void)printEOGenericRecord:(EOGenericRecord *)_record {
  NSArray  *keys;
  unsigned i, count;
  
  keys = [[_record attributeKeys] 
           sortedArrayUsingSelector:@selector(compare:)];
  count = [keys count];
  
  printf("[EOGenericRecord: %s, %i keys]\n",
         [[[_record entity] name] cString], count);
  for (i = 0; i < count; i++) {
    NSString *key;
    id value;

    key   = [keys objectAtIndex:i];
    value = [_record valueForKey:key];
    
    printf("  %-20s: ", [key cString]);

    if ([value isNotNull]) {
      printf("%-20s", [[value stringValue] cString]);
      printf(" <%s>", [NSStringFromClass([value class]) cString]);
    }
    else
      printf("[nil]");
    
    printf("\n");
  }
}

- (void)printResult:(id)_result {
  if ([_result isKindOfClass:[NSException class]]) {
    [self printException:_result];
  }
  else if ([_result isKindOfClass:[NSArray class]]) {
    [self printArrayResult:_result];
  }
  else if ([_result isKindOfClass:[EOGenericRecord class]]) {
    [self printEOGenericRecord:_result];
  }
  else {
    /* output */
    printf("%s\n", [[_result description] cString]);
    fflush(stdout);
  }
}

@end /* RunCmd */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  rc = [RunCmd run:[[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
