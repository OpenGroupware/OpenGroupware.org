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

#include <OGoFoundation/OGoContentPage.h>

@class NSString, NSDictionary, NSMutableDictionary;
@class EOArrayDataSource;

@interface SkyNews : OGoContentPage
{
@protected
  EOArrayDataSource   *dataSource;
  NSString            *tabKey;
  NSDictionary        *selectedAttribute;
  unsigned            startIndex;
  id                  article;
  BOOL                isDescending;
  BOOL                isAccountNewsEditor;
  BOOL                fetchArticles;
  NSString            *sortedKey;
  NSMutableDictionary *nameToExtComponent;
  id                  currentTab;
}
@end

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoSession.h>
#include <EOControl/EOArrayDataSource.h>

@interface SkyNews(PrivateMethods)
- (id)tabClicked;
@end

@implementation SkyNews

static NGBundleManager *bm           = nil;
static NGMimeType      *eoNewsType   = nil;
static NSArray         *allNewsPages = nil;

+ (void)initialize {
  bm = [[NGBundleManager defaultBundleManager] retain];
  allNewsPages = [[bm providedResourcesOfType:@"NewsPages"] copy];
  
  if (eoNewsType == nil)
    eoNewsType = [[NGMimeType mimeType:@"eo" subType:@"newsarticle"] retain];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    [self registerAsPersistentInstance];
    [self tabClicked];
    [self registerForNotificationNamed:LSWNewNewsArticleNotificationName];
    [self registerForNotificationNamed:LSWUpdatedNewsArticleNotificationName];
    [self registerForNotificationNamed:LSWDeletedNewsArticleNotificationName];
    
    self->sortedKey  = @"name";
    self->dataSource = [[EOArrayDataSource alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->nameToExtComponent release];
  [self->dataSource release];
  [self->article    release];
  [self->tabKey     release];
  [self->sortedKey  release];
  [super dealloc];
}

/* accessors */

- (void)setSortedKey:(NSString *)_key {
  ASSIGNCOPY(self->sortedKey, _key);
}
- (NSString *)sortedKey {
  return self->sortedKey;
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGNCOPY(self->tabKey, _tabKey);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  self->selectedAttribute = _selectedAttribute;
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setArticle:(id)_article {
  ASSIGN(self->article, _article);
}
- (id)article {
  return self->article;    
}

/* operations */

- (void)_fetchArticles {
  NSArray *a = nil;

  a = [self runCommand:@"newsarticle::get",
            @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  [self->dataSource setArray:a];
}

- (NSArray *)_fetchTeamEOsOfAccountEO:(id)_acnt {
  return [self runCommand:@"account::teams",
                  @"account",    _acnt,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
	       nil];
}

- (BOOL)_checkWhetherAccountIsNewsEditor {
  NSArray  *teams;
  unsigned i, cnt;
  
  if ([[self session] activeAccountIsRoot])
    return YES;
  
  teams = [self _fetchTeamEOsOfAccountEO:[[self session] activeAccount]];
  
  /* scan for 'newseditors' team */
  for (i = 0, cnt = [teams count]; i < cnt; i++) {
    id team;
    
    team = [teams objectAtIndex:i];
    if ([[team valueForKey:@"login"] isEqualToString:@"newseditors"])
      return YES;
  }
  
  return NO;
}

/* bundles */

- (NSArray *)bundleTabs {
  return allNewsPages;
}

- (void)setCurrentTab:(id)_tab {
  ASSIGN(self->currentTab, _tab);
}
- (id)currentTab {
  return self->currentTab;
}

- (WOComponent *)tabComponent {
  WOComponent *page;
  NSString    *compName;
  
  compName = [[self currentTab] valueForKey:@"component"];
  
  if ((page = [self->nameToExtComponent objectForKey:compName]) != nil) {
    [page ensureAwakeInContext:[self context]];
    return page;
  }
  
  if ((page = [self pageWithName:compName]) == nil) {
    [self setErrorString:@"Did not find news extension page!"];
    return nil;
  }
  
  if (self->nameToExtComponent == nil) {
    self->nameToExtComponent = 
      [[NSMutableDictionary alloc] initWithCapacity:4];
  }
  [self->nameToExtComponent setObject:page forKey:compName];
  return page;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  
  if (!self->fetchArticles)
    return;
  
  [self _fetchArticles];
  self->fetchArticles = NO;
}

/* actions */

- (id)tabClicked {
  if ([self->tabKey isEqualToString:@"editors"]) {
    self->startIndex = 0;
    [self _fetchArticles];
    return nil;
  } 
  
  self->isAccountNewsEditor = [self _checkWhetherAccountIsNewsEditor];
  return nil;
}

- (id)showNewsTabAction {
  [self setTabKey:@"news"];
  [self tabClicked];
  return self;
}
- (id)showNewsEditorTabAction {
  [self setTabKey:@"editors"];
  [self tabClicked];
  return self;
}

/* accessors */

- (BOOL)isAccountNewsEditor {
  return self->isAccountNewsEditor;    
}

- (NSString *)isIndexArticle {
  NSString *s;

  s = [[[self article] valueForKey:@"isIndexArticle"] stringValue];
  return [[self labels] valueForKey:s];
}

- (id)dataSource {
  return self->dataSource;
}

/* actions */

- (id)refresh {
  [self _fetchArticles];
  return nil;
}

- (id)viewNewsArticle {
  return [self activateObject:self->article withVerb:@"view"];
}

- (id)newNewsArticle {
  WOComponent *ct;
  ct = [[self session] instantiateComponentForCommand:@"new" type:eoNewsType];
  return ct;
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];
  self->startIndex    = 0;
  self->fetchArticles = YES;
}

@end /* SkyNews */
