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

#include <OGoFoundation/LSWContentPage.h>

@class NSString;
@class EOFetchSpecification, EOQualifier;
@class EOFilterDataSource, EODataSource;

@interface SkyProject4Desktop : LSWContentPage
{
  EODataSource         *documentDS;
  EOFilterDataSource   *ds;
  EOQualifier          *searchQualifier;
  
  /* transient */
  unsigned int         currentBatch;
  id                   project;
  NSArray              *clippedGIDs;

  BOOL extendedSearch;
  BOOL isExtendetSearch;

  NSString *title;
  NSString *fileName;
  NSString *extension;
  NSString *searchString;

  NSArray *searchProjects;

  id item;
  id prevItem;
}

- (EOFetchSpecification *)_fetchSpecification;
- (NSArray *)groupings;

@end

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

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  archivedQualifier =
    [[EOQualifier qualifierWithQualifierFormat:@"type='archived'"] retain];
  trueQualifier = [[EOQualifier qualifierWithQualifierFormat:@"1=1"] retain];
  publicQualifier =
    [[EOQualifier qualifierWithQualifierFormat:@"type='common'"] retain];
  privateQualifier =
    [[EOQualifier qualifierWithQualifierFormat:@"type='private'"] retain];

  /* the following triggers the loading of the bundles */
  [OGoFileManagerFactory sharedFileManagerFactory];
}

- (void)_setupDataSourceInContext:(LSCommandContext *)_cmdctx {
  EOCacheDataSource    *cds;
  EOFilterDataSource   *fds;
  EOFetchSpecification *fspec;
  
  self->ds = [[SkyProjectDataSource alloc] initWithContext:(id)_cmdctx];
  [self->ds setFetchSpecification:[self _fetchSpecification]];

  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                qualifier:nil
                                sortOrderings:nil];
  [fspec setGroupings:[self groupings]];
  
  [self->ds setFetchSpecification:fspec];
  cds = [[EOCacheDataSource alloc] initWithDataSource:self->ds];
  [self->ds autorelease]; self->ds = nil;
  [cds setTimeout:projectDataSourceCacheTimeout];
  
  fds = [[EOFilterDataSource alloc] initWithDataSource:cds];
  self->ds = (id)fds;
  [cds release];
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
  [self->clippedGIDs    release];
  [self->project        release];
  [self->ds             release];
  [self->title          release];
  [self->extension      release];
  [self->fileName       release];
  [self->searchString   release];
  [self->searchProjects release];
  [self->item           release];
  [self->prevItem       release];
  [self->documentDS     release];
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

- (id)dataSource {
  return self->ds;
}

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
  if (self->searchQualifier == nil) return nil;
  
  [self->ds setAuxiliaryQualifier:self->searchQualifier];
  [self->ds setGroupings:nil];

  return self->ds;
}

- (EOQualifier *)_buildFavoriteProjectsQualifier {
  NSUserDefaults *ud         = nil;
  EOQualifier    *result     = nil;
  NSMutableArray *qualArray  = nil;
  NSArray        *projectIds = nil;
  int            cnt, i;
  
  ud         = [(LSWSession *)[self session] userDefaults];
  projectIds = [ud arrayForKey:@"skyp4_desktop_selected_projects"];
  qualArray  = [[NSMutableArray alloc] initWithCapacity:[projectIds count]];

  for (cnt = [projectIds count], i=0; i<cnt; i++) {
    NSNumber    *projectId = [projectIds objectAtIndex:i];
    EOQualifier *qual;

    qual=[EOQualifier qualifierWithQualifierFormat:
                      [NSString stringWithFormat:@"projectId=%@", projectId]];
    [qualArray addObject:qual];
  }
  result = [[EOOrQualifier alloc] initWithQualifierArray:qualArray];
  [qualArray release];
  
  return [result autorelease];
}

- (id)favoriteDataSource {
  [self->ds setAuxiliaryQualifier:[self _buildFavoriteProjectsQualifier]];
  [self->ds setGroupings:nil];
  
  return self->ds;
}

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

