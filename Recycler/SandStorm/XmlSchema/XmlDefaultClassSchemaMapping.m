
#include "XmlDefaultClassSchemaMapping.h"
#include "XmlSchemaType.h"
#include "XmlSchemaAttribute.h"
#include "XmlSchemaElement.h"
#include "NSString+XML.h"
#include "common.h"

@interface NSObject(XmlDefaultClassSchemaMapping)
- (id)_initWithBaseValue:(NSString *)_baseValue type:(XmlSchemaType *)_type;
@end

@interface NSData(Misc)
- (NSData *)dataByDecodingBase64;
@end

@interface NSDate(Misc)
- (id)initWithString:(NSString *)_string calendarFormat:(NSString *)_format;
@end

@interface NSObject(Misc)
- (id)initWithString:(NSString *)_string;
@end

@interface XmlDefaultClassSchemaMapping(PrivateMethods)
+ (NSString *)_realKeyFromKey:(NSString *)_key;
@end

@implementation XmlDefaultClassSchemaMapping : XmlSchemaMapping

- (void)dealloc {
  [self->classPrefix release];
  [super dealloc];
}

static NSDictionary *TypeToClassName = nil;

+ (void)initialize {
  if (TypeToClassName == nil) {
#warning the namespace is missing here?!
    TypeToClassName = [[NSDictionary alloc]
                                     initWithObjectsAndKeys:
                                     @"NSNumber",       @"int",
                                     @"NSNumber",       @"double",
                                     @"NSNumber",       @"float",
                                     @"NSNumber",       @"long",
                                     @"NSNumber",       @"short",
                                     @"NSNumber",       @"byte",
                                     @"NSNumber",       @"boolean",
                                     @"NSNumber",       @"nonNegativeInteger",
                                     @"NSNumber",       @"decimal",
                                     @"NSNumber",       @"integer",
                                     @"NSNumber",       @"nonPositiveInteger",
                                     @"NSNumber",       @"negativeInteger",
                                     @"NSNumber",       @"unsignedLong",
                                     @"NSNumber",       @"unsignedInt",
                                     @"NSNumber",       @"unsignedShort",
                                     @"NSNumber",       @"unsignedByte",
                                     @"NSNumber",       @"positiveInteger",
                                     @"NSString",       @"string",
                                     @"NSData",         @"base64",
                                     @"NSCalendarDate", @"dateTime",
                                     nil];
  }
}

+ (NSString *)nameFromElement:(XmlSchemaElement *)_element {
  NSString *str = [_element name];

  str = [self _realKeyFromKey:str];
  
  if (![_element isScalar]) {
    if ([str hasSuffix:@"s"])
      str = [str stringByAppendingString:@"es"];
    else if ([str hasSuffix:@"y"]) {
      str = [str substringToIndex:[str length] - 1];
      str = [str stringByAppendingString:@"ies"];
    }
    else
      str =  [str stringByAppendingString:@"s"];
  }
  return str;
}

- (void)setClassPrefix:(NSString *)_classPrefix {
  ASSIGNCOPY(self->classPrefix, _classPrefix);
}
- (NSString *)classPrefix {
  return self->classPrefix;
}

- (Class)defaultClassForType:(XmlSchemaType *)_type {
  Class clazz = Nil;
  
  if ([_type isSimpleType])
    clazz = NSClassFromString(@"NSString");
  else if (_type)
    clazz = NSClassFromString(@"NSMutableDictionary");
  return clazz;
}

- (Class)classForType:(XmlSchemaType *)_type {
  Class    clazz      = Nil;
  NSString *className = nil;
  
  if (_type == nil) {
    NSLog(@"WARNING: passed nil-type to %s ...", __PRETTY_FUNCTION__);
    return nil;
  }

  if ((className = [_type typeValue])) {
    if ( [TypeToClassName objectForKey:className])
      className = [TypeToClassName objectForKey:className];
    else if (self->classPrefix)
      className = [self->classPrefix stringByAppendingString:className];
  }
  
  clazz = (className) ? NGClassFromString(className) : Nil;
  if (clazz == Nil) {
    NSLog(@"Warning(%s): could not find class %@.",
          __PRETTY_FUNCTION__,
          className);
    clazz = [self defaultClassForType:_type];
  }
  return clazz;
}

- (NSString *)nameFromElement:(XmlSchemaElement *)_element {
  return [XmlDefaultClassSchemaMapping nameFromElement:_element];
}

- (XmlSchemaType *)typeFromType:(XmlSchemaType *)_type name:(NSString *)_name {
  return [_type elementWithName:_name];
}

/* callback API for coder */

- (id)valueForElement:(XmlSchemaElement *)_element
  inObject:(id)_object
{
  return [_object valueForKey:[self nameFromElement:_element]];
}

- (id)valueForOptionalElement:(XmlSchemaElement *)_element
  inObject:(id)_object
{
  return [self valueForElement:_element inObject:_object];
}

- (NSString *)valueForAttribute:(XmlSchemaAttribute *)_attribute
  inObject:(id)_object
{
  return [[_object valueForKey:[_attribute name]] description];
}

- (NSString *)baseValueOfObject:(id)_object {
  return [_object description];
}

- (id)objectWithBaseValue:(NSString *)_baseValue
  type:(XmlSchemaType *)_type
  object:(id)_object
{
  id result;

