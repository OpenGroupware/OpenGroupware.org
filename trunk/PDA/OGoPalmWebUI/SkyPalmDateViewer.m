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

#include "SkyPalmDateViewer.h"
#include <OGoPalm/SkyPalmDateDocument.h>
#import <Foundation/Foundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <NGExtensions/EOCacheDataSource.h>
#include <NGObjWeb/WOContext.h>
#include <NGObjWeb/WOResourceManager.h>
#include <NGExtensions/NSCalendarDate+misc.h>

#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmDateDocumentCopy.h>

@implementation SkyPalmDateViewer

- (id)init {
  if ((self = [super init])) {
    self->ds    = nil;
    self->state = nil;
    self->from  = nil;
    self->to    = nil;
    self->item  = nil;
    self->selections = [[NSMutableArray alloc] initWithCapacity:16];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->ds);
  RELEASE(self->state);
  RELEASE(self->from);
  RELEASE(self->to);
  RELEASE(self->item);
  RELEASE(self->selections);
  [super dealloc];
}
#endif

// overwriting
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmDate";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmDate";
}
- (NSString *)palmDb {
  return @"DatebookDB";
}
- (NSString *)entityName {
  return @"palm_date";
}

// accessors

- (void)setSelections:(NSMutableArray *)_sel {
  ASSIGN(self->selections,_sel);
}
- (NSMutableArray *)selections {
  return self->selections;
}
- (void)clearSelections {
  [self->selections removeAllObjects];
}
#if 0
- (void)syncSleep {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self clearSelections];
  [super syncSleep];
}
#endif

- (SkyPalmDateDocument *)date {
  return (SkyPalmDateDocument *)[self record];
}

- (void)setFrom:(NSString *)_from {
  ASSIGN(self->from,_from);
}
- (NSString *)from {
  if (self->from == nil) {
    self->from =
      [(NSCalendarDate *)[NSCalendarDate date]
                         descriptionWithCalendarFormat:@"%Y-%m-%d"];
    RETAIN(self->from);
  }
  return self->from;
}
- (void)setTo:(NSString *)_to {
  ASSIGN(self->to,_to);
}
- (NSString *)to {
  if (self->to == nil) {
    self->to =
      [(NSCalendarDate *)[NSCalendarDate date]
                       descriptionWithCalendarFormat:@"%Y-%m-%d"];
    RETAIN(self->to);
  }
  return self->to;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}
// formating to dates

- (NSCalendarDate *)fromDate {
  NSCalendarDate *d = [NSCalendarDate dateWithString:[self from]
                                      calendarFormat:@"%Y-%m-%d"];
  return (d == nil)
    ? [(NSCalendarDate *)[NSCalendarDate date] beginOfDay]
    : [d beginOfDay];
}
- (NSCalendarDate *)toDate {
  NSCalendarDate *d = [NSCalendarDate dateWithString:[self to]
                                      calendarFormat:@"%Y-%m-%d"];
  return (d == nil)
    ? [(NSCalendarDate *)[NSCalendarDate date] endOfDay]
    : [d endOfDay];
}

// repeatings
- (LSCommandContext *)_context {
  return [(id)[self session] commandContext];
}

- (EOCacheDataSource *)repeatingsDataSource {
  if (self->ds == nil) {
    id d =
      [SkyPalmEntryDataSource dataSourceWithContext:[self _context]
                              forPalmDb:[self palmDb]];
    self->ds = [[EOCacheDataSource alloc] initWithDataSource:d];
  }
  return self->ds;
}

- (SkyPalmEntryListState *)repeatingsState {
  if (self->state == nil) {
    id companyId = [[self date] companyId];
    id ud        = [[self session] userDefaults];
    self->state =
      [SkyPalmEntryListState listStateWithDefaults:ud
                             companyId:companyId
                             subKey:@"PalmDateViewer"
                             forPalmDb:[self palmDb]];
    RETAIN(self->state);
    [self->state takeValue:[self fromDate] forKey:@"startdate"];
    [self->state takeValue:[self toDate]   forKey:@"enddate"];
    [self->state takeValue:
         [NSArray arrayWithObject:[[self date] valueForKey:@"palmId"]]
         forKey:@"palmIds"];
  }
  return self->state;
}

// calendar support
- (NSString *)calendarPageURL {
  WOResourceManager *rm;
  NSString *url;
  
  rm = [(id)[WOApplication application] resourceManager];
  
  url = [rm urlForResourceNamed:@"calendar.html"
            inFramework:nil
            languages:[[self session] languages]
            request:[[self context] request]];
  
  if (url == nil) {
    [self debugWithFormat:@"couldn't locate calendar page"];
    url = @"/Skyrix.woa/WebServerResources/English.lproj/calendar.html";
  }

  return url;
}
- (NSString *)_dateOnClickEvent:(NSString *)_date {
  return
    [NSString stringWithFormat:
              @"setDateField(document.editform.%@);"
              @"top.newWin=window.open('%@','cal','WIDTH=208,HEIGHT=230')",
              _date,
              [self calendarPageURL]];
}
- (NSString *)fromOnClickEvent {
  return [self _dateOnClickEvent:@"from"];
}
- (NSString *)toOnClickEvent {
  return [self _dateOnClickEvent:@"to"];
}

// actions
- (id)viewRepeating {
  return [[[self session] navigation] activateObject:[self item]
                                      withVerb:@"view"];
}
- (id)showRepeatings {
  [self->state takeValue:[self fromDate] forKey:@"startdate"];
  [self->state takeValue:[self toDate]   forKey:@"enddate"];
  [(id)[self repeatingsDataSource]
       setFetchSpecification:[self->state fetchSpecification]];
  [self clearSelections];
  return nil;
}

// selection actions

- (id)selectionDetach {
  NSEnumerator *e  = nil;
  id           one = nil;

  e = [self->selections objectEnumerator];
  while ((one = [e nextObject])) {
    one = [one detachFromOrigin];
    // save new entry
    [one save];
  }

  [self clearSelections];
  [[self date] reload];

  return nil;
}

- (id)selectionDelete {
  NSEnumerator *e  = nil;
  id           one = nil;

  e = [self->selections objectEnumerator];
  while ((one = [e nextObject])) {
    [one detachFromOrigin]; // drop new entry
  }

  [self clearSelections];
  [[self date] reload];
  
  return nil;
}

- (id)viewSkyrixRecord {
  id gid = nil;

  gid = [[[self record] skyrixRecord] valueForKey:@"globalID"];

  if (gid) {
    [[self session] transferObject:gid owner:self];
    [self executePasteboardCommand:@"view"];
  }

  return nil;
}

@end /* SkyPalmDateViewer */
