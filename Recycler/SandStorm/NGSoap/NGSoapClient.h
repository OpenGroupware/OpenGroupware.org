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

#ifndef __NGSOAP_NGSoapClient_H__
#define __NGSOAP_NGSoapClient_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSMutableDictionary;
@class SOAPWSDLService;
@class WSDLDefinitions;

@interface NGSoapClient : NSObject
{
  NSArray             *services;
  NSString            *defaultServiceName;
  NSMutableDictionary *serviceName2connection;
}

- (id)initWithContentsOfFile:(NSString *)_file;
- (id)initWithDefinitions:(WSDLDefinitions *)_wsdl;
- (id)initWithLocation:(NSString *)_location;
- (id)initWithHost:(NSString *)_host uri:(NSString *)_uri port:(int)_port;

- (NSArray *)services;
- (SOAPWSDLService *)serviceWithName:(NSString *)_serviceName;

- (NSString *)defaultServiceName;
- (void)setDefaultServiceName:(NSString *)_defaultServiceName;

// invoke methods
- (id)invokeMethodNamed:(NSString *)_methodName
            serviceName:(NSString *)_serviceName
             parameters:(NSArray *)_params;
@end /* NGSoapClient */

#endif /* __NGSOAP_NGSoapClient_H__ */
