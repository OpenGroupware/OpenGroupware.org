/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "LSWObjectViewer.h"
#include "common.h"
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/LSWMailEditorComponent.h>

@implementation LSWObjectViewer

+ (int)version {
  return 4;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
	    @"invalid superclass (%@) version %i !",
	    NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  if ((self = [super init])) {
    NGBundleManager *bm;
  
    bm = [NGBundleManager defaultBundleManager];
    if ([bm bundleProvidingResource:@"LSWImapMailEditor"
            ofType:@"WOComponents"] != nil)
      self->isMailAvailable = YES;
    
    self->nullString   = @"";
    self->privateLabel = @"";
    self->hideEmpty    = NO;
    
    self->markArchivedObjects = NO;
  }
  return self;
}

- (void)dealloc {
  [self->object         release];
  [self->attributes     release];
  [self->attributeColor release];
  [self->valueColor     release];
  [self->nullString     release];
  [self->labels         release];
  [self->privateLabel   release];
  [self->attributesMap  release];
  [self->mapItem        release];
  [super dealloc];
}

/* finals */

static inline id _getAttrValue(LSWObjectViewer *self) {
  if (self->object == nil)
    return nil;
  
#if DEBUG
  NSCAssert1(self->object,       @"missing object for %@ ..", self);
  NSCAssert1(self->getValue,     @"missing getValue method for %@ ..", self);
  NSCAssert1(self->attributeKey, @"invalid attribute key in %@ ..", self);
#endif

  return self->getValue(self->object,
                        @selector(valueForKey:), self->attributeKey);
}

- (NSString *)_boolLabelForValue: (NSNumber*)_value {
  NSString *label, *tmp;
  
  label = [_value boolValue] ? @"YES" : @"NO";
  tmp = [self->labels valueForKey:label];
  if ((tmp))
    label = tmp;
  return label;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->isMailAvailable) {
    self->isInternalMailEditor =
      ([[[[self session] userDefaults] objectForKey:@"mail_editor_type"]
                isEqualToString:@"internal"]) ? YES : NO;
  }
}

- (void)syncSleep {
  self->attribute  = nil;
  RELEASE(self->attributes); self->attributes = nil;
  RELEASE(self->object);     self->object     = nil;
  RELEASE(self->labels);     self->labels     = nil;
  [super syncSleep];
}

/* accessors */

- (void)setHideEmpty:(BOOL)_flag {
  self->hideEmpty = _flag;
}
- (BOOL)hideEmpty {
  return self->hideEmpty;
}

- (void)setObject:(id)_object {
  NSDictionary* map = [_object valueForKey:@"attributeMap"];
  ASSIGN(self->object, _object);
  self->getValue = (void*)[self->object methodForSelector:
                               @selector(valueForKey:)];
  self->useMap = (map != nil) ? YES : NO;

  if (self->useMap) // has extended attributes
    [self takeValue:map forKey:@"attributesMap"];
}
- (id)object {
  return self->object;
}

- (void)setRelatedObject:(id)_object {
  self->relatedObject = _object;
}
- (id)relatedObject {
  return self->relatedObject;
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setAttributeKeys:(NSArray *)_attributes {
  if (_attributes == nil) {
    [self setAttributes:nil];
  }
  else {
    NSMutableArray *result;
    NSString *key;
    NSEnumerator *attrs;

    attrs = [_attributes objectEnumerator];

    result = [NSMutableArray arrayWithCapacity:[_attributes count]];
    while ((key = [attrs nextObject]))
      [result addObject:[NSDictionary dictionaryWithObject:key forKey:@"key"]];

    [self setAttributes:result];
  }
}
- (NSArray *)attributeKeys {
  NSEnumerator   *attrs;
  NSMutableArray *result;
  NSDictionary   *attr;

  attrs = [[self attributes] objectEnumerator];

  if (attrs == nil)
    return nil;
  
  result = [NSMutableArray arrayWithCapacity:16];
  while ((attr = [attrs nextObject])) {
    id value;

    if ((value = [attr valueForKey:@"key"]))
      [result addObject:value];
  }
  return result;
}

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  return self->labels;
}

- (void)setAttributeConfig:(NSDictionary *)_attribute {
  NSDictionary *mapI = nil;

  self->attribute    = _attribute;
  self->attributeKey = [_attribute valueForKey:@"key"];
  // is this attribute an extended attribute?
  self->isExtendedAttribute =
    ((self->useMap) &&
     ((mapI = [self->attributesMap valueForKey:self->attributeKey]) != nil)
     ) ? YES : NO;
  
  if (self->isExtendedAttribute)
    [self takeValue:mapI forKey:@"mapItem"];

  self->relKey = [_attribute valueForKey:@"relKey"];
}
- (NSDictionary *)attributeConfig {
  return self->attribute;
}

- (NSDictionary *)attributesMap {
  return self->attributesMap;
}
- (void)setAttributesMap: (NSDictionary*)_map {
  ASSIGN(self->attributesMap, _map);
}

