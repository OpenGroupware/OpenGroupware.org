/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "SxTaskFolder.h"
#include "SxTask.h"
#include <Main/SxAuthenticator.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include <NGObjWeb/SoObject+SoDAV.h>
#include <EOControl/EOControl.h>
#include "common.h"

#include <ZSBackend/SxTaskManager.h>

@implementation SxTaskFolder

- (void)dealloc {
  [self->idsAndVersions release];
  [self->group release];
  [self->type  release];
  [super dealloc];
}

/* accessors */

- (void)setType:(NSString *)_type {
  ASSIGNCOPY(self->type, _type);
}
- (NSString *)type {
  return self->type;
}

- (void)setGroup:(NSString *)_group {
  ASSIGNCOPY(self->group, _group);
}
- (NSString *)group {
  return self->group;
}

/* factory */

- (Class)recordClassForKey:(NSString *)_key {
  return [SxTask class];
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  id obj;
  
  obj = [[self recordClassForKey:_key] alloc];
  obj = [obj initNewWithName:_key inFolder:self];
  [obj takeValue:[self group] forKey:@"group"];
  return [obj autorelease];;
}

/* DAV mappings */

- (BOOL)davHasSubFolders {
  /* task folders currently never have child folders */
  return NO;
}

/* rendering objects to a DAV dict */

- (id)mapJob:(id)_job {
  return [[[SxTask alloc] initWithEO:_job inFolder:self] autorelease];
}

- (NSArray *)mapJobs:(NSArray *)_jobs {
  NSMutableArray   *result;
  unsigned i, len;
  
  len    = [_jobs count];
  result = [NSMutableArray arrayWithCapacity:len];
  for (i = 0; i < len; i++) {
    id job;
    
    job = [_jobs objectAtIndex:i];
    job = [self mapJob:job];
    [result addObject:job];
  }
  return result;
}

/* fixed accessors for appointment folders */

- (NSString *)outlookFolderClass {
  return @"IPF.Task";
}

- (NSString *)davContentClass {
  return @"urn:content-classes:taskfolder";
}

- (int)mapiID_8112_int {
  return 3;
}
- (int)mapiID_8113_int {
  return 1;
}

#if 0
- (int)cdoRights {
  NSLog(@"################ [%s] ###############", __PRETTY_FUNCTION__);
  return 2043;
  /* frightsReadAny          0x001
   * frightsCreate           0x002
   * frightsEditOwned        0x008
   * frightsDeleteOwned      0x010
   * frightsEditAny          0x020
   * frightsDeleteAny        0x040
   * frightsCreateSubfolder  0x080
   * frightsOwner            0x100
   * frightsContact          0x200
   * frightsVisible          0x400
   */
}
#endif

- (NSString *)fileExtensionForFileSystem {
  return @"ics";
}

/* fetching */

- (SxTaskManager *)taskManagerInContext:(id)_ctx {
  SxTaskManager *m;
  m = [SxTaskManager managerWithContext:[self commandContextInContext:_ctx]];
  if (m == nil)
    [self logWithFormat:@"got no task manager for context: %@", _ctx];
  return m;
}

- (NSString *)getIDsAndVersionsInContext:(id)_ctx {
  SxTaskManager *tm;
  NSEnumerator  *tasks;
  NSMutableString *ms;
  id            task;
  unsigned      i = 0;

  if (self->idsAndVersions)
    return self->idsAndVersions;
  
  tm    = [self taskManagerInContext:_ctx];
  tasks = [tm listTasksOfGroup:[self group] type:[self type]];
  
  ms = [NSMutableString stringWithCapacity:128];
  while ((task = [tasks nextObject])) {
    i++;
    [ms appendFormat:@"%i:%i\n", 
          [[task objectForKey:@"jobId"] intValue],
          [[task objectForKey:@"objectVersion"] intValue]];
  }
  if ([self doExplainQueries])
    [self logWithFormat:@"[ids and versions] processing %i tasks", i];
  self->idsAndVersions = [ms retain];
  self->contentCount = i;
  return ms;
}
- (int)cdoContentCount {
  SxTaskManager *tm;
  int count;

  if (self->contentCount > 0)
    return self->contentCount;
  
  tm = [self taskManagerInContext:[[WOApplication application] context]];
  if ((count = [tm countTasksOfGroup:[self group] type:[self type]]) == -1) {
    [self logWithFormat:@"failed to fetch number of tasks .."];
    return 0;
  }
  if ([self doExplainQueries])
    [self logWithFormat:@"queried count attribute, deliver %i", count];
  self->contentCount = count;
  return count;
}

