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

@class NSArray, NSBundle, NSUserDefaults;

@interface LSWPreferencesViewer : LSWViewerPage 
{
@private  
  NSArray        *bundleEditors;
  id             editor;
  id             item;
  NSBundle       *editorBundle;
  NSUserDefaults *defaults;

  id category;
}

- (void)setEditor:(id)_e;
- (BOOL)isTemplateUserCond;

@end /* LSWPreferencesViewer */

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>

@implementation LSWPreferencesViewer

static BOOL DisablePasswordModification = NO;
static BOOL IsMailConfigEnabled         = NO;
static NSArray *PreferencePages = nil;

static int keySort(id o1, id o2, void *ctx) {
  NSString *key = ctx;
  
  o1 = [(NSDictionary *)o1 objectForKey:key];
  o2 = [(NSDictionary *)o2 objectForKey:key];
  return [(NSString *)o1 compare:o2];
}

+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  
  DisablePasswordModification = [ud boolForKey:@"DisablePasswordModification"];
  IsMailConfigEnabled         = [ud boolForKey:@"MailConfigEnabled"];
  
  PreferencePages = [bm providedResourcesOfType:@"PreferencePages"];
  PreferencePages = 
    [[PreferencePages sortedArrayUsingFunction:keySort context:@"name"] copy];
}

