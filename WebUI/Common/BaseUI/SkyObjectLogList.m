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

#include <OGoFoundation/OGoComponent.h>

/*
  Example:
  
    LogList: SkyObjectLogList {
      object = person; // display logs of that object
    }
*/
    

@class NSArray;
@class SkyLogDataSource;

@interface SkyObjectLogList : OGoComponent
{
@protected
  NSArray  *logs;
  id       log;
  id       object; // non-retained (hh asks: why not?)
  
  unsigned startIndex;
  BOOL     fetchLogs;
  BOOL     isDescending;
  id       selectedAttribute;
  
  SkyLogDataSource *dataSource; // <> or object must be defined
}

- (void)setObject:(id)_object;
- (id)object;

@end

#include "common.h"
#include <OGoFoundation/WOComponent+Commands.h>
#include <OGoFoundation/NSObject+Commands.h>
#include <OGoBase/SkyLogDataSource.h>

@implementation SkyObjectLogList

static NSNumber *noN = nil;

+ (void)initialize {
  if (noN == nil)
    noN = [[NSNumber alloc] initWithBool:NO];
}

- (id)init {
  if ((self = [super init])) {
    self->fetchLogs    = YES;
    self->isDescending = YES;
    self->dataSource   = nil;
  }
  return self;
}

- (void)dealloc {
  [self->logs       release];
  [self->log        release];
  [self->dataSource release];
  [self->selectedAttribute release];
  [super dealloc];
}

/* accessors */

- (void)setObject:(id)_object {
  self->object = _object;
}
- (id)object {
  return self->object;
}

- (void)setDataSource:(SkyLogDataSource *)_dataSource {
  ASSIGN(self->dataSource,_dataSource);
}
- (SkyLogDataSource *)dataSource {
  return self->dataSource;
}

- (void)setLogs:(NSArray *)_logs {
  ASSIGN(self->logs, _logs);
}
- (NSArray *)logs {
  return self->logs;
}

- (void)setLog:(id)_log {
  ASSIGN(self->log, _log);
}
- (id)log {
  return self->log;
}

- (void)setSelectedAttribute:(id)_val {
  ASSIGN(self->selectedAttribute, _val);
}
- (id)selectedAttribute {
  return self->selectedAttribute;
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

/* fetching */

- (void)_fetchLogs {
  static Class DocumentClass = Nil;
  id      obj;
  NSArray *a;

  obj = self->object;

  if (self->dataSource == nil) {
    NSAssert((obj != nil), @"No object is set");

    if (DocumentClass == Nil)
      DocumentClass = NGClassFromString(@"SkyDocument");

    if ([obj isKindOfClass:DocumentClass]) {
      obj = [[self runCommand:@"object::get-by-globalid",
                   @"gid", [obj globalID], nil] lastObject];
    }

    a = [self runCommand:@"object::get-logs", @"object", obj, nil];
  
    [self setLogs:a];

    //NSLog(@"%s logs: %@:", __PRETTY_FUNCTION__, self->logs);
    
    [self runCommand:@"log::set-actor",
          @"relationKey", @"actor",
          @"objects",     self->logs, nil];
    //    NSLog(@"%s logs: %@:", __PRETTY_FUNCTION__, self->logs);

  }
  else {
    NSAssert((obj == nil), @"Object and dataSource set!");

    [self setLogs:[self->dataSource fetchObjects]];
  }
  self->fetchLogs = NO;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  
  if (self->fetchLogs)
    [self _fetchLogs];
}

- (void)syncSleep {
  self->fetchLogs = YES;
  [self->logs release]; self->logs = nil;
  [self->log  release]; self->log  = nil;
  self->startIndex = 0;
  
  [super syncSleep];
}

/* accessors */

- (NSNumber *)isActorArchived {
  return (self->dataSource == nil)
    ? [NSNumber numberWithBool:
                [[[[self log] valueForKey:@"actor"] valueForKey:@"dbStatus"]
                         isEqualToString:@"archived"]]
    : noN;
}

@end /* SkyObjectLogList */
