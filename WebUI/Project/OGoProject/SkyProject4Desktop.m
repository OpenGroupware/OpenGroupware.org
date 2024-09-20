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

/*
  SkyProject4Desktop
  
  This is the main entry page of the projects application.

  TODO: cleanup / splitup
*/

@class NSString, NSMutableDictionary;
@class EOFetchSpecification, EOQualifier;
@class EOFilterDataSource, EODataSource;

@interface SkyProject4Desktop : LSWContentPage
{
  EODataSource         *documentDS;
  EOFilterDataSource   *ds;
  EOQualifier          *searchQualifier;
  NSString	       *qualifierOperator;
  
  /* transient */
  unsigned int         currentBatch;
  id                   project;
  NSArray              *clippedGIDs;

  BOOL extendedSearch;
  BOOL isExtendetSearch; // TODO: fix typo

  NSString *title;
  NSString *fileName;
  NSString *extension;
  NSString *searchString;

  NSArray *searchProjects;

  id item;
  id prevItem;
  id currentTab;

  struct {
    int isListViewActive:1;
    int reserved:31;
  } spdFlags;

  NSMutableDictionary *nameToExtComponent;
}

- (EOFetchSpecification *)_fetchSpecification;
- (NSArray *)groupings;

@end

#include <OGoProject/EOQualifier+Project.h>
#include <NGMime/NGMimeType.h>
#include "common.h"

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@implementation SkyProject4Desktop

static NSTimeInterval projectDataSourceCacheTimeout = 3600;
static EOQualifier *archivedQualifier = nil;
static EOQualifier *publicQualifier   = nil;
static EOQualifier *privateQualifier  = nil;
static EOQualifier *trueQualifier     = nil;
static NSArray     *extDesktopPages   = nil;

+ (void)initialize {
  NGBundleManager *bm;
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  bm = [[NGBundleManager defaultBundleManager] retain];
  extDesktopPages = [[bm providedResourcesOfType:@"ProjectDesktopPages"] copy];
  
  trueQualifier = [[EOQualifier qualifierWithQualifierFormat:@"1=1"] retain];
  
  archivedQualifier =
    [[EOQualifier qualifierForProjectType:@"archived"] retain];
  publicQualifier  = [[EOQualifier qualifierForProjectType:@"common"] retain];
  privateQualifier = [[EOQualifier qualifierForProjectType:@"private"] retain];
  
  /* the following triggers the loading of the bundles */
  [OGoFileManagerFactory sharedFileManagerFactory];
}

- (EOFetchSpecification *)fetchSpecWithJustTheGroupings {
  EOFetchSpecification *fspec;
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                qualifier:nil
                                sortOrderings:nil];
  [fspec setGroupings:[self groupings]];
  return fspec;
}

- (void)wrapDataSourceInCacheAndFilter {
  EOCacheDataSource  *cds;
  EOFilterDataSource *fds;
  
  cds = [[EOCacheDataSource alloc] initWithDataSource:self->ds];
  [self->ds autorelease]; self->ds = nil;
  [cds setTimeout:projectDataSourceCacheTimeout];
  
  fds = [[EOFilterDataSource alloc] initWithDataSource:cds];
  self->ds = (id)fds;
  [cds release];
}

- (void)_setupDataSourceInContext:(LSCommandContext *)_cmdctx {
  self->ds = [SkyProjectDataSource alloc]; /* sep line to make gcc happy */
  self->ds = [(SkyProjectDataSource *)self->ds initWithContext:(id)_cmdctx];
  
  // TODO: twice?
  [self->ds setFetchSpecification:[self _fetchSpecification]];
  [self->ds setFetchSpecification:[self fetchSpecWithJustTheGroupings]];
  
  [self wrapDataSourceInCacheAndFilter];
}

- (id)init {
  /* this component is a session-singleton */
  WOComponent *p;
  
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    [self registerAsPersistentInstance];
    
    [self _setupDataSourceInContext:
            [(OGoSession *)[self session] commandContext]];
    self->extendedSearch = NO;
  }
  return self;
}

- (void)dealloc {
  [self->nameToExtComponent  release];
  [self->currentTab          release];
  [self->clippedGIDs         release];
  [self->project             release];
  [self->ds                  release];
  [self->title               release];
  [self->extension           release];
  [self->fileName            release];
  [self->searchString        release];
  [self->qualifierOperator   release];
  [self->searchProjects      release];
  [self->item                release];
  [self->prevItem            release];
  [self->documentDS          release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->project        release]; self->project        = nil;
  [self->clippedGIDs    release]; self->clippedGIDs    = nil;
  [self->searchProjects release]; self->searchProjects = nil;
  [super sleep];
}

/* accessors */

