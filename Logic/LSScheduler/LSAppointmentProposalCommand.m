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

// TODO: this files needs MAJOR cleanups

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  LSAppointmentProposalCommand (appointment::proposal)
  
  Use in:
    LSWAppointmentProposal

  Returns an array of dictionaries like:
    {
        endDate = "2005-09-19 18:00:00 +0200";
        kind = start;
        startDate = "2005-09-19 17:00:00 +0200";
    },
    {
        endDate = "2005-09-19 18:00:00 +0200";
        kind = end;
        startDate = "2005-09-19 17:01:00 +0200";
    }
*/

@class NSCalendarDate, NSTimeZone;
@class LSCommandContext;

@interface LSAppointmentProposalCommand : LSDBObjectBaseCommand
{
@private
  NSArray        *participants;
  NSArray        *resources;
  NSArray        *categories;
  int            duration;
  int            interval;  
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  int            startTime; // seconds from 0:00
  int            endTime;   // seconds from 0:00
  NSTimeZone     *timeZone;
  NSCalendarDate *now;
}

- (NSArray *)_getPrimaryKeysOfCompanyRecords:(NSArray *)_a inContext:(id)_ctx;
- (NSString *)_getResourceString:(id)_ctx;
- (NSArray *)_getFreeTimeIntervals:(NSArray *)_dates inContext:(id)_ctx;
- (NSMutableArray *)_getDatesInContext:(id)_context;

- (EOSQLQualifier *)_partQualifierForEntity:(EOEntity *)_entity
  inContext:(id)_context ids:(NSArray *)_ids;

- (NSArray *)_resQualifier:(NSArray *)_res entity:(EOEntity *)_entity
  context:(id)_context adaptor:(EOAdaptor *)_adaptor;

- (EOSQLQualifier *)_dateQualifierForEntity:(EOEntity *)_entity
  inContext:(id)_context adaptor:(EOAdaptor *)_adaptor;

- (NSCalendarDate *)dateAtHour:(int)_hour minute:(int)_minute second:(int)_sec;

- (NSArray *)_getStartDateFetchOrderingWithEntity:(EOEntity *)_entity
  inContext:(id)_context;
- (NSMutableArray *)_datesForParticipantsAndResources:(id)_context;
- (NSMutableArray *)_datesForCategories:(id)_ctx;

- (void)_sortDates:(NSMutableArray *)_dates  inContext:(LSCommandContext *)_cx;
- (void)_mergeDates:(NSMutableArray *)_dates inContext:(LSCommandContext *)_cx;

@end

#include "common.h"

static int compareDates(id part1, id part2, void *context);

@implementation LSAppointmentProposalCommand

static NSTimeZone *gmt         = nil;
static NSTimeZone *met         = nil;
static NSArray    *emptyArray  = nil;
static int        LSAppointmentProposalCommand_MAXSEARCH = 400;
static BOOL       debugOn      = NO; // LSAppointmentProposalCommand_DEBUG

+ (void)initialize {
  if (gmt == nil) 
    gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
  if (met == nil) 
    met = [[NSTimeZone timeZoneWithAbbreviation:@"MET"] retain];
  if (emptyArray == nil)
    emptyArray = [[NSArray alloc] init];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->startTime    = -1;
    self->endTime      = -1;
    self->duration     = -1;
    self->interval     = -1;
  }
  return self;
}

- (void)dealloc {
  [self->now          release];
  [self->participants release];
  [self->resources    release];
  [self->startDate    release];
  [self->endDate      release];
  [self->timeZone     release];
  [super dealloc];
}

/* processing */

- (void)_prepareForExecutionInContext:(id)_context {
  if (self->timeZone == nil)
    self->timeZone = [gmt retain];

  [self->now release]; self->now = nil;
  self->now = [[NSCalendarDate date] copy];
  [self->now setTimeZone:self->timeZone];
  
  if (![self->startDate isNotNull]) {
    [self warnWithFormat:@"startDate == nil, take today"];
    self->startDate = [[self dateAtHour:0 minute:0 second:0] retain];
  }
  if (![self->endDate isNotNull]) {
    [self warnWithFormat:@"endDate == nil, take today"];
    self->endDate = [[self dateAtHour:0 minute:0 second:0] copy];
  }
  if (![self->participants isNotNull]) {
    [self warnWithFormat:@"no participants are set"];
    self->participants = [emptyArray retain];
  }
  if ((![self->resources isNotNull]) || (self->resources == nil)) {
    [self warnWithFormat:@"no resources are set"];
    self->resources = [emptyArray retain];
  }
  if (self->startTime == -1) {
    [self warnWithFormat:@"no startTime is set"];
    self->startTime = 60 * 8;    
  }
  if (self->endTime == -1) {
    [self warnWithFormat:@"no endTime is set"];
    self->endTime = 60 * 20;    
  }
  if (self->duration == -1) {
    [self logWithFormat:@"duration is not set"];
    self->duration = 60;
  }
  if (self->interval == -1) {
    [self logWithFormat:@"interval is not set"];
    self->interval = 60;
  }
  
  if (self->endDate == nil)
    return;
  
  [self assert:([self->startDate compare:self->endDate] != NSOrderedDescending)
        reason:@"startDate before endDate"];
}

