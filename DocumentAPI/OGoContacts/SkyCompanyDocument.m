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

#include "SkyCompanyDocument.h"
#include "SkyAddressDocument.h"
#include "common.h"
#include "SkyContactAddressDataSource.h"
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOQualifier.h>
#include <NGExtensions/NGExtensions.h>

@interface SkyCompanyDocument(PrivateMethodes)
- (void)_registerForGID;
- (void)_fetchAddresses;
- (void)_setObjectVersion:(NSNumber *)_version;
- (EOKeyGlobalID *)_personGidFrom:(NSString *)_personId;
- (void)_reloadImage;
- (void)_setGlobalID:(id)_gid;
- (void)_setCompanyId:(id)_companyId;
@end /* SkyCompanyDocument(PrivateMethodes) */

@implementation SkyCompanyDocument

+ (int)version {
  return [super version] + 7; /* v8 */
}

+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

// designated initializer
- (id)initWithCompany:(id)_company
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
  addAsObserver:(BOOL)_addAsObserver
{
  if ((self = [super init]) != nil) {
    EOFetchSpecification *fSpec;
    NSArray              *attrs;

    self->addAsObserver = _addAsObserver;
    self->globalID = [_gid retain];
    [self _registerForGID];
    
    self->dataSource = [_ds retain];
    
    fSpec = [_ds fetchSpecification];
    attrs = [[fSpec hints] objectForKey:@"attributes"];
    self->supportedAttributes = [attrs copy];
  }
  return self;
}

- (id)initWithEO:(id)_eo dataSource:(EODataSource *)_ds {
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  [self release];
  return nil;
}

- (void)dealloc {
  if (self->addAsObserver)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self->dataSource    release];
  [self->globalID      release];
  [self->addresses     release];
  [self->phones        release];
  [self->phoneTypes    release];
  [self->extendedAttrs release];
  [self->extendedKeys  release];
  [self->objectVersion release];
  [self->comment       release];
  [self->keywords      release];
  [self->imageData     release];
  [self->imageType     release];
  [self->imagePath     release];
  [self->contact       release];
  [self->owner         release];
  [self->ownerGID      release];
  [self->contactGID    release];
  [self->supportedAttributes release];
  [self->attributeMap        release];
  [self->bossName   release];
  [self->department release];
  [self->office     release];
  [super dealloc];
}

/* accessors */

- (BOOL)isComplete {
  if ([self isValid] == NO)
    return NO;
  
  if (self->supportedAttributes != nil)
    return NO;

  return self->status.isComplete;
}

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (NSArray *)attributesForNamespace:(NSString *)_namespace {
  if (_namespace == nil)
    return nil;

  return nil;
}

- (id)context {
  if (self->dataSource)
    return [(id)self->dataSource context];
  
#if DEBUG
  NSLog(@"WARNING(%s): document %@ has no datasource/context !!",
        __PRETTY_FUNCTION__, self);
#endif
  return nil;
}

- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setSupportedAttributes:(NSArray *)_attrs {
  ASSIGNCOPY(self->supportedAttributes, _attrs);
}
- (NSArray *)supportedAttributes {
  return self->supportedAttributes;
}

- (BOOL)isAttributeSupported:(NSString *)_attr {
  return (self->supportedAttributes == nil)
    ? YES
    : [self->supportedAttributes containsObject:_attr];
}

// ---------------------------------------------------------------------

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (BOOL)isValid {
  return self->status.isValid;
}

- (void)invalidate {
  RELEASE(self->phones);       self->phones       = nil;
  RELEASE(self->phoneTypes);   self->phoneTypes   = nil;
  RELEASE(self->addresses);    self->addresses    = nil;
  RELEASE(self->comment);      self->comment      = nil;
  RELEASE(self->keywords);     self->keywords     = nil;
  RELEASE(self->imageType);    self->imageType    = nil;
  RELEASE(self->imageData);    self->imageData    = nil;

  [self->bossName   release]; self->bossName   = nil;
  [self->department release]; self->department = nil;
  [self->office     release]; self->office     = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->globalID release]; self->globalID     = nil;  
  self->status.isValid = NO;
}
- (void)invalidate:(NSNotification *)_notification {
  [self invalidate];
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited) ? YES : NO;
}

