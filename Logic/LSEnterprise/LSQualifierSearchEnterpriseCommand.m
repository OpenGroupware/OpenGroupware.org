/*
  Copyright (C) 2006 Helge Hess

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

#include <LSSearch/LSQualifierSearchCommand.h>

/*
  enterprise::qsearch
  
  TODO: document

  you can define groups of attributes to fetch, e.g.
       "telephones" and
       "extendedAttributes"
*/

@class NSString, NSNumber, NSArray, NSDictionary;
@class EOQualifier;

@interface LSQualifierSearchEnterpriseCommand : LSQualifierSearchCommand
{
}

@end

#include "common.h"

@implementation LSQualifierSearchEnterpriseCommand

static BOOL debugOn = NO;

+ (int)version {
  return [super version] /* v1 */;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if ((debugOn = [ud boolForKey:@"LSDebugQSearch"]))
    NSLog(@"Note: LSDebugQSearch is enabled for %@", NSStringFromClass(self));
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

/* qualifier construction */

- (NSString *)aclOwnerAttributeName {
  return @"ownerId";
}
- (NSString *)aclPrivateAttributeName {
  return @"isPrivate";
}

/* entity */

- (NSString *)entityName {
  return @"Enterprise";
}

@end /* LSQualifierSearchEnterpriseCommand */
