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

#include "SkyPersonJobDataSource.h"
#include "common.h"
#include "SkyJobDocument.h"

@interface SkyPersonJobDataSource(PrivateMethodes)
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos withType:(NSString *)_types;
- (NSString *)_typeFromQualifier;
- (EOQualifier *)_filteredQualifier;
- (NSArray *)_makeGIDsFromIDs:(NSArray *)_ids;
@end

@interface SkyJobDocument(SkyPersonJobDataSource)
- (void)_setGlobalID:(id)_gid; // set globalID after insertObject
@end

@implementation SkyPersonJobDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initWithContext:(id)_ctx personId:(EOGlobalID *)_gid {
  NSAssert(_ctx, @"missing context for datasource !");
  NSAssert(_gid, @"missing Person gid for datasource !");
  
  if ((self = [super init])) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(noteChange:)
        name:SkyNewJobNotification object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name:SkyUpdatedJobNotification object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name:SkyDeletedJobNotification object:nil];
    
    self->context  = [_ctx retain];
    self->personId = [_gid retain];
  }
  return self;
}
- (id)initWithContext:(id)_ctx {
  return [self initWithContext:_ctx
               personId:[[_ctx valueForKey:LSAccountKey] globalID]];
}
- (id)init {
  return [self initWithContext:nil personId:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->fetchSpecification release];
  [self->personId           release];
  [self->context            release];
  [self->lastException      release];
  [super dealloc];
}

