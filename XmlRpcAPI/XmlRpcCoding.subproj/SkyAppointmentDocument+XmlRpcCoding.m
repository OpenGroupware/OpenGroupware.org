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

#include <OGoScheduler/SkyAppointmentDocument.h>
#include <XmlRpc/XmlRpcCoder.h>
#include "common.h"
#include "SkyDocument+XmlRpcCoding.h"

@implementation SkyAppointmentDocument(XmlRpcCoding)

- (id)initWithXmlRpcCoder:(XmlRpcDecoder *)_coder {
  if ((self = [super initWithXmlRpcCoder:_coder]) != nil) {
    NSArray *tmp;
    
    [self setStartDate:   [_coder decodeDateTimeForKey:@"startDate"]];
    [self setEndDate:     [_coder decodeDateTimeForKey:@"endDate"]];
    [self setCycleEndDate:[_coder decodeDateTimeForKey:@"cycleEndDate"]];
    [self setTitle:       [_coder decodeStringForKey:@"title"]];
    [self setLocation:    [_coder decodeStringForKey:@"location"]];
    [self setType:        [_coder decodeStringForKey:@"type"]];
    [self setOwner:       [_coder decodeObjectForKey:@"owner"]];
    [self setComment:     [_coder decodeStringForKey:@"comment"]];
    [self setParticipants:[_coder decodeArrayForKey:@"participants"]];
    [self setAptType:     [_coder decodeStringForKey:@"aptType"]];
    [self setAccessTeamId:[_coder decodeStringForKey:@"accessTeamId"]];
    [self setWriteAccess: [_coder decodeArrayForKey:@"writeAccess"]];

    tmp = [_coder decodeArrayForKey:@"resourceNames"];
    if ([tmp isNotEmpty])
      [self setResourceNames:[tmp componentsJoinedByString:@", "]];
    else
      [self setResourceNames:nil];
  }  
  return self;
}

- (void)encodeWithXmlRpcCoder:(id)_coder {
  id tmp;
  
  [super encodeWithXmlRpcCoder:_coder];
  [_coder encodeDateTime:[self startDate]    forKey:@"startDate"];
  [_coder encodeDateTime:[self endDate]      forKey:@"endDate"];
  [_coder encodeDateTime:[self cycleEndDate] forKey:@"cycleEndDate"];
  [_coder encodeString:[self title]          forKey:@"title"];
  [_coder encodeString:[self location]       forKey:@"location"];
  [_coder encodeString:[self type]           forKey:@"type"];
  [_coder encodeObject:[self owner]          forKey:@"owner"];
  [_coder encodeString:[self comment]        forKey:@"comment"];
  [_coder encodeArray:[self participants]    forKey:@"participants"];
  [_coder encodeString:[self aptType]        forKey:@"aptType"];
  [_coder encodeObject:[self accessTeamId]   forKey:@"accessTeamId"];
  [_coder encodeArray:[self writeAccess]     forKey:@"writeAccess"];

  if ([(tmp = [self resourceNames]) isNotEmpty])
    tmp = [tmp componentsSeparatedByString:@", "];
  else
    tmp = [NSArray array];
  [_coder encodeArray:tmp forKey:@"resourceNames"];
}

@end /* SkyAppointmentDocument(XmlRpcCoding) */
