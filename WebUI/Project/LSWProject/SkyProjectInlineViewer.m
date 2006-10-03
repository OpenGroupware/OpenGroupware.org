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

@class NSArray, NSDictionary;

@interface SkyProjectInlineViewer : OGoComponent
{
  id  project;
  
  /* temporary */
  id   item;
  BOOL reload;
  BOOL showClip;
  BOOL showSend;
  NSArray      *publicExtendedProjectAttributes;
  NSArray      *privateExtendedProjectAttributes;
  NSDictionary *props;
  NSDictionary *currentAttr;
}
@end

#include "common.h"

@interface SkyProjectInlineViewer(PrivateMethods)
- (SkyObjectPropertyManager *)propertyManager;
- (void)_setExtAttributes;
@end

@implementation SkyProjectInlineViewer

- (id)init {
  if ((self = [super init])) {
    self->showSend = YES;
    self->showClip = YES;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->project);
  RELEASE(self->item);
  RELEASE(self->publicExtendedProjectAttributes);
  RELEASE(self->privateExtendedProjectAttributes);
  RELEASE(self->props);
  RELEASE(self->currentAttr);
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (NSArray *)privateProjectAttributeInfos {
  return [[self userDefaults] 
	        arrayForKey:@"SkyPrivateExtendedProjectAttributes"];
}
- (NSArray *)publicExtendedAttributeInfos {
  return [[self userDefaults] 
	        arrayForKey:@"SkyPublicExtendedProjectAttributes"];
}

/* notifications */

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

- (void)reload {
  NSDictionary *oprops;
  
  if (!self->reload)
    return;

  [self runCommand:@"project::get-persons", @"object", self->project, nil];
  [self runCommand:@"project::get-enterprises",
          @"object", self->project, nil];
  [self runCommand:@"project::get-accounts", @"object", self->project, nil];
  [self runCommand:@"project::get-teams", @"object", self->project, nil];
      
  [self runCommand:@"project::get-comment",
          @"object", self->project,
          @"relationKey", @"comment", nil];
    
  oprops = [[self propertyManager] propertiesForGlobalID:
				     [self->project globalID]];
  ASSIGN(self->props, oprops);
  [self _setExtAttributes];
  self->reload = NO;
}

- (void)_setExtAttributes {
  NSArray        *extAttrs;
  NSMutableArray *a;
  NSString       *key      = nil;
  NSString       *propKey  = @"{http://www.skyrix.com/namespaces/project}";
  int            i, cnt;

  extAttrs = [self publicExtendedAttributeInfos];
  a = [[NSMutableArray alloc] init];
      
  for (i = 0, cnt = [extAttrs count]; i < cnt; i++) {
    NSMutableDictionary *ea;
    NSMutableDictionary *e;
        
    e   = [extAttrs objectAtIndex:i];
    key = [propKey stringByAppendingString:[e valueForKey:@"key"]];
    ea  = [[NSMutableDictionary alloc] initWithCapacity:4];
    [ea takeValuesFromDictionary:e];
    [ea takeValue:key forKey:@"key"];
    [a addObject:ea];
    [ea release]; ea  = nil;
  }
  self->publicExtendedProjectAttributes = [a copy];
  
  extAttrs = [self privateProjectAttributeInfos];
  [a removeAllObjects];
  
  for (i = 0, cnt = [extAttrs count]; i < cnt; i++) {
    NSMutableDictionary *ea;
    NSMutableDictionary *e;
    NSString       *key;

    e   = [extAttrs objectAtIndex:i];
    key = [propKey stringByAppendingString:[e valueForKey:@"key"]];
    ea  = [[NSMutableDictionary alloc] initWithCapacity:4];
    [ea takeValuesFromDictionary:e];
    [ea takeValue:key forKey:@"key"];
    [ea takeValue:[NSNumber numberWithBool:YES] forKey:@"isPrivate"];
    [a addObject:ea];
    [ea release];
  }
  self->privateExtendedProjectAttributes = [a copy];
  [a release];
}

- (void)awake {
  [super awake];
  [self reload];
}

/* accessors */

- (void)setProject:(id)_project {
  if (self->project != _project) {
    ASSIGN(self->project, _project);
    self->reload = YES;
    [self reload];
  }
}
- (id)project {
  return self->project;
}

- (BOOL)isEditDisabled {
  SkyAccessManager *accessManager;
  
  accessManager = [[(id)[self session] commandContext] accessManager];
  return ![accessManager operation:@"m"
                         allowedOnObjectID:[[self project] globalID]];
}
- (BOOL)isEditEnabled {
  return [self isEditDisabled] ? NO : YES;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (BOOL)itemIsArchived {
  return [[[self item] valueForKey:@"dbStatus"] isEqual:@"archived"];
}
- (BOOL)itemIsViewable {
  LSCommandContext *ctx;
  SkyAccessManager *am;
  EOGlobalID       *gid;
  
  ctx = [[self session] commandContext];
  am  = [ctx accessManager];
  gid = [[self item] valueForKey:@"globalID"];
  return [am operation:@"r" allowedOnObjectID:gid];
}

- (NSArray *)accounts {
  return [[self project] valueForKey:@"accounts"];
}
- (NSArray *)teams {
  return [[self project] valueForKey:@"teams"];
}
- (NSArray *)persons {
  return [[self project] valueForKey:@"persons"];
}
- (NSArray *)enterprises {
  return [[self project] valueForKey:@"enterprises"];
}

- (BOOL)hasAccessTeam {
  return ([[self project] valueForKey:@"teamId"] == nil) ? NO : YES;
}


- (NSArray *)publicExtendedProjectAttributes {
  return self->publicExtendedProjectAttributes;
}

- (NSArray *)privateExtendedProjectAttributes {
  return self->privateExtendedProjectAttributes;
}

- (NSDictionary *)props {
  return self->props;
}

- (void)setCurrentAttr:(NSDictionary *)_obj {
  ASSIGN(self->currentAttr, _obj);
}

- (NSDictionary *)currentAttr {
  return self->currentAttr;
}

- (NSString *)_currentAttrKey {
  NSString *key;
  NSRange  r;
  
  key = [self->currentAttr valueForKey:@"key"];
  if (![(NSString *)key hasPrefix:@"{"])
    return key;
  
  r = [key rangeOfString:@"}"];
  if (r.length == 0)
    return key;
  
  return [key substringFromIndex:(r.location + r.length)];
}
- (NSString *)_currentAttrLabel {
  return [self->currentAttr valueForKey:@"label"];
}

- (NSString *)currentAttrLabel {
  NSString *ret;
  NSArray  *ak;
  id       labels;

  labels = [self labels];
  
  ak  = [self->currentAttr allKeys];
  ret = [ak containsObject:@"label"]
    ? [labels valueForKey:[self _currentAttrLabel]]
    : [labels valueForKey:[self _currentAttrKey]];
  
  if ([[self->currentAttr valueForKey:@"isPrivate"] boolValue]) {
    NSString *p;
    
    p = [labels valueForKey:@"private"];
    if (p == nil) p = @"private";
    ret = [ret stringByAppendingFormat:@" (%@)", p];
  }
  return (ret == nil) ? [self _currentAttrKey] : ret;
}

- (NSString *)privateLabel {
  NSString *l;

  l = [[self labels] valueForKey:@"private"];
  return (l != nil) ? l : (NSString *)@"private";
}

/* actions */

- (id)_activateObject:(id)_obj withVerb:(NSString *)_verb {
  return [[[self session] navigation] activateObject:_obj withVerb:_verb];
}
- (id)_viewObject:(id)_obj {
  return [self _activateObject:_obj withVerb:@"view"];
}

- (id)viewItem {
  return [self _viewObject:[self item]];
}
- (id)viewTeam {
  return [self _viewObject:[[self project] valueForKey:@"team"]];
}
- (id)viewOwner {
  return [self _viewObject:[[self project] valueForKey:@"owner"]];
}

- (id)placeInClipboard {
  [[self session] placeInClipboard:[self project]];
  return nil;
}

- (id)edit {
  self->reload = YES;
  return [self _activateObject:[self project] withVerb:@"edit"];
}
- (id)mailObject {
  return [self _activateObject:[self project] withVerb:@"mail"];
}

- (BOOL)showClip {
  return self->showClip;
}
- (BOOL)showSend {
  return self->showSend;
}

- (void)setShowClip:(BOOL)_b {
  self->showClip = _b;
}
- (void)setShowSend:(BOOL)_b {
  self->showSend = _b;
}

- (SkyObjectPropertyManager *)propertyManager {
  return [[(OGoSession *)[self session] commandContext] propertyManager];
}

- (BOOL)showProjectURL {
  NSString *url;
  
  if (![[self session] activeAccountIsRoot])
    return NO;
  
  if ([(url = [self->project valueForKey:@"url"]) isNotNull])
    return [url hasPrefix:@"file:"];
  
  return NO;
}

@end /* SkyProjectInlineViewer */
