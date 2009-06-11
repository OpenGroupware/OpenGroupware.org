/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "LSSetCompanyCommand.h"
#include "common.h"

@interface LSSetCompanyCommand(ExtendedAttributes)
- (NSDictionary *)_fetchDefaultExtendedAttributes:(id)_context;
- (NSMutableDictionary *)_getDefaults:(NSString *)_status with:(id)_context;
@end /* LSSetCompanyCommand(ExtendedAttributes) */

@implementation LSSetCompanyCommand

static id <NSObject,LSCommand> setCmd = nil;
static id <NSObject,LSCommand> newCmd = nil;
static NSArray  *defExcludeKeys    = nil;
static NSString *autoNumberPrefix = @"OGo";

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  defExcludeKeys = [[ud arrayForKey:@"LSCompanyCommandExcludeKeys"] copy];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"05_changed"      forKey:@"logAction"];
    [self takeValue:@"company changed" forKey:@"logText"];
  }
  return self;
}

- (void)dealloc {
  [self->telephones      release];
  [self->comment         release];
  [self->pictureData     release];
  [self->pictureFilePath release];
  [super dealloc];
}

/* command methods */

- (BOOL)_setCompanyInfo:(id)_ctx {
  NSNumber       *objId;
  EOSQLQualifier *qual;
  EOModel        *model;
  id   genObjInfo = nil;
  id c;
  id obj;

  model = [[[_ctx valueForKey:LSDatabaseKey] adaptor] model];
  objId = [[self object] valueForKey:@"companyId"];
  qual  = [[EOSQLQualifier alloc] initWithEntity:
                                  [model entityNamed:@"CompanyInfo"]
                                  qualifierFormat:@"%A=%@",
                                  @"companyId", objId, nil];

  if (![[self databaseChannel] selectObjectsDescribedByQualifier:qual
                               fetchOrder:nil]) {
    [self errorWithFormat:@"%s: select of company info failed (%@)",
	    __PRETTY_FUNCTION__, [self object]];
    return NO;
  }
  [qual release]; qual = nil;


  genObjInfo = [[self databaseChannel] fetchWithZone:NULL];
  [[self databaseChannel] cancelFetch];
    
  if (genObjInfo == nil)
    return NO;

  c = [self comment];
  if (![c isNotEmpty])
    c = [NSNull null];
    
  [genObjInfo takeValue:c forKey:@"comment"];

  obj = [self primaryKeyValue];
  if ([obj intValue] != 0)
    [genObjInfo takeValue:obj forKey:@"companyId"];

  [genObjInfo takeValue:@"updated" forKey:@"status"];

  [self assert:(genObjInfo != nil) reason:@"no toCompanyInfo to update .."];
  return [[self databaseChannel] updateObject:genObjInfo];
}

- (void)_setExtendedAttributesInContext:(id)_context {
  NSDictionary        *defaultAttrs = nil;
  NSMutableArray      *excludeKeys  = nil;
  NSEnumerator        *keyEnum      = nil;
  NSArray             *extAttrs     = nil;
  NSString            *key          = nil;
  NSMutableDictionary *map          = nil;
  NSMutableArray      *compValues   = nil;
  NSNumber            *accountId    = nil;
  int                 i, cnt;
  id                  obj;
  
  /* handle already existing attributes */
  obj      = [self object];
  extAttrs = [obj valueForKey:@"companyValue"]; // TODO: who does that?
  // TODO: autofetch if 'companyValue' isn't set?
  if (extAttrs == nil)
    [self warnWithFormat:@"companyValue is not set, might DUP attrs."];
  
  for (i = 0, cnt = [extAttrs count]; i < cnt; i++) {
    id extAttr, value;
    
    extAttr = [extAttrs objectAtIndex:i];
    value   = [obj valueForKey:[extAttr valueForKey:@"attribute"]];
    
    LSRunCommandV(_context, @"companyvalue", @"set",
                  @"object",      extAttr,
                  @"checkAccess", [self checkAccess],
                  @"value",       value, nil);
  }

  /* handle new attributes */
  excludeKeys = 
    [NSMutableArray arrayWithArray:[[obj entity] classPropertyNames]];
  [excludeKeys addObjectsFromArray:defExcludeKeys];
  [excludeKeys addObjectsFromArray:[extAttrs valueForKey:@"attribute"]];
  
  defaultAttrs = [self _fetchDefaultExtendedAttributes:_context];
  keyEnum      = [defaultAttrs keyEnumerator];
  map          = [obj valueForKey:@"attributeMap"];
  compValues   = [obj valueForKey:@"companyValue"];
  accountId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  
  while ((key = [keyEnum nextObject]) != nil) {
    NSDictionary *attr;
    int           type;
    NSString     *label;
    id            userId;
    id            compValue = nil;
    
    if (!(![excludeKeys containsObject:key] && [obj valueForKey:key] != nil))
      continue;
    
    attr   = [defaultAttrs objectForKey:key];
    type   = [[attr valueForKey:@"type"] intValue];
    label  = [attr valueForKey:@"label"];
    userId = [NSNull null];
      
    if ([[attr objectForKey:@"isPrivate"] boolValue])
      userId = accountId;
    if (type == 0) type = 1;
    if (label == nil) label = (id)[NSNull null];
    compValue = LSRunCommandV(_context,
			      @"companyvalue", @"new",
			      @"companyId", [obj valueForKey:@"companyId"],
			      @"attribute", key,
			      @"uid",       userId,
			      @"label",     label,
			      @"type",      [NSNumber numberWithInt:type],
			      @"value",     [obj valueForKey:key], nil);
    [map setObject:compValue forKey:key];
    [compValues addObject:compValue];
  }
}

