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

#include "common.h"
#import  <Foundation/Foundation.h>
#include <WSDL/WSDL.h>
#include <SOAP/SOAP.h>
#include <NGObjWeb/NGObjWeb.h>

void testSOAPArchiver() {
  WSDLDefinitions *wsdl;
  SOAPEncoder     *encoder;
  SOAPBody        *body;
  NSMutableString *str;
  NSArray         *value;

  str  = @"test/types.wsdl";
  wsdl = [WSDLSaxBuilder parseDefinitionsFromContentsOfFile:str];
  NSLog(@"wsdl is %@", wsdl);

  value = [NSArray arrayWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"duck",               @"name",
                                 @"donald",             @"firstname",
                                 @"kurze beschreibung", @"shortDescription",
                                 @"http://www.wsdl.de", @"wsdlURL",
                                 @"12345",              @"id",
                                 @"pub_id_1",           @"publisherID", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ente",               @"name",
                                 @"daisy",              @"firstname",
                                 @"flotte schnitte",    @"shortDescription",
                                 @"www.daisy.com",      @"wsdlURL",
                                 @"54321",              @"id",
                                 @"pub_id_2",           @"publisherID", nil],
                   nil];
  
  body = [[SOAPBody alloc] initWithName:@"getAllServiceSummaries"];
  [body setOperation:nil]; // toDo: operation has to be generated
  [body addValue:value];

  str     = [[NSMutableString alloc] initWithCapacity:512];
  encoder = [[SOAPEncoder alloc] initForWritingWithMutableString:str];
  [encoder encodeEnvelopeWithBlocks:[NSArray arrayWithObject:body]];

  NSLog(@"\n\n%@", str);
  
  RELEASE(str);
}

void testSOAPDecoder() {
  WSDLDefinitions  *wsdl;
  SOAPDecoder      *encoder;
  SOAPBody         *body;
  NSMutableString  *str;
  NSArray          *blocks;
  SOAPWSDLAnalyzer *analyzer;
  NSArray          *services;

  str  = @"test/types.wsdl";
  wsdl = [WSDLSaxBuilder parseDefinitionsFromContentsOfFile:str];
  NSLog(@"wsdl is %@", wsdl);

  analyzer = [[SOAPWSDLAnalyzer alloc] initWithDefinitions:wsdl];
  services = [analyzer services];
  NSLog(@"services is %@", services);
  RELEASE(analyzer);
  
  str = @"test/fault_response.xml";

  blocks = [SOAPDecoder parseBlocksFromContentsOfFile:str
                        service:nil
                        isRequest:NO];
  
  NSLog(@"blocks is %@", blocks);
}

void testDocumentStyle() {
  WSDLDefinitions   *wsdl;
  SOAPWSDLAnalyzer  *analyzer;
  SOAPWSDLOperation *operation;
  NSArray           *services;
  NSString          *str;
  NSString          *element;
  SOAPBody          *body;
  SOAPEncoder       *encoder;

  str       = @"test/weatherDocumentStyle.wsdl";
  wsdl      = [WSDLSaxBuilder parseDefinitionsFromContentsOfFile:str];
  analyzer  = [[SOAPWSDLAnalyzer alloc] initWithDefinitions:wsdl];
  services  = [analyzer services];
  operation = [[services lastObject] operationWithName:@"GetWeather"];
  NSLog(@"operation.name = '%@'", [operation name]);
  
  body      = [[SOAPBody alloc] initWithName:@"GetWeather"];
  [body setOperation:operation];
  [body setIsRequest:YES];
  [body addValue:
        [NSDictionary dictionaryWithObjectsAndKeys:@"12345", @"ZipCode", nil]];

  str     = [[NSMutableString alloc] initWithCapacity:128];
  encoder = [[SOAPEncoder alloc] initForWritingWithMutableString:str];
  [encoder encodeEnvelopeWithBlocks:[NSArray arrayWithObject:body]];
  NSLog(@"result is %@", str);
  
  RELEASE(encoder);
  RELEASE(str);
  RELEASE(analyzer);
}

/* ******************** main ******************** */

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc
                 environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];
  //testSOAPArchiver();
  // testSOAPDecoder();
  // testDocumentStyle();
  RELEASE(pool);
  return 0;
}