- (NSArray *)performListQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  id jobs;
  
  jobs = [[self taskManagerInContext:_ctx] 
	        listTasksOfGroup:[self group] type:[self type]];
  jobs = [[[NSArray alloc] initWithObjectsFromEnumerator:jobs] autorelease];
  jobs = [self mapJobs:jobs];
  return jobs;
}

- (NSArray *)performEvoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  EOQualifier *q;
  id jobs;
  
  if ((q = [_fs qualifier])) {
    /* qualifier=davLastModified > 1970-01-01T00:00:00Z */
    NSCalendarDate *modDate = nil;
    
    if ([q isKindOfClass:[EOKeyValueQualifier class]]) {
      if ([[(EOKeyValueQualifier *)q key] isEqualToString:@"davLastModified"])
	// TODO: check operation
	modDate = [(EOKeyValueQualifier *)q value];
    }
    if (modDate)
      [self logWithFormat:@"mod-date: %@", modDate];
    else
      [self logWithFormat:@"evolution query: %@", q];
  }
  
  jobs = [[self taskManagerInContext:_ctx] 
	        evoTasksOfGroup:[self group] type:[self type]];
  jobs = [[[NSArray alloc] initWithObjectsFromEnumerator:jobs] autorelease];
  jobs = [self mapJobs:jobs];
  return jobs;
}

- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* messages query */
  return [self performEvoQuery:nil inContext:_ctx];
}

- (NSArray *)performZideLookTaskQuery:(EOFetchSpecification *)_fs 
  inContext:(id)_ctx 
{
  [self logWithFormat:@"ZideLook task query"];
  return [self performEvoQuery:_fs inContext:_ctx];
}

- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)propNames
  inContext:(id)_ctx
{
  static NSSet *cadaverSet = nil;
  SEL handler = NULL;

  if (cadaverSet == nil)
    cadaverSet = [[self propertySetNamed:@"CadaverListSet"] copy];
  
  if ([propNames isSubsetOfSet:cadaverSet])
    return @selector(performListQuery:inContext:);
  if ([propNames isSubsetOfSet:
                 [self propertySetNamed:@"EvolutionTaskQuerySet"]])
    return @selector(performEvoQuery:inContext:);
  
  handler = [super fetchSelectorForQuery:_fs 
                   onAttributeSet:propNames 
                   inContext:_ctx];
  if (handler) return handler;
  
  if ([propNames isSubsetOfSet:[self propertySetNamed:@"ZideLookTaskQuery"]])
    handler = @selector(performZideLookTaskQuery:inContext:);
  
  return handler;
}

- (SEL)defaultFetchSelectorForZLQuery {
  return @selector(performZideLookTaskQuery:inContext:);
}

/* DAV default attributes (allprop queries by ZideLook ;-) */

- (id)davResourceType {
  static id coltype = nil;
  if (coltype == nil) {
    id tmp;
    tmp = [NSArray arrayWithObjects:@"vtodo-collection", @"GROUPWARE:", nil];
    coltype = [[NSArray alloc] initWithObjects:@"collection", tmp, nil];
  }
  return coltype;
}

- (NSString *)folderAllPropSetName {
  return @"DefaultTaskFolderProperties";
}

- (NSString *)entryAllPropSetName {
  return @"DefaultTaskProperties";
}

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  /* overridden for efficiency (caches array in static var) */
  static NSArray *defFolderNames = nil;
  static NSArray *defEntryNames  = nil;
  
  if (defFolderNames == nil) {
    defFolderNames =
      [[[self propertySetNamed:[self folderAllPropSetName]] allObjects] copy];
  }
  if (defEntryNames == nil) {
    defEntryNames =
      [[[self propertySetNamed:[self entryAllPropSetName]] allObjects] copy];
  }
  return [self isBulkQueryContext:_ctx] ? defEntryNames : defFolderNames;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  if (self->type)  [ms appendFormat:@" type=%@",  self->type];
  if (self->group) [ms appendFormat:@" group=%@", self->group];
  [ms appendString:@">"];
  return ms;
}

@end /* SxTaskFolder(Exchange) */
