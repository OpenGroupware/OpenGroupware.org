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
}

@end

#include "common.h"
#include <OGoContacts/SkyPersonDocument.h>

@implementation SkyPersonList

+ (int)version {
  return [super version] + 0 /* v4 */;
}
+ (void)initialize {
  NSAssert2([super version] == 4,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
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

- (NSString *)itemIdString {
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
