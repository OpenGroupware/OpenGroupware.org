/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxProjectsFolder.h"
#include <ZSFrontend/SxMapEnumerator.h>
#include "common.h"

// TODO: we should use commands only
#include <OGoProject/SkyProjectDataSource.h>

@implementation SxProjectsFolder

static BOOL debugOn = NO;
static BOOL kontactGroupDAV = YES;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SxProjectsFolderDebugEnabled"];
  kontactGroupDAV = 
    [ud boolForKey:@"ZSDisableKontact34GroupDAVHack"] ? NO : YES;
}

- (void)dealloc {
  [self->projectNames release];
  [super dealloc];
}

/* child names */

- (NSArray *)toManyRelationshipKeys {
  LSCommandContext *cmdctx;
  NSArray          *names, *projects;

  if (self->projectNames)
    return self->projectNames;
  
  if ((cmdctx = [self commandContextInContext:nil]) == nil) {
    [self logWithFormat:@"no command context!"];
    return nil;
  }
  
  projects = [cmdctx runCommand:@"person::get-projects",
                       @"object", [cmdctx valueForKey:LSAccountKey], 
                     nil];
  names = [projects valueForKey:@"number"];
  
  self->projectNames = 
    [[names sortedArrayUsingSelector:@selector(compare:)] copy];
  
  [self debugWithFormat:@"  fetched %i project names", [names count]];
  return self->projectNames;
}

- (NSEnumerator *)davChildKeysInContext:(id)_ctx {
  [self debugWithFormat:@"davChildKeysInContext:"];
  return [[self toManyRelationshipKeys] objectEnumerator];
}

- (EODataSource *)rawContentDataSourceInContext:(id)_ctx {
  SkyProjectDataSource *ds;
  id cmdctx;

  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"missing command context."];
    return nil;
  }
  ds = [SkyProjectDataSource alloc]; /* seperate line to keep gcc happy */
  ds = [[ds initWithContext:cmdctx] autorelease];
  if (ds == nil) {
    [self logWithFormat:@"could not create project datasource!"];
    return nil; 
  }
  // TODO: setup some useful spec?
  return ds;
}

/* name lookup */

- (BOOL)isProjectName:(NSString *)_name inContext:(id)_ctx {
  if ([_name length] == 0) return NO;
  return [[self toManyRelationshipKeys] containsObject:_name];
}

- (BOOL)isNewKey:(NSString *)_key inContext:(id)_ctx {
  return [self isProjectName:_key inContext:_ctx] ? NO : YES;
}

- (Class)recordClassForKey:(NSString *)_key {
  /* triggered by SxFolder lookup */
  return NSClassFromString(@"SxProjectFolder");
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  if ([_key isEqualToString:@"getIDsAndVersions"])
    return [self getIDsAndVersionsAction:_ctx];
  
  if (kontactGroupDAV) {
    WEClientCapabilities *cc;
  
    cc = [[_ctx request] clientCapabilities];
    if ([[cc userAgentType] isEqualToString:@"Konqueror"]) {
      if ([cc majorVersion] == 3 && [cc minorVersion] == 4) {
	if (![[_ctx valueForKey:@"KontactGroupDAVDidWarn"] boolValue]) {
	  [self logWithFormat:
		  @"WARNING: applying Kontact 3.4 GroupDAV hack"
		  @" - project browsing is disabled!"
		  @" (can be enabled using 'ZSDisableKontact34GroupDAVHack')"];
	  [_ctx takeValue:@"YES" forKey:@"KontactGroupDAVDidWarn"];
	}
	return nil;
      }
    }
  }
  
  [self logWithFormat:@"CC: %@",
	[[_ctx request] clientCapabilities]];
  
  return [super lookupName:_key inContext:_ctx acquire:_flag];
}

/* actions */

- (NSString *)defaultMethodNameInContext:(id)_ctx {
  return @"view";
}

/* RSS support */

- (NSString *)rssChannelTitleInContext:(WOContext *)_ctx {
  NSString *s;
  
  s = @"OGo Projects for User '";
  s = [s stringByAppendingString:[[_ctx activeUser] login]];
  s = [s stringByAppendingString:@"'"];
  return s;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->projectNames)
    [ms appendFormat:@" #projects=%i", [self->projectNames count]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxProjectsFolder */
