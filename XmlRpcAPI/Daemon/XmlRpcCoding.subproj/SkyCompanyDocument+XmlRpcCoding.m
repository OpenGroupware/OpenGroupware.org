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

#include <OGoContacts/SkyCompanyDocument.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@interface SkyCompanyDocument(ObjectVersion)
- (void)_setObjectVersion:(NSNumber *)_version;
@end /* SkyCompanyDocument(ObjectVersion) */

@implementation SkyCompanyDocument(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder])) {
    id tmp;
    
    [self setSupportedAttributes:
          [_coder decodeArrayForKey:@"supportedAttributes"]];

    if ([self isAttributeSupported:@"telephones"]) {
      if ((tmp = [_coder decodeStructForKey:@"phones"]) == nil)
        tmp = [NSDictionary dictionary];
      [self->phones release];
      self->phones = [[NSMutableDictionary alloc] initWithDictionary:tmp];
      
      if ((tmp = [_coder decodeArrayForKey:@"phoneTypes"]))
        tmp = [NSDictionary dictionary];
      [self->phoneTypes release];
      self->phoneTypes = [[NSMutableArray alloc] initWithArray:tmp];      
    }

    if ([self isAttributeSupported:@"addresses"]) {
      if ((tmp = [_coder decodeStructForKey:@"addresses"]) == nil)
        tmp = [NSDictionary dictionary];
      [self->addresses release];
      self->addresses = [[NSMutableDictionary alloc] initWithDictionary:tmp];
    }

    if ([self isAttributeSupported:@"extendedAttributes"]) {
      if ((tmp = [_coder decodeStructForKey:@"extendedAttrs"]) == nil)
        tmp = [NSDictionary dictionary];
      [self->extendedAttrs release];
      self->extendedAttrs=[[NSMutableDictionary alloc] initWithDictionary:tmp];

      if ((tmp = [_coder decodeArrayForKey:@"extendedKeys"]) == nil)
        tmp = [NSDictionary dictionary];
      [self->extendedKeys release];
      self->extendedKeys = [[NSMutableArray alloc] initWithArray:tmp];
    }

    if ([self isAttributeSupported:@"contact"])
      [self setContact:[_coder decodeObjectForKey:@"contact"]];


    if ([self isAttributeSupported:@"owner"])
      [self setOwner:[_coder decodeObjectForKey:@"owner"]];
    
    if ([self isAttributeSupported:@"comment"])
      [self setComment:[_coder decodeStringForKey:@"comment"]];

    if ([self isAttributeSupported:@"keywords"])
      [self setKeywords:[_coder decodeStringForKey:@"keywords"]];
    
    // [self _setGlobalID:[_coder decodeObjectForKey:@"globalID"]];
    [self _setObjectVersion:
          [NSNumber numberWithInt:[_coder decodeIntForKey:@"objectVersion"]]];
    self->status.isEdited   = NO;
    self->status.isComplete = (self->supportedAttributes == nil);
    self->status.isValid    = YES;
  }
  return self;
}

- (void)encodeWithXmlRpcCoder:(id)_coder {
  NSMutableDictionary *addrDict;
  NSEnumerator        *typeEnum;
  NSString            *type;

  [super encodeWithXmlRpcCoder:_coder];
  addrDict = [NSMutableDictionary dictionaryWithCapacity:4];
  typeEnum = [[self addressTypes] objectEnumerator];
  while ((type = [typeEnum nextObject])) {
    id addr;

    if ((addr = [self addressForType:type]) != nil)
      [addrDict setObject:addr forKey:type];
  }

#if 0
  if (self->supportedAttributes) {
    [_coder encodeArray:self->supportedAttributes
            forKey:@"supportedAttributes"];
  }
#endif
  
  if ([self isAttributeSupported:@"telephones"]) {
    [_coder encodeStruct:self->phones     forKey:@"phones"];
    [_coder encodeArray:[self phoneTypes] forKey:@"phoneTypes"];
  }
  
  if ([self isAttributeSupported:@"addresses"])
    [_coder encodeStruct:addrDict forKey:@"addresses"];

  if ([self isAttributeSupported:@"extendedAttributes"]) {
    [_coder encodeStruct:self->extendedAttrs forKey:@"extendedAttrs"];
    [_coder encodeArray:self->extendedKeys   forKey:@"extendedKeys"];
  }

  if ([self isAttributeSupported:@"contact"])
    [_coder encodeObject:[self contact] forKey:@"contact"];
  
  if ([self isAttributeSupported:@"owner"])
    [_coder encodeObject:[self owner] forKey:@"owner"];

  if ([self isAttributeSupported:@"comment"])
    [_coder encodeString:[self comment] forKey:@"comment"];

  if ([self isAttributeSupported:@"keywords"])
    [_coder encodeString:[self keywords] forKey:@"keywords"];

  //  [_coder encodeObject:[self globalID]              forKey:@"globalID"];
  [_coder encodeInt:[[self objectVersion] intValue] forKey:@"objectVersion"];
  [_coder encodeBoolean:self->status.isComplete     forKey:@"isComplete"];
}

@end /* SkyCompanyDocument(XmlRpcCoding) */