/* telephones */

- (NSArray *)phoneTypes {
  return self->phoneTypes;
}

- (void)setPhoneNumber:(NSString *)_number forType:(NSString *)_type {
  id phone;
  
  if (_type == nil) return;
  
  if ([[self phoneNumberForType:_type] isEqual:_number]) /* did not change */
    return;
  
  phone = [self->phones valueForKey:_type];
  self->status.isEdited = YES;
  if (phone == nil) {
    phone = [NSMutableDictionary dictionaryWithCapacity:4];
        
    [phone takeValue:_type   forKey:@"type"];
    [self->phones takeValue:phone forKey:_type];
  }
  [phone takeValue:_number forKey:@"number"];
}
- (NSString *)phoneNumberForType:(NSString *)_type {
  id tmp = nil;

  if (_type == nil) return nil;
  tmp = [self->phones valueForKey:_type];
  return [tmp valueForKey:@"number"];
}

- (void)setPhoneInfo:(NSString *)_info forType:(NSString *)_type {
  id phone;
  
  if (_type == nil) return;

  if ([[self phoneInfoForType:_type] isEqual:_info])
    return;
  
  phone = [self->phones valueForKey:_type];

  self->status.isEdited = YES;
  if (phone == nil) {
      phone = [NSMutableDictionary dictionaryWithCapacity:4];
        
      [phone takeValue:_type   forKey:@"type"];
      [self->phones takeValue:phone forKey:_type];
  }
  [phone takeValue:_info forKey:@"info"];
}
- (NSString *)phoneInfoForType:(NSString *)_type {
  id tmp = nil;

  if (_type == nil) return nil; 
  tmp = [self->phones valueForKey:_type];
  return [tmp valueForKey:@"info"];
}

/* addresses */

- (EODataSource *)addressDataSource {
  SkyContactAddressDataSource *das = nil;
  EOFetchSpecification *fSpec;
  NSDictionary         *hints;

  if (self->globalID == nil)
    return nil;

  das = [[SkyContactAddressDataSource alloc] initWithContext:[self context]
                                             contact:self->globalID];
  das = [das autorelease];
  if (self->addAsObserver)
    return das;
  
  hints = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithBool:NO],
                                  @"addDocumentsAsObserver",
                                  nil];
    
  fSpec = [[EOFetchSpecification alloc] init];
  [fSpec setHints:hints];                 
  [das setFetchSpecification:fSpec];
  
  [fSpec release];
  [hints release];
  
  return das;
}

- (id)addressForType:(NSString *)_type {
  if (self->addresses == nil)
    [self _fetchAddresses];

  return [self->addresses objectForKey:_type];
}

