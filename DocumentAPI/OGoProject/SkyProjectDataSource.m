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

#include "SkyProjectDataSource.h"
#include "SkyProject.h"
#include "EOQualifier+Project.h"
#include "common.h"
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoAccounts/SkyTeamDataSource.h>

@interface SkyProjectDataSource(Privates)
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
- (NSArray *)_kindsNotToFetch;
@end

@interface SkyProject(Private)
- (void)_setGlobalID:(EOGlobalID *)_gid;
- (EOGlobalID *)leader_id;
- (EOGlobalID *)team_id;
@end

@implementation SkyProjectDataSource

static NSArray  *hiddenProjectTypes = nil;
static NSNumber *yesNum = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *defs;
  NSArray *v;
  
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  
  // TODO: all of them could be removed?
  v = [[NSArray alloc] initWithObjects:
			 @"00_invoiceProject",
	                 @"05_historyProject",
		         @"10_edcProject",
		         @"15_accountLog", nil];
  defs = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   v, @"hiddenprojectkinds", nil];
  [ud registerDefaults:defs];
  [defs release]; defs = nil; [v release]; v= nil;
  
  if (hiddenProjectTypes == nil)
    hiddenProjectTypes = [[ud arrayForKey:@"hiddenprojectkinds"] copy];
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (id)initWithContext:(id)_context {
  if (_context == nil) {
    [self release];
    return nil;
  }
  
  if ((self = [super init])) {
    self->context = [_context retain];
    [[self notificationCenter]
           addObserver:self
           selector:@selector(postDataSourceChangedNotification)
           name:@"SkyProjectDidChangeNotification" object:nil];
  }
  return self;
}

- (id)init {
  return [self initWithContext:nil];
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  [self->fetchSpecification release];
  [self->timeZone           release];
  [self->context            release];
  [super dealloc];
}

/* accessors */

- (id)context {
  return self->context;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if (self->fetchSpecification == _fSpec ||
      [self->fetchSpecification isEqual:_fSpec])
    return;
  
  ASSIGNCOPY(self->fetchSpecification, _fSpec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];;
}

/* command wrappers */

- (NSArray *)_fetchProjectsForPersonEO:(id)_eo {
  return [self->context runCommand:@"person::get-projects",
	      @"withArchived", yesNum,
	      @"object", _eo, nil];
}
- (NSArray *)_fetchProjectsForPersonEO:(id)_eo 
  butNotThoseOfKind:(NSArray *)_notTheseKinds
{
  if (_notTheseKinds == nil)
    return [self _fetchProjectsForPersonEO:_eo];
  
  return [self->context runCommand:@"person::get-projects",
	      @"withoutKinds", _notTheseKinds,
	      @"withArchived", yesNum,
	      @"object", _eo, nil];
}

/* fetching */

- (void)_adjustTimeZonesOfProjects:(NSArray *)_projects {
  if (self->timeZone == nil) 
    /* maybe better use GMT in this case? */
    return;
  
  [[_projects mappedArrayUsingSelector:@selector(objectForKey:)
	      withObject:@"startDate"]
              makeObjectsPerformSelector:@selector(setTimeZone:)
              withObject:self->timeZone];
}

- (void)_fixupProjectsAfterFetch:(NSArray *)_projects {
  NSEnumerator *enumerator;
  id  obj;

  enumerator = [_projects objectEnumerator];
  while ((obj = [enumerator nextObject])) { /* set types */
    id       pca;
    id       teamId;
    NSString *type;

    type   = nil;
    pca    = [obj valueForKey:@"companyAssignments"];
    teamId = [obj valueForKey:@"teamId"];
    if (![teamId isNotNull]) teamId = nil;
            
    if ((teamId == nil) && [pca count] == 0 &&
	![[obj valueForKey:@"dbStatus"]
	  isEqualToString:@"archived"]) { /* private */
      type = @"private";
    }
    else if (((teamId != nil) || [pca count] > 0) &&
	     ![[obj valueForKey:@"dbStatus"]
	       isEqualToString:@"archived"]) { /* common */
      type = @"common";
    }
    else if ([[obj valueForKey:@"dbStatus"]
	       isEqualToString:@"archived"]) {
      type = @"archived";
    }
    if ([type isNotNull])
      [obj takeValue:type forKey:@"type"];
  }
}

- (NSArray *)_filterProjectDocs:(NSArray *)_projects {
  EOQualifier *qualifier;
  
  if ((qualifier = [self->fetchSpecification qualifier]) == nil)
    return _projects;
  
  [self debugWithFormat:@"filter: %@", qualifier];
  return [_projects filteredArrayUsingQualifier:qualifier];
}

