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

#include <LSFoundation/LSGetObjectForGlobalIDs.h>

@interface LSGetSessionLogsForGlobalIDs : LSGetObjectForGlobalIDs
@end

#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSCommandContext.h>
#include <GDLAccess/GDLAccess.h>
#include <NGExtensions/NGExtensions.h>
#include <EOControl/EOControl.h>
#import <Foundation/Foundation.h>

@implementation LSGetSessionLogsForGlobalIDs

static BOOL disableSessionLog = NO;

+ (void)initialize {
  disableSessionLog = 
    [[NSUserDefaults standardUserDefaults] boolForKey:@"LSDisableSessionLog"];
}

- (BOOL)isSessionLogEnabledInContext:(id)_ctx {
  return disableSessionLog ? NO : YES;
}

- (void)_prepareForExecutionInContext:(id)_context {
  if (![self isSessionLogEnabledInContext:_context])
    return;
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  /* TODO: split up this huge method ... */
  id  results;
  int i, cnt;
  NSMutableArray      *accountKeys;
  NSMutableArray      *attrs       = nil;
  NSMutableSet        *accountGids;
  NSMutableArray      *newResults;
  NSMutableDictionary *mapped = nil;
  id accounts;
  
  if (![self isSessionLogEnabledInContext:_context])
    return;
  
  if (self->attributes == nil) {
    [super _executeInContext:_context];
    return;
  }

  // first pick "account.*" attributes out and then call super

  accountKeys = [NSMutableArray arrayWithCapacity:16];
    
  for (i = 0, cnt = [self->attributes count]; i < cnt; i++) {
      NSString *attrName;

      attrName = [self->attributes objectAtIndex:i];
      
      if ([attrName hasPrefix:@"account."]) {
        [accountKeys addObject:[attrName substringFromIndex:8]];
        if (attrs == nil)
          attrs = [self->attributes mutableCopy];
        [attrs removeObject:attrName];
      }
  }
    
  if (attrs) {
    [self takeValue:attrs forKey:@"attributes"];
    [attrs release]; attrs = nil;
  }

  [super _executeInContext:_context];

  results = [self returnValue];

  if (!(([accountKeys count] > 0) && [results count] > 0))
    return;


  accountGids = [NSMutableSet setWithCapacity:32];

  if (self->groupBy)
    results = [results allValues];

  for (i = 0, cnt = [results count]; i < cnt; i++) {
    NSNumber      *pid;
    EOKeyGlobalID *pgid;
        
    pid  = [[results objectAtIndex:i] valueForKey:@"accountId"];
    pgid = [EOKeyGlobalID globalIDWithEntityName:@"Person" 
			  keys:&pid keyCount:1 zone:NULL];        
    [accountGids addObject:pgid];
  }
      
  if ([accountGids count] <= 0)
    return;
  

  cnt = [results count];
        
  newResults = [[NSMutableArray alloc] initWithCapacity:cnt];
    
  if (self->groupBy)
    mapped = [[NSMutableDictionary alloc] initWithCapacity:cnt];

  accounts = LSRunCommandV(_context,
			   @"person",     @"get-by-globalid",
			   @"gids",       accountGids,
			   @"groupBy",    @"globalID",
			   @"attributes", accountKeys,
			   @"fetchArchivedPersons",
			   [NSNumber numberWithBool:YES],
			   nil);

  for (i = 0; i < cnt; i++) {
    NSNumber      *pid;
    EOKeyGlobalID *pgid;
    id            account;
    NSMutableDictionary *log;

    log  = [[results objectAtIndex:i] mutableCopy];
    pid  = [log valueForKey:@"accountId"];
    pgid = [EOKeyGlobalID globalIDWithEntityName:@"Person" 
			  keys:&pid keyCount:1 zone:NULL];
    // TODO: should use -objectForKey:
    account = [accounts valueForKey:(id)pgid];
    if (account != nil) {
      [log setObject:account forKey:@"account"];
      [newResults addObject:log];

      if (self->groupBy) {
	[mapped setObject:[newResults lastObject]
		forKey:[log valueForKey:@"globalID"]];
      }
    }
  }
  if (self->groupBy) {
    [self setReturnValue:mapped];
    [mapped release];
  }
  else
    [self setReturnValue:newResults];

  [newResults release];
}

/* accessors */

- (NSString *)entityName {
  return @"SessionLog";
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_objs context:(id)_context {
}

@end /* LSGetSessionLogsForGlobalIDs */