- (NSArray *)addressTypes {
  if (![self isAttributeSupported:@"addresses"])
    return nil;
  
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* extended attributes */

- (NSArray *)extendedKeys {
  return self->extendedKeys;
}

- (void)setExtendedAttribute:(id)_value forKey:(NSString *)_key {
  NSString *obj = nil;

  if (_key == nil)
    return;

  obj = [self->extendedAttrs objectForKey:_key];
  if (![obj isEqual:_value]) {
    self->status.isEdited = YES;
    [self->extendedAttrs setObject:_value forKey:_key];
  }
}

- (id)extendedAttributeForKey:(NSString *)_key {
  return [self->extendedAttrs objectForKey:_key];
}

- (NSDictionary *)attributeMap {
  return self->attributeMap;
}

/* contact */

- (void)setContact:(SkyDocument *)_contact {
  id inputId   = nil;
  id currentId = nil;

  inputId = [[(EOKeyGlobalID *)[_contact globalID] keyValuesArray] lastObject];
  currentId = [[(EOKeyGlobalID *)self->contactGID keyValuesArray] lastObject];

  if (![currentId isEqual:inputId]) {
    RELEASE(self->contact);    self->contact = nil;
    RELEASE(self->contactGID); self->contactGID = nil;
    //    ASSIGN(self->contact,    (id)nil);
    //    ASSIGN(self->contactGID, (id)nil);
    self->contactGID = [self _personGidFrom:inputId];
    RETAIN(self->contactGID);
    self->status.isEdited = YES;
  }
}

- (SkyDocument *)contact {
  if (![self isAttributeSupported:@"contact"]) return nil;
  
  if (self->contact == nil && self->contactGID != nil) {
    static Class clazz = Nil;

    if (clazz == Nil)
      clazz = NSClassFromString(@"SkyAccountDocument");
      
    self->contact = [[clazz alloc] initWithGlobalID:self->contactGID
                                 context:[self context]];
  }
  return self->contact;
}

/* owner */

- (void)setOwner:(SkyDocument *)_owner {
  id inputId   = nil;
  id currentId = nil;

  inputId   = [[(EOKeyGlobalID *)[_owner globalID] keyValuesArray] lastObject];
  currentId = [[(EOKeyGlobalID *)self->ownerGID keyValuesArray] lastObject];

  if ([currentId isEqual:inputId])
    return;

  [self->owner release];    self->owner    = nil;
  [self->ownerGID release]; self->ownerGID = nil;
  self->ownerGID = [[self _personGidFrom:inputId] retain];
  self->status.isEdited = YES;
}

- (SkyDocument *)owner {
  static Class clazz = Nil;
  if (![self isAttributeSupported:@"owner"]) return nil;
  
  if (!(self->owner == nil && self->ownerGID != nil))
    return self->owner;

  if (clazz == Nil)
    clazz = NSClassFromString(@"SkyAccountDocument");
  
  self->owner = [[clazz alloc] initWithGlobalID:self->ownerGID
			       context:[self context]];
  return self->owner;
}

/* comment */

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY_IFNOT_EQUAL(self->comment, _comment, self->status.isEdited);
}
- (NSString *)comment {
  return self->comment;
}

- (void)setKeywords:(NSString *)_keywords {
  ASSIGNCOPY_IFNOT_EQUAL(self->keywords, _keywords, self->status.isEdited);
}
- (NSString *)keywords {
  return self->keywords;
}

- (void)setBossName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->bossName,_name,self->status.isEdited);
}
- (NSString *)bossName {
  return self->bossName;
}
- (void)setDepartment:(NSString *)_dep {
  ASSIGNCOPY_IFNOT_EQUAL(self->department,_dep,self->status.isEdited);
}
- (NSString *)department {
  return self->department;
}
- (void)setOffice:(NSString *)_office {
  ASSIGNCOPY_IFNOT_EQUAL(self->office,_office,self->status.isEdited);
}
- (NSString *)office {
  return self->office;
}


- (void)setIsReadonly:(BOOL)_isReadonly {
  if (self->isReadonly != _isReadonly) {
    self->isReadonly = _isReadonly;
    self->status.isEdited = YES;
  }
}
- (BOOL)isReadonly {
  return self->isReadonly;
}

- (void)setIsPrivate:(BOOL)_isPrivate {
  if (self->isPrivate != _isPrivate) {
    self->isPrivate = _isPrivate;
    self->status.isEdited = YES;
  }
}
- (BOOL)isPrivate {
  return self->isPrivate;
}


/* image */