- (NSDictionary *)mapItem {
  return self->mapItem;
}
- (void)setMapItem: (NSDictionary*)_mapItem {
  ASSIGN(self->mapItem, _mapItem);
}

- (BOOL)useMap {
  return self->useMap;
}
- (void)setUseMap: (BOOL)_useMap {
  self->useMap = _useMap;
}

- (NSString*)privateLabel {
  return self->privateLabel;
}
- (void)setPrivateLabel: (NSString*)_privateLabel {
  ASSIGN(self->privateLabel, _privateLabel);
}

- (BOOL)isExtendedAttribute {
  return self->isExtendedAttribute;
}
- (void)setIsExtendedAttribute: (BOOL)_isExtendedAttribute {
  self->isExtendedAttribute = _isExtendedAttribute;
}

- (NSString *)attributeKey {
  return self->attributeKey;
}

- (NSString *)attributeRelKey {
  return self->relKey;
}

- (NSString *)attributeLabel {
  id       value;
  NSString *private = @"";

  /* lookup current label or use key if no label is available */
  /* check if is extendedAttribute */
  
  if ([[self->attribute valueForKey:@"isPrivate"] boolValue] &&
      [self->privateLabel length] > 0)
    private = [NSString stringWithFormat:@" (%@)",self->privateLabel];

  if ((value = [self->attribute valueForKey:@"label"]) == nil) {
    if (self->isExtendedAttribute) {
            
      value = [self->mapItem valueForKey:@"label"];
      if (([value isNotNull]) &&
          (![[self->mapItem valueForKey:@"isLabelLocalized"] boolValue])) {
        return private ? [value stringByAppendingString:private] : value;
      }
    } 
    if (![value isNotNull])
      value = [self->attribute valueForKey:@"key"];
  }
  
  /* check if a label-mapping is supplied, if so, localize the label */

  if (self->labels) {
    id label = [self->labels valueForKey:value];
    // NSLog(@"lookup label %@, got %@", value, label);
    if (label) value = label;
  }
  return private ? [value stringByAppendingString:private] : value;
}

- (void)setDateFormatter:(NSFormatter *)_formatter {
  self->dateFormatter = _formatter;
}
- (NSFormatter *)dateFormatter {
  return self->dateFormatter;
}

- (void)setNumberFormatter:(NSFormatter *)_formatter {
  self->numberFormatter = _formatter;
}
- (NSFormatter *)numberFormatter {
  return self->numberFormatter;
}

- (id)_attributeValue {
  id value;
  id values;

  value = _getAttrValue(self);

  if (![value isNotNull])
    return value;
  
  if (self->relKey != nil)
    value = [value valueForKey:self->relKey];

  if ((values = [self->attribute valueForKey:@"values"])) {
    /* check if localized value mappings were specified */
    NSString *tmp;

    if ((tmp = [values valueForKey:value])) {
      value = tmp;
    }
    else {
      [self logWithFormat:@"WARNING: couldn't map value %@ for attribute %@",
              value, self->attribute];
    }
  }
  else if ((values = [self->attribute valueForKey:@"valueKeys"])) {
    /* check if value label mappings were specified */
    NSString *tmp;
    tmp = [values valueForKey:value];
    if (self->labels)
      tmp = [self->labels valueForKey:tmp ? tmp : value];
    if (tmp) value = tmp;
  }
  /* localizeValue is not longer supported, use isLocalized instead */
  else if ([[self->attribute valueForKey:@"localizeValue"] boolValue] ||
           [[self->attribute valueForKey:@"isLocalized"] boolValue]) {
    /* check if the value is to be localized */
    NSString *tmp = value;
    if (self->labels)
      tmp = [self->labels valueForKey:[value stringValue]];
    if (tmp) value = tmp;
  }
  if (isExtendedAttribute) {
    NSNumber *t;
    
    t = [self->mapItem valueForKey:@"type"];
    if ([t isNotNull]) {
      if ([t intValue] == 2)
        value = [self _boolLabelForValue: value];
    }
  }
  return value;
}

- (id)attributeValue {
  id value;

  value = [self _attributeValue];
  
  if (![value isNotNull]) 
    value = [self->attribute valueForKey:@"nilString"];

  return value;
}

- (NSFormatter *)attributeValueFormatter {
  static Class DateClass = Nil;
  id value = [self attributeValue];

  if (DateClass == Nil)
    DateClass = [NSDate class];

  if (([value isKindOfClass:DateClass]) && (self->dateFormatter != nil))
    return self->dateFormatter;

  if (([value isKindOfClass:[NSNumber class]]) &&
       (self->numberFormatter != nil)) {
    return self->numberFormatter;
  }
  
  return [[self session] formatterForValue:[self attributeValue]];
}

- (NSArray *)arrayAttrList {
  return _getAttrValue(self);
}

- (id)relatedObjectAttrValue {
  return [self->relatedObject valueForKey:self->relKey];
}

- (NSString *)linkAction {
  return [self->attribute valueForKey:@"action"];
}

