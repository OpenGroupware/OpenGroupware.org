/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "NGSoapClient.h"
#include <WSDL/WSDL.h>
#include <NGObjWeb/NGObjWeb.h>
#include <SOAP/SOAPWSDLService.h>
#include <SOAP/SOAPWSDLAnalyzer.h>
#include <SOAP/SOAP.h>
#include "SOAPBody+DocumentStyle.h"
#include "common.h"


@interface NGSoapClient(PrivateMethods)
- (BOOL)isSoapDebugging;
- (WORequest *)_requestWithBlock:(SOAPBlock *)_block
                         service:(SOAPWSDLService *)_service;
- (WOHTTPConnection *)_connectionWithServiceName:(NSString *)_serviceName;
- (WSDLDefinitions *)_loadWSDL:(NSString *)_host
                           uri:(NSString *)_uri
                          port:(int)_port;
@end

@interface NSURL(WORequest_uri)
- (NSString *)_uri;
@end

@implementation NGSoapClient

- (id)initWithLocation:(NSString *)_location {
  NSURL *url;
  
  url = [NSURL URLWithString:_location];
  if ([url isFileURL])
    return [self initWithContentsOfFile:[url path]];
  else
    return [self initWithHost:[url host]
                 uri:[url _uri]
                 port:[[url port] intValue]];
}

- (id)initWithContentsOfFile:(NSString *)_file {
  WSDLDefinitions *wsdl;

  wsdl = [[WSDLDefinitions alloc] initWithContentsOfFile:_file];
  AUTORELEASE(wsdl);
  return [self initWithDefinitions:wsdl];
}

- (id)initWithHost:(NSString *)_host uri:(NSString *)_uri port:(int)_port {
  WSDLDefinitions  *wsdl;
  
  wsdl = [self _loadWSDL:_host uri:_uri port:_port];
  return [self initWithDefinitions:wsdl];
}

- (id)initWithDefinitions:(WSDLDefinitions *)_wsdl {
  if ((self = [super init])) {
    SOAPWSDLAnalyzer *analyzer;
    unsigned         cnt;

    analyzer       = [[SOAPWSDLAnalyzer alloc] initWithDefinitions:_wsdl];
    self->services = [[analyzer services] retain];
    cnt            = [self->services count];
    RELEASE(analyzer);
    
    self->serviceName2connection =
      [[NSMutableDictionary alloc] initWithCapacity:cnt+1];
  }
  return self;
}


#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->services);
  RELEASE(self->defaultServiceName);
  RELEASE(self->serviceName2connection);
  [super dealloc];
}
#endif

- (NSArray *)services {
  return self->services;
}

- (SOAPWSDLService *)serviceWithName:(NSString *)_serviceName {
  NSEnumerator    *serviceEnum = [self->services objectEnumerator];
  SOAPWSDLService *service     = nil;
  SOAPWSDLService *result      = nil;
  
  while ((service = [serviceEnum nextObject])) {
    if ([[service name] isEqualToString:_serviceName]) {
      result = service;
      break;
    }
  }
  return result;
}


- (NSString *)defaultServiceName {
  return self->defaultServiceName;
}
- (void)setDefaultServiceName:(NSString *)_defaultServiceName {
  ASSIGNCOPY(self->defaultServiceName, _defaultServiceName);
}

- (id)call {
  return nil;
}

