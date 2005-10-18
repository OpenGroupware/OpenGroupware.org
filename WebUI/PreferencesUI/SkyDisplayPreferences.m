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

#include <OGoFoundation/LSWContentPage.h>

@class NSDictionary, NSUserDefaults, NSArray, NSMutableArray;

@interface SkyDisplayPreferences : LSWContentPage
{
  id             account;
  id             item;
  NSUserDefaults *defaults;
  BOOL           isRoot;
  NSDictionary   *availableDockablePages;

  /* values */
  NSArray        *dockablePages;
  NSMutableArray *dockedPages;
  NSMutableArray *undockedPages;
  
  BOOL           defaultButtonsLeft;
  BOOL           hideInactiveButtons;
  BOOL           buttonTextMode;
  BOOL           dockTextMode;
  BOOL           dockShowDesktop;
  int            maxClipCount;
  int            maxNavLabelLength;
  NSString       *language;
  NSString       *theme;
  NSString       *timezone;
  BOOL           showAMPMDates;

  /* access */
  BOOL           isDockablePagesEditable;
  BOOL           isDockShowDesktopEditable;
  BOOL           isLanguageEditable;
  BOOL           isTimezoneEditable;
}

- (void)setItem:(id)_item;
- (id)item;

- (void)setLanguageAndTheme:(NSString *)_splitMe;

@end /* SkyDisplayPreferences */

#include <OGoFoundation/LSWNotifications.h>
#include "common.h"

@implementation SkyDisplayPreferences

static NSArray         *allDockablePages = nil;
static NGBundleManager *bm = nil;
static NSNumber *YesNumber = nil;
static NSNumber *NoNumber  = nil;

+ (void)initialize {
  bm = [[NGBundleManager defaultBundleManager] retain];
  allDockablePages = [[bm providedResourcesOfType:@"DockablePages"] copy];
  
  YesNumber = [[NSNumber numberWithBool:YES] retain];
  NoNumber  = [[NSNumber numberWithBool:NO] retain];
}

- (void)_processDockablePages:(NSArray *)tmp 
  includeRootPages:(BOOL)isRootAccount
  onlyExtraAccountPages:(BOOL)isExtraAccount
{
  NSMutableDictionary *dict;
  NSMutableSet        *uniquer;
  int                 count, i;

  count   = [tmp count];
  dict    = [NSMutableDictionary dictionaryWithCapacity:count];
  uniquer = [NSMutableSet setWithCapacity:count];

  for (i = 0; i < [tmp count]; i++) {
    NSDictionary *cfgEntry;
    NSBundle     *bundle;
    NSString     *componentName, *label, *icon, *pageName;;

    cfgEntry = [tmp objectAtIndex:i];
    pageName = [cfgEntry objectForKey:@"name"];

    if (pageName == nil) {
      [self logWithFormat:@"missing pagename in bundle config %@", cfgEntry];
      continue;
    }

    if ([uniquer containsObject:pageName])
      /* already found a bundle providing that resource */
      continue;

    [uniquer addObject:pageName];
        
    bundle = [bm bundleProvidingResource:pageName ofType:@"DockablePages"];
    if (bundle == nil) {
      [self logWithFormat:@"did not find dockable page %@", pageName];
      continue;
    }

    /* refetch config entry, so that it is the right one .. */

    cfgEntry = [bundle configForResource:pageName ofType:@"DockablePages"];
    if (cfgEntry == nil) {
      [self logWithFormat:@"missing configuration of dockable page %@",
	      pageName];
      continue;
    }
    componentName = [cfgEntry objectForKey:@"component"];
    label         = [cfgEntry objectForKey:@"labelKey"];
    icon          = [cfgEntry objectForKey:@"listicon"];

    /* check whether page is visible for root only */

    if ([[cfgEntry objectForKey:@"onlyRoot"] boolValue]) {
      if (!isRootAccount)
	continue;
    }

    /* check whether the page is visible for extra accounts */
    
    if (componentName == nil) {
      [self logWithFormat:@"missing component-name of page %@", pageName];
      continue;
    }
    /* ok, add to configurable pages */
    {
      NSDictionary *entry;

      if (label == nil) label = pageName;
      if (icon  == nil) icon  = @"icon_preferences_26x21.gif";

      entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                  pageName,      @"name",
                                  label,         @"labelKey",
                                  bundle,        @"bundle",
                                  componentName, @"componentName",
                                  icon,          @"listicon",
			    nil];
      [dict setObject:entry forKey:pageName];
    }
  }
  self->availableDockablePages = [dict copy];
}

