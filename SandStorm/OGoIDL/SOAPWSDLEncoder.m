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

#include "SOAPWSDLEncoder.h"
#include <OGoIDL/SkyIDL.h>
#include <XmlSchema/XmlSchema.h>
#include <XmlSchema/NSString+XML.h>
#include "common.h"

@interface SOAPWSDLEncoder(PrivateMethods)
- (void)_appendSchema:(SkyIDLInterface *)_interface;
- (void)_appendMessages:(SkyIDLInterface *)_interface;
- (void)_appendPortTypes:(SkyIDLInterface *)_interface;
- (void)_appendBinding:(SkyIDLInterface *)_interface;
- (void)_appendService;

- (NSString *)_portTypeName;
- (NSString *)_portName;
- (NSString *)_bindingName;

- (NSString *)_targetNamespacePrefix;
- (NSString *)_soapNamespacePrefix;

- (void)_appendPrefix:(NSString *)_prefix;
- (void)_appendPrefix:(NSString *)_prefix ns:(NSString *)_ns;
@end /* SOAPWSDLEncoder(PrivateMethods) */

@interface SOAPWSDLEncoder(RPC_STYLE)
- (NSString *)_typeOfPart:(SkyIDLInput *)_part; // returns a qname
- (void)_appendSchemaAsRpcStyle:(SkyIDLInterface *)_interface;
@end /* SOAPWSDLEncoder(RPC_STYLE) */

@interface SOAPWSDLEncoder(DOCUMENT_STYLE)
- (void)_appendSchemaAsDocumentStyle:(SkyIDLInterface *)_interface;
@end /* SOAPWSDLEncoder(DOCUMENT_STYLE) */


@implementation SOAPWSDLEncoder

- (id)initForWritingWithMutableString:(NSString *)_string {
  if ((self = [super init])) {
    self->string     = [_string retain];
    self->isRpcStyle = YES;
    self->isEncoded  = YES;
    self->location   = @"http://inster.in.skyrix.com:20000/";
    // ASSIGNCOPY(self->location, @"http://localhost:3333/");
  }
  return self;
}

- (void)dealloc {
  [self->string   release];
  [self->location release];
  [super dealloc];
}

