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

#include <OGoFoundation/OGoContentPage.h>

@class NSString, NSNumber, NSUserDefaults;

@interface LSWAddressPreferences : OGoContentPage
{
  id              account;
  NSUserDefaults* defaults;

  NSString        *enterpriseSubView;
  NSString        *personsSubView;
  NSString        *formletterKind;
  NSNumber        *blockSize;
  NSString        *clipboardFormat;
  
  BOOL            isEnterpriseSubviewEditable;
  BOOL            isBlockSizeEditable;
  BOOL            isPersonsSubviewEditable;
  BOOL            isRoot;
  BOOL            isFormletterKindEditable;
  BOOL            isClipboardFormatEditable;
}

@end

#include <OGoFoundation/LSWNotifications.h>
#include "common.h"
#include <NGObjWeb/WEClientCapabilities.h>

@implementation LSWAddressPreferences

static NSNumber *yes = nil, *no = nil;

+ (void)initialize {
  yes = [[NSNumber numberWithBool:YES] retain];
  no  = [[NSNumber numberWithBool:NO]  retain];
}

- (void)dealloc {
  [self->account           release];
  [self->defaults          release];
  [self->enterpriseSubView release];
  [self->blockSize         release];
  [self->formletterKind    release];
  [self->personsSubView    release];
  [self->clipboardFormat   release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
  [super sleep];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

- (BOOL)isRoot {
  return self->isRoot;
}

- (BOOL)_isEditable:(NSString *)_defName {
  id obj;

  _defName = [@"rootAccess" stringByAppendingString:_defName];
  obj = [self->defaults objectForKey:_defName];

  return obj ? [obj boolValue] : YES;
}

- (void)setAccount:(id)_account {
  NSUserDefaults *ud;

  [self->defaults          release]; self->defaults          = nil;
  [self->enterpriseSubView release]; self->enterpriseSubView = nil;
  [self->personsSubView    release]; self->personsSubView    = nil;
  [self->formletterKind    release]; self->formletterKind    = nil;
  [self->blockSize         release]; self->blockSize         = nil;
  [self->clipboardFormat   release]; self->clipboardFormat   = nil;

  ASSIGN(self->account, _account);

  ud = _account
    ? [self runCommand:@"userdefaults::get",
            @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];

  self->defaults = RETAIN(ud);
 
  self->formletterKind =
    [[self->defaults stringForKey:@"formletter_kind"] copy];
  self->personsSubView =
    [[self->defaults stringForKey:@"persons_sub_view"] copy];
  self->enterpriseSubView =
    [[self->defaults stringForKey:@"enterprise_sub_view"] copy];
  self->blockSize = [[self->defaults objectForKey:@"address_blocksize"] copy];
  
  self->clipboardFormat =
    [self->defaults stringForKey:@"address_clipboard_format"];
  self->clipboardFormat =
    [[[self->clipboardFormat componentsSeparatedByString:@"\\r\\n"]
                             componentsJoinedByString:@"\n"]
                             copy];
  
  self->isBlockSizeEditable         = [self _isEditable:@"address_blocksize"];
  self->isFormletterKindEditable    = [self _isEditable:@"formletter_kind"];
  self->isPersonsSubviewEditable    = [self _isEditable:@"persons_sub_view"];
  self->isEnterpriseSubviewEditable =[self _isEditable:@"enterprise_sub_view"];
  self->isClipboardFormatEditable   =
    [self _isEditable:@"address_clipboard_format"];
}

- (id)account {
  return self->account;
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (BOOL)isBlockSizeEditable {
  return self->isBlockSizeEditable || self->isRoot;
}

- (void)setIsBlockSizeEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isBlockSizeEditable = _flag;
  }
}

- (BOOL)hasClipboard {
  WEClientCapabilities *ccaps;
  ccaps = [[[self context] request] clientCapabilities];
  if (![ccaps isInternetExplorer]) return NO;
  if ([ccaps isMacBrowser]) return NO;
  return YES;
}
- (BOOL)isClipboardFormatEditable {
  return self->isClipboardFormatEditable || self->isRoot;
}
- (void)setIsClipboardFormatEditable:(BOOL)_flag {
  if (self->isRoot) self->isClipboardFormatEditable = _flag;
}

- (BOOL)isPersonsSubviewEditable {
  return self->isPersonsSubviewEditable || self->isRoot;
}
- (void)setIsPersonsSubviewEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isPersonsSubviewEditable = _flag;
  }
}

