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

#include "SkyPersonDataSource.h"
#include "SkyPersonDocument.h"
#include "common.h"

// TODO: try to avoid inheritance from SkyCompanyDataSource

@implementation SkyPersonDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

static NSSet *nativeKeys = nil;

- (void)_registerForChangeNotifications {
  NSNotificationCenter *nc;
    
  nc = [self notificationCenter];
  [nc addObserver:self selector:@selector(personWasChanged:)
      name:SkyNewPersonNotification object:nil];
  [nc addObserver:self selector:@selector(personWasChanged:)
      name:SkyUpdatedPersonNotification object:nil];
  [nc addObserver:self selector:@selector(personWasChanged:)
      name:SkyDeletedPersonNotification object:nil];
}

- (id)initWithContext:(id)_context {
  if ((self = [super initWithContext:_context])) {
    if (nativeKeys == nil) {
      // hack, we can only use one EOModel here
      EOModel *model;
      NSArray *tmp;
      
      model = [[[self->context valueForKey:LSDatabaseKey] adaptor] model];
      tmp   = [[[model entityNamed:@"Person"] attributes] map:@selector(name)];
      nativeKeys = [[NSSet alloc] initWithArray:tmp];
    }
  }
  return self;
}

/* accessors */

- (Class)documentClass {
  return [SkyPersonDocument class];
}
- (NSSet *)nativeKeys {
  return nativeKeys;
}

/* notifications */

- (void)personWasChanged:(id)_obj {
  [self postDataSourceChangedNotification];
}

/* commands */

- (NSString *)nameOfFullSearchCommand {
  return @"person::full-search";
}
- (NSString *)nameOfExtSearchCommand {
  return @"person::extended-search";
}
- (NSString *)nameOfGetCommand {
  return @"person::get";
}
- (NSString *)nameOfDeleteCommand {
  return @"person::delete";
}
- (NSString *)nameOfNewCommand {
  return @"person::new";
}
- (NSString *)nameOfSetCommand {
  return @"person::set";
}
- (NSString *)nameOfGetByGIDCommand {
  return @"person::get-by-globalid";
}

- (NSString *)nameOfEntity {
  return @"Person";
}

- (NSString *)nameOfNewCompanyNotification {
  return SkyNewPersonNotification;
}
- (NSString *)nameOfUpdatedCompanyNotification {
  return SkyUpdatedPersonNotification;
}
- (NSString *)nameOfDeletedCompanyNotification {
  return SkyDeletedPersonNotification;
}

- (NSString *)_mapKeyFromEOToDoc:(NSString *)_key {
  if ([_key isEqualToString:@"description"])
    return @"nickname";
  if ([_key isEqualToString:@"sex"])
    return @"gender";
  
  return [super _mapKeyFromEOToDoc:_key];
}
- (NSString *)_mapKeyFromDocToEO:(NSString *)_key {
  if ([_key isEqualToString:@"nickname"])
    return @"description";
  if ([_key isEqualToString:@"gender"])
    return @"sex";
  
  return [super _mapKeyFromDocToEO:_key];
}

- (id)createObject {
  return [[[SkyPersonDocument alloc] initWithContext:self->context]
                              autorelease];
}

@end /* SkyPersonDataSource */

@implementation SkyPersonDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Person"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyPersonDataSource *ds;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [[SkyPersonDataSource alloc] initWithContext:[_dm context]];
  if (ds == nil)
    return nil;
  ds = [ds autorelease];

  return [ds _fetchObjectsForGlobalIDs:_gids];
}

/* NSCopying */

- (id)copyWithZone:(NSZone *)_zone {
  /* required by MacOSX */
  return [self retain];
}

@end /* SkyPersonDocumentGlobalIDResolver */