/* *** encoding *** */
- (void)encodeInterface:(SkyIDLInterface *)_interface {
  if (_interface == nil) return;

  [self->string appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
  [self->string appendString:
       @"<definitions xmlns:http=\"http://schemas.xmlsoap.org/wsdl/http/\"\n"
       @"   xmlns:s=\"http://www.w3.org/2001/XMLSchema\"\n"
       @"   xmlns:mime=\"http://schemas.xmlsoap.org/wsdl/mime/\"\n"
       @"   xmlns:soap=\"http://schemas.xmlsoap.org/wsdl/soap/\"\n"
       @"   xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\"\n"
       @"   xmlns:wsdl=\"http://schemas.xmlsoap.org/wsdl/\"\n"
       @"   xmlns=\"http://schemas.xmlsoap.org/wsdl/\"\n"]; 

  [self->string appendString:@"   targetNamespace=\""];
  [self->string appendString:[self targetNamespace]];
  [self->string appendString:@"\"\n"];

  [self->string appendString:@"   name=\""];
  [self->string appendString:[self serviceName]];
  [self->string appendString:@"\"\n"];

  [self->string appendString:@"   "];
  [self _appendPrefix:[self _targetNamespacePrefix] ns:[self targetNamespace]];
  
  [self->string appendString:@">\n"];
  [self->string appendString:@"\n"];

  [self _appendSchema:_interface];
  [self _appendMessages:_interface];
  [self _appendPortTypes:_interface];
  [self _appendBinding:_interface];
  [self _appendService];
  
  [self->string appendString:@"</definitions>"];
}

/* configuration */

- (void)setIsRpcStyle:(BOOL)_flag {
  self->isRpcStyle = _flag;
}

- (void)setIsEncoded:(BOOL)_flag {
  self->isEncoded = _flag;
}

- (void)setServiceLocation:(NSString *)_location {
  ASSIGNCOPY(self->location, _location);
}

/* *************************************** */

- (NSString *)targetNamespace {
  return @"http://tempuri.org/";
}

- (NSString *)serviceName {
  return @"Service1";
}

- (NSString *)use {
  return self->isEncoded ? @"encoded" : @"literal";
}

- (NSString *)style {
  return self->isRpcStyle ? @"rpc" : @"document";
}

- (NSString *)serviceLocation {
  return self->location;
}

- (NSString *)encodingStyle {
  return @"http://schemas.xmlsoap.org/soap/encoding/";
}

- (NSString *)namespace {
  return @"urn:test-namespace";
}

- (NSString *)soapAction {
  return @"";
}

- (NSString *)transport {
  return @"http://schemas.xmlsoap.org/soap/http";
}
  
@end /* SOAPWSDLEncoder */

@implementation SOAPWSDLEncoder(PrivateMethods)

- (void)_writePartAsRpcStyle:(SkyIDLInput *)_part {
  NSString *type   = nil;
  NSString *prefix = nil;
  NSString *uri    = nil;

  type = [self _typeOfPart:_part];
  uri  = [type uriFromQName];
  type = [type valueFromQName];

  if (uri != nil)
    prefix = @"s1";
  
  [self->string appendString:@"    <part name=\""];
  [self->string appendString:[_part name]];
  [self->string appendString:@"\""];
  [self->string appendString:@" type=\""];
  [self _appendPrefix:prefix];
  [self->string appendString:type];
  [self->string appendString:@"\" "];
  if (prefix) [self _appendPrefix:prefix ns:uri];
  [self->string appendString:@"/>\n"];
}

- (void)_writeMessageNamed:(NSString *)_name parts:(NSArray *)_parts {
  NSEnumerator *partEnum = [_parts objectEnumerator];
  SkyIDLInput  *part     = nil;
  
  [self->string appendString:@"  <message name=\""];
  [self->string appendString:_name];
  [self->string appendString:@"\">\n"];

  if (self->isRpcStyle) {
    while ((part = [partEnum nextObject])) {
      [self _writePartAsRpcStyle:part];
    }
  }
  else {
    [self->string appendString:@"    <part name=\"parameters\" "];
    [self->string appendString:@"element=\""];
    [self _appendPrefix:[self _targetNamespacePrefix]];
    [self->string appendString:_name];
    [self->string appendString:@"\"/>\n"];
  }
  
  [self->string appendString:@"  </message>\n"];
}

- (void)_writeOperation:(SkyIDLMethod *)_method {
  NSString *name;

  name = [_method name];
  [self->string appendString:@"    <operation name=\""];
  [self->string appendString:name];
  [self->string appendString:@"\">\n"];

  [self->string appendString:@"      <input message=\""];
  [self _appendPrefix:[self _targetNamespacePrefix]];
  [self->string appendString:name];
  [self->string appendString:@"\""];
  [self->string appendString:@">"];
  [self->string appendString:@"</input>\n"];

  [self->string appendString:@"      <output message=\""];
  [self _appendPrefix:[self _targetNamespacePrefix]];
  [self->string appendString:[name stringByAppendingString:@"Response"]];
  [self->string appendString:@"\""];
  [self->string appendString:@">"];
  [self->string appendString:@"</output>\n"];
         
  [self->string appendString:@"    </operation>\n"];
}

- (void)_appendSchema:(SkyIDLInterface *)_interface {
  if (self->isRpcStyle)
    [self _appendSchemaAsRpcStyle:_interface];
  else
    [self _appendSchemaAsDocumentStyle:_interface];
}

- (void)_appendMessages:(SkyIDLInterface *)_interface {
  NSEnumerator *nameEnum;
  NSString     *name;

  nameEnum = [[_interface methodNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    SkyIDLMethod    *method    = [_interface methodWithName:name];
    NSEnumerator    *sigEnum   = [[method signatures] objectEnumerator];
    SkyIDLSignature *signature = nil;

    while ((signature = [sigEnum nextObject])) {
      [self _writeMessageNamed:name parts:[signature inputs]];
      name = [name stringByAppendingString:@"Response"];
      [self _writeMessageNamed:name parts:[signature outputs]];
    }
  }
  [self->string appendString:@"\n"];
}

- (void)_appendPortTypes:(SkyIDLInterface *)_interface {
  NSEnumerator *nameEnum = [[_interface methodNames] objectEnumerator];
  NSString     *name;

  [self->string appendString:@"  <portType name=\""];
  [self->string appendString:[self _portTypeName]];
  [self->string appendString:@"\">\n"];

  while ((name = [nameEnum nextObject])) {
    [self _writeOperation:[_interface methodWithName:name]];
  }
  
  [self->string appendString:@"  </portType>\n"];
  [self->string appendString:@"\n"];
}

- (void)_writeSoapBody {
  [self->string appendString:@"        <"];
  [self _appendPrefix:[self _soapNamespacePrefix]];
  [self->string appendString:@"body"];
  
  [self->string appendString:@" use=\""];
  [self->string appendString:[self use]];
  [self->string appendString:@"\""];
  
  [self->string appendString:@" encodingStyle=\""];
  [self->string appendString:[self encodingStyle]];
  [self->string appendString:@"\""];
  
  [self->string appendString:@" namespace=\""];
  [self->string appendString:[self namespace]];
  [self->string appendString:@"\""];
  
  [self->string appendString:@"/>\n"];
}

- (void)_writeSoapOperation:(SkyIDLMethod *)_method {
  NSString *name;

  name = [_method name];
  [self->string appendString:@"    <operation name=\""];
  [self->string appendString:name];
  [self->string appendString:@"\""];
  [self->string appendString:@">\n"];
  
  [self->string appendString:@"      <"];
  [self _appendPrefix:[self _soapNamespacePrefix]];
  [self->string appendString:@"operation"];
  [self->string appendString:@" soapAction=\""];
  [self->string appendString:[self soapAction]];
  [self->string appendString:@"\""];
  [self->string appendString:@" style=\""];
  [self->string appendString:[self style]];
  [self->string appendString:@"\""];
  [self->string appendString:@"/>\n"];

  [self->string appendString:@"      <input>\n"];
  [self _writeSoapBody];
  [self->string appendString:@"      </input>\n"];

  [self->string appendString:@"      <output>\n"];
  [self _writeSoapBody];
  [self->string appendString:@"      </output>\n"];
  [self->string appendString:@"    </operation>\n"];
}

- (void)_appendBinding:(SkyIDLInterface *)_interface {
  NSEnumerator *nameEnum;
  NSString     *name;

  [self->string appendString:@"  <binding name=\""];
  [self->string appendString:[self _bindingName]];
  [self->string appendString:@"\""];
  [self->string appendString:@" type=\""];
  [self _appendPrefix:[self _targetNamespacePrefix]];
  [self->string appendString:[self _portTypeName]];
  [self->string appendString:@"\""];
  [self->string appendString:@">\n"];

  [self->string appendString:@"<soap:binding"];
  [self->string appendString:@" style=\""];
  [self->string appendString:[self style]];
  [self->string appendString:@"\""];

  [self->string appendString:@" transport=\""];
  [self->string appendString:[self transport]];
  [self->string appendString:@"\""];
  [self->string appendString:@"/>\n"];

  nameEnum = [[_interface methodNames] objectEnumerator];
  while (( name = [nameEnum nextObject])) {
    [self _writeSoapOperation:[_interface methodWithName:name]];
  }

  [self->string appendString:@"  </binding>\n"];
  [self->string appendString:@"\n"];
}

- (void)_appendService {
  [self->string appendString:@"  <service name=\""];
  [self->string appendString:[self serviceName]];
  [self->string appendString:@"\">\n"];

  [self->string appendString:@"    <port name=\""];
  [self->string appendString:[self _portName]];
  [self->string appendString:@"\""];
  [self->string appendString:@" binding=\""];
  [self _appendPrefix:[self _targetNamespacePrefix]];
  [self->string appendString:[self _bindingName]];
  [self->string appendString:@"\""];
  [self->string appendString:@">\n"];

  [self->string appendString:@"      <"];
  [self _appendPrefix:[self _soapNamespacePrefix]];
  [self->string appendString:@"address"];
  [self->string appendString:@" location=\""];
  [self->string appendString:[self serviceLocation]];
  [self->string appendString:@"\""];
  [self->string appendString:@"/>\n"];
  
  [self->string appendString:@"    </port>\n"];

  [self->string appendString:@"  </service>\n"];
  [self->string appendString:@"\n"];
}

/* configuration */
- (NSString *)_portTypeName {
  return [[self serviceName] stringByAppendingString:@"PortType"];
}

- (NSString *)_portName {
  return [[self serviceName] stringByAppendingString:@"Port"];
}

- (NSString *)_bindingName {
  return [[self serviceName] stringByAppendingString:@"Binding"];
}

- (NSString *)_targetNamespacePrefix {
  return @"tns";
}
- (NSString *)_soapNamespacePrefix {
  return @"soap";
}

- (void)_appendPrefix:(NSString *)_prefix {
  if (_prefix) {
    [self->string appendString:_prefix];
    [self->string appendString:@":"];
  }
}

- (void)_appendPrefix:(NSString *)_prefix ns:(NSString *)_ns {
  if (_prefix && _ns) {
    [self->string appendString:@"xmlns:"];
    [self->string appendString:_prefix];
    [self->string appendString:@"=\""];
    [self->string appendString:_ns];
    [self->string appendString:@"\""];
  }
}

@end /* SOAPWSDLEncoder(PrivateMethodes) */


@implementation SOAPWSDLEncoder(RPC_STYLE)

- (NSString *)_typeOfPart:(SkyIDLInput *)_part {
  NSEnumerator *nameEnum = [[_part extraAttributeNames] objectEnumerator];
  NSString     *name     = nil;
  
  while ((name = [nameEnum nextObject])) {
    NSString *value = nil;
    
    if ([@"http://schemas.xmlsoap.org/soap/encoding/"
          isEqualToString:[name uriFromQName]])
      continue;

    value = [name valueFromQName];
      
    if ([value isEqualToString:@"type"])
      return [_part extraAttributeWithName:name];
    else if ([value isEqualToString:@"arrayType"]) {
      NSString *type  = nil;
      NSString *uri   = nil;
      NSString *value = nil;
      
      type  = [_part extraAttributeWithName:name];
      uri   = [type uriFromQName];
      value = [type valueFromQName];
      type  = [NSString stringWithFormat:@"{%@}ArrayOf%@", uri, value];
      
      return type;
    }
  }
  return [_part type];
}

- (void)_addTypesFromParts:(NSArray *)_parts into:(NSMutableArray *)_result {
  NSEnumerator *partEnum = [_parts objectEnumerator];
  SkyIDLInput  *part;

  while ((part = [partEnum nextObject])) {
    NSString *type  = [self _typeOfPart:part];
    NSString *value = [type valueFromQName];
    NSString *uri   = [type uriFromQName];
      
    NSLog(@"type is %@", type);

    if (![_result containsObject:type])
      [_result addObject:type];

    if ([value hasPrefix:@"ArrayOf"]) {
      value = [value substringFromIndex:7];
      type  = [NSString stringWithFormat:@"{%@}%@", uri, value];
      if (![_result containsObject:type])
        [_result addObject:type];
    }
  }
}

// array of qname, e.g. ({http://www.skyrix.com/Person.xsd}Person, ...)
- (NSArray *)_schemaTypes:(SkyIDLInterface *)_interface {
  NSMutableArray *result   = nil;
  NSEnumerator   *nameEnum = [[_interface methodNames] objectEnumerator];
  NSString       *name;

  result = [[NSMutableArray alloc] initWithCapacity:8];
  
  while ((name = [nameEnum nextObject])) {
    NSEnumerator    *sigEnum = nil;
    SkyIDLSignature *sig;

    sigEnum = [[[_interface methodWithName:name] signatures] objectEnumerator];
    
    while ((sig = [sigEnum nextObject])) {
      [self _addTypesFromParts:[sig inputs]  into:result];
      [self _addTypesFromParts:[sig outputs] into:result];
    }
  }
  return AUTORELEASE(result);
}

// group types depending on namespace
- (NSDictionary *)_typeDict:(SkyIDLInterface *)_interface {
  NSEnumerator        *typeEnum = nil;
  NSMutableDictionary *typeDict = nil;
  id                  type;

  typeEnum = [[self _schemaTypes:_interface] objectEnumerator];
  typeDict = [[NSMutableDictionary alloc] initWithCapacity:4];
  while ((type = [typeEnum nextObject])) {
    NSString       *uri   = [type uriFromQName];
    NSMutableArray *types = nil;

    if (uri == nil) continue;
    types = [typeDict objectForKey:uri];
    if (types == nil) {
      types = [NSMutableArray arrayWithCapacity:4];
      [typeDict setObject:types forKey:uri];
    }
    [types addObject:type];
  }
  return (NSDictionary *)AUTORELEASE(typeDict);
}

- (void)_appendSchemaAsRpcStyle:(SkyIDLInterface *)_interface {
  NSDictionary *typeDict = [self _typeDict:_interface];
  NSEnumerator *uriEnum  = [typeDict keyEnumerator];
  NSString     *uri      = nil;
    
  [self->string appendString:@"  <types>\n"];
  while ((uri = [uriEnum nextObject])) {
    NSEnumerator *typeEnum = [[typeDict objectForKey:uri] objectEnumerator];
    XmlSchema    *schema;
    NSString     *type;

    schema = [XmlSchema schemaForNamespace:uri];
      
    [self->string appendString:
         @"    <schema xmlns=\"http://www.w3.org/2001/XMLSchema\""
         @" xmlns:tns=\""];
    [self->string appendString:uri];
    [self->string appendString:@"\" targetNamespace=\""];
    [self->string appendString:uri];
    [self->string appendString:@"\">\n"];
      
    while ((type = [typeEnum nextObject])) {
      NSString  *value = [type valueFromQName];


      if ([value hasPrefix:@"ArrayOf"]) {
        [self->string appendString:@"      <complexType name=\""];
        [self->string appendString:value];
        [self->string appendString:
             @"\">\n"
             @"        <complexContent>\n"
             @"          <restriction base=\"soapenc:Array\">\n"
             @"            <attribute ref=\"soapenc:arrayType\""
             @" wsdl:arrayType=\"tns:"];
        value = [value substringFromIndex:7];
        [self->string appendString:value];
        [self->string appendString:
             @"[]\"/>\n"
             @"          </restriction>\n"
             @"        </complexContent>\n"
             @"      </complexType>\n"];
      }
      else {
        XmlSchemaType *type = [schema typeWithName:value];

        [self->string appendString:[type description]];
      }
    }
    [self->string appendString:@"    </schema>\n"];
  }
  [self->string appendString:@"  </types>\n"];
}

@end /* SOAPWSDLEncoder(RPC_STYLE) */



@implementation SOAPWSDLEncoder(DOCUMENT_STYLE)

- (void)_appendSchemaMessageParts:(NSArray *)_parts {
  unsigned i, cnt;

  cnt = [_parts count];

  if (cnt == 0) {
    [self->string appendString:@"        <s:complexType />\n"];
  }
  else {
    [self->string appendString:@"        <s:complexType>\n"];
    [self->string appendString:@"          <s:sequence>\n"];

    for (i=0; i<cnt; i++) {
      SkyIDLInput *part   = [_parts objectAtIndex:i];
      NSString    *prefix = nil;
      NSString    *type   = nil;
      NSString    *uri    = nil;

      type = [part type];
      uri  = [type uriFromQName];
      type = [type valueFromQName];

      if (uri != nil)
        prefix = @"s1";

      [self->string appendString:@"            <s:element name=\""];
      [self->string appendString:[part name]];
      [self->string appendString:@"\" type=\""];
      [self _appendPrefix:prefix];
      [self->string appendString:type];
      [self->string appendString:@"\" "];
      if (prefix) [self _appendPrefix:prefix ns:uri];
      [self->string appendString:@"/>\n"];
    }
    [self->string appendString:@"          </s:sequence>\n"];
    [self->string appendString:@"        </s:complexType>\n"];
  }
}

- (void)_appendSchemaMessage:(SkyIDLMethod *)_method {
  NSArray  *signatures;
  NSString *name;
  unsigned i, cnt;

  signatures = [_method signatures];
  cnt        = [signatures count];
  name       = [_method name];

  for (i=0; i<cnt; i++) {
    SkyIDLSignature *signature = [signatures objectAtIndex:i];
    
    [self->string appendString:@"      <s:element name=\""];
    [self->string appendString:name];
    [self->string appendString:@"\">\n"];
    [self _appendSchemaMessageParts:[signature inputs]];
    [self->string appendString:@"      </s:element>\n"];

    [self->string appendString:@"      <s:element name=\""];
    [self->string appendString:[name stringByAppendingString:@"Response"]];
    [self->string appendString:@"\">\n"];
    [self _appendSchemaMessageParts:[signature outputs]];
    [self->string appendString:@"      </s:element>\n"];
  }
}

- (void)_appendSchemaAsDocumentStyle:(SkyIDLInterface *)_interface {
  NSEnumerator *nameEnum;
  NSString     *name;

  [self->string appendString:@"  <types>\n"];
  [self->string appendString:@"    <s:schema"];
  [self->string appendString:@" elementFormDefault=\"qualified\""];
  [self->string appendString:@" attributeFormDefault=\"qualified\""];
  [self->string appendString:@" targetNamespace=\""];
  [self->string appendString:[self targetNamespace]];
  [self->string appendString:@"\">\n"];

  nameEnum = [[_interface methodNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    [self _appendSchemaMessage:[_interface methodWithName:name]];
  }

  [self->string appendString:@"    </s:schema>\n"];
  [self->string appendString:@"  </types>\n"];
}

@end /* SOAPWSDLEncoder(DOCUMENT_STYLE) */
