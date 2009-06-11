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

#include "LSNewCompanyCommand.h"
#include "common.h"

@interface LSNewCompanyCommand(ReadDefaults)
- (void)_fetchDefaultExtendedAttributes:(id)_context;
- (NSMutableDictionary *)_getDefaults:(NSString *)_status with:(id)_context;

@end

@implementation LSNewCompanyCommand

static NSArray  *defExcludeKeys = nil;
static EONull   *null   = nil;
static NSNumber *yesNum = nil;
static NSString *autoLoginPrefix  = @"OGo";
static NSString *autoNumberPrefix = @"OGo";

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  defExcludeKeys = [[ud arrayForKey:@"LSCompanyCommandExcludeKeys"] copy];
  null   = [[EONull null] retain];
  yesNum = [[NSNumber numberWithBool:YES] retain];
  
  autoLoginPrefix  = [[ud stringForKey:@"LSAutoCompanyLoginPrefix"] copy];
  autoNumberPrefix = [[ud stringForKey:@"LSAutoCompanyNumberPrefix"] copy];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"00_created"      forKey:@"logAction"];
    [self takeValue:@"Company created" forKey:@"logText"];
  }
  return self;
}

- (void)dealloc {
  [self->comment           release];
  [self->telephones        release];
  [self->_newAddrCmds      release];
  [self->_newTelephoneCmds release];
  [self->pictureData       release];
  [self->pictureFilePath   release];
  [super dealloc];
}

/* defaults */

- (NSDictionary *)addressTypeMapInContext:(id)_ctx {
  /* eg: LSAddressType = { Enterprise = ( ship ); Person = ( private ) }; */
  return [[_ctx userDefaults] dictionaryForKey:@"LSAddressType"];
}
- (NSDictionary *)teleTypeMapInContext:(id)_ctx {
  return [[_ctx userDefaults] dictionaryForKey:@"LSTeleType"];
}

- (NSArray *)addressTypesInContext:(id)_ctx {
  /* eg: ( ship, bill ) */
  return [[self addressTypeMapInContext:_ctx] objectForKey:[self entityName]];
}
- (NSArray *)teleTypesInContext:(id)_ctx {
  /* eg: ( 01_tel, 02_tel, 10_fax ) */
  return [[self teleTypeMapInContext:_ctx] objectForKey:[self entityName]];
}

/* command methods */

- (BOOL)_hasCommandWithEntityName:(NSString *)_entityName andKey:(id)_key
  andValue:(id)_value
{
  // TODO: only used by LSNewCompanyCommand, move there?!
  BOOL         hasCommmand;
  NSEnumerator *cmdEnumerator;
  id<NSObject,LSDBCommand> cmd;

  hasCommmand   = NO;
  cmdEnumerator = [[self commands] objectEnumerator];
  while ((cmd = [cmdEnumerator nextObject]) != nil) {
    if (![cmd isKindOfClass:[LSDBObjectBaseCommand class]])
      continue;
    
    if (![[cmd entityName] isEqualToString:_entityName])
      continue;

    if (_key != nil) {
      if ([[cmd valueForKey:_key] isEqual:_value]) {
	hasCommmand = YES;
	break;
      }
    }
    else {
      hasCommmand = YES;
      break;
    }
  }
  return hasCommmand;
}

- (BOOL)_hasCommandWithEntityName:(NSString *)_entityName {
  return [self _hasCommandWithEntityName:_entityName andKey:nil andValue:nil];
}