- (BOOL)isEnterpriseSubviewEditable {
  return self->isEnterpriseSubviewEditable || self->isRoot;
}
- (void)setIsEnterpriseSubviewEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isEnterpriseSubviewEditable = _flag;
  }
}

- (BOOL)isFormletterKindEditable {
  return self->isFormletterKindEditable || self->isRoot;
}
- (BOOL)isFormletterKindEditableRoot {
  return self->isFormletterKindEditable;
}
- (void)setIsFormletterKindEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isFormletterKindEditable = _flag;
  }
}

- (void)setBlockSize:(NSNumber *)_number {
  ASSIGN(self->blockSize, _number);
}
- (NSNumber *)blockSize {
  return self->blockSize;
}

- (void)setClipboardFormat:(NSString *)_format {
  ASSIGN(self->clipboardFormat,_format);
}
- (NSString *)clipboardFormat {
  return self->clipboardFormat;
}
  
- (void)setPersons_sub_view:(NSString *)_subview {
  ASSIGN(self->personsSubView, _subview);
}
- (NSString *)persons_sub_view {
  return self->personsSubView;
}

- (void)setEnterprise_sub_view:(NSString *)_subview {
  ASSIGN(self->enterpriseSubView, _subview);
}
- (NSString *)enterprise_sub_view {
  return self->enterpriseSubView;
}

- (void)setFormletterKind:(NSString *)_formletterKind {
  ASSIGN(self->formletterKind, _formletterKind);
}
- (NSString *)formletterKind {
  return self->formletterKind;
}

/* operations */

- (BOOL)_writeDefault:(NSString *)_name value:(id)_value {
  NSNumber *uid;
  
  if ((uid = [[self account] valueForKey:@"companyId"]) == nil)
    return NO;

  [self runCommand:@"userdefaults::write",
          @"key", _name, @"value", _value, @"defaults", self->defaults,
          @"userId",   uid, nil];
  return YES;
}

/* actions */

- (id)cancel {
  return [self leavePage];
}

- (id)save {
  id uid;

  uid = [[self account] valueForKey:@"companyId"];

#if 0 // TODO: hh asks: why is that?
  if ([self isPersonsSubviewEditable])
    [self _writeDefault:@"persons_sub_view" value:[self persons_sub_view]];

  if ([self isEnterpriseSubviewEditable]) {
    [self _writeDefault:@"enterprise_sub_view" 
          value:[self enterprise_sub_view]];
  }
#endif
  if ([self isClipboardFormatEditable]) {
    id tmp = [[[self clipboardFormat] componentsSeparatedByString:@"\r\n"]
                     componentsJoinedByString:@"\n"];
    tmp = [[tmp componentsSeparatedByString:@"\n"]
                componentsJoinedByString:@"\\r\\n"];

    [self _writeDefault:@"address_clipboard_format" value:tmp];
  }

  if ([self isBlockSizeEditable])
    [self _writeDefault:@"address_blocksize" value:[self blockSize]];
  
  if ([self isFormletterKindEditable])
    [self _writeDefault:@"formletter_kind" value:[self formletterKind]];

  if (self->isRoot) {
    [self _writeDefault:@"rootAccessformletter_kind"
          value:self->isFormletterKindEditable ? yes : no];
  }
  
  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  [[[self session] userDefaults] synchronize];

  return [self leavePage];
}

@end /* LSWAddressPreferences */
