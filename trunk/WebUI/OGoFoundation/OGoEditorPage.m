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

#include <OGoFoundation/OGoEditorPage.h>
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <OGoFoundation/SkyWizard.h>
#include <OGoFoundation/OGoNavigation.h>
#include <GDLAccess/EOEntity+Factory.h>
#import "common.h"

@implementation OGoEditorPage

+ (int)version {
  return [super version] /* v3 */;
}
+ (void)initialize {
  NSAssert2([super version] == 3,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->snapshot    release];
  [self->object      release];
  [self->wizard      release];
  [self->windowTitle release];
  [self->activationCommand release]; // bs: testing
  [super dealloc];
}

- (void)clearEditor {
  [self->snapshot release];          self->snapshot          = nil;
  [self->object release];            self->object            = nil;
  [self->activationCommand release]; self->activationCommand = nil;
  [self setIsInWarningMode:NO];
}

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  [self clearEditor];
  self->activationCommand = [_command copy];
  
  self->isInWizardMode = [_command hasPrefix:@"wizard"];
  self->isInNewMode    = [_command hasPrefix:@"new"] || self->isInWizardMode;

  if (self->isInNewMode) {
    self->snapshot = [[NSMutableDictionary alloc] initWithCapacity:32];
    return [self prepareForNewCommand:_command type:_type configuration:nil];
  }

  if ((self->object = [[[self session] getTransferObject] retain]) == nil) {
    [self setErrorString:@"No object in transfer pasteboard !"];
    return NO;
  }
      
  /* make snapshot */
  self->snapshot =
    [[self->object valuesForKeys:[[self->object entity] attributeNames]]
                   mutableCopy];
      
  return [self prepareForEditCommand:_command type:_type configuration:nil];
}

/* object */

- (NSString *)activationCommand {
  return self->activationCommand;
}

- (void)setIsInNewMode:(BOOL)_status {
  self->isInNewMode = _status;
}
- (BOOL)isInNewMode {
  return self->isInNewMode;
}

- (void)setIsInWizardMode:(BOOL)_status {
  self->isInWizardMode = _status;
}
- (BOOL)isInWizardMode {
  return self->isInWizardMode;
}

- (void)setObject:(id)_object {
  ASSIGN(self->object, _object);
}
- (id)object {
  return self->object;
}

- (void)setSnapshot:(NSMutableDictionary *)_snapshot {
  ASSIGN(self->snapshot, _snapshot);
}
- (NSMutableDictionary *)snapshot {
  return self->snapshot;
}

- (NSString *)objectLabel {
  id obj;
  
  if ((obj = [self object]))
    return [[self session] labelForObject:obj];
  
  if (self->isInNewMode) {
    NSString *l = [[self labels] valueForKey:@"new"];
    return (l != nil) ? l : @"new";
  }
  
  return nil;
}

/* content page */

- (NSString *)label {
  NSString *label;

  label = [super label];
  return [NSString stringWithFormat:@"%@ (%@)", label, [self objectLabel]];
}

- (BOOL)isDeleteDisabled {
  return self->isInNewMode ? YES : NO;
}

/* operations */

- (id)insertObject {
  [self setErrorString:@"ERROR: this editor-page cannot create object!"];
  return nil;
}
- (id)updateObject {
  [self setErrorString:@"ERROR: this editor-page cannot save objects!"];
  return nil;
}
- (id)deleteObject {
  [self setErrorString:@"ERROR: this editor-page cannot delete objects!"];
  return nil;
}

- (void)refreshObject {
  // TODO: is this actually used somewhere? Only works on EOs.
  EODatabaseChannel *channel;
  
  channel = [[self session] valueForKey:@"databaseChannel"];
  [channel refetchObject:[self object]];
}

- (id)_performOpInTransaction:(SEL)_op {
  id   result;
  BOOL beganTx = NO;
  BOOL isOk    = YES;

  *(&result) = nil;
  [self setErrorString:nil];
  
  NS_DURING {
    if (![self isTransactionInProgress])
      beganTx = YES;
    
    if (isOk) {
      if (!self->isInNewMode) {
        if (self->object) {
          [self->snapshot takeValue:self->object forKey:@"object"];
        }
        else {
          [self setErrorString:@"Missing object in editor."];
          isOk = NO;
        }
      }
    }
    if (isOk) {
      NS_DURING {
        isOk = NO;
        result = [self performSelector:_op];
        isOk = result ? YES : NO;
      }
      NS_HANDLER {
        if (beganTx) { [self rollback]; beganTx = NO; }
        [self handleException:localException];
        isOk = NO;
      }
      NS_ENDHANDLER;
    }

    if (beganTx && !isOk) {
      [self rollback];
      beganTx = NO;
    }
    
    if (beganTx && isOk) {
      if (![self commit]) {
        [self setErrorString:@"Could not commit database transaction."];
        isOk = NO;
        
        if ([self isTransactionInProgress])
          [self rollback];
      }
    }
  }
  NS_HANDLER {
    [self setErrorString:[localException reason]];
    if (beganTx) [self rollback];
    isOk = NO;
  }
  NS_ENDHANDLER;
  
  return result;
}