- (NSArray *)searchProjectArray {
  return self->searchProjects;
}

- (EODataSource *)dataSource {
  return self->ds;
}

- (EODataSource *)documentDS {
  return self->documentDS;
}

- (void)setQualifierOperator:(NSString *)_op {
  ASSIGNCOPY(self->qualifierOperator, _op);
}
- (NSString *)qualifierOperator {
  return [self->qualifierOperator isNotNull]
    ? self->qualifierOperator : (NSString *)@"AND";
}



/* datasources */

- (EOFetchSpecification *)_fetchSpecification {
  EOFetchSpecification *fspec;

  if ((fspec = [self->ds fetchSpecification]))
    return [[fspec copy] autorelease];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                qualifier:nil
                                sortOrderings:nil];
  [fspec setGroupings:[self groupings]];
  
  return fspec;
}

- (id)privateDataSource {
  [self->ds setAuxiliaryQualifier:privateQualifier];
  [self->ds setGroupings:nil];
  
  return self->ds;
}
- (id)archivedDataSource {
  [self->ds setAuxiliaryQualifier:archivedQualifier];
  [self->ds setGroupings:nil];
  
  return self->ds;
}
- (id)publicDataSource {
  [self->ds setAuxiliaryQualifier:publicQualifier];
  [self->ds setGroupings:nil];
  
  return self->ds;
}

- (id)searchDataSource {
  if (self->searchQualifier == nil) 
    return nil;
  
  [self->ds setAuxiliaryQualifier:self->searchQualifier];
  [self->ds setGroupings:nil];
  return self->ds;
}

- (EOQualifier *)_buildFavoriteProjectsQualifier {
  NSUserDefaults *ud;
  NSArray        *projectIds;
  
  ud         = [(OGoSession *)[self session] userDefaults];
  projectIds = [ud arrayForKey:@"skyp4_desktop_selected_projects"];
  
  return [EOQualifier qualifierForProjectIDs:projectIds];
}

- (id)favoriteDataSource {
  [self->ds setAuxiliaryQualifier:[self _buildFavoriteProjectsQualifier]];
  [self->ds setGroupings:nil];
  return self->ds;
}

/* tabs */

- (NSArray *)tabs {
  static NSArray *tabs = nil;
  if (tabs == nil) {
    tabs = [[[NSUserDefaults standardUserDefaults]
              arrayForKey:@"skyp4_desktop_tabs"] copy];
  }
  return tabs;
}

- (void)setCurrentTab:(NSDictionary *)_info {
  ASSIGN(self->currentTab, _info);
}
- (NSDictionary *)currentTab {
  return self->currentTab;
}

- (BOOL)isQuickViewActive {
  return self->spdFlags.isListViewActive ? NO : YES;
}
- (BOOL)isListViewActive {
  return self->spdFlags.isListViewActive ? YES : NO;
}

