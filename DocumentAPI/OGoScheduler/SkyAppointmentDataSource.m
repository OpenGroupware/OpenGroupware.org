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

#include "SkyAppointmentDataSource.h"
#include "SkyAppointmentQualifier.h"
#include "SkyAppointmentDocument.h"
#include <LSFoundation/OGoContextSession.h>
#include "common.h"

@interface NSObject(Gid)
- (EOGlobalID *)globalID;
@end

@interface SkyAppointmentDataSource(PrivateMethods)
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
@end

@interface SkyAppointmentDocument(SkyAppointmentDataSource)
- (void)_setGlobalID:(id)_gid;
@end

@implementation SkyAppointmentDataSource

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    NSNotificationCenter *nc = nil;

    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
        selector:@selector(appointmentWasChanged:)
        name:SkyNewAppointmentNotification
        object:nil];
    
    [nc addObserver:self
        selector:@selector(appointmentWasChanged:)
        name:SkyUpdatedAppointmentNotification
        object:nil];
    
    [nc addObserver:self
        selector:@selector(appointmentWasChanged:)
        name:SkyDeletedAppointmentNotification
        object:nil];
    
    ASSIGN(self->context, _ctx);
  }
  return self;
}

- (id)init {
  return [self initWithContext:nil];
}


- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self->context            release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* notifications */