- (void)setImageData:(NSData *)_data filePath:(NSString *)_filePath {
  NSString       *ext;
  NSUserDefaults *defaults;
  NSString       *companyId;
  NSString       *path;
  NSString       *imgPath;
  NSData         *oldData;
  NSString       *newType;

  // delete image file, if exists
  oldData = [self imageData];
  ext     = [[_filePath pathExtension] lowercaseString];
  ext     = ([ext isEqualToString:@"jpeg"]) ?  (NSString *)@"jpg" : ext;
  newType = [@"image/" stringByAppendingString:ext];

  if ([oldData isEqual:_data] && [self->imageType isEqualToString:newType])
    return;

  self->status.isEdited = YES;

  if ([oldData length] > 0 || [self->imageType length] > 0) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeFileAtPath:self->imagePath handler:nil];
  }

  [self->imageData release]; self->imageData = nil;
  [self->imageType release]; self->imageType = nil;
  [self->imagePath release]; self->imagePath = nil;

  companyId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];
  if (companyId == nil) return;
  
  defaults = [[self context] valueForKey:LSUserDefaultsKey];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  imgPath  = [NSString stringWithFormat:
                       @"%@/%@.picture.%@", path, companyId, ext];
  [_data writeToFile:imgPath atomically:YES];
}

- (NSData *)imageData {
  if (self->imageData == nil) {
    [self _reloadImage];
  }
  return self->imageData;
}

- (NSString *)imageType {
  if (self->imageType == nil) {
    [self _reloadImage];
  }
  return self->imageType; 
}

/* object version */
- (NSNumber *)objectVersion {
  return self->objectVersion;
}

- (NSNumber *)companyId {
  return [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];
}

- (NSString *)entityName {
  [self subclassResponsibility:_cmd];
  return nil;
}


/* ****************************** */

- (NSDictionary *)asDict {
  NSMutableDictionary *dict;
  NSNumber            *companyId;

  dict      = [NSMutableDictionary dictionaryWithCapacity:16];
  companyId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (companyId != nil)
    [dict setObject:companyId forKey:@"companyId"];

  if ([self isAttributeSupported:@"telephones"])
    [dict takeValue:[self->phones allValues] forKey:@"telephones"];
  
  if ([self isAttributeSupported:@"comment"])
    [dict takeValue:[self comment]           forKey:@"comment"];

  if ([self isAttributeSupported:@"keywords"])
    [dict takeValue:[self keywords]          forKey:@"keywords"];

  if ([self isAttributeSupported:@"extendedAttributes"])
    [dict takeValuesFromDictionary:self->extendedAttrs];

  if ([self isAttributeSupported:@"contact"] ||
      [self isAttributeSupported:@"contactId"]) {
    NSString *contactId;
    
    contactId=[[(EOKeyGlobalID *)self->contactGID keyValuesArray] lastObject];
    [dict takeValue:contactId forKey:@"contactId"];
  }

  if ([self isAttributeSupported:@"owner"] ||
      [self isAttributeSupported:@"ownerId"]) {
    NSString *ownerId;
    
    ownerId = [[(EOKeyGlobalID *)self->ownerGID keyValuesArray] lastObject];
    [dict takeValue:ownerId forKey:@"ownerId"];
  }
  if ([self isAttributeSupported:@"isReadonly"]) {
    [dict takeValue:[NSNumber numberWithBool:[self isReadonly]]
             forKey:@"isReadonly"];
  }

  if ([self isAttributeSupported:@"isPrivate"]) {
    [dict takeValue:[NSNumber numberWithBool:[self isPrivate]]
             forKey:@"isPrivate"];
  }

  if ([self isAttributeSupported:@"bossName"])
    [dict takeValue:[self bossName]   forKey:@"bossName"];
  if ([self isAttributeSupported:@"department"])
    [dict takeValue:[self department] forKey:@"department"];
  if ([self isAttributeSupported:@"office"])
    [dict takeValue:[self office]     forKey:@"office"];

  return dict;
}

- (void)_setGlobalID:(id)_gid {
  if (self->globalID == nil) {
    [self _registerForGID];
    ASSIGN(self->globalID,_gid);
  }
}

/* equality */

