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

#include "SkyPersonDocument.h"
#include "common.h"
#include "SkyPersonEnterpriseDataSource.h"
#include "SkyPersonDataSource.h"
#include "SkyPersonProjectDataSource.h"

@interface SkyPersonDocument(SkyCompanyDocument)
- (NSDictionary *)_newAttributeMap:(id)_ctx;
- (NSArray *)_newTelephones:(id)_ctx;
@end
@implementation SkyPersonDocumentType
@end /* SkyPersonDocumentType */

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@implementation SkyPersonDocument

- (NSString *)nameOfSetCommand {
  return @"person::set";
}

+ (int)version {
  return [super version];
}
+ (void)initialize {
  NSAssert2([super version] == 8,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

static NSArray * addressTypes = nil;

- (id)initWithEO:(id)_person context:(id)_context {
  EODataSource *ds;
  
  ds = [[[SkyPersonDataSource alloc] initWithContext:_context] autorelease];
  return [self initWithPerson:_person dataSource:ds];
}

// designated initializer
- (id)initWithCompany:(id)_person
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
  addAsObserver:(BOOL)_addAsObserver
{
  if ((self = [super initWithCompany:_person
                     globalID:_gid
                     dataSource:_ds
                     addAsObserver:_addAsObserver])) {
    [self _loadDocument:_person];
    if (addressTypes == nil) {
      NSUserDefaults *ud = [[self context] userDefaults];

      addressTypes = [[ud objectForKey:@"LSAddressType"]
                          objectForKey:@"Person"];
      RETAIN(addressTypes);
    }
  }
  return self;
}

- (id)initWithPerson:(id)_person
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
{
  return [self initWithCompany:_person
               globalID:_gid
               dataSource:_ds
               addAsObserver:YES];
}

- (id)initWithPerson:(id)_person dataSource:(EODataSource *)_ds {
  EOKeyGlobalID *gid;

  if ([_person respondsToSelector:@selector(globalID)])
    gid = (EOKeyGlobalID *)[_person globalID];
  else
    gid = [_person valueForKey:@"globalID"];
  
  return [self initWithPerson:_person globalID:gid dataSource:_ds];
}
- (id)initWithEO:(id)_person dataSource:(EODataSource *)_ds {
  return [self initWithPerson:_person dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds {
  return [self initWithPerson:nil globalID:_gid dataSource:_ds];
}

/* create a virtual document */
- (id)initWithContext:(id)_ctx {
  EODataSource *ds;
  NSDictionary *dict;
  id           own;

  own  = [_ctx valueForKey:LSAccountKey];
  ds   = [[[SkyPersonDataSource alloc] initWithContext:_ctx] autorelease];
  dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [self _newTelephones:_ctx],     @"telephones",
                              [NSNumber numberWithBool:NO],   @"isAccount",
                              [NSNumber numberWithBool:NO],   @"isPrivate",
                              [self _newAttributeMap:_ctx],   @"attributeMap",
                              [own valueForKey:@"companyId"], @"ownerId",
                              nil];
  return [self initWithPerson:dict globalID:nil dataSource:ds];
}

- (void)dealloc {
  RELEASE(self->firstname);
  RELEASE(self->middlename);
  RELEASE(self->name);
  RELEASE(self->number);
  RELEASE(self->nickname);
  RELEASE(self->salutation);
  RELEASE(self->degree);
  RELEASE(self->url);
  RELEASE(self->gender);
  RELEASE(self->birthday);
  RELEASE(self->enterpriseDataSource);

  [self->partnerName       release];
  [self->assistantName     release];
  [self->occupation        release];
  [self->imAddress         release];
  [self->associatedCompany release];
  
  [super dealloc];
}

/* accessors */

- (SkyDocumentType *)documentType {
  static SkyPersonDocumentType *docType = nil;
  
  if (docType == nil)
    docType = [[SkyPersonDocumentType alloc] init];

  return docType;
}

- (EODataSource *)enterpriseDataSource {
  SkyPersonEnterpriseDataSource *ds;

  if (self->globalID == nil) {
    if (self->enterpriseDataSource == nil)
      self->enterpriseDataSource =  [[EOArrayDataSource alloc] init];

    return self->enterpriseDataSource;
  }
  else {
    ds = [[SkyPersonEnterpriseDataSource alloc] initWithContext:[self context]
                                                personId:[self globalID]];
    return AUTORELEASE(ds);
  }
}

- (EODataSource *)projectDataSource {
  SkyPersonProjectDataSource *ds;

  ds = [[SkyPersonProjectDataSource alloc] initWithContext:[self context]
                                           personId:[self globalID]];
  return AUTORELEASE(ds);
}

- (EODataSource *)jobDataSource {
  EODataSource *ds = nil;
  static Class clz = Nil;

  if (clz == Nil)
    clz = NSClassFromString(@"SkyPersonJobDataSource");


  if (self->globalID != nil) {
    ds = [[clz alloc] initWithContext:[self context] personId:[self globalID]];
  }
    
  return AUTORELEASE(ds);
}
  
/* accessors */

- (void)setFirstname:(NSString *)_firstName {
  ASSIGNCOPY_IFNOT_EQUAL(self->firstname, _firstName, self->status.isEdited);
}
- (NSString *)firstname {
  return self->firstname; // "firstname"
}

- (void)setMiddlename:(NSString *)_middlename {
  ASSIGNCOPY_IFNOT_EQUAL(self->middlename, _middlename, self->status.isEdited);
}
- (NSString *)middlename {
  return self->middlename; // "middlename"
}

- (void)setName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name, _name, self->status.isEdited);
}
- (NSString *)name {
  return self->name; // "name"
}

- (void)setNumber:(NSString *)_number {
  ASSIGNCOPY_IFNOT_EQUAL(self->number, _number, self->status.isEdited);
}
- (NSString *)number {
  return self->number; // "number"
}

- (void)setNickname:(NSString *)_nickname {
  ASSIGNCOPY_IFNOT_EQUAL(self->nickname, _nickname, self->status.isEdited);
}
- (NSString *)nickname {
  return self->nickname; // "description"
}

- (void)setSalutation:(NSString *)_salutation {
  ASSIGNCOPY_IFNOT_EQUAL(self->salutation, _salutation, self->status.isEdited);
}
- (NSString *)salutation {
  return self->salutation; // "salutation"
}

- (void)setDegree:(NSString *)_degree {
  ASSIGNCOPY_IFNOT_EQUAL(self->degree, _degree, self->status.isEdited);
}
- (NSString *)degree {
  return self->degree; // "degree"
}

- (void)setBirthday:(NSCalendarDate *)_birthday {
  ASSIGNCOPY_IFNOT_EQUAL(self->birthday, _birthday, self->status.isEdited);
}
- (NSCalendarDate *)birthday {
  return self->birthday; // "birthday"
}

- (void)setUrl:(NSString *)_url {
  if ((![_url isNotNull]) || ([_url isEqualToString:@"http://"])) _url = @"";
  ASSIGNCOPY_IFNOT_EQUAL(self->url, _url, self->status.isEdited);
}
- (NSString *)url {
  return self->url; // "url"
}

- (void)setGender:(NSString *)_gender {
  ASSIGNCOPY_IFNOT_EQUAL(self->gender, _gender, self->status.isEdited);
}
- (NSString *)gender {
  return self->gender; // "sex"
}

- (void)setSex:(NSString *)_sex {
  ASSIGNCOPY_IFNOT_EQUAL(self->gender, _sex, self->status.isEdited);
}
- (NSString *)sex {
  return self->gender; // "sex"
}

- (void)setIsAccount:(BOOL)_flag {
  if (self->isAccount != _flag) {
    self->status.isEdited = YES;
    self->isAccount = _flag;
  }
}
- (BOOL)isAccount {
  return self->isAccount;
}

- (void)setIsPerson:(BOOL)_flag {
  if (self->isPerson != _flag) {
    self->status.isEdited = YES;
    self->isPerson = _flag;
  }
}
- (BOOL)isPerson {
  return self->isPerson;
}

- (void)setLogin:(NSString *)_login {
  ASSIGNCOPY_IFNOT_EQUAL(self->login, _login, self->status.isEdited);
}
- (NSString *)login {
  return self->login;
}

- (void)setPartnerName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->partnerName,_name,self->status.isEdited)
}
- (NSString *)partnerName {
  return self->partnerName;
}
- (void)setAssistantName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->assistantName,_name,self->status.isEdited);
}
- (NSString *)assistantName {
  return self->assistantName;
}
- (void)setOccupation:(NSString *)_oc {
  ASSIGNCOPY_IFNOT_EQUAL(self->occupation,_oc,self->status.isEdited);
}
- (NSString *)occupation {
  return self->occupation;
}
- (void)setImAddress:(NSString *)_address {
  ASSIGNCOPY_IFNOT_EQUAL(self->imAddress,_address,self->status.isEdited);
}
- (NSString *)imAddress {
  return self->imAddress;
}
- (void)setAssociatedCompany:(NSString *)_company {
  ASSIGNCOPY_IFNOT_EQUAL(self->associatedCompany,_company,
                         self->status.isEdited);
}
- (NSString *)associatedCompany {
  return self->associatedCompany;
}

