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

#include <OGoContacts/SkyCompanyDocument.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>

#include <OGoContacts/SkyAddressDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>

#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOQualifier.h>

#include <LSFoundation/LSCommandKeys.h>
#include <NGExtensions/EODataSource+NGExtensions.h>

@interface SkyPalmAddressDocument(SkyrixSync_PrivatMethods)
/* setting phone values */
- (int)_setPhoneValue:(NSString *)_phoneValue
  forLabelId:(int)_labelId
  withControl:(int *)_ctrl;
- (NSString *)_phoneValueForLabelId:(int)_labelId;
/* fetching */
- (id)_fetchPerson;
- (id)_fetchEnterprise;
/* user defaults */
- (NSDictionary *)_userDefaultPalmKeys;
- (NSDictionary *)_userDefaultSkyrixKeysForEntity:(NSString *)_entity;
- (NSDictionary *)_userDefaultAttributeMappingForEntity:(NSString *)_entity;
- (NSString *)_palmKeyForAddressAttribute:(NSString *)_skyAttr
                               forEntity:(NSString *)_skyrixEntity;
/* value handling */
- (NSString *)_entityForSkyrixRecord:(id)_rec;
- (int)_phoneLabelIdForPalmAttributeConfig:(id)_cfg;
- (int)_attributeTypeForSkyrixAttributeConfig:(id)_cfg;
- (id)_valueFromSkyrixRecord:(id)_skyrixRecord
                      ofType:(int)_attrType
                      forKey:(NSString *)_key;
- (void)_setValue:(id)_val toSkyrixRecord:(id)_skyrixRecord
         attrType:(int)_attrType forKey:(NSString *)_key;
- (SkyAddressDocument *)_addressFromSkyrixRecord:(id)_skyrixRecord
                                       forEntity:(NSString *)_entity;

@end

@interface SkyPalmDocument(StopObserving)
- (void)_stopObserving;
@end /* OGoPalmDocument(StopObserving) */

static inline SEL _getSetSel(char *_key, unsigned _len) {
  char buf[259];
  buf[0] = 's';
  buf[1] = 'e';
  buf[2] = 't';
  memcpy(&(buf[3]), _key, _len);
  buf[3] = toupper(buf[3]);
  buf[_len+3] = ':';
  buf[_len+4] = '\0';

  return sel_get_uid(buf);
}

SEL _getSetSelector(NSString *_key) {
  char     *buf;
  unsigned len;
  SEL      setSel;

  len = [_key cStringLength];
  buf = malloc(len+1);
  [_key getCString:buf];
  setSel = _getSetSel(buf, len);
  free(buf); buf = NULL;

  return setSel;
}

#define SKYPALMADDRESS_ATTRIBUTES_KEY @"OGoPalmAddress_Palm_Attributes"


@implementation SkyPalmAddressDocument(SkyrixSync)

/* ################ initialize */
// dictWithPair
NSDictionary *__dP(id _obj, NSString *_key) {
  if (_obj == nil)
    return [NSDictionary dictionary];
  return [NSDictionary dictionaryWithObject:_obj forKey:_key];
}

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id tmp       = nil;
  id tmp2      = nil;
  id tmp1      = nil;
  NSNumber *n2 = [NSNumber numberWithInt:2];
  NSNumber *n1 = [NSNumber numberWithInt:1];