- (void)_prepareNewAddrCmdsInContext:(id)_ctx {
  /* this sets up an array of configured 'address::new' invocations */
  NSArray      *types;
  NSEnumerator *objEnum;
  id curtype;
  
  if ((types = [self addressTypesInContext:_ctx]) == nil)
    return;
  
  self->_newAddrCmds = [[NSMutableArray alloc] initWithCapacity:4];
  
  objEnum = [types objectEnumerator]; 
  while ((curtype = [objEnum nextObject]) != nil) {
    id <NSObject,LSCommand> cmd;
    BOOL hasCommand;
    
    // TODO: what does that check?
    // => see LSDBObjectBaseCommand, it searches for a 'subcommand' which
    //    has the 'address' entity (namespace, not EO) and a parameter key
    //    'type' which equals the given value
    // TODO: how can this work? one can't attach a subcommand because the
    //       command wouldn't know about the primary-key of the company?
    hasCommand = [self _hasCommandWithEntityName:@"address" andKey:@"type"
		       andValue:curtype];
    if (hasCommand) continue;
    
    cmd = LSLookupCommand(@"address", @"new");
    [cmd takeValue:curtype forKey:@"type"];
    [self->_newAddrCmds addObject:cmd];
  }
}

- (void)_prepareNewTelephoneCmdsInContext:(id)_ctx {
  // TODO: this is basically a duplicate of _prepareNewAddrCmdsInContext!!
  NSArray      *types;
  NSEnumerator *objEnum;
  id obj;
  
  if ((types = [self teleTypesInContext:_ctx]) == nil)
    return;

  self->_newTelephoneCmds = [[NSMutableArray alloc] initWithCapacity:8];
  
  objEnum = [types objectEnumerator]; 
  while ((obj = [objEnum nextObject]) != nil) {
    id <NSObject,LSCommand> cmd;
    BOOL hasCommand;
    
    // TODO: what does that check?
    hasCommand = [self _hasCommandWithEntityName:@"telephone" andKey:@"type"
		       andValue:obj];
    if (hasCommand) continue;

    cmd = LSLookupCommand(@"telephone", @"new");
    [cmd takeValue:obj forKey:@"type"];
    [self->_newTelephoneCmds addObject:cmd];
  }
}

- (void)_checkAndPrepareAddedCommands {
  id<NSObject,LSCommand> cmd;
  NSEnumerator *cmds;
  NSNumber     *pkey;
  
  cmds = [[self commands] objectEnumerator];
  pkey = [[self object] valueForKey:[self primaryKeyName]];
  
  while ((cmd = [cmds nextObject]) != nil) 
    [cmd takeValue:pkey forKey:@"companyId"];
}

- (void)_runAddressCommandsInContext:(id)_context {
  id<NSObject,LSCommand> cmd;
  NSEnumerator *cmds;
  NSNumber     *pkey;

  pkey = [[self object] valueForKey:[self primaryKeyName]];
  
  [self _prepareNewAddrCmdsInContext:_context];
  cmds = [self->_newAddrCmds objectEnumerator];
  while ((cmd = [cmds nextObject]) != nil) {
    [cmd takeValue:pkey forKey:@"companyId"];
    [cmd runInContext:_context];                  
  }
}

- (void)_runTelephoneCommandsInContext:(id)_context {
  // TODO: a copy of the -_runAddressCommandsInContext!
  id<NSObject,LSCommand> cmd;
  NSEnumerator *cmds;
  NSNumber     *pkey;

  pkey = [[self object] valueForKey:[self primaryKeyName]];

  [self _prepareNewTelephoneCmdsInContext:_context];
  
  cmds = [self->_newTelephoneCmds objectEnumerator];
  while ((cmd = [cmds nextObject]) != nil) {
    [cmd takeValue:pkey forKey:@"companyId"];
    [cmd runInContext:_context];                  
  }
}  
  
- (void)_newCompanyInfoInContext:(id)_context {
  id           company;
  NSNumber     *pkey;
  EOEntity     *infoEntity;
  id           info;
  NSDictionary *pk;
  
  company    = [self object];
  pkey       = [company valueForKey:[self primaryKeyName]];
  infoEntity = [[self databaseModel] entityNamed:@"CompanyInfo"];

  pk   = [self newPrimaryKeyDictForContext:_context keyName:@"companyInfoId"];
  info = [self produceEmptyEOWithPrimaryKey:pk entity:infoEntity];
  
  [info takeValue:[pk valueForKey:@"companyInfoId"] forKey:@"companyInfoId"];
  [info takeValue:pkey        forKey:@"companyId"];
  [info takeValue:@"inserted" forKey:@"dbStatus"];  
  
  if (self->comment != nil) 
    [info takeValue:self->comment forKey:@"comment"];

  [self assert:[[self databaseChannel] insertObject:info]
        reason:[dbMessages description]];
}

