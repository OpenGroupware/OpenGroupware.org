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
#include <NGSoap/NGSoapClient.h>
#include <SOAP/SOAPWSDLService.h>

/* ******************** main ******************** */

void run(NSString *_location) {
  NGSoapClient    *client  = nil;
  SOAPWSDLService *service = nil;
  NSArray         *params  = nil;
  id              result   = nil;

  client  = [[NGSoapClient alloc] initWithLocation:_location];
  service = [[client services] lastObject];

  params = [NSArray arrayWithObjects:@"belgium", @"uk", nil];
  result = [client invokeMethodNamed:[[service operationNames] lastObject]
                    serviceName:[service name]
                    parameters:params];
  
  NSLog(@"result is %@", result);

  // NSLog(@"service name is %@", [service name]);
  // NSLog(@"client operation is %@", [service operationNames]);
  
  RELEASE(client);
}

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc
                 environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];

  // run(@"http://www.xmethods.net/sd/2001/TemperatureService.wsdl");
  run(@"http://www.xmethods.net/sd/2001/CurrencyExchangeService.wsdl"); 
  // run(@"http://www.xmethods.net/sd/2001/EBayWatcherService.wsdl");
  // run(@"http://www.xmethods.net/sd/2001/XMethodsFilesystemService.wsdl");
  // run(@"http://www.alanbushtrust.org.uk/soap/compositions.wsdl");
  
  RELEASE(pool);
  return 0;
}
