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

#include <OGoContacts/SkyAddressDocument.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@implementation SkyAddressDocument(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder])) {
    [self setName1:  [_coder decodeStringForKey:@"name1"]];
    [self setName2:  [_coder decodeStringForKey:@"name2"]];
    [self setName3:  [_coder decodeStringForKey:@"name3"]];
    [self setStreet: [_coder decodeStringForKey:@"street"]];
    [self setZip:    [_coder decodeStringForKey:@"zip"]];
    [self setCity:   [_coder decodeStringForKey:@"city"]];
    [self setCountry:[_coder decodeStringForKey:@"country"]];
    [self setState:  [_coder decodeStringForKey:@"state"]];
    [self setType:   [_coder decodeStringForKey:@"type"]];
  }
  return self;
}

- (void)encodeWithXmlRpcCoder:(id)_coder {
  [super encodeWithXmlRpcCoder:_coder];
  [_coder encodeString:[self name1]   forKey:@"name1"];
  [_coder encodeString:[self name2]   forKey:@"name2"];
  [_coder encodeString:[self name3]   forKey:@"name3"];  
  [_coder encodeString:[self street]  forKey:@"street"];
  [_coder encodeString:[self zip]     forKey:@"zip"];
  [_coder encodeString:[self city]    forKey:@"city"];
  [_coder encodeString:[self country] forKey:@"country"];
  [_coder encodeString:[self state]   forKey:@"state"];
  [_coder encodeString:[self type]    forKey:@"type"];
}

@end /* SkyAddressDocument(XmlRpcCoding) */
