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

#include <OGoPalm/SkyPalmDateDataSource.h>
#include <OGoPalm/SkyPalmDateDocument.h>
#include <EOControl/EOControl.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <OGoScheduler/SkyAppointmentDataSource.h>
#include <OGoScheduler/SkyAppointmentDocument.h>
#include <NGExtensions/NSNull+misc.h>
 
@interface SkyPalmDocument(SkyPalmDateDataSource)
- (BOOL)_hasSkyrixRecordBinding;
@end

@interface EODataSource(SetFS)
- (void)setFetchSpecification:(EOFetchSpecification *)_fs;
@end

@implementation SkyPalmDateDataSource

- (id)init {
  if ((self = [super init])) {
    self->fetchEvents   = YES;
    self->fetchAssigned = YES;
  }
  return self;
}

- (void)dealloc {
  [self->start release];
  [self->end   release];;
  [super dealloc];
}

// overwriting
- (NSString *)entityName {
  return @"palm_date";
}
- (NSString *)palmDb {
  return @"DatebookDB";
}
- (SkyPalmDocument *)allocDocument {
  return [SkyPalmDateDocument alloc];
}

// accessors
- (void)setFetchEvents:(BOOL)_flag {
  self->fetchEvents = _flag;
}
- (BOOL)fetchEvents {
  return self->fetchEvents;
}

- (void)setStartdate:(NSCalendarDate *)_start {
  ASSIGN(self->start,_start);
}
- (NSCalendarDate *)startdate {
  return self->start;
}
- (void)setEnddate:(NSCalendarDate *)_end {
  ASSIGN(self->end,_end);
}
- (NSCalendarDate *)enddate {
  return self->end;
}