- (void)appointmentWasChanged:(id)_obj {
  [self postDataSourceChangedNotification];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if (![self->fetchSpecification isEqual:_fSpec]) {
    ASSIGNCOPY(self->fetchSpecification, _fSpec);
    [self postDataSourceChangedNotification];
  }
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (id)context {
  return self->context;
}

- (NSArray *)fetchObjects {
  /* TODO: split up this huge method! */
  EOFetchSpecification *fSpec;
  NSDictionary         *hints;
  EOQualifier          *qual;
  NSMutableDictionary  *args  = nil;
  NSCalendarDate   *startDate = nil;
  NSCalendarDate   *endDate   = nil;
  NSTimeZone       *timeZone  = nil;
  NSArray *companies          = nil;
  NSArray *resources          = nil;
  NSArray *aptTypes           = nil;
  NSArray *attributes         = nil;
  NSArray *sortOrderings      = nil;
  NSArray *dates              = nil;
  NSArray *gidsToFetch        = nil;
  BOOL    fetchGlobalIDs      = NO;
  BOOL    onlyNotified        = NO;
  BOOL    onlyResourceApts    = NO;

  fSpec = [self fetchSpecification];
  hints = [fSpec hints];
  sortOrderings  = [fSpec sortOrderings];
  qual           = [fSpec qualifier];
  gidsToFetch    = [hints objectForKey:@"fetchGIDs"];
  attributes     = [hints objectForKey:@"attributes"];
  timeZone       = [hints objectForKey:@"timeZone"];
  fetchGlobalIDs = [[hints objectForKey:@"fetchGlobalIDs"] boolValue];
  
  if ([attributes containsObject:@"owner"]) {
    NSMutableArray *attrs;
    
    attrs = [NSMutableArray arrayWithArray:attributes];
    [attrs removeObject:@"owner"];
    if (![attrs containsObject:@"ownerId"])
      [attrs addObject:@"ownerId"];
    
    attributes = attrs ? [NSArray arrayWithArray:attrs] : nil;
  }
      
  
  if (gidsToFetch != nil) dates = gidsToFetch;

  if (qual == nil)
    ;// do nothing
  else if ([qual isKindOfClass:[SkyAppointmentQualifier class]]) {
    startDate     = [(SkyAppointmentQualifier *)qual startDate];
    endDate       = [(SkyAppointmentQualifier *)qual endDate];
    resources     = [(SkyAppointmentQualifier *)qual resources];
    companies     = [(SkyAppointmentQualifier *)qual companies];
    if (![companies count]) {
      companies = [(SkyAppointmentQualifier *)qual personGIDs];
    }
    else {
      companies = [[companies mutableCopy] autorelease];
      [(NSMutableArray *)companies addObjectsFromArray:
                 [(SkyAppointmentQualifier *)qual personGIDs]];
    }
    aptTypes      = [(SkyAppointmentQualifier *)qual aptTypes];
    onlyNotified  = [(SkyAppointmentQualifier *)qual onlyNotified];
    onlyResourceApts = [(SkyAppointmentQualifier *)qual onlyResourceApts];
    if ([(SkyAppointmentQualifier *)qual timeZone])
      timeZone = [(SkyAppointmentQualifier *)qual timeZone];
  }
  else if ([qual isKindOfClass:[EOKeyValueQualifier class]] &&
           [[(EOKeyValueQualifier *)qual key] isEqualToString:@"globalID"]) {
    dates = [(EOKeyValueQualifier *)qual value];
    if (![dates isKindOfClass:[NSArray class]] && dates != nil)
      dates = [NSArray arrayWithObject:companies];
  }
  else {
    NSAssert1((NO),
              @"SkyAppointmentDataSource only supports "
              @"SkyAppointmentQualifiers (qualifier = %@)",
              qual);
  }

  args = [[NSMutableDictionary alloc] initWithCapacity:8];
  if (dates == nil) {
    if (startDate) [args setObject:startDate forKey:@"fromDate"];
    if (endDate)   [args setObject:endDate   forKey:@"toDate"];
    if (companies) [args setObject:companies forKey:@"companies"];
    if (resources) [args setObject:resources forKey:@"resourceNames"];
    if (aptTypes)  [args setObject:resources forKey:@"aptTypes"];

    // fetching gids
    dates = [self->context runCommand:@"appointment::query" arguments:args];
  }
  
  if (dates == nil) dates = [NSArray array];

  if (fetchGlobalIDs) return dates;

  [args removeAllObjects];
  if (timeZone)      [args setObject:timeZone      forKey:@"timeZone"];
  if (dates)         [args setObject:dates         forKey:@"gids"];
  if (sortOrderings) [args setObject:sortOrderings forKey:@"sortOrderings"];
  if (attributes)    [args setObject:attributes    forKey:@"attributes"];

  // fetching appointments
  dates =
    [self->context runCommand:@"appointment::get-by-globalid" arguments:args];

  if (dates == nil) dates = [NSArray array];

  /*
    if filter aptTypes check if this is allowed
    it is when aptType is still set
    if aptType is nil or "" view/sort is not allowed or aptType is unspecified
    so this must be filtered anyway
  */
  if (([aptTypes count] > 0) && ([dates count] > 0)) {
    NSEnumerator   *e;
    NSMutableArray *ma;
    id             one;

    e  = [dates objectEnumerator];
    ma = [NSMutableArray array];
    while ((one = [e nextObject])) {
      if ([[one valueForKey:@"aptType"] length])
        [ma addObject:one];
    }
    dates = [ma copy];
    [dates autorelease];
  }

  if ((onlyNotified) &&
      ((attributes == nil) ||
       ([attributes containsObject:@"notificationTime"]))) {
    EOQualifier *q =
      [EOQualifier qualifierWithQualifierFormat:
                   @"(NOT ((%@ = %@) OR "
                   @"(%@ = 0)))",
                   @"notificationTime", [EONull null],
                   @"notificationTime"];
    dates = [dates filteredArrayUsingQualifier:q];
  }
  if ((onlyResourceApts) &&
      ((attributes == nil) ||
       ([attributes containsObject:@"resourceNames"]))) {
    EOQualifier *q =
      [EOQualifier qualifierWithQualifierFormat:
                   @"NOT ((resourceNames = %@) OR "
                   @"(resourceNames = ''))", [EONull null]];
    dates = [dates filteredArrayUsingQualifier:q];
  }

  dates = [self _morphEOsToDocuments:dates];

  /* commit tx */
  if ([self->context isTransactionInProgress]) {
    BOOL result = NO;
    
    result = [self->context commit];
    NSAssert(result, @"could not commit tx !");
  }
  [args release];
  return dates;
}

/* document operations */

- (id)createObject {
  SkyAppointmentDocument *doc   = nil;
  NSCalendarDate         *date;
  NSArray                *parts;
  NSMutableDictionary    *vals  = nil;
  id                     owner;

  date  = [NSCalendarDate date];
  owner = [[self context] valueForKey:LSAccountKey];
  parts = [NSArray arrayWithObject:owner];

  vals  = [NSMutableDictionary dictionaryWithObjectsAndKeys:
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
  NSDictionary *dict = nil;

  dict = ([_obj respondsToSelector:@selector(asDict)]) ? [_obj asDict] : _obj;
  
  [dict takeValue:[NSNumber numberWithBool:YES] forKey:@"isWarningIgnored"];
  [dict takeValue:[NSNumber numberWithBool:YES] forKey:@"isConflictDisabled"];

  dict = [[self context] runCommand:@"appointment::new" arguments:dict];
  [_obj _setGlobalID:[dict valueForKey:@"globalID"]];

  [self postDataSourceChangedNotification];
}

- (void)updateObject:(id)_obj {
  NSDictionary *dict = [_obj asDict];
  
  [dict takeValue:[NSNumber numberWithBool:YES] forKey:@"isWarningIgnored"];
  dict = [[self context] runCommand:@"appointment::set" arguments:dict];

  [self postDataSourceChangedNotification];
}

- (NSException *)deleteObjectEx:(id)_obj {
  // TODO: return exception object
  NSMutableDictionary *dict;
  NSDictionary *values;
  
  NSParameterAssert(_obj != nil);
  
  if ((values = [_obj asDict]) == nil) {
    [self logWithFormat:
            @"ERROR: could not represent object '%@'(%@) as a dictionary!",
            _obj, NSStringFromClass([_obj class])];
    [NSException raise:@"ParameterError"
                 format:
                   @"parameter given to -deleteObject is not a proper "
                   @"object for deletion! (%@, class=%@)",
                   _obj, NSStringFromClass([_obj class])];
    return nil;
  }
  
  dict = [NSMutableDictionary dictionaryWithCapacity:16];
  [dict addEntriesFromDictionary:values];
  [dict takeValue:[NSNumber numberWithBool:YES] forKey:@"reallyDelete"];
  
  [[self context] runCommand:@"appointment::delete" arguments:dict];
  
  [self postDataSourceChangedNotification];
  return nil;
}
- (void)deleteObject:(id)_obj {
  [[self deleteObjectEx:_obj] raise];
}

@end /* SkyAppointmentDataSource */

@implementation SkyAppointmentDataSource(PrivateMethodes)

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  unsigned i, count;
  NSMutableArray *result;

  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id doc;
    id apt;
    
    apt = [_eos objectAtIndex:i];
    
    doc = [[SkyAppointmentDocument alloc] initWithEO:apt dataSource:self];
    [result addObject:doc];
    [doc release];
  }
  return result;
}

@end /* SkyAppointmentDataSource(PrivateMethodes) */

#if 0 /* hh asks: what about that? why commented out? */
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
#endif
