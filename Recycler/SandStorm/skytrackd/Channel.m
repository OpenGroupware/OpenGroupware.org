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

#include "Channel.h"
#include "common.h"

@implementation Channel

- (id)init {
  if ((self = [super init])) {
    self->channelID        = [[NSString alloc] init];
    self->lastModification = [[NSDate alloc] init];
    self->credentials      = [[NSString alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->channelID);
  RELEASE(self->credentials);
  RELEASE(self->lastModification);

  [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)_dict name:(NSString *)_name {

  [self setChannelID:_name];
  [self setCredentials:[_dict objectForKey:@"credentials"]];

  return self;
}

/* accessors */

- (NSString *)channelID {
  return self->channelID;
}
- (void)setChannelID:(NSString *)_channelID {
  ASSIGNCOPY(self->channelID, _channelID);
}

- (NSString *)credentials {
  return self->credentials;
}
- (void)setCredentials:(NSString *)_credentials {
  ASSIGNCOPY(self->credentials, _credentials);
}

- (NSDate *)lastModification {
  return self->lastModification;
}
- (void)setLastModification:(NSDate *)_lastModification {
  ASSIGN(self->lastModification, _lastModification);
}

- (id)trackChannel {
  return nil;
}

@end /* Channel */