- (void)_executeInContext:(id)_context {
  NSMutableArray    *dates = nil;
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
  dates = [[self _getDatesInContext:_context] retain];
  [pool release];

  pool = [[NSAutoreleasePool alloc] init];
  [self _sortDates:dates  inContext:_context];
  [self _mergeDates:dates inContext:_context];
  [pool release];
  
  pool = [[NSAutoreleasePool alloc] init];
  /* dates is an array of dicts with _only_ 'startDate' and 'endDate' */
  [dates autorelease]; // Note: still live and used as an arg below!
  dates = [(id)[self _getFreeTimeIntervals:dates inContext:_context] retain];
  [pool release];
  
  [self setReturnValue:dates];
  [dates release];
}

- (NSArray *)_getPrimaryKeysOfCompanyRecords:(NSArray *)_a inContext:(id)_ctx {
  NSMutableSet *staff;
  unsigned i, cnt;
  
  cnt   = [_a count];
  staff = [NSMutableSet setWithCapacity:cnt + 1];
  
  // TODO: just fetch the IDs of members and teams
  for (i = 0; i < cnt; i++) {
    id obj;
    
    obj = [_a objectAtIndex:i];
    if ([[obj valueForKey:@"isTeam"] boolValue]) {
      NSArray *teams;      
      NSArray *members;

      if ((members = [obj valueForKey:@"members"]) == nil) {
        LSRunCommandV(_ctx, @"team", @"members", @"object", obj, nil);
      }
      if ((members = [obj valueForKey:@"members"]) == nil) {
        [self errorWithFormat:@"could not fetch members for team %@", obj];
        members = emptyArray;
      }
#if 0 // hh: document!
      [staff removeObject:obj];
#endif
      
      teams = LSRunCommandV(_ctx, @"account", @"teams",
                            @"accounts", members, nil);
      [staff addObjectsFromArray:[teams valueForKey:@"companyId"]];
      [staff addObjectsFromArray:[members valueForKey:@"companyId"]];
      [staff addObject:[obj valueForKey:@"companyId"]];
    }
    else {
      NSArray *teams;
      
      teams = LSRunCommandV(_ctx, @"account", @"teams", 
                            @"object", obj, nil);
      [staff addObjectsFromArray:[teams valueForKey:@"companyId"]];
      [staff addObject:[obj valueForKey:@"companyId"]];
    }
  }
  return [staff allObjects];
}

- (NSString *)_getResourceString:(id)_context {
  int             i, cnt;
  NSMutableString *str;
  BOOL            first;

  str = [NSMutableString stringWithCapacity:255];
  
  for (i = 0, cnt = [self->resources count], first = YES; i < cnt; i++) {
    NSString *s;

    s = [self->resources objectAtIndex:i];
    if (![s isNotEmpty])
      continue;
    
    if (!first)
      [str appendString:@", "];
    else
      first = NO;
    [str appendString:s];
  }
  return str;
}

- (NSArray *)_getStartDateFetchOrderingWithEntity:(EOEntity *)_entity
  inContext:(id)_context
{
  EOAttributeOrdering *ao;
  
  ao = [EOAttributeOrdering attributeOrderingWithAttribute:
                              [_entity attributeNamed:@"startDate"]
                            ordering:EOAscendingOrder];
  return [NSArray arrayWithObject:ao];
}

- (EOSQLQualifier *)_partQualifierForEntity:(EOEntity *)_entity
  inContext:(id)_context ids:(NSArray *)_ids
{
  EOSQLQualifier *qualifier;
  
  if (![_ids isNotEmpty]) {
    [self errorWithFormat:@"%s: got no IDs for building qualifier!",
	    __PRETTY_FUNCTION__];
    return nil;
  }
  
  qualifier = [self createSqlInQualifierOnEntity:_entity
		    attributePath:@"toDateCompanyAssignment.companyId"
		    primaryKeys:_ids];
  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];
}

- (EOSQLQualifier *)_atomicResQualifier:(NSString *)_res
  forEntity:(EOEntity *)_entity inContext:(id)_context
{
  EOSQLQualifier *qualifier;
  
  qualifier = [[EOSQLQualifier alloc]
                               initWithEntity:_entity
                               qualifierFormat:
                               @"(%A LIKE '%@') OR (%A LIKE '%@,%%') OR "
                               @"(%A LIKE '%%, %@') OR (%A LIKE '%%, %@,%%')",
                               @"resourceNames", _res,
                               @"resourceNames", _res,
                               @"resourceNames", _res,
                               @"resourceNames", _res, nil];
  return [qualifier autorelease];  
}

- (NSArray *)_removeEmptyResources:(NSArray *)_res {
  NSMutableArray *res        = nil;
  NSEnumerator   *enumerator = nil;
  id             obj         = nil;

  enumerator = [_res objectEnumerator];
  res        = [NSMutableArray arrayWithCapacity:64];
  while ((obj = [enumerator nextObject])) {
    if ([obj length] > 0)
      [res addObject:obj];
  }
  return res;
}