// labelId: Palm PhoneLableId
  //"OGoPalmAddress_Palm_Attributes" = {
  tmp1 = __dP(nil, nil);
  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  __dP([NSNumber numberWithInt:0], @"labelId"), @"work",
                  __dP(n1, @"labelId"),                         @"home",
                  __dP(n2, @"labelId"),                         @"fax",
                  __dP([NSNumber numberWithInt:3], @"labelId"), @"other",
                  __dP([NSNumber numberWithInt:4], @"labelId"), @"email",
                  __dP([NSNumber numberWithInt:5], @"labelId"), @"main",
                  __dP([NSNumber numberWithInt:6], @"labelId"), @"pager",
                  __dP([NSNumber numberWithInt:7], @"labelId"), @"mobile",
                  tmp1, @"title",
                  tmp1, @"custom1",
                  tmp1, @"custom2",
                  tmp1, @"custom3",
                  tmp1, @"custom4",
                  tmp1, @"firstname",
                  tmp1, @"lastname",
                  tmp1, @"company",
                  tmp1, @"address",
                  tmp1, @"zipcode",
                  tmp1, @"city",
                  tmp1, @"country",
                  tmp1, @"note",
                  tmp1, @"state",nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalmAddress_Palm_Attributes"]];
  
  // type: 1 - attribute 2 - phone  3 - ext
  tmp2  = __dP(n2,@"type");   // type = 2
  tmp1  = __dP(n1,@"type");   // type = 1
  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  tmp2, @"01_tel",
                  tmp2, @"02_tel",
                  tmp2, @"03_tel_funk",
                  tmp2, @"05_tel_private",
                  tmp2, @"10_fax",
                  tmp2, @"15_fax_private",

                  tmp1, @"firstname",
                  tmp1, @"middlename",
                  tmp1, @"name",
                  tmp1, @"number",
                  tmp1, @"nickname",
                  tmp1, @"salutation",
                  tmp1, @"degree",
                  tmp1, @"url",
                  tmp1, @"gender",
                  tmp1, @"birthday",
                  tmp1, @"comment",
                  tmp1, @"keywords",
                  tmp1, @"bossName",
                  tmp1, @"partnerName",
                  tmp1, @"assistantName",
                  tmp1, @"department",
                  tmp1, @"office",
                  tmp1, @"occupation",
                  tmp1, @"imAddress",
                  tmp1, @"associatedCompany",
                  nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalmAddress_Person_Attributes"]];

  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  tmp2, @"01_tel",
                  tmp2, @"02_tel",
                  tmp2, @"10_fax",

                  tmp1, @"name",
                  tmp1, @"number",
                  tmp1, @"url",
                  tmp1, @"email",
                  tmp1, @"bank",
                  tmp1, @"bankCode",
                  tmp1, @"account",
                  tmp1, @"keywords",
                  tmp1, @"bossName",
                  tmp1, @"department",
                  tmp1, @"office",
                  nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalmAddress_Enterprise_Attributes"]];
  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  @"01_tel",            @"work",
                  @"03_tel_funk",       @"mobile",
                  @"05_tel_private",    @"home",
                  @"10_fax",            @"fax",
                  @"15_fax_private",    @"other",
                  @"email1",            @"email",           
                  @"02_tel",            @"main",            
                  @"job_title",         @"title",           
                  @"nickname",          @"custom1",         
                  @"degree",            @"custom2",         
                  @"url",               @"custom3",         
                  @"middlename",        @"custom4",
                  @"firstname",         @"firstname",       
                  @"name",              @"lastname",        
                  @"comment",           @"note",
                  @"associatedCompany", @"company",
                  nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalmAddress_Person_AttributeMapping"]];

  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  @"10_fax",      @"fax",
                  @"02_tel",      @"other",
                  @"email",       @"email",
                  @"01_tel",      @"main",
                  @"number",      @"title",
                  @"bank",        @"custom1",
                  @"bankCode",    @"custom2",
                  @"account",     @"custom3",
                  @"url",         @"custom4",
                  @"name",        @"company",
                  @"keywords",    @"note",
                  nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalmAddress_Enterprise_AttributeMapping"]];
  tmp =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  @"private", @"OGoPalmAddress_Person_Address",
                  @"bill",    @"OGoPalmAddress_Enterprise_Address",
                  nil];
  [ud registerDefaults:tmp];

  // default address mapping for enterprises
  tmp = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"company", @"name1", nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalmAddress_Enterprise_AddressMapping"]];
  // no default address mapping for person attributes
  // but may be configured by user

  // default sync conduits
  tmp = [NSArray arrayWithObjects:@"AddressDB", @"DatebookDB",
                 @"MemoDB", @"ToDoDB", nil];
  [ud registerDefaults:
      [NSDictionary dictionaryWithObject:tmp
                    forKey:@"OGoPalm_sync_conduits"]];
  
}  /* ################ initialize */


