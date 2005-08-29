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

#ifndef __OGoFoundation_SkyEditorPage_H__
#define __OGoFoundation_SkyEditorPage_H__

#include <OGoFoundation/LSWContentPage.h>

/*
  SkyEditorPage

  TODO: document
  TODO: change superclass
*/

@class NSMutableDictionary, NSDictionary, NSString;
@class NGMimeType, SkyDocument;

@interface SkyEditorPage : LSWContentPage
{
@private
  SkyDocument *document;
  NSArray     *subEditors;

  BOOL        isInNewMode;
  NSString    *windowTitle;
}

- (void)clearEditor; // release all state

/* accessors */

- (void)setIsInNewMode:(BOOL)_status;
- (BOOL)isInNewMode;
- (void)setObject:(id)_oject;
- (id)object;

- (NSString *)objectLabel;
- (NSString *)label;
- (BOOL)isDeleteDisabled;

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg;

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg;

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg;

/* constraints (return NO if contraints fail) */

- (BOOL)checkConstraintsForSave;
- (BOOL)checkConstraintsForDelete;
- (BOOL)checkConstraintsForCancel;

/* actions */

- (id)save;   // update or insert record
- (id)delete; // delete record (not applicable in new mode)
- (id)cancel; // cancel editor
- (id)cancelDelete; // cancel delete (switch back to editor)

- (id)saveAndGoBackWithCount:(int)_backCount;
- (id)deleteAndGoBackWithCount:(int)_backCount;

/* to change the window-title (e.g. in wizard mode) */

- (NSString *)windowTitle;
- (void)setWindowTitle:(NSString *)_title;

@end

@interface NSObject(SkyEditorPageTyping)
- (BOOL)isEditorPage;
@end

#endif /* __OGoFoundation_SkyEditorPage_H__ */
