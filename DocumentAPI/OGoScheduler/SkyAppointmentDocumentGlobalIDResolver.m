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

#include "SkyAppointmentDataSource.h"
#include "common.h"

@implementation SkyAppointmentDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Date"])
    return NO;
  
  return YES;
}

- (EOFetchSpecification *)newFetchSpecForGIDs:(NSArray *)_gids {
  EOFetchSpecification *fSpec;
  NSDictionary         *hints;
  
  hints = [NSDictionary dictionaryWithObjectsAndKeys:_gids, @"fetchGIDs",nil];
  fSpec = [[EOFetchSpecification alloc] init];
  [fSpec setHints:hints];
  return fSpec;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyAppointmentDataSource *ds;
  EOFetchSpecification *fSpec;
  NSArray              *result;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [[SkyAppointmentDataSource alloc] initWithContext:[_dm context]];
  if (ds == nil)
    return nil;
  
  fSpec = [self newFetchSpecForGIDs:_gids];
  [ds setFetchSpecification:fSpec];
  result = [ds fetchObjects];
  [fSpec release];
  [ds release];
  
  return result;
}

@end /* SkyAppointmentDocumentGlobalIDResolver */
