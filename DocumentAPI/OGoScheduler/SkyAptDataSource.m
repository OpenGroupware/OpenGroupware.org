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

#include "SkyAptDataSource.h"
#include "SkyAppointmentQualifier.h"
#include "SkyAppointmentDocument.h"
#include <LSFoundation/OGoContextSession.h>
#include "common.h"

@interface NSObject(Gid)
- (EOGlobalID *)globalID;
@end

@interface SkyAptDataSource(PrivateMethods)
- (void)primaryClear;
- (void)clear;
- (id)objects;
@end

@interface SkyAppointmentDocument(SkyAptDataSource)
- (void)_setGlobalID:(id)_gid;
@end

@implementation SkyAptDataSource

static NSNumber *yesNum = nil;

+ (void)initialize {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (void)_registerForNotifications {
    NSNotificationCenter *nc = nil;

    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(noteChange:)
        name: SkyNewAppointmentNotification object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name: SkyUpdatedAppointmentNotification object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name: SkyDeletedAppointmentNotification object:nil];
}

- (id)init {
  if ((self = [super init])) {
    self->sortOrderings = [[NSArray alloc] init];
    [self _registerForNotifications];
  }
  return self;
}
- (id)initWithContext:(id)_ctx {
  if ((self = [self init])) {
    [self setContext:_ctx];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self primaryClear];

  [self->lso         release];
  [self->q           release]; 
  [self->attributes  release];
  [self->objects     release];
  [self->gidsToFetch release];
  [super dealloc];
}

/* notifications */

- (void)noteChange:(NSNotification *)_notification {
  [self clear];
  [self postDataSourceChangedNotification];
}

/* query accessors */

- (void)setIsResCategorySelected:(BOOL)_flag {
  self->isResCategorySelected = _flag;
}
- (BOOL)isResCategorySelected {
  return self->isResCategorySelected;
}

- (void)setContext:(id)_ctx {
  if ([_ctx isKindOfClass:[OGoContextSession class]]) {
    _ctx = [_ctx commandContext];
    ASSIGN(self->lso, _ctx);
  }
  else {
    ASSIGN(self->lso, _ctx);
  }
}
- (id)context {
  return self->lso;
}

- (NSTimeZone *)timeZone {
  return [self->q timeZone];
}
- (NSArray *)companies {
  return [self->q companies];
}
- (NSArray *)resources {
  return [self->q resources];
}
- (NSCalendarDate *)startDate {
  return [self->q startDate];
}
- (NSCalendarDate *)endDate {
  return [self->q endDate];
}

- (void)setQualifier:(SkyAppointmentQualifier *)_qual {
  if (self->q == _qual)
    return;
  
  ASSIGN(self->q, _qual);
}
- (SkyAppointmentQualifier *)qualifier {
  return self->q;
}

- (void)setAttributes:(NSArray *)_attrs {
  if ([self->attributes isEqual:_attrs]) {
    return;
  }
  ASSIGN(self->attributes, _attrs);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setSortOrderings:(NSArray *)_so {
  ASSIGN(self->sortOrderings,_so);
}
- (NSArray *)sortOrderings {
  return self->sortOrderings;
}

/* fetching */

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  [self setQualifier:(SkyAppointmentQualifier *)[_fspec qualifier]];
  [self setSortOrderings:[_fspec sortOrderings]];
  [self setAttributes:[[_fspec hints] objectForKey:@"attributeKeys"]];
  self->returnDocuments =
    [[[_fspec hints] objectForKey:@"SkyReturnDocs"] boolValue];

  RELEASE(self->gidsToFetch);
  self->gidsToFetch = 
    [[_fspec hints] objectForKey:@"FetchGIDs"];
  RETAIN(self->gidsToFetch);
  
  [self clear];
  [self postDataSourceChangedNotification];
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *f     = nil;
  NSMutableDictionary  *hints = nil;
    
  f = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                            qualifier:[self qualifier]
                            sortOrderings:[self sortOrderings]];
  hints = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [self attributes], @"attributeKeys",
                        nil];
  
  if (self->returnDocuments) {
    [hints setObject:yesNum forKey:@"SkyReturnDocs"];
  }
  if (self->gidsToFetch != nil)
    [hints setObject:self->gidsToFetch forKey:@"FetchGIDs"];
  [f setHints:hints];
  return f;
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  unsigned i, count;
  NSMutableArray *result;

  if (_eos == nil)                 return nil;
  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id doc;
    id apt;
    
    apt = [_eos objectAtIndex:i];

    doc = [[SkyAppointmentDocument alloc] initWithEO:apt dataSource:self];
    [result addObject:doc];
    RELEASE(doc);
  }
  return result;
}

