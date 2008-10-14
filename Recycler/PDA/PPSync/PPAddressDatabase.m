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

#include "PPAddressDatabase.h"
#include "PPAddressPacker.h"
#include "PPClassDescription.h"
#include "common.h"

static EONull *null = nil;

enum {
  entryLastname, entryFirstname, entryCompany, 
  entryPhone1, entryPhone2, entryPhone3, entryPhone4, entryPhone5,
  entryAddress, entryCity, entryState, entryZip, entryCountry, entryTitle,
  entryCustom1, entryCustom2, entryCustom3, entryCustom4,
  entryNote
};

@implementation PPAddressDatabase

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

- (void)dealloc {
  int i;
  for (i = 0; i < 8; i++)
    RELEASE(self->phoneLabels[i]);
  for (i = 0; i < 22; i++)
    RELEASE(self->labels[i]);
  [super dealloc];
}

/* accessors */

- (int)country {
  return self->country;
}
- (BOOL)sortByCompany {
  return self->sortByCompany;
}

/* phone labels */

- (NSString *)phoneLabelForType:(PPAddressPhoneType)_idx {
  if ((_idx < 0) || (_idx > 8)) {
    NSLog(@"cannot get phone label at index %i", _idx);
    return nil;
  }
  return self->phoneLabels[_idx];
}
- (NSArray *)phoneLabels {
  NSMutableArray *array;
  int i;

  array = [NSMutableArray arrayWithCapacity:8];
  for (i = 0; i < 8; i++) {
    if ([self->phoneLabels[i] length] > 0)
      [array addObject:self->phoneLabels[i]];
  }
  return array;
}

- (PPAddressPhoneType)typeOfPhoneLabel:(NSString *)_label {
  int i;

  if (_label == nil)      return NSNotFound;
  if (_label == (id)null) return NSNotFound;
  
  for (i = 0; i < 8; i++) {
    if ([self->phoneLabels[i] isEqualToString:_label])
      return i;
  }
  return NSNotFound;
}

/* labels */

- (NSString *)labelAtIndex:(short)_idx {
  if ((_idx < 0) || (_idx > 21)) {
    NSLog(@"cannot get label at index %i", _idx);
    return nil;
  }
  return self->labels[_idx];
}

- (NSArray *)labels {
  NSMutableArray *array;
  int i;

  array = [NSMutableArray arrayWithCapacity:8];
  for (i = 0; i < 22; i++) {
    if ([self->labels[i] length] > 0)
      [array addObject:self->labels[i]];
  }
  return array;
}
- (int)indexOfLabel:(NSString *)_label {
  int i;
  
  if (_label == nil)      return NSNotFound;
  if (_label == (id)null) return NSNotFound;
  
  for (i = 0; i < 22; i++) {
    NSString *label;

    label = self->labels[i];
    
    if ([label isEqualToString:_label])
      return i;
  }
  return NSNotFound;
}

/* records */

- (EOClassDescription *)classDescriptionNeededForEntityName:(NSString *)_name {
  PPClassDescription *pp;
  
  pp = nil;
  if ([_name isEqualToString:@"AddressDB"]) {
    pp = [[PPClassDescription alloc] initWithClass:[PPAddressRecord class]
                                     creator:'addr'
                                     type:'DATA'];
  }
  return AUTORELEASE(pp);
}

- (Class)databaseRecordClassForGlobalID:(EOGlobalID *)_oid {
  return [PPAddressRecord class];
}

/* packing & unpacking */

- (NSData *)packRecord:(id)_eo {
  PPAddressPacker *packer;
  NSData *data;
  
  packer = [[PPAddressPacker alloc] initWithObject:_eo];
  data = [packer packWithDatabase:self];
  RELEASE(packer);
  
  if ([data length] >= 65535) {
    NSLog(@"ERROR: got packed address data with length %i ..", [data length]);
    return nil;
  }
  
  return data;
}