- (id)invokeMethodNamed:(NSString *)_methodName
            serviceName:(NSString *)_serviceName
             parameters:(NSArray *)_params
{
  NSString          *serviceName;
  WOHTTPConnection  *connection;
  SOAPWSDLService   *service;
  SOAPWSDLOperation *operation;
  WORequest         *request;
  WOResponse        *response;
  SOAPBody          *body;
  id                result = nil;

  serviceName = (_serviceName) ? _serviceName : self->defaultServiceName;
  service    = [self serviceWithName:serviceName];
  operation  = [service operationWithName:_methodName];
  connection = [self _connectionWithServiceName:serviceName];

  if (service == nil) {
    return [NSException exceptionWithName:@"NoSuchService"
                        reason:@"wrong service name"
                        userInfo:nil];
  }
  else if (operation == nil) {
    return [NSException exceptionWithName:@"NoSuchOperation"
                        reason:@"wrong operation name"
                        userInfo:nil];
  }
  else if (connection == nil) {
    return [NSException exceptionWithName:@"NoConnection"
                        reason:@"could not to server"
                        userInfo:nil];
  }

  NSLog(@"call %@.%@%@", serviceName, _methodName, _params);
  
  body = [[SOAPBody alloc] init];
  [body setName:_methodName];
  [body setOperation:operation];
  [body setIsRequest:YES];
  if ([operation isRpcStyle])
    [body setValues:_params];
  else
    [body setDocumentValues:_params];

  request = [self _requestWithBlock:body service:service];

  [connection sendRequest:request];
  response = [connection readResponse];

  if ([self isSoapDebugging]) {
    NSString *tmp;
    
    tmp = [[NSString alloc] initWithData:[response content]
                            encoding:[response contentEncoding]];
    NSLog(@"\n%@\n", tmp);
    
    RELEASE(tmp);
  }

  result = [SOAPDecoder parseBlocksFromData:[response content]
                        service:service
                        isRequest:NO];
  
  RELEASE(body);

  result = [result lastObject];
  if ([result fault]) {
    SOAPFault *fault;
    fault = [result fault];
    
    return [NSException exceptionWithName:[fault faultCode]
                        reason:[fault faultString]
                        userInfo:nil];
  }
  else if (![operation isRpcStyle]) {
    return [result valueWithXmlSchema];
  }
  else
    return [[result values] lastObject];
}

@end /* NGSoapClient */


@implementation NGSoapClient(PrivateMethods)

- (BOOL)isSoapDebugging {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"SOAPDebugging"];
}

- (WORequest *)_requestWithBlock:(SOAPBlock *)_block
                         service:(SOAPWSDLService *)_service
{
  SOAPEncoder     *encoder;
  WORequest       *request;
  NSMutableString *str;
  NSURL           *url;
  NSString        *soapAction;

  url        = [NSURL URLWithString:[_service endpoint]];
  soapAction = [[_block operation] soapAction];
  request    = [[WORequest alloc] initWithMethod:@"POST"
                                  uri:[url _uri]
                                  httpVersion:@"HTTP/1.0"
                                  headers:nil
                                  content:nil
                                  userInfo:nil];
  
  [request setHeader:@"text/xml" forKey:@"content-type"];
  [request setHeader:soapAction  forKey:@"SOAPAction"];
  [request setContentEncoding:NSUTF8StringEncoding];
  
  str     = [[NSMutableString alloc] initWithCapacity:512];
  encoder = [[SOAPEncoder alloc] initForWritingWithMutableString:str];
  [encoder encodeEnvelopeWithBlocks:[NSArray arrayWithObject:_block]];

  if ([self isSoapDebugging])
    NSLog(@"request is %@", str);
  
  [request appendContentString:str];

  RELEASE(encoder);
  RELEASE(str);
              
  return AUTORELEASE(request);
}

- (WOHTTPConnection *)_connectionWithServiceName:(NSString *)_serviceName {
  WOHTTPConnection *connection = nil;

  if (_serviceName == nil) return nil;
  connection = [self->serviceName2connection objectForKey:_serviceName];
  
  if (connection == nil) {
    NSString *endpoint = [[self serviceWithName:_serviceName] endpoint];

    if (endpoint) {
      NSURL *url = [NSURL URLWithString:endpoint];
      connection = [[WOHTTPConnection alloc] initWithHost:[url host]
                                             onPort:[[url port] intValue]];
      [self->serviceName2connection setObject:connection forKey:_serviceName];
      RELEASE(connection);
    }
  }
  return connection;
}

- (WSDLDefinitions *)_loadWSDL:(NSString *)_host
                           uri:(NSString *)_uri
                          port:(int)_port
{
  WOHTTPConnection *connection;
  WORequest        *request;
  WOResponse       *response;

  connection = [[WOHTTPConnection alloc] initWithHost:_host
                                         onPort:_port];
  request = [[WORequest alloc] initWithMethod:@"GET"
                               uri:_uri
                               httpVersion:@"HTTP/1.0"
                               headers:nil
                               content:nil
                               userInfo:nil];

  [connection sendRequest:request];
  response = [connection readResponse];

  return [WSDLSaxBuilder parseDefinitionsFromData:[response content]];
}

@end /* NGSoapClient(PrivateMethods) */

@implementation NSURL(WORequest_uri)

- (NSString *)_uri {
  NSMutableString *result;

  result   = [[NSMutableString alloc] initWithString:[self relativePath]];
  if ([self query]) {
    [result appendString:@"?"];
    [result appendString:[self query]];
  }
  return AUTORELEASE(result);
}

@end /* NSURL(WORequest_uri) */
