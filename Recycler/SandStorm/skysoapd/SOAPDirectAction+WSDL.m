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

#include "SOAPDirectAction+WSDL.h"
#include <SOAP/SOAP.h>
#include <WSDL/WSDL.h>
#include <SkyIDL/SkyIDL.h>
#include "common.h"

@implementation SOAPDirectAction(WSDL)

static NSMutableDictionary *key2services = nil; // key -> services
static NSMutableDictionary *key2wsdlstr  = nil; // key -> wsdl (string)

- (NSString *)cacheKey {
  return NSStringFromClass([self class]);
}

- (void)registerWsdlAtPath:(NSString *)_path {
  SOAPWSDLEncoder  *encoder     = nil;
  WSDLDefinitions  *definitions = nil;
  SOAPWSDLAnalyzer *analyzer    = nil;
  NSArray          *services    = nil;
  NSString         *str         = nil;
  NSString         *key         = nil;

  key = [self cacheKey];

  if ([key2services objectForKey:key]) return;

  if (key2services == nil)
    key2services = [[NSMutableDictionary alloc] initWithCapacity:32];
  if (key2wsdlstr == nil)
    key2wsdlstr = [[NSMutableDictionary alloc] initWithCapacity:32];

  str = [NSString stringWithContentsOfFile:_path];

  if ([str length] > 0) {
    NSData *data  = [str dataUsingEncoding:NSUTF8StringEncoding];
    definitions = [WSDLSaxBuilder parseDefinitionsFromData:data];
  }

  analyzer = [[SOAPWSDLAnalyzer alloc] initWithDefinitions:definitions];
  services = [analyzer services];
  
  if ([services count] > 0) {
    [key2services setObject:services forKey:key];
    [key2wsdlstr  setObject:str      forKey:key];
  }
  RELEASE(analyzer);
  RELEASE(encoder);
}

- (void)registerInterfaceAtPath:(NSString *)_path {
  SOAPWSDLEncoder  *encoder     = nil;
  SkyIDLInterface  *interface   = nil;
  WSDLDefinitions  *definitions = nil;
  SOAPWSDLAnalyzer *analyzer    = nil;
  NSArray          *services    = nil;
  NSMutableString  *str         = nil;
  NSString         *key         = nil;

  key = [self cacheKey];

  if ([key2services objectForKey:key]) return;

  if (key2services == nil)
    key2services = [[NSMutableDictionary alloc] initWithCapacity:32];
  if (key2wsdlstr == nil)
    key2wsdlstr = [[NSMutableDictionary alloc] initWithCapacity:32];

  interface = [SkyIDLSaxBuilder parseInterfaceFromContentsOfFile:_path];
  str       = [NSMutableString stringWithCapacity:512];
  encoder   = [[SOAPWSDLEncoder alloc] initForWritingWithMutableString:str];
  [encoder encodeInterface:interface];
  
  if ([str length] > 0) {
    NSData *data  = [str dataUsingEncoding:NSUTF8StringEncoding];
    definitions = [WSDLSaxBuilder parseDefinitionsFromData:data];
  }

  analyzer = [[SOAPWSDLAnalyzer alloc] initWithDefinitions:definitions];
  services = [analyzer services];

  if (services) {
    [key2services setObject:services forKey:key];
    [key2wsdlstr  setObject:str      forKey:key];
  }
  RELEASE(analyzer);
  RELEASE(encoder);
}

- (NSString *)wsdlString {
  return [key2wsdlstr objectForKey:[self cacheKey]];
}

- (NSArray *)services {
  return [key2services objectForKey:[self cacheKey]];
}

@end /* SOAPDirectAction(WSDL) */