- (int)decodeAppBlock:(NSData *)_block {
  const unsigned char *record;
  int                 len, i;
  const unsigned char *start;
  unsigned long       r;
  int                 destlen = 4 + 16 * 22 + 2 + 2;
  
  record = start = [_block bytes];
  len    = [_block length];
  
  i = [super decodeAppBlock:_block];
  record += i;
  len    -= i;
  
  if (len < destlen)
    return -1;
  
  r = get_long(record); record += 4;
  for(i = 0; i < 22; i++)
    self->renamedLabels[i] = (!!(r & (1<<i))) ? YES : NO;
  
  for (i = 0; i < 22; i++, record += 16)
    self->labels[i] = [[NSString alloc] initWithCString:record];
  
  self->country       = get_short(record);           record += 2;
  self->sortByCompany = get_byte(record) ? YES : NO; record += 2;
  
  /* phone labels (1-5, 3-8) */
  for (i = 3; i < 8; i++)
    self->phoneLabels[i - 3] = [self->labels[i] copy];
  
  /* phone labels (6-8, 19-21) */
  for (i = 19; i < 22; i++)
    self->phoneLabels[i - 19 + 5] = [self->labels[i] copy];
  
  self->hasAppInfo = YES;
  
  return record - start;
}

/* description */

- (NSString *)propertyDescription {
  if (self->hasAppInfo) {
    NSMutableString *s;

    s = [NSMutableString stringWithString:[super propertyDescription]];
    [s appendFormat:@" country=%i", self->country];
    [s appendFormat:@" sortByCompany=%s", self->sortByCompany ? "yes" : "no"];
    return s;
  }
  else
    return [super propertyDescription];
}

@end /* PPAddressDatabase */

@implementation PPAddressRecord

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

- (id)init {
  if ((self = [super init])) {
    self->phoneValues = [[NSMutableDictionary alloc] init];
  }
  return self;
}

+ (long)palmCreator {
  return 'addr';
}
+ (long)palmType {
  return 'DATA';
}

static NSString *mkString(const char *_cstr) __attribute__((unused));

static NSString *mkString(const char *_cstr) {
  if (_cstr == NULL)
    return nil;
  if (_cstr == (void*)0xFFFF)
    return nil;
  if (strlen(_cstr) == 0)
    return nil;

  return [[NSString alloc] initWithCString:_cstr];
}

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data
{
  PPAddressPacker *packer;
  
  [super awakeFromDatabase:_db objectID:_oid attributes:_attrs
         category:_category
         data:_data];
  
  if ([self isDeleted])
    return;
  
  packer = [[PPAddressPacker alloc] initWithObject:self];
  [packer unpackWithDatabase:_db data:_data];
  RELEASE(packer);
}

- (void)dealloc {
  int i;
  
  for (i = 0; i < 19; i++)
    RELEASE(self->values[i]);
  for (i = 0; i < 5; i++)
    RELEASE(self->phoneLabels[i]);
  
  RELEASE(self->phoneValues);
  RELEASE(self->showPhone);
  [super dealloc];
}

/* accessors */

- (void)setShowPhone:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->showPhone isEqual:_value]) {
    [self willChange];
    ASSIGN(self->showPhone, _value);
  }
}
- (NSString *)showPhone {
  return self->showPhone;
}

- (void)setLastName:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryLastname] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryLastname], _value);
  }
}
- (NSString *)lastName {
  return self->values[entryLastname];
}

- (void)setFirstName:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryFirstname] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryFirstname], _value);
  }
}
- (NSString *)firstName {
  return self->values[entryFirstname];
}

- (void)setCompany:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCompany] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCompany], _value);
  }
}
- (NSString *)company {
  return self->values[entryCompany];
}

- (void)setAddress:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryAddress] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryAddress], _value);
  }
}
- (NSString *)address {
  return self->values[entryAddress];
}

- (void)setCity:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCity] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCity], _value);
  }
}
- (NSString *)city {
  return self->values[entryCity];
}

- (void)setState:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryState] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryState], _value);
  }
}
- (NSString *)state {
  return self->values[entryState];
}

- (void)setZip:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryZip] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryZip], _value);
  }
}
- (NSString *)zip {
  return self->values[entryZip];
}

- (void)setCountry:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCountry] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCountry], _value);
  }
}
- (NSString *)country {
  return self->values[entryCountry];
}

- (void)setTitle:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryTitle] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryTitle], _value);
  }
}
- (NSString *)title {
  return self->values[entryTitle];
}

- (void)setNote:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryNote] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryNote], _value);
  }
}
- (NSString *)note {
  return self->values[entryNote];
}

/* custom stuff */

