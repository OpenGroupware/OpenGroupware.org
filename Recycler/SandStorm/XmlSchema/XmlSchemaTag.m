
#include "XmlSchemaTag.h"
#include "XmlSchemaType.h"
#include "common.h"

@implementation XmlSchemaTag

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->annotations);
  RELEASE(self->extraAttributes);
  //self->schema is non-retained !!!
  
  [super dealloc];
}
#endif

- (NSString *)description {
  NSMutableString *s;
  
  s = [NSMutableString stringWithFormat:@"<%p[%@]: ",
                         self, NSStringFromClass([self class])];
  [s appendString:@">"];
  return s;
}

- (NSArray *)annotations {
  return self->annotations;
}

- (NSArray *)extraAttributeNames {
  return [self->extraAttributes allKeys];
}

- (NSString *)extraAttributeWithName:(NSString *)_name {
  if (_name == nil)
    return nil;
  return [self->extraAttributes objectForKey:_name];
}

- (XmlSchema *)schema {
  return self->schema;
}

@end /* XmlSchemaTag */

@implementation XmlSchemaTag(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_namespaces {
  if ((self = [super init])) {
    unsigned i, cnt;
    
    self->annotations     = [[NSMutableArray      alloc] initWithCapacity:8];
    self->extraAttributes = [[NSMutableDictionary alloc] initWithCapacity:4];

    cnt = [_attrs count];
    for (i=0; i<cnt; i++) {
      NSString *uri   = [_attrs uriAtIndex:i];

      if (!isXmlSchemaNamespace(uri)) {
        NSString *name  = [_attrs nameAtIndex:i];
        NSString *value = [_attrs valueAtIndex:i];
        NSString *key   = [NSString stringWithFormat:@"{%@}%@", uri, name];
        
        if (key && value)
          [self->extraAttributes setObject:value forKey:key];
      }
    }
  }
  return self;
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  self->schema = _schema;
}

- (NSString *)tagName {
  NSString *str = nil;

  str = NSStringFromClass([self class]);

  if ([str length] > 9) {
    NSString *tmp;

    tmp = [str substringFromIndex:9]; // remove @"XmlSchema"
    str = [[tmp substringToIndex:1] lowercaseString];
    str = [str stringByAppendingString:[tmp substringFromIndex:1]];
  }
  return str;
}

- (BOOL)isTagAccepted:(XmlSchemaTag *)_tag {
  return [self isTagNameAccepted:[_tag tagName]];
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  return [_tagName isEqualToString:@"annotation"];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([[_tag tagName] isEqualToString:@"annotation"]) {
    [self->annotations addObject:_tag];
    return YES;
  }
  NSLog(@"%s: could not add tag (%@)!", __PRETTY_FUNCTION__, _tag);
  return NO;
}


@end /* XmlSchemaTag(XmlSchemaSaxBuilder) */

@implementation XmlSchemaTag(XmlSchemaSaxBuilder_PrivateMethods)

- (BOOL)_shouldPrepare {
  if (self->didPrepare == NO) {
    self->didPrepare = YES;
    return YES;
  }
  return NO;
}
- (BOOL)_insertTag:(XmlSchemaType *)_tag
  intoDict:(NSMutableDictionary *)_dict
  restArray:(NSMutableArray *)_rest
{
  NSString *n;

  n = [_tag name];
  if (n) {
    [_dict setObject:_tag forKey:n];
    return YES;
  }
  else if (_rest && _tag) {
    [_rest addObject:_tag];
    return YES;
  }
  else {
#if 0
    NSLog(@"%s WARNING: attribute name of <%@> is nil!",
          __PRETTY_FUNCTION__, [_tag tagName]);
#endif
    return NO;
  }
}

- (BOOL)_insertTag:(XmlSchemaType *)_tag
          intoDict:(NSMutableDictionary *)_dict
{
  return [self _insertTag:_tag intoDict:_dict restArray:nil];
}

// e.g. "xsd:string" --> "{http://schemas.xmlsoap.org/soap}string"
- (NSString *)_getQNameFrom:(NSString *)_value ns:(NSDictionary *)_ns {
  NSArray  *segs;

  segs  = [_value componentsSeparatedByString:@":"];
  if ([segs count] <= 1)
    return _value;
  else {
    NSString *prefix = [segs objectAtIndex:0];
    NSString *result;
    
    if ((result = [[_ns objectForKey:prefix] lastObject])) {
      NSString *suffix;
      
      segs   = [segs subarrayWithRange:NSMakeRange(1,[segs count] - 1)];
      suffix = [segs componentsJoinedByString:@":"];
      result = [NSString stringWithFormat:@"{%@}", result];
      result = [result stringByAppendingString:suffix];

      return result;
    }
    return _value;
  }
}

- (NSString *)copy:(NSString *)_key
             attrs:(id<SaxAttributes>)_attrs
                ns:(NSDictionary *)_ns
{
  NSString *value;

  value = [_attrs valueForRawName:_key];
  return [[self _getQNameFrom:value ns:_ns] copy];
}

- (void)append:(NSString *)_value
          attr:(NSString *)_attrName
      toString:(NSMutableString *)_str
{
  if (_value) {
    [_str appendString:@" "];
    [_str appendString:_attrName];
    [_str appendString:@"=\""];
    [_str appendString:_value];
    [_str appendString:@"\""];
  }
}

- (void)_prepareTags:(id)_tags withSchema:(XmlSchema *)_schema {
  NSEnumerator *tagEnum;
  XmlSchemaTag *tag;

  tagEnum = [_tags objectEnumerator];
  while ((tag = [tagEnum nextObject])) {
    [tag prepareWithSchema:_schema];
  }
}


@end /* XmlSchemaTag(XmlSchemaSaxBuilder_PrivateMethods) */
