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
// $Id$

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSData;
@class NGMimeType;

@interface SkyDocImageInlineViewer : LSWComponent
{
  NSString   *uri;
  NGMimeType *contentType;
  unsigned   contentLength;
  NSData     *data;
  NSString   *fileName;
}

- (void)setObject:(id)_object;
- (void)setContentType:(NGMimeType *)_type;

@end

#include <NGMime/NGMimeType.h>
#include "common.h"

@implementation SkyDocImageInlineViewer

- (void)dealloc {
  [self->uri         release];
  [self->contentType release];
  [self->fileName    release];
  [self->data        release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  object:(id)_object
{
  [self setContentType:_type];
  [self setObject:_object];
  return YES;
}

/* accessors */

- (void)setObject:(id)_object {
  ASSIGN(self->data, _object);
  self->contentLength = [self->data length];
}
- (id)object {
  return self->data;
}

- (void)setUri:(NSString *)_object {
  ASSIGNCOPY(self->uri, _object);
}
- (id)uri {
  return self->uri;
}

- (void)setFileName:(NSString *)_object {
  ASSIGNCOPY(self->fileName, _object);
  self->contentLength = [self->data length];
}
- (id)fileName {
  return self->fileName;
}

- (void)setContentType:(NGMimeType *)_type {
  ASSIGN(self->contentType, _type);
}
- (NGMimeType *)contentType {
  return self->contentType;
}

- (id)mimeContent {
  return [LSWMimeContent mimeContent:[self object]
                         ofType:[self contentType]
                         inContext:[self context]];
}

- (id)width {
  WEClientCapabilities *ccaps;

  ccaps = [[[self context] request] clientCapabilities];
  return ([ccaps majorVersion] >= 5 && [ccaps isInternetExplorer])
    ? @"100%" : @"600";
}
- (int)height {
  return 500;
}

- (BOOL)useURI {
  return [self->uri length] > 0 ? YES : NO;
}

@end /* SkyDocImageInlineViewer */