- (NSArray *)_resQualifier:(NSArray *)_res entity:(EOEntity *)_entity
  context:(id)_context adaptor:(EOAdaptor *)_adaptor
{
  /* TODO: split up */
  id      obj  = nil;
  NSArray *res = nil;
  NSEnumerator   *enumerator = nil;
  EOSQLQualifier *qualifier  = nil;
    
  res = [self _removeEmptyResources:_res];
  if (![res isNotEmpty])
    return emptyArray;

  enumerator = [res objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
      EOSQLQualifier *rq;
	
      rq = [self _atomicResQualifier:obj forEntity:_entity inContext:_context];
      
      if (qualifier == nil)
	qualifier = rq;
      else if (rq != nil)
	[qualifier disjoinWithQualifier:rq];
      else {
	[self warnWithFormat:@"%s: got no qualifier!", 
	        __PRETTY_FUNCTION__];
      }
  }
  return (qualifier != nil) 
    ? (NSArray *)[NSArray arrayWithObject:qualifier] : emptyArray;
}

- (EOSQLQualifier *)_dateQualifierForEntity:(EOEntity *)_entity
  inContext:(id)_context adaptor:(EOAdaptor *)_adaptor
{
  NSString       *formattedBegin, *formattedEnd;
  EOSQLQualifier *qualifier;
  
  formattedBegin = 
    [_adaptor formatValue:self->startDate
              forAttribute:[_entity attributeNamed:@"startDate"]];
  formattedEnd   = 
    [_adaptor formatValue:self->endDate
              forAttribute:[_entity attributeNamed:@"endDate"]];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:_entity
                                      qualifierFormat:
                                      @"%A > %@ AND %A < %@ ",
                                      @"endDate",       formattedBegin,
                                      @"startDate",     formattedEnd];
  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];  
}

- (NSMutableArray *)_getDatesInContext:(id)_context {
  NSMutableArray *array;
  
  array = [self _datesForParticipantsAndResources:_context];
  [array addObjectsFromArray:[self _datesForCategories:_context]];
  return array;
}

- (NSTimeZone *)timeZoneInContext:(id)_ctx {
  NSTimeZone *tz;
  NSString *tzName;
  
  tzName = [(NSUserDefaults *)[_ctx valueForKey:LSUserDefaultsKey] 
                              objectForKey:@"timezone"];
  return ((tz = [NSTimeZone timeZoneWithAbbreviation:tzName]) != nil)
    ? tz : met;
}

- (NSArray *)_fetchResourcesForCategory:(id)_obj inContext:(id)_ctx {
  return LSRunCommandV(_ctx, @"appointmentresource", @"categories",
		       @"category", _obj, nil);
}

