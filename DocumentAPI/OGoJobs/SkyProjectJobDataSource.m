/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyProjectJobDataSource.h"
#include "SkyJobDocument.h"
#include "common.h"

@interface SkyProjectJobDataSource(PrivateMethodes)
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
- (NSString *)_typeFromQualifier;
- (void)notImplemented:(SEL)_sel;
@end
  
@implementation SkyProjectJobDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initWithContext:(id)_ctx projectId:(EOGlobalID *)_gid {
  NSAssert(_ctx, @"missing context for datasource !");
  NSAssert(_gid, @"missing Project gid for datasource !");
  
  if ((self = [super init])) {
    self->context   = [_ctx retain];
    self->projectId = [_gid retain];
  }
  return self;
}
- (id)initWithContext:(id)_ctx {
  return [self initWithContext:_ctx projectId:nil];
}
- (id)init {
  return [self initWithContext:nil projectId:nil];
}

- (void)dealloc {
  [self->fetchSpecification release];
  [self->projectId     release];
  [self->context       release];
  [self->lastException release];
  
  [super dealloc];
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

- (NSArray *)_postProcessFetchResult:(NSArray *)jobs {
  NSArray     *sortOrderings;
  EOQualifier *qualifier;
  
  if ([jobs count] == 0)
    return jobs;
  
  if ((qualifier = [self->fetchSpecification qualifier]) != nil)
    jobs = [jobs filteredArrayUsingQualifier:qualifier];

  if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
    jobs = [jobs sortedArrayUsingKeyOrderArray:sortOrderings];

  jobs = [self _morphEOsToDocuments:jobs];
  
  return jobs;
}
- (NSArray *)fetchObjects {
  NSArray  *jobs;
  id       project;

  /* could introduce hint to set this dynamically .. */
  if (self->projectId == nil)
    return nil;
  
  NS_DURING {
    project =
      [[self->context runCommand:@"project::get-by-globalid",
            @"gid", self->projectId, nil] lastObject];
    
    NSAssert1(project, @"couldn't get Project for gid %@", self->projectId);
    
    jobs = [self->context runCommand:@"project::get-jobs",
                          @"object", project, nil];

    [self->context runCommand:@"job::get-job-executants",
         @"objects",    jobs,
         @"relationKey", @"executant", nil];
  }
  NS_HANDLER {
    *(&jobs) = nil;
    ASSIGN(self->lastException, localException);
  }
  NS_ENDHANDLER;
  
  return [self _postProcessFetchResult:jobs];
}

/* operations */

- (id)createObject {
  return nil;
}

- (void)insertObject:(id)_object {
  [self notImplemented:_cmd];
}
- (void)deleteObject:(id)_object {
  [self notImplemented:_cmd];
}

- (void)updateObject:(id)_object {
  [self notImplemented:_cmd];
}

/* PrivateMethodes */

- (Class)jobDocumentClass {
  static Class docClass = Nil;
  if (docClass == Nil)
    docClass = [SkyJobDocument class];
  return docClass;
}
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  NSMutableArray *result;
  unsigned i, count;

  if (_eos == nil)                 return nil;
  if ((count = [_eos count]) == 0) return [NSArray array];
  
  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    SkyJobDocument *doc;
    id job;
    
    job = [_eos objectAtIndex:i];
    
    doc = [[[self jobDocumentClass] alloc] initWithEO:job dataSource:self];
    if (doc == nil)
      continue;
    
    [result addObject:doc];
    [doc release];
  }
  return result;
}

- (NSString *)_typeFromKeyValueQualifier:(EOKeyValueQualifier *)qual {
  return ([[qual key] isEqualToString:@"type"]) ? [qual value] : nil;
}
- (NSString *)_typeFromArrayQualifier:(id)qual {
  NSArray *quals;
  int     i, cnt;
  
  quals = [(id)qual qualifiers];
  cnt = [quals count];
  for (i = 0; i < cnt; i++) {
    EOKeyValueQualifier *qual = [quals objectAtIndex:i];

    if ([[qual key] isEqualToString:@"type"])
      return [qual value];
  }
  return nil;
}
- (NSString *)_typeFromQualifier {
  EOQualifier *qual;
  
  if ((qual = [self->fetchSpecification qualifier]) == nil)
    return nil;
  
  if ([qual isKindOfClass:[EOKeyValueQualifier class]])
    return [self _typeFromKeyValueQualifier:(id)qual];
  
  if ([qual isKindOfClass:[EOOrQualifier class]] ||
      [qual isKindOfClass:[EOAndQualifier class]])
    return [self _typeFromArrayQualifier:qual];
  
  return nil;
}

@end /* SkyProjectJobDataSource */