- (id)_newCompanyValue:(NSString *)_key value:(id)_value
  companyId:(NSNumber *)_pkey accountId:(NSNumber *)_uid
  type:(int)_type label:(NSString *)_label
  inContext:(id)_context
{
  if (_type  == 0)   _type  = 1;
  if (_label == nil) _label = (id)null;
  
  return LSRunCommandV(_context,
		       @"companyvalue", @"new",
		       @"companyId", _pkey,
		       @"attribute", _key,
		       @"uid",       _uid,
		       @"label",     _label,
		       @"type",      [NSNumber numberWithInt:_type],
		       @"value",     _value, nil);
}

- (void)_newExtendedAttributesInContext:(id)_context {
  // TODO: see below, this might be broken
  NSNumber       *accountId   = nil;
  id              obj;
  NSEnumerator   *keyEnum;
  NSMutableDictionary *map;
  NSMutableArray *compValues;
  NSMutableArray *excludeKeys = nil;
  id              key         = nil;
  
  obj         = [self object];
  keyEnum     = [[self->defaultAttrs allKeys] objectEnumerator];
  map         = [NSMutableDictionary dictionaryWithCapacity:16];
  compValues  = [NSMutableArray arrayWithCapacity:8];
  
  accountId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  excludeKeys = 
    [NSMutableArray arrayWithArray:[[obj entity] classPropertyNames]];
  
  [excludeKeys addObjectsFromArray:defExcludeKeys];
  
  while ((key = [keyEnum nextObject]) != nil) {
    NSDictionary *attr;
    int           type;
    NSString     *label;
    id            userId;
    id            compValue = nil;
    
    if ([excludeKeys containsObject:key])
      continue;

    // TODO: this doesn't make a lot of sense to me? The 'object' is the
    //       newly created company EO which can't contain a value for an
    //       extended attribute?! Maybe this is just a moron copy of the set
    //       command?
    //       Note: but it _does_ seem to work (just using extattrs as
    //             additional command arguments)
    if ([obj valueForKey:key] == nil)
      continue;
    
    attr   = [self->defaultAttrs objectForKey:key];
    type   = [[attr valueForKey:@"type"] intValue];
    label  = [attr valueForKey:@"label"];
    userId = null;
      
    if ([[attr objectForKey:@"isPrivate"] boolValue])
      userId = accountId;

    compValue = [self _newCompanyValue:key value:[obj valueForKey:key]
		      companyId:[obj valueForKey:@"companyId"] accountId:userId
		      type:type label:label inContext:_context];
    [map setObject:attr forKey:key];
    [compValues addObject:compValue];
  }
  [obj takeValue:map        forKey:@"attributeMap"];
  [obj takeValue:compValues forKey:@"companyValue"];
}

