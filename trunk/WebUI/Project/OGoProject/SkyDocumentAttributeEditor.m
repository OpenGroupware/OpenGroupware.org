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

#include <OGoFoundation/LSWContentPage.h>

@class SkyProjectDocument;

@interface SkyDocumentAttributeEditor : LSWContentPage
{
  SkyProjectDocument *doc;
}

@end

#include "common.h"

@implementation SkyDocumentAttributeEditor

- (void)dealloc {
  [self->doc release];
  [super dealloc];
}

/* accessors */

- (NSString *)label {
  return [NSString stringWithFormat:
                   [[self labels] valueForKey:@"AttributeEditorFor"],
                   [self->doc valueForKey:@"NSFileName"]];
}

- (void)setDoc:(id)_id {
  ASSIGN(self->doc, _id);
}
- (id)doc {
  return self->doc;
}

/* actions */

- (id)save {
  if (![doc save]) {
    [self setErrorString:@"document save failed"];
    return nil;
  }
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)cancel {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

@end /* SkyProject4DocumentRename */