- (NSArray *)addressTypes {
  return addressTypes;
}

- (NSString *)entityName {
  return @"Person";
}

// -----------------------------------------------------------------------

- (void)invalidate {
  RELEASE(self->firstname);    self->firstname    = nil;
  RELEASE(self->middlename);   self->middlename   = nil;
  RELEASE(self->name);         self->name         = nil;
  RELEASE(self->number);       self->number       = nil;
  RELEASE(self->nickname);     self->nickname     = nil;
  RELEASE(self->salutation);   self->salutation   = nil;
  RELEASE(self->degree);       self->degree       = nil;
  RELEASE(self->url);          self->url          = nil;
  RELEASE(self->gender);       self->gender       = nil;
  RELEASE(self->birthday);     self->birthday     = nil;
  RELEASE(self->login);        self->login        = nil;

  [self->partnerName   release];     self->partnerName       = nil;
  [self->assistantName release];     self->assistantName     = nil;
  [self->occupation    release];     self->occupation        = nil;
  [self->imAddress     release];     self->imAddress         = nil;
  [self->associatedCompany release]; self->associatedCompany = nil;

  [super invalidate];
}

/*
    "isReadonly": { auch bei enterprises !!! }


  
    "isPerson": {
    "isIntraAccount": {
    "isExtraAccount": {
    "isCustomer": {
    "priority": {
    "isLocked": {
      
    "password": {
    "imapPasswd": {

    
    # relationships
    
    "toCompanyAssignment1": {
    "toDateCompanyAssignment": {
    "toStaff": {
*/