- (NSString *)linkHref {
  NSString *s;
  
  if (self->isExtendedAttribute) {
    NSNumber *t;
    int type;
    
    t = [self->mapItem valueForKey:@"type"];

    if ([t isNotNull]) {
      type = [t intValue];
      
      if (type == 3) {// email
	s = [[self->mapItem valueForKey:@"value"] stringValue];
	if ([s length] > 0) 
	  s = [@"mailto:" stringByAppendingString:s];
	
	return nil;
      }
      if (type == 4) // default-link
        return [[self->mapItem valueForKey:@"value"] stringValue];
      
      return nil; // type is set, but not a link
    }
  }
  
  if ((s = [self attributeValue]))
    s = [[self->attribute valueForKey:@"href"] stringByAppendingString:s];
  else
    s = [self->attribute valueForKey:@"href"];
  
  return s;
}

- (NSString *)linkImage {
  NSString *img = [self->attribute valueForKey:@"image"];

  return img ? img : @"/missingresource?image";
}

- (NSString *)linkTarget {
  return [self->attribute valueForKey:@"target"];
}

- (id)hrefAttrValue {
  id value = _getAttrValue(self);
  return [value isNotNull] ? value : @"";
}

- (BOOL)isActionLink {
  return ([self linkAction] != nil) ? YES : NO;
}

- (BOOL)isHrefLink {
  return ([self linkHref] != nil) ? YES : NO;
}

- (BOOL)isImageLink {
  return ([self linkImage] != nil) ? YES : NO;
}

- (BOOL)isLinkAttribute {
  return ([self linkAction] != nil ||
          [self->attribute valueForKey:@"href"] != nil) ? YES : NO;
}

- (BOOL)isArrayAttribute {
  static Class ArrayClass = Nil;
  if (ArrayClass == Nil) ArrayClass = [NSArray class];
  return [_getAttrValue(self) isKindOfClass:ArrayClass];
}

- (void)setAttributeColor:(NSString *)_color {
  if (self->attributeColor != _color) {
    RELEASE(self->attributeColor); self->attributeColor = nil;
    self->attributeColor = [_color copyWithZone:[self zone]];
  }
}
- (NSString *)attributeColor {
  id cfg = [self config];
  
  if (self->attributeColor) {
    return [cfg valueForKey:[@"colors_" stringByAppendingString:
				self->attributeColor]];
  }
  return [cfg valueForKey:@"colors_attributeCell"];
}

- (void)setValueColor:(NSString *)_color {
  if (self->valueColor != _color) {
    RELEASE(self->valueColor); self->valueColor = nil;
    self->valueColor = [_color copyWithZone:[self zone]];
  }
}
- (NSString *)valueColor {
  id cfg = [self config];
  
  return self->valueColor
    ? [cfg valueForKey:[@"colors_" stringByAppendingString:self->valueColor]]
    : [cfg valueForKey:@"colors_valueCell"];
}

- (BOOL)isAttributeVisible {
  if (self->hideEmpty) {
    id v = [self _attributeValue];
    
    if (![v isNotNull])
      return NO;

    if ([v respondsToSelector:@selector(cStringLength)]) {
      if ([v cStringLength] == 0)
        return NO;
    }
  }
  return YES;
}

- (void)setNullString:(NSString *)_value {
  NSAssert(_value, @"cannot assign <nil> to nullString");
  if (self->nullString != _value) {
    RELEASE(self->nullString); self->nullString = nil;
    self->nullString = [_value copyWithZone:[self zone]];
  }
}
- (NSString *)nullString {
  return self->nullString;
}

- (id)cellObjectValue {
  return [self isArrayAttribute]
    ? [self relatedObjectAttrValue]
    : [self attributeValue];
}

- (void)setIsInternalMailEditor:(BOOL)_flag {
  self->isInternalMailEditor = _flag;
}
- (BOOL)isInternalMailEditor {
  return self->isInternalMailEditor;
}

// actions

- (id)editObject {
  return [self performParentAction:[self linkAction]];
}

- (id)mailTo {
  id mailEditor;

  mailEditor = [[self application] pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:[self cellObjectValue] type:@"to"];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[self session] navigation] enterPage:(id<LSWContentPage>)mailEditor];
  }
  return nil;
}

- (BOOL)markArchivedObjects {
  return self->markArchivedObjects;
}
- (void)setMarkArchivedObjects:(BOOL)_bool {
  self->markArchivedObjects = _bool;
}

- (BOOL)isDeletedObject {
  BOOL result = NO;
  if (self->markArchivedObjects == YES) {
    id obj = nil;

    if ([self isArrayAttribute]) {
      obj = self->relatedObject;
    }
    else {
      if ([[self attributeConfig] valueForKey:@"relKey"] != nil) {
        obj = [self->object valueForKey:
                   [[self attributeConfig] valueForKey:@"key"]];
      }
    }
    if (obj != nil) {
      result = [[obj valueForKey:@"dbStatus"] isEqualToString:@"archived"];
    }
  }
  return result;
}

@end
