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
   
     EnterpriseList: SkyEnterpriseList {
       dataSource = enterpriseDataSource;
       onFavoritesChange = updateFavoritesAction;
     };

     Buttons: SkyButtons {
       onNew = newEnterprise;
     }

   *.html:
   
     <#EnterpriseList>
       <#Buttons />
     </#EnterpriseList>
   
*/

@interface SkyEnterpriseList : OGoListComponent
{
@protected
  int currentBatch;
}

@end

#include "common.h"

@implementation SkyEnterpriseList

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

/* accessors */

- (NSString *)defaultFavoritesKey {
  return [self->favoritesKey isNotEmpty]
    ? self->favoritesKey : (NSString *)@"enterprise_favorites";
}

- (void)setCurrentBatch:(int)_val {
  self->currentBatch = _val;
}
- (int)currentBatch {
  return self->currentBatch;
}

- (NSString *)itemIdString {
  return [[[self item] valueForKey:@"companyId"] stringValue];
}

/* deprecated */

- (id)viewEnterprise { // DEPRECATED
  return [self viewItem];
}

- (void)setEnterprise:(id)_person { // DEPRECATED
  [self setItem:_person];
}
- (id)enterprise { // DEPRECATED
  return [self item];
}

@end /* SkyEnterpriseList */
