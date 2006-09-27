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

#include <OGoFoundation/OGoComponent.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoJobs/SkyJobDocument.h>
#include "common.h"

@interface SkyPersonalAttributesViewer : OGoComponent
{
  NSArray        *patterns;
  unsigned int   patternIndex;
  id             item;
  id             object;
  BOOL           viewerConfigMode;
  NSUserDefaults *defaults;
}
@end /* SkyPersonalAttributesViewer */

@interface WOComponent(EditPageWithPattern)
- (void)setPatternName:(NSString *)_name;
@end

@implementation SkyPersonalAttributesViewer

- (id)init {
  if ((self = [super init])) {
    self->viewerConfigMode = NO;
    self->defaults = nil;
  }
  return self;
}

- (void)dealloc {
  [self->item     release];
  [self->patterns release];
  [self->defaults release];
  [self->object   release];
  [super dealloc];
}

- (NSUserDefaults *)defaults {
  if (self->defaults == nil)
    self->defaults = [[[self session] userDefaults] retain];
  return self->defaults;
}

- (NSString *)_entityName {
  id o;

  o = self->object;

  if ([o isKindOfClass:[SkyPersonDocument class]])
    return @"Person";
  else if ([o isKindOfClass:[SkyEnterpriseDocument class]])
    return @"Enterprise";
  else if ([o isKindOfClass:[SkyJobDocument class]])
    return @"Job";
  else if ([o respondsToSelector:@selector(entityName)])
    return [o entityName];
  else
    return nil;
}

- (void)_fetchPatterns {
  NSDictionary *allCfg;
  NSArray      *tmp;
  NSString     *key;

  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"s_view_attributes"];

  allCfg = [[self defaults] dictionaryForKey:key];

  if (allCfg != nil && [[allCfg allKeys] count] > 0) {
    RELEASE(self->patterns); self->patterns = nil;
    tmp = [[allCfg allKeys] copy];
    self->patterns =
      [tmp sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    RETAIN(self->patterns);
    RELEASE(tmp);
  }
  else {
    tmp = [NSArray arrayWithObject:[[self labels] valueForKey:@"newPattern"]];
    self->patterns = RETAIN(tmp);
  }
}

// accessors

- (NSArray *)patterns {
  return self->patterns;
}

- (BOOL)hasPatterns {
  return ([self->patterns count] > 0 ? YES : NO);
}

- (void)setPatternIndex:(unsigned int)_ind {
  self->patternIndex = _ind;
}
- (unsigned int)patternIndex {
  return self->patternIndex;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}
- (id)currentPattern {
  return self->item;
}

- (NSArray *)patternValues {
  NSDictionary *allCfg = nil;
  NSString     *key;

  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"s_view_attributes"];
  
  allCfg = [[self defaults] dictionaryForKey:key];

  if (allCfg != nil) {
    return [[[allCfg objectForKey:self->item] copy] autorelease];
  }
  return [NSArray array];
}

- (void)setViewerConfigMode:(BOOL)_b {
  self->viewerConfigMode = _b;
}
- (BOOL)viewerConfigMode {
  return self->viewerConfigMode;
}

- (void)setPatternVisibility:(BOOL)_flag {
  NSString *key;
  NSUserDefaults *ud;

  ud = [self defaults];

  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"_viewer_expand_"];
  key = [key stringByAppendingString:self->item];

  [ud setObject:[NSNumber numberWithBool:_flag] forKey:key];
  [ud synchronize];
}

- (BOOL)patternVisibility {
  NSString *key;

  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"_viewer_expand_"];
  key = [key stringByAppendingString:self->item];
  
  return [[[self defaults] objectForKey:key] boolValue];
}

- (int)maxColumns {
  int c;

  c = [[[self session] userDefaults] integerForKey:@"attributes_no_of_cols"];
  return ([self->patterns count] <= c) ? [self->patterns count] : c;
}

- (void)setObject:(id)_obj {
  ASSIGN(self->object, _obj);
}
- (id)object {
  return self->object;
}

/* actions */

- (id)viewerConfigModeActivate {
  self->viewerConfigMode = YES;
  return nil;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self _fetchPatterns];
  [super appendToResponse:_response inContext:_ctx];
}

- (id)edit {
  id editPage;

  editPage = [self activateObject:[self object] withVerb:@"editAttributes"];
  [editPage setPatternName:[self item]];
  return editPage;
}

- (BOOL)isEditAllowed {
  return [[[[self session] valueForKey:@"commandContext"] accessManager]
                  operation:@"w" allowedOnObjectID:
                  [[self object] valueForKey:@"globalID"]];
}

@end /* SkyPersonalAttributesViewer */
