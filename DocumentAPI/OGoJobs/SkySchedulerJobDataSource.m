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

#include "SkySchedulerJobDataSource.h"
#include <NGExtensions/NGBundleManager.h>
#include "SkyPersonJobDataSource.h"
#include "SkyJobDocument.h"
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOSortOrdering.h>
#include <EOControl/EOFetchSpecification.h>
#include <NGExtensions/NSCalendarDate+misc.h>
#include "common.h"

@interface SkySchedulerJobDocument : SkyDocument
{
  id                  job;        // the job document
  NSCalendarDate      *startDate; // starts at 11:00 on duedate
  NSCalendarDate      *endDate;   // ends   at 12:00 on duedate
  NSMutableDictionary *aptValues; // saving appointment values
}

- (id)initWithJob:(id)_job timeZone:(id)_tz;

@end /* SkySchedulerJobDocument */

@interface EOQualifier(SkyAppointmentQualifier)
- (NSArray *)companies;
- (NSArray *)aptTypes;
- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;
- (NSTimeZone *)timeZone;
@end /* EOQualifier(SkyAppointmentQualifier) */

@implementation SkySchedulerJobDataSource

- (id)initWithContext:(id)_ctx {
  if ((self = [self init])) {
    NSBundle *bundle;
    ASSIGN(self->ctx,_ctx);

    // try to load 'SkyScheduler.ds bundle'
    bundle = [[NGBundleManager defaultBundleManager]
                               bundleWithName:@"OGoScheduler" type:@"ds"];
    if (![bundle load]) {
      NSLog(@"ERROR[%s]: SkyScheduler.ds bundle needed",
            __PRETTY_FUNCTION__);
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [self->ctx   release];
  [self->fSpec release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  // TODO: post change notification!
  ASSIGNCOPY(self->fSpec,_fSpec);
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fSpec;
}

- (NSTimeZone *)timeZone {
  NSTimeZone *tzone  = nil;
  NSString   *abbrev;

  abbrev = [[self->ctx valueForKey:LSUserDefaultsKey]
                       objectForKey:@"timezone"];

  if (abbrev != nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:abbrev];
  if (tzone == nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:@"MET"];

  return tzone;
}

- (NSArray *)fetchObjects {
  static Class         qualClass = NULL;
  EOQualifier          *qual;
  EOFetchSpecification *fs;
  NSArray              *comps, *aptTypes;
  NSCalendarDate       *start, *end;
  NSTimeZone           *timeZone;

  if (qualClass == NULL)
    qualClass = NSClassFromString(@"SkyAppointmentQualifier");

  fs = [self fetchSpecification];

  if ((qual = [fs qualifier]) == nil)  return [NSArray array];
  if (![qual isKindOfClass:qualClass]) return [NSArray array];

  start = [qual startDate];
  end   = [qual endDate];

  timeZone = [self timeZone];

  if ((!start) || (!end)) return [NSArray array];

  aptTypes = [qual aptTypes];
  if ([aptTypes count]) {
    if (([aptTypes count] != 1) ||
        (![[aptTypes lastObject] isEqualToString:@"_todojob_"]))
      return [NSArray array];
  }

  comps = [qual companies];

  // TODO: split up
  switch ([comps count]) {
    case 0: return [NSArray array];
    case 1: {
      id one = [comps lastObject];
      if (!([[one entityName] isEqualToString:@"Person"] ||
            [[one entityName] isEqualToString:@"Account"])) 
        return [NSArray array];
      {
        id          ds;
        NSArray     *jobs;
        id          so;
        
        ds = [[SkyPersonJobDataSource alloc]
                                      initWithContext:self->ctx personId:one];
        qual = [EOQualifier qualifierWithQualifierFormat:@"type='toDoJob'"];
        [ds setFetchSpecification:
            [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                  qualifier:qual sortOrderings:nil]];

        jobs = [ds fetchObjects];
        [ds release]; ds = nil;

        if (![jobs count]) return [NSArray array];

        qual = [EOQualifier qualifierWithQualifierFormat:
                            @"startDate<%@ AND endDate>%@",
                            end, start];
        jobs = [jobs filteredArrayUsingQualifier:qual];

        if ((so = [fs sortOrderings]) != nil)
          jobs = [jobs sortedArrayUsingKeyOrderArray:so];
        {
          NSEnumerator   *e;
          NSMutableArray *ma;

          e = [jobs objectEnumerator];
          ma = [NSMutableArray arrayWithCapacity:[jobs count]];


          while ((one = [e nextObject])) {
            one = [[SkySchedulerJobDocument alloc] initWithJob:one
                                                   timeZone:timeZone];
            [ma addObject:one];
            [one release]; one = nil;
          }
          jobs = ma; // stays mutable ...
        }
        return jobs;
      }
      
    }
    default: {
      return [NSArray array];
    }
  }
  return [NSArray array];
}

@end /* SkySchedulerJobDataSource */

@implementation SkySchedulerJobDocument

- (id)initWithJob:(id)_job timeZone:(id)_tz {
  if ((self = [super init])) {
    NSCalendarDate *date;
    
    date = [_job endDate];
    [date setTimeZone:_tz];
    date = [date beginOfDay];
    self->job = [_job retain];
    
    self->startDate = [date dateByAddingYears:0 months:0 days:0
                            hours:11 minutes:0 seconds:0];
    self->startDate = [self->startDate retain];
    self->endDate = [self->startDate dateByAddingYears:0 months:0 days:0
                         hours:1 minutes:0 seconds:0];
    self->endDate = [self->endDate retain];
    self->aptValues = [[NSMutableDictionary alloc] initWithCapacity:4];
  }
  return self;
}

- (void)dealloc {
  [self->job       release];
  [self->startDate release];
  [self->endDate   release];
  [self->aptValues release];
  [super dealloc];
}

/* accessors */

- (NSCalendarDate *)startDate {
  return self->startDate;
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (NSString *)permissions {
  // view always allowed
  return @"v";  // view
}
- (BOOL)isViewAllowed {
  return YES;
}

- (NSString *)title {
  // TODO: cast is wrong, what type is self->job? EO? (if so, use valueForKey)
  return [(EOEntity *)self->job name];
}

- (EOGlobalID *)globalID {
  return [self->job globalID];
}

- (NSNumber *)ownerId {
  return [(EOKeyGlobalID *)[[self->job creator] globalID] keyValues][0];
}
- (NSArray *)participants {
  return [NSArray arrayWithObject:[self->job executor]];
}

- (NSString *)aptType {
  static NSString *jobAptType = nil;
  if (jobAptType == nil)
    jobAptType = [[NSString alloc] initWithString:@"_todojob_"];
  return jobAptType;
}

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"members"]) 
    [self->aptValues takeValue:_val forKey:_key];
  else
    [super takeValue:_val forKey:_key];
}
- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"members"])
    return [self->aptValues valueForKey:_key];
  return [super valueForKey:_key];
}

@end /* SkySchedulerJobDocument */