- (void)saveSkyrixRecord {
  // is class SkyCompanyDocument
  [(SkyCompanyDocument *)[self skyrixRecord] save];
  // force reload --> made by notifications
}

- (void)takeValuesFromSkyrixRecord:(id)_skyrixRecord {
  int                setValues      = 0; // for saving used fields
  NSString           *skyrixEntity  = nil;
  NSDictionary       *palmKeys      = nil;
  NSDictionary       *skyrixKeys    = nil;
  NSDictionary       *mapping       = nil; // attribute key mapping
                                           // palm -> skyrix
  NSEnumerator       *e  = nil;
  NSString           *palmKey = nil;
  NSString           *skyrixKey = nil;
  id                 tmp = nil;

  int                phoneLabelId   = -1;
  int                attrType       = 1;

  skyrixEntity = [self _entityForSkyrixRecord:_skyrixRecord];
  palmKeys     = [self _userDefaultPalmKeys];
  skyrixKeys   = [self _userDefaultSkyrixKeysForEntity:skyrixEntity];
  mapping      = [self _userDefaultAttributeMappingForEntity:skyrixEntity];

  e = [[mapping allKeys] objectEnumerator];
  // iterating throug mapped values
  while ((palmKey = [e nextObject])) {

    // checking palm key
    tmp = [palmKeys valueForKey:palmKey];
    phoneLabelId = [self _phoneLabelIdForPalmAttributeConfig:tmp];
    if (phoneLabelId == -2) // no valid palm key
      continue;

    // checking skyrix key
    skyrixKey = [mapping valueForKey:palmKey];
    attrType  = [self _attributeTypeForSkyrixAttributeConfig:
                      [skyrixKeys valueForKey:skyrixKey]];
    if (attrType == -1) // no valid skyrix key
      continue;

    // getting value from skyrix record
    tmp = [self _valueFromSkyrixRecord:_skyrixRecord
                ofType:attrType forKey:skyrixKey];

    // setting value to palm record (self)
    if (phoneLabelId >= 0) {
      if ([[tmp stringByTrimmingWhiteSpaces] length]) {
        [self _setPhoneValue:tmp
              forLabelId:phoneLabelId withControl:&setValues];
      }
    }
    else {
      [self performSelector:_getSetSelector(palmKey) withObject:tmp];
    }
  }

  { // address values
    SkyAddressDocument *addr = nil;
    addr = [self _addressFromSkyrixRecord:_skyrixRecord
                 forEntity:skyrixEntity];
    if (addr != nil) {
      [self setAddress:[addr street]];
      [self setCity:   [addr city]];
      [self setState:  [addr state]];
      [self setZipcode:[addr zip]];
      [self setCountry:[addr country]];
      // special configured mapping for address values name1 .. name3
      if ((palmKey = [self _palmKeyForAddressAttribute:@"name1"
                           forEntity:skyrixEntity]) != nil)
        [self performSelector:_getSetSelector(palmKey)
              withObject:[addr name1]];
      if ((palmKey = [self _palmKeyForAddressAttribute:@"name2"
                           forEntity:skyrixEntity]) != nil)
        [self performSelector:_getSetSelector(palmKey)
              withObject:[addr name2]];
      if ((palmKey = [self _palmKeyForAddressAttribute:@"name3"
                           forEntity:skyrixEntity]) != nil)
        [self performSelector:_getSetSelector(palmKey)
              withObject:[addr name3]];
    }
  }
}
- (void)putValuesToSkyrixRecord:(id)_skyrixRecord {
  NSString           *skyrixEntity  = nil;
  NSDictionary       *palmKeys      = nil;
  NSDictionary       *skyrixKeys    = nil;
  NSDictionary       *mapping       = nil; // attribute key mapping
                                           // palm -> skyrix
  NSEnumerator       *e  = nil;
  NSString           *palmKey = nil;
  NSString           *skyrixKey = nil;
  id                 tmp = nil;

  int                phoneLabelId   = -1;
  int                attrType       = 1;

  skyrixEntity = [self _entityForSkyrixRecord:_skyrixRecord];
  palmKeys     = [self _userDefaultPalmKeys];
  skyrixKeys   = [self _userDefaultSkyrixKeysForEntity:skyrixEntity];
  mapping      = [self _userDefaultAttributeMappingForEntity:skyrixEntity];

  e = [[mapping allKeys] objectEnumerator];
  // iterating throug mapped values
  while ((palmKey = [e nextObject])) {

    // checking palm key
    tmp = [palmKeys valueForKey:palmKey];
    phoneLabelId = [self _phoneLabelIdForPalmAttributeConfig:tmp];
    if (phoneLabelId == -2) // no valid palm key
      continue;

    // checking skyrix key
    skyrixKey = [mapping valueForKey:palmKey];
    attrType  = [self _attributeTypeForSkyrixAttributeConfig:
                      [skyrixKeys valueForKey:skyrixKey]];
    if (attrType == -1) // no valid skyrix key
      continue;

    // getting value from palm record (self)
    if (phoneLabelId >= 0)
      tmp = [self _phoneValueForLabelId:phoneLabelId];
    else
      tmp = [self performSelector:NSSelectorFromString(palmKey)];

    // setting value to skyrix record
    if (tmp == nil)
      tmp = @"";

    // mh: this is a bit like a hack
    if ([skyrixKey isEqualToString:@"name"]) {
      // do not allow to overwrite the name with an empty string
      if (![tmp length])
        continue;
    }
      
    [self _setValue:tmp toSkyrixRecord:_skyrixRecord
          attrType:attrType forKey:skyrixKey];
  }

  { // address
    SkyAddressDocument *addr = nil;

    addr = [self _addressFromSkyrixRecord:_skyrixRecord
                 forEntity:skyrixEntity];
    if (addr != nil) {
      // address values
      [addr setStreet: [self address]];
      [addr setCity:   [self city]];
      [addr setState:  [self state]];
      [addr setZip:    [self zipcode]];
      [addr setCountry:[self country]];
      // special configured mapping for address values name1 .. name3
      if ((palmKey = [self _palmKeyForAddressAttribute:@"name1"
                           forEntity:skyrixEntity]) != nil)
        [addr setName1:[self performSelector:NSSelectorFromString(palmKey)]];
      if ((palmKey = [self _palmKeyForAddressAttribute:@"name2"
                           forEntity:skyrixEntity]) != nil)
        [addr setName2:[self performSelector:NSSelectorFromString(palmKey)]];
      if ((palmKey = [self _palmKeyForAddressAttribute:@"name3"
                           forEntity:skyrixEntity]) != nil)
        [addr setName3:[self performSelector:NSSelectorFromString(palmKey)]];
    } // addr != nil
  }
}

