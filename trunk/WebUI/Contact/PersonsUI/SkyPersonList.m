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

#include <OGoFoundation/OGoContentPage.h>

/*
  Example:

   *.wod:
   
     PersonList: SkyPersonList {
       dataSource   = personDataSource;
       favoritesKey = "person_favorites";
     };

     Buttons: SkyButtons {
       onNew = newPerson;
     }

   *.html:
   
     <#PersonList>
       <#Buttons />
     </#PersonList>
   
*/

@class NSString, NSArray;
@class EODataSource;

@interface SkyPersonList : OGoContentPage
{
@protected
  EODataSource *dataSource;
  id           person;
  NSString     *favoritesKey;
  NSArray      *favoriteCompanyIds;
}
@end /* SkyPersonList */

#include "common.h"
#include <OGoContacts/SkyPersonDocument.h>

@implementation SkyPersonList

- (void)dealloc {
  [self->dataSource         release];
  [self->person             release];
  [self->favoritesKey       release];
  [self->favoriteCompanyIds release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->favoriteCompanyIds release]; self->favoriteCompanyIds = nil;
  [super sleep];
}

/* accessors */

- (void)setDataSource:(EODataSource *)_dataSource {
  ASSIGN(self->dataSource, _dataSource);
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setFavoritesKey:(NSString *)_key {
  ASSIGN(self->favoritesKey,_key);
}
- (NSString *)favoritesKey {
  return [self->favoritesKey length] > 0
    ? self->favoritesKey : @"person_favorites";
}

- (NSArray *)favoriteCompanyIds {
  if (self->favoriteCompanyIds == nil) {
    self->favoriteCompanyIds =
      [[[[self session] userDefaults] arrayForKey:[self favoritesKey]] copy];
  }
  return self->favoriteCompanyIds;
}

- (void)setPerson:(id)_person {
  ASSIGN(self->person, _person);
}
- (id)person {
  return self->person;
}

- (NSString *)personName {
  NSString *s = nil;
  
  if ([self->person isNotNull])
    s = [(SkyPersonDocument *)self->person name];

  return ([s length]) ? s : @"---";
}

- (NSString *)personFirstname {
  NSString *s = nil;

  if ([self->person isNotNull])
    s = [self->person firstname];

  return ([s length]) ? s : @"---";
}

- (NSString *)companyIdString {
  return [[[self person] valueForKey:@"companyId"] stringValue];
}

- (BOOL)isInFavorites {
  return [[self favoriteCompanyIds] containsObject:[self companyIdString]];
}

- (BOOL)_modifyFavorites:(BOOL)_doRemove {
  NSMutableArray *favIds;
  NSUserDefaults *ud;
    
  if (_doRemove && ![self isInFavorites])
    return NO; /* not in favorites */
  if (!_doRemove && [self isInFavorites])
    return NO; /* already in favorites */

  favIds = [[NSMutableArray alloc] initWithArray:[self favoriteCompanyIds]];
    
  if (_doRemove)
    [favIds removeObject:[self companyIdString]];
  else
    [favIds addObject:[self companyIdString]];

  ud = [[self session] userDefaults];
  [ud setObject:favIds forKey:[self favoritesKey]];
  [ud synchronize];
  [self->favoriteCompanyIds release]; self->favoriteCompanyIds = nil;
  [favIds release];
  return YES;
}

/* actions */

- (id)updateFavoritesAction {
  if ([self hasBinding:@"onFavoritesChange"])
    return [self valueForBinding:@"onFavoritesChange"];
  return nil;
}

- (id)addToFavorites {
  [self _modifyFavorites:NO /* NO means "add favorite" */];
  return [self updateFavoritesAction];
}
- (id)removeFromFavorites {
  [self _modifyFavorites:YES /* YES means "remove favorite" */];
  return [self updateFavoritesAction]; 
}

/* actions */

- (id)viewPerson {
  return [self activateObject:[self person] withVerb:@"view"];
}

@end /* SkyPersonList */
