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

#ifndef __OGoFoundation_OGoEditorPage_H__
#define __OGoFoundation_OGoEditorPage_H__

#include <OGoFoundation/LSWContentPage.h>

/**
 * @class OGoEditorPage
 * @brief Base page for editing OGo objects in a form.
 *
 * Provides the standard editing lifecycle: activation
 * (new or edit mode), snapshot management, constraint
 * checking, insert/update/delete operations wrapped in
 * database transactions, and navigation back to the
 * previous page. Editor pages disable navigation links
 * to prevent accidental data loss. Supports optional
 * wizard mode for multi-step creation flows.
 *
 * Subclasses override -insertObject, -updateObject, and
 * -deleteObject to perform the actual Logic command
 * execution, and -checkConstraintsForSave /
 * -checkConstraintsForDelete for validation.
 *
 * @see OGoContentPage
 * @see OGoEditorPage(Wizard)
 */

@class NSMutableDictionary, NSDictionary, NSString;
@class NGMimeType;

// TODO: remove wizard nonsense once sure it isn't used
// TODO: replace LSWContentPage with OGoContentPage in the long run
@interface OGoEditorPage : LSWContentPage
{
@private
  NSString            *activationCommand;
  NSMutableDictionary *snapshot;
  id                  wizard;  
  id                  object;
  
  /* 
     if isInWizardMode wizardObjectParent contains the parent of the
     edited object (during the save-process)
  */
  id                  wizardObjectParent;
  BOOL                isInNewMode;
  BOOL                isInWizardMode;
  NSString            *windowTitle;
}

- (void)clearEditor; // release all state

/* accessors */

- (NSString *)activationCommand;
- (void)setIsInNewMode:(BOOL)_status;
- (BOOL)isInNewMode;
- (void)setIsInWizardMode:(BOOL)_status;
- (BOOL)isInWizardMode;
- (void)setObject:(id)_oject;
- (id)object;
- (void)setSnapshot:(NSMutableDictionary *)_snapshot;
- (NSMutableDictionary *)snapshot;

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

- (BOOL)makeSnapshotFromObject;

/*
  Operations

  Operations must return the new object or nil if the operation failed.
  Operations are automagically placed in a transaction and exception handler.
*/
- (id)insertObject;
- (id)updateObject;
- (id)deleteObject;

/* constraints (return NO if contraints fail) */

- (BOOL)checkConstraintsForSave;
- (BOOL)checkConstraintsForDelete;
- (BOOL)checkConstraintsForCancel;

/* actions */

- (id)save;   // update or insert record
- (id)delete; // delete record (not applicable in new mode)
- (id)cancel; // cancel editor

- (id)view;   // show viewer

- (id)saveAndGoBackWithCount:(int)_backCount;
- (id)deleteAndGoBackWithCount:(int)_backCount;

/* errors */

- (void)handleException:(NSException *)_exc;

/* to change the window-title (e.g. in wizard mode) */

- (NSString *)windowTitle;
- (void)setWindowTitle:(NSString *)_title;

@end

/**
 * @class LSWEditorPage
 * @brief Deprecated alias for OGoEditorPage.
 *
 * @deprecated Use OGoEditorPage.
 * @see OGoEditorPage
 */
@interface LSWEditorPage : OGoEditorPage // DEPRECATED
@end

/**
 * @category NSObject(LSWEditorPageTyping)
 * @brief Typing check for editor pages.
 *
 * Provides -isEditorPage which returns NO by default.
 * OGoEditorPage overrides this to return YES, allowing
 * runtime type discrimination without class checks.
 */
@interface NSObject(LSWEditorPageTyping)

- (BOOL)isEditorPage;

@end

#include <OGoFoundation/LSWEditorPage+Wizard.h>

#endif /* __OGoFoundation_OGoEditorPage_H__ */