- (id)fetchSkyrixRecord {
  NSString *type = nil;

  if (self->isObserving)
    [self _stopObserving];
  
  type = [self skyrixType];
  if ([type isEqualToString:@"person"])
    return [self _fetchPerson];
  if ([type isEqualToString:@"enterprise"])
    return [self _fetchEnterprise];
  return nil;
}

- (id)createSkyrixRecordCopy {
  SkyCompanyDocument *newCompany = nil;
  id oldSkyrixRecord;
  oldSkyrixRecord = [self skyrixRecord];
  if (oldSkyrixRecord != nil) {
    NSString *type;
    type = [self skyrixType];
    if ([type isEqualToString:@"person"]) {
      SkyPersonDataSource  *ds =
        [[[SkyPersonDataSource alloc] initWithContext:[self context]]
                               autorelease];
      newCompany = [ds createObject];
      [(SkyPersonDocument *)newCompany
                            setName:
                            @"new person created due to palm conflict"];
    }
    else if ([type isEqualToString:@"enterprise"]) {
      SkyEnterpriseDataSource  *ds =
        [[[SkyEnterpriseDataSource alloc] initWithContext:[self context]]
                                   autorelease];
      newCompany = [ds createObject];
      [(SkyEnterpriseDocument *)newCompany
                                setName:
                                @"new enterprise created due to palm "
                                @"conflict"];
    }

  }

  return [newCompany save] ? newCompany : nil;
}