- (NSMutableArray *)_datesForCategories:(id)_ctx {
  /* TODO: split up this HUGE method! */
  NSMutableArray   *attributes = nil;
  EOEntity         *entity     = nil;
  EOAdaptor        *adaptor    = nil;
  EOAdaptorChannel *channel    = nil;
  id               result      = nil;
  NSTimeZone       *tz         = nil;
  NSEnumerator     *enumerator = nil;
  id               obj         = nil;
  
  tz = [self timeZoneInContext:_ctx];
  
  channel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  adaptor = [[[_ctx valueForKey:LSDatabaseContextKey] adaptorContext]
                    adaptor];
  entity = [[adaptor model] entityNamed:@"Date"];
  
  attributes = [NSMutableArray arrayWithObjects:
                               [entity attributeNamed:@"startDate"],
                               [entity attributeNamed:@"endDate"],
                               [entity attributeNamed:@"resourceNames"], nil];
  
  result = [[NSMutableSet alloc] initWithCapacity:255];

  enumerator = [self->categories objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSArray             *res   = nil;
    NSMutableArray      *dates;
    NSMutableDictionary *dict  = nil;
    EOSQLQualifier *qualifier;

    dates = [[NSMutableArray alloc] initWithCapacity:100];
    
    res   = LSRunCommandV(_ctx, @"appointmentresource", @"categories",
                          @"category", obj, nil);

    qualifier = [[self _resQualifier:res entity:entity context:_ctx
                       adaptor:adaptor] lastObject];
    [qualifier conjoinWithQualifier:[self _dateQualifierForEntity:entity
                                          inContext:_ctx
                                          adaptor:adaptor]];
    
    if (![channel selectAttributes:attributes describedByQualifier:qualifier
                  fetchOrder:[self _getStartDateFetchOrderingWithEntity:entity
                                   inContext:_ctx]
                  lock:NO]) {
      [self errorWithFormat:@"could not perform SQL select!"];
      return [NSMutableArray arrayWithCapacity:4];
    }
      
    while ((dict = [channel fetchAttributes:attributes withZone:NULL])) {
        NSCalendarDate *date  = nil;
        NSMutableArray *array = nil;
        id             tmp    = nil;
        id *v = NULL;
        id *k = NULL;

        v = calloc(4, sizeof(id));
        k = calloc(4, sizeof(id));
	
        date = [dict objectForKey:@"startDate"];
        [date setTimeZone:self->timeZone];
        v[0] = date;
        k[0] = @"startDate";
        
        date = [dict objectForKey:@"endDate"];
        [date setTimeZone:self->timeZone];
        v[1] = date;
        k[1] = @"endDate";

        array  = [NSMutableArray arrayWithCapacity:16];

        if ((tmp = [dict objectForKey:@"resourceNames"]) != nil) {
          NSEnumerator *resEnum;
          
          resEnum = [[tmp componentsSeparatedByString:@", "] objectEnumerator];
          while ((tmp = [resEnum nextObject])) {
            if ([res containsObject:tmp])
              [array addObject:tmp];
          }
        }
        v[2] = array;
        k[2] = @"resourceNames";
        
        tmp = [[NSDictionary alloc] initWithObjects:v forKeys:k count:3];
        [dates addObject:tmp];
        [tmp release];
        if (v != NULL) free(v);
        if (k != NULL) free(k);
    }
    
    {
      NSMutableArray *array    = nil;
      NSEnumerator   *resEnum  = nil;
      id             aResource = nil;

      array   = [NSMutableArray array];
      resEnum = [res objectEnumerator];

      while ((aResource = [resEnum nextObject])) {
        NSEnumerator   *dateEnum  = nil;
        id             aDate      = nil;
        NSMutableArray *dateArray = nil;

        dateArray = [NSMutableArray array];
        dateEnum  = [dates objectEnumerator];
        while ((aDate = [dateEnum nextObject])) {
	  int i   = 0;
	  int cnt = 0;
	  
          if (![[aDate valueForKey:@"resourceNames"] containsObject:aResource])
	    continue;
              
	  cnt = [dateArray count];

	  if (cnt == 0) {
	    NSMutableDictionary *d;

	    d = [NSMutableDictionary dictionaryWithCapacity:10];
	    [d setObject:[aDate valueForKey:@"startDate"] forKey:@"startDate"];
	    [d setObject:[aDate valueForKey:@"endDate"]   forKey:@"endDate"];
	    [d setObject:aResource  forKey:@"resource"];
	    [dateArray addObject:d];
	    continue;
	  }
	  
	  for (i = 0; i < cnt; i++) {
	    NSCalendarDate *cDateStart, *cDateEnd;
	    NSCalendarDate *aDateStart, *aDateEnd;
	    NSMutableDictionary *cDate;
	    
	    cDate      = [dateArray objectAtIndex:i];
	    cDateStart = [cDate valueForKey:@"startDate"];
	    cDateEnd   = [cDate valueForKey:@"endDate"];
	    aDateEnd   = [aDate valueForKey:@"endDate"];
	    aDateStart = [aDate valueForKey:@"startDate"];
                  
	    if ([cDateEnd earlierDate:aDateStart] == cDateEnd ||
		[aDateEnd earlierDate:cDateStart] == aDateEnd) {
	      NSMutableDictionary *d;
              
	      d = [NSMutableDictionary dictionaryWithCapacity:3];
	      [d setObject:aDateStart forKey:@"startDate"];
	      [d setObject:aDateEnd   forKey:@"endDate"];
	      [d setObject:aResource  forKey:@"resource"];
	      [dateArray addObject:d];
	    }
	    else if ([aDateStart earlierDate:cDateStart] == aDateStart &&
                         [aDateEnd earlierDate:cDateEnd] == aDateEnd) {
	      [cDate setObject:aDateStart forKey:@"startDate"];
	    }
	    else if ([cDateStart earlierDate:aDateStart] == cDateStart &&
                         [cDateEnd earlierDate:aDateEnd] == cDateEnd) {
	      [cDate setObject:aDateEnd forKey:@"endDate"];
	    }
	    else if ([aDateStart earlierDate:cDateStart] == aDateStart &&
		     [cDateEnd earlierDate:aDateEnd] == cDateEnd) {
	      [cDate setObject:aDateStart forKey:@"startDate"];
	      [cDate setObject:aDateEnd   forKey:@"endDate"];
	    }
	    else if ([cDateStart earlierDate:aDateStart] == cDateStart &&
		     [aDateEnd earlierDate:cDateEnd] == aDateEnd) {
	    }
	    else {
	      // TODO: explain?!
	      [self errorWithFormat:@"impossible cDate %@ aDate %@", 
		    cDate, aDate];
	    }
	  }
        }
        [array addObjectsFromArray:dateArray];          
      }
      [dates autorelease];
      dates = array;
    }
    {
      NSSet          *allRes       = nil;
      NSMutableSet   *currentRes   = nil;
      NSMutableArray *currentDates = nil;
      NSEnumerator   *enumerator   = nil;
      NSDictionary   *date         = nil;
      
      allRes       = [NSSet setWithArray:
			      [self _fetchResourcesForCategory:obj 
				    inContext:_ctx]];
      
      currentRes   = [[NSMutableSet alloc] initWithCapacity:[allRes count]];
      currentDates = [[NSMutableArray alloc] initWithCapacity:[dates count]];

      [dates sortUsingFunction:compareDates context:nil];
      enumerator   = [dates objectEnumerator];

      while ((date = [enumerator nextObject])) {
        int i   = 0;
        int cnt = 0;

        cnt = [currentDates count];
        for (i = 0; i < cnt; i++) {
          NSDictionary *d = [currentDates objectAtIndex:i];
	  
          if ([(NSCalendarDate *)[d valueForKey:@"endDate"] 
                                 compare:[date valueForKey:@"startDate"]] ==
              NSOrderedAscending) {
            [currentDates removeObjectAtIndex:i];
            i--; cnt--;
          }
        }
        [currentDates addObject:date]; 
        [currentRes removeAllObjects];
        cnt = [currentDates count];
        for (i = 0; i < cnt; i++) {
          id           dObj   = nil;

          dObj = [[currentDates objectAtIndex:i] valueForKey:@"resource"];
          if ([allRes containsObject:dObj]) {
            [currentRes addObject:dObj];
          }
        }

        if ([allRes count] == [currentRes count]) {
          NSString       **keys         = NULL;
          NSCalendarDate **values       = NULL;
          NSEnumerator   *curDateEnum   = nil;
          id             cDate          = nil;

          curDateEnum = [currentDates objectEnumerator];

          keys    = calloc(2, sizeof(id));
          values  = calloc(2, sizeof(id));
          keys[0] = @"startDate";
          keys[1] = @"endDate";
          cDate = [curDateEnum nextObject];
          if (cDate != nil) {
            values[0] = [cDate valueForKey:@"startDate"];
            values[1] = [cDate valueForKey:@"endDate"];
	      
            while ((cDate = [curDateEnum nextObject])) {
              NSCalendarDate *d = [cDate valueForKey:@"startDate"];
                
              if ([values[0] compare:d] == NSOrderedAscending)
                values[0] = d;

              d = [cDate valueForKey:@"endDate"];
              if ([values[1] compare:d] == NSOrderedDescending)
                values[1] = d;
            }
            [result addObject:[NSDictionary dictionaryWithObjects:values
                                            forKeys:keys count:2]];
          }
          if (keys)   free(keys);   keys   = NULL;
          if (values) free(values); values = NULL;
        }
      }
      [currentDates release]; currentDates = nil;
      [currentRes   release]; currentRes   = nil;
      [channel cancelFetch];
    }
  }
  {
    id tmp = result;
    result = [result allObjects];
    [tmp release];
  }
  return result;
}

  
- (NSMutableArray *)_datesForParticipantsAndResources:(id)_context {
  // TODO: split up this huge method, cleanup duplicate code
  NSTimeZone       *tz;
  EOAdaptorChannel *channel;
  EOAdaptor        *adaptor;
  EOEntity         *entity;
  NSMutableArray   *attributes  = nil;
  NSMutableArray   *result      = nil;
  EOSQLQualifier *qualifier;
  EOSQLQualifier *resQual     = nil; // Note: this is different for PG 6.5
  NSArray        *partIds     = nil;
  int            i, cnt;
  
  // TODO: isn't that available using a context key?
  tz = [self timeZoneInContext:_context];
  
  channel = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel];
  adaptor = [[[_context valueForKey:LSDatabaseContextKey] adaptorContext]
                           adaptor];
  entity  = [[adaptor model] entityNamed:@"Date"];

  attributes = [NSMutableArray arrayWithObjects:
                                 [entity attributeNamed:@"startDate"],
                                 [entity attributeNamed:@"endDate"], nil];
  
  result = [NSMutableArray arrayWithCapacity:255];

  //  qualifier = [self _partQualifierForEntity:entity inContext:_context];

  resQual   = [[self _resQualifier:self->resources entity:entity
		     context:_context adaptor:adaptor] 
		lastObject]; // Note: different to PG 6.5!
     
  qualifier = [self _dateQualifierForEntity:entity
		    inContext:_context
		    adaptor:adaptor];
  
  partIds = [self _getPrimaryKeysOfCompanyRecords:self->participants
                  inContext:_context];
  cnt     = [partIds count];
  i       = 0;
  do {
    EOSQLQualifier *q = nil;
       
    if (cnt == 0) {
      if (resQual == nil)
	break;
	 
      q = qualifier;
      // TODO: not sure whether this is a bug?!
      [q conjoinWithQualifier:resQual];
    }
    else {
      int start  = i;
      int maxIds = 150;

      i += maxIds;
      
      if (i > cnt) {
	i      = cnt;
	maxIds = cnt - start;
      }
      q  = [self _partQualifierForEntity:entity inContext:_context
		 ids:[partIds subarrayWithRange:NSMakeRange(start,maxIds)]];
      if (resQual) {
	// TODO: not sure whether this is a bug?! (resQual is an array)
	[q disjoinWithQualifier:resQual];
      }
         
      if (qualifier)
	[q conjoinWithQualifier:qualifier];
      else
	[self warnWithFormat:@"%s: missing qualifier!", __PRETTY_FUNCTION__];
    }
       
    if ([channel selectAttributes:attributes describedByQualifier:q
		 fetchOrder:[self _getStartDateFetchOrderingWithEntity:entity
				  inContext:_context]
		 lock:NO]) {
      NSDictionary *dict;

      while ((dict = [channel fetchAttributes:attributes withZone:NULL])) {
	/* patch timezone */
	[[dict objectForKey:@"startDate"] setTimeZone:self->timeZone];
	[[dict objectForKey:@"endDate"]   setTimeZone:self->timeZone];
	[result addObject:dict];
      }
      [channel cancelFetch];
    }
  } while (i < cnt);
  
  return result;
}