- (void)setCustom1:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCustom1] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCustom1], _value);
  }
}
- (NSString *)custom1 {
  return self->values[entryCustom1];
}
- (void)setCustom2:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCustom2] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCustom2], _value);
  }
}
- (NSString *)custom2 {
  return self->values[entryCustom2];
}
- (void)setCustom3:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCustom3] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCustom3], _value);
  }
}
- (NSString *)custom3 {
  return self->values[entryCustom3];
}
- (void)setCustom4:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->values[entryCustom4] isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->values[entryCustom4], _value);
  }
}
- (NSString *)custom4 {
  return self->values[entryCustom4];
}

/* phones */

- (NSArray *)phoneKeys {
  //  NSLog(@"phonekeys are: %@", self->phoneValues);
  return [self->phoneValues allKeys];
}

- (void)setPhoneWork:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneWork"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneWork"];
}
- (NSString *)phoneWork {
  return [self->phoneValues objectForKey:@"phoneWork"];
}

- (void)setPhoneHome:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneHome"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneHome"];
}
- (NSString *)phoneHome {
  return [self->phoneValues objectForKey:@"phoneHome"];
}

- (void)setPhoneFax:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneFax"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneFax"];
}
- (NSString *)phoneFax {
  return [self->phoneValues objectForKey:@"phoneFax"];
}

- (void)setPhoneOther:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneOther"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneOther"];
}
- (NSString *)phoneOther {
  return [self->phoneValues objectForKey:@"phoneOther"];
}

- (void)setPhoneEmail:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneEmail"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneEmail"];
}
- (NSString *)phoneEmail {
  return [self->phoneValues objectForKey:@"phoneEmail"];
}

- (void)setPhoneMain:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneMain"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneMain"];
}
- (NSString *)phoneMain {
  return [self->phoneValues objectForKey:@"phoneMain"];
}

- (void)setPhonePager:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phonePager"];
  else
    [self->phoneValues setObject:_value forKey:@"phonePager"];
}
- (NSString *)phonePager {
  return [self->phoneValues objectForKey:@"phonePager"];
}

- (void)setPhoneMobile:(id)_value {
  if ((_value == nil) || (_value == null))
    [self->phoneValues removeObjectForKey:@"phoneMobile"];
  else
    [self->phoneValues setObject:_value forKey:@"phoneMobile"];
}
- (NSString *)phoneMobile {
  return [self->phoneValues objectForKey:@"phoneMobile"];
}

/* EOKeyValueCoding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if (_value == null) _value = nil;
  [super takeValue:_value forKey:_key];
}

/* validation */

- (NSString *)firstValidPhoneKey {
  /* find the first phone key with a valid value */
  NSEnumerator *keys;
  NSString *key;
  
  keys = [self->phoneValues keyEnumerator];
  while ((key = [keys nextObject])) {
    id value;

    value = [self->phoneValues objectForKey:key];
    if (value == nil)  continue;
    if (value == null) continue;
    if ([value length] == 0) continue;
    
    return key;
  }
  
  /* no phone label with value .. */
  keys = [self->phoneValues keyEnumerator];
  return [keys nextObject];
}

- (NSException *)validateForSave {
  NSException *e;
  
  if (self->showPhone == nil) {
    NSLog(@"phone key is nil, using first valid .. ");
    self->showPhone = [[self firstValidPhoneKey] copy];
  }
  else if ([self->phoneValues objectForKey:self->showPhone] == nil) {
    NSLog(@"no value for show phone key, using first valid .. ");
    RELEASE(self->showPhone);
    self->showPhone = [[self firstValidPhoneKey] copy];
  }
  
  if ((e = [super validateForSave]))
    return e;
  
  return nil;
}

/* description */

- (NSString *)propertyDescription {
  NSMutableString *s;
  
  s = [NSMutableString stringWithString:[super propertyDescription]];
  
  if ([[self firstName] length] > 0)
    [s appendFormat:@" %@", [self firstName]];
  if ([[self lastName] length] > 0)
    [s appendFormat:@" %@", [self lastName]];
  
  if ([[self company] length] > 0)
    [s appendFormat:@" company='%@'", [self company]];
  
  if ([[self showPhone] length] > 0)
    [s appendFormat:@" showphone=%@", [self showPhone]];
  return s;
}

- (NSArray *)attributeKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
                              @"isArchived", @"category", @"isPrivate",
                              @"name", @"firstName", @"company",
                              @"address", @"city", @"state", @"zip", @"country",
                              @"title", @"note",
                              @"showPhone",
                              @"custom1", @"custom2", @"custom3", @"custom4",
                              nil];
                            
  }
  return [keys arrayByAddingObjectsFromArray:[self phoneKeys]];
}

@end /* PPAddressRecord */
