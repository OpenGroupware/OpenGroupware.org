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

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSBundle;
@class WOComponent;

struct DockInfo {
  NSString *component;
  NSString *page;
  NSString *label;
  NSString *image;
  NSString *miniView;
  NSString *miniTextView;
  NSBundle *bundle;

  /* cached state */
  NSString    *localizedLabel;
  WOComponent *miniViewPage;
  WOComponent *miniTextViewPage;
};

@interface SkyDock : LSWComponent
{
  struct DockInfo *dockInfo;
  unsigned count;
  unsigned idx;
  BOOL     textMode;
  NSString *logoImageName;
  NSString *logoImageLink;
  NSString *logoMenuAlignment;
  
  id       item;
}

- (void)_releaseConfig;
- (void)configure;

@end /* SkyDock */

#include <OGoFoundation/LSWEditorPage.h>
#include "common.h"

@implementation SkyDock

+ (int)version {
  return 2;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  id p;
  /* this component is a session-singleton */

  if ((p = [self persistentInstance])) {
    [p retain];
    [p ensureAwakeInContext:self->context];
    [self release];
    return p;
  }
  if ((self = [super init])) {
    [self registerAsPersistentInstance];

    [[NSNotificationCenter defaultCenter]
                           addObserver:self selector:@selector(reloadConfig:)
                           name:@"SkyDockReload"
                           object:nil];
  }
  return self;
}