- (void)_newTelephoneCommandsInContext:(id)_context {
  NSNumber *pkey;
  unsigned i, cnt;
  
  pkey = [[self object] valueForKey:[self primaryKeyName]];
  for (i = 0, cnt = [self->telephones count]; i < cnt; i++) {
    id<NSObject,LSCommand> cmd;
    id tel;
    
    tel = [self->telephones objectAtIndex:i];
    cmd = LSLookupCommand(@"telephone", @"new");
    
    [cmd takeValuesFromDictionary:tel];
    [cmd takeValue:pkey forKey:@"companyId"];
    [cmd runInContext:_context];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSString *nr = nil;
  NSString *n, *l;
  id obj;
  
  [super _prepareForExecutionInContext:_context];
  
  [self _fetchDefaultExtendedAttributes:_context];
  
  /* if 'login' or 'number' are undefined, set them up */
  
  obj = [self object];
  n   = [self->recordDict valueForKey:@"number"];
  l   = [self->recordDict valueForKey:@"login"];
  
  if ([n isKindOfClass:[NSString class]]) {
    if (![n isNotEmpty])
      n = nil;
  }
  
  if (![n isNotNull]) {
    nr = [[obj valueForKey:[self primaryKeyName]] stringValue];
    nr = [autoNumberPrefix stringByAppendingString:nr];
    [obj takeValue:nr forKey:@"number"];
  }
  if (![l isNotNull]) { 
    nr = [[obj valueForKey:[self primaryKeyName]] stringValue];
    nr = [autoLoginPrefix stringByAppendingString:nr];
    [obj takeValue:nr forKey:@"login"];
  }
  
  /* setup some default values */
  
  [obj takeValue:[NSNumber numberWithInt:1] forKey:@"objectVersion"];
  
  /* set initial owner if not provider by command callsite */
  
  if (![[obj valueForKey:@"ownerId"] isNotNull]) {
    [obj takeValue:
           [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"]
	 forKey:@"ownerId"];
  }
}

- (void)_saveAttachmentInContext:(id)_context {
  NSFileManager  *manager;
  NSUserDefaults *defaults;
  id             obj;
  NSString       *fileName;
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

      if ([manager fileExistsAtPath:fName]) {
        [manager removeFileAtPath:fName handler:nil];        
      }
      fName = [fileName stringByAppendingPathExtension:@"gif"];

      if ([manager fileExistsAtPath:fName]) {
        [manager removeFileAtPath:fName handler:nil];        
      }
  }

  if (self->pictureData !=nil && self->pictureFilePath != nil &&
        [self->pictureData isNotEmpty]) {
      fName = [fileName stringByAppendingPathExtension:
                        [self->pictureFilePath pathExtension]];
      isOk  = [self->pictureData writeToFile:fName atomically:YES];

      [self assert:isOk
            reason:@"Error during save of person/enterprise picture!"];
  }
}

- (void)_addCreationLogInContext:(id)_context {
  LSRunCommandV(_context, @"object", @"add-log",
                @"logText"    , [self valueForKey:@"logText"],
                @"action"     , [self valueForKey:@"logAction"],
                @"objectToLog", [self object],
                nil);
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  [self _newCompanyInfoInContext:_context];
  [self _checkAndPrepareAddedCommands];
  [self _newExtendedAttributesInContext:_context];
  [self _runAddressCommandsInContext:_context];
  
  if (self->telephones == nil)
    [self _runTelephoneCommandsInContext:_context];
  else
    [self _newTelephoneCommandsInContext:_context];
  
  [self _saveAttachmentInContext:_context];
  [self _addCreationLogInContext:_context];
  [self calculateCTagInContext:_context];
}

/* initialize records */

- (NSString *)entityName {
  return @"Company";
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

/* defaults */

- (void)_fetchDefaultExtendedAttributes:(id)_context {
  NSMutableDictionary *attrs;
  
  attrs = [self _getDefaults:@"Public" with:_context];
  [attrs addEntriesFromDictionary:
	   [self _getDefaults:@"Private" with:_context]];
  ASSIGN(self->defaultAttrs, attrs);
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
    
    result = [NSMutableDictionary dictionaryWithCapacity:8];
    attrEnum = [[defs arrayForKey:key] objectEnumerator];
    while ((attr = [attrEnum nextObject])) {
      NSString *key;
      
      key = [attr objectForKey:@"key"];
      [self assert:(key != nil)
	    reason:@"Extended attribute: missing attribute 'key'"];
      
      if (isPrivate) [attr setObject:yesNum forKey:@"isPrivate"];
      [result setObject:attr forKey:[attr objectForKey:@"key"]];
    }
    return result;
  }
}

@end /* LSNewCompanyCommand */
