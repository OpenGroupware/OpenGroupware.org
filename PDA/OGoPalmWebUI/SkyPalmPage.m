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

#include "SkyPalmPage.h"

#include "common.h"
#include <NGMime/NGMime.h>

@interface OGoSession(SkyPalmPage)
- (NSNotificationCenter *)notificationCenter;
@end

@implementation SkyPalmPage

- (id)init {
  id p;

  if ((p = [self persistentInstance])) {
    RELEASE(self);
    return RETAIN(p);
  }
  
  if ((self = [super init])) {
    NSNotificationCenter *nc     = nil;

    [self registerAsPersistentInstance];

    self->addresses = nil;
    self->dates     = nil;
    self->memos     = nil;
    self->jobs      = nil;

    nc = [(id)[self session] notificationCenter];
    [nc addObserver:self selector:@selector(noteDateChange:)
        name:@"LSWNewPalmDate" object:nil];
    [nc addObserver:self selector:@selector(noteDateChange:)
        name:@"LSWUpdatedPalmDate" object:nil];
    [nc addObserver:self selector:@selector(noteDateChange:)
        name:@"LSWDeletedPalmDate" object:nil];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [self unregisterAsObserver];
  RELEASE(self->addresses);
  RELEASE(self->dates);
  RELEASE(self->memos);
  RELEASE(self->jobs);
  [super dealloc];
}
#endif

- (void)noteDateChange:(NSString *)_cn {
  [self->dates clear];
}

/* accessors */

- (void)setSelectedTab:(NSString *)_tab {
  [[[self session] userDefaults] setObject:_tab
                                 forKey:@"SkyPalmPage_tab"];
}
- (NSString *)selectedTab {
  NSString *tab = [[[self session] userDefaults]
                          valueForKey:@"SkyPalmPage_tab"];
  if (![tab length]) {
    [self setSelectedTab:@"address"];
    return (NSString *)@"address";
  }
  return tab;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

// context
- (LSCommandContext *)_context {
  return [(id)[self session] commandContext];
}

- (EOCacheDataSource *)addressDataSource {
  if (self->addresses == nil) {
    id ds =
      [SkyPalmEntryDataSource dataSourceWithContext:[self _context]
                              forPalmDb:@"AddressDB"];
    self->addresses = [[EOCacheDataSource alloc] initWithDataSource:ds];
  }
  return self->addresses;
}
- (EOCacheDataSource *)dateDataSource {
  if (self->dates == nil) {
    id ds = 
      [SkyPalmEntryDataSource dataSourceWithContext:[self _context]
                              forPalmDb:@"DatebookDB"];
    self->dates = [[EOCacheDataSource alloc] initWithDataSource:ds];
  }
  return self->dates;
}
- (SkyPalmEntryDataSource *)memoDataSource {
  if (self->memos == nil) {
    self->memos =
      [SkyPalmEntryDataSource dataSourceWithContext:[self _context]
                              forPalmDb:@"MemoDB"];
    RETAIN(self->memos);
  }
  return self->memos;
}
- (SkyPalmEntryDataSource *)jobDataSource {
  if (self->jobs == nil) {
    self->jobs =
      [SkyPalmEntryDataSource dataSourceWithContext:[self _context]
                              forPalmDb:@"ToDoDB"];
    RETAIN(self->jobs);
  }
  return self->jobs;
}

// actions
- (id)addressTabClicked {
  [[self addressDataSource] clear];
  return nil;
}
- (id)dateTabClicked {
  [[self dateDataSource] clear];
  return nil;
}
- (id)memoTabClicked {
  //  [[self memoDataSource] clear];
  return nil;
}
- (id)todoTabClicked {
  //  [[self jobDataSource] clear];
  return nil;
}

#if 0
// takeValuesFromRequest
- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [super takeValuesFromRequest:_req inContext:_ctx];
  NSLog(@"%s ..done", __PRETTY_FUNCTION__);
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [super appendToResponse:_response inContext:_ctx];
  NSLog(@"%s done", __PRETTY_FUNCTION__);
}
#endif


@end
