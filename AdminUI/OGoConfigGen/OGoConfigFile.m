/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "OGoConfigFile.h"
#include "OGoConfigDatabase.h"
#include "OGoConfigEntryGlobalID.h"
#include "common.h"
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSFoundation.h>

@implementation OGoConfigFile

- (id)initWithPath:(NSString *)_path configDatabase:(OGoConfigDatabase *)_db {
  if ((self = [super init])) {
    self->path     = [_path copy];
    self->database = [_db retain];
  }
  return self;
}
- (void)dealloc {
  [self->database release];
  [self->path release];
  [super dealloc];
}

/* accessors */

- (NSString *)name {
  return [[self->path lastPathComponent] stringByDeletingPathExtension];
}
- (NSString *)configType {
  return NSStringFromClass([self class]);
}
- (EOGlobalID *)globalID {
  return [[[OGoConfigEntryGlobalID alloc] initWithEntryName:[self name]] 
	                           autorelease];
}

/* common operations */

- (NSUserDefaults *)defaultsForAccount:(id)_account
  inContext:(LSCommandContext *)_ctx
{
  return [_ctx runCommand:@"userdefaults::get", @"user", _account, nil];
}
- (NSUserDefaults *)defaultsForTeam:(id)_team
  inContext:(LSCommandContext *)_ctx
{
  return [_ctx runCommand:@"userdefaults::get", @"user", _team, nil];
}

- (BOOL)shouldExportAccount:(id)_account inContext:(LSCommandContext *)_ctx {
  NSUserDefaults *defs;
  
  if ((defs = [self defaultsForAccount:_account inContext:_ctx]) == nil)
    return NO;

  return [defs boolForKey:@"admin_exportAddresses"];
}
- (BOOL)shouldExportTeam:(id)_team inContext:(LSCommandContext *)_ctx {
  NSUserDefaults *defs;
  
  if ((defs = [self defaultsForTeam:_team inContext:_ctx]) == nil)
    return NO;
  
  return [defs boolForKey:@"admin_team_doexport"];
}

/* common fetches */

- (NSArray *)fetchTeamGlobalIDsInContext:(LSCommandContext *)_ctx {
  if (_ctx == nil) {
    [self logWithFormat:@"ERROR: missing command context."];
    return nil;
  }
  return [_ctx runCommand:@"team::get-all", 
	       @"fetchGlobalIDs", [NSNumber numberWithBool:YES], nil];
}

- (NSArray *)fetchTeamEmailsForGlobalIDs:(NSArray *)_gids 
  inContext:(LSCommandContext *)_ctx
{
  NSArray *attrNames;

  if (_gids         == nil) return nil;
  if ([_gids count] == 0)   return _gids;
  
  attrNames = [NSArray arrayWithObjects:
			 @"description", @"email", @"globalID", nil];
  return [_ctx runCommand:@"team::get-by-globalid",
	         @"gids",       _gids,
	         @"attributes", attrNames,
	         nil];
}

- (NSArray *)fetchAccountLoginsForGlobalIDs:(NSArray *)_gids 
  inContext:(LSCommandContext *)_ctx
{
  NSArray *attrNames;

  if (_gids         == nil) return nil;
  if ([_gids count] == 0)   return _gids;
  
  attrNames = [NSArray arrayWithObjects:@"login",@"companyId",@"globalID",nil];
  return [_ctx runCommand:@"person::get-by-globalid",
	         @"gids",       _gids,
	         @"attributes", attrNames,
	         nil];
}

- (NSArray *)fetchAllTeamEOsInContext:(LSCommandContext *)_ctx {
  return [_ctx runCommand:@"team::get-all", nil];
}

- (NSArray *)fetchAccountGlobalIDsForTeamGlobalID:(EOGlobalID *)_gid 
  inContext:(LSCommandContext *)_ctx
{
  return [_ctx runCommand:@"team::expand", 
	         @"teamGID", _gid,
	         @"fetchGlobalIDs", [NSNumber numberWithBool:YES], nil];
}

- (NSArray *)fetchAllAccountEOsInContext:(LSCommandContext *)_ctx {
  return [_ctx runCommand:@"account::get", 
               @"returnType", 
               [NSNumber numberWithInt:LSDBReturnType_ManyObjects], nil];
}
- (NSArray *)fetchAccountGlobalIDsInContext:(LSCommandContext *)_ctx {
  // TODO: is there a way to fetch just the GIDs?
  return [[self fetchAllAccountEOsInContext:_ctx] valueForKey:@"globalID"];
}

/* factory */

+ (NSArray *)configFileStorageKeys {
  NSLog(@"%s: actual factory subclass needs to override this method!",
        __PRETTY_FUNCTION__);
  return nil;
}

- (NSDictionary *)propertyList {
  return [self valuesForKeys:[[self class] configFileStorageKeys]];
}

+ (id)instantiateWithDictionary:(NSDictionary *)_values
  path:(NSString *)_path configDatabase:(OGoConfigDatabase *)_db
{
  id obj;
  
  if ((obj = [[self alloc] initWithPath:_path configDatabase:_db]) == nil)
    return nil;
  
  if (_values) [obj takeValuesFromDictionary:_values];
  return obj;
}

+ (id)loadEntryFromPath:(NSString *)_p configDatabase:(OGoConfigDatabase *)_db{
  NSArray      *sk;
  NSDictionary *d;

  if (_p == nil)
    return nil;
  
  if ((sk = [self configFileStorageKeys]) == nil) {
    NSLog(@"%s: factory %@ does not provide filestorage keys: %@",
          __PRETTY_FUNCTION__, self, _p);
    return nil;
  }
  
  // TODO: only works on local filesystem
  if ((d = [[NSDictionary alloc] initWithContentsOfFile:_p]) == nil) {
    NSLog(@"%s: could not load file as dictionary: '%@'",
          __PRETTY_FUNCTION__, _p);
    return nil;
  }
  
  if ((d = [[d autorelease] valuesForKeys:sk]) == nil) {
    NSLog(@"%s: could not restrict to storage keys: %@", 
          __PRETTY_FUNCTION__, sk);
    return nil;
  }
  
  return [self instantiateWithDictionary:d path:_p configDatabase:_db];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];

  if (self->path)
    [ms appendFormat:@" file='%@'", [self->path lastPathComponent]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoConfigFile */
