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

#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoPalm/SkyPalmConstants.h>

@implementation SkyPalmAddressDocument

- (id)init {
  if ((self = [super init])) {
    self->workPhone   = nil;
    self->homePhone   = nil;
    self->faxPhone    = nil;
    self->otherPhone  = nil;
    self->emailPhone  = nil;
    self->mainPhone   = nil;
    self->pagerPhone  = nil;
    self->mobilePhone = nil;

    self->address   = nil;
    self->city      = nil;
    self->company   = nil;
    self->country   = nil;
    self->firstname = nil;
    self->lastname  = nil;
    self->note      = nil;
    self->phone0    = nil;
    self->phone1    = nil;
    self->phone2    = nil;
    self->phone3    = nil;
    self->state     = nil;
    self->title     = nil;
    self->zipcode   = nil;
    self->custom1   = nil;
    self->custom2   = nil;
    self->custom3   = nil;
    self->custom4   = nil;

    self->skyrixType = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->address);
  RELEASE(self->city);
  RELEASE(self->company);
  RELEASE(self->country);
  RELEASE(self->firstname);
  RELEASE(self->lastname);
  RELEASE(self->note);
  RELEASE(self->phone0);
  RELEASE(self->phone1);
  RELEASE(self->phone2);
  RELEASE(self->phone3);
  RELEASE(self->phone4);
  RELEASE(self->state);
  RELEASE(self->title);
  RELEASE(self->zipcode);
  RELEASE(self->custom1);
  RELEASE(self->custom2);
  RELEASE(self->custom3);
  RELEASE(self->custom4);

  RELEASE(self->workPhone);
  RELEASE(self->homePhone);
  RELEASE(self->faxPhone);
  RELEASE(self->otherPhone);
  RELEASE(self->emailPhone);
  RELEASE(self->mainPhone);
  RELEASE(self->pagerPhone);
  RELEASE(self->mobilePhone);

  RELEASE(self->skyrixType);
  [super dealloc];
}
#endif

// accessors
- (void)setAddress:(NSString *)_address {
  ASSIGN(self->address,_address);
}
- (NSString *)address {
  return self->address;
}

- (void)setCity:(NSString *)_city {
  ASSIGN(self->city,_city);
}
- (NSString *)city {
  return self->city;
}

- (void)setCompany:(NSString *)_company {
  ASSIGN(self->company,_company);
}
- (NSString *)company {
  return self->company;
}

- (void)setCountry:(NSString *)_country {
  ASSIGN(self->country,_country);
}
- (NSString *)country {
  return self->country;
}

- (void)setDisplayPhone:(int)_dp {
  self->displayPhone = _dp;
}
- (int)displayPhone {
  return self->displayPhone;
}

- (void)setFirstname:(NSString *)_firstname {
  ASSIGN(self->firstname,_firstname);
}
- (NSString *)firstname {
  return self->firstname;
}

- (void)setLastname:(NSString *)_lastname {
  ASSIGN(self->lastname,_lastname);
}
- (NSString *)lastname {
  return self->lastname;
}

- (void)setNote:(NSString *)_note {
  ASSIGN(self->note,_note);
}
- (NSString *)note {
  return self->note;
}

- (void)setPhone0:(NSString *)_phone {
  ASSIGN(self->phone0,_phone);
}
- (NSString *)phone0 {
  return self->phone0;
}

- (void)setPhone1:(NSString *)_phone {
  ASSIGN(self->phone1,_phone);
}
- (NSString *)phone1 {
  return self->phone1;
}

- (void)setPhone2:(NSString *)_phone {
  ASSIGN(self->phone2,_phone);
}
- (NSString *)phone2 {
  return self->phone2;
}

- (void)setPhone3:(NSString *)_phone {
  ASSIGN(self->phone3,_phone);
}
- (NSString *)phone3 {
  return self->phone3;
}

- (void)setPhone4:(NSString *)_phone {
  ASSIGN(self->phone4,_phone);
}
- (NSString *)phone4 {
  return self->phone4;
}

- (void)setPhoneLabelId0:(int)_val {
  self->phoneLabelId0 = _val;
}
- (int)phoneLabelId0 {
  return self->phoneLabelId0;
}

- (void)setPhoneLabelId1:(int)_val {
  self->phoneLabelId1 = _val;
}
- (int)phoneLabelId1 {
  return self->phoneLabelId1;
}

- (void)setPhoneLabelId2:(int)_val {
  self->phoneLabelId2 = _val;
}
- (int)phoneLabelId2 {
  return self->phoneLabelId2;
}

- (void)setPhoneLabelId3:(int)_val {
  self->phoneLabelId3 = _val;
}
- (int)phoneLabelId3 {
  return self->phoneLabelId3;
}

- (void)setPhoneLabelId4:(int)_val {
  self->phoneLabelId4 = _val;
}
- (int)phoneLabelId4 {
  return self->phoneLabelId4;
}

- (void)setState:(NSString *)_state {
  ASSIGN(self->state,_state);
}
- (NSString *)state {
  return self->state;
}

- (void)setTitle:(NSString *)_title {
  ASSIGN(self->title,_title);
}
- (NSString *)title {
  return self->title;
}

- (void)setZipcode:(NSString *)_code {
  ASSIGN(self->zipcode,_code);
}
- (NSString *)zipcode {
  return self->zipcode;
}

- (void)setCustom1:(NSString *)_custom {
  ASSIGN(self->custom1,_custom);
}
- (NSString *)custom1 {
  return self->custom1;
}

- (void)setCustom2:(NSString *)_custom {
  ASSIGN(self->custom2,_custom);
}
- (NSString *)custom2 {
  return self->custom2;
}

- (void)setCustom3:(NSString *)_custom {
  ASSIGN(self->custom3,_custom);
}
- (NSString *)custom3 {
  return self->custom3;
}

- (void)setCustom4:(NSString *)_custom {
  ASSIGN(self->custom4,_custom);
}
- (NSString *)custom4 {
  return self->custom4;
}

- (void)setSkyrixType:(NSString *)_type {
  ASSIGN(self->skyrixType,_type);
}
- (NSString *)skyrixType {
  return self->skyrixType;
}

- (NSString *)work {
  return self->workPhone;
}
- (NSString *)home {
  return self->homePhone;
}
- (NSString *)fax {
  return self->faxPhone;
}
- (NSString *)other {
  return self->otherPhone;
}
- (NSString *)email {
  return self->emailPhone;
}
- (NSString *)main {
  return self->mainPhone;
}
- (NSString *)pager {
  return self->pagerPhone;
}
- (NSString *)mobile {
  return self->mobilePhone;
}

- (NSString *)description {
  if ((self->firstname != nil) && (self->lastname != nil))
    return [NSString stringWithFormat:@"%@, %@",
                     self->lastname, self->firstname];

  if (self->lastname != nil)
    return self->lastname;
  if (self->firstname != nil)
    return self->firstname;
  if (self->company != nil)
    return self->company;

  return @"SkyPalmAddressDocument";
}

- (NSMutableString *)_md5Source {
  NSMutableString *src = [NSMutableString stringWithCapacity:32];

  [src appendString:[self address]];
  [src appendString:[self city]];
  [src appendString:[self company]];
  [src appendString:[self country]];
  [src appendString:[self custom1]];
  [src appendString:[self custom2]];
  [src appendString:[self custom3]];
  [src appendString:[self custom4]];
  [src appendString:[self firstname]];
  [src appendString:[self lastname]];
  [src appendString:[self note]];
  [src appendString:[self phone0]];
  [src appendString:[self phone1]];
  [src appendString:[self phone2]];
  [src appendString:[self phone3]];
  [src appendString:[self phone4]];
  [src appendString:
       [[NSNumber numberWithInt:[self phoneLabelId0]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self phoneLabelId1]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self phoneLabelId2]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self phoneLabelId3]] stringValue]];
  [src appendString:
       [[NSNumber numberWithInt:[self phoneLabelId4]] stringValue]];
  [src appendString:[self state]];
  [src appendString:[self title]];
  [src appendString:[self zipcode]];

  [src appendString:[super _md5Source]];
  return src;
}

// additional
- (NSString *)_appendPhone:(NSString *)_phone toString:(NSString *)_src {
  if ([_src isEqualToString:@""])
    return _phone;
  if ([_phone isEqualToString:@""])
    return _src;
  return [NSString stringWithFormat:@"%@, %@", _src, _phone];
}

- (void)_computePhoneValues {
  NSString *work   = @"";   // 0
  NSString *home   = @"";   // 1
  NSString *fax    = @"";   // 2
  NSString *other  = @"";   // 3
  NSString *email  = @"";   // 4
  NSString *mainP  = @"";   // 5
  NSString *pager  = @"";   // 6
  NSString *mobile = @"";   // 7
    
  NSNumber *labelId  = nil;
  NSString *labelKey = nil;
  NSString *value    = nil;
  int      lid       = 0;
  int      pos       = 0;

  for (pos = 0; pos < 5; pos++) {
    labelKey = [NSString stringWithFormat:@"phoneLabelId%d", pos];
    labelId = [self valueForKey:labelKey];
    if (labelId != nil) {
      labelKey = [NSString stringWithFormat:@"phone%d", pos];
      value    = [self valueForKey:labelKey];
      if (value == nil)
        value = @"";
        
      lid      = [labelId intValue];
      switch (lid) {
          case PALM_ADDRESS_PHONE_WORK:
            work =   [self _appendPhone:value toString:work];
            break;
          case PALM_ADDRESS_PHONE_HOME:
            home =   [self _appendPhone:value toString:home];
            break;
          case PALM_ADDRESS_PHONE_FAX:
            fax  =   [self _appendPhone:value toString:fax];
            break;
          case PALM_ADDRESS_PHONE_OTHER:
            other =  [self _appendPhone:value toString:other];
            break;
          case PALM_ADDRESS_PHONE_EMAIL:
            email =  [self _appendPhone:value toString:email];
            break;
          case PALM_ADDRESS_PHONE_MAIN:
            mainP =  [self _appendPhone:value toString:mainP];
            break;
          case PALM_ADDRESS_PHONE_PAGER:
            pager =  [self _appendPhone:value toString:pager];
            break;
          case PALM_ADDRESS_PHONE_MOBILE:
            mobile = [self _appendPhone:value toString:mobile];
            break;
        }
    }
  }
  ASSIGN(self->workPhone,work);
  ASSIGN(self->homePhone,home);
  ASSIGN(self->faxPhone,fax);
  ASSIGN(self->otherPhone,other);
  ASSIGN(self->emailPhone,email);
  ASSIGN(self->mainPhone,mainP);
  ASSIGN(self->pagerPhone,pager);
  ASSIGN(self->mobilePhone,mobile);
}

// overwriting
- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  [self setAddress:       [_dict valueForKey:@"address"]];
  [self setCity:          [_dict valueForKey:@"city"]];
  [self setCompany:       [_dict valueForKey:@"company"]];
  [self setCountry:       [_dict valueForKey:@"country"]];
  [self setDisplayPhone:  [[_dict valueForKey:@"display_phone"] intValue]];
  [self setFirstname:     [_dict valueForKey:@"firstname"]];
  [self setLastname:      [_dict valueForKey:@"lastname"]];
  [self setNote:          [_dict valueForKey:@"note"]];
  [self setPhone0:        [_dict valueForKey:@"phone0"]];
  [self setPhone1:        [_dict valueForKey:@"phone1"]];
  [self setPhone2:        [_dict valueForKey:@"phone2"]];
  [self setPhone3:        [_dict valueForKey:@"phone3"]];
  [self setPhone4:        [_dict valueForKey:@"phone4"]];
  [self setPhoneLabelId0: [[_dict valueForKey:@"phone_label_id0"] intValue]];
  [self setPhoneLabelId1: [[_dict valueForKey:@"phone_label_id1"] intValue]];
  [self setPhoneLabelId2: [[_dict valueForKey:@"phone_label_id2"] intValue]];
  [self setPhoneLabelId3: [[_dict valueForKey:@"phone_label_id3"] intValue]];
  [self setPhoneLabelId4: [[_dict valueForKey:@"phone_label_id4"] intValue]];
  [self setState:         [_dict valueForKey:@"state"]];
  [self setTitle:         [_dict valueForKey:@"title"]];
  [self setZipcode:       [_dict valueForKey:@"zipcode"]];
  [self setCustom1:       [_dict valueForKey:@"custom1"]];
  [self setCustom2:       [_dict valueForKey:@"custom2"]];
  [self setCustom3:       [_dict valueForKey:@"custom3"]];
  [self setCustom4:       [_dict valueForKey:@"custom4"]];

  [self setSkyrixType:    [_dict valueForKey:@"skyrix_type"]];

  [self _computePhoneValues];
  
  [super takeValuesFromDictionary:_dict];
}

- (NSMutableDictionary *)asDictionary {
  NSMutableDictionary *dict = [super asDictionary];

  [self _takeValue:self->address   forKey:@"address" toDict:dict];
  [self _takeValue:self->city      forKey:@"city" toDict:dict];
  [self _takeValue:self->company   forKey:@"company" toDict:dict];
  [self _takeValue:self->country   forKey:@"country" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->displayPhone]
        forKey:@"display_phone" toDict:dict];
  [self _takeValue:self->firstname forKey:@"firstname" toDict:dict];
  [self _takeValue:self->lastname  forKey:@"lastname" toDict:dict];
  [self _takeValue:self->note      forKey:@"note" toDict:dict];
  [self _takeValue:self->phone0    forKey:@"phone0" toDict:dict];
  [self _takeValue:self->phone1    forKey:@"phone1" toDict:dict];
  [self _takeValue:self->phone2    forKey:@"phone2" toDict:dict];
  [self _takeValue:self->phone3    forKey:@"phone3" toDict:dict];
  [self _takeValue:self->phone4    forKey:@"phone4" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->phoneLabelId0]
        forKey:@"phone_label_id0" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->phoneLabelId1]
        forKey:@"phone_label_id1" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->phoneLabelId2]
        forKey:@"phone_label_id2" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->phoneLabelId3]
        forKey:@"phone_label_id3" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->phoneLabelId4]
         forKey:@"phone_label_id4" toDict:dict];
  [self _takeValue:self->state     forKey:@"state" toDict:dict];
  [self _takeValue:self->title     forKey:@"title" toDict:dict];
  [self _takeValue:self->zipcode   forKey:@"zipcode" toDict:dict];
  [self _takeValue:self->custom1   forKey:@"custom1" toDict:dict];
  [self _takeValue:self->custom2   forKey:@"custom2" toDict:dict];
  [self _takeValue:self->custom3   forKey:@"custom3" toDict:dict];
  [self _takeValue:self->custom4   forKey:@"custom4" toDict:dict];

  [self _takeValue:self->skyrixType forKey:@"skyrix_type" toDict:dict];

  return dict;
}

- (void)takeValuesFromDocument:(SkyPalmDocument *)_doc {
  SkyPalmAddressDocument *doc = (SkyPalmAddressDocument *)_doc;
  [self setAddress:      [doc address]];
  [self setCity:         [doc city]];
  [self setCompany:      [doc company]];
  [self setCountry:      [doc country]];
  [self setDisplayPhone: [doc displayPhone]];
  [self setFirstname:    [doc firstname]];
  [self setLastname:     [doc lastname]];
  [self setNote:         [doc note]];
  [self setPhone0:       [doc phone0]];
  [self setPhone1:       [doc phone1]];
  [self setPhone2:       [doc phone2]];
  [self setPhone3:       [doc phone3]];
  [self setPhone4:       [doc phone4]];
  [self setPhoneLabelId0:[doc phoneLabelId0]];
  [self setPhoneLabelId1:[doc phoneLabelId1]];
  [self setPhoneLabelId2:[doc phoneLabelId2]];
  [self setPhoneLabelId3:[doc phoneLabelId3]];
  [self setPhoneLabelId4:[doc phoneLabelId4]];
  [self setState:        [doc state]];
  [self setTitle:        [doc title]];
  [self setZipcode:      [doc zipcode]];
  [self setCustom1:      [doc custom1]];
  [self setCustom2:      [doc custom2]];
  [self setCustom3:      [doc custom3]];
  [self setCustom4:      [doc custom4]];

  [self _computePhoneValues];

  [super takeValuesFromDocument:_doc];
}

- (void)prepareAsNew {
  [super prepareAsNew];

  [self setPhoneLabelId0:0];
  [self setPhoneLabelId1:0];
  [self setPhoneLabelId2:0];
  [self setPhoneLabelId3:0];
  [self setPhoneLabelId4:0];
  [self setDisplayPhone:0];
  [self setSkyrixType:@"person"];
}
- (NSString *)insertNotificationName {
  return SkyNewPalmAddressNotification;
}
- (NSString *)updateNotificationName {
  return SkyUpdatedPalmAddressNotification;
}
- (NSString *)deleteNotificationName {
  return SkyDeletedPalmAddressNotification;
}

// action
- (id)save {
  NSString *key   = nil;
  int      dPhone = [self displayPhone];
  int      i      = 0;
  int      label  = 0;
  BOOL     valid  = NO;
  id       result = nil;
  
  for (i = 0; i < 8; i++) {
    key   = [NSString stringWithFormat:@"phoneLabelId%d", i];
    label = [[self valueForKey:key] intValue];
    if (label == dPhone) {
      key = [NSString stringWithFormat:@"phone%d", i];
      if ([[self valueForKey:key] length] > 0) {
        valid = YES;
        break;
      }
    }
  }

  if (!valid) {
    dPhone = 0;
    for (i = 0; i < 8; i++) {
      key = [NSString stringWithFormat:@"phone%d", i];
      if ([[self valueForKey:key] length] > 0) {
        key    = [NSString stringWithFormat:@"phoneLabelId%d", i];
        dPhone = [[self valueForKey:key] intValue];
        break;
      }
    }
    [self setDisplayPhone:dPhone];
  }

  result = [super save];
  [self _computePhoneValues];
  return result;
}

@end /* SkyPalmAddressDocument */


@implementation SkyPalmAddressDocumentSelection

- (Class)mustBeClass {
  return [SkyPalmAddressDocument class];
}

@end /* SkyPalmAddressDocumentSelection */
