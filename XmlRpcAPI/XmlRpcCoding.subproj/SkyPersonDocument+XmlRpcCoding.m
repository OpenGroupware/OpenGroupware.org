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

#include <OGoContacts/SkyPersonDocument.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@implementation SkyPersonDocument(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder]) != nil) {
    [self setFirstname: [_coder decodeStringForKey:@"firstname"]];
    [self setMiddlename:[_coder decodeStringForKey:@"middlename"]];
    [self setName:      [_coder decodeStringForKey:@"name"]];
    [self setNickname:  [_coder decodeStringForKey:@"nickname"]];
    [self setNumber:    [_coder decodeStringForKey:@"number"]];
    [self setSalutation:[_coder decodeStringForKey:@"salutation"]];
    [self setDegree:    [_coder decodeStringForKey:@"degree"]];
    [self setBirthday:  [_coder decodeDateTimeForKey:@"birthday"]];
    [self setUrl:       [_coder decodeStringForKey:@"url"]];
    [self setGender:    [_coder decodeStringForKey:@"gender"]];
    [self setComment:   [_coder decodeStringForKey:@"comment"]];
    [self setLogin:     [_coder decodeStringForKey:@"login"]];
    
    [self setIsAccount: [_coder decodeBooleanForKey:@"isAccount"]];
    [self setIsPrivate: [_coder decodeBooleanForKey:@"isPrivate"]];
  }
  return self;
}

- (void)encodeWithXmlRpcCoder:(id)_coder {
  [super encodeWithXmlRpcCoder:_coder];
  [_coder encodeString:[self firstname]  forKey:@"firstname"];
  [_coder encodeString:[self middlename] forKey:@"middlename"];
  [_coder encodeString:[self name]       forKey:@"name"];
  [_coder encodeString:[self nickname]   forKey:@"nickname"];
  [_coder encodeString:[self number]     forKey:@"number"];
  [_coder encodeString:[self salutation] forKey:@"salutation"];
  [_coder encodeString:[self degree]     forKey:@"degree"];
  [_coder encodeDateTime:[self birthday] forKey:@"birthday"];
  [_coder encodeString:[self url]        forKey:@"url"];
  [_coder encodeString:[self gender]     forKey:@"gender"];
  [_coder encodeString:[self comment]    forKey:@"comment"];
  [_coder encodeString:[self login]      forKey:@"login"];
  [_coder encodeBoolean:[self isAccount] forKey:@"isAccount"];
  [_coder encodeBoolean:[self isPrivate] forKey:@"isPrivate"];
}

@end /* SkyPersonDocument(XmlRpcCoding) */
