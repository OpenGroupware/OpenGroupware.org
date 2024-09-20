/*
  Copyright (C) 2006 SKYRIX Software AG
  Copyright (C) 2006 Helge Hess

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

@class NSArray;
@class OGoContextManager, LSCommandContext;

@interface OGoTaskQualifierSearchTool : NSObject
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

@implementation OGoTaskQualifierSearchTool

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    self->lso       = [[OGoContextManager defaultManager] retain];
    self->login     = [[ud stringForKey:@"login"]     copy];
    self->password  = [[ud stringForKey:@"password"]  copy];
    self->sxid      = [[ud stringForKey:@"skyrix_id"] copy];
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

/* usage */

- (void)usage:(NSString *)_toolName {
  static const char *toolname = "ogo-qsearch-task";
  fprintf(stderr,
	  "Usage:\n"
          "  %s -login <login> -password <pwd> <qualifier>\n\n"
          "  examples:\n"
	  "    %s -login donald -password x 'name = \"Duck\"'\n"
	  "\n", toolname, toolname);
}

/* result processing */

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

/* run with context */

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSArray  *records;
    
  /* clean up arguments */
  
  if ([_args count] < 2) {
    [self usage:[_args lastObject]];
    return 1;
  }
  
  /* fetch records */
  
#warning TODO
   records = [_ctx runCommand:@"job::qsearch", 
                              @"qualifier", [_args objectAtIndex:1],
                              nil];
  [self printArrayResult:records];
  return 0;
}

/* parameter run */

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

@end /* OGoTaskQualifierSearchTool */


int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  rc = [OGoTaskQualifierSearchTool run:[[NSProcessInfo processInfo] 
					   argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