- (id)_findEOWithId:(NSNumber *)_phoneId {
  NSArray *tels;
  int     i, cnt;
  
  // TODO: ensure explicit fetch of phones, avoid fault?
  tels = [[self object] valueForKey:@"toTelephone"];
  for (i = 0, cnt = [tels count]; i < cnt; i++) {
    id tel;
  
    // TODO: should we also check the type?
    tel = [tels objectAtIndex:i];
    if ([[tel valueForKey:@"telephoneId"] isEqual:_phoneId])
      return tel;
  }
  return nil;
}

- (void)_setupPhoneCommands {
  if (setCmd == nil) setCmd = [LSLookupCommand(@"telephone", @"set") retain];
  if (newCmd == nil) newCmd = [LSLookupCommand(@"telephone", @"new") retain];
}

- (void)_setTelephone:(NSDictionary *)telDict 
  onContactWithPrimaryKey:(NSNumber *)pkey inContext:(id)_context
{
  NSNumber *phoneId;
  id       telEO;

  phoneId  = [telDict valueForKey:@"telephoneId"];
  telEO    = [self _findEOWithId:phoneId];
    
  if ([phoneId isNotNull]) { /* telephone::set */
    [setCmd takeValue:telEO forKey:@"object"];
    [setCmd takeValuesFromDictionary:telDict];
    [setCmd runInContext:_context];
  }
  else { /* telephone::new */
    [newCmd takeValuesFromDictionary:telDict];
    [newCmd takeValue:pkey forKey:@"companyId"];
    phoneId = [[newCmd runInContext:_context] valueForKey:@"telephoneId"];
    [telDict takeValue:phoneId forKey:@"telephoneId"];
  }
}
- (void)_setTelephoneCommandsInContext:(id)_context {
  NSNumber *pkey;
  int i, cnt;

  [self _setupPhoneCommands];
  
  pkey = [[self object] valueForKey:[self primaryKeyName]];
  for (i = 0, cnt = [self->telephones count]; i < cnt; i++) {
    [self _setTelephone:[self->telephones objectAtIndex:i] 
	  onContactWithPrimaryKey:pkey inContext:_context];
  }
}

/* prepare for execution */

- (void)_fixNumber {
  id obj, n;

  obj = [self object];
  n   = [obj valueForKey:@"number"];
  
  if ([n isKindOfClass:[NSString class]]) {
    if (![n isNotEmpty])
      n = nil;
  }
  if ([n isNotNull])
    return;

  n = [[obj valueForKey:@"companyId"] stringValue];
  n = [autoNumberPrefix stringByAppendingString:n];
  [obj takeValue:n forKey:@"number"];
}

- (void)_prepareForExecutionInContext:(id)_context {
  [super _prepareForExecutionInContext:_context];
  [self _fixNumber];
}

/* run */

- (BOOL)hasWriteAccessOn:(id)_obj inContext:(id)_ctx {
  _obj = [_obj valueForKey:@"globalID"];
  return [[_ctx accessManager] operation:@"w" allowedOnObjectID:_obj];
}

- (void)saveAttachmentInContext:(id)_context {
  // TODO: overridden in person::set?
  /*
    Writes the picture for a given contact
  */
  NSFileManager  *manager;
  NSUserDefaults *defaults;
  id             obj;
  NSString       *fileName = nil;
  NSString       *fName    = nil;
  BOOL           isOk      = NO;

  manager  = [NSFileManager defaultManager];
  defaults = [_context userDefaults];
  obj      = [self object];
    
  fileName = [defaults stringForKey:@"LSAttachmentPath"];
  fileName = [NSString stringWithFormat:@"%@/%@.picture",
                         fileName, [obj valueForKey:@"companyId"]];

  if ((self->pictureData != nil && self->pictureFilePath != nil
       && [self->pictureData isNotEmpty])
      || self->deleteImage) {
    fName = [fileName stringByAppendingPathExtension:@"jpg"];
    
    if ([manager fileExistsAtPath:fName])
      [manager removeFileAtPath:fName handler:nil];        
    
    fName = [fileName stringByAppendingPathExtension:@"gif"];

    if ([manager fileExistsAtPath:fName])
      [manager removeFileAtPath:fName handler:nil];        
  }

  if (self->pictureData !=nil && self->pictureFilePath != nil &&
      [self->pictureData isNotEmpty]) {
    fName = [fileName stringByAppendingPathExtension:
                        [self->pictureFilePath pathExtension]];
    isOk  = [self->pictureData writeToFile:fName atomically:YES];

    [self assert:isOk
	  reason:@"error during save of person/enterprise picture"];
  }
}

