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

@interface OGoVCardPutTool : NSObject
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

// we need to cheat a bit to support both, SOPE 4.4 and SOPE 4.5
@interface NSObject(NGVCard)
+ (NSArray *)parseVCardsFromSource:(id)_src;
@end

@implementation OGoVCardPutTool

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
  static const char *toolname = "ogo-vcard-put";
  fprintf(stderr,
	  "Usage:\n"
          "  %s -login <login> -password <pwd> <file1> <file2> <file3>\n\n"
          "  examples:\n"
	  "    %s -login donald -password x donald.vcf\n"
	  "\n", toolname, toolname);
}

/* run with context */

- (int)runOnVCard:(id)_vCard inContext:(LSCommandContext *)_ctx {
  id result;
  
  NSLog(@"    import %@", [_vCard valueForKey:@"uid"]);
  result = [_ctx runCommand:@"company::set-vcard",
		 @"vCardObject", _vCard, nil];
  NSLog(@"    added record: %@", [result valueForKey:@"companyId"]);
  
  return 0;
}

- (int)runOnURL:(NSURL *)_url inContext:(LSCommandContext *)_ctx {
  NSArray  *vCards;
  unsigned i, count;
  
  if (_url == nil) return 5;
  
  NSLog(@"parse vCard file: %@", [_url absoluteString]);
  vCards = [NSClassFromString(@"NGVCard") parseVCardsFromSource:_url];
  if (vCards == nil) {
    NSLog(@"ERROR: could not parse vCards from source: %@", _url);
    return 6;
  }
  
  NSLog(@"  import %d vCards ...", [vCards count]);
  for (i = 0, count = [vCards count]; i < count; i++) {
    int rc;
    
    if ((rc = [self runOnVCard:[vCards objectAtIndex:i] inContext:_ctx]) != 0)
      return rc;
  }
  NSLog(@"done.");
  return 0;
}

- (int)runOnPath:(NSString *)_path inContext:(LSCommandContext *)_ctx {
  NSURL *url;
  
  if (![_path isAbsolutePath]) {
    _path = [[[NSFileManager defaultManager] currentDirectoryPath]
	      stringByAppendingPathComponent:_path];
  }
  
  if ((url = [NSURL fileURLWithPath:_path]) == nil) {
    NSLog(@"ERROR: could not make URL from path: %@", _path);
    return 1;
  }
  
  return [self runOnURL:url inContext:_ctx];
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSEnumerator *files;
  NSString *p;
  
  if ([_args count] < 2) {
    [self usage];
    return 1;
  }

  files = [_args objectEnumerator];
  [files nextObject]; // skip tool name
  
  while ((p = [files nextObject]) != nil) {
    int rc;
    
    if ((rc = [self runOnPath:p inContext:_ctx]) != 0)
      return rc;
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

@end /* OGoVCardPutTool */


int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  rc = [OGoVCardPutTool run:[[NSProcessInfo processInfo] 
			      argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
