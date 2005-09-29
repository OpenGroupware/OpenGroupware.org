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

#import <LSFoundation/LSBaseCommand.h>

@interface LSGetFavoriteProjectIdsCommand : LSBaseCommand
@end

@interface LSModifyProjectFavoritesCommand : LSBaseCommand
{
  id projectId;
}

- (id)projectId;

@end

@interface LSAddProjectToFavoritesCommand : LSModifyProjectFavoritesCommand
@end

@interface LSRemoveProjectFromFavoritesCommand:LSModifyProjectFavoritesCommand
@end

#import "common.h"

#define PROJECT_FAVORITES_UD_KEY @"skyp4_desktop_selected_projects"

@implementation LSModifyProjectFavoritesCommand

- (void)dealloc {
  [self->projectId release];
  [super dealloc];
}

/* accessor */

- (void)setProjectId:(id)_projectId {
  ASSIGN(self->projectId,_projectId);
}
- (id)projectId {
  return self->projectId;
}

/* exec */

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:(projectId != nil)
        reason:@"missing projectId to add to/remove from favorites"];
  [super _prepareForExecutionInContext:_context];
}

/* key/value coding */

- (void)takeValue:(id)_val forKey:(NSString *)_key {
  if ([_key isEqualToString:@"projectId"] || [_key isEqualToString:@"id"])
    [self setProjectId:_val];
  else if ([_key isEqualToString:@"project"] ||
	   [_key isEqualToString:@"object"])
    [self setProjectId:[_val valueForKey:@"projectId"]];
  else
    [super takeValue:_val forKey:_key];
}

@end /* LSModifyProjectFavoritesCommand */


@implementation LSAddProjectToFavoritesCommand

- (void)_executeInContext:(id)_context {
  NSMutableArray *ma;
  NSArray        *favorites;
  
  favorites = [[_context userDefaults]
                         arrayForKey:PROJECT_FAVORITES_UD_KEY];
  if (favorites == nil) favorites = [NSArray array];
  
  ma = [[NSMutableArray alloc] initWithArray:favorites];
  if (![ma containsObject:[self projectId]]) {
    [ma addObject:[self projectId]];

    [[_context userDefaults] setObject:ma
                             forKey:PROJECT_FAVORITES_UD_KEY];
    [[_context userDefaults] synchronize];
  }
  
  [ma release];
  [self setReturnValue:[NSNumber numberWithBool:YES]];
}

@end /* LSAddProjectToFavoritesCommand */


@implementation LSRemoveProjectFromFavoritesCommand

- (void)_executeInContext:(id)_context {
  NSMutableArray *ma;
  NSArray        *favorites;

  favorites = [[_context userDefaults]
                         arrayForKey:PROJECT_FAVORITES_UD_KEY];
  if (favorites == nil) favorites = [NSArray array];

  ma = [[NSMutableArray alloc] initWithArray:favorites];
  if ([ma containsObject:[self projectId]]) {
    [ma removeObject:[self projectId]];

    [[_context userDefaults] setObject:ma
                             forKey:PROJECT_FAVORITES_UD_KEY];
    [[_context userDefaults] synchronize];
  }
    
  [ma release];
  [self setReturnValue:[NSNumber numberWithBool:YES]];
}

@end /* LSRemoveProjectFromFavoritesCommand */


@implementation LSGetFavoriteProjectIdsCommand

- (void)_executeInContext:(id)_context {
  NSArray        *favorites;

  favorites = [[_context userDefaults]
                         arrayForKey:PROJECT_FAVORITES_UD_KEY];
  if (favorites == nil) favorites = [NSArray array];

  [self setReturnValue:favorites];
}

@end /* LSGetFavoriteProjectIds */
