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

#include "LSWMimeBodyPartViewer.h"
#include "common.h"

@implementation LSWMimeBodyPartViewer

- (BOOL)isCompositeType {
  return [[self->part contentType] isCompositeType] ? YES : NO;
}

- (BOOL)isEoType {
  id contentType = [self->part contentType];
  
  return ([[(NGMimeType *)contentType type] isEqualToString:@"eo-pkey"]) ? YES : NO;
}

- (BOOL)isRfcType {
  id contentType;

  if (self->showRfc822) {
    return NO;
  }
  contentType = [self->part contentType];
  
  return ([contentType hasSameType:[NGMimeType mimeType:@"message/rfc822"]])
         ? YES : NO;
}

- (BOOL)isInForm {
  return [[self context] isInForm];
}

- (void)setShowRfc822:(BOOL)_bool {
  self->showRfc822 = _bool;
}
- (BOOL)showRfc822 {
  return self->showRfc822;
}


@end /* LSWMimeBodyPartViewer */
