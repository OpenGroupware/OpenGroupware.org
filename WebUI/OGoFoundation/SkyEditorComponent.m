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

#include <OGoFoundation/SkyEditorComponent.h>
#include <OGoDocuments/SkyDocument.h>
#import "common.h"

#define SkySubEditors @"SkyEditor_SubEditors"

@implementation SkyEditorComponent

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->document release];
  [super dealloc];
}

- (void)prepareEditor {
}

/* document */

- (void)setDocument:(id)_document {
  ASSIGN(self->document, _document);
}
- (SkyDocument *)document {
  return self->document;
}

/* constraints */

- (BOOL)checkConstraintsForSave {
  return YES;
}
- (BOOL)checkConstraintsForDelete {
  return YES;
}
- (BOOL)checkConstraintsForCancel {
  return YES;
}

/* actions */

- (BOOL)save {
  return YES;
}

- (BOOL)delete {
  return YES;
}

- (BOOL)cancel {
  return YES;
}

/* register as subEditor */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSMutableArray *tmp;

  if (!self->didPrepareEditor) {
    [self prepareEditor];
    self->didPrepareEditor = YES;
  }
  
  // register as SubEditor
  if ((tmp = [_ctx objectForKey:SkySubEditors])) [tmp addObject:self];

  [super appendToResponse:_response inContext:_ctx];
}

@end /* SkyEditorComponent */
