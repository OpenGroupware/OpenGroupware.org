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

#include "LSTelephone.h"
#include "common.h"
#import <EOControl/EONull.h>

#ifdef USE_EO_RECORDS

@implementation LSTelephone

static EONull *null = nil;
+ (void)initialize {
  if (null == nil) null = [[EONull null] retain];
}

- (void)setAllAttributesToEONull {
  self->telephoneId = RETAIN(null);
  self->companyId   = RETAIN(null);
  self->number      = RETAIN(null);
  self->realNumber  = RETAIN(null);
  self->type        = RETAIN(null);
  self->info        = RETAIN(null);
  self->url         = RETAIN(null);
  self->dbStatus    = RETAIN(null);
}

- (void)dealloc {
  [EODatabase forgetObject:self];
  
  RELEASE(self->toCompany);
  
  RELEASE(self->telephoneId);
  RELEASE(self->companyId);
  RELEASE(self->number);
  RELEASE(self->realNumber);
  RELEASE(self->type);
  RELEASE(self->info);
  RELEASE(self->url);
  RELEASE(self->dbStatus);
  [super dealloc];
}

- (void)setTelephoneId:(NSNumber *)_value {
  ASSIGN(self->telephoneId, _value);
}
- (NSNumber *)telephoneId {
  return self->telephoneId;
}
- (void)setCompanyId:(NSNumber *)_value {
  ASSIGN(self->companyId, _value);
}
- (NSNumber *)companyId {
  return self->companyId;
}
- (void)setNumber:(NSString *)_value {
  ASSIGN(self->number, _value);
}
- (NSString *)number {
  return self->number;
}
- (void)setRealNumber:(NSString *)_value {
  ASSIGN(self->realNumber, _value);
}
- (NSString *)realNumber {
  return self->realNumber;
}
- (void)setType:(NSString *)_value {
  ASSIGN(self->type, _value);
}
- (NSString *)type {
  return self->type;
}
- (void)setInfo:(NSString *)_value {
  ASSIGN(self->info, _value);
}
- (NSString *)info {
  return self->info;
}
- (void)setUrl:(NSString *)_value {
  ASSIGN(self->url, _value);
}
- (NSString *)url {
  return self->url;
}
- (void)setDbStatus:(NSString *)_value {
  ASSIGN(self->dbStatus, _value);
}
- (NSString *)dbStatus {
  return self->dbStatus;
}

- (void)setToPerson:(id)_object {
  ASSIGN(self->toCompany, _object);
}
- (id)toPerson {
  return self->toCompany;
}

- (void)setToEnterprise:(id)_object {
  ASSIGN(self->toCompany, _object);
}
- (id)toEnterprise {
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

@implementation LSTelephone
@end

#endif
