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

#include "Attachment.h"
#include "common.h"

@implementation Attachment

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->mimeType);
  RELEASE(self->encoding);
  RELEASE(self->content);
  RELEASE(self->fileName);

  [super dealloc];
}
#endif

- (NGMimeType *)mimeType {
  return self->mimeType;
}
- (void)setMimeType:(NGMimeType *)_mimeType {
  ASSIGN(self->mimeType, _mimeType);
}

- (NSString *)encoding {
  return self->encoding;
}
- (void)setEncoding:(NSString *)_encoding {
  ASSIGN(self->encoding, _encoding);
}

- (NSData *)content {
  return self->content;
}
- (void)setContent:(NSData *)_content {
  ASSIGN(self->content, _content);
}

- (NSString *)fileName {
  return self->fileName;
}
- (void)setFileName:(NSString *)_fileName {
  ASSIGN(self->fileName, _fileName);
}

@end // Attachment
