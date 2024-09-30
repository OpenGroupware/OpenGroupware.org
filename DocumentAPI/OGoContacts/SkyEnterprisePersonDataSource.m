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

#include "SkyEnterprisePersonDataSource.h"
#include "SkyPersonDataSource.h"
#include "common.h"

@implementation SkyEnterprisePersonDataSource

- (id)initWithContext:(id)_ctx enterpriseId:(EOGlobalID *)_gid {
  return [super initWithContext:_ctx companyId:_gid];
}

- (void)dealloc {
  [self->personDS release];
  [super dealloc];
}

/* accessors */

- (NSString *)destinyEntityName {
  return @"Person";
}

- (NSString *)nameOfGetByGIDCommand {
  return @"person::get-by-globalid";
}

- (NSString *)_mapKeyFromDocToEO:(NSString *)_key {
  if ([_key isEqualToString:@"nickname"])
    return @"description";
  if ([_key isEqualToString:@"gender"])
    return @"sex";
  
  return [super _mapKeyFromDocToEO:_key];
}

- (EODataSource *)companyDataSource {
  if (self->personDS == nil) {
    self->personDS = 
      [[SkyPersonDataSource alloc] initWithContext:self->context];
  }
  return self->personDS;
}

- (Class)documentClass {
  static Class clazz = Nil;
  if (clazz == Nil) clazz = NGClassFromString(@"SkyPersonDocument");
  return clazz;
}

@end /* SkyEnterprisePersonDataSource */
