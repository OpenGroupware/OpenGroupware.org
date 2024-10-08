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

#include "SkyPersonEnterpriseDataSource.h"
#include "SkyEnterpriseDataSource.h"
#include "common.h"

@implementation SkyPersonEnterpriseDataSource

- (id)initWithContext:(id)_ctx personId:(EOGlobalID *)_gid {
  return [super initWithContext:_ctx companyId:_gid];
}

- (void)dealloc {
  [self->enterpriseDS release];
  [super dealloc];
}

/* subclass setup */

- (NSString *)nameOfGetByGIDCommand {
  return @"enterprise::get-by-globalid";
}

- (NSString *)destinyEntityName {
  return @"Enterprise";
}

- (NSString *)_mapKeyFromDocToEO:(NSString *)_key {
  if ([_key isEqualToString:@"name"])
    return @"description";
  
  return [super _mapKeyFromDocToEO:_key];
}

- (EODataSource *)companyDataSource {
  if (self->enterpriseDS == nil) {
    self->enterpriseDS = [SkyEnterpriseDataSource alloc];
    self->enterpriseDS = [self->enterpriseDS initWithContext:self->context];
  }
  return self->enterpriseDS;
}

- (Class)documentClass {
  static Class clazz = Nil;
  if (clazz == Nil) clazz = NGClassFromString(@"SkyEnterpriseDocument");
  return clazz;
}

@end /* SkyPersonEnterpriseDataSource */