- (id)initWithContext:(WOContext *)_ctx {
  id p;

  self->context = _ctx;
  if ((p = [self persistentInstance])) {
    [p retain];
    [self release];
    [p ensureAwakeInContext:_ctx];
    return p;
  }
  if ((self = [super initWithContext:_ctx])) {
    [self registerAsPersistentInstance];

    [[NSNotificationCenter defaultCenter]
                           addObserver:self selector:@selector(reloadConfig:)
                           name:@"SkyDockReload"
                           object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self _releaseConfig];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  
  if ([self hasSession]) {
    if (self->dockInfo == NULL)
      [self configure];

    self->textMode = [[[[self session] userDefaults]
                              objectForKey:@"SkyDockTextMode"]
                              boolValue];
  }
}

/* configuring */

- (void)_releaseConfig {
  if (self->dockInfo) {
    unsigned i;

    for (i = 0; i < self->count; i++) {
      [self->dockInfo[i].miniViewPage     release];
      [self->dockInfo[i].miniTextViewPage release];
      [self->dockInfo[i].component        release];
      [self->dockInfo[i].page             release];
      [self->dockInfo[i].label            release];
      [self->dockInfo[i].localizedLabel   release];
      [self->dockInfo[i].image            release];
      [self->dockInfo[i].bundle           release];
      [self->dockInfo[i].miniView         release];
      [self->dockInfo[i].miniTextView     release];
    }
    free(self->dockInfo);
    self->dockInfo = NULL;

    ASSIGN(self->logoImageName,     nil);
    ASSIGN(self->logoImageLink,     nil);
    ASSIGN(self->logoMenuAlignment, nil);

    self->item  = nil;
    self->count = 0;
  }
}

- (void)reloadConfig:(NSNotification *)_notification {
  [self debugWithFormat:@"reconfiguring dock .."];
  [self _releaseConfig];
}

- (void)configure {
  NGBundleManager *bm;
  WOSession       *sn;
  NSUserDefaults  *df;
  NSEnumerator    *dockedPageNames;
  NSString        *pageName;
  NSZone          *z;
  NSArray         *tmp;
  unsigned        i;
  BOOL            isExtraAccount, isRootAccount;

  //[self logWithFormat:@"CONFIGURE DOCK .."];
  
  [self _releaseConfig];
  
  z  = [self zone];
  sn = [self session];
  df = [sn userDefaults];
  bm = [NGBundleManager defaultBundleManager];

  /* get type of current account */

  isRootAccount = [sn activeAccountIsRoot];
  isExtraAccount =
    [[[sn activeAccount] valueForKey:@"isExtraAccount"] boolValue];

  /* set logoImageName and alignment of the logo - menu */
  
  self->logoImageName     = [[df stringForKey:@"SkyDockLogo"] retain];
  self->logoImageLink     = [[df stringForKey:@"SkyDockLogoLink"] retain];
  self->logoMenuAlignment = [[[df stringForKey:@"SkyDockLogoMenuAlignment"]
                                  lowercaseString] retain];
  
  /* determine docked pages from NSUserDefaults */

  tmp             = [df arrayForKey:@"SkyDockablePagesOrdering"];
  dockedPageNames = [tmp objectEnumerator];

  /* allocate dock array with max size */

  self->dockInfo = calloc(sizeof(struct DockInfo), [tmp count] + 1);
  
  NSAssert(self->dockInfo, @"could not allocate memory for dock !");

  /* find configuration for each page .. */

  for (i = 0; ((pageName = [dockedPageNames nextObject]));) {
    NSBundle     *bundle;
    NSDictionary *cfgEntry;
    NSString     *componentName, *label, *imageName, *miniView, *miniTextView;

    bundle = [bm bundleProvidingResource:pageName ofType:@"DockablePages"];
    if (bundle == nil) {
      [self logWithFormat:@"did not find dockable page %@", pageName];
      continue;
    }
    cfgEntry = [bundle configForResource:pageName ofType:@"DockablePages"];
    if (cfgEntry == nil) {
      [self logWithFormat:@"missing configuration of dockable page %@",
              pageName];
      continue;
    }
    componentName = [cfgEntry objectForKey:@"component"];
    label         = [cfgEntry objectForKey:@"labelKey"];
    imageName     = [cfgEntry objectForKey:@"image"];
    miniView      = [cfgEntry objectForKey:@"miniView"];
    miniTextView  = [cfgEntry objectForKey:@"miniTextView"];
    
    /* check whether page is visible for root only */
    
    if ([[cfgEntry objectForKey:@"onlyRoot"] boolValue]) {
      if (!isRootAccount)
        continue;
    }
    
    /* check whether the page is visible for extra accounts */
    
    if (isExtraAccount) {
      if (![[cfgEntry objectForKey:@"allowedForExtraAccounts"] boolValue]) {
        NSLog(@"page %@ is not allowed for extra accounts !", pageName);
        continue;
      }
    }

    if (componentName == nil) {
      [self logWithFormat:@"missing component-name of page %@", pageName];
      continue;
    }

    /* check whether there is a bundle providing the required component */

    if (![bm bundleProvidingResource:componentName ofType:@"WOComponents"]) {
      [self logWithFormat:@"module providing %@ is missing !",
              componentName];
      continue;
    }

    /* check whether the miniView is valid */
    if (miniView) {
      if (![bm bundleProvidingResource:miniView ofType:@"WOComponents"]) {
        [self logWithFormat:@"module providing dock miniview %@ is missing !",
                miniView];
        miniView = nil;
      }
    }

    /* check whether the miniView is valid */
    if (miniTextView) {
      if (![bm bundleProvidingResource:miniTextView ofType:@"WOComponents"]) {
        [self logWithFormat:@"module providing dock minitextview %@ is "
              @"missing !", miniTextView];
        miniTextView = nil;
      }
    }

    self->dockInfo[i].image = imageName
                            ? [imageName copyWithZone:z]
                            : [[NSNull null] retain];
    
    self->dockInfo[i].label            = [label         copyWithZone:z];
    self->dockInfo[i].component        = [componentName copyWithZone:z];
    self->dockInfo[i].page             = [pageName      copyWithZone:z];
    self->dockInfo[i].miniView         = [miniView      copyWithZone:z];
    self->dockInfo[i].miniTextView     = [miniTextView  copyWithZone:z];
    self->dockInfo[i].bundle           = [bundle        retain];
    self->dockInfo[i].localizedLabel   = nil;
    self->dockInfo[i].miniViewPage     = nil;
    self->dockInfo[i].miniTextViewPage = nil;

    i++;
  }
  self->count = i;
}

/* actions */

- (id)logout {
  BOOL logLogout;

  logLogout = [[[[self session] userDefaults]
                       objectForKey:@"LSSessionAccountLogEnabled"] boolValue];
  if (logLogout) {
    [[self session] runCommand:@"sessionlog::add",
                    @"account", [[self session] activeAccount],
                    @"action",  @"logout", nil];
  }
  [[self session] terminate];
  return [[self application] pageWithName:@"OGoLogoutPage"];
}

- (id)dockEntryClicked {
  OGoSession *sn;
  id         page;

  sn = (id)[self session];
  
  if (self->idx >= self->count)
    page = nil;
  else
    page = self->dockInfo[self->idx].component;

  if ((page = [self pageWithName:page]) == nil) {
    [self logWithFormat:@"couldn't create page %@", page];
    return nil;
  }
  [[sn navigation] enterPage:page];
  return page;
}

/* be a repetition */

- (id)pages {
  return self;
}
- (int)count {
  return self->dockInfo ? self->count : 0;
}
- (id)objectAtIndex:(unsigned)_idx {
  /* fake array for list-binding of repetition */
  if (_idx >= self->count) return nil;
  return self->dockInfo[_idx].component;
}

/* accessors */

- (BOOL)isInGfxMode {
  if (self->textMode)
    return NO;
  if ([[[self session] valueForKey:@"isTextModeBrowser"] boolValue])
    return NO;
  return YES;
}
- (BOOL)isInTextMode {
  return self->textMode;
}
- (BOOL)isTextModeBrowser {
  return [[[self session] valueForKey:@"isTextModeBrowser"] boolValue];
}

- (BOOL)disableLinks {
  return [[[[self session] navigation] activePage] isEditorPage];
}

- (BOOL)hasDockMiniView {
  if (self->idx >= self->count) {
    [self debugWithFormat:@"dock idx is out of range !"];
    return NO;
  }

  if (self->dockInfo[self->idx].miniView != nil)
    return YES;

  return NO;
}

- (BOOL)hasDockMiniTextView {
  if (self->idx >= self->count) {
    [self debugWithFormat:@"dock idx is out of range !"];
    return NO;
  }

  if (self->dockInfo[self->idx].miniTextView != nil)
    return YES;

  return NO;
}

- (WOComponent *)dockMiniView {
  WOComponent *page;

  if (self->idx >= self->count) {
    [self logWithFormat:@"dock idx is out of range !"];
    return nil;
  }
  
  if ((page = self->dockInfo[self->idx].miniViewPage))
    return page;
  
  if ((page = [self pageWithName:self->dockInfo[self->idx].miniView])) {
    self->dockInfo[self->idx].miniViewPage = [page retain];
    return page;
  }
  [self logWithFormat:@"WARNING: couldn't load miniview %@ !",
          self->dockInfo[self->idx].miniView];

  return nil;
}
- (WOComponent *)dockMiniTextView {
  WOComponent *page;

  if (self->idx >= self->count) {
    [self logWithFormat:@"dock idx is out of range !"];
    return nil;
  }
  
  if ((page = self->dockInfo[self->idx].miniTextViewPage))
    return page;
  
  if ((page = [self pageWithName:self->dockInfo[self->idx].miniTextView])) {
    self->dockInfo[self->idx].miniTextViewPage = [page retain];
    return page;
  }
  [self logWithFormat:@"WARNING: couldn't load minitextview %@ !",
          self->dockInfo[self->idx].miniTextView];

  return nil;
}

- (NSString *)dockComponent {
  return (self->idx >= self->count)
    ? nil
    : self->dockInfo[self->idx].component;
}

- (NSString *)dockImageName {
  NSString *s;
  
  if (self->idx >= self->count)
    return nil;
  s = self->dockInfo[self->idx].image;
  return s;
}
- (NSString *)dockImageNameAsPNG {
  NSRange  r;
  NSString *s;
  
  if ((s = [self dockImageName]) == nil)
    return nil;
  
  r = [s rangeOfString:@"."];
  if (r.length > 0)
    s = [s substringToIndex:r.location];
  return [s stringByAppendingString:@".png"];
}

- (NSString *)logoImageName {
  return self->logoImageName;
}

- (NSString *)logoImageLink {
  return self->logoImageLink;
}

- (NSString *)logoMenuAlignment {
  return self->logoMenuAlignment;
}

- (NSString *)dockLabel {
  NSString *labelKey, *table, *label;
  
  if (self->idx >= self->count)
    return nil;
  
  if ((label = self->dockInfo[self->idx].localizedLabel))
    return label;
  
  labelKey = self->dockInfo[self->idx].label;
  table    = [self->dockInfo[self->idx].bundle bundleName];
  
  if (labelKey == nil) {
    [self logWithFormat:@"missing labelkey for dock item !"];
    return nil;
  }
  if (table) {
    label = [[[self application]
                    resourceManager]
                    stringForKey:labelKey
                    inTableNamed:table
                    withDefaultValue:nil
                    languages:[[self session] languages]];

    if (label == nil) {
#if DEBUG
      [self logWithFormat:@"couldn't resolve string key %@ in table %@",
              labelKey, table];
#endif
      label = labelKey;
    }
  }
  else
    label = labelKey;
  
  self->dockInfo[self->idx].localizedLabel =
    label ? [label copy] : [labelKey copy];
  
  return self->dockInfo[self->idx].localizedLabel;
}

- (void)setIndex:(int)_idx {
  self->idx = _idx;
}
- (int)index {
  return self->idx;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

/* handle requests */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  /* no takevalues required for content */
}

/* generate response */

- (void)_appendGfxToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  BOOL hasLinks;
  
  hasLinks = [self disableLinks] ? NO : YES;
  
  [_r appendContentString:
        @"<table cellpadding=\"0\" cellspacing=\"0\" "
        @"border=\"0\" width=\"100%\">"
        @"<tr>"];
  
  [super appendToResponse:_r inContext:_ctx];
  [_r appendContentString:@"</tr></table>"];
}

