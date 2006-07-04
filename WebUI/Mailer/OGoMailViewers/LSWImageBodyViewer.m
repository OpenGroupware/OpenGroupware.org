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

#include "LSWPartBodyViewer.h"
#include "common.h"

@implementation LSWImageBodyViewer

- (void)dealloc {
  [self->mimeType release];
  [super dealloc];
}

- (BOOL)isDownloadable {
  return YES;
}

- (NSData *)data {
  if ([self->body isKindOfClass:[NSURL class]]) {
    NSString *part;

    part = [[[self->body query] componentsSeparatedByString:@"="] lastObject];
    return [self->source contentsOfPart:part];
  }
  return self->body;
}

- (id)mimeContent {
  return [LSWMimeContent mimeContent:[self data]
                         ofType:[self->partOfBody contentType]
                         inContext:[self context]];
}

- (void)setMimeType:(NGMimeType *)_mimeType {
  ASSIGN(self->mimeType, _mimeType);
}
- (NGMimeType *)mimeType {
  return self->mimeType != nil ? self->mimeType : (NGMimeType *)@"image/gif";
}

- (NSString *)imageKey {
  char ikey[32];
  
  sprintf(ikey, "img%p", self);
  return [NSString stringWithCString:ikey];
}


@end /* LSWImageBodyViewer */

