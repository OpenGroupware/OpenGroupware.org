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

#include "LSWMimeMessageViewer.h"
#include "common.h"

@implementation LSWMimeMessageViewer

- (NSString *)subject {
  id subject;

  subject = [self->part valuesOfHeaderFieldWithName:@"subject"];
  subject = [subject nextObject];

  return [subject stringValue];
}

- (NSString *)sender {
  id sender;

  sender = [self->part valuesOfHeaderFieldWithName:@"from"];
  sender = [sender nextObject];

  return [sender stringValue];
}

- (id)date {
  return [[self->part valuesOfHeaderFieldWithName:@"date"] nextObject];
}

- (NSString *)organization {
  id organization;

  organization = [self->part valuesOfHeaderFieldWithName:@"organization"];
  organization = [organization nextObject];

  return [organization stringValue];
}

- (NSString *)messageId {
  id messageId;

  messageId = [self->part valuesOfHeaderFieldWithName:@"message-id"];
  messageId = [messageId nextObject];

  return [messageId stringValue];
}

- (NSNumber *)contentLength {
  id contentLength;

  contentLength = [self->part valuesOfHeaderFieldWithName:@"content-length"];
  contentLength = [contentLength nextObject];

  return ([contentLength isKindOfClass:[NSNumber class]])
    ? contentLength
    : [NSNumber numberWithInt:[contentLength intValue]];
}

- (id)bodyViewerComponent {
  id viewer;

  viewer = [self pageWithName:
                 [[self session] viewerComponentForPart:self->part]];
  [viewer setSource:[self source]];
  return viewer;
}

- (id)part {
  return self->part;
}

@end