- (void)_appendTxtToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [_r appendContentString:
        @"<table class=\"skytextdocktable\" cellspacing='0' cellpadding='0'>"
        @"<tr>"];

  [super appendToResponse:_r inContext:_ctx];

  [_r appendContentString:@"</tr></table>"];
}

- (void)_appendOnlyTxtToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [super appendToResponse:_r inContext:_ctx];
  [_r appendContentString:@"<br />"];
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  if (self->dockInfo == NULL)
    [self configure];

  if ([self isInGfxMode]) {
    [self _appendGfxToResponse:_r inContext:_ctx];
  }
  else if ([self isInTextMode]) {
    [self _appendTxtToResponse:_r inContext:_ctx];
  }
  else if ([self isTextModeBrowser]) {
    [self _appendOnlyTxtToResponse:_r inContext:_ctx];
  }
  else {
    [self logWithFormat:@"unknown dock mode ?!"];
    [super appendToResponse:_r inContext:_ctx];
  }
}

@end /* SkyDock */

@interface _SkyDockIcons : WODynamicElement
{
  WOAssociation *pages;
}
@end

@implementation _SkyDockIcons

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSArray  *lpages;
  unsigned i, count;
  BOOL     isLogoMenuBottomAligned;
  
  lpages = [self->pages valueInComponent:[_ctx component]];
  
  [_response appendContentString:
               @"<table cellpadding='0' cellspacing='0' border='0' width='100%'>"
               @"<tr><td valign='top'>"];
  
  /* dock entries */
  for (i = 0, count = [lpages count]; i < count; i++) {
    BOOL hasDockMiniView;
    BOOL activePageIsNotEditor;
    
    if (hasDockMiniView) {
      /* mini view */
    }
    else {
      if (activePageIsNotEditor) {
        // DockLink(DockImage)
      }
      else {
        // DockImage
      }
    }
  }
  
  [_response appendContentString:@"</td>"];

  if (isLogoMenuBottomAligned) {
  }
  else { /* right aligned */
  }
  [_response appendContentString:@"</tr>"];  
  [_response appendContentString:@"</table>"];
}

@end /* _SkyDockIcons */