/* bubble sort (dates should be already sorted) */

- (void)_sortDates:(NSMutableArray *)_dates inContext:(LSCommandContext *)_cx {
  BOOL     isReady = NO;
  unsigned cnt;

  if ((cnt = [_dates count]) == 0)
    return;
  
  while (!isReady) {
    unsigned i;
    
    isReady = YES;
    
    for (i = 0; i < (cnt - 1); i++) {
      NSDictionary *date1;
      NSDictionary *date2;
      NSCalendarDate *startDate1, *startDate2;
      
      date1 = [_dates objectAtIndex:i];
      date2 = [_dates objectAtIndex:(i + 1)];
      startDate1 = [date1 objectForKey:@"startDate"];
      startDate2 = [date2 objectForKey:@"startDate"];
      
      if ([startDate1 compare:startDate2] == NSOrderedDescending) {
        isReady = NO;
        [_dates replaceObjectAtIndex:i       withObject:date2]; 
        [_dates replaceObjectAtIndex:(i + 1) withObject:date1];
      }
    }
  }
}

- (void)_mergeDates:(NSMutableArray *)_dates
  inContext:(LSCommandContext *)_context
{
  unsigned i, cnt;

  if ((cnt = [_dates count]) == 0)
    return;
  
  for (i = 0; i < cnt - 1; i++) {
    // date probably means "appointment" here
    NSDictionary   *date1;
    NSDictionary   *date2;
    NSCalendarDate *endDate1;
    NSCalendarDate *endDate2;
    NSCalendarDate *lEndDate;
    NSDictionary   *dict     = nil;
    
    date1    = [_dates objectAtIndex:i];
    date2    = [_dates objectAtIndex:i + 1];
    endDate1 = [date1 objectForKey:@"endDate"];
    
    if ([endDate1 compare:
                  [date2 objectForKey:@"startDate"]] == NSOrderedAscending)
      continue;
      
    endDate2 = [date2 objectForKey:@"endDate"];
    lEndDate = ([endDate1 compare:endDate2] == NSOrderedDescending)
      ? endDate1
      : endDate2;
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [date1 objectForKey:@"startDate"], @"startDate",
                           lEndDate , @"endDate", nil];
    [_dates removeObjectsInRange:NSMakeRange(i, 2)];
    [_dates insertObject:dict atIndex:i];
    [dict release]; dict = nil;
    i--;
    cnt--;
  }
}