- (NSArray *)_applyFetchLimit:(int)_limit onProjectDocs:(NSArray *)_projects {
  if (!((_limit != 0) && ([_projects count] > _limit)))
    return _projects;
  
  [self logWithFormat:@"Note: fetch limit reached (limit=%d, count=%d)",
	  self, _limit, [_projects count]];
  return [_projects subarrayWithRange:NSMakeRange(0, _limit)];
}

- (NSArray *)_sortProjectDocs:(NSArray *)_projects {
  NSArray *sortOrderings;
  
  if ((sortOrderings = [self->fetchSpecification sortOrderings]) == nil)
    return _projects;
  
  return [_projects sortedArrayUsingKeyOrderArray:sortOrderings];
}

- (id)loginAccountEO {
  /* avoid using this method, rather base stuff on primary key */
  return [self->context valueForKey:LSAccountKey];
}

- (NSArray *)fetchObjects {
  NSAutoreleasePool *pool;
  NSArray      *projects      = nil;
  NSArray      *notTheseKinds = nil;
  NSDictionary *hints;
  NSArray      *attributes;
  unsigned     fetchLimit;
  BOOL         SearchAllProjects, fetchGlobalIDs;
  
  hints             = [[self fetchSpecification] hints];
  SearchAllProjects = [[hints valueForKey:@"SearchAllProjects"] boolValue];
  fetchGlobalIDs    = [[hints valueForKey:@"fetchGlobalIDs"]    boolValue];
  attributes        = [hints valueForKey:@"attributes"];
  
  pool          = [[NSAutoreleasePool alloc] init];
  notTheseKinds = [self _kindsNotToFetch];
  fetchLimit    = [self->fetchSpecification fetchLimit];
  
  if (SearchAllProjects) {
    projects = [self _fetchProjectsForPersonEO:[self loginAccountEO]];
  }
  else {
    projects = [self _fetchProjectsForPersonEO:[self loginAccountEO]
		     butNotThoseOfKind:notTheseKinds];
  }
  
  if (![projects isNotNull]) {
    [self logWithFormat:
	    @"WARNING[%s] no projects for %@", __PRETTY_FUNCTION__,
            [self->context valueForKey:LSAccountKey]];
    [pool release];
    return nil;
  }
  
  [self _adjustTimeZonesOfProjects:projects];
  [self _fixupProjectsAfterFetch:projects];

  /* morph EOs to documents */
  
  projects = [self _morphEOsToDocuments:projects];
  
  /* work on documents */
  
  projects = [self _filterProjectDocs:projects];
  projects = [self _applyFetchLimit:fetchLimit onProjectDocs:projects];
  projects = [self _sortProjectDocs:projects];

  /* apply filters ... */
  
  if (attributes != nil) {
    NSMutableArray *ma;
    unsigned i, count;
    
    count = [projects count];
    ma = [NSMutableArray arrayWithCapacity:(count + 1)];
    for (i = 0; i < count; i++) {
      id project;
      
      project = [projects objectAtIndex:i];
      project = [project valuesForKeys:attributes];
      if (project) [ma addObject:project];
    }
    projects = ma;
  }
  else if (fetchGlobalIDs)
    projects = [projects valueForKey:@"globalID"];
  
  /* prepare result */
  
  projects = [projects copy];
  [pool release];
  return [projects autorelease];
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  NSArray *projects;

  if (_gids         == nil) return nil;
  if ([_gids count] == 0)   return 0;

  projects = [self->context runCommand:@"project::get-by-globalid",
                  @"gids", _gids,
                  nil];
  projects = [self _morphEOsToDocuments:projects];
  return projects;
}

- (void)setTimeZone:(NSString *)_tz {
  ASSIGN(self->timeZone, _tz);
}
- (NSString *)timeZone {
  return self->timeZone;
}

- (Class)documentClass {
  static Class docClass = Nil;
  if (docClass == Nil)
    docClass = [SkyProject class];
  return docClass;
}

- (EOQualifier *)qualifierToCheckForGIDs:(NSArray *)_gids {
  EOQualifier *qual;
  
  qual = [[EOKeyValueQualifier alloc] 
           initWithKey:@"globalID"
           operatorSelector:EOQualifierOperatorEqual
           value:_gids];
  return [qual autorelease];
}

- (EODataSource *)ctxDataSource:(NSString *)_className 
  fetchSpecification:(EOFetchSpecification *)_fspec
{
  EODataSource *ds;
  
  ds = [[NSClassFromString(_className) alloc] initWithContext:[self context]];
  if (_fspec) [ds setFetchSpecification:_fspec];
  return [ds autorelease];
}

