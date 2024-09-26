/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2006-2007 Helge Hess

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

#include "LSWObjectEditor.h"
#include "common.h"

/*
  Example:
  
  AddressEditor : LSWObjectEditor {
    labels     = labels;
    object     = address;
    attributes = (
      { key = "name1";   },
      { key = "name2";   },
      { key = "name3";   },
      { key = "street";  },
      { key = "city";    },
      { key = "zip";     },
      { key = "state";   },
      { key = "country"; }
    );
    prefix = "post"; // -> WOTextField.name = prefix+attribute.key
  }

*/

#define ATTR_TYPECODE_CHECKBOX 2
#define ATTR_TYPECODE_MULTI    9

@implementation LSWObjectEditor

+ (int)version {
  return 3;
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->privateLabel = @"";
  }
  return self;
}

- (void)dealloc {
  [self->namespace    release];
  [self->prefix       release];
  [self->object       release];  
  [self->attributes   release];
  [self->labels       release];
  [self->privateLabel release];
  [self->map          release];
  [self->showOnly     release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  [self->labels       release]; self->labels       = nil;
  [self->attributes   release]; self->attributes   = nil;
  [self->object       release]; self->object       = nil;
  [self->privateLabel release]; self->privateLabel = nil;
  [self->showOnly     release]; self->showOnly     = nil;
  self->attribute  = nil;
  self->currentKey = nil;
  [super syncSleep];
}

/* accessors */

- (void)setObject:(id)_object {
  ASSIGN(self->object, _object);
}
- (id)object {
  return self->object;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  return self->labels;
}

- (void)setPrefix:(NSString *)_prefix {
  ASSIGNCOPY(self->prefix, _prefix);
}
- (NSString *)prefix {
  return self->prefix;
}

- (void)setNamespace:(NSString *)_namespace {
  ASSIGNCOPY(self->namespace, _namespace);
}
- (NSString *)namespace {
  return self->namespace;
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  /*
    If the 'showOnly' binding was set, this filters out unwanted keys. Note
    that this is bad style and should be done in a separate method!
  */
  NSMutableArray *result;
  unsigned count, i;
  
  if (self->showOnly == nil)
    return self->attributes;
  
  result = [NSMutableArray arrayWithCapacity:4];
  count  = [self->attributes count];

  for (i = 0; i < count; i++)  {
    NSDictionary *obj;

    obj = [self->attributes objectAtIndex:i];
    
    if ([self->showOnly containsObject:[obj objectForKey:@"key"]])
      [result addObject:obj];
  }
  return result;
}

- (void)setMap:(NSDictionary *)_map {
  ASSIGN(self->map, _map);
}
- (NSDictionary *)map {
  return self->map;
}

- (void)setPrivateLabel:(NSString *)_label {
  ASSIGNCOPY(self->privateLabel, _label);
}
- (NSString *)privateLabel {
  return self->privateLabel;
}

- (void)setAttributeKeys:(NSArray *)_attributes {
  NSMutableArray *result;
  NSString       *key;
  NSEnumerator   *attrs;
  
  if (_attributes == nil) {
    [self setAttributes:nil];
    return;
  }

  attrs  = [_attributes objectEnumerator];
  result = [[NSMutableArray alloc] initWithCapacity:[_attributes count]];
  
  while ((key = [attrs nextObject]) != nil) {
    static NSString *kkey = @"key";
    NSDictionary *row;
    
    row = [[NSDictionary alloc] initWithObjects:&key forKeys:&kkey count:1];
    [result addObject:row];
    [row release];
  }
  
  [self setAttributes:result];
  [result release];
}
- (NSArray *)attributeKeys {
  NSEnumerator   *attrs;
  NSMutableArray *result;
  NSDictionary   *attr;

  attrs = [[self attributes] objectEnumerator];

  if (attrs == nil)
    return nil;
  
  result = [NSMutableArray arrayWithCapacity:16];
  while ((attr = [attrs nextObject]) != nil) {
    id value;
    
    if ((value = [attr valueForKey:@"key"]) != nil)
      [result addObject:value];
  }
  return result;
}

- (void)setShowOnly:(NSArray *)_attribs {
  ASSIGN(self->showOnly, _attribs);
}
- (NSArray *)showOnly {
  return self->showOnly;
}

- (void)setAttribute:(NSDictionary *)_attribute {
  #if 0 // hh(2024-09-26): WOSimpleRepetition DOES clear the value
  assert(_attribute != nil);
  NSAssert(_attribute != nil, @"no attribute passed ..");
  #endif
  self->attribute  = _attribute;
  self->currentKey = [_attribute valueForKey:@"key"];
  NSAssert(_attribute == nil || self->currentKey != nil, @"no key set ..");
}
- (NSDictionary *)attribute {
  return self->attribute;
}

- (NSArray *)currentValues {
  NSDictionary *values, *dict;
  NSArray      *valueKeys;
  id storedValue;
  
  dict = [self->map isNotNull]
    ? [self->map objectForKey:self->currentKey]
    : (id)self->attribute;
  
  values    = [dict valueForKey:@"values"];
  valueKeys = [dict valueForKey:@"valueKeys"];
  
  if (values != nil) {
    /* also allow arrays in values ... */
    if ([values respondsToSelector:@selector(allKeys)])
      valueKeys = [values allKeys];
    else if ([values isKindOfClass:[NSArray class]])
      valueKeys = (NSArray *)values;
  }
  
  /* when 'valueKeys' is a String, resolve it as a KVC value */
  
  if ([valueKeys isKindOfClass:[NSString class]])
    valueKeys = [self valueForKeyPath:(NSString *)valueKeys];
  
  /* sort results, *before* adding extra values */

  if ([valueKeys respondsToSelector:@selector(sortedArrayUsingSelector:)])
    valueKeys = [valueKeys sortedArrayUsingSelector:@selector(compare:)];
  else {
    [self errorWithFormat:
	    @"expected an array for 'valueKeys', got: %@ (%@), dict: %@",
	    valueKeys, NSStringFromClass([valueKeys class]), dict];
    return nil;
  }
  
  /* ensure that the currently saved value is in the popup */
  
  if ([(storedValue = [self attributeValue]) isNotEmpty]) {
    if ([valueKeys isNotEmpty]) {
      if (![valueKeys containsObject:storedValue]) {
	valueKeys = [[valueKeys mutableCopy] autorelease];

	/* insert value as the first element */
	[(NSMutableArray *)valueKeys insertObject:storedValue atIndex:0];
      }
      // else: contained
    }
    else
      valueKeys = [NSArray arrayWithObjects:&storedValue count:1];
  }
  
  /* return */
  return valueKeys;
}

- (NSString *)currentLabel {
  NSDictionary *values, *dict;
  NSArray      *valueKeys;

  dict = ([self->map isNotNull])
    ? [self->map objectForKey:self->currentKey]
    : (id)self->attribute;
  
  values    = [dict valueForKey:@"values"];
  valueKeys = [dict valueForKey:@"valueKeys"];

  if (values != nil)
    return [values valueForKey:self->item];
  
  if (valueKeys != nil) {
    BOOL isLocalized;
    
    isLocalized = [[dict valueForKey:@"isLocalized"] boolValue];

    if (isLocalized && (self->labels != nil))
      return [self->labels valueForKey:[self->item stringValue]];
  }
  return self->item;
}

- (NSString *)_encodeMultiValue:(NSArray *)_value {
  NSString *string;
  
  if ([_value count] == 0)
    return @"";
  
  string = [_value componentsJoinedByString:@","];
  // TODO: perform escaping of ","
  return string;
}
- (NSArray *)_decodeMultiValue:(NSString *)_value {
  NSArray *components;

  if ([_value length] == 0)
    return [NSArray array];
  
  components = [_value componentsSeparatedByString:@","];
  // TODO: perform unescaping of encoded ","
  return components;
}

/* attribute value accessors */

- (void)setAttributeRawValue:(id)_value {
  NSString *k;
  
  k = self->currentKey;
  if ([self->namespace isNotEmpty]) {
    k = [[NSString alloc] initWithFormat:@"{%@}%@", self->namespace, k];
    [self->object takeValue:_value forKey:k];
    [k release];
  }
  else
    [self->object takeValue:_value forKey:k];
}
- (id)attributeRawValue {
  NSString *k;
  
  k = self->currentKey;
  if ([self->namespace isNotEmpty])
    k = [NSString stringWithFormat:@"{%@}%@", self->namespace, k];
  return [self->object valueForKey:k];
}

- (void)setAttributeValue:(id)_value {
  id           value;
  NSString     *calendarFormat;
  NSDictionary *dict;
  
  // TODO: check for multi, return array
  if ([self currentTypeCode] == ATTR_TYPECODE_MULTI) {
    //[self logWithFormat:@"WARNING: should set multi value: %@", _value];
    if ([_value isKindOfClass:[NSArray class]])
      _value = [self _encodeMultiValue:_value];
  }

  dict = ([self->map isNotNull])
    ? [self->map objectForKey:self->currentKey]
    : (id)self->attribute;
  
  value          = _value;
  calendarFormat = [dict valueForKey:@"calendarFormat"];
  
  if ((calendarFormat != nil) && ([value isNotNull])) {
    NSString *time, *tz;

    time = [dict valueForKey:@"time"];
    tz   = [[(id)[self session] timeZone] abbreviation];
    
    if (time != nil) {
      calendarFormat =
        [calendarFormat stringByAppendingString:@" %H:%M:%S %Z"];
      
      value = [NSString stringWithFormat:@"%@ %@ %@", value, time, tz];
    }
    else {
      calendarFormat = [calendarFormat stringByAppendingString:@" %Z"];
      value          = [NSString stringWithFormat:@"%@ GMT", value];      
    }
    value = [NSCalendarDate dateWithString:value
                            calendarFormat:calendarFormat];
    if (value == nil) {
      // TODO: document!
      [self performParentAction:[dict objectForKey:@"couldNotFormat"]];
    }
  }
  else if (value == nil)
    value = [EONull null];
  
  NSAssert(self->currentKey, @"no key set ..");
  if (value != nil)
    [self setAttributeRawValue:value];
}

- (id)attributeValue {
  id       value;
  NSString *calendarFormat;
  NSDictionary *dict;

  NSAssert(self->currentKey, @"no key set ..");
  
  /* retrieve raw value */
  
  value = [self attributeRawValue];
  
  // TODO: check for multi, return array
  if ([self currentTypeCode] == ATTR_TYPECODE_MULTI) {
    if (![value isNotNull])
      return nil;
    if ([value isKindOfClass:[NSArray class]])
      return value;
    
    return [self _decodeMultiValue:[value stringValue]];
  }
  
  /* processing mapping */
  
  dict = ([self->map isNotNull])
    ? [self->map objectForKey:self->currentKey]
    : (id)self->attribute;
  
  calendarFormat = [dict valueForKey:@"calendarFormat"];

  if ((calendarFormat != nil) && (value != nil) && ([value isNotNull]))
    value = [value descriptionWithCalendarFormat:calendarFormat];
  
  if (![value isNotNull])
    value = [dict valueForKey:@"nilString"];

  return value;
}

- (void)setIsValueChecked:(BOOL)_flag {
  [self setAttributeRawValue:(_flag ? @"YES" : @"NO")];
}
- (BOOL)isValueChecked {
  id value;
  
  value = [self attributeRawValue];
  if (![value isNotNull]) return NO;
  return [value isEqualToString:@"YES"]; // TODO: better use -boolValue?
}

/* attribute label */

- (NSString *)attributeLabel {
  id            value;
  NSDictionary  *attr;
  NSString      *label, *private;

  attr = ([self->map isNotNull])
    ? [self->map objectForKey:self->currentKey]
    : (id)self->attribute;
  private = @"";
  
  if (![(value = [attr objectForKey:@"label"]) isNotNull]) {
    if ((value = [self->attribute valueForKey:@"label"]) == nil) {
      value = [self->attribute valueForKey:@"key"];
      
      /* strip namespace names */
      if ([(NSString *)value xmlIsFQN])
	value = [value xmlLocalName];
    }
  }
  
  label = self->labels ? [self->labels valueForKey:value] : value;
  
  if ([[attr valueForKey:@"isPrivate"] boolValue] &&
      [self->privateLabel length] > 0)
    private = [NSString stringWithFormat:@" (%@)",self->privateLabel];
  
  return label
    ? [label stringByAppendingString:private]
    : [value stringByAppendingString:private];
}

- (id)textFieldName {
  NSString *tmp;
  
  tmp = [self valueForKey:@"prefix"];
  
  return (tmp != nil)
    ? [tmp stringByAppendingString:[self->attribute valueForKey:@"key"]]
    : (NSString *)[self->attribute valueForKey:@"key"];
}

/* conditions */

- (BOOL)isEnumAttribute {
  NSDictionary *dict;
  
  if (self->currentKey == nil)
    return NO;
    
  dict = [self->map isNotNull]
    ? [self->map objectForKey:self->currentKey]
    : (id)self->attribute;

  if ([dict valueForKey:@"valueKeys"] != nil)
    return YES;
  if ([dict valueForKey:@"values"] != nil)
    return YES;
  
  return NO;
}

- (int)currentTypeCode {
  id attr;
  
  attr = self->attribute;
  if ([[self->map allKeys] containsObject:self->currentKey])
    attr = [self->map objectForKey:self->currentKey];
  
  return [[attr valueForKey:@"type"] intValue];
}
- (BOOL)isTextField {
  return [self currentTypeCode] == ATTR_TYPECODE_CHECKBOX ? NO : YES;
}

- (NSString *)fieldType {
  switch ([self currentTypeCode]) {
  case ATTR_TYPECODE_CHECKBOX: return @"checkbox";
  case ATTR_TYPECODE_MULTI:    return @"multi";
  }
  
  if ([self isEnumAttribute])
    return @"enum";
  
  return @"string";
}

- (void)setColVal:(int)_i {
  self->colVal = _i;
}
- (int)colVal {
  return self->colVal;
}

- (void)setColAttr:(int)_i {
  self->colAttr = _i;
}
- (int)colAttr {
  return self->colAttr;
}

- (int)colspanA {
  return self->colAttr > 0 ? self->colAttr : 1;
}
- (int)colspanV { // TODO: explain this
  return self->colVal > 0 ? self->colVal : 1;
}

@end /* LSWObjectEditor */