// additional
// SkyScheduler support
- (EOQualifier *)qualifierForSkyQualifier:(SkyAppointmentQualifier *)_sq {
  EOQualifier    *qual;
  NSString       *format;
  BOOL           currentUser = NO;
  NSEnumerator   *compE;
  id             one;
  id             gid;
  NSMutableArray *allComps   = [NSMutableArray array];
  NSMutableArray *teams      = nil;

  gid   = [[self currentAccount] valueForKey:@"globalID"];
  compE = [[_sq companies] objectEnumerator];

  while ((one = [compE nextObject])) {
    if ([[one entityName] isEqualToString:@"Team"]) {
      if (teams == nil)
        teams = [NSMutableArray array];
      [teams addObject:one];
      continue;
    }
    [allComps addObject:one];
  }
  if (teams != nil) {
    id members = [self->context runCommand:@"team::members",
                      @"groups", teams,
                      @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                      nil];
    if ([members isKindOfClass:[NSDictionary class]]) {
      // grouped ids
      NSMutableArray *a      = [NSMutableArray array];
      int             i, cnt;

      members = [members allValues];
      for (i = 0, cnt = [members count]; i < cnt; i++) {
        [a addObjectsFromArray:[members objectAtIndex:i]];
      }
      members = a;
    }
    [allComps addObjectsFromArray:members];
  }

  compE = [allComps objectEnumerator];
  while ((one = [compE nextObject])) {
    if ([gid isEqual:one]) {
      currentUser = YES;
      break;
    }
  }
  
  if (!currentUser)
    // fetching nothing
    return [EOQualifier qualifierWithQualifierFormat:@"company_id=0"];
  
  [self setStartdate:[_sq startDate]];
  [self setEnddate:[_sq endDate]];

  if (self->fetchAssigned) {
    format =
      @"(company_id=%@) AND ("
      @"(((startdate<%@) AND (enddate>%@)) AND (is_untimed=%@))"
      @" OR "
      @"(NOT (repeat_type=0)"
      @" AND (startdate < %@)"
      @" AND ((repeat_enddate=%@) OR (repeat_enddate>%@))"
      @" AND (is_untimed=%@))"
      @") "
      @"AND (is_deleted=0) AND (is_archived=0)";

    qual = [EOQualifier qualifierWithQualifierFormat:
                        format, [self companyId],
                        self->end, self->start,                        
                        (self->fetchEvents) ? @"1" : @"0",

                        self->end, [NSNull null], self->start,
                        (self->fetchEvents) ? @"1" : @"0"];
  }
  else {
    format =
      @"(company_id=%@) AND ("
      @"((startdate<%@ AND enddate>%@) AND (is_untimed=%@))"
      @" OR "
      @"(NOT (repeat_type=0)"
      @" AND (startdate<%@)"
      @" AND ((repeat_enddate=%@) OR (repeat_enddate > %@))"
      @" AND (is_untimed=%@))"
      @") "
      @"AND (is_deleted=0) AND (is_archived=0) "
      @"AND ((skyrix_id=0) OR (skyrix_id=%@))";
    
    qual = [EOQualifier qualifierWithQualifierFormat:
                        format, [self companyId],
                        self->end, self->start,                        
                        (self->fetchEvents) ? @"1" : @"0",

                        self->end, [NSNull null], self->start,
                        (self->fetchEvents) ? @"1" : @"0",

                        [NSNull null]];
  }

  return qual;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_spec {
  id qual = [_spec qualifier];

  if ([qual isKindOfClass:[SkyAppointmentQualifier class]]) {
    _spec = [_spec copy];
    self->fetchAssigned = NO;
    AUTORELEASE(_spec);
    [_spec setQualifier:[self qualifierForSkyQualifier:qual]];
    [_spec setEntityName:[self entityName]];

    if ([self startdate] != nil) {
      id hints = [_spec hints];
      if (hints == nil) {
        hints = [NSDictionary dictionaryWithObjectsAndKeys:
                              [self startdate], @"startdate",
                              [self enddate],   @"enddate",
                              [NSNumber numberWithBool:YES],
                              @"fetchRepeatings",
                              nil];
      }
      else {
        hints = [hints mutableCopy];
        [hints setObject:[self startdate] forKey:@"startdate"];
        [hints setObject:[self enddate]   forKey:@"enddate"];
        [hints setObject:[NSNumber numberWithBool:YES]
               forKey:@"fetchRepeatings"];
        AUTORELEASE(hints);
      }
      [_spec setHints:hints];
    }
  }
  else {
    id hints = [_spec hints];
    self->fetchAssigned = YES;
    
    if ([[hints valueForKey:@"fetchRepeatings"] boolValue]) {
      [self setStartdate:[hints valueForKey:@"startdate"]];
      [self setEnddate:  [hints valueForKey:@"enddate"]];
    }
    else {
      [self setStartdate:nil];
      [self setEnddate:nil];
    }
  }

  [super setFetchSpecification:_spec];
}

- (NSArray *)_noAssigned:(NSArray *)_src {
  NSMutableArray *all = [NSMutableArray array];
  NSEnumerator   *e   = [_src objectEnumerator];
  id             one  = nil;

  while ((one = [e nextObject])) {
    if (![one _hasSkyrixRecordBinding])
      [all addObject:one];
  }
  return all;
}

- (NSArray *)fetchObjects {
  NSArray             *objs = [super fetchObjects];
  NSEnumerator        *e    = nil;
  SkyPalmDateDocument *doc  = nil;
  NSMutableArray      *ma   = nil;

  if (!self->fetchAssigned)
    objs = [self _noAssigned:objs];

  if ((self->start == nil) || (self->end == nil))
    return objs;
  
  e  = [objs objectEnumerator];
  ma = [NSMutableArray array];
  while ((doc = [e nextObject])) {
    [ma addObjectsFromArray:[doc repeatsBetween:self->start and:self->end]];
  }

  objs = [ma copy];
  return AUTORELEASE(objs);
}


- (NSArray *)categoriesForDevice:(NSString *)_dev {
  return [NSArray array];
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  NSMutableArray      *ma;
  EOKeyGlobalID       *gid;
  NSMutableDictionary *repIdxMap;
  NSNumber            *pKey;
  NSArray             *result;
  id                  one;
  unsigned i, max, idx;

  if ((max = [_gids count]) == 0) return [NSArray array];
  
  ma = [[NSMutableArray alloc] initWithCapacity:[_gids count]];
  repIdxMap = [NSMutableDictionary dictionaryWithCapacity:3];
  for (i = 0; i < max; i++) {
    gid  = [_gids objectAtIndex:i];
    pKey = [NSNumber numberWithInt:[[gid keyValues][0] intValue]];
    [ma addObject:pKey];
    if ([gid keyCount] > 1)
      [repIdxMap setObject:[gid keyValues][1] forKey:pKey];
  }
  [self setFetchSpecification:[self fetchSpecForIds:ma]];
  result = [self fetchObjects];
  [ma removeAllObjects];
  max = [result count];
  for (i = 0; i < max; i++) {
    one  = [result objectAtIndex:i];
    pKey = [[one globalID] keyValues][0];
    if ((pKey = [repIdxMap objectForKey:pKey]) != nil) {
      idx = [pKey intValue];
      one = [one repetitionAtIndex:idx];
    }
    if (one != nil) [ma addObject:one];
  }

  return [ma autorelease];
}

- (SkyAppointmentQualifier *)_qualifierForTimeZone:(NSTimeZone *)_tz {
  SkyAppointmentQualifier *qual;
  qual = [[SkyAppointmentQualifier alloc] init];

  [qual setTimeZone:_tz];

  return [qual autorelease];
}
- (NSArray *)_sortOrderings {
  return [NSArray arrayWithObject:
                  [EOSortOrdering sortOrderingWithKey:@"startDate"
                                  selector:EOCompareAscending]];
}
- (NSArray *)_neededAttributes {
  return [NSArray arrayWithObjects:
                  @"dateId", @"startDate", @"endDate", @"cycleEndDate",
                  @"type", @"title", @"globalID", @"permissions",
                  @"participants.login", @"objectVersion", @"comment",
                  @"location", @"accessTeamId", @"writeAccessList", 
                  nil];
}
- (NSDictionary *)_hintsForSkyrixRecordGIDs:(NSArray *)_gids {
  NSDictionary *hints = nil;

  hints = 
    [NSDictionary dictionaryWithObjectsAndKeys:
                  _gids,                    @"fetchGIDs",
                  [self _neededAttributes], @"attributes",
                  nil];
  return hints;
}
- (EOFetchSpecification *)_fetchSpecForSkyrixRecordGIDs:(NSArray *)_gids
                                               timeZone:(NSTimeZone *)_tz
{
  EOFetchSpecification *fspec =
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Date"
                          qualifier:[self _qualifierForTimeZone:_tz]
                          sortOrderings:[self _sortOrderings]];
  [fspec setHints:[self _hintsForSkyrixRecordGIDs:_gids]];
  return fspec;
}