- (BOOL)_getFreeTimeIntervals:(NSArray *)_dates
  forDay:(unsigned)i addToResult:(NSMutableArray *)result
  startDateCursor:(NSCalendarDate **)_sD_ currentDateIndex:(int *)_iDates_
  inContext:(id)_context
{
  // TODO: split up this methods, REFACTOR!
  /*
    Note: the method returns YES if the caller should stop processing further
          slots (limit reached)
          
    Note: *_iDates_ is an *index* into the _dates array.
  */
  double         end                 = 0;
  NSCalendarDate *eD                 = nil;
  BOOL           alreadyAtTheNextDay = NO;
  unsigned cntDates;
  const double steps  = 60;
  const double dur    = self->duration  * 60;
  const double startT = self->startTime * 60;
  const double endT   = self->endTime   * 60;
  
  cntDates = [_dates count];
  
  /* setup start and end date */
  
  *_sD_ = [*_sD_ beginOfDay];
  [*_sD_ setTimeZone:self->timeZone];

  if ([*_sD_ timeIntervalSinceReferenceDate] >
      [self->endDate timeIntervalSinceReferenceDate])
    return NO; /* leave the loop */
  
  if (debugOn) {
      [self logWithFormat:@"########## day number %d", i];
      [self logWithFormat:@"********** sD %@ %g", *_sD_,
            [*_sD_ timeIntervalSinceReferenceDate]];
  }
  end = [*_sD_ timeIntervalSinceReferenceDate] + endT;
  if (debugOn)
    [self logWithFormat:@"********** end %g", end];
    
  *_sD_ = [*_sD_ addTimeInterval:startT];
  [*_sD_ setTimeZone:self->timeZone];
  if (debugOn) {
      [self logWithFormat:@"********** sD after startTime%@ %g", *_sD_,
            [*_sD_ timeIntervalSinceReferenceDate]];
  }
  eD = [*_sD_ addTimeInterval:dur];
  [eD setTimeZone:self->timeZone];
    
  if (debugOn) {
    [self logWithFormat:@"********** eD %@ %g", eD,
            [eD timeIntervalSinceReferenceDate]];
  }

  /* loop */
  
  alreadyAtTheNextDay = NO;
  while ([eD timeIntervalSinceReferenceDate] <= end) {
    NSDictionary   *datesEntry = nil;
    BOOL           foundDate   = NO;
    BOOL           addStep     = YES;
    BOOL           isFirst     = YES;

    if (*_iDates_ < cntDates) {
      NSCalendarDate *entryStart, *entryEnd;

      datesEntry = [_dates objectAtIndex:*_iDates_];
      entryStart = [datesEntry objectForKey:@"startDate"];
      entryEnd   = [datesEntry objectForKey:@"endDate"];
        if (debugOn ) {
          [self logWithFormat:
                  @"********** [sD timeIntervalSinceReferenceDate]<%g"
              @"|%@> - [entryEnd timeIntervalSinceReferenceDate]<%g|%@> = %g",
              [*_sD_ timeIntervalSinceReferenceDate], *_sD_,
              [entryEnd timeIntervalSinceReferenceDate], entryEnd,
              ([*_sD_ timeIntervalSinceReferenceDate] -
               [entryEnd timeIntervalSinceReferenceDate])];
        }
        if ([*_sD_ timeIntervalSinceReferenceDate] -
            [entryEnd timeIntervalSinceReferenceDate] > 0) {
          /* _dates[i] is before sD */
          if (debugOn) {
            [self logWithFormat:@"********** _dates[%@] is before %@ -- %@",
                    datesEntry, *_sD_, eD];
          }
          *_iDates_ = *_iDates_ + 1;
          foundDate = NO;
          addStep   = NO;
        }
        else if ([eD timeIntervalSinceReferenceDate] -
                 [entryStart timeIntervalSinceReferenceDate] <= 0) {
          if (debugOn) {
            [self logWithFormat:@"********** _date[%@] is after %@ -- %@",
                  datesEntry, *_sD_, eD];
          }
          foundDate = YES;
          addStep   = YES;
        }
        else {
          if (isFirst) {
            if ([entryStart timeIntervalSinceReferenceDate] >
                [*_sD_ timeIntervalSinceReferenceDate]) {
              int min = [*_sD_ minuteOfHour];

              if ((min == 0) || (min == 30)) {
                NSDictionary *d;
                
                d = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            *_sD_,      @"startDate",
                                            entryStart, @"endDate",
                                            @"free",    @"kind", nil];
                [result addObject:d];
                [d release];
              }
              isFirst = NO;
            }
          }
          *_sD_ = entryEnd;
          [*_sD_ setTimeZone:self->timeZone];
          
          eD = [*_sD_ addTimeInterval:dur];
          [eD setTimeZone:self->timeZone];
          
          foundDate = NO;
          addStep   = NO;
          if ([[*_sD_ beginOfDay] timeIntervalSinceReferenceDate] > end) {
            alreadyAtTheNextDay = YES;
            break;
          }
          else {
            *_iDates_ = *_iDates_ + 1;
          }
        }
      }
      else /* iDates >= cntDates - means we have reached the soft-limit? */
        foundDate = YES;
      
      if (foundDate) {
        int min = [*_sD_ minuteOfHour];
        
        if (debugOn)
          [self logWithFormat:@"********** found date %@ -- %@", *_sD_, eD];
        
        [*_sD_ setTimeZone:self->timeZone];
        [eD setTimeZone:self->timeZone];
        
        if ((min == 0) || (min == 30)) {
          NSDictionary *d;
          
          d = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      *_sD_, @"startDate", eD, @"endDate",
                                      @"start", @"kind", nil];
          [result addObject:d];
          [d release];
        }
      }
      else if (debugOn) {
        [self logWithFormat:@"********** %@ -- %@ conflicted with %@",
              *_sD_, eD,
              datesEntry];
      }
      
      
      if (debugOn) {
        [self logWithFormat:@"********** next step before %@ %g", *_sD_,
              [*_sD_ timeIntervalSinceReferenceDate]];
      }
      if (addStep) {
        *_sD_ = [*_sD_ addTimeInterval:steps];
        [*_sD_ setTimeZone:self->timeZone];
        eD = [*_sD_ addTimeInterval:dur];
        [eD setTimeZone:self->timeZone];
        
        if (debugOn) {
          [self logWithFormat:@"********** next step after %@ %g", *_sD_,
                [*_sD_ timeIntervalSinceReferenceDate]];
        }
      }
      else if (debugOn) {
        [self logWithFormat:@"no next step"];
      }
      
      if ([eD timeIntervalSinceReferenceDate] > end) {
        if ([*_sD_ timeIntervalSinceReferenceDate] < end) {
          NSCalendarDate *e;
          NSDictionary   *d;
          
          e = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:end];
          [e setTimeZone:self->timeZone];

          d = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      *_sD_,     @"startDate",
                                      e,      @"endDate",
                                      @"end", @"kind", nil];
          [result addObject:d];
          [d release];
        }
      }
  }

  /* after loop */

  if (debugOn) {
      [self logWithFormat:@"********** next day before %@ %g", *_sD_,
            [*_sD_ timeIntervalSinceReferenceDate]];
  }
  if (!alreadyAtTheNextDay) {
      *_sD_ = [*_sD_ addTimeInterval:(24 * 60 * 60)];
      [*_sD_ setTimeZone:self->timeZone];
  }
  if (debugOn) {
      [self logWithFormat:@"********** next day after %@ %g", *_sD_,
            [*_sD_ timeIntervalSinceReferenceDate]];
  }
  if ([result count] > LSAppointmentProposalCommand_MAXSEARCH)
    return NO; /* leave the loop */
  
  return YES;
}

