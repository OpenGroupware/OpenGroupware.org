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

/*
  Example:
  
  EditorButtons : SkyEditorButtons {
    isSaveEnabled   = NO;           // default: YES
    isCancelEnabled = NO;           // default: YES
    isDeleteEnabled = YES;          // default: NO
    saveLabel       = "save";       // default: localized "save"
    deleteLabel     = "delete";     // default: localized "delete"
    cancelLabel     = "cancel";     // default: localized "cancel"
  }

  <#EditorButtons>
    <!-- some extra buttons -->
  </#EditorButtons>
*/

@class NSString;

@interface SkyEditorButtons : LSWComponent {
  BOOL     isSaveEnabled;
  BOOL     isCancelEnabled;
  BOOL     isDeleteEnabled;
  NSString *saveLabel;
  NSString *deleteLabel;
  NSString *cancelLabel;
  NSString *saveFilename;
  NSString *deleteFilename;
  NSString *cancelFilename;
}
@end /* SkyEditorButtons */

#include "common.h"

@implementation SkyEditorButtons

- (id)init {
  if ((self = [super init])) {
    self->isSaveEnabled   = YES;
    self->isCancelEnabled = YES;
  }
  return self;
}

/* accessors */

- (void)setIsSaveEnabled:(BOOL)_bool {
  self->isSaveEnabled = _bool;
}
- (BOOL)isSaveEnabled {
  return self->isSaveEnabled;
}

- (void)setIsCancelEnabled:(BOOL)_bool {
  self->isCancelEnabled = _bool;
}
- (BOOL)isCancelEnabled {
  return self->isCancelEnabled;
}

- (void)setIsDeleteEnabled:(BOOL)_bool {
  self->isDeleteEnabled = _bool;
}
- (BOOL)isDeleteEnabled {
  return self->isDeleteEnabled;
}

- (void)setSaveLabel:(NSString *)_label {
  ASSIGN(self->saveLabel, _label);
}
- (NSString *)_saveLabel {
  return (self->saveLabel != nil)
    ? self->saveLabel
    : [[self labels] valueForKey:@"save"];
}

- (void)setCancelLabel:(NSString *)_label {
  ASSIGN(self->cancelLabel, _label);
}
- (NSString *)_cancelLabel {
  return (self->cancelLabel != nil)
    ? self->cancelLabel
    : [[self labels] valueForKey:@"cancel"];
}

- (void)setDeleteLabel:(NSString *)_label {
  ASSIGN(self->deleteLabel, _label);
}
- (NSString *)_deleteLabel {
  return (self->deleteLabel != nil)
    ? self->deleteLabel
    : [[self labels] valueForKey:@"delete"];
}

/* actions */

- (id)save {
  return [self performParentAction:@"save"];
}

- (id)cancel {
  return [self performParentAction:@"cancel"];
}

- (id)delete {
  return [self performParentAction:@"delete"];
}

@end /* SkyEditorButtons */