- (void)handleException:(NSException *)_exc {
  [self logWithFormat:
           @"command exception:\n"
           @"  name=  %@\n  reason=%@\n  info=  %@",
          [_exc name], [_exc reason], [_exc userInfo]];
  [self setErrorString:[NSString stringWithFormat:@"%@ %@",
                                   [_exc name], [_exc reason]]];

  if ([[[NSUserDefaults standardUserDefaults]
                        objectForKey:@"LSCoreOnCommandException"]
                        boolValue])
    abort();
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

/* notifications */

- (NSString *)insertNotificationName {
  return nil;
}

- (NSString *)updateNotificationName {
  return nil;
}

- (NSString *)deleteNotificationName {
  return nil;
}

/* actions */

- (id)saveAndGoBackWithCount:(int)_backCount {
  id result = nil;
  SEL op;
  
  if (![self checkConstraintsForSave]) {
    [self debugWithFormat:@"save contraint check failed!"];
    return nil;
  }
  
  op = self->isInNewMode ? @selector(insertObject) : @selector(updateObject);

  if ((result = [self _performOpInTransaction:op])) {
    NSString *notificationName = self->isInNewMode
      ? [self insertNotificationName]
      : [self updateNotificationName];

    ASSIGN(self->object, result);

    [[self session] transferObject:result owner:self];

    if (notificationName) {
      [self postChange:notificationName onObject:result];
    }
    return [self backWithCount:_backCount];
  }
  [self debugWithFormat:@"couldn't perform op .."];
  return nil;
}

- (id)deleteAndGoBackWithCount:(int)_backCount {
  id result = nil;

  [self setIsInWarningMode:NO];
  
  if (![self checkConstraintsForDelete])
    return nil;
  
  if (self->isInNewMode) {
    [self setErrorString:@"Cannot delete in new mode !"];
    return nil;
  }

  if ((result = [self _performOpInTransaction:@selector(deleteObject)])) {
    NSString *notificationName = [self deleteNotificationName];

    ASSIGN(self->object, result);

    if (notificationName)
      [self postChange:notificationName onObject:result];

    return [self backWithCount:_backCount];
  }
  { // handle failed delete
    NSString *tmp = [self errorString];
    
    [self _performOpInTransaction:@selector(refreshObject)];

    tmp = [tmp stringByAppendingString:[self errorString]];
    [self setErrorString:tmp];
  }

  return nil;
}

- (id)cancel {
  return (![self checkConstraintsForCancel])
    ? nil
    : [self back];
}

- (id)save {
  return [self saveAndGoBackWithCount:1];
}

- (id)delete {
  [self setWarningOkAction:@"reallyDelete"];
  [self setWarningPhrase:@"Really Delete"];
  [self setIsInWarningMode:YES];
  
  return nil;
}

- (id)reallyDelete {
  return [self deleteAndGoBackWithCount:2];
}

/* page actions */

- (id)placeInClipboard {
  [[self session] placeInClipboard:[self object]];
  return nil;
}

- (id)view {
  return [self activateObject:[self object] withVerb:@"view"];
}

- (NSString *)windowTitle {
  return self->windowTitle;
}
- (void)setWindowTitle:(NSString *)_title {
  ASSIGN(self->windowTitle, _title);
}

- (NSString *)windowTitleLabel {
  NSString *label = nil;
  NSString *title = nil;

  if ((title = [self windowTitle]) == nil)
    title = @"-- no windowtitle --";
  
  label = [[self labels] valueForKey:title];
  return (label != nil) ? label : title;
}

@end /* OGoEditorPage */

@implementation NSObject(OGoEditorPageTyping)

- (BOOL)isEditorPage {
  return NO;
}

@end /* NSObject(OGoEditorPageTyping) */

@implementation OGoEditorPage(OGoEditorPageTyping)

- (BOOL)isEditorPage {
  return YES;
}

@end /* OGoEditorPage(OGoEditorPageTyping) */

@implementation LSWEditorPage // DEPRECATED
@end /* LSWEditorPage */