- (id)asDict {
  id dict = [super asDict];
  
  [dict takeValue:[self firstname]  forKey:@"firstname"];
  [dict takeValue:[self middlename] forKey:@"middlename"];
  [dict takeValue:[self name]       forKey:@"name"];
  [dict takeValue:[self nickname]   forKey:@"description"];
  [dict takeValue:[self number]     forKey:@"number"];
  [dict takeValue:[self salutation] forKey:@"salutation"];
  [dict takeValue:[self degree]     forKey:@"degree"];
  [dict takeValue:[self birthday]   forKey:@"birthday"];
  [dict takeValue:[self url]        forKey:@"url"];
  [dict takeValue:[self gender]     forKey:@"sex"];
  
  [dict takeValue:[self partnerName]       forKey:@"partnerName"];
  [dict takeValue:[self assistantName]     forKey:@"assistantName"];
  [dict takeValue:[self occupation]        forKey:@"occupation"];
  [dict takeValue:[self imAddress]         forKey:@"imAddress"];
  [dict takeValue:[self associatedCompany] forKey:@"associatedCompany"];

  [dict takeValue:[NSNumber numberWithBool:[self isAccount]]
       forKey:@"isAccount"];

  [dict takeValue:[NSNumber numberWithBool:[self isPerson]]
       forKey:@"isPerson"];

  [dict takeValue:[self login]      forKey:@"login"];

  return dict;
}

- (BOOL)save {
  EODataSource *enterpriseDS; // SkyPersonEnterpriseDataSource
  NSArray      *enterprises;
  int  i, cnt;
  BOOL isNew = (self->globalID == nil);

  if (![super save])
    return NO;
  
  if (!isNew)
    return YES;

  // should return a real SkyPersonEnterpriseDataSource now:
  enterpriseDS = [self enterpriseDataSource];
  // self->enterpriseDataSource should be an EOArrayDataSource
  enterprises  = [self->enterpriseDataSource fetchObjects];

  for (i = 0, cnt = [enterprises count]; i < cnt; i++)
    [enterpriseDS insertObject:[enterprises objectAtIndex:i]];
  
  [self->enterpriseDataSource release]; self->enterpriseDataSource = nil;
  return YES;
}

- (void)_loadDocument:(id)_object {
  [super _loadDocument:_object];
  [self setFirstname: [_object valueForKey:@"firstname"]];
  [self setMiddlename:[_object valueForKey:@"middlename"]];
  [self setName:      [_object valueForKey:@"name"]];
  [self setNickname:  [_object valueForKey:@"description"]];
  [self setNumber:    [_object valueForKey:@"number"]];
  [self setSalutation:[_object valueForKey:@"salutation"]];
  [self setDegree:    [_object valueForKey:@"degree"]];
  [self setBirthday:  [_object valueForKey:@"birthday"]];
  [self setUrl:       [_object valueForKey:@"url"]];
  [self setGender:    [_object valueForKey:@"sex"]];
    
  [self setIsAccount: [[_object valueForKey:@"isAccount"] boolValue]];
  [self setIsPerson:  [[_object valueForKey:@"isPerson"] boolValue]];

  [self setLogin:     [_object valueForKey:@"login"]];

  [self setPartnerName:      [_object valueForKey:@"partnerName"]];
  [self setAssistantName:    [_object valueForKey:@"assistantName"]];
  [self setOccupation:       [_object valueForKey:@"occupation"]];
  [self setImAddress:        [_object valueForKey:@"imAddress"]];
  [self setAssociatedCompany:[_object valueForKey:@"associatedCompany"]];
  
  self->status.isValid     = YES;
  self->status.isEdited    = NO;
}

/* actions */

@end /* SkyPersonDocument */