  result = [_object _initWithBaseValue:_baseValue type:_type];
  return AUTORELEASE(result);
}

- (void)takeValue:(id)_value
  forElement:(XmlSchemaElement *)_element
  inObject:(id)_object
{
  NSString *key;

  key = [self nameFromElement:_element];
  if (key)
    [_object takeValue:_value forKey:key];
  else
    NSLog(@"Warning(%s): try to take value %@ for nil key in object %@.",
          __PRETTY_FUNCTION__,
          _value,
          _object);
}

- (void)takeValue:(id)_value
  forAttribute:(XmlSchemaAttribute *)_attribute
  inObject:(id)_object
{
  NSString *key;
  
  key = [_attribute name];
  
  if (key)
    [_object takeValue:_value forKey:key];
  else
    NSLog(@"Warning(%s): try to take value %@ for nil key in object %@.",
          __PRETTY_FUNCTION__,
          _value,
          _object);
}

@end /* XmlDefaultClassSchemaMapping */

@implementation XmlDefaultClassSchemaMapping(PrivateMethods)

+ (NSArray *)_forbiddenKeys {
  static NSArray *forbiddenKeys = nil;

  if (forbiddenKeys == nil) {
    forbiddenKeys = [NSArray allocWithZone:[self zone]];
    forbiddenKeys = [forbiddenKeys initWithObjects:
                                   @"id",
                                   @"default",
                                   @"case",
                                   @"switch",
                                   @"for",
                                   @"while",
                                   @"continue",
                                   @"do",
                                   @"int",
                                   @"double",
                                   @"float",
                                   @"char",
                                   @"byte",
                                   @"nil",
                                   nil];
  }
  return forbiddenKeys;
}

+ (NSString *)_realKeyFromKey:(NSString *)_key {
  NSString   *key  = nil;
  NSArray    *keys = [self _forbiddenKeys];
  unsigned   i, j, len;
  char       *buf;
  const char *cString;

  len     = [_key cStringLength];
  cString = [_key cString];
  buf     = malloc((len + 1) * sizeof(const char));
  
  for (i = 0, j = 0; i < len; i++) {
    unsigned char chr = cString[i];
    
    switch(chr) {
      case ' ':
      case '-':
      case '/':
      case '*':
      case '.':
      case '\\':
        chr = '_';
    }
    buf[j++] = chr;
  }
  buf[j] = '\0';

  key = [NSString stringWithCString:buf];
  
  free(buf);
  
  if ([keys containsObject:key])
    return [@"_" stringByAppendingString:key];
  else
    return key;
}

@end /* XmlDefaultClassSchemaMapping(PrivateMethods) */

@implementation NSObject(XmlDefaultClassSchemaMapping)

- (id)_initWithBaseValue:(NSString *)_baseValue type:(XmlSchemaType *)_type {
  if ([self respondsToSelector:@selector(initWithString:)])
    return [self initWithString:_baseValue];
  else
    return [self init];
}

@end /* NSObject(XmlDefaultClassSchemaMapping) */

@implementation NSData(XmlDefaultClassSchemaMapping)

/* NSData represents the base type 'base64' */

- (id)_initWithBaseValue:(NSString *)_baseValue type:(XmlSchemaType *)_type {
  RELEASE(self); self = nil;
  
  self = [_baseValue dataUsingEncoding:NSUTF8StringEncoding];

  if ([[_type typeValue] isEqualToString:@"base64"])
    self = [self dataByDecodingBase64];
  
  return [self copy];
}

@end /* NSData(XmlDefaultClassSchemaMapping) */

@implementation NSDate(XmlDefaultClassSchemaMapping)

- (id)_initWithBaseValue:(NSString *)_baseValue type:(XmlSchemaType *)_type {
  /* eg 1998-07-17T14:08:55+0100 */
  if ([_baseValue length] < 24) {
    RELEASE(self);
    return nil;
  }

  if (![self isKindOfClass:[NSCalendarDate class]]) {
    RELEASE(self);
    self = [NSCalendarDate alloc];
  }
  /*
    ToDo: - time zones
          - other date type, like <date>, <month>, ...
   */
  return [self initWithString:_baseValue calendarFormat:@"%Y-%m-%dT%H:%M:%S"];
}

@end /* NSDate(XmlDefaultClassSchemaMapping) */

@implementation NSNumber(XmlDefaultClassSchemaMapping)

/* NSNumber represents the types: 'int', 'double', 'boolean': */

- (id)_initWithBaseValue:(NSString *)_baseValue type:(XmlSchemaType *)_type {
  NSString *type = [_type typeValue];
  
  if ([type isEqualToString:@"boolean"]) {
    BOOL v;
      
    v = ([_baseValue isEqualToString:@"true"]) ? YES : NO;
    return [self initWithBool:v];
  }
  else {
    BOOL isInt = NO;
    
    if ([type isEqualToString:@"int"])
      isInt = YES;
    else if ([type isEqualToString:@"double"] ||
             [type isEqualToString:@"float"])
      isInt = NO;
    else
      isInt = ([_baseValue indexOfString:@"."] == NSNotFound) ? YES : NO;
    
    return isInt
      ? [self initWithInt:[_baseValue intValue]]
      : [self initWithDouble:[_baseValue doubleValue]];
  }
}

@end /* NSNumber(XmlDefaultClassSchemaMapping) */
