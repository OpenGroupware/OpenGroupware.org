/*
  Copyright (C) 2005 SKYRIX Software AG

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

@interface OGoVCardGetTool : NSObject
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

@implementation OGoVCardGetTool

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

/* usage */

- (void)usage {
  static const char *toolname = "ogo-vcard-get";
  fprintf(stderr,
	  "Usage:\n"
          "  %s -login <login> -password <pwd> <id1> <id2> <id3>\n\n"
          "  examples:\n"
	  "    %s -login donald -password x 10000 10003 \n"
	  "\n", toolname, toolname);
}

/* run with context */

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSArray  *gids;
  NSArray  *vcards;
  unsigned i, count;
  
  /* clean up arguments */
  
  _args = [_args subarrayWithRange:NSMakeRange(1, [_args count] - 1)];
  if ([_args count] == 0) {
    [self usage];
    return 1;
  }
  
  _args = [_args valueForKey:@"intValue"];
  
  /* fetch types (part of gids) of the primary keys */
  
  gids = [[_ctx typeManager] globalIDsForPrimaryKeys:_args];
  if ([gids count] == 0) {
    fprintf(stderr, "could not fetch any ids: %s\n",
	    [[_args description] cString]);
    return 2;
  }
  
  /* fetch vcards */
  
  vcards = [_ctx runCommand:@"company::get-vcard", @"gids", gids, nil];
  
  /* output */
  
  for (i = 0, count = [vcards count]; i < count; i++) {
    const char *vc;

    vc = [[vcards objectAtIndex:i] UTF8String];
    fwrite(vc, strlen(vc), 1, stdout);
    fflush(stdout);
  }
  
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

@end /* OGoVCardGetTool */


int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  rc = [OGoVCardGetTool run:[[NSProcessInfo processInfo] 
			      argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