- (NSArray *)groupings {
  EOGrouping     *grouping;
  NSMutableArray *groupings;
  
  groupings = [NSMutableArray arrayWithCapacity:64];

  /* read defaults */
  {
    NSEnumerator *e;
    NSArray *entry;
    
    e = [[[(LSWSession *)[self session]
                 userDefaults]
                 arrayForKey:@"skyp4_project_groupings"]
                 objectEnumerator];

    while ((entry = [e nextObject])) {
      NSString    *groupName;
      EOQualifier *q;
      
      groupName = [entry objectAtIndex:0];
      q = [EOQualifier qualifierWithQualifierFormat:
                         [entry objectAtIndex:1]];

      grouping =
        [[EOQualifierGrouping alloc] initWithQualifier:q name:groupName];
      [groupings addObject:grouping];
      [grouping release];
    }
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
  LSWSession *sn;
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
  LSWSession     *sn;
  NSArray        *ids;
  NSMutableArray *mids;
  EOGlobalID     *gid;

  if ((gid = [_project globalID]) == nil)
    return;
  
  sn = (LSWSession *)[self session];
  
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

/* actions */

- (id)refetch {
  [(EOCacheDataSource *)[(EOCacheDataSource *)[self dataSource] source] clear];
  return self;
}

- (id)clickedProject {
  return [self activateObject:[project globalID] withVerb:@"view"];
}

- (id)newWizard {
  NGMimeType *mt;
  
  mt = [NGMimeType mimeType:@"eo" subType:@"project"];
  return [[self session] instantiateComponentForCommand:@"new" type:mt];
}

- (BOOL)isAndSearch {
  return YES;
}

- (EOQualifier *)qualifier {
  NSString *s;
  SEL      op;
  NSMutableArray *qualifiers;
  
  qualifiers = [NSMutableArray arrayWithCapacity:4];
  op         = EOQualifierOperatorCaseInsensitiveLike;

  
  if ([(s = self->title) length] > 0) {
    EOQualifier *q;
    
    if ([s rangeOfString:@"*"].length == 0)
      s  = [[@"*" stringByAppendingString:s] stringByAppendingString:@"*"];

    q = [[EOKeyValueQualifier alloc]
                              initWithKey:@"NSFileSubject"
                              operatorSelector:op
                              value:s];
    [qualifiers addObject:q];
    [q release];
  }
  if ([(s = self->fileName) length] > 0) {
    EOQualifier *q;

    if ([s rangeOfString:@"*"].length == 0)
      s = [[@"*" stringByAppendingString:s] stringByAppendingString:@"*"];
   
    if ([s rangeOfString:@"."].length == 0)
      s  = [s stringByAppendingString:@".*"];
    
    q = [[EOKeyValueQualifier alloc]
                              initWithKey:@"NSFileName"
                              operatorSelector:op
                              value:s];
    [qualifiers addObject:q];
    [q release];
  }
  if ([(s = self->extension) length] > 0) {
    EOQualifier *q;

    s = [@"*." stringByAppendingString:s];
    
    q = [[EOKeyValueQualifier alloc]
                              initWithKey:@"NSFileName"
                              operatorSelector:op
                              value:s];
    [qualifiers addObject:q];
    [q release];
  }

  if ([qualifiers count] == 0) {
    return nil;
  }
  else if ([qualifiers count] == 1) {
    return [qualifiers objectAtIndex:0];
  }
  else {
    EOQualifier *q;
    
    q = [self isAndSearch]
      ? [[EOAndQualifier alloc] initWithQualifierArray:qualifiers]
      : [[EOOrQualifier alloc] initWithQualifierArray:qualifiers];
    
    return [q autorelease];
  }
}

- (id)searchProjectArray {
  return self->searchProjects;
}

- (id)searchProjects {
  EOKeyValueQualifier *nameQual, *numberQual;
  EOQualifier         *qual;
  NSString            *str;

  str                    = nil;
  self->isExtendetSearch = NO;
  
  if ([self->searchString length] > 0) {
    str = [NSString stringWithFormat:@"*%@*", self->searchString];
    
    [self->searchQualifier release]; self->searchQualifier = nil;
    nameQual =
      [[EOKeyValueQualifier alloc]
        initWithKey:@"name"
        operatorSelector:EOQualifierOperatorCaseInsensitiveLike
        value:str];
    numberQual =
      [[EOKeyValueQualifier alloc]
        initWithKey:@"number"
        operatorSelector:EOQualifierOperatorCaseInsensitiveLike
        value:str];

    self->searchQualifier =
      [[EOOrQualifier alloc] initWithQualifiers:nameQual, numberQual, nil];

    [nameQual   release];
    [numberQual release];

    ASSIGN(self->searchString, @"");
  }
  if ((qual = [self qualifier])) {
    Class                class;
    id                   pds;
    EOFetchSpecification *fs;

    class = NSClassFromString(@"SkyProjectDocumentDataSource");
    pds = [[[class alloc] initWithContext:(id)[[self session] commandContext]]
                   autorelease];
    if (pds) {
      fs = [[EOFetchSpecification alloc] init];

      [fs setQualifier:qual];
      {
        EOKeyGrouping *grp;

        grp = [[[EOKeyGrouping alloc]
                               initWithKey:@"projectName"]
                               autorelease];
        [fs setGroupings:[NSArray arrayWithObject:grp]];
    
        [pds setFetchSpecification:fs];
    
        self->isExtendetSearch = YES;

#if 0
        [self->searchProjects release];
        self->searchProjects = [[pds fetchObjects] retain];
#else
        ASSIGN(self->documentDS, pds);
#endif
      }
    }
  }
  return nil;
}

- (id)documentDS {
  return self->documentDS;
}

- (NSString *)textFieldStyle {
  return [NSString stringWithFormat:
                     @"font-size: 10px; background-color: %@;",
                     [[self config] valueForKey:@"colors_mainButtonRow"]];
}

- (BOOL)extendedSearch {
  return self->extendedSearch;
}
- (void)setExtendedSearch:(BOOL)_ext {
  self->extendedSearch = _ext;
}

- (NSString *)fileName {
  return self->fileName;
}
- (void)setFileName:(NSString *)_str {
  ASSIGN(self->fileName, _str);;
}
- (NSString *)title {
  return self->title;
}
- (void)setTitle:(NSString *)_str {
  ASSIGN(self->title, _str);;
}
- (NSString *)extension {
  return self->extension;
}
- (void)setExtension:(NSString *)_str {
  ASSIGN(self->extension, _str);;
}
- (NSString *)searchString {
  return self->searchString;
}
- (void)setSearchString:(NSString *)_str {
  ASSIGN(self->searchString, _str);;
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
  if (self->prevItem == nil)
    return NO;

  return [[[self->prevItem valueForKey:@"project"] valueForKey:@"number"]
                           isEqual:[[self->item valueForKey:@"project"]
                                                valueForKey:@"number"]];
}

- (id)showGroup {
  return [NSNumber numberWithBool:YES];
}

- (id)clickedFile {
  return [self activateObject:[item objectForKey:@"globalID"]
               withVerb:@"view"];
}

@end /* SkyProject4Desktop */
