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

@class NSArray, NSString, NSDictionary;
@class SkyProjectDataSource;

@interface LSWProjects : LSWContentPage
{
@protected
  NSArray      *projects;
  NSDictionary *selectedAttribute;
  unsigned     startIndex;
  id           project;
  NSString     *tabKey;
  BOOL         fetchProjects; 
  BOOL         isDescending;

  SkyProjectDataSource *commonDS;
  SkyProjectDataSource *staffDS;
  SkyProjectDataSource *privateDS;
  SkyProjectDataSource *archivedDS;
}

@end

#include "common.h"

@interface LSWProjects(PrivateMethods)
- (id)tabClicked;
- (void)initDataSources;
- (void)clearDataSources;
@end

@implementation LSWProjects

+ (int)version {
  return 1;
}

- (id)init {
  id p;
 
  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    NSString *tb;
    
    [self registerAsPersistentInstance];
    
    tb  = [[[self session] userDefaults] stringForKey:@"projects_sub_view"];
    self->tabKey = (tb!=nil) ? [tb copy] : @"common";
    self->fetchProjects = YES;

    [self registerForNotificationNamed:LSWNewProjectNotificationName];
    [self registerForNotificationNamed:LSWUpdatedProjectNotificationName];
    [self registerForNotificationNamed:LSWDeletedProjectNotificationName];
    [self initDataSources];
    [self tabClicked];
  }
  return self;
}

- (Class)dataSourceClass {
  return [SkyProjectDataSource class];
}
- (SkyProjectDataSource *)createDataSourceWithQualifierFormat:(NSString *)_fmt
  timeZone:(NSString *)_tz inContext:(LSCommandContext *)ctx
{
  SkyProjectDataSource *ds;
  EOFetchSpecification *fSpec = nil;
  EOQualifier          *qual  = nil;
  
  qual  = [EOQualifier qualifierWithQualifierFormat:_fmt];
  fSpec = [[EOFetchSpecification alloc] initWithEntityName:@"Project"
                                        qualifier:qual
                                        sortOrderings:nil usesDistinct:NO
					isDeep:NO hints:nil];
  ds = [[self dataSourceClass] alloc];
  ds = [ds  initWithContext:(id)ctx];
  [ds setTimeZone:_tz];
  [ds setFetchSpecification:fSpec];
  [fSpec release]; fSpec = nil;
  
  return ds;
}

- (void)initDataSources {
  LSCommandContext *ctx;
  NSString         *tz;
  
  ctx = [(OGoSession *)[self session] commandContext];
  tz  = (id)[(OGoSession *)[self session] timeZone]; // weird!
  
  self->commonDS = 
    [self createDataSourceWithQualifierFormat:@"type = \"common\""
	  timeZone:tz inContext:ctx];
  self->staffDS =
    [self createDataSourceWithQualifierFormat:@"type = \"staff\""
	  timeZone:tz inContext:ctx];
  self->privateDS =
    [self createDataSourceWithQualifierFormat:@"type = \"private\""
	  timeZone:tz inContext:ctx];
  self->archivedDS =
    [self createDataSourceWithQualifierFormat:@"type = \"archived\""
	  timeZone:tz inContext:ctx];
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->project    release];
  [self->tabKey     release];
  [self->projects   release];
  [self->commonDS   release];
  [self->staffDS    release];
  [self->privateDS  release];
  [self->archivedDS release];
  [super dealloc];
}

/* notifications */

- (void)_processNewProjectNotification:(id)p {
  NSArray *pca;
  
  pca = [p valueForKey:@"toProjectCompanyAssignment"];

  if (p) {
    self->tabKey = ([p valueForKey:@"teamId"] == nil)
      ? (([pca count] == 0) ? @"private" : @"staff")
      : @"common";
  }
  [self clearDataSources];
  [self tabClicked];
}
- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];
  
  if ([_cn isEqualToString:LSWNewProjectNotificationName]) {
    [self _processNewProjectNotification:_object];
  }
  else if ([_cn isEqualToString:LSWDeletedProjectNotificationName] ||
           [_cn isEqualToString:LSWUpdatedProjectNotificationName]){
    [self clearDataSources];
    [self tabClicked];
  }
}

- (void)clearDataSources {
#if 0 // TODO: hh asks: why is this disabled?
  [self->commonDS   clear];
  [self->staffDS    clear];
  [self->privateDS  clear];
  [self->archivedDS clear];
#endif  
  [self->projects release]; self->projects = nil;
}

/* accessors */

- (int)blockSize {
  id sn = [self session];
  return [[[sn userDefaults] objectForKey:@"projects_blocksize"] intValue];
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
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

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;    
}

- (void)setProjects:(NSArray *)_projects {
  ASSIGN(self->projects, _projects);
}
- (NSArray *)projects {
  return self->projects;
}

- (BOOL)isProjectLinkDisabled {
  id           ac     = [[self session] activeAccount];
  NSNumber     *acId  = [ac valueForKey:@"companyId"];
  NSArray *assignments;
  int     i, cnt;

  if ([acId intValue] == 10000) // TODO: fix root check
    return NO;
  
  assignments = [self->project valueForKey:@"companyAssignments"];
  cnt         = [assignments count];

  if ([[self->project valueForKey:@"ownerId"] isEqual:acId])
    return NO;

  for (i = 0; i < cnt; i++) {
    id as = [assignments objectAtIndex:i];

    if (![acId isEqual:[as valueForKey:@"companyId"]])
      continue;
    if ([[as valueForKey:@"hasAccess"] boolValue])
      return NO;
  }
  return YES;
}

- (BOOL)isNewCommonProjectEnabled {
  return [[self session] activeAccountIsRoot];
}

- (BOOL)isNewStaffProjectEnabled {
  return ![[self session] activeAccountIsRoot];
}

- (EODataSource *)dataSourceForActiveTabKey {
  if ([self->tabKey isEqualToString:@"archived"])
    return self->archivedDS;
  if ([self->tabKey isEqualToString:@"common"])
    return self->commonDS;
  if ([self->tabKey isEqualToString:@"staff"])
    return self->staffDS;
  if ([self->tabKey isEqualToString:@"private"])
    return self->privateDS;
  
  return nil;
}

/* actions */

- (id)tabClicked {
  self->startIndex = 0;
  [self->projects release]; self->projects = nil;
  
  self->projects = [[[self dataSourceForActiveTabKey] fetchObjects] retain];
  return nil;
}

- (id)refresh {
  [self clearDataSources];
  return [self tabClicked];
}

- (id)viewProject {
  return [self activateObject:self->project withVerb:@"view"];
}

- (id)newProject {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"project"];
  return [[self session] instantiateComponentForCommand:@"new" type:mt];
}

@end /* LSWProjects */