- (id)init {
  if ((self = [super init])) {
    id account;

    account = [[self session] activeAccount];

    [self registerForNotificationNamed:LSWUpdatedAccountNotificationName];
    [self takeValue:account forKey:@"object"];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->category         release];
  [self->item             release];
  [self->editorBundle     release];
  [self->editor           release];
  [self->bundleEditors    release];
  [self->defaults         release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if (![super prepareForActivationCommand:_command type:_type
              configuration:_cmdCfg])
    return NO;
  
  [self runCommand:
          @"account::teams",
          @"object",     [self object],
          @"returnType", intObj(LSDBReturnType_ManyObjects), 
          nil];
  return YES;
}

/* notifications */

- (void)awake {
  NSArray         *availablePrefs;
  NSMutableArray  *array;
  NSMutableSet    *names;
  NSEnumerator    *e;
  NSDictionary    *config;
  
  [super awake];
  
  if (self->bundleEditors)
    return;
  
  availablePrefs = PreferencePages;
  
  if ([availablePrefs count] == 0)
    return;

  array = [[NSMutableArray alloc] init];
  names = [[NSMutableSet alloc] init];

  e = [availablePrefs objectEnumerator];
  while ((config = [e nextObject])) {
    NSString *cname;
    
    cname = [config objectForKey:@"name"];
    if (cname == nil)
      continue;

    if ([names containsObject:cname])
      continue;

    [names addObject:cname];
    [array addObject:config];
  }
  [names release]; names = nil;
  self->bundleEditors = array;
}

- (void)sleep {
  [self setEditor:nil];
  [self->defaults release]; self->defaults = nil;
  [self->item     release]; self->item     = nil;
  [self->category release]; self->category = nil;
  [super sleep];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (![_cn isEqualToString:LSWUpdatedAccountNotificationName])
    return;
  if (_object == nil)
    return;

  [self runCommand:
          @"account::teams",
          @"object",     _object,
          @"returnType", intObj(LSDBReturnType_ManyObjects), 
        nil];
}

/* accessors */

- (BOOL)isRoot {
  return [[self session] activeAccountIsRoot];
}

- (BOOL)isRootViewed {
  WOSession *sn;

  sn = [self session];
  
  return [sn activeAccountIsRoot] && [[self object] isEqual:
                                                    [sn activeAccount]];
}

- (NSString *)userName {
  NSString *firstname, *userName;

  firstname = [[self object] valueForKey:@"firstname"];
  userName  = [[self object] valueForKey:@"name"];

  return (firstname == nil)
    ? userName
    : [NSString stringWithFormat:@"%@ %@", firstname, userName];
}

- (NSString *)windowTitle {
  WOSession *sn;

  sn = [self session];

  if ([sn activeAccountIsRoot] && 
      ![[self object] isEqual:[sn activeAccount]])
    return [[self labels] valueForKey:@"accountViewer"];
  
  return [[self labels] valueForKey:@"preferencesViewer"];
}

- (NSString *)boolLabelForValue:(NSString *)_value {
  return ([[[self object] valueForKey:_value] boolValue] == YES)
    ? [[self labels] valueForKey:@"YES"]
    : [[self labels] valueForKey:@"NO"];
}

- (NSString *)isLocked {
  return [self boolLabelForValue:@"isLocked"];
}

- (NSString *)isTemplateUser {
  return [self boolLabelForValue:@"isTemplateUser"];
}

- (BOOL)canChangePassword {
  if (DisablePasswordModification)
    return NO;
  
  if ([[[self object] valueForKey:@"isTemplateUser"] boolValue])
    return NO;

  return YES;
}

- (BOOL)canMakePerson {
  // can account be changed to person?
  // not root-account
  if ([[[self object] valueForKey:@"companyId"] intValue] == 10000) return NO;
  // but only by root
  if ([self isTemplateUserCond])
      return NO;
  
  return [[self session] activeAccountIsRoot];
}

/* bundle editors */

- (NSArray *)editors {
  return self->bundleEditors;
}

- (BOOL)hasEditors {
  return [[self editors] count] > 0 ? YES : NO;
}

- (BOOL)hasEdit {
  id am;
  
  am = [[(id)[self session] commandContext] accessManager];
  return [am operation:@"w" allowedOnObjectID:[[self object] globalID]];
}

- (void)setEditor:(id)_e {
  ASSIGN(self->editor, _e);
  [self->editorBundle release]; self->editorBundle = nil;
}

- (id)editor {
  return self->editor;
}

- (NSBundle *)editorBundle {
  if (self->editorBundle == nil) {
    self->editorBundle =
      [[[NGBundleManager defaultBundleManager]
                         bundleProvidingResource:
                           [(NSDictionary *)[self editor] objectForKey:@"name"]
                         ofType:@"PreferencePages"] retain];
  }
  return self->editorBundle;
}

- (NSString *)editorLabel {
  /* to be improved .. (use localized label) */
  return [[self labels] valueForKey:
                          [(NSDictionary *)[self editor] 
                                           objectForKey:@"labelKey"]];
}

- (BOOL)hasIcon {
  return [(NSDictionary *)[self editor] objectForKey:@"icon"] ? YES : NO;
}
- (NSString *)editorIcon {
  return [(NSDictionary *)[self editor] objectForKey:@"icon"];
}

/* accessors */

- (void)setItem:(id)_i {
  ASSIGN(self->item, _i);
}
- (id)item {
  return self->item;
}

- (void)setCategory:(id)_i {
  ASSIGN(self->category, _i);
}
- (id)category {
  return self->category;
}

- (BOOL)isTemplateUserCond {
  return [[[self object] valueForKey:@"isTemplateUser"] boolValue];
}

- (BOOL)showAccountLogs {
  if (![[[self session] userDefaults] boolForKey:@"SkyLogAccounts"])
    return NO;
  return [self isRoot];
}

- (NSUserDefaults *)defaults {
  if (self->defaults != nil)
    return self->defaults;
  
  if ([[self session] activeAccountIsRoot]) {
    self->defaults = [[self runCommand:@"userdefaults::get", @"user",
                              [self object], nil] retain];
  }
  else 
    self->defaults = [[[self session] userDefaults] retain];
  
  return self->defaults;
}

- (BOOL)isMailConfigEnabled {
  return IsMailConfigEnabled;
}

/* actions */

- (id)accountToPerson {
  [self runCommand:@"account::toPerson", @"object", [self object], nil];
  [self postChange:LSWDeletedAccountNotificationName
        onObject:[self object]];
  return [[[self session] navigation] leavePage];
}

- (id)showEditor {
  id editorPage;
  
  editorPage = [(NSDictionary *)[self editor] objectForKey:@"component"];
  if (![editorPage isNotEmpty]) {
    [self logWithFormat:
            @"missing 'component' config for preference-page %@",
            [self editor]];
    return nil;
  }
  
  if ((editorPage = [self pageWithName:editorPage]) == nil) {
    [self logWithFormat:
            @"couldn't instantiate preference-page %@",
            [(NSDictionary *)[self editor] objectForKey:@"component"]];
    return nil;
  }
  
  /* put account into pasteboard */
  [[self session] transferObject:[self object] owner:self];

  [editorPage takeValue:[self object] forKey:@"account"];
  return editorPage;
}

/*
  Note: does not work because there are two viewers for eo/person:
        PersonViewer and AccountViewer(PreferencesViewer)
*/
- (id)viewPerson {
  return [self activateObject:[self object] withVerb:@"view"];
}

- (id)viewAccountLogs {
  return [self activateObject:[self object] withVerb:@"viewAccountLogs"];
}

- (id)viewItem {
  /* this is used by the object-editor to view a team! */
  return [self activateObject:[self item] withVerb:@"view"];
}

- (id)editPassword {
  return [self activateObject:[self object] withVerb:@"editAccountPassword"];
}
- (id)edit {
  return [self activateObject:[self object] withVerb:@"editPreferences"];
}

@end /* LSWPreferencesViewer */
