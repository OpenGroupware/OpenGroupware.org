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
// $Id: SkyProject+XmlRpcCoding.m 1 2004-08-20 11:17:52Z znek $

#include <OGoProject/SkyProject.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@implementation SkyProject(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder])) {
    [self setName:[_coder decodeStringForKey:@"name"]];
    [self setStartDate:[_coder decodeDateTimeForKey:@"startDate"]];
    [self setEndDate:[_coder decodeDateTimeForKey:@"endDate"]];
    [self setLeader:[_coder decodeObjectForKey:@"leader"]];
    [self setTeam:[_coder decodeObjectForKey:@"team"]];
    [self setNumber:[_coder decodeObjectForKey:@"number"]];
    //[self setType:[_coder decodeObjectForKey:@"type"]];
    [self setKind:[_coder decodeObjectForKey:@"kind"]];
  }
  return self;
}

- (void)encodeWithXmlRpcCoder:(XmlRpcEncoder *)_coder {
  [super encodeWithXmlRpcCoder:_coder];

  [_coder encodeString:[self name]                  forKey:@"name"];
  [_coder encodeDateTime:[self startDate]           forKey:@"startDate"];
  [_coder encodeDateTime:[self endDate]             forKey:@"endDate"];
  [_coder encodeObject:[self leader]                forKey:@"leader"];
  [_coder encodeObject:[self team]                  forKey:@"team"];
  [_coder encodeObject:[self number]                forKey:@"number"];
  [_coder encodeObject:self->type                   forKey:@"type"];
  [_coder encodeObject:[self kind]                  forKey:@"kind"];
  [_coder encodeObject:self->projectAccounts        forKey:@"accounts"];
}

@end /* SkyProject(XmlRpcCoding) */