- (BOOL)isEqual:(id)_other {
  if (_other == self)
    return YES;
  
  if (![_other isKindOfClass:[self class]])
    return NO;
  
  if (![[_other globalID] isEqual:[self globalID]])
    return NO;

  /* docs have same global-id, but could be in different editing state .. */
  
  if (![_other isEdited] && ![self isEdited])
    return YES;
  
  return NO;
}

/* actions */

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
}

- (NSString *)nameOfSetCommand {
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (BOOL)save {
  BOOL result = YES;

  if (self->status.isEdited == NO) return YES;
  if (![self isComplete])          return NO;
  
  NS_DURING {
    if (self->globalID == nil) {
      NSArray *addrs;
      int     i, cnt;
      
      [self->dataSource insertObject:self];
      addrs = [[self context] runCommand:@"address::get",
                            @"companyId", [self companyId],
                            @"returnType", intObj(LSDBReturnType_ManyObjects),
                            nil];

      for (i = 0, cnt = [addrs count]; i < cnt; i++) {
        SkyAddressDocument *addrDoc = nil;
        EOKeyGlobalID      *gid     = nil;
        id                 addrEO   = [addrs objectAtIndex:i];
        id                 value[1];

        addrDoc = [self addressForType:[addrEO valueForKey:@"type"]];
        value[0] = [addrEO valueForKey:@"addressId"];
        gid = [EOKeyGlobalID globalIDWithEntityName:@"Address"
                             keys:value
                             keyCount:1
                             zone:[addrDoc zone]];
        [(id)addrDoc _setGlobalID:gid];
        [(id)addrDoc _setCompanyId:[addrEO valueForKey:@"companyId"]];
        [addrDoc save];
      }
    }
    else {
      NSEnumerator *typE = [[self addressTypes] objectEnumerator];
      id           one   = nil;

      while ((one = [typE nextObject])) {
        one = [self addressForType:one];
        if (one != nil)
          [one save];
      }
      [self->dataSource updateObject:self];
    }
    self->status.isEdited = NO;
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)delete {
  BOOL result = YES;
  
  NS_DURING {
    [self->dataSource deleteObject:self];
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)reload {
  if ([self isValid] == NO)
    return NO;

  if ([self globalID] == nil) {
    [self invalidate];
  }
  else {
    id obj;

    obj = [[[self context] runCommand:@"object::get-by-globalid",
                @"gid", [self globalID], nil] lastObject];
    [self _loadDocument:obj];
  }
  return YES;
}

- (void)_loadPhoneTypes {
  id tmp;

  [self->phoneTypes release]; self->phoneTypes = nil;
  tmp = [[[self context] userDefaults] dictionaryForKey:@"LSTeleType"];
  tmp = [(NSDictionary *)tmp objectForKey:[self entityName]];
  tmp = [tmp sortedArrayUsingSelector:@selector(compare:)];
  self->phoneTypes = [[NSMutableArray alloc] initWithArray:tmp];
}

- (void)_loadDocument:(id)_object {
  NSArray *list;
  int     i, cnt;

  // set telephone numbers
  if ([self isAttributeSupported:@"telephones"]) {
    list = [_object valueForKey:@"telephones"];
    cnt  = [list count];
    [self->phones release]; self->phones = nil;
    self->phones = [[NSMutableDictionary alloc] initWithCapacity:cnt];
    
    for (i = 0; i < cnt; i++) {
      NSMutableDictionary *dict;
      id       phone;
      NSString *type;
      
      phone = [list objectAtIndex:i];
      type  = [phone valueForKey:@"type"];

      if (![type isNotNull]) continue;
        
      dict = [[NSMutableDictionary alloc] initWithCapacity:4];
        
      [dict takeValue:[phone valueForKey:@"type"]   forKey:@"type"];
      [dict takeValue:[phone valueForKey:@"number"] forKey:@"number"];
      [dict takeValue:[phone valueForKey:@"info"]   forKey:@"info"];
      if ([(NSDictionary *)phone objectForKey:@"telephoneId"] != nil) {
	[dict setObject:[(NSDictionary *)phone objectForKey:@"telephoneId"]
	      forKey:@"telephoneId"];
      }
      [self->phones setObject:dict forKey:type];
      [dict release]; dict = nil;
    }

    [self _loadPhoneTypes];
  }

  [self _setObjectVersion:[_object valueForKey:@"objectVersion"]];

  if ([self isAttributeSupported:@"extendedAttributes"]) {
    NSMutableArray *slist = nil;
    
    list = [[_object valueForKey:@"attributeMap"] allKeys];
    list = [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    cnt  = [list count];

    slist = [NSMutableArray arrayWithCapacity:cnt];
    
    [self->extendedAttrs release];
    self->extendedAttrs = [[NSMutableDictionary alloc] initWithCapacity:cnt];

    for (i = 0; i < cnt; i++) {
      NSString *key = [list objectAtIndex:i];
      id       obj  = [_object valueForKey:key];

      if (obj)
        [self->extendedAttrs setObject:obj forKey:key];

      if ([key isEqualToString:@"email1"])
        [slist insertObject:key atIndex:0];
      else if ([key isEqualToString:@"email2"]) {
        if ([slist count] > 0)
          [slist insertObject:key atIndex:1];
        else
          [slist addObject:key];
      }
      else
        [slist addObject:key];
    }
    ASSIGN(self->extendedKeys, slist);
    
    [self->attributeMap release];
    self->attributeMap = [[_object valueForKey:@"attributeMap"] retain];
  }

  
  [self->contact release];    self->contact = nil;
  [self->contactGID release]; self->contactGID = nil;
  self->contactGID = [self _personGidFrom:[_object valueForKey:@"contactId"]];
  [self->contactGID retain];


  [self->owner release];    self->owner    = nil;
  [self->ownerGID release]; self->ownerGID = nil;
  
  self->ownerGID = [self _personGidFrom:[_object valueForKey:@"ownerId"]];
  [self->ownerGID retain];

  [self->addresses release]; self->addresses = nil;

  if ([self isAttributeSupported:@"comment"]) {
    [self setComment:[[_object valueForKey:@"comment"]
                               valueForKey:@"comment"]];
  }
  
  if ([self isAttributeSupported:@"keywords"])
    [self setKeywords:[_object valueForKey:@"keywords"]];

  if ([self isAttributeSupported:@"isReadonly"])
    [self setIsReadonly:[[_object valueForKey:@"isReadonly"] boolValue]];

  if ([self isAttributeSupported:@"isPrivate"])
    [self setIsPrivate:[[_object valueForKey:@"isPrivate"] boolValue]];

  if ([self isAttributeSupported:@"bossName"])
    [self setBossName:[_object valueForKey:@"bossName"]];
  if ([self isAttributeSupported:@"department"])
    [self setBossName:[_object valueForKey:@"department"]];
  if ([self isAttributeSupported:@"office"])
    [self setBossName:[_object valueForKey:@"office"]];
  
  self->status.isComplete = (self->supportedAttributes == nil);
  self->status.isValid    = YES;
  self->status.isEdited   = NO;
}

@end /* SkyCompanyDocument */


@implementation SkyCompanyDocument(Private)

- (void)_registerForGID {
  if (!self->addAsObserver) return;

  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"DebugDocumentRegistration"]) {
    NSLog(@"++++++++++++++++++ Warning: register Document"
          @" in NotificationCenter(%s)",
          __PRETTY_FUNCTION__);
  }
  if (self->globalID) {
    //printf("%s: %s[%p]\n", __PRETTY_FUNCTION__, [self->globalID class]->name,
    //       self->globalID);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(invalidate:)
                                          name:SkyGlobalIDWasDeleted
                                          object:self->globalID];
  }
}

- (void)_fetchAddresses {
  SkyAddressDocument  *one  = nil;
  NSEnumerator        *e    = nil;
  NSMutableDictionary *dict = nil;

  if (![self isAttributeSupported:@"addresses"]) return;

  if (self->globalID == nil) {
    NSArray  *types = [self addressTypes];
    NSString *type;

    dict = [[NSMutableDictionary alloc] initWithCapacity:[types count]];
    e    = [types objectEnumerator];

    while ((type = [e nextObject]) != nil) {
      SkyAddressDocument *one;
      
      one = [SkyAddressDocument alloc]; // keep gcc happy
      one = [one initWithContext:[self context]];
      [one setType:type];
      [dict setObject:one forKey:type];
      [one release]; one = nil;
    }
  }
  else {
    NSArray *all;
    
    all  = [[self addressDataSource] fetchObjects];
    e    = [all objectEnumerator];
    dict = [[NSMutableDictionary alloc] initWithCapacity:[all count]];
    
    while ((one = [e nextObject]) != nil)
      [dict setObject:one forKey:[one type]];
  }
  
  [self->addresses release];
  self->addresses = dict; dict = nil;
}

- (EOKeyGlobalID *)_personGidFrom:(NSString *)_personId {
  EOKeyGlobalID *result = nil;
  
  if ([_personId isNotNull]) {
    id values[1];

    values[0] = _personId;
    result    = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                               keys:values
                               keyCount:1
                               zone:[self zone]];
  }
  return result;
}



