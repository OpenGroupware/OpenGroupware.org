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

#include "SkyJobAction+PrivateMethods.h"
#include "SkyJobAction.h"
#include "JobPool.h"
#include "Job.h"
#include "common.h"
#include <OGoDaemon/SDXmlRpcFault.h>

@implementation SkyJobAction(PrivateMethods)

- (BOOL)_executantIsTeam:(NSString *)_executantId {
  EOGlobalID *gid;

  gid = [[[self commandContext] documentManager] globalIDForURL:_executantId];
  if ([[gid entityName] isEqualToString:@"Team"])
    return YES;
  return NO;
}

- (id)_setJobStatus:(NSString *)_status
  forJobId:(NSString *)_id
  withComment:(NSString *)_comment
{
  return [[self jobPool] setJobStatus:_status withComment:_comment
                         forJobWithId:_id];
}

- (NSArray *)_getJobsWithQualifier:(SkyJobQualifier *)_qual {
  return [[self jobPool] getJobsWithQualifier:_qual];
}

- (NSDictionary *)_buildDictionaryForAttributes:(NSString *)_query
  :(NSString *)_personURL:(NSString *)_teamId:(NSString *)_sel:(NSString *)_key
  :(NSNumber *)_ordering:(NSNumber *)_groups
{
  NSMutableDictionary *dict;
  
  dict = [NSMutableDictionary dictionaryWithCapacity:6];
  if (_query != nil && [_query length] > 0)
    [dict setObject:_query forKey:@"query"];

  _personURL = [_personURL stringValue];
  if (_personURL != nil && [_personURL length] > 0) 
    [dict setObject:_personURL forKey:@"personURL"];

  if (_teamId != nil && [_teamId length] > 0)
    [dict setObject:_teamId forKey:@"teamId"];
  
  if (_sel != nil && [_sel length] > 0)
    [dict setObject:_sel forKey:@"time"];
  
  if (_key != nil && [_key length] > 0) {
    [dict setObject:_key forKey:@"sortKey"];
    [dict setObject:_ordering forKey:@"sortDescending"];
  }

  if (_groups != nil)
    [dict setObject:_groups forKey:@"showGroups"];

  return (NSDictionary *)dict;
}

/* valid dictionary elements */

- (id)_validStartDate:(NSDate *)_date {
  if (_date != nil)
    return _date;
  return [NSCalendarDate date];
}

- (id)_validEndDate:(NSDate *)_date {
  if (_date != nil)
    return _date;

  return [NSCalendarDate dateWithYear:2032 month:12 day:31
                         hour:12 minute:0 second:0 timeZone:nil];
}

- (id)_validExecutantId:(NSString *)_executantId {
  id ctx;

  ctx = [self commandContext];

  if (_executantId == nil)
    return [[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];

  else if ([_executantId isKindOfClass:[NSString class]]) {
    if ([_executantId hasPrefix:@"skyrix://"])
      return [_executantId lastPathComponent];

    else {
      id result = nil;

      result = [ctx runCommand:@"account::get-by-login",
                    @"login", _executantId,
                    @"suppressAdditionalInfos",
                    [NSNumber numberWithBool:YES],
                    nil];

      if (result != nil)
        return [result objectForKey:@"companyId"];
      else {
        [self logWithFormat:@"ERROR: Invalid login '%@'", _executantId];
        return [SDXmlRpcFault invalidObjectFaultForId:_executantId
                              entity:@"login"];
      }
    }
  }
  return nil;
}

- (NSNumber *)_validPriority:(NSNumber *)_priority {
  if ([_priority intValue] != 0)
    return _priority;
  return [NSNumber numberWithInt:3];
}

@end /* SkyJobAction(PrivateMethods) */
