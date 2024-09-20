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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSGetLogsCommand : LSDBObjectBaseCommand
@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <GDLAccess/EOSQLQualifier.h>

static int compareLogs(id part1, id part2, void* context) {
  return [(NSDate *)[part1 valueForKey:@"creationDate"]
 		           compare:(NSDate *)
		    [part2 valueForKey:@"creationDate"]];
}

@implementation LSGetLogsCommand

static NSTimeZone *gmt = nil;

+ (void)initialize {
  if (gmt == nil)
    gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
}

/* defaults */

- (id)userDefaultsInContext:(id)_ctx {
  return [_ctx valueForKey:LSUserDefaultsKey];
}
- (NSString *)tzInContext:(id)_ctx {
  return [[self userDefaultsInContext:_ctx] stringForKey:@"timezone"];
}

/* execute */

- (void)_getPrimaryKey:(NSNumber **)_pkey andEntity:(EOEntity **)_entity 
  ofObject:(id)_obj
{
  if (_pkey)   *_pkey = nil;
  if (_entity) *_entity = nil;
  if (_obj == nil) return;
  
  if ([_obj isKindOfClass:[EOKeyGlobalID class]]) {
    if (_pkey) *_pkey = [_obj keyValues][0];
  }
  else if ([_obj isKindOfClass:[NSDictionary class]]) {
    if (_pkey)
      *_pkey = [[[_obj valueForKey:@"globalID"] keyValuesArray] lastObject];
  }
  else {
    if (_entity) *_entity = [[_obj classDescription] entity];
    if (_pkey) {
      *_pkey = [_obj valueForKey:
		       [[*_entity primaryKeyAttributeNames] lastObject]];
    }
  }
}

- (void)_executeInContext:(id)_context {
  /* split up this method */
  NSMutableArray    *result;
  NSNumber          *objectId = nil;
  EOEntity          *objectEntity;
  EOEntity          *logEntity = nil;
  EOAdaptorChannel  *adChannel = nil;
  EOSQLQualifier    *q         = nil;
  NSString          *abbrev;
  NSTimeZone        *tz;
  id                obj        = nil;
  NSArray           *logAttrs  = nil;
  
  tz = ((abbrev = [self tzInContext:_context]))
    ? [NSTimeZone timeZoneWithAbbreviation:abbrev]
    : (NSTimeZone *)nil;
  if (tz == nil) tz = gmt;
  
  adChannel = [[self databaseChannel] adaptorChannel];
  logEntity = [[self databaseModel] entityNamed:@"Log"];
  logAttrs  = [logEntity attributes];
  result    = [NSMutableArray arrayWithCapacity:64];
  
  obj = [self object];

  if (![obj isNotNull]) {
    [self warnWithFormat:@"[%s]: missing object", __PRETTY_FUNCTION__];
    return;
  }
  
  [self _getPrimaryKey:&objectId andEntity:&objectEntity ofObject:obj];
  
  q = [EOSQLQualifier alloc];
  q = [q initWithEntity:logEntity qualifierFormat:@"objectId=%@", objectId];

  [self assert:[adChannel selectAttributes:logAttrs
                          describedByQualifier:q
                          fetchOrder:nil
                          lock:NO]
        reason:[dbMessages description]];
  
  while ((obj = [adChannel fetchAttributes:logAttrs withZone:NULL]) != nil) {
    NSCalendarDate *d;
    id tmp;
    
    /* adjust timezone of dates */
    if ([(d = [obj valueForKey:@"creationDate"]) isNotNull])
      [d setTimeZone:tz];
    
    tmp = [obj mutableCopy];
    [result addObject:tmp];
    [tmp release];
  }
  
  result = (id)[result sortedArrayUsingFunction:compareLogs context:NULL];
  
  if (result) [self setReturnValue:result];
  [q release];
}

@end /* LSGetLogsCommand */