@end /* SkyPalmAddressDocument(SkyrixSync) */

@implementation SkyPalmAddressDocument(SkyrixSync_PrivatMethods)

/* ####   userDefault fetching   #### */

- (NSUserDefaults *)_userDefaults {
  return [[self context] valueForKey:LSUserDefaultsKey];
}

- (NSDictionary *)_userDefaultPalmKeys {
  return [[self _userDefaults]
                dictionaryForKey:SKYPALMADDRESS_ATTRIBUTES_KEY];
}
- (NSArray *)_extendedAttributesForEnity:(NSString *)_entity
                                    type:(NSString *)_type
{
  NSString *key = nil;
  key = [NSString stringWithFormat:@"Sky%@Extended%@Attributes",
                  _type, _entity];
  return [[self _userDefaults] arrayForKey:key];
}
- (NSDictionary *)_userDefaultSkyrixKeysForEntity:(NSString *)_entity {
  NSMutableDictionary *allKeys  = nil;
  NSEnumerator        *e        = nil;
  id                  tmp       = nil;

  allKeys = [NSMutableDictionary dictionaryWithCapacity:16];
  
  // getting public extended attributes
  tmp = [self _extendedAttributesForEnity:_entity type:@"Public"];
  e = [tmp objectEnumerator];
  while ((tmp = [e nextObject])) {
    // no bool values
    if ([[tmp valueForKey:@"type"] intValue] == 2)
      continue;
    [allKeys setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:3], @"type",
                                     nil]
             forKey:[tmp valueForKey:@"key"]];
  }
  
  // getting private extended attributes
  tmp = [self _extendedAttributesForEnity:_entity type:@"Private"];
  e = [tmp objectEnumerator];
  while ((tmp = [e nextObject])) {
    // no bool values
    if ([[tmp valueForKey:@"type"] intValue] == 2)
      continue;
    [allKeys setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:3], @"type",
                                     nil]
             forKey:[tmp valueForKey:@"key"]];
  }

  // getting default configured skyrix keys
  tmp = [NSString stringWithFormat:@"OGoPalmAddress_%@_Attributes", _entity];
  tmp = [[self _userDefaults] dictionaryForKey:tmp];
  [allKeys takeValuesFromDictionary:tmp];

  return allKeys;
}

- (NSDictionary *)_userDefaultAttributeMappingForEntity:(NSString *)_entity {
  NSString *key = nil;
  key = [NSString stringWithFormat:
                  @"OGoPalmAddress_%@_AttributeMapping", _entity];
  return [[self _userDefaults] dictionaryForKey:key];
}

// special mappings for address attributes name1, name2, name3
- (NSDictionary *)_address2PalmKeyMappingForEntity:(NSString *)_entity {
  NSString *key = nil;
  key = [NSString stringWithFormat:
                  @"OGoPalmAddress_%@_AddressMapping", _entity];
  return [[self _userDefaults] dictionaryForKey:key];
}
- (NSString *)_palmKeyForAddressAttribute:(NSString *)_skyAttr
                               forEntity:(NSString *)_skyrixEntity
{
  return [[self _address2PalmKeyMappingForEntity:_skyrixEntity]
                valueForKey:_skyAttr];
}

