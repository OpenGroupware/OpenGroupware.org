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

#include <OGoDocuments/SkyDocumentManager.h>
#include "SkyJobDocument.h"
#include "SkyPersonJobDataSource.h"
#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@interface SkyJobDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
@end

@implementation SkyJobDocumentGlobalIDResolver

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos
  withType:(NSString *)_type
  documentManager:(id<SkyDocumentManager>)_dm
{
  unsigned i, count;
  NSMutableArray *result;

  if (_eos == nil)                 return [NSArray array];
  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    EODataSource  *ds;
    EOKeyGlobalID *personGid = nil;
    id doc;
    id job;
    
    job = [_eos objectAtIndex:i];
    if (_type)
      [job takeValue:_type forKey:@"type"];

    if ([job valueForKey:@"executantId"]) {
      id values[1];

      values[0] = [job valueForKey:@"executantId"];
      
      personGid = [EOKeyGlobalID globalIDWithEntityName:@"Job"
                                 keys:values keyCount:1 zone:NULL];
    }
    ds  = [[SkyPersonJobDataSource alloc] initWithContext:[_dm context]
                                          personId:personGid];
    doc = [[SkyJobDocument alloc] initWithEO:job dataSource:ds];
    [ds release]; ds = nil;
    [result addObject:doc];
    [doc release]; doc = nil;
  }
  return result;
}

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Job"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  NSArray *eos;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];

  eos = [[_dm context]
              runCommand:@"object::get-by-globalid", @"gids", _gids, nil];
  return [self _morphEOsToDocuments:eos
               withType:@"toDoJob"
               documentManager:_dm];
}

@end /* SkyJobDocumentGlobalIDResolver */


