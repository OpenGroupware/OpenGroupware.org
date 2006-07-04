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

#include "SkyAptCompoundDataSource.h"
#include "SkyAptDataSource.h"
#include "common.h"
#include <NGExtensions/EODataSource+NGExtensions.h>

@interface SkyAptCompoundDataSource(PrivateMethods)
- (EODataSource *)buildSkyAptDataSource;
- (EODataSource *)buildPalmDateDataSource;
@end

@implementation SkyAptCompoundDataSource

- (id)init {
  if ((self = [super init])) {
    //    EODataSource   *ds      = nil;

    //    ASSIGN(self->ctx,_ctx);
    self->fetchSpec = nil;
    
    //    ds = [self buildSkyAptDataSource];
    //    if (ds != nil)
    //      [sources addObject:ds];
    //    ds = [self buildPalmDateDataSource];
    //    if (ds != nil)
    //      [sources addObject:ds];
    
    self->source =
      [[EOCompoundDataSource alloc] initWithDataSources:[NSArray array]];
    //    NSLog(@"<SkyAptCompoundDataSource> has following dataSources: %@",
    //          [self->source sources]);;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->source);
  //  RELEASE(self->ctx);
  RELEASE(self->fetchSpec);
  [super dealloc];
}
#endif

// helper
- (Class)palmDateDataSourceClass {
  return NSClassFromString(@"SkyPalmDateDataSource");
}
- (Class)skyAptDataSourceClass {
  return [SkyAptDataSource class];
}

#if 0
// building dataSoures
- (EODataSource *)buildSkyAptDataSource {
  SkyAptDataSource *ds = [[SkyAptDataSource alloc] init];
  [ds setContext:self->ctx];
  
  return ds;
}
- (EODataSource *)buildPalmDateDataSource {
  Class        c   = [self palmDateDataSourceClass];
  EODataSource *ds = nil;

  NSLog(@"Class : %@", c);
  ds = [[c alloc] initWithContext:self->ctx];
  NSLog(@"DataSource: %@", ds);
  return AUTORELEASE(ds);
}
#endif

- (void)addSource:(EODataSource *)_ds {
  NSArray *sources = [self->source sources];
  if (_ds != nil)
    [self->source setSources:[sources arrayByAddingObject:_ds]];
}

// overwriting

- (void)setFetchSpecification:(EOFetchSpecification *)_spec {
  NSEnumerator *e = [[self->source sources] objectEnumerator];
  EODataSource *d = nil;

  ASSIGN(self->fetchSpec,_spec);

  while ((d = [e nextObject])) {
    [d setFetchSpecification:_spec];
  }
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpec;
}

- (NSArray *)fetchObjects {
  NSArray *objs = [self->source fetchObjects];
  return (objs == nil) ? (NSArray *)[NSArray array] : objs;
}

// SkyScheduler support
- (NSArray *)companies {
  NSMutableArray *cs = [NSMutableArray array];
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(companies)])
      [cs addObjectsFromArray:[d companies]];
  }
  return cs;
}

- (NSArray *)resources {
  NSMutableArray *rs = [NSMutableArray array];
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(resources)])
      [rs addObjectsFromArray:[d resources]];
  }
  return rs;
}

- (void)setIsResCategorySelected:(BOOL)_flag {
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(setIsResCategorySelected:)])
      [d setIsResCategorySelected:_flag];
  }
}
- (BOOL)isResCategorySelected {
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(isResCategorySelected)])
      if ([d isResCategorySelected])
        return YES;
  }
  return NO;
}

- (void)clear {
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(clear)])
      [d clear];
  }
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(setTimeZone:)])
      [d setTimeZone:_tz];
  }
}
- (NSTimeZone *)timeZone {
  NSEnumerator   *e  = [[self->source sources] objectEnumerator];
  id             d   = nil;

  while ((d = [e nextObject])) {
    if ([d respondsToSelector:@selector(timeZone)])
        return [d timeZone];
  }
  return nil;
}

@end /* SkyAptCompoundDataSource */