- (void)_executeInContext:(id)_context {
  [self assert:([self object] != nil) reason:@"no company object to act on"];
  
  if ([[self checkAccess] boolValue]) {
    if (![self hasWriteAccessOn:[self object] inContext:_context]) {
      // TODO: do not log object!
      [self logWithFormat:@"missing write access for %@", [self object]];
      [self setReturnValue:nil];
      return;
    }
  }

  [self bumpChangeTrackingFields];
  
  [super _executeInContext:_context];

  //  if (self->comment)
  [self assert:[self _setCompanyInfo:_context]];

  [self _setExtendedAttributesInContext:_context];

  if (self->telephones != nil)
    [self _setTelephoneCommandsInContext:_context];
  
  // save attachment
  [self saveAttachmentInContext:_context];
  
  LSRunCommandV(_context, @"object", @"add-log",
                @"logText"    , [self valueForKey:@"logText"],
                @"action"     , [self valueForKey:@"logAction"],
                @"objectToLog", [self object],
                nil);

  [self calculateCTagInContext:_context];
}

/* accessors */

- (void)setTelephones:(NSArray *)_telephones {
  ASSIGN(self->telephones, _telephones);
}
- (NSArray *)telephones {
  return self->telephones;
}

/* company info accessors */

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;
}

- (void)setPictureData:(NSData *)_pictureData {
  ASSIGN(self->pictureData, _pictureData);
}
- (NSData *)pictureData {
  return self->pictureData;
}

- (void)setPictureFilePath:(NSString *)_pictureFilePath {
  ASSIGNCOPY(self->pictureFilePath, _pictureFilePath);
}
- (NSString *)pictureFilePath {
  return self->pictureFilePath;
}

- (void)setDeleteImage:(BOOL)_flag {
  self->deleteImage = _flag;
}
- (BOOL)deleteImage {
  return self->deleteImage;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"telephones"]) {
    [self setTelephones:_value];
    return;
  }
  if ([_key isEqualToString:@"comment"]) {
    [self setComment:_value];
    return;
  }
  if ([_key isEqualToString:@"pictureData"]) {
    [self setPictureData:_value];
    return;
  }
  if ([_key isEqualToString:@"pictureFilePath"]) {
    [self setPictureFilePath:_value];
    return;
  }
  if ([_key isEqualToString:@"deleteImage"]) {
    [self setDeleteImage:[_value boolValue]];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"comment"])
    return [self comment];
  if ([_key isEqualToString:@"telephones"])
    return [self telephones];
  if ([_key isEqualToString:@"pictureData"])
    return [self pictureData];
  if ([_key isEqualToString:@"pictureFilePath"])
    return [self pictureFilePath];
  if ([_key isEqualToString:@"deleteImage"])
    return [NSNumber numberWithBool:[self deleteImage]];

  return [super valueForKey:_key];
}

/* ExtendedAttributes */

- (NSDictionary *)_fetchDefaultExtendedAttributes:(id)_context {
  NSMutableDictionary *attrs;
  
  attrs = [self _getDefaults:@"Public" with:_context];
  [attrs addEntriesFromDictionary:
	   [self _getDefaults:@"Private" with:_context]];
  return attrs;
}

// _status should be "Private" or "Public"
- (NSMutableDictionary *)_getDefaults:(NSString *)_status with:(id)_context {
  BOOL           isPrivate;
  id             account;
  NSString       *key;
  NSUserDefaults *defs;
  
  isPrivate = [_status isEqualToString:@"Private"];
  account   = [_context valueForKey:LSAccountKey];
  key       = [NSString stringWithFormat:@"Sky%@Extended", _status];
  defs      = nil;
  
  if (account == nil) {
    defs = [NSUserDefaults standardUserDefaults];
  }
  else {
    defs = LSRunCommandV(_context, @"userdefaults", @"get",
                         @"user", account, nil);
  }
  
  key = [key stringByAppendingString:[self entityName]];
  key = [key stringByAppendingString:@"Attributes"];

  //e.g. key = "SkyPublicExtendedPersonAttributes"
  {
    NSMutableDictionary *result;
    NSEnumerator        *attrEnum;
    NSMutableDictionary *attr;
    
    result   = [NSMutableDictionary dictionaryWithCapacity:16];
    attrEnum = [[defs arrayForKey:key] objectEnumerator];
    while ((attr = [attrEnum nextObject])) {
      [self assert:([attr objectForKey:@"key"] != nil)
            reason:@"Extended attribute: missing attribute 'key'"];
      if (isPrivate)
        [attr setObject:[NSNumber numberWithBool:YES] forKey:@"isPrivate"];
      [result setObject:attr forKey:[attr objectForKey:@"key"]];
    }
    return result;
  }
}

@end /* LSSetCompanyCommand */