- (void)_setObjectVersion:(NSNumber *)_version {
  ASSIGNCOPY_IFNOT_EQUAL(self->objectVersion,_version,self->status.isEdited);
}

- (void)_reloadImage {
  NSUserDefaults *defaults;
  NSFileManager  *manager;
  NSString       *companyId;
  NSString       *path;
  NSString       *imgPath;

  companyId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (companyId == nil) return;
  RELEASE(self->imageData); self->imageData = nil;
  RELEASE(self->imageType); self->imageType = nil;
  RELEASE(self->imagePath); self->imagePath = nil;


  if (![self isAttributeSupported:@"image"]) return;
  
  manager  = [NSFileManager defaultManager];
  defaults = [[self context] valueForKey:LSUserDefaultsKey];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  
  imgPath = [NSString stringWithFormat:@"%@/%@.picture.jpg", path, companyId];
  if ([manager fileExistsAtPath:imgPath]) {
    self->imageData = [[NSData alloc] initWithContentsOfFile:imgPath];
    self->imageType = @"image/jpeg";
    RETAIN(self->imageType);
    ASSIGN(self->imagePath, imgPath);
    return;
  }

  imgPath = [NSString stringWithFormat:@"%@/%@.picture.gif", path, companyId];
  if ([manager fileExistsAtPath:imgPath]) {
    self->imageData = [[NSData alloc] initWithContentsOfFile:imgPath];
    self->imageType = @"image/gif";
    ASSIGN(self->imagePath, imgPath);
    RETAIN(self->imageType);
  }
  if (self->imageData == nil) self->imageData = [[NSData alloc] init];
  if (self->imageType == nil) self->imageType = [[NSString alloc] init];
}

