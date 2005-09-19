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

#include "LSWAppointmentEditor+Fetches.h"
#include "common.h"

@implementation LSWAppointmentEditor(Fetches)

- (void)_fetchEnterprisesOfPersons:(NSArray *)_persons {
  if ([_persons count] == 0)
    return;
  
  [self runCommand:@"person::enterprises",
        @"persons",     _persons,
        @"relationKey", @"enterprises", nil];
}
- (NSArray *)_fetchTeams {
  id loginEO;
  
  loginEO = [[self existingSession] activeAccount];
  return [self runCommand:@"account::teams", @"object", loginEO, nil];
}

- (NSArray *)_fetchPersonsForGIDs:(NSArray *)_gids {
  if ([_gids count] == 0) return [NSArray array];
  return [self runCommand:@"person::get-by-globalID", @"gids", _gids,nil];
}
- (NSArray *)_fetchTeamsForGIDs:(NSArray *)_gids {
  if ([_gids count] == 0) return [NSArray array];
  return [self runCommand:@"team::get-by-globalID", @"gids", _gids, nil];
}

- (NSArray *)_fetchParticipantsOfAppointment:(id)_apt force:(BOOL)_force {
  NSArray *ps;
  
  if (_apt == nil) return nil;
  
  if (!_force) {
    ps = [_apt valueForKey:@"participants"];
    if ([ps isNotNull]) return ps;
  }
  
  [self runCommand:@"appointment::get-participants",
          @"appointment", _apt, nil];
  ps = [_apt valueForKey:@"participants"];
  return [ps isNotNull] ? ps : nil;
}

- (NSArray *)_fetchPartCoreInfoOfAppointment:(id)_apt {
  // Note: 'groupBy' is unsupported for simple fetches in list-parts
  static NSArray *coreInfo = nil;
  if (coreInfo == nil)
    coreInfo = [[NSArray alloc] initWithObjects:@"companyId", @"role", nil];
  return [self runCommand:@"appointment::list-participants",
                 @"gid", [_apt globalID], 
                 @"attributes", coreInfo,
               nil];
}

- (NSString *)_getCommentOfAppointment:(id)_apt {
  NSString *c;
  
  c = [_apt valueForKey:@"comment"];
  if ([c isNotNull]) return c;

  // TODO: remove automatic fault handling?!
  c = [[_apt valueForKey:@"toDateInfo"] valueForKey:@"comment"];
  if ([c isNotNull]) return c;
  
  return nil;
}

- (id)_fetchAccountForPrimaryKey:(id)_pkey {
  id c;
  if (_pkey == nil) return nil;
  
  c = [self runCommand:@"account::get", @"companyId", _pkey, nil];
  if ([c isKindOfClass:[NSArray class]])
    c = [c lastObject];
  return c;
}
- (id)_fetchAccountOrTeamForPrimaryKey:(id)_pkey {
  id res;
  if (_pkey == nil) return nil;
  
  res = [self runCommand:@"account::get", @"companyId", _pkey, nil];
  if ([res count] == 0)
    res = [self runCommand:@"team::get", @"companyId", _pkey, nil];
  
  res = ([res count] > 0) ? [res lastObject] : nil;
  return res;
}

- (id)_fetchAppointmentForPrimaryKey:(id)_pkey {
  return [[self runCommand:@"appointment::get", @"dateId", _pkey, nil] 
           lastObject];
}
- (NSArray *)_fetchCyclicAppointmentsOfAppointment:(id)_apt {
  return [self runCommand:@"appointment::get-cyclic", @"object", _apt, nil];
}

@end /* LSWAppointmentEditor(Fetches) */