- (NSArray *)primaryFetch {
  NSDictionary    *args  = nil;
  NSArray         *dates = nil;
  NSArray         *aptTypes = [self->q aptTypes];
  BOOL            makeCopy = NO;

  if (aptTypes == nil) aptTypes = [NSArray array];

  if (self->gidsToFetch != nil) {
    dates = self->gidsToFetch;
  }
  else {
    args =
      [NSDictionary dictionaryWithObjectsAndKeys:
                    [self->q startDate],  @"fromDate",
                    [self->q endDate],    @"toDate",
                    aptTypes,             @"aptTypes",
                    [self->q companies],  @"companies",
                    [self->q resources],  @"resourceNames",
                    nil];
    // fetching gids
    dates = [self->lso runCommand:@"appointment::query" arguments:args];
  }

  args =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  [self->q timeZone],   @"timeZone",
                  dates,                @"gids",
                  [self sortOrderings], @"sortOrderings",
                  self->attributes,     @"attributes",
                  nil];

  // fetching appointments
  
  dates =
    [self->lso runCommand:@"appointment::get-by-globalid" arguments:args];

  if (dates == nil)
    dates = [NSArray array];

  // if filter aptTypes check if this is allowed
  // it is when aptType is still set
  // if aptType is nil or "" view/sort is not allowed or aptType is unspecified
  // so this must be filtered anyway
  if (([aptTypes count]) && ([dates count])) {
    NSEnumerator   *e  = [dates objectEnumerator];
    NSMutableArray *ma = [NSMutableArray array];
    id             one = nil;
    while ((one = [e nextObject]))
      if ([[one valueForKey:@"aptType"] length])
        [ma addObject:one];
    //dates = [ma copy];
    //AUTORELEASE(dates);
    dates = ma;
    makeCopy = YES;
  }

  /* in the near future: always create documents */
  if (self->returnDocuments) {
    dates = [self _morphEOsToDocuments:dates];
    makeCopy = NO;
  }

  if (!self->returnDocuments) {
    // only save if not documents
    if (makeCopy) {
      RELEASE(self->objects);
      self->objects = [dates copy];
    }
    else {
      ASSIGN(self->objects, dates);
    }
    self->objectsFetched = YES;
  }
  else
    self->objects = nil;

  /* commit tx */
  if ([self->lso isTransactionInProgress]) {
    BOOL result = NO;
    
    result = [self->lso commit];
    NSAssert(result, @"could not commit tx !");
  }

  if (!self->returnDocuments) {
    NSDictionary *ui = nil;

    ui = [NSDictionary dictionaryWithObject:dates forKey:@"objects"];
    [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"SkyDataSourceDidFetch"
                         object:self
                         userInfo:ui];
  }
  return dates;
}

- (void)primaryClear {
  RELEASE(self->objects);  self->objects        = nil;
  self->objectsFetched = NO;
}

- (void)clear {
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
  if (self->objectsFetched) {
    [[NSNotificationCenter defaultCenter]
                           postNotificationName:@"SkyDataSourceWillClear"
                           object:self];
  }
  [self primaryClear];
  RELEASE(pool); pool = nil;
}

/* result list */

- (NSArray *)objects {
  if (self->objects)
    return self->objects;

  return [self primaryFetch];
}

- (NSArray *)fetchObjects {
  return [self objects];
}

- (NSArray *)appointmentsWithStartDate:(NSCalendarDate *)_start
             andInterval:(NSTimeInterval)_interval
{
  NSCalendarDate *end    = nil;
  NSMutableArray *ma     = nil;
  id             apt     = nil;
  int            cnt     = 0;
  int            oCnt    = 0;

  [self objects];
  end     = [_start dateByAddingYears:0 months:0 days:0 hours:0 minutes:0
                    seconds:(int)_interval];
  ma      = [NSMutableArray array];
  oCnt    = [self->objects count];
  
  for (cnt = 0; cnt < oCnt; cnt++) {
    NSCalendarDate *sd = nil;
    
    apt = [self->objects objectAtIndex:cnt];
    sd  = [apt valueForKey:@"startDate"];
    
    if (([_start earlierDate:sd] == _start) ||
        ([_start isEqual:sd])){
      if (([end laterDate:sd] == end) &&
          (![end isEqual:sd])) {
        [ma addObject:apt];
      }
    }
  }
  return ma;
}

// document operations

- (id)createObject {
  SkyAppointmentDocument *doc   = nil;
  NSCalendarDate         *date  = [NSCalendarDate date];
  NSArray                *parts = nil;
  NSMutableDictionary    *vals  = nil;
  id                     owner  = nil;

  owner = [[self context] valueForKey:LSAccountKey];
  parts = [NSArray arrayWithObject:owner];
  vals = 
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         date,  @"startDate",
                         date,  @"endDate",
                         @"",   @"title",
                         @"",   @"location",
                         parts, @"participants",
                         nil];
  doc = [[SkyAppointmentDocument alloc] initWithEO:vals globalID:nil
                                        dataSource:self];
  return [doc autorelease];
}

- (void)insertObject:(id)_obj {
  NSDictionary *dict = [_obj asDict];
  
  [dict takeValue:yesNum forKey:@"isWarningIgnored"];
  [dict takeValue:yesNum forKey:@"isConflictDisabled"];
  dict = [[self context] runCommand:@"appointment::new" arguments:dict];
  [_obj _setGlobalID:[dict valueForKey:@"globalID"]];

  [self clear];
  [self postDataSourceChangedNotification];
}

- (void)updateObject:(id)_obj {
  NSDictionary *dict;
  
  dict = [_obj asDict];
  dict = [[self context] runCommand:@"appointment::set" arguments:dict];
  
  [self clear];
  [self postDataSourceChangedNotification];
}

- (void)deleteObject:(id)_obj {
  NSDictionary *dict;
  
  dict = [_obj asDict];
  [dict takeValue:yesNum forKey:@"reallyDelete"];
  [[self context] runCommand:@"appointment::delete" arguments:dict];

  [self clear];
  [self postDataSourceChangedNotification];
}

@end /* SkyAptDataSource */
