
#include "XmlSchemaAttribute.h"
#include "common.h"

@implementation XmlSchemaAttribute

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->defValue);
  RELEASE(self->fixed);
  RELEASE(self->form);
  RELEASE(self->idValue);
  RELEASE(self->name);
  RELEASE(self->ref);
  RELEASE(self->type);
  RELEASE(self->use);
  
  [super dealloc];
}
#endif

- (NSString *)default {
  return self->defValue;
}
- (NSString *)fixed {
  return self->fixed;
}
- (NSString *)form {
  return self->form;
}
- (NSString *)id {
  return self->idValue;
}
- (NSString *)name {
  return self->name;
}
- (NSString *)ref {
  return self->ref;
}
- (NSString *)type {
  return self->type;
}
- (NSString *)use {
  return self->use;
}

@end /* XmlSchemaAttribute */

@implementation XmlSchemaAttribute(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->defValue = [[_attrs valueForRawName:@"default"] copy];
    self->fixed    = [[_attrs valueForRawName:@"fixed"]   copy];
    self->form     = [[_attrs valueForRawName:@"form"]    copy];
    self->idValue  = [[_attrs valueForRawName:@"id"]      copy];
    self->name     = [[_attrs valueForRawName:@"name"]    copy];
    self->use      = [[_attrs valueForRawName:@"use"]     copy];
    
    self->ref      = [self copy:@"ref"  attrs:_attrs ns:_ns];
    self->type     = [self copy:@"type" attrs:_attrs ns:_ns];
  }
  return self;
}


- (NSString *)tagName {
  return @"attribute";
}

@end /* XmlSchemaAttribute(XmlSchemaSaxBuilder) */