- (NSArray *)_newTelephones:(id)_ctx {
  NSEnumerator   *e    = nil;
  id             one   = nil;
  NSMutableArray *tels = nil;
  NSArray *types =
    [[[_ctx userDefaults]
             dictionaryForKey:@"LSTeleType"]
             objectForKey:[self entityName]];

  e = [types objectEnumerator];
  tels = [NSMutableArray array];
  while ((one = [e nextObject])) {
    NSMutableDictionary *tel = [NSMutableDictionary dictionaryWithCapacity:4];
    [tel setObject:one forKey:@"type"];
    [tels addObject:tel];
  }
  return tels;
}

- (NSArray *)_attributesForState:(NSString *)_state ctx:(id)_ctx {
  NSString  *key     = [NSString stringWithFormat:@"Sky%@Extended",
                                       _state];

  key = [key stringByAppendingString:[self entityName]];
  key = [key stringByAppendingString:@"Attributes"];

  return [[_ctx userDefaults] arrayForKey:key];
}

- (NSDictionary *)_newAttributeMap:(id)_ctx {
  NSMutableDictionary *map      = nil;
  NSArray             *allAttrs = nil;
  unsigned cnt, pos;
  
  map = [NSMutableDictionary dictionaryWithCapacity:12];

  allAttrs = [self _attributesForState:@"Private" ctx:_ctx];
  allAttrs = (allAttrs != nil)
    ? [allAttrs arrayByAddingObjectsFromArray:
               [self _attributesForState:@"Public" ctx:_ctx]]
    : [self _attributesForState:@"Public" ctx:_ctx];
  
  if (allAttrs == nil)
    allAttrs = [NSArray array];
  
  for (pos = 0, cnt = [allAttrs count]; pos < cnt; pos++) {
    NSDictionary *attr;
    
    attr = [allAttrs objectAtIndex:pos];
    [map setObject:attr forKey:[attr objectForKey:@"key"]];
  }
  return map;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@[%@] owner:%@ "
                   @"self->supportedAttributes %@ self->attributeMap %@",
                   [super description], self->globalID, self->owner,
                   self->supportedAttributes, self->attributeMap];
}

