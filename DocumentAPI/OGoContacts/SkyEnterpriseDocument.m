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

#include "SkyEnterpriseDocument.h"
#include "common.h"
#include "SkyEnterprisePersonDataSource.h"
#include "SkyEnterpriseDataSource.h"
#include "SkyEnterpriseProjectDataSource.h"
#include "SkyEnterpriseAllProjectsDataSource.h"

@interface SkyEnterpriseDocument(SkyCompanyDocument)
- (NSDictionary *)_newAttributeMap:(id)_ctx;
- (NSArray *)_newTelephones:(id)_ctx;
@end

@implementation SkyEnterpriseDocumentType
@end /* SkyEnterpriseDocumentType */

@implementation SkyEnterpriseDocument

static NSArray * addressTypes = nil;

+ (int)version {
  return [super version];
}
+ (void)initialize {
  NSAssert2([super version] == 8,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initWithEO:(id)_enterprise context:(LSCommandContext *)_context {
  SkyEnterpriseDataSource *ds;
  
  ds = [SkyEnterpriseDataSource alloc];
  ds = [ds initWithContext:_context];
  self = [self initWithEnterprise:_enterprise dataSource:ds];
  [ds release];
  return self;
}

/* designated initializer */
- (id)initWithCompany:(id)_enterprise
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
  addAsObserver:(BOOL)_addAsObserver
{
  if ((self = [super initWithCompany:_enterprise
                     globalID:_gid
                     dataSource:_ds
                     addAsObserver:_addAsObserver]) != nil) {
    [self _loadDocument:_enterprise];
    if (addressTypes == nil) {
      NSUserDefaults *ud = [[self context] userDefaults];
      
      addressTypes = [[[ud dictionaryForKey:@"LSAddressType"]
                           objectForKey:@"Enterprise"] retain];
    }
  }
  return self;
}

- (id)initWithEnterprise:(id)_enterprise
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
{
  return [self initWithCompany:_enterprise
               globalID:_gid
               dataSource:_ds
               addAsObserver:YES];
}


- (id)initWithEnterprise:(id)_enterprise dataSource:(EODataSource *)_ds {
  EOKeyGlobalID *gid;

  gid = [_enterprise valueForKey:@"globalID"];
  return [self initWithEnterprise:_enterprise globalID:gid dataSource:_ds];
}
- (id)initWithEO:(id)_enterprise dataSource:(EODataSource *)_ds {
  return [self initWithEnterprise:_enterprise dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds {
  return [self initWithEnterprise:nil globalID:_gid dataSource:_ds];
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  SkyEnterpriseDataSource *ds;
  NSDictionary *dict;
  id           own;

  own  = [_ctx valueForKey:LSAccountKey];
  ds   = [SkyEnterpriseDataSource alloc]; // keep gcc happy
  ds   = [ds initWithContext:_ctx];
  dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [self _newTelephones:_ctx],     @"telephones",
                              [self _newAttributeMap:_ctx],   @"attributeMap",
                              [own valueForKey:@"companyId"], @"ownerId",
                              nil];
  
  self = [self initWithEnterprise:dict globalID:nil dataSource:ds];
  [ds release];
  return self;
}

- (void)dealloc {
  [self->number   release];
  [self->name     release];
  [self->priority release];
  [self->url      release];
  [self->bank     release];
  [self->bankCode release];
  [self->account  release];
  [self->email    release];   // ??? (hh: who placed these marks ?)
  [self->login    release];   // ???

  [super dealloc];
}

- (SkyDocumentType *)documentType {
  static SkyEnterpriseDocumentType *docType = nil;
  
  if (docType == nil)
    docType = [[SkyEnterpriseDocumentType alloc] init];

  return docType;
}

- (EODataSource *)personDataSource {
  SkyEnterprisePersonDataSource *ds;

  ds = [SkyEnterprisePersonDataSource alloc]; // keep gcc happy
  ds = [ds initWithContext:[self context] enterpriseId:[self globalID]];
  return [ds autorelease];
}

- (EODataSource *)projectDataSource {
  SkyEnterpriseProjectDataSource *ds;

  ds = [SkyEnterpriseProjectDataSource alloc]; // keep gcc happy
  ds = [ds initWithContext:[self context] enterpriseId:[self globalID]];
  return [ds autorelease];
}

- (EODataSource *)allProjectsDataSource {
  SkyEnterpriseAllProjectsDataSource *ds;

  ds = [SkyEnterpriseAllProjectsDataSource alloc]; // keep gcc happy
  ds = [ds initWithContext:[self context] enterpriseId:[self globalID]];
  return [ds autorelease];
}

/* accessors */

- (void)setNumber:(NSString *)_number {
  ASSIGNCOPY_IFNOT_EQUAL(self->number, _number, self->status.isEdited);
}
- (NSString *)number {
  return self->number; // "number"
}
 
- (void)setName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name, _name, self->status.isEdited);
}
- (NSString *)name {
  return self->name; // "description"
}

- (void)setPriority:(NSString *)_priority {
  ASSIGNCOPY_IFNOT_EQUAL(self->priority, _priority, self->status.isEdited);
}
- (NSString *)priority {
  return self->priority; // "priority"
}

- (void)setSalutation:(NSString *)_salutation {
  ASSIGNCOPY_IFNOT_EQUAL(self->salutation, _salutation, self->status.isEdited);
}
- (NSString *)salutation {
  return self->salutation; // "salutation"
}

- (void)setUrl:(NSString *)_url {
  if ([_url isEqualToString:@"http://"]) _url = @"";
  ASSIGNCOPY_IFNOT_EQUAL(self->url, _url, self->status.isEdited);
}
- (NSString *)url {
  return self->url; // "url"
}

- (void)setBank:(NSString *)_bank {
  ASSIGNCOPY_IFNOT_EQUAL(self->bank, _bank, self->status.isEdited);
}
- (NSString *)bank {
  return self->bank; // "bank"
}

- (void)setBankCode:(NSString *)_bankCode {
  ASSIGNCOPY_IFNOT_EQUAL(self->bankCode, _bankCode, self->status.isEdited);
}
- (NSString *)bankCode {
  return self->bankCode; // "bankCode"
}

- (void)setAccount:(NSString *)_account {
  ASSIGNCOPY_IFNOT_EQUAL(self->account, _account, self->status.isEdited);
}
- (NSString *)account {
  return self->account;
}
 
- (void)setLogin:(NSString *)_login {
  ASSIGNCOPY_IFNOT_EQUAL(self->login, _login, self->status.isEdited);
}
- (NSString *)login {
  return self->login;
}
 
- (void)setEmail:(NSString *)_email {
  ASSIGNCOPY_IFNOT_EQUAL(self->email, _email, self->status.isEdited);
}
- (NSString *)email {
  return self->email;
}

- (void)setIsEnterprise:(BOOL)_flag {
  if (self->isEnterprise != _flag) {
    self->status.isEdited = YES;
    self->isEnterprise = _flag;
  }
}
- (BOOL)isEnterprise {
  return self->isEnterprise;
}

- (NSArray *)addressTypes {
  return addressTypes;
}

- (NSString *)entityName {
  return @"Enterprise";
}

- (void)invalidate {
  [self->number   release]; self->number     = nil;
  [self->name     release]; self->name       = nil;
  [self->priority release]; self->priority   = nil;
  [self->url      release]; self->url        = nil;
  [self->bank     release]; self->bank       = nil;
  [self->bankCode release]; self->bankCode   = nil;
  [self->account  release]; self->account    = nil;
  [self->email    release]; self->email      = nil;
  [self->login    release]; self->login      = nil;
  
  [super invalidate];
}

- (NSDictionary *)asDict {
  id dict;
  
  dict = [super asDict]; // TODO? should be mutable?
  [dict takeValue:[self number]   forKey:@"number"];
  [dict takeValue:[self name]     forKey:@"description"];
  [dict takeValue:[self priority] forKey:@"priority"];
  [dict takeValue:[self url]      forKey:@"url"];
  [dict takeValue:[self bank]     forKey:@"bank"];
  [dict takeValue:[self bankCode] forKey:@"bankCode"];
  [dict takeValue:[self account]  forKey:@"account"];
  [dict takeValue:[self email]    forKey:@"email"];
  [dict takeValue:[self login]    forKey:@"login"];
  [dict takeValue:[NSNumber numberWithBool:[self isEnterprise]]
       forKey:@"isEnterprise"];

  return dict;
}

- (void)_loadDocument:(id)_object {
  [super _loadDocument:_object];
  [self setNumber:    [_object valueForKey:@"number"]];
  [self setName:      [_object valueForKey:@"description"]];
  [self setPriority:  [_object valueForKey:@"priority"]];
  [self setUrl:       [_object valueForKey:@"url"]];
  [self setBank:      [_object valueForKey:@"bank"]];
  [self setBankCode:  [_object valueForKey:@"bankCode"]];
  [self setAccount:   [_object valueForKey:@"account"]];
  [self setEmail:     [_object valueForKey:@"email"]];
  [self setLogin:     [_object valueForKey:@"login"]];
  [self setIsEnterprise:  [[_object valueForKey:@"isEnterprise"] boolValue]];

  self->status.isValid     = YES;  
  self->status.isEdited    = NO;
}

@end /* SkyEnterpriseDocument */
