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

#include "SkyJobHistoryDataSource.h"
#include "common.h"
#include "SkyJobHistoryDocument.h"

@interface SkyJobHistoryDataSource(PrivateMethodes)
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
@end
  
@implementation SkyJobHistoryDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initWithContext:(id)_ctx jobId:(EOGlobalID *)_gid {
  if (_ctx == nil) {
    [self logWithFormat:@"missing context for datasource!"];
    [self release];
    return nil;
  }
  if (_gid == nil) {
    [self logWithFormat:@"missing job global-id for datasource!"];
    [self release];
    return nil;
  }
  
  if ((self = [super init])) {
    self->context  = [_ctx retain];
    self->jobId    = [_gid retain];
  }
  return self;
}

- (id)initWithContext:(id)_ctx {
  return [self initWithContext:_ctx jobId:nil];
}
- (id)init {
  return [self initWithContext:nil jobId:nil];
}

- (void)dealloc {
  [self->fetchSpecification release];
  [self->jobId              release];
  [self->context            release];
  [self->lastException      release];
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

- (NSException *)_processFetchException:(NSException *)_exception {
  ASSIGN(self->lastException, _exception);
  return nil;
}
- (NSArray *)fetchObjects {
  NSArray     *sortOrderings = nil;
  EOQualifier *qualifier     = nil;
  NSArray  *histories;
  id       job;

  /* could introduce hint to set this dynamically .. */
  if (self->jobId == nil)
    return nil;
  
  NS_DURING {
    job = [[self->context runCommand:@"job::get-by-globalid",
            @"gid", self->jobId, nil] lastObject];
    
    NSAssert1(job, @"couldn't get Job for gid %@", self->jobId);
    
    [self->context runCommand:@"job::get-job-history",
         @"object", job,
         @"relationKey", @"jobHistory", nil];
    
    histories = [job valueForKey:@"jobHistory"];
  }
  NS_HANDLER {
    *(&histories) = nil;
    [[self _processFetchException:localException] raise];
  }
  NS_ENDHANDLER;
  
  histories = [self _morphEOsToDocuments:histories];

  if ((qualifier = [self ->fetchSpecification qualifier]))
    histories = [histories filteredArrayUsingQualifier:qualifier];

  if ((sortOrderings = [self->fetchSpecification sortOrderings]))
    histories = [histories sortedArrayUsingKeyOrderArray:sortOrderings];
  
  return histories;
}

/* operations */

- (id)createObject {
  return nil;
}

- (void)insertObject:(id)_object {
  [self logWithFormat:@"%s: method not implemented for this datasource!",
	  __PRETTY_FUNCTION__];
#if LIB_FOUNDATION_LIBRARY
  [self notImplemented:_cmd];
#endif
}
- (void)deleteObject:(id)_object {
  [self logWithFormat:@"%s: method not implemented for this datasource!",
	  __PRETTY_FUNCTION__];
#if LIB_FOUNDATION_LIBRARY
  [self notImplemented:_cmd];
#endif
}

- (void)updateObject:(id)_object {
  [self logWithFormat:@"%s: method not implemented for this datasource!",
	  __PRETTY_FUNCTION__];
#if LIB_FOUNDATION_LIBRARY
  [self notImplemented:_cmd];
#endif
}

/* morphing EOs */

- (Class)jobHistoryDocumentClass {
  static Class clazz = Nil;
  if (clazz == Nil) clazz = [SkyJobHistoryDocument class];
  return clazz;
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  unsigned i, count;
  NSMutableArray *result;

  if (_eos == nil) 
    return nil;
  if ((count = [_eos count]) == 0) 
    return [NSArray array];
  
  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id doc;
    id jobHistory;
    
    jobHistory = [_eos objectAtIndex:i];
    
    doc = [[[self jobHistoryDocumentClass] alloc] 
	          initWithEO:jobHistory dataSource:self];
    [result addObject:doc];
    [doc release];
  }
  return result;
}

@end /* SkyJobHistoryDataSource */