@end /* SkyCompanyDocument(Private) */

@implementation SkyCompanyDocument(EOGenericRecord)

/* compatibility with EOGenericRecord (is deprecated!!!)*/

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSAssert1((_key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
  if (_value == nil)
    return;
  else if (![self isValid]) {
    [NSException raise:@"invalid person document"
                 format:@"cannot takeValue:forKey:%@, document %@ is invalid",
                 _key, self];
    return;
  }
  else if (![self isComplete]) {
    [NSException raise:@"person document is not complete, use reload"
               format:@"cannot takeValue:forKey:%@, document %@ is incomplete",
                   _key, self];
    return;
  }
  else if ([self->extendedKeys containsObject:_key])
    [self setExtendedAttribute:_value forKey:_key];
  else if ([[self phoneTypes] containsObject:_key])
    [self setPhoneNumber:_value forType:_key];
  else if ([_key hasSuffix:@"_info"]) {
    NSArray *frags = [_key componentsSeparatedByString:@"_info"];

    if ([frags count] == 2)
      [self setPhoneInfo:_value forType:[frags objectAtIndex:0]];
  }
  else if ([_key isEqualToString:@"extendedAttrs"]) {
    NSLog(@"WARNING[%s]: tried to set extendedAttrs",
          __PRETTY_FUNCTION__);
  }
  else {
    //NSLog(@"%s: _value[%@][%p] %@ _key[%@][%p] %@",
    //      __PRETTY_FUNCTION__, [_value class], _value, _value,
    //      [_key class], _key, _key);
    [super takeValue:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"ownerId"])
    return [[(EOKeyGlobalID *)self->ownerGID keyValuesArray] lastObject];
  if ([_key isEqualToString:@"contactId"])
    return [[(EOKeyGlobalID *)self->contactGID keyValuesArray] lastObject];
  
  if ([_key isEqualToString:@"globalID"])
    return self->globalID;
  
  if ([[self addressTypes] containsObject:_key])
    return [self addressForType:_key];
  
  if ([[self phoneTypes] containsObject:_key])
    return [self phoneNumberForType:_key];
  
  if ([_key hasSuffix:@"_info"]) {
    NSArray *frags = [_key componentsSeparatedByString:@"_info"];

    return ([frags count] == 2)
      ? [self phoneInfoForType:[frags objectAtIndex:0]]
      : nil;
  }
  
  if ([self->extendedKeys containsObject:_key])
    return [self extendedAttributeForKey:_key];
  
  return [super valueForKey:_key];
}

@end /* SkyCompanyDocument(EOGenericRecord) */