- (EOGlobalID *)globalIDForPKey:(NSNumber *)_pkey entityName:(NSString *)_en {
  if (![_pkey isNotNull]) return nil;
  
  return [EOKeyGlobalID globalIDWithEntityName:_en
                        keys:&_pkey keyCount:1 zone:NULL];
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  /* TODO: split up this huge method! */
  NSEnumerator        *enumerator;
  NSMutableArray      *result, *persons, *teams;
  id                  project;
  int                 cnt;

  if (_eos == nil)           return nil;
  if (!(cnt = [_eos count])) return [NSArray array];

  result  = [NSMutableArray arrayWithCapacity:cnt];
  persons = [NSMutableSet setWithCapacity:cnt];
  teams   = [NSMutableSet setWithCapacity:cnt];

  enumerator = [_eos objectEnumerator];

  while ((project = [enumerator nextObject])) {
    id doc, tmp;
    
    doc = [[[self documentClass] alloc] initWithEO:project dataSource:self];
    [result addObject:doc];
    
    tmp = [project valueForKey:@"ownerId"];
    if ((tmp = [self globalIDForPKey:tmp entityName:@"Person"]))
      [persons addObject:tmp];
    
    tmp = [project valueForKey:@"teamId"];
    if ((tmp = [self globalIDForPKey:tmp entityName:@"Team"]))
      [teams addObject:tmp];
    
    [doc release]; doc = nil;
  }
  {
    { /* fetch persons */
      id  ds;
      EOQualifier          *qual;
      EOFetchSpecification *fs;

      qual = [self qualifierToCheckForGIDs:[(id)persons allObjects]];
      fs = [[EOFetchSpecification alloc] init];
      [fs setQualifier:qual];
      ds = [self ctxDataSource:@"SkyPersonDataSource" fetchSpecification:fs];
      persons = (id)[ds fetchObjects];

      [qual release]; qual = nil;
    }
    { /* fetch persons */
      id ds;
      EOQualifier          *qual;
      EOFetchSpecification *fs;

      qual = [self qualifierToCheckForGIDs:[(id)teams allObjects]];
      fs = [[EOFetchSpecification alloc] init];
      [fs setQualifier:qual];
      
      ds = [self ctxDataSource:@"SkyTeamDataSource" fetchSpecification:fs];
      teams = (id)[ds fetchObjects];
    }
    {
      NSEnumerator *projectEnum;
      id           obj;

      projectEnum = [result objectEnumerator];

      while ((obj = [projectEnum nextObject])) {
        NSEnumerator *e;
        id           o;
        
        e = [persons objectEnumerator];

        while ((o = [e nextObject])) {
          if ([[obj leader_id] isEqual:[o globalID]]) {
            [obj setLeader:o];
            break;
          }
        }
        e = [teams objectEnumerator];

        while ((o = [e nextObject])) {
          if ([[obj team_id] isEqual:[o globalID]]) {
            [obj setTeam:o];
            break;
          }
        }        
      }
    }
    return result;
  }
}

/*
  if special kind (00_invoiceProject, 
                   05_historyProject,
                   10_edcProject,
                   15_accountLog) 
   appears in qualifier, eos are fetched,
   if not, these kinds are ignored
*/
- (NSArray *)_kindsNotToFetch {
  /* extracts a set of project kinds (strings) from a qualifier */
  EOQualifier *qual;
  
  if ((qual = [[self fetchSpecification] qualifier]) == nil)
    return hiddenProjectTypes; /* no qualifer => hide all */
  
  return [qual reduceProjectKindRestrictionByUsedNames:hiddenProjectTypes];
}

/* operations which modify the database */

- (id)createObject {
  return [[[SkyProject alloc] initWithContext:self->context] autorelease];
}

- (void)insertObject:(id)_obj {
  NSDictionary *dict;

  dict = ([_obj respondsToSelector:@selector(asDict)]) ? [_obj asDict] : _obj;
  dict = [self->context runCommand:@"project::new" arguments:dict];
  [(id)_obj _setGlobalID:[dict valueForKey:@"globalID"]];
  [self postDataSourceChangedNotification];
}

- (void)deleteObject:(id)_obj {
  NSDictionary *dict = [_obj asDict];

  [dict takeValue:yesNum forKey:@"reallyDelete"];
  [self->context runCommand:@"project::delete" arguments:dict];
  [self postDataSourceChangedNotification];
}

- (void)updateObject:(id)_obj {
  NSDictionary *dict;
  
  if (![_obj isComplete])
    return;
  
  dict = [_obj asDict];
  [self->context runCommand:@"project::set" arguments:dict];
  [self postDataSourceChangedNotification];
}

@end /* SkyProjectDataSource */