- (void)noteChange:(NSNotification *)_notification {
  [self postDataSourceChangedNotification];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if ([self->fetchSpecification isEqual:_fSpec])
    return;

  ASSIGNCOPY(self->fetchSpecification, _fSpec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (id)context {
  return self->context;
}

/* fetching */

- (NSString *)commandNameForType:(NSString *)_type {
  if ([_type isEqualToString:@"toDoJob"])
    return @"job::get-todo-jobs";
  if ([_type isEqualToString:@"controlJob"])
    return @"job::get-control-jobs";
  if ([_type isEqualToString:@"delegatedJob"])
    return @"job::get-delegated-jobs";
  if ([_type isEqualToString:@"archivedJob"])
    return @"job::get-archived-jobs";
  if ([_type isEqualToString:@"palmJob"])
    return @"job::get-palm-jobs";
  
  return nil;
}

- (NSArray *)fetchObjects {
  NSArray      *jobs;
  NSString     *cmdName;
  NSString     *type;
  NSDictionary *hints;
  id           person;
  BOOL         returnGlobalIds;

  type            = [self _typeFromQualifier];
  hints           = [self->fetchSpecification hints];
  returnGlobalIds = [[hints objectForKey:@"fetchGlobalIDs"] boolValue];
  
  /* could introduce hint to set this dynamically .. */
  if (self->personId == nil)
    return nil;
  
  if ((cmdName = [self commandNameForType:type]) == nil)
    return [NSArray array];
  
  NS_DURING {
    person =
      [[self->context runCommand:@"person::get-by-globalid",
            @"gid", self->personId, nil] lastObject];

    
    NSAssert1(person, @"could not get Person for gid %@", self->personId);
    
    jobs = [self->context runCommand:cmdName, @"object", person, nil];

    if (!returnGlobalIds) {
      [self->context runCommand:@"job::get-job-executants",
           @"objects",    jobs,
           @"relationKey", @"executant", nil];
    }
  }
  NS_HANDLER {
    *(&jobs) = nil;
    ASSIGN(self->lastException, localException);
  }
  NS_ENDHANDLER;

  if (returnGlobalIds)
    return [self _makeGIDsFromIDs:jobs];

  {
    NSArray     *sortOrderings = nil;
    EOQualifier *qualifier     = nil;

    jobs = [self _morphEOsToDocuments:jobs withType:type];

    if ((qualifier = [self _filteredQualifier]) != nil)
      jobs = [jobs filteredArrayUsingQualifier:qualifier];

    if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
      jobs = [jobs sortedArrayUsingKeyOrderArray:sortOrderings];
  }

  return jobs;
}

/* operations */

- (id)createObject {
  SkyJobDocument      *doc  = nil;
  EOKeyGlobalID       *gid;
  NSMutableDictionary *dict;
  NSCalendarDate *now;
  
  gid  = [[self->context valueForKey:LSAccountKey] valueForKey:@"globalID"];
  now  = [NSCalendarDate date];
  dict =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         @"",                   @"name",
                         now,                   @"startDate",
                         now,                   @"endDate",
                         @"",                   @"category",
                         @"00_created",         @"jobStatus",
                         [NSNumber numberWithInt:3], @"priority",
                         [gid keyValues][0],    @"executantId",
                         nil];
  doc = [[SkyJobDocument alloc] initWithJob:dict globalID:nil dataSource:self];
  return [doc autorelease];
}

- (void)insertObject:(id)_object {
  NSDictionary *dict;

  dict = [self->context runCommand:@"job::new" arguments:[_object asDict]];
  [_object _setGlobalID:[dict valueForKey:@"globalID"]];
  [self postDataSourceChangedNotification];
}

- (void)deleteObject:(id)_object {
  EOGlobalID *gid;
  id jobEO;
  
  gid   = [_object globalID];
  jobEO = [self->context runCommand:@"job::get-by-globalid", @"gid", gid, nil];
  
  [self->context runCommand:@"job::delete", 
       @"object",       jobEO,
       @"reallyDelete", [NSNumber numberWithBool:YES], nil];
  
  [self postDataSourceChangedNotification];
}

- (void)updateObject:(id)_object {
  NSDictionary *dict;
  
  if (![_object isComplete])
    // TODO: should throw/set exception?!
    return;
  
  dict = [_object asDict];
  [self->context runCommand:@"job::set" arguments:dict];
  [self postDataSourceChangedNotification];
}

/* SubClassing */

- (NSString *)_typeFromQualifier {
  EOQualifier *qual = [self->fetchSpecification qualifier];
  int         i, cnt;

  if (qual == nil)
    return nil;

  if ([qual isKindOfClass:[EOKeyValueQualifier class]]) {
    return ([[(EOKeyValueQualifier *)qual key] isEqualToString:@"type"])
      ? [(EOKeyValueQualifier *)qual value]
      : nil;
  }
  
  if ([qual isKindOfClass:[EOOrQualifier class]] ||
      [qual isKindOfClass:[EOAndQualifier class]]) {
    NSArray *quals = [(id)qual qualifiers];

    cnt = [quals count];
    for (i=0; i<cnt; i++) {
      EOKeyValueQualifier *qual = [quals objectAtIndex:i];

      if ([[qual key] isEqualToString:@"type"])
        return [qual value];
    }
  }
  return nil;
}

- (NSArray *)_makeGIDsFromIDs:(NSArray *)_ids {
  NSMutableArray *gids;
  int            i, cnt;
  
  cnt  = [_ids count];
  gids = [NSMutableArray arrayWithCapacity:cnt];
  
  for (i = 0; i < cnt; i++) {
    id obj;
    id values[1];
    EOGlobalID *gid;

    obj       = [_ids objectAtIndex:i];
    values[0] = [obj valueForKey:@"jobId"];
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Job"
                         keys:values keyCount:1 zone:NULL];
    [gids addObject:gid];
  }
  return gids;  
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos withType:(NSString *)_type {
  unsigned i, count;
  NSMutableArray *result;

  if (_eos == nil)                 return nil;
  if ((count = [_eos count]) == 0) return [NSArray array];
  
  result = [NSMutableArray arrayWithCapacity:(count + 1)];

  for (i = 0; i < count; i++) {
    id doc;
    id job;
    
    job = [_eos objectAtIndex:i];
    if (_type)
      [job takeValue:_type forKey:@"type"];
    
    doc = [[SkyJobDocument alloc] initWithEO:job dataSource:self];
    [result addObject:doc];
    [doc release];
  }
  return result;
}

- (EOQualifier *)_filteredQualifier {
  static Class keyValueQualClass = Nil;
  EOQualifier *qual;

  if (keyValueQualClass == Nil)
    keyValueQualClass = [EOKeyValueQualifier class];

  qual = [self->fetchSpecification qualifier];
  if ([qual isKindOfClass:keyValueQualClass])
    return [[(id)qual key] isEqualToString:@"type"] ? (EOQualifier *)nil :qual;

  return qual;
}

@end /* SkyPersonJobDataSource */
