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
// $Id$

#include <OGoFoundation/OGoComponent.h>

@class EOFilterDataSource, NSUserDefaults;

@interface SkyP4ProjectTableView : OGoComponent
{
  EOFilterDataSource *dataSource;
  NSArray            *selections;
  NSUserDefaults     *userDefaults;
  NSArray            *favoriteProjectIds;

  /* temporary */
  id   project;
  id   groups;
  BOOL isDescending;
}

@end

#include <NGMime/NGMimeType.h>
#include "common.h"
#include <time.h>

@implementation SkyP4ProjectTableView

- (void)dealloc {
  [self->dataSource         release];
  [self->selections         release];
  [self->userDefaults       release];
  [self->favoriteProjectIds release];
  
  [super dealloc];
}

/* accessors */

- (void)setDataSource:(EOFilterDataSource *)_ds {
  ASSIGN(self->dataSource, _ds);
}
- (EOFilterDataSource *)dataSource {
  return self->dataSource;
}

- (void)setIsDescending:(BOOL)_flag {
  self->isDescending = _flag;
}
- (BOOL)isDescending {
  return self->isDescending;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setGroups:(id)_groups {
  ASSIGN(self->groups, _groups);
}
- (id)groups {
  return self->groups;
}

- (void)setSelections:(NSArray *)_selections {
  ASSIGN(self->selections, _selections);
}
- (NSArray *)selections {
  return self->selections;
}

- (NSUserDefaults *)userDefaults {
  if (self->userDefaults == nil)
    self->userDefaults = [[(OGoSession *)[self session] userDefaults] retain];
  
  return self->userDefaults;
}

- (NSArray *)favoriteProjectIds {
  if (self->favoriteProjectIds == nil) {
    self->favoriteProjectIds =
      [[[(OGoSession *)[self session] commandContext]
	       runCommand:@"project::get-favorite-ids", nil] retain];
  }
  return self->favoriteProjectIds;
}

- (NSString *)projectId {
  return [[self->project valueForKey:@"projectId"] stringValue];
}

/* notifications */

- (void)sleep {
  /* tear down temporary variables */
  [self->groups             release]; self->groups             = nil;
  [self->project            release]; self->project            = nil;
  [self->userDefaults       release]; self->userDefaults       = nil;
  [self->favoriteProjectIds release]; self->favoriteProjectIds = nil;
  [super sleep];
}

/* conditionals */

- (BOOL)isInFavorites {
  return [[self favoriteProjectIds] containsObject:[self projectId]];
}

/* actions */

- (NSString *)newWizardURL {
  /* 
     TODO: this is necessary because SkyButtonRow can't trigger direct
           actions. (which should be fixed)
  */
  static NSString *keys[3] = { @"wosid", @"t", nil };
  NSDictionary *qd;
  id values[2];
  values[0] = [[self session] sessionID];
  values[1] = [NSNumber numberWithUnsignedInt:time(NULL)];
  qd = [[[NSDictionary alloc] 
	    initWithObjects:values forKeys:keys count:2]
	    autorelease];
  return [[self context] directActionURLForActionNamed:
			   @"OGoProjectAction/new"
			 queryDictionary:qd];
}

- (id)sortAction {
  NSUserDefaults *ud;
  NSString       *sortedKey;
  NSArray        *sos         = nil;
  EOSortOrdering *so          = nil;
  SEL      sel;
  
  ud        = [self userDefaults];
  sortedKey = [ud stringForKey:@"skyp4_desktop_sortfield"];
  sel = [[self valueForKey:@"isDescending"] boolValue] 
    ? EOCompareDescending : EOCompareAscending;
  
  so  = [EOSortOrdering sortOrderingWithKey:sortedKey selector:sel];
  sos = [NSArray arrayWithObject:so];
  
  if (![[[self dataSource] sortOrderings] isEqual:sos])
    [[self dataSource] setSortOrderings:sos];
  
  return nil;
}

- (BOOL)_modifyFavorites:(BOOL)_doRemove {
  //NSMutableArray *favIds;
  id cmdctx;
    
  if (_doRemove && ![self isInFavorites])
    return NO; /* not in favorites */
  if (!_doRemove && [self isInFavorites])
    return NO; /* already in favorites */

  cmdctx = [(OGoSession *)[self session] commandContext];
  if (_doRemove)
    [cmdctx runCommand:@"project::remove-favorite",
            @"projectId", [self projectId],
            nil];
  else
    [cmdctx runCommand:@"project::add-favorite",
            @"projectId", [self projectId],
            nil];
  
  [self->favoriteProjectIds release]; self->favoriteProjectIds = nil;
  return YES;
}

- (id)addToFavorites {
  [self _modifyFavorites:NO /* NO means "add favorite" */];
  return nil;
}
- (id)removeFromFavorites {
  [self _modifyFavorites:YES /* YES means "remove favorite" */];
  return nil; 
}

@end /* SkyP4ProjectTableView */
