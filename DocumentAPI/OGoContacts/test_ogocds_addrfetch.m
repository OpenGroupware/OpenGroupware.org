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

@interface OGoTestTool : NSObject
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
#include <OGoContacts/SkyCompanyDocument.h>

@implementation OGoTestTool

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

/* run with context */

- (void)printAddressesOfContact:(id)_doc {
  NSArray  *types;
  unsigned i, count;
  
  types = [_doc addressTypes];
  for (i = 0, count = [types count]; i < count; i++) {
    id a = [_doc addressForType:[types objectAtIndex:i]];
    printf("         %-8s %-16s %-10s %-10s\n",
           [[types objectAtIndex:i] cString],
           [[a valueForKey:@"name1"]  cString],
           [[a valueForKey:@"street"] cString],
           [[a valueForKey:@"city"]   cString]);
  }
}

- (void)printResults:(NSArray *)_objs {
  unsigned i, count;

  printf("%8s %-16s %-16s %-16s %s\n", 
         "id", "lastname", "firstname", "login", "class");
  
  for (i = 0, count = [_objs count]; i < count; i++) {
    id o = [_objs objectAtIndex:i];
    
    printf("%8d %-16s %-16s %-16s %s%s\n",
           [[o valueForKey:@"companyId"]   intValue],
           [[o valueForKey:@"name"]        cString],
           [[o valueForKey:@"firstname"]   cString],
           [[o valueForKey:@"login"]       cString],
           [NSStringFromClass([o class]) cString],
           [o isComplete] ? "(complete)" : "(fragment)");
    
    // Note: SkyCompanyDocument also supports special KVC keys like:
    //         'ship_street'
    [self printAddressesOfContact:o];
  }
}

- (void)runFetchInDataSource:(EODataSource *)_ds {
  NSArray *o;
  
  if ((o = [_ds fetchObjects]) == nil) {
    [self logWithFormat:@"datasource returned 'nil'!"];
    return;
  }
  
  [self logWithFormat:@"datasource fetched %d objects ..", [o count]];
  [self printResults:o];
}

- (Class)dsClass {
  return NSClassFromString(@"SkyPersonDataSource");
}

- (NSDictionary *)fetchHints {
  NSArray *attrs;
  
  attrs = [NSArray arrayWithObjects:
                     @"firstname", @"name", @"login", @"addresses", @"phones",
                     nil];

  return [NSDictionary dictionaryWithObjectsAndKeys:
                         attrs, @"attributes",
                         [NSNumber numberWithBool:NO],
                         @"addDocumentsAsObserver",
                         nil];
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  EODataSource *ds;
  NSEnumerator *e;
  NSString     *s;
  
  ds = [[[[self dsClass] alloc] initWithContext:_ctx] autorelease];
  [self logWithFormat:@"datasource: %@", ds];
  
  e = [_args objectEnumerator];
  [e nextObject]; // skip tool name
  
  while ((s = [e nextObject]) != nil) {
    NSAutoreleasePool *pool;
    EOFetchSpecification *fs;
    
    fs = [[EOFetchSpecification alloc] initWithPropertyList:s owner:nil];
    if (fs == nil) {
      [self logWithFormat:@"ERROR: could not parse fetchspec: '%@'", s];
      continue;
    }
    [fs setHints:[self fetchHints]];
    
    [self logWithFormat:@"Evaluate fetchspec %@: %@", s, fs];
    [ds setFetchSpecification:fs];
    [fs release]; fs = nil;
    
    pool = [[NSAutoreleasePool alloc] init];
    [self runFetchInDataSource:ds];
    [pool release];
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

@end /* OGoTestTool */


int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  rc = [OGoTestTool run:
                      [[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
