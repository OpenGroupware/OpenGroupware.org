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

#include <OGoFoundation/LSWViewerPage.h>

@interface LSWTeamViewer : LSWViewerPage
{
@private
  id item;
  id defaults;
}

@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <NGMime/NGMimeType.h>

@implementation LSWTeamViewer

static BOOL IsMailConfigEnabled = NO;

+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  IsMailConfigEnabled = [ud boolForKey:@"MailConfigEnabled"];
}

- (id)init {
  if ((self = [super init])) {
    [self registerForNotificationNamed:LSWUpdatedAccountNotificationName];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->defaults release];
  [super dealloc];
}

/* activation */

- (BOOL)_prepareGlobalID:(EOKeyGlobalID *)gid type:(NGMimeType *)_type {
  id obj;
  
  if (![[_type subType] isEqualToString:@"team"])
    return NO;
  
  // TODO: rewrite to use get-by-globalid?!
  obj = [self run:@"team::get", @"companyId", [gid keyValues][0], nil];
  obj = [obj lastObject];
  
  [self setObject:obj];
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_verb type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id obj, members;
  
  if (![super prepareForActivationCommand:_verb type:_type 
	      configuration:_cmdCfg])
    return NO;


  if ([[_type type] isEqualToString:@"eo-gid"]) {
    if (![self _prepareGlobalID:[self object] type:_type])
      return NO;
  }
  
  obj = [self object];
    
  NSAssert(obj, @"no team is set !");
    
  if ((members = [obj valueForKey:@"members"]) == nil) {
    [self runCommand:
            @"team::members",
            @"object",     obj,
            @"returnType", intObj(LSDBReturnType_ManyObjects), 
            nil];
  }
  self->defaults = 
    [[self runCommand:@"userdefaults::get", @"user", obj, nil] retain];
  return YES;
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (_object == nil)
    return;
  if (![_cn isEqualToString:LSWUpdatedTeamNotificationName])
    return;
  
  [self runCommand:
            @"team::members",
            @"object",     _object,
            @"returnType", intObj(LSDBReturnType_ManyObjects), 
	nil];
}

/* accessors */

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (id)team {
  return [self object];
}

- (NSString *)isLocationTeam {
  NSNumber *isLocationTeam;

  isLocationTeam = [[self object] valueForKey:@"isLocationTeam"];

  return [[self labels] valueForKey:[isLocationTeam boolValue]
                        ? @"yesValue" : @"noValue"];
}

- (NSUserDefaults *)defaults {
  return self->defaults;
}

- (BOOL)isMailConfigEnabled {
  return IsMailConfigEnabled;
}

/* actions */

- (id)viewAccount {
  return [self activateObject:self->item withVerb:@"viewPreferences"];
}

@end /* LSWTeamViewer */
