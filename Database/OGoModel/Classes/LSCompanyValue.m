/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "LSCompanyValue.h"
#include "common.h"
#import <EOControl/EONull.h>

#ifdef USE_EO_RECORDS

@implementation LSCompanyValue

static EONull *null = nil;
+ (void)initialize {
  if (null == nil) null = [[EONull null] retain];
}

- (void)setAllAttributesToEONull {
  self->companyValueId   = RETAIN(null);
  self->attribute        = RETAIN(null);
  self->value            = RETAIN(null);
  self->isEnum           = RETAIN(null);
  self->dbStatus         = RETAIN(null);
  self->uid              = RETAIN(null);
  self->type             = RETAIN(null);
  self->label            = RETAIN(null);
  self->isLabelLocalized = RETAIN(null);
  self->companyId        = RETAIN(null);
}

- (void)dealloc {
  [EODatabase forgetObject:self];
  
  RELEASE(self->toCompany);
  RELEASE(self->companyId);

  RELEASE(self->companyValueId);
  RELEASE(self->attribute);
  RELEASE(self->value);
  RELEASE(self->isEnum);
  RELEASE(self->dbStatus);
  RELEASE(self->uid);
  RELEASE(self->type);
  RELEASE(self->label);
  RELEASE(self->isLabelLocalized);
  
  [super dealloc];
}

- (void)setCompanyId:(NSNumber *)_value {
  ASSIGN(self->companyId, _value);
}
- (NSNumber *)companyId {
  return self->companyId;
}

- (void)setCompanyValueId:(NSNumber *)_value {
  ASSIGN(self->companyValueId, _value);
}
- (NSNumber *)companyValueId {
  return self->companyValueId;
}
- (void)setAttribute:(NSString *)_value {
  ASSIGN(self->attribute, _value);
}
- (NSString *)attribute {
  return self->attribute;
}
- (void)setValue:(NSString *)_value {
  ASSIGN(self->value, _value);
}
- (NSString *)value {
  return self->value;
}
- (void)setIsEnum:(NSNumber *)_value {
  ASSIGN(self->isEnum, _value);
}
- (NSNumber *)isEnum {
  return self->isEnum;
}
- (void)setDbStatus:(NSString *)_value {
  ASSIGN(self->dbStatus, _value);
}
- (NSString *)dbStatus {
  return self->dbStatus;
}
- (void)setUid:(NSNumber *)_value {
  ASSIGN(self->uid, _value);
}
- (NSNumber *)uid {
  return self->uid;
}
- (void)setType:(NSNumber *)_value {
  ASSIGN(self->type, _value);
}
- (NSNumber *)type {
  return self->type;
}
- (void)setLabel:(NSString *)_value {
  ASSIGN(self->label, _value);
}
- (NSString *)label {
  return self->label;
}
- (void)setIsLabelLocalized:(NSNumber *)_value {
  ASSIGN(self->isLabelLocalized, _value);
}
- (NSNumber *)isLabelLocalized {
  return self->isLabelLocalized;
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

@implementation LSCompanyValue
@end

#endif