/* ####    handling values   #### */

- (NSString *)_entityForSkyrixRecord:(id)_rec {
  if ([_rec isKindOfClass:[SkyEnterpriseDocument class]])
    return @"Enterprise";
  else if ([_rec isKindOfClass:[SkyPersonDocument class]])
    return @"Person";
  return nil;
}

- (int)_phoneLabelIdForPalmAttributeConfig:(id)_cfg {
  id tmp = nil;
  if (_cfg == nil)
      // no valid palm key
    return -2;
  if ((tmp = [_cfg valueForKey:@"labelId"]) != nil)
    return [tmp intValue];
  return -1; // no label id set
}

- (int)_attributeTypeForSkyrixAttributeConfig:(id)_cfg {
  if (_cfg == nil)
    // no valid skyrix key
    return -1;
  return [[_cfg valueForKey:@"type"] intValue];
}

- (id)_valueFromSkyrixRecord:(id)_skyrixRecord
                      ofType:(int)_attrType
                      forKey:(NSString *)_key
{
  switch(_attrType) {
    case 2: // phone
      return [_skyrixRecord phoneNumberForType:_key];
      break;
    case 3: // extended attribute
      return [_skyrixRecord extendedAttributeForKey:_key];
      break;
    default: // attribute
      return [_skyrixRecord performSelector:NSSelectorFromString(_key)];
      break;
  }
}

- (void)_setValue:(id)_val toSkyrixRecord:(id)_skyrixRecord
         attrType:(int)_attrType forKey:(NSString *)_key
{
  switch(_attrType) {
    case 2: // phone
      [_skyrixRecord setPhoneNumber:_val forType:(NSString *)_key];
      break;
    case 3: // extended attribute
      [_skyrixRecord setExtendedAttribute:_val forKey:_key];
      break;
    default: // attribute
      [_skyrixRecord performSelector:_getSetSelector(_key) withObject:_val];
      break;
  }
}

- (SkyAddressDocument *)_addressFromSkyrixRecord:(id)_skyrixRecord
                                       forEntity:(NSString *)_entity
{
  NSString *addressType = nil;
  addressType =
    [NSString stringWithFormat:@"OGoPalmAddress_%@_Address", _entity];
  addressType = [[self _userDefaults] stringForKey:addressType];

  if ([addressType length] == 0)
    return nil;

  return [_skyrixRecord addressForType:addressType];
}

/* ####   saving phone values    #### */

- (int)_setPhoneValue:(NSString *)_phoneValue
           forLabelId:(int)_labelId
              notThat:(int)_that
{
  NSString *key    = nil;
  NSString *val    = nil;
  int      labelId = 0;
  int      i       = 0;
  int      flag    = 0;

  // searching existant field
  for (i = 0; i < 5; i++) {
    flag = (1 << i);
    if ((_that & flag) == flag)
      // already set
      continue;
    key     = [NSString stringWithFormat:@"phoneLabelId%d",i];
    labelId = [[self valueForKey:key] intValue];
    if (labelId == _labelId) {
      // found field
      key = [NSString stringWithFormat:@"phone%d",i];
      [self takeValue:_phoneValue forKey:key];
      return i;
    }
  }
  // no field found
  // searching empty field
  for (i = 0; i < 5; i++) {
    flag = (1 << i);
    if ((_that & flag) == flag)
      // field already set
      continue;
    key = [NSString stringWithFormat:@"phone%d",i];
    val = [self valueForKey:key];
    if ((val == 0) || ([val length] == 0)) {
      [self takeValue:_phoneValue forKey:key];
      key = [NSString stringWithFormat:@"phoneLabelId%d",i];
      [self takeValue:[NSNumber numberWithInt:_labelId]
            forKey:key];
      return i;
    }
  }
  // no free field found
  return -1;
}
- (int)_setPhoneValue:(NSString *)_phoneValue
           forLabelId:(int)_labelId {
  // set phone label without control
  return [self _setPhoneValue:_phoneValue forLabelId:_labelId notThat:0];
}
- (int)_setPhoneValue:(NSString *)_phoneValue
           forLabelId:(int)_labelId
          withControl:(int *)_ctrl
{
  int      i;
  int      flag = 0;
  NSString *key = nil;

  i = [self _setPhoneValue:_phoneValue forLabelId:_labelId
            notThat:*_ctrl];
  if (i != -1) {
    flag = (1 << i);
    // saving, that field is used
    *_ctrl = (*_ctrl | flag);    
    return i;
  }
  // not able to set value without overwriting
  // so now overwriting
  for (i = 0; i < 5; i++) {
    flag = (1 << i);
    if ((*_ctrl & flag) == flag)
      // already set
      continue;
    
    key = [NSString stringWithFormat:@"phone%d", i];
    [self takeValue:_phoneValue forKey:key];
    key = [NSString stringWithFormat:@"phoneLabelId%d", i];
    [self takeValue:[NSNumber numberWithInt:_labelId] forKey:key];
    // saving that field is used
    *_ctrl = (*_ctrl | flag);
    return i;
  }
  // all fields used
  return -1;
}

