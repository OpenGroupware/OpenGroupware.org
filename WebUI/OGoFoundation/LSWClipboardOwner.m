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

#import "common.h"
#import "LSWClipboardOwner.h"
#import "OWPasteboard.h"

@implementation LSWClipboardOwner

- (id)initWithSession:(WOSession *)_session object:(id)_object {
  if ((self = [super init])) {
    self->session = _session;
    self->object  = RETAIN(_object);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->object);
  [super dealloc];
}
#endif

+ (id)clipboardOwnerForSession:(WOSession *)_session {
  return AUTORELEASE([[self alloc] initWithSession:_session object:nil]);
}
+ (id)clipboardOwnerForSession:(WOSession *)_session object:(id)_object {
  return AUTORELEASE([[self alloc] initWithSession:_session object:_object]);
}

// pasteboard owner

- (void)pasteboardChangedOwner:(OWPasteboard *)_pasteboard {
  NSLog(@"%@: pasteboard changed owner ..", self);
}

- (void)pasteboard:(OWPasteboard *)_pasteboard
  provideDataForType:(NGMimeType *)_type {

  NSLog(@"%@: provide data for type %@ in pasteboard with types %@",
        self, _type, [_pasteboard types]);

  if (self->object)
    [_pasteboard setObject:self->object forType:_type];
}

@end
