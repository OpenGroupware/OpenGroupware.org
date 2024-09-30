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
- (EOKeyGlobalID *)_personGidFrom:(NSNumber *)_personId;
- (void)_reloadImage;
- (void)_setGlobalID:(id)_gid;
- (void)_setCompanyId:(id)_companyId;
@end /* SkyCompanyDocument(PrivateMethodes) */

@implementation SkyCompanyDocument

static BOOL DebugDocumentRegistration = NO;

+ (int)version {
  return [super version] + 7; /* v8 */
}

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);

  DebugDocumentRegistration = [ud boolForKey:@"DebugDocumentRegistration"];
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
  [self errorWithFormat:@"%s: subclasses need to override this method!",
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
  [self warnWithFormat:@"%s: document has no datasource/context: %@",
         __PRETTY_FUNCTION__, self];
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
  [self->phones     release]; self->phones       = nil;
  [self->phoneTypes release]; self->phoneTypes   = nil;
  [self->addresses  release]; self->addresses    = nil;
  [self->comment    release]; self->comment      = nil;
  [self->keywords   release]; self->keywords     = nil;
  [self->imageType  release]; self->imageType    = nil;
  [self->imageData  release]; self->imageData    = nil;

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
  
  if (_type == nil) {
    [self warnWithFormat:@"got no type when setting phone number: %@",_number];
    return;
  }
  
  if ([[self phoneNumberForType:_type] isEqual:_number]) /* did not change */
    return;
  
  phone = [self->phones valueForKey:_type];
  self->status.isEdited = YES;
  if (phone == nil) {
    phone = [NSMutableDictionary dictionaryWithCapacity:4];
        
    [phone takeValue:_type   forKey:@"type"];
    [self->phones takeValue:phone forKey:_type];

#if 0
#warning DEBUG LOG, DISABLE ME
    [self logWithFormat:@"created new phone for type %@: %@", _type, phone];
#endif
  }
#if 0
  else {
    [self logWithFormat:@"changing number(%@) in existing phone type %@: %@",
	    _number, _type, phone];
  }
#endif

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
  
  [self errorWithFormat:@"%s: subclasses need to override this method!",
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
  NSNumber *inputId, *currentId;

  inputId = [[(EOKeyGlobalID *)[_contact globalID] keyValuesArray] lastObject];
  currentId = [[(EOKeyGlobalID *)self->contactGID keyValuesArray] lastObject];

  if ([currentId isEqual:inputId])
    return;

  [self->contact    release]; self->contact = nil;
  [self->contactGID release]; self->contactGID = nil;
  
  self->contactGID = [[self _personGidFrom:inputId] retain];
  self->status.isEdited = YES;
}

- (SkyDocument *)contact {
  if (![self isAttributeSupported:@"contact"]) return nil;
  
  if (self->contact == nil && self->contactGID != nil) {
    static Class clazz = Nil;

    if (clazz == Nil)
      clazz = NGClassFromString(@"SkyAccountDocument");
      
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
    clazz = NGClassFromString(@"SkyAccountDocument");
  
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
  [self errorWithFormat:@"%s: catched exception: %@", 
	  __PRETTY_FUNCTION__, _exception];
}

- (NSString *)nameOfSetCommand {
  [self errorWithFormat:@"%s: subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (BOOL)save {
  BOOL result = YES;
  
  if (!self->status.isEdited) return YES;
  if (![self isComplete])     return NO;
  
  NS_DURING {
    if (self->globalID == nil) {
      NSArray *addrs;
      int     i, cnt;

#if 0
#warning DEBUG LOG, REMOVE ME
      [self logWithFormat:@"saving w/o GID ..."];
#endif
      
      [self->dataSource insertObject:self];
      addrs = [[self context] runCommand:@"address::get",
                            @"companyId", [self companyId],
                            @"returnType", intObj(LSDBReturnType_ManyObjects),
                            nil];

      for (i = 0, cnt = [addrs count]; i < cnt; i++) {
        SkyAddressDocument *addrDoc;
        EOKeyGlobalID      *gid;
        id                 addrEO;
        id                 value[1];

	addrEO   = [addrs objectAtIndex:i];
        addrDoc  = [self addressForType:[addrEO valueForKey:@"type"]];
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
      NSEnumerator *typE;
      id           one;

#if 0
#warning DEBUG LOG, REMOVE ME
      [self logWithFormat:@"updating using DS ..."];
#endif
      
      typE = [[self addressTypes] objectEnumerator];
      while ((one = [typE nextObject]) != nil) {
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
  
  NS_DURING
    [self->dataSource deleteObject:self];
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)reload {
  if (![self isValid])
    return NO;

  if ([self globalID] == nil) {
    [self invalidate];
  }
  else {
    NSString *cmdName;
    id obj;
    
    // eg person::get-by-globalid
    cmdName = [[[self entityName] lowercaseString]
		      stringByAppendingString:@"::get-by-globalid"];
    
    obj = [[[self context] runCommand:cmdName, @"gid", [self globalID], nil] 
	    lastObject];
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

- (void)_loadPhonesFromObject:(id)_object {
  NSArray *list;
  int     i, cnt;

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
      if ([phone objectForKey:@"telephoneId"] != nil) {
	[dict setObject:[phone objectForKey:@"telephoneId"]
	      forKey:@"telephoneId"];
      }
      [self->phones setObject:dict forKey:type];
      [dict release]; dict = nil;
  }

  [self _loadPhoneTypes];
}

- (void)_loadExtAttrsFromObject:(id)_object {
  /*
    If the subclass supports extended attributes this derives the following
    ivars from the 'attributeMap' KVC key of the _object:
    - TODO
  */
  NSMutableArray *slist = nil;
  NSArray *list;
  int     i, cnt;

  list = [[_object valueForKey:@"attributeMap"] allKeys];
  list = [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
  cnt  = [list count];

  slist = [[NSMutableArray alloc] initWithCapacity:cnt];
    
  [self->extendedAttrs release]; self->extendedAttrs = nil;
  self->extendedAttrs = [[NSMutableDictionary alloc] initWithCapacity:cnt];
    
  for (i = 0; i < cnt; i++) {
      NSString *key;
      id       obj;

      key = [list objectAtIndex:i];
      obj = [_object valueForKey:key];

      if (obj != nil)
        [self->extendedAttrs setObject:obj forKey:key];
    
      /* Note: we sort in email1/email2 in the front (hack hack hack) */
      if ([key isEqualToString:@"email1"])
        [slist insertObject:key atIndex:0];
      else if ([key isEqualToString:@"email2"]) {
        if ([slist isNotEmpty])
          [slist insertObject:key atIndex:1];
        else
          [slist addObject:key];
      }
      else
        [slist addObject:key];
  }
  ASSIGN(self->extendedKeys, slist); // TODO: can we use a copy?
  [slist release]; slist = nil;
  
  [self->attributeMap release]; self->attributeMap = nil;
  self->attributeMap = [[_object valueForKey:@"attributeMap"] retain];
}

- (void)_resetDocumentPriorLoad {
  [self->extendedAttrs release]; self->extendedAttrs = nil;
  [self->attributeMap  release]; self->attributeMap  = nil;
  [self->contact       release]; self->contact       = nil;
  [self->contactGID    release]; self->contactGID    = nil;
  [self->owner         release]; self->owner         = nil;
  [self->ownerGID      release]; self->ownerGID      = nil;
  [self->addresses     release]; self->addresses     = nil;
}

- (void)_loadCommentFromObject:(id)_object {
  [self setComment:[[_object valueForKey:@"comment"]
                             valueForKey:@"comment"]];
}

- (void)_loadDocument:(id)_object {
  [self _resetDocumentPriorLoad];
  
  // set telephone numbers
  if ([self isAttributeSupported:@"telephones"])
    [self _loadPhonesFromObject:_object];

  [self _setObjectVersion:[_object valueForKey:@"objectVersion"]];

  if ([self isAttributeSupported:@"extendedAttributes"])
    [self _loadExtAttrsFromObject:_object];
  
  self->contactGID = 
    [[self _personGidFrom:[_object valueForKey:@"contactId"]] retain];
  
  self->ownerGID = 
    [[self _personGidFrom:[_object valueForKey:@"ownerId"]] retain];
  
  if ([self isAttributeSupported:@"comment"])
    [self _loadCommentFromObject:_object];
  
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

/* Private */

- (void)_registerForGID {
  if (!self->addAsObserver) return;

  if (DebugDocumentRegistration) {
    [self warnWithFormat:@"register Document in NotificationCenter(%s)",
          __PRETTY_FUNCTION__];
  }
  if (self->globalID != nil) {
#if 0
    printf("%s: %s[%p]\n", __PRETTY_FUNCTION__, [self->globalID class]->name,
           self->globalID);
#endif
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

- (EOKeyGlobalID *)_personGidFrom:(NSNumber *)_personId {
  if (![_personId isNotNull])
    return nil;

  return [EOKeyGlobalID globalIDWithEntityName:@"Person"
			keys:&_personId keyCount:1
			zone:NULL];
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
  [self->imageData release]; self->imageData = nil;
  [self->imageType release]; self->imageType = nil;
  [self->imagePath release]; self->imagePath = nil;
  
  if (![self isAttributeSupported:@"image"]) return;
  
  manager  = [NSFileManager defaultManager];
  defaults = [[self context] valueForKey:LSUserDefaultsKey];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  
  /* check for .jpg */
  
  imgPath = [NSString stringWithFormat:@"%@/%@.picture.jpg", path, companyId];
  if ([manager fileExistsAtPath:imgPath]) {
    self->imageData = [[NSData alloc] initWithContentsOfFile:imgPath];
    self->imageType = @"image/jpeg";
    
    ASSIGNCOPY(self->imagePath, imgPath);
    return;
  }

  /* check for .gif */
  
  imgPath = [NSString stringWithFormat:@"%@/%@.picture.gif", path, companyId];
  if ([manager fileExistsAtPath:imgPath]) {
    self->imageData = [[NSData alloc] initWithContentsOfFile:imgPath];
    self->imageType = @"image/gif";
    ASSIGNCOPY(self->imagePath, imgPath);
    return;
  }
  
  /* empty */
  if (self->imageData == nil) self->imageData = [[NSData   alloc] init];
  if (self->imageType == nil) self->imageType = @"";
}

- (NSArray *)_newTelephones:(id)_ctx {
  NSEnumerator   *e;
  id             one;
  NSMutableArray *tels = nil;
  NSArray *types;
  
  types =
    [[[_ctx userDefaults] dictionaryForKey:@"LSTeleType"] 
            objectForKey:[self entityName]];
  
  tels = [NSMutableArray arrayWithCapacity:4];
  
  e = [types objectEnumerator];
  while ((one = [e nextObject]) != nil) {
    NSMutableDictionary *tel;
    
    tel = [[NSMutableDictionary alloc] initWithCapacity:4];
    [tel setObject:one forKey:@"type"];
    [tels addObject:tel];
    [tel release]; tel = nil;
  }
  return tels;
}

- (NSArray *)_attributesForState:(NSString *)_st ctx:(LSCommandContext *)_ctx {
  NSString  *key;
  
  key = [NSString stringWithFormat:@"Sky%@Extended%@Attributes",
		  _st, [self entityName]];
  
  return [[_ctx userDefaults] arrayForKey:key];
}

- (NSDictionary *)_newAttributeMap:(LSCommandContext *)_ctx {
  NSMutableDictionary *map;
  NSArray             *allAttrs;
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

/* EOGenericRecord */

/* compatibility with EOGenericRecord (is deprecated!!!)*/

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSAssert1((_key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
  
  if (_value == nil) {
    // TODO: hm, why is this?
    [self warnWithFormat:@"attempt to set key to nil: %@", _key];
    return;
  }
  
  if (![self isValid]) {
    [NSException raise:@"invalid person document"
                 format:@"cannot takeValue:forKey:%@, document %@ is invalid",
                 _key, self];
    return;
  }
  
  if (![self isComplete]) {
    [NSException raise:@"person document is not complete, use reload"
               format:@"cannot takeValue:forKey:%@, document %@ is incomplete",
                   _key, self];
    return;
  }
  
  if ([self->extendedKeys containsObject:_key])
    [self setExtendedAttribute:_value forKey:_key];
  else if ([[self phoneTypes] containsObject:_key])
    [self setPhoneNumber:_value forType:_key];
  else if ([_key hasSuffix:@"_info"]) {
    NSArray *frags = [_key componentsSeparatedByString:@"_info"];

    if ([frags count] == 2)
      [self setPhoneInfo:_value forType:[frags objectAtIndex:0]];
  }
  else if ([_key isEqualToString:@"extendedAttrs"]) {
    [self warnWithFormat:@"%s: attempt to set 'extendedAttrs' key via KVC",
          __PRETTY_FUNCTION__];
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
      : (NSString *)nil;
  }
  
  if ([self->extendedKeys containsObject:_key])
    return [self extendedAttributeForKey:_key];
  
  return [super valueForKey:_key];
}

/* description */

- (void)appendAttributesToDescription:(NSMutableString *)_md {
  [super appendAttributesToDescription:_md];
  
  if (self->owner != nil)
    [_md appendFormat:@" owner=%@", self->owner];
  
  if (self->supportedAttributes != nil)
    [_md appendFormat:@" supattrs=%@", self->supportedAttributes];
  
  if (self->attributeMap != nil)
    [_md appendFormat:@" amap=%@", self->attributeMap];
  
  if (self->phoneTypes != nil)
    [_md appendFormat:@" ptypes=%@", self->phoneTypes];
  
  [_md appendFormat:@" phones=#%d", [self->phones    count]];
  [_md appendFormat:@" addrs=#%d",  [self->addresses count]];
}

@end /* SkyCompanyDocument */
