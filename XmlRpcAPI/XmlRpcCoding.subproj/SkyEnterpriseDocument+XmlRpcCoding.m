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

#include <OGoContacts/SkyEnterpriseDocument.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@implementation SkyEnterpriseDocument(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder])) {
    [self setNumber:     [_coder decodeStringForKey:@"number"]];
    [self setName:       [_coder decodeStringForKey:@"name"]];
    [self setPriority:   [_coder decodeStringForKey:@"priority"]];
    [self setKeywords:   [_coder decodeStringForKey:@"keywords"]];
    [self setSalutation: [_coder decodeStringForKey:@"salutation"]];
    [self setUrl:        [_coder decodeStringForKey:@"url"]];
    [self setBank:       [_coder decodeStringForKey:@"bank"]];
    [self setBankCode:   [_coder decodeStringForKey:@"bankCode"]];
    [self setAccount:    [_coder decodeStringForKey:@"account"]];
    [self setEmail:      [_coder decodeStringForKey:@"email"]];
  }
  return self;
}

- (void)encodeWithXmlRpcCoder:(id)_coder {
  [super encodeWithXmlRpcCoder:_coder];
  [_coder encodeString:[self number]     forKey:@"number"];
  [_coder encodeString:[self name]       forKey:@"name"];    
  [_coder encodeString:[self priority]   forKey:@"priority"];
  [_coder encodeString:[self keywords]   forKey:@"keywords"];
  [_coder encodeString:[self salutation] forKey:@"salutation"];
  [_coder encodeString:[self url]        forKey:@"url"];
  [_coder encodeString:[self bank]       forKey:@"bank"];
  [_coder encodeString:[self bankCode]   forKey:@"bankCode"];
  [_coder encodeString:[self account]    forKey:@"account"];
  [_coder encodeString:[self email]      forKey:@"email"];
}

@end /* SkyEnterpriseDocument(XmlRpcCoding) */
