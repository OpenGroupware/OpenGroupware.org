/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "SkyEnterpriseDataSource.h"
#include "SkyEnterpriseDocument.h"
#include "common.h"

@implementation SkyEnterpriseDataSource

static NSSet *nativeKeys = nil;

- (void)_registerForChangeNotifications {
  NSNotificationCenter *nc;
    
  nc = [self notificationCenter];
  [nc addObserver:self selector:@selector(enterpriseWasChanged:)
      name:SkyNewEnterpriseNotification object:nil];
  [nc addObserver:self selector:@selector(enterpriseWasChanged:)
      name:SkyUpdatedEnterpriseNotification object:nil];
  [nc addObserver:self selector:@selector(enterpriseWasChanged:)
      name:SkyDeletedEnterpriseNotification object:nil];
}

- (id)initWithContext:(LSCommandContext *)_context {
  if ((self = [super initWithContext:_context]) != nil) {
    if (nativeKeys == nil) {
      EOModel *model;

      model = [[[self->context valueForKey:LSDatabaseKey] adaptor] model];
      
      nativeKeys = [[NSSet alloc] initWithArray:
                           [[[model entityNamed:@"Enterprise"] attributes]
                                    map:@selector(name)]];
    }
  }
  return self;
}

- (Class)documentClass {
  return [SkyEnterpriseDocument class];
}
- (NSSet *)nativeKeys {
  return nativeKeys;
}

/* notifications */

- (void)enterpriseWasChanged:(id)_obj {
  [self postDataSourceChangedNotification];
}

/* commands */

- (NSString *)nameOfEntity {
  return @"Enterprise";
}

- (NSString *)_mapKeyFromEOToDoc:(NSString *)_key {
  if ([_key isEqualToString:@"description"])
    return @"name";
  
  return [super _mapKeyFromEOToDoc:_key];
}
- (NSString *)_mapKeyFromDocToEO:(NSString *)_key {
  if ([_key isEqualToString:@"name"])
    return @"description";
  
  return [super _mapKeyFromDocToEO:_key];
}

- (NSString *)nameOfNewCompanyNotification {
  return SkyNewEnterpriseNotification;
}
- (NSString *)nameOfUpdatedCompanyNotification {
  return SkyUpdatedEnterpriseNotification;
}
- (NSString *)nameOfDeletedCompanyNotification {
  return SkyDeletedEnterpriseNotification;
}

- (id)createObject {
  return [[(SkyEnterpriseDocument *)[SkyEnterpriseDocument alloc] 
				    initWithContext:self->context]
                                  autorelease];
}


@end /* SkyEnterpriseDataSource */

@implementation SkyEnterpriseDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Enterprise"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyEnterpriseDataSource *ds;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [SkyEnterpriseDataSource alloc]; // keep gcc happy
  ds = [ds initWithContext:[_dm context]];
  if (ds == nil)
    return nil;
  ds = [ds autorelease];

  return [ds _fetchObjectsForGlobalIDs:_gids];
}

@end /* SkyEnterpriseDocumentGlobalIDResolver */
