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

#include "common.h"
#import  <Foundation/Foundation.h>
#include <NGSoap/NGSoapClient.h>
#include <WSDL/WSDL.h>

void testSoapClientWithDocumentStyle() {
  NGSoapClient    *client;
  NSString        *str;
  WSDLDefinitions *wsdl;
  id              result;

  if (NO) {
    str    = @"test/weatherDocumentStyle.wsdl";
    wsdl   = [WSDLSaxBuilder parseDefinitionsFromContentsOfFile:str];
    client = [[NGSoapClient alloc] initWithDefinitions:wsdl];
  }
  else {
    str    = @"http://hosting001.vs.k2unisys.net/Weather/PDCWebService/WeatherServices.asmx?WSDL";
    // str = @"http://ws.cdyne.com/delayedstockquote/delayedstockquote.asmx?wsdl";

    // str = @"http://www.richsolutions.com/RichPayments/RichCardValidator.asmx?WSDL";
    
    client = [[NGSoapClient alloc] initWithLocation:str];
  }
  NSLog(@"services is %@", [[client services] valueForKey:@"name"]);
  NSLog(@"operationNames is %@", [[[client services] lastObject] operationNames]);

  result = [client invokeMethodNamed:@"GetWeather"
                   serviceName:@"WeatherServices"
                   parameters:[NSArray arrayWithObject:@"12345"]];

  NSLog(@"result is %@", result);
  RELEASE(client);
}

/* ******************** main ******************** */

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc
                 environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];
  testSoapClientWithDocumentStyle();
  RELEASE(pool);
  return 0;
}
