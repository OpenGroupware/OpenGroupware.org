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

#include "LSBuildConverterDataCommand.h"
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
  [self->type release];
  [self->kind release];
  [self->ids release];
  [self->objectList release];
  [self->labels release];
  [self->entityName release];
  [self->returnKind release];
  [super dealloc];
}

// command methods

- (void)_executeInContext:(id)_ctx {
  id data = nil;

  NSAssert((self->ids != nil), @"no ids set");
  
  [self _prepareForIdsInCtx:_ctx];

  if ([self->type isEqualToString:@"vCard"])
    data = [self _createVCardDataInCtx:_ctx];
  else if ([self->type isEqualToString:@"formLetter"])
    data = [self _createFormLetterDataInCtx:_ctx];
  else {
    [self logWithFormat:@"WARNING: Unknown type! Can not convert address!"];
    data = [NSData data];
  }
  if (self->returnKind != nil) {
    if ([self->returnKind isEqualToString:@"NSString"]) {
      data = [[[NSString alloc] initWithData:data
                                encoding:[NSString defaultCStringEncoding]]
                         autorelease];
    }
    else if (![self->returnKind isEqualToString:@"NSData"]) {
      [self logWithFormat:
            @"WARNING: Unknown returnKind / expected NSString/NSData"];
    }
  }
  [self setReturnValue:data];
}

- (void)_prepareForIdsInCtx:(id)_ctx {
  [self assert:(self->ids != nil) reason:@"enter _prepareForIds without ids"];

  if (self->objectList != nil) {
    [self->objectList release]; self->objectList = nil;
  }
  if ([self->ids count] > 0) {
    self->objectList = LSRunCommandV(_ctx, @"address", @"fetchAttributes",
                                     @"searchKeys", self->ids,
                                     @"entityName", self->entityName, nil);
    self->objectList = [self->objectList retain];
  }
  return;  
}

- (NSData *)_createVCardDataInCtx:(id)_ctx {
  NSMutableString *res       = nil;
  NSDictionary    *defaults  = nil;
  NSArray         *keyList   = nil;
  NSEnumerator    *keyEnum   = nil;
  NSDictionary    *vCardKeys = nil;
  NSString        *key       = nil;

  if (self->objectList == nil) {
    [self logWithFormat:@"WARNING: Address is not set. Can't create vCard."];
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

- (NSData *)_createFormLetterDataInCtx:(id)_ctx {
  NSString *objType = nil;
  NSString *key     = nil;
  NSArray  *fields  = nil;
  id tmp;
  
  if ([self->objectList count] == 0)
    return [NSData data];

  tmp = [(NSDictionary *)[self->objectList objectAtIndex:0] 
                         objectForKey:@"object"];
  if ((objType = [[tmp entity] name]) == nil)
    objType = self->entityName;
  
  key    = [[NSString alloc] initWithFormat:@"LS%@FormLetter", objType];
  fields = [[(NSUserDefaults *)[_ctx valueForKey:LSUserDefaultsKey] 
                               dictionaryForKey:key]
             objectForKey:self->kind];
  [key release]; key = nil;
  
  if (fields == nil) {
    [self logWithFormat:@"WARNING: unknown FormLetter format!"];
    return [NSData data];
  }
  
  {
    NSMutableString *result  = nil;
    NSEnumerator    *objEnum = nil;
    id              obj      = nil;
    NSData          *data    = nil;

    result  = [[NSMutableString allocWithZone:[self zone]]
                                initWithCapacity:
                                [self->objectList count] * 128];
    objEnum = [self->objectList objectEnumerator];

    while ((obj = [objEnum nextObject])) {
      NSEnumerator *fieldEnum;
      NSDictionary *field;
      
      fieldEnum = [fields objectEnumerator];
      while ((field = [fieldEnum nextObject])) {
        NSString *strObj;
        
        strObj = [self _getObj:obj forKey:[field objectForKey:@"key"]];
        strObj = [strObj isNotNull] ? [strObj stringValue] : nil;
        
        [result appendString:[field objectForKey:@"prefix"]];
        [result appendString:strObj];
        [result appendString:[field objectForKey:@"suffix"]];
      }
    }
    data = [result dataUsingEncoding:[NSString defaultCStringEncoding]];
    [result release]; result = nil;
    return data;
  }
}

- (NSString *)_getVCardValueForKey:(NSString *)_key
  keys:(NSDictionary *)_keys
{
  NSString *value;

  value = [self _getObj:[self->objectList lastObject] forKey:_key];

  return ([value length] > 0)
    ? [[_keys objectForKey:_key] stringByAppendingString:value]
    : @"";
}


- (NSString *)_getObj:(id)_obj forKey:(NSString *)_key {
  NSArray      *keys    = nil;
  NSEnumerator *keyEnum = nil;
  id           result   = nil;
  id           key      = nil;

  keys    = [_key componentsSeparatedByString:@"."];
  keyEnum = [keys objectEnumerator];
  result  = _obj;

  if (self->ids == nil) {
    id obj = nil;

    if ((obj = [keys objectAtIndex:0]) == nil)
      return @"";
    
    if (![(NSString *)obj hasPrefix:@"to"])
      result = [result valueForKey:@"object"];
  }
  
  while ((key = [keyEnum nextObject])) {
    result = [result valueForKey:key];

    if ((result != nil) && ([key isEqualToString:@"salutation"])) {
      result = [self->labels valueForKey:result];
    }
  }
  if (![result isNotNull])
    return @"";
  else if ([result isKindOfClass:[NSCalendarDate class]])
    return [result descriptionWithCalendarFormat:@"%Y-%m-%d"];
  else if ([result respondsToSelector:@selector(stringValue)])
    return [result stringValue];
  else 
    return [result description];
}

- (void)_validateInContext:(id)_context {
  [super _validateInContext:_context];
}

// accessors

- (void)setType:(NSString *)_type {
  ASSIGN(self->type, _type);
}
- (NSString *)type {
  return self->type;
}

- (void)setKind:(NSString *)_kind {
  ASSIGN(self->kind, _kind);
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
  ASSIGN(self->entityName, _name);
}
- (NSString *)entityName {
  return self->entityName;
}

- (void)setReturnKind:(NSString *)_kind {
  ASSIGN(self->returnKind, _kind);
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
  return [super valueForKey:_key];
}

@end /* LSBuildConverterDataCommand */
