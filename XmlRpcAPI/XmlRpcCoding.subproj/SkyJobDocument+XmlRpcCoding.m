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

#include <OGoJobs/SkyJobDocument.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@interface SkyJobDocument(ObjectVersion)
- (void)_setObjectVersion:(NSNumber *)_version;
@end /* SkyJobDocument(ObjectVersion) */

@implementation SkyJobDocument(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder])) {
    [self setName:[_coder decodeStringForKey:@"name"]];
    [self setStartDate:[_coder decodeDateTimeForKey:@"startDate"]];
    [self setEndDate:[_coder decodeDateTimeForKey:@"endDate"]];
    [self setKeywords:[_coder decodeStringForKey:@"keywords"]];
    [self setCategory:[_coder decodeStringForKey:@"category"]];
    [self setStatus:[_coder decodeStringForKey:@"status"]];
    [self setPriority:
          [NSNumber numberWithInt:[_coder decodeIntForKey:@"priority"]]];
    [self setType:[_coder decodeStringForKey:@"type"]];
    [self setCreator:[_coder decodeObjectForKey:@"creator"]];
    [self setExecutor:[_coder decodeObjectForKey:@"executor"]];
    [self _setObjectVersion:
          [NSNumber numberWithInt:[_coder decodeIntForKey:@"objectVersion"]]];
  }
  return self;
}

- (void)encodeWithXmlRpcCoder:(XmlRpcEncoder *)_coder {
  [super encodeWithXmlRpcCoder:_coder];
  
  [_coder encodeBoolean:self->isTeamJob             forKey:@"isTeamJob"];
  [_coder encodeString:[self name]                  forKey:@"name"];
  [_coder encodeDateTime:[self startDate]           forKey:@"startDate"];
  [_coder encodeDateTime:[self endDate]             forKey:@"endDate"];
  [_coder encodeString:[self keywords]              forKey:@"keywords"];
  [_coder encodeString:[self category]              forKey:@"category"];
  [_coder encodeString:[self status]                forKey:@"status"];
  [_coder encodeInt:[[self priority] intValue]      forKey:@"priority"];
  [_coder encodeString:[self type]                  forKey:@"type"];
  [_coder encodeObject:[self creator]               forKey:@"creator"];
  [_coder encodeObject:[self executor]              forKey:@"executor"];
  [_coder encodeInt:[[self objectVersion] intValue] forKey:@"objectVersion"];
}

@end /* SkyJobDocument(XmlRpcCoding) */