- (NSDictionary *)_bulkFetchSkyrixRecords:(NSArray *)_palmRecords {
  NSTimeZone               *tz = nil;
  NSMutableArray           *gids;
  SkyPalmDateDocument      *doc;
  SkyAppointmentDataSource *ads;
  SkyAppointmentDocument   *skyDoc;
  NSArray                  *apts;
  NSMutableDictionary      *aptMap;
  id                       skyrixId;
  unsigned int             i, cnt;

  cnt  = [_palmRecords count];
  gids = [NSMutableArray arrayWithCapacity:cnt+1];
  for (i = 0; i < cnt; i++) {
    doc = [_palmRecords objectAtIndex:i];
    skyrixId = [doc skyrixId];
    tz = [[doc startDate] timeZone];
    if ([skyrixId intValue] > 1000) {
      skyrixId = [EOKeyGlobalID globalIDWithEntityName:@"Date"
                                keys:&skyrixId keyCount:1 zone:nil];
      [gids addObject:skyrixId];
    }
  }
  
  ads = [[SkyAppointmentDataSource alloc] initWithContext:[self context]];
  [ads setFetchSpecification:[self _fetchSpecForSkyrixRecordGIDs:gids
                                   timeZone:tz]];
  apts = [ads fetchObjects];
  [ads release];

  cnt = [apts count];
  aptMap = [NSMutableDictionary dictionaryWithCapacity:cnt+1];
  for (i = 0; i < cnt; i++) {
    skyDoc   = [apts objectAtIndex:i];
    skyrixId = [skyDoc globalID];
    skyrixId = [skyrixId keyValues][0];
    if (![skyrixId isKindOfClass:[NSNumber class]])
      skyrixId = [NSNumber numberWithInt:[skyrixId intValue]];
    
    [aptMap setObject:skyDoc forKey:skyrixId];
  }
  
  return aptMap;
}

@end /* SkyPalmDateDataSource */