- (NSString *)_phoneValueForLabelId:(int)_labelId {
  switch(_labelId) {
    case PALM_ADDRESS_PHONE_WORK:   return self->workPhone;
    case PALM_ADDRESS_PHONE_HOME:   return self->homePhone;
    case PALM_ADDRESS_PHONE_FAX:    return self->faxPhone;
    case PALM_ADDRESS_PHONE_OTHER:  return self->otherPhone;
    case PALM_ADDRESS_PHONE_EMAIL:  return self->emailPhone;
    case PALM_ADDRESS_PHONE_MAIN:   return self->mainPhone;
    case PALM_ADDRESS_PHONE_PAGER:  return self->pagerPhone;
    case PALM_ADDRESS_PHONE_MOBILE: return self->mobilePhone;
  }
  return nil;
}


/* fetching */

- (EOFetchSpecification *)_fetchSpecForSkyrixRecord {
  EOFetchSpecification *fs;
  EOQualifier *qual = nil;
  
  qual = [[EOKeyValueQualifier alloc] initWithKey:@"companyId"
                                      operatorSelector:EOQualifierOperatorEqual
                                      value:[self skyrixId]];
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"company"
                             qualifier:qual
                             sortOrderings:nil];
  [qual release];
  return fs;
}

- (id)_fetchContactFromDataSource:(EODataSource *)_ds {
  [_ds setFetchSpecification:[self _fetchSpecForSkyrixRecord]];
  return [[_ds fetchObjects] lastObject];
}
- (void)_observeSkyrixRecord:(id)_skyrixRecord {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];  
  
  // TODO: should we check whether isObserving is already YES for reliability?
  // TODO: this is wrong! a notification selector needs to have at least
  //       one argument to work on all platforms
  [nc addObserver:self selector:@selector(skyrixRecordChanged)
      name:EODataSourceDidChangeNotification
      object:[(SkyCompanyDocument *)_skyrixRecord dataSource]];
  self->isObserving = YES;
}
- (id)_fetchPerson {
  SkyPersonDataSource *ds;
  id person;
  
  ds = [[SkyPersonDataSource alloc] initWithContext:[self context]];
  person = [[self _fetchContactFromDataSource:ds] retain];
  [ds release];
  return [person autorelease];
}
- (id)_fetchEnterprise {
  SkyEnterpriseDataSource *ds;
  id enterprise;
  
  ds = [[SkyEnterpriseDataSource alloc] initWithContext:[self context]];
  enterprise = [[self _fetchContactFromDataSource:ds] retain];
  [ds release];
  return [enterprise autorelease];
}

@end /* SkyPalmAddressDocument(SkyrixSync_PrivatMethods) */
