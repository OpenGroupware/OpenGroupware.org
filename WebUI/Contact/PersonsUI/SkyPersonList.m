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

#include <OGoFoundation/OGoListComponent.h>

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

@interface SkyPersonList : OGoListComponent
{
  NSMutableDictionary *_companyCache;
}

@end

#include "common.h"
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>

@implementation SkyPersonList

+ (int)version {
  return [super version] + 0 /* v4 */;
}
+ (void)initialize {
  NSAssert2([super version] == 4,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->_companyCache release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->_companyCache release];
  self->_companyCache = nil;
  [super sleep];
}

/* config */

- (NSString *)defaultFavoritesKey {
  return @"person_favorites";
}
- (NSString *)defaultConfigKey {
  return @"person_defaultlist";
}

- (NSArray *)configOptList {
  static NSArray *lConfigOptList = nil;
  if (lConfigOptList == nil) {
    lConfigOptList = [[[NSUserDefaults standardUserDefaults] 
			arrayForKey:@"person_defaultlist_opts"] copy];
  }
  return lConfigOptList;
}

- (NSString *)itemIdString { /* used for favorites */
  return [[[self item] valueForKey:@"companyId"] stringValue];
}

- (NSString *)personName {
  NSString *s = nil;
  
  if ([[self item] isNotNull])
    s = [(SkyPersonDocument *)[self item] name];

  return [s isNotEmpty] ? s : (NSString *)@"---";
}

- (NSString *)personFirstname {
  NSString *s = nil;

  if ([[self item] isNotNull])
    s = [[self item] firstname];

  return [s isNotEmpty] ? s : (NSString *)@"---";
}

/* company column support */

/**
 * Returns cached enterprise documents for the
 * current item, excluding groups (isEnterprise==NO).
 * Fetches and caches on first access per item.
 */
- (NSArray *)_enterprisesForCurrentItem {
  NSNumber *pid;
  NSArray  *cached;

  pid = [[self item] companyId];
  if (pid == nil) return nil;

  if (self->_companyCache == nil) {
    self->_companyCache =
      [[NSMutableDictionary alloc]
          initWithCapacity:32];
  }

  cached = [self->_companyCache objectForKey:pid];
  if (cached == nil) {
    NSArray        *all;
    NSMutableArray *filtered;
    unsigned       i, count;

    all = [[[self item] enterpriseDataSource]
              fetchObjects];
    count    = [all count];
    filtered = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
      SkyEnterpriseDocument *ent;
      ent = [all objectAtIndex:i];
      if ([ent isEnterprise])
        [filtered addObject:ent];
    }
    [self->_companyCache setObject:filtered forKey:pid];
    cached = filtered;
  }
  return cached;
}

/* column values */

- (id)currentColumnValue {
  NSString *col = [self currentColumn];

  if ([col hasPrefix:@"company."]) {
    NSArray        *ents;
    NSMutableArray *values;
    NSString       *attr;
    unsigned       i, count;

    attr  = [col substringFromIndex:8];
    ents  = [self _enterprisesForCurrentItem];
    count = [ents count];
    if (count == 0) return @"";

    values = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
      NSString *v;
      v = [[ents objectAtIndex:i] valueForKey:attr];
      if ([v isNotEmpty]) [values addObject:v];
    }
    [values sortUsingSelector:
        @selector(caseInsensitiveCompare:)];
    return [values componentsJoinedByString:@", "];
  }
  return [super currentColumnValue];
}

/* deprecated */

- (id)viewPerson { // DEPRECATED
  return [self viewItem];
}
- (void)setPerson:(id)_person { // DEPRECATED
  [self setItem:_person];
}
- (id)person { // DEPRECATED
  return [self item];
}

@end /* SkyPersonList */
