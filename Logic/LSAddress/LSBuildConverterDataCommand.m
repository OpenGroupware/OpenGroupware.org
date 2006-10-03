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

#include <LSFoundation/LSBaseCommand.h>

/*
  address::build-converter-data
  
  TODO: document!
  
  Called by SkyAddressConverterDataSource.
*/

@class NSString, NSArray, NSDictionary;

@interface LSBuildConverterDataCommand : LSBaseCommand
{
  NSString     *type;
  NSString     *kind;
  NSArray      *ids;
  NSArray      *objectList;
  NSDictionary *labels;
  NSString     *entityName;
  NSString     *returnKind;
}

@end

#include "common.h"

@interface LSBuildConverterDataCommand(Private)
- (void)_prepareForIdsInCtx:(id)_ctx;
- (NSData *)_createVCardDataInCtx:(id)_ctx;
- (NSData *)_createFormLetterDataInCtx:(id)_ctx;
- (NSString *)_getVCardValueForKey:(NSString *)_key keys:(NSDictionary *)_keys;
- (NSString *)_getObj:(id)_obj forKey:(NSString *)_key;
@end

@implementation LSBuildConverterDataCommand

- (void)dealloc {
  [self->type       release];
  [self->kind       release];
  [self->ids        release];
  [self->objectList release];
  [self->labels     release];
  [self->entityName release];
  [self->returnKind release];
  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_ctx {
  id data;
  
  /* ids is a set of primary keys */
  NSAssert((self->ids != nil), @"no ids set");
  
  [self _prepareForIdsInCtx:_ctx];

  if ([self->type isEqualToString:@"vCard"])
    data = [self _createVCardDataInCtx:_ctx];
  else if ([self->type isEqualToString:@"formLetter"])
    data = [self _createFormLetterDataInCtx:_ctx];
  else {
    [self warnWithFormat:@"Unknown type! Cannot convert address!"];
    data = [NSData data];
  }
  
  if (self->returnKind != nil) {
    if ([self->returnKind isEqualToString:@"NSString"]) {
      data = [[[NSString alloc] initWithData:data
                                encoding:[NSString defaultCStringEncoding]]
                         autorelease];
    }
    else if (![self->returnKind isEqualToString:@"NSData"]) {
      [self warnWithFormat:
	      @"Unknown returnKind / expected NSString/NSData"];
    }
  }
  [self setReturnValue:data];
}

- (void)_prepareForIdsInCtx:(id)_ctx {
  [self assert:(self->ids != nil) reason:@"enter _prepareForIds without ids"];

  if (self->objectList != nil) {
    [self->objectList release];
    self->objectList = nil;
  }
  
  if ([self->ids isNotEmpty]) {
    self->objectList = LSRunCommandV(_ctx, @"address", @"fetchAttributes",
                                     @"searchKeys", self->ids,
                                     @"entityName", self->entityName, nil);
    self->objectList = [self->objectList retain];
  }
  return;  
}

/* vCard generation */

- (NSData *)_createVCardDataInCtx:(id)_ctx {
  // DEPRECATED: we have special vcard commands
  // TODO: replace with company::get-vcard command
  NSMutableString *res       = nil;
  NSDictionary    *defaults  = nil;
  NSArray         *keyList   = nil;
  NSEnumerator    *keyEnum   = nil;
  NSDictionary    *vCardKeys = nil;
  NSString        *key       = nil;

  if (self->objectList == nil) {
    [self warnWithFormat:@"Address is not set. Cannot create vCard."];
    return [NSData data];
  }
  
  res       = [NSMutableString stringWithCapacity:512];
  defaults  = [(NSUserDefaults *)[_ctx valueForKey:LSUserDefaultsKey]
                                 dictionaryForKey:@"ConverterAttributes"];
  keyList   = [defaults objectForKey:@"LSVCard"];
  keyEnum   = [keyList objectEnumerator];
  vCardKeys = [defaults objectForKey:@"vCardKeys"];

  [self assert:((keyList != nil) && (vCardKeys != nil))
        reason:@"got no LSVCard or vCardKeys"];

  [res appendString:[vCardKeys valueForKey:@"prefix"]];
  
  while ((key = [keyEnum nextObject])) {
    [res appendString:[self _getVCardValueForKey:key keys:vCardKeys]];
  }
  [res appendString:[vCardKeys valueForKey:@"suffix"]];
  return [res dataUsingEncoding:[NSString defaultCStringEncoding]];
}

- (NSString *)_getVCardValueForKey:(NSString *)_key
  keys:(NSDictionary *)_keys
{
  NSString *value;

  value = [self _getObj:[self->objectList lastObject] forKey:_key];

  return [value isNotEmpty]
    ? [[_keys objectForKey:_key] stringByAppendingString:value]
    : (NSString *)@"";
}


/* generate form letter */

- (NSData *)_createFormLetterDataInCtx:(id)_ctx {
  NSString *objType;
  NSString *key;
  NSArray  *fields;
  id tmp;
  
  if (![self->objectList isNotEmpty])
    return [NSData data];
  
  /* extract the entity from the first list object */
  
  tmp = [(NSDictionary *)[self->objectList objectAtIndex:0]
			                   objectForKey:@"object"];
  if ((objType = [[tmp entity] name]) == nil)
    objType = self->entityName;

  /*
    Load the render specification, eg "LSPersonFormLetter". The toplevel is a
    dictionary keyed on the type (eg 'framemaker', 'winword' etc).

    The fields then contains an array of dictionaries which have those keys:
    - key    (eg 'toAddress.name1')
    - suffix (eg \n)
    - prefix
  */
  key    = [[NSString alloc] initWithFormat:@"LS%@FormLetter", objType];
  fields = [[(NSUserDefaults *)[_ctx valueForKey:LSUserDefaultsKey] 
                                     dictionaryForKey:key]
                                     objectForKey:self->kind];
  [key release]; key = nil;
  
  if (fields == nil) {
    [self errorWithFormat:@"unknown FormLetter format: %@ / %@",
	    objType, self->kind];
    return [NSData data];
  }

  /* process specification */
  
  {
    NSMutableString *result;
    NSEnumerator    *objEnum;
    id              obj;
    NSData          *data    = nil;

    result  = [[NSMutableString alloc]
                initWithCapacity:[self->objectList count] * 128];

    /* walk over each object */

    objEnum = [self->objectList objectEnumerator];
    while ((obj = [objEnum nextObject]) != nil) {
      NSEnumerator *fieldEnum;
      NSDictionary *field;

      /* and process the specified fields for each object */
      
      fieldEnum = [fields objectEnumerator];
      while ((field = [fieldEnum nextObject]) != nil) {
        NSString *strObj, *t;
	
        strObj = [self _getObj:obj forKey:[field objectForKey:@"key"]];
        strObj = [strObj isNotNull] ? [strObj stringValue] : (NSString *)nil;
	
	if ([(t = [field objectForKey:@"prefix"]) isNotEmpty])
	  [result appendString:t];
	if (strObj != nil)
	  [result appendString:strObj];
	if ([(t = [field objectForKey:@"suffix"]) isNotEmpty])
	  [result appendString:t];
      }
    }
    
    /* apply charset */
    data = [result dataUsingEncoding:[NSString defaultCStringEncoding]];
    [result release]; result = nil;
    return data;
  }
}


/* get a normalized string representation of some object key */

- (NSString *)_getObj:(id)_obj forKey:(NSString *)_key {
  NSArray      *keys;
  NSEnumerator *keyEnum;
  id           result;
  id           key;

  /* Note: '_obj' is a preprocessed dictionary */
  
  /* split keypathes, eg toAddress.name1 */
  keys   = [_key componentsSeparatedByString:@"."];
  result = _obj;
  
  if (self->ids == nil) {
    // TODO: document when this happens
    id obj = nil;
    
    if ((obj = [keys objectAtIndex:0]) == nil)
      return @"";
    
    if (![(NSString *)obj hasPrefix:@"to"])
      result = [result valueForKey:@"object"];
  }

  /* traverse keypath */
  
  keyEnum = [keys objectEnumerator];
  while ((key = [keyEnum nextObject]) != nil) {
    result = [result valueForKey:key];

    if ((result != nil) && [key isEqualToString:@"salutation"])
      result = [self->labels valueForKey:result];
  }
  
  /* process plain value */

  if (![result isNotNull])
    return @"";
  
  if ([result isKindOfClass:[NSCalendarDate class]])
    return [result descriptionWithCalendarFormat:@"%Y-%m-%d"];
  
  if ([result respondsToSelector:@selector(stringValue)])
    return [result stringValue];
  
  return [result description];
}

- (void)_validateInContext:(id)_context {
  [super _validateInContext:_context];
}

/* accessors */

- (void)setType:(NSString *)_type {
  ASSIGNCOPY(self->type, _type);
}
- (NSString *)type {
  return self->type;
}

- (void)setKind:(NSString *)_kind {
  ASSIGNCOPY(self->kind, _kind);
}
- (NSString *)kind {
  return self->kind;
}

- (void)setIds:(NSArray *)_ids {
  ASSIGN(self->ids, _ids);
}
- (NSArray *)ids {
  return self->ids;
}

- (void)setLabels:(NSDictionary *)_dict {
  ASSIGN(self->labels, _dict);
}
- (NSDictionary *)labels {
  return self->labels;
}

- (void)setEntityName:(NSString *)_name {
  ASSIGNCOPY(self->entityName, _name);
}
- (NSString *)entityName {
  return self->entityName;
}

- (void)setReturnKind:(NSString *)_kind {
  ASSIGNCOPY(self->returnKind, _kind);
}
- (NSString *)returnKind {
  return self->returnKind;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"type"])
    [self setType:_value];
  else if ([_key isEqualToString:@"ids"])
    [self setIds:_value];
  else if ([_key isEqualToString:@"entityName"])
    [self setEntityName:_value];
  else if ([_key isEqualToString:@"labels"])
    [self setLabels:_value];
  else if ([_key isEqualToString:@"kind"])
    [self setKind:_value];
  else if ([_key isEqualToString:@"returnKind"])
    [self setReturnKind:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  // TODO: no get accessors?
  return [super valueForKey:_key];
}

@end /* LSBuildConverterDataCommand */