- (NSArray *)_getFreeTimeIntervals:(NSArray *)_dates inContext:(id)_context {
  /* TODO: split up this huge method */
  NSMutableArray *result = nil;
  NSCalendarDate *sD     = nil;
  unsigned i, days;
  int iDates, cntDates;

  result = [NSMutableArray arrayWithCapacity:
                             LSAppointmentProposalCommand_MAXSEARCH];
  
  days = ([self->endDate timeIntervalSinceReferenceDate] -
          [self->startDate timeIntervalSinceReferenceDate]) / 60 / 60 / 24;
  days++;
  
  [self->startDate setTimeZone:self->timeZone];
  [self->startDate setCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
  [self->endDate   setTimeZone:self->timeZone];
  [self->endDate   setCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"];

  if (debugOn) {
    [self logWithFormat:@"********** self->startDate %@", self->startDate];
    [self logWithFormat:@"********** self->endDate %@", self->endDate];
    [self logWithFormat:@"********** _dates %@", _dates];
    [self logWithFormat:@"********** days %d", days];
  }
  
  sD       = self->startDate;
  iDates   = 0;
  cntDates = [_dates count];
  
  for (i = 0; i < days; i++) {
    if (![self _getFreeTimeIntervals:_dates 
               forDay:i addToResult:result
               startDateCursor:&sD currentDateIndex:&iDates
               inContext:_context])
      break;
  }
  if (debugOn) {
    [self logWithFormat:
            @"\n*** _dates \n%@\n***startDate : %@\n***endDate : %@\n"
            @"***result %@\n", _dates, self->startDate, self->endDate, result];
  }
  return result;
}

- (NSCalendarDate *)dateAtHour:(int)_hour minute:(int)_minute second:(int)_sec{
  return [NSCalendarDate dateWithYear:[self->now yearOfCommonEra]
                         month:[self->now monthOfYear]
                         day:[self->now dayOfMonth]
                         hour:_hour
                         minute:_minute
                         second:_sec
                         timeZone:self->timeZone];
}

- (void)setTimeZone:(NSTimeZone *)_zone {
  NSAssert1([_zone isKindOfClass:[NSTimeZone class]],
            @"invalid parameter %@ ..", _zone);
  ASSIGN(self->timeZone, _zone);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"timeZone"]) {
    [self setTimeZone:_value];
  }
  else if ([_key isEqualToString:@"participants"]) {
    ASSIGN(self->participants, _value);
  }
  else if ([_key isEqualToString:@"resources"]) {
    ASSIGN(self->resources, _value);
  }
  else if ([_key isEqualToString:@"duration"])
    self->duration = [_value intValue];
  else if ([_key isEqualToString:@"interval"])
    self->interval = [_value intValue];
  else if ([_key isEqualToString:@"startDate"]) {
    ASSIGN(self->startDate, _value);
  }
  else if ([_key isEqualToString:@"endDate"]) {
    ASSIGN(self->endDate, _value);
  }
  else if ([_key isEqualToString:@"startTime"])
    self->startTime = [_value intValue];
  else if ([_key isEqualToString:@"endTime"])
    self->endTime = [_value intValue];
  else if ([_key isEqualToString:@"categories"]) {
    ASSIGN(self->categories, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"participants"])
    return self->participants;

  if ([_key isEqualToString:@"resources"])
    return self->resources;

  if ([_key isEqualToString:@"duration"])
    return [NSNumber numberWithInt:self->duration];
  
  if ([_key isEqualToString:@"interval"])
    return [NSNumber numberWithInt:self->interval];
  
  if ([_key isEqualToString:@"startDate"])
    return self->startDate;
  if ([_key isEqualToString:@"endDate"])
    return self->endDate;
  
  if ([_key isEqualToString:@"startTime"])
    return [NSNumber numberWithInt:self->startTime];
  if ([_key isEqualToString:@"endTime"])
    return [NSNumber numberWithInt:self->endTime];
  
  if ([_key isEqualToString:@"timeZone"])
    return [self timeZone];
  
  if ([_key isEqualToString:@"categories"])
    return self->categories;
  
  return [super valueForKey:_key];
}

static int compareDates(id part1, id part2, void *context) {
  return ([[part1 valueForKey:@"startDate"]
                  earlierDate:[part2 valueForKey:@"startDate"]] ==
          [part1 valueForKey:@"startDate"]) ? -1 : 1;
}
 
@end /* LSAppointmentProposalCommand */
