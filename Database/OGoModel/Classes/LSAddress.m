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

#include "LSAddress.h"
#include "common.h"
#import <EOControl/EONull.h>

#ifdef USE_EO_RECORDS

@implementation LSAddress

static EONull *null = nil;

+ (void)initialize {
  if (null == nil) null = [[EONull null] retain];
}

- (void)setAllAttributesToEONull {
  self->addressId = RETAIN(null);
  self->companyId = RETAIN(null);
  self->name1     = RETAIN(null);
  self->name2     = RETAIN(null);
  self->name3     = RETAIN(null);
  self->street    = RETAIN(null);
  self->zip       = RETAIN(null);
  self->country   = RETAIN(null);
  self->state     = RETAIN(null);
  self->type      = RETAIN(null);
  self->dbStatus  = RETAIN(null);
}

- (void)dealloc {
  [EODatabase forgetObject:self];
  
  RELEASE(self->toCompany);
  RELEASE(self->companyId);

  RELEASE(self->addressId);
  RELEASE(self->name1);
  RELEASE(self->name2);
  RELEASE(self->name3);
  RELEASE(self->street);
  RELEASE(self->zip);
  RELEASE(self->country);
  RELEASE(self->state);
  RELEASE(self->type);
  RELEASE(self->dbStatus);
  [super dealloc];
}

- (void)setCompanyId:(NSNumber *)_value {
  ASSIGN(self->companyId, _value);
}
- (NSNumber *)companyId {
  return self->companyId;
}

- (void)setAddressId:(NSNumber *)_value {
  ASSIGN(self->addressId, _value);
}
- (NSNumber *)addressId {
  return self->addressId;
}
- (void)setName1:(NSString *)_value {
  ASSIGN(self->name1, _value);
}
- (NSString *)name1 {
  return self->name1;
}
- (void)setName2:(NSString *)_value {
  ASSIGN(self->name2, _value);
}
- (NSString *)name2 {
  return self->name2;
}
- (void)setName3:(NSString *)_value {
  ASSIGN(self->name3, _value);
}
- (NSString *)name3 {
  return self->name3;
}
- (void)setStreet:(NSString *)_value {
  ASSIGN(self->street, _value);
}
- (NSString *)street {
  return self->street;
}
- (void)setZip:(NSString *)_value {
  ASSIGN(self->zip, _value);
}
- (NSString *)zip {
  return self->zip;
}
- (void)setCountry:(NSString *)_value {
  ASSIGN(self->country, _value);
}
- (NSString *)country {
  return self->country;
}
- (void)setState:(NSString *)_value {
  ASSIGN(self->state, _value);
}
- (NSString *)state {
  return self->state;
}
- (void)setType:(NSString *)_value {
  ASSIGN(self->type, _value);
}
- (NSString *)type {
  return self->type;
}
- (void)setDbStatus:(NSString *)_value {
  ASSIGN(self->dbStatus, _value);
}
- (NSString *)dbStatus {
  return self->dbStatus;
}

/* relationships */

- (void)setToEnterprise:(id)_object {
  ASSIGN(self->toCompany, _object);
}
- (id)toEnterprise {
  return self->toCompany;
}

- (void)setToPerson:(id)_object {
  ASSIGN(self->toCompany, _object);
}
- (id)toPerson {
  return self->toCompany;
}

- (void)setToTeam:(id)_object {
  ASSIGN(self->toCompany, _object);
}
- (id)toTeam {
  return self->toCompany;
}

@end

#else

@implementation LSAddress
@end

#endif