- (id)init {
  if ((self = [super init]) != nil) {
    NSArray *tmp;
    
    if ([(tmp = allDockablePages) isNotEmpty]) {
      [self _processDockablePages:tmp 
            includeRootPages:[[self session] activeAccountIsRoot]
            onlyExtraAccountPages:NO];
    }
  }
  return self;
}

- (void)dealloc {
  [self->dockedPages            release];
  [self->undockedPages          release];
  [self->availableDockablePages release];;
  [self->dockablePages          release];
  [self->item                   release];
  [self->account                release];
  [self->defaults               release];
  [self->language               release];
  [self->theme                  release];
  [self->timezone               release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
  [self setItem:nil];
  [super sleep];
}

- (void)postDockReloadNotification {
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"SkyDockReload"
                         object:self->defaults];
}
- (void)postAccountChanged:(id)_accountEO {
  [self postChange:LSWUpdatedAccountNotificationName onObject:_accountEO];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

- (BOOL)isRoot {
  return self->isRoot;
}

- (BOOL)_isEditable:(NSString *)_defName {
  id obj;

  _defName = [@"rootAccess" stringByAppendingString:_defName];
  obj      = [self->defaults objectForKey:_defName];

  return obj ? [obj boolValue] : YES;
}

- (void)resetAccountCaches {
  [self->dockablePages release]; self->dockablePages = nil;
  [self->dockedPages   release]; self->dockedPages   = nil;
  [self->undockedPages release]; self->undockedPages = nil;
  [self->language      release]; self->language      = nil;
  [self->theme         release]; self->theme         = nil;
  [self->timezone      release]; self->timezone      = nil;
}

- (void)loadDefaults:(NSUserDefaults *)_ud {
  self->dockablePages = [[_ud arrayForKey:@"SkyDockablePagesOrdering"] copy];
  
  self->defaultButtonsLeft =
    [[_ud objectForKey:@"SkyButtonRowDefaultButtonsLeft"] boolValue];
  self->hideInactiveButtons =
    [[_ud objectForKey:@"SkyButtonRowHideInactiveButtons"] boolValue];
  self->buttonTextMode = [[_ud objectForKey:@"SkyButtonTextMode"] boolValue];

  self->maxClipCount = [[_ud objectForKey:@"SkyMaxFavoritesCount"] intValue];
  self->maxNavLabelLength = 
    [[_ud objectForKey:@"SkyMaxNavLabelLength"] intValue];
  
  [self setLanguageAndTheme:[_ud stringForKey:@"language"]];
  self->timezone      = [[_ud stringForKey:@"timezone"] copy];
  self->showAMPMDates = [[_ud objectForKey:@"scheduler_AMPM_dates"] boolValue];
  
  self->dockTextMode    = [[_ud objectForKey:@"SkyDockTextMode"]    boolValue];
  self->dockShowDesktop = [[_ud objectForKey:@"SkyDockShowDesktop"] boolValue];
  
  self->isDockablePagesEditable =
    [self _isEditable:@"SkyDockablePagesOrdering"];
  self->isDockShowDesktopEditable   = [self _isEditable:@"SkyDockShowDesktop"];
  self->isLanguageEditable = [self _isEditable:@"language"];
  self->isTimezoneEditable = [self _isEditable:@"timezone"];
}

- (void)loadDockedPagesDefaults:(NSUserDefaults *)_ud {
  NSEnumerator *e;
  NSDictionary *entry;
  NSMutableSet *uniquer;
  
  self->dockedPages   = [[NSMutableArray alloc] initWithCapacity:16];
  self->undockedPages = [[NSMutableArray alloc] initWithCapacity:16];

  uniquer = [NSMutableSet setWithCapacity:32];

  e = [self->dockablePages objectEnumerator];
  while ((entry = [e nextObject])) {
    NSDictionary *cfg;

    if ((cfg = [self->availableDockablePages objectForKey:entry]) == nil)
      continue;

    [self->dockedPages addObject:cfg];
    [uniquer addObject:entry];
  }
    
  e = [self->availableDockablePages objectEnumerator];
  while ((entry = [e nextObject])) {
    NSString *pageName;

    if ((pageName = [entry objectForKey:@"name"]) == nil)
      continue;
    if ([uniquer containsObject:pageName])
      continue;
    
    [self->undockedPages addObject:entry];
    [uniquer addObject:pageName];
  }
}

- (void)setAccount:(id)_account {
  NSUserDefaults *tmp;
  
  [self resetAccountCaches];
  ASSIGN(self->account, _account);
  
  tmp = self->defaults;
  self->defaults = (_account != nil)
    ? [self runCommand:@"userdefaults::get", @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];
  
  self->defaults = [self->defaults retain];
  
  [tmp release]; tmp = nil;
  
  [self loadDefaults:self->defaults];
  [self loadDockedPagesDefaults:self->defaults];
}
- (id)account {
  return self->account;
}
- (NSNumber *)accountId {
  return [[self account] valueForKey:@"companyId"];
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemLabel {
  return [[self labels] valueForKey:[self item]];
}

- (NSArray *)timeZoneNames {
  return ([self->defaults arrayForKey:@"LSTimeZones"]);
}

/* access */

- (BOOL)isDockablePagesEditable {
  return self->isRoot || self->isDockablePagesEditable;
}
- (BOOL)isDefaultButtonsLeftEditable {
  return self->isRoot || [self _isEditable:@"SkyButtonRowDefaultButtonsLeft"];
}
- (BOOL)isHideInactiveButtonsEditable {
  return self->isRoot || [self _isEditable:@"SkyButtonRowHideInactiveButtons"];
}
- (BOOL)isButtonTextModeEditable {
  return self->isRoot || [self _isEditable:@"SkyButtonTextMode"];
}

- (BOOL)isMaxClipCountEditable {
  return self->isRoot || [self _isEditable:@"SkyMaxFavoritesCount"];
}

- (BOOL)isDockTextModeEditable {
  return self->isRoot || [self _isEditable:@"SkyDockTextMode"];
}
- (BOOL)isDockShowDesktopEditable {
  return self->isRoot || self->isDockShowDesktopEditable;
}
- (BOOL)isLanguageEditable {
  return self->isRoot || self->isLanguageEditable;
}
- (BOOL)isThemeEditable {
  return [self isLanguageEditable]; // TODO: decouple?
}
- (BOOL)isTimezoneEditable {
  return self->isRoot || self->isTimezoneEditable;
}

/* root access */

- (void)setIsDockablePagesEditableRoot:(BOOL)_flag {
  self->isDockablePagesEditable = _flag;
}
- (BOOL)isDockablePagesEditableRoot {
  return self->isDockablePagesEditable;
}

- (void)setIsDockShowDesktopEditableRoot:(BOOL)_flag {
  self->isDockShowDesktopEditable = _flag;
}
- (BOOL)isDockShowDesktopEditableRoot {
  return self->isDockShowDesktopEditable;
}

- (void)setIsLanguageEditableRoot:(BOOL)_flag {
  self->isLanguageEditable = _flag;
}
- (BOOL)isLanguageEditableRoot {
  return self->isLanguageEditable;
}

- (void)setIsTimezoneEditableRoot:(BOOL)_flag {
  self->isTimezoneEditable = _flag;
}
- (BOOL)isTimezoneEditableRoot {
  return self->isTimezoneEditable;
}

- (NSArray *)languages {
  // TODO: this is not correct?! the session languages only contain the
  //       active languages, not all?
  //       probably this is the "SkyLanguages" default (see OGoSession.m)
  return [(WOSession *)[self session] languages];
}
- (NSArray *)languagePartsGetTheme:(BOOL)_getTheme {
  NSMutableArray *ma;
  NSEnumerator   *e;
  NSString       *ls;
  
  ma = [NSMutableArray arrayWithCapacity:16];
  e = [[self languages] objectEnumerator];
  while ((ls = [e nextObject])) {
    NSRange r;
    
    r = [ls rangeOfString:@"_"];
    if (r.length > 0) {
      ls = _getTheme
	? [ls substringFromIndex:r.location + r.length]
	: [ls substringToIndex:r.location];
    }
    else if (_getTheme)
      ls = @"default";
    
    if ([ma containsObject:ls])
      continue;
    [ma addObject:ls];
  }
  [ma sortUsingSelector:@selector(compare:)];
  return ma;
}
- (NSArray *)rawLanguages {
  return [self languagePartsGetTheme:NO];
}
- (NSArray *)themes {
  return [self languagePartsGetTheme:YES];
}

/* dockable pages */

- (NSString *)dockItemLabel {
  NSString     *tmp, *tableName, *s;
  NSDictionary *di;

  if ((di = [self item]) == nil)
    return nil;
  
  tableName = [[di objectForKey:@"bundle"] bundleName];
    
  if (tableName == nil)
    tableName = [[NGBundle bundleForClass:[self class]] bundleName];
    
  tmp = [di objectForKey:@"labelKey"];
  if (tmp == nil) tmp = [di objectForKey:@"name"];
  if (tmp == nil) tmp = [di objectForKey:@"componentName"];

  if (tmp == nil)
    return nil;
  
  s = [[[self application] resourceManager]
               stringForKey:tmp inTableNamed:tableName
               withDefaultValue:nil
               languages:[(WOSession *)[self session] languages]];
  return s != nil ? s : tmp;
}

- (id)showDockPage {
  OGoNavigation *nav;
  id page;

  page = [(NSDictionary *)[self item] objectForKey:@"componentName"];
  if (page != nil)
    page = [self pageWithName:page];
  
  if (page == nil)
    return nil;
  
  // TODO: can we save the stuff below and just return the component?
  nav = [[self session] navigation];
  [nav leavePage];
  [nav enterPage:page];
  return page;
}

- (NSDictionary *)availableDockablePages {
  return self->availableDockablePages;
}

- (NSArray *)dockablePages {
  return self->dockablePages;
}

- (NSArray *)dockedPages {
  return self->dockedPages;
}
- (NSArray *)undockedPages {
  return self->undockedPages;
}

- (id)addPageAtTop {
  unsigned int idx;
  id           page;

  page = [[[self item] retain] autorelease];
  idx  = [self->undockedPages indexOfObjectIdenticalTo:page];
  
  if (idx == NSNotFound) {
    [self logWithFormat:@"missing dock page %@", page];
    return nil;
  }
  [self->undockedPages removeObjectAtIndex:idx];
  [self->dockedPages   insertObject:page atIndex:0];
  
  return nil;
}
- (id)addPageAtBottom {
  unsigned int idx;
  id           page;

  page = [[[self item] retain] autorelease];
  idx   = [self->undockedPages indexOfObjectIdenticalTo:page];
  
  if (idx == NSNotFound) {
    [self logWithFormat:@"missing dock page %@", page];
    return nil;
  }
  [self->undockedPages removeObjectAtIndex:idx];
  [self->dockedPages   addObject:page];
  return nil;
}

- (id)movePageUp {
  unsigned int idx;
  id           page;

  page = [[[self item] retain] autorelease];
  idx  = [self->dockedPages indexOfObjectIdenticalTo:page];
  
  if (idx == NSNotFound) {
    [self logWithFormat:@"missing dock page %@", page];
    return nil;
  }
  if (idx == 0)
    /* top page */
    return nil;

  [self->dockedPages removeObjectAtIndex:idx];
  [self->dockedPages insertObject:page atIndex:(idx - 1)];
  
  return nil;
}
- (id)movePageDown {
  unsigned int idx, cnt;
  id           page;

  page = [[[self item] retain] autorelease];
  idx  = [self->dockedPages indexOfObjectIdenticalTo:page];
  
  if (idx == NSNotFound) {
    [self logWithFormat:@"missing dock page %@", page];
    return nil;
  }
  cnt = [self->dockedPages count];

  if (idx == cnt - 1) {
    /* last page */
    return nil;
  }
  [self->dockedPages removeObjectAtIndex:idx];
  [self->dockedPages insertObject:page atIndex:(idx + 1)];
  
  return nil;
}
- (id)removeDockPage {
  unsigned int idx;
  id           page;

  page = [[[self item] retain] autorelease];
  idx  = [self->dockedPages indexOfObjectIdenticalTo:page];
  
  if (idx == NSNotFound) {
    [self logWithFormat:@"missing dock page %@", page];
    return nil;
  }
  [self->dockedPages removeObjectAtIndex:idx];
  [self->undockedPages addObject:page];
  return nil;
}

/* values */

- (void)setMaxClipCount:(int)_count {
  if (_count < 1)  _count = 1;
  if (_count > 20) _count = 20;
  self->maxClipCount = _count;
}
- (int)maxClipCount {
  return self->maxClipCount;
}
- (void)setMaxNavLabelLength:(int)_count {
  if (_count < 10)  _count = 10;
  if (_count > 200) _count = 200;
  self->maxNavLabelLength = _count;
}
- (int)maxNavLabelLength {
  return self->maxNavLabelLength;
}

- (void)setDefaultButtonsLeft:(BOOL)_value {
  self->defaultButtonsLeft = _value;
}
- (BOOL)defaultButtonsLeft {
  return self->defaultButtonsLeft;
}

- (void)setHideInactiveButtons:(BOOL)_value {
  self->hideInactiveButtons = _value;
}
- (BOOL)hideInactiveButtons {
  return self->hideInactiveButtons;
}

- (void)setButtonTextMode:(BOOL)_value {
  self->buttonTextMode = _value;
}
- (BOOL)buttonTextMode {
  return self->buttonTextMode;
}

- (void)setDockTextMode:(BOOL)_value {
  self->dockTextMode = _value;
}
- (BOOL)dockTextMode {
  return self->dockTextMode;
}

- (void)setDockShowDesktop:(BOOL)_value {
  self->dockShowDesktop = _value;
}
- (BOOL)dockShowDesktop {
  return self->dockShowDesktop;
}

- (void)setLanguage:(NSString *)_value {
  ASSIGNCOPY(self->language,_value);
}
- (NSString *)language {
  return self->language;
}
- (void)setTheme:(NSString *)_value {
  ASSIGNCOPY(self->theme,_value);
}
- (NSString *)theme {
  return self->theme;
}
- (void)setLanguageAndTheme:(NSString *)_splitMe {
  NSRange  r;
  NSString *l, *t;
  
  r = [_splitMe rangeOfString:@"_"];
  if (r.length > 0) {
    l = [_splitMe substringToIndex:r.location];
    t = [_splitMe substringFromIndex:(r.location + r.length)];
  }
  else {
    l = _splitMe;
    t = nil;
  }
  [self setLanguage:[l isNotEmpty] ? l : @"English"];
  [self setTheme:   [t isNotEmpty] ? t : @"default"];
}
- (NSString *)languageAndTheme {
  /* join lang and theme, eg "English_blue" as required by OGo internally */
  NSString *t, *l;
  
  t = [self theme];
  l = [self language];
  if ([t isEqualToString:@"default"]) t = nil;
  if (![l isNotEmpty]) l = @"English";
  if ([t isNotEmpty])
    l = [[l stringByAppendingString:@"_"] stringByAppendingString:t];
  return l;
}

- (BOOL)isTimeZoneEnabled {
  // TODO: deprecated
  return YES;
}

- (void)setTimezone:(NSString *)_value {
  ASSIGNCOPY(self->timezone,_value);  
}
- (NSString *)timezone {
  return self->timezone;
}

- (void)setShowAMPMDates:(BOOL)_flag {
  self->showAMPMDates = _flag;
}
- (BOOL)showAMPMDates {
  return self->showAMPMDates;
}

/* default writes */

- (void)_writeDefault:(NSString *)_key value:(id)_value {
  [self runCommand:@"userdefaults::write",
	  @"key",      _key,
          @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   [self accountId],
	nil];
}
- (void)_writeDefault:(NSString *)_key boolValue:(BOOL)_value {
  [self _writeDefault:_key value:_value ? YesNumber : NoNumber];
}

- (void)_writeRootDefault:(NSString *)_key boolValue:(BOOL)_value {
  _key = [@"rootAccess" stringByAppendingString:_key];
  [self _writeDefault:_key value:_value ? YesNumber : NoNumber];
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)save {
  NSNumber *uid;
  BOOL     reloadDock;
  
  reloadDock = NO;
  uid        = [self accountId];
  
  if ([self isDockablePagesEditable]) {
    NSMutableArray *array;
    NSEnumerator   *e;
    NSDictionary   *entry;

    array = [NSMutableArray arrayWithCapacity:16];
    
    e = [self->dockedPages objectEnumerator];
    while ((entry = [e nextObject]) != nil) {
      NSString *pageName;
      
      if ((pageName = [entry objectForKey:@"name"]) == nil)
        continue;
      
      [array addObject:pageName];
    }
    reloadDock = YES;

    [self _writeDefault:@"SkyDockablePagesOrdering" value:array];
  }
  if ([self isDefaultButtonsLeftEditable]) {
    [self _writeDefault:@"SkyButtonRowDefaultButtonsLeft" 
	  boolValue:self->defaultButtonsLeft];
  }
  if ([self isHideInactiveButtonsEditable]) {
    [self _writeDefault:@"SkyButtonRowHideInactiveButtons"
	  boolValue:self->hideInactiveButtons];
  }
  if ([self isButtonTextModeEditable])
    [self _writeDefault:@"SkyButtonTextMode" boolValue:self->buttonTextMode];
  
  if ([self isDockTextModeEditable])
    [self _writeDefault:@"SkyDockTextMode" boolValue:self->dockTextMode];
  
  if ([self isDockShowDesktopEditable])
    [self _writeDefault:@"SkyDockShowDesktop" boolValue:self->dockShowDesktop];
  
  if ([self isMaxClipCountEditable]) {
    [self _writeDefault:@"SkyMaxFavoritesCount"
	  value:[NSNumber numberWithInt:[self maxClipCount]]];
  }
  [self _writeDefault:@"SkyMaxNavLabelLength"
	value:[NSNumber numberWithInt:[self maxNavLabelLength]]];
  
  if ([self isLanguageEditable])
    [self _writeDefault:@"language" value:[self languageAndTheme]];
  
  if ([self isTimezoneEditable])
    [self _writeDefault:@"timezone" value:[self timezone]];
  
  [self _writeDefault:@"scheduler_AMPM_dates" boolValue:[self showAMPMDates]];
  
  /* save access stuff */
  if (self->isRoot) {
    [self _writeRootDefault:@"SkyDockablePagesOrdering" 
	  boolValue:self->isDockablePagesEditable];
    [self _writeRootDefault:@"SkyDockShowDesktop"
	  boolValue:self->isDockShowDesktopEditable];
    
    [self _writeRootDefault:@"language" boolValue:self->isLanguageEditable];
    [self _writeRootDefault:@"timezone" boolValue:self->isTimezoneEditable];
  }
  
  [self postAccountChanged:[self account]];
  if (reloadDock)
    [self postDockReloadNotification];
  
  return [self leavePage];
}

@end /* SkyDisplayPreferences */