- (NSString *)currentTabLabel {
  NSString *k;
  
  k = [[self currentTab] objectForKey:@"labelKey"];
  if ([k length] == 0)
    k = [[self currentTab] objectForKey:@"key"];
  return [[self labels] valueForKey:k];
}
- (EODataSource *)tabDataSource {
  EOQualifier *q;
  
  // TODO: we need to use one DS per tab-key!
  
  q = [EOQualifier qualifierWithQualifierFormat:
                     [[self currentTab] objectForKey:@"qualifier"]];
  [self->ds setAuxiliaryQualifier:q];
  [self->ds setGroupings:nil];
  return self->ds;
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setCurrentBatch:(unsigned int)_idx {
  self->currentBatch = _idx;
}
- (unsigned int)currentBatch {
  return self->currentBatch;
}

- (NSArray *)defaultProjectGroupings {
  /* contains an array of arrays, entry idx 0 is groupname, idx 1 is qual */
  return [[(OGoSession *)[self session] userDefaults]
           arrayForKey:@"skyp4_project_groupings"];
}
- (NSArray *)groupings {
  EOGrouping     *grouping;
  NSMutableArray *groupings;
  NSEnumerator *e;
  NSArray *entry;
  
  groupings = [NSMutableArray arrayWithCapacity:64];

  /* read defaults */
  e = [[self defaultProjectGroupings] objectEnumerator];
  while ((entry = [e nextObject]) != nil) {
    NSString    *groupName;
    EOQualifier *q;
    
    groupName = [entry objectAtIndex:0];
    q = [EOQualifier qualifierWithQualifierFormat:[entry objectAtIndex:1]];

    grouping =
      [[EOQualifierGrouping alloc] initWithQualifier:q name:groupName];
    [groupings addObject:grouping];
    [grouping release];
  }
  
  /* check whether we have groupings ... */

  if ([groupings count] == 0)
    return nil;

  /* catch all the remaining stuff */
  
  grouping =
    [[EOQualifierGrouping alloc] initWithQualifier:trueQualifier name:@"%"];
  [groupings addObject:grouping];
  [grouping release]; grouping = nil;
  
#if 0 /* this grouping is done by tabs now .. */
  keyGrouping = [[EOKeyGrouping alloc] initWithKey:@"status"];
  [groupings addObject:keyGrouping];
  [keyGrouping release];
#endif
  
  grouping = [[[EOGroupingSet alloc] init] autorelease];
  [(EOGroupingSet *)grouping setGroupings:groupings];
  
  return [NSArray arrayWithObject:grouping];
}

/* clipping */

- (NSArray *)clippedProjectGIDs {
  OGoSession *sn;
  NSArray *ids;

  if (self->clippedGIDs)
    return self->clippedGIDs;
  
  sn = (id)[self session];
  
  ids = [[sn userDefaults] arrayForKey:@"clipped_projects"];
  if ([ids count] == 0) return nil;
  
  return [[[sn commandContext] documentManager] globalIDsForURLs:ids];
}

- (BOOL)isProjectClipped:(id)_project {
  return [[self clippedProjectGIDs] indexOfObject:[_project globalID]]
    != NSNotFound ? YES : NO;
}

- (void)clipProject:(id)_project {
  OGoSession     *sn;
  NSArray        *ids;
  NSMutableArray *mids;
  EOGlobalID     *gid;

  if ((gid = [_project globalID]) == nil)
    return;
  
  sn = (OGoSession *)[self session];
  
  ids = [[sn userDefaults] arrayForKey:@"clipped_projects"];
  if (ids) {
    if ([self isProjectClipped:_project])
      return;
    mids = [[ids mutableCopy] autorelease];
  }
  else
    mids = [NSMutableArray arrayWithCapacity:16];
  
  [mids addObject:gid];
  [[sn userDefaults] setObject:mids forKey:@"clipped_projects"];
}

/* qualifiers */

- (NSString *)likeWrapString:(NSString *)_s {
  if ([_s rangeOfString:@"*"].length == 0)
    _s  = [[@"*" stringByAppendingString:_s] stringByAppendingString:@"*"];
  return _s;
}

- (EOQualifier *)_newICaseLikeQualifierOnKey:(NSString *)_k value:(id)_value {
  return [[EOKeyValueQualifier alloc]
           initWithKey:_k
           operatorSelector:EOQualifierOperatorCaseInsensitiveLike
           value:_value];
}

- (EOQualifier *)qualifier {
  EOQualifier    *q;
  NSString       *s;
  NSMutableArray *qualifiers;
  
  qualifiers = [NSMutableArray arrayWithCapacity:4];
  // unused: op = EOQualifierOperatorCaseInsensitiveLike;

  s = self->title;
  if ([s length] > 0) {
    q = [self _newICaseLikeQualifierOnKey:@"NSFileSubject" 
              value:[self likeWrapString:s]];
    [qualifiers addObject:q];
    [q release];
  }

  s = self->fileName;
  if ([s length] > 0) {
    s = [self likeWrapString:s];
    
    if ([s rangeOfString:@"."].length == 0)
      s  = [s stringByAppendingString:@".*"];
    
    q = [self _newICaseLikeQualifierOnKey:@"NSFileName" value:s];
    [qualifiers addObject:q];
    [q release];
  }
  
  s = self->extension;
  if ([s length] > 0) {
    s = [@"*." stringByAppendingString:s];
    q = [self _newICaseLikeQualifierOnKey:@"NSFileName" value:s];
    [qualifiers addObject:q];
    [q release];
  }

  if ([qualifiers count] == 0)
    return nil;
  
  if ([qualifiers count] == 1)
    return [qualifiers objectAtIndex:0];
  
  q = [[self qualifierOperator] isEqualToString:@"OR"]
      ? [[EOOrQualifier alloc]  initWithQualifierArray:qualifiers]
      : [[EOAndQualifier alloc] initWithQualifierArray:qualifiers];
 
  return [q autorelease];
}

- (EOQualifier *)_newNameOrNumberICaseContainsQualifier:(id)_value {
  EOQualifier *nameQual, *numberQual, *result;
  NSString *str;
  
  str = [NSString stringWithFormat:@"*%@*", _value];
  nameQual   = [self _newICaseLikeQualifierOnKey:@"name"   value:str];
  numberQual = [self _newICaseLikeQualifierOnKey:@"number" value:str];
  result = [[EOOrQualifier alloc] initWithQualifiers:
                                    nameQual, numberQual, nil];
  [nameQual   release];
  [numberQual release];
  return result;
}

/* datasources */

- (Class)projectDocumentDataSourceClass {
  /* for project-wide searches */
  return NSClassFromString(@"SkyProjectDocumentDataSource");
}
- (EODataSource *)projectDocumentDataSource {
  LSCommandContext *cmdctx;
  Class        class;
  EODataSource *pds;
  
  cmdctx = [(OGoSession *)[self session] commandContext];
  class = [self projectDocumentDataSourceClass];
  pds   = [class alloc];
  pds   = [(SkyProjectDataSource *)pds initWithContext:cmdctx];
  return [pds autorelease];
}

/* actions */

- (id)showQuickView {
  self->spdFlags.isListViewActive = 0;
  return nil;
}
- (id)showListView {
  self->spdFlags.isListViewActive = 1;
  return nil;
}

- (id)refetch {
  [(EOCacheDataSource *)[(EOCacheDataSource *)[self dataSource] source] clear];
  return self;
}

- (id)clickedProject {
  return [self activateObject:[project globalID] withVerb:@"view"];
}

- (id)newProject {
  NGMimeType *mt;
  
  mt = [NGMimeType mimeType:@"eo" subType:@"project"];
  return [[self session] instantiateComponentForCommand:@"new" type:mt];
}
- (id)newWizard {
  [self warnWithFormat:@"%s: used deprecated method!", __PRETTY_FUNCTION__];
  return [self newProject];
}

- (id)searchProjects {
  EOQualifier *qual;
  
  self->isExtendetSearch = NO;
  
  if ([self->searchString length] > 0) {
    [self->searchQualifier release]; self->searchQualifier = nil;
    self->searchQualifier =
      [self _newNameOrNumberICaseContainsQualifier:self->searchString];
    
    ASSIGN(self->searchString, @"");
  }
  
  if ((qual = [self qualifier]) != nil) {
    EODataSource         *pds;
    EOFetchSpecification *fs;
    EOKeyGrouping *grp;
    
    if ((pds = [self projectDocumentDataSource]) == nil) {
      [self setErrorString:@"did not find project document datasource!"];
      return nil;
    }
    
    fs = [[EOFetchSpecification alloc] init];
    [fs setQualifier:qual];
    
    grp = [[[EOKeyGrouping alloc] initWithKey:@"projectName"] autorelease];
    [fs setGroupings:[NSArray arrayWithObject:grp]];
    
    [pds setFetchSpecification:fs];
    
    self->isExtendetSearch = YES; // TODO: fix typo
    
    ASSIGN(self->documentDS, pds);
    [pds setFetchSpecification:fs];
    [fs release]; fs = nil;
  }
  return nil;
}

/* accessors */

- (NSString *)textFieldStyle {
  return [NSString stringWithFormat:
                     @"font-size: 10px; background-color: %@;",
                     [[self config] valueForKey:@"colors_mainButtonRow"]];
}

- (void)setExtendedSearch:(BOOL)_ext {
  self->extendedSearch = _ext;
}
- (BOOL)extendedSearch {
  return self->extendedSearch;
}

- (void)setFileName:(NSString *)_str {
  ASSIGNCOPY(self->fileName, _str);;
}
- (NSString *)fileName {
  return self->fileName;
}
- (void)setTitle:(NSString *)_str {
  ASSIGNCOPY(self->title, _str);;
}
- (NSString *)title {
  return self->title;
}
- (void)setExtension:(NSString *)_str {
  ASSIGNCOPY(self->extension, _str);;
}
- (NSString *)extension {
  return self->extension;
}
- (void)setSearchString:(NSString *)_str {
  ASSIGNCOPY(self->searchString, _str);;
}
- (NSString *)searchString {
  return self->searchString;
}

- (BOOL)isExtendetSearch {
  return self->isExtendetSearch;
}

- (void)setItem:(id)_it {
  ASSIGN(self->item, _it);
}
- (id)item {
  return self->item;
}

- (void)setPrevItem:(id)_it {
  ASSIGN(self->prevItem, _it);
}
- (id)prevItem {
  return self->prevItem;
}

- (BOOL)isGroup {
  NSString *projectNum, *prevProjectNum;
  
  if (self->prevItem == nil)
    return NO;
  
  prevProjectNum = 
    [[self->prevItem valueForKey:@"project"] valueForKey:@"number"];
  projectNum = [[self->item valueForKey:@"project"] valueForKey:@"number"];
  return [prevProjectNum isEqual:projectNum];
}

- (BOOL)showGroup {
  return YES;
}

/* bundles */

- (NSArray *)bundleTabs {
  return extDesktopPages;
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

/* actions */

- (id)clickedFile {
  return [self activateObject:[(NSDictionary *)item objectForKey:@"globalID"]
               withVerb:@"view"];
}

@end /* SkyProject4Desktop */
