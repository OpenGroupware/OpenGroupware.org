/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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
  id             account;
  NSUserDefaults *defaults;

  NSString       *formletterKind;
  NSNumber       *blockSize;
  NSString       *clipboardFormat;
#if WITH_PRINTLIST_CONFIG
  NSArray        *personPrintList;
  NSArray        *enterprisePrintList;
#endif
  
  BOOL           isBlockSizeEditable;
  BOOL           isRoot;
  BOOL           isFormletterKindEditable;
  BOOL           isClipboardFormatEditable;

#if WITH_PRINTLIST_CONFIG
  /* transient */
  NSString       *currentColumn;
  int            currentColumnIndex;
  NSString       *currentColumnOpt;
#endif
}

@end

#include <OGoFoundation/LSWNotifications.h>
#include "common.h"
#include <NGObjWeb/WEClientCapabilities.h>

@implementation LSWAddressPreferences

static NSNumber *yes = nil, *no = nil;

+ (void)initialize {
  if (yes == nil) yes = [[NSNumber numberWithBool:YES] retain];
  if (no  == nil) no  = [[NSNumber numberWithBool:NO]  retain];
}

- (void)dealloc {
#if WITH_PRINTLIST_CONFIG
  [self->currentColumn       release];
  [self->currentColumnOpt    release];
  [self->personPrintList     release];
  [self->enterprisePrintList release];
#endif
  [self->account             release];
  [self->defaults            release];
  [self->blockSize           release];
  [self->formletterKind      release];
  [self->clipboardFormat     release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
#if WITH_PRINTLIST_CONFIG
  [self->currentColumnOpt release]; self->currentColumnOpt = nil;
  [self->currentColumn    release]; self->currentColumn    = nil;
#endif
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

- (void)resetDefaults {
#if WITH_PRINTLIST_CONFIG
  [self->personPrintList     release]; self->personPrintList     = nil;
  [self->enterprisePrintList release]; self->enterprisePrintList = nil;
#endif
  [self->defaults            release]; self->defaults            = nil;
  [self->formletterKind      release]; self->formletterKind      = nil;
  [self->blockSize           release]; self->blockSize           = nil;
  [self->clipboardFormat     release]; self->clipboardFormat     = nil;
}

- (void)loadDefaults:(NSUserDefaults *)_ud {
#if WITH_PRINTLIST_CONFIG
  NSArray  *a;
#endif
  NSString *s;
  
  self->formletterKind = [[_ud stringForKey:@"formletter_kind"] copy];
  self->blockSize      = [[_ud objectForKey:@"address_blocksize"] copy];
  
  s = [_ud stringForKey:@"address_clipboard_format"];
  s = [s stringByReplacingString:@"\\r\\n" withString:@"\n"];
  self->clipboardFormat = [s copy];
  
#if WITH_PRINTLIST_CONFIG
  /* print lists */
  
  if (![(a = [_ud arrayForKey:@"person_printlist"]) isNotEmpty])
    a = [_ud arrayForKey:@"person_defaultprintlist"];
  self->personPrintList = [a copy];
  
  if (![(a = [_ud arrayForKey:@"enterprise_printlist"]) isNotEmpty])
    a = [_ud arrayForKey:@"enterprise_defaultprintlist"];
  self->enterprisePrintList = [a copy];
#endif
  
  /* permissions */
  self->isBlockSizeEditable         = [self _isEditable:@"address_blocksize"];
  self->isFormletterKindEditable    = [self _isEditable:@"formletter_kind"];
  self->isClipboardFormatEditable   =
    [self _isEditable:@"address_clipboard_format"];
}

- (void)setAccount:(id)_account {
  NSUserDefaults *ud;
  
  [self resetDefaults];
  
  ASSIGN(self->account, _account);
  
  ud = (_account != nil)
    ? [self runCommand:@"userdefaults::get", @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];
  
  self->defaults = [ud retain];
  [self loadDefaults:self->defaults];
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
  ASSIGNCOPY(self->blockSize, _number);
}
- (NSNumber *)blockSize {
  return self->blockSize;
}

- (void)setClipboardFormat:(NSString *)_format {
  ASSIGNCOPY(self->clipboardFormat,_format);
}
- (NSString *)clipboardFormat {
  return self->clipboardFormat;
}
  
- (void)setFormletterKind:(NSString *)_formletterKind {
  ASSIGNCOPY(self->formletterKind, _formletterKind);
}
- (NSString *)formletterKind {
  return self->formletterKind;
}

#if WITH_PRINTLIST_CONFIG
/* print lists */

- (void)setCurrentColumn:(NSString *)_s {
  ASSIGNCOPY(self->currentColumn, _s);
}
- (NSString *)currentColumn {
  return self->currentColumn;
}

- (void)setCurrentColumnIndex:(int)_idx {
  self->currentColumnIndex = _idx;
}
- (int)currentColumnIndex {
  return self->currentColumnIndex;
}
- (int)columnIndexPlusOne {
  /* we start at 0 */
  return [self currentColumnIndex] + 1;
}

- (void)setCurrentColumnOpt:(NSString *)_s {
  ASSIGNCOPY(self->currentColumnOpt, _s);
}
- (NSString *)currentColumnOpt {
  return self->currentColumnOpt;
}

- (NSString *)currentPersonColumnOptLabel {
  return [[self resourceManager] stringForKey:[self currentColumnOpt]
				 inTableNamed:@"PersonsUI"
				 withDefaultValue:[self currentColumnOpt]
				 languages:[[self session] languages]];
}
- (NSString *)currentEnterpriseColumnOptLabel {
  return [[self resourceManager] stringForKey:[self currentColumnOpt]
				 inTableNamed:@"EnterprisesUI"
				 withDefaultValue:[self currentColumnOpt]
				 languages:[[self session] languages]];
}

- (NSArray *)personPrintList {
  return self->personPrintList;
}
- (NSArray *)enterprisePrintList {
  return self->enterprisePrintList;
}

- (NSArray *)personConfigOptList {
  static NSArray *configOptList = nil;
  if (configOptList == nil) {
    configOptList = [[[NSUserDefaults standardUserDefaults] 
		       arrayForKey:@"person_defaultlist_opts"] copy];
  }
  return configOptList;
}
- (NSArray *)enterpriseConfigOptList {
  static NSArray *configOptList = nil;
  if (configOptList == nil) {
    configOptList = [[[NSUserDefaults standardUserDefaults] 
		       arrayForKey:@"enterprise_defaultlist_opts"] copy];
  }
  return configOptList;
}

- (NSString *)currentPersonColumnCheckerName {
  return [NSString stringWithFormat:@"pcb%i", [self currentColumnIndex]];
}
- (NSString *)currentEnterpriseColumnCheckerName {
  return [NSString stringWithFormat:@"ecb%i", [self currentColumnIndex]];
}

- (void)setCurrentPersonColumnSelection:(NSString *)_newValue {
  NSMutableArray *ma;
  
  if (![_newValue isNotEmpty])
    return;
  if ([_newValue isEqualToString:[self currentColumn]])
    return; /* didn't change */
  
  /* changed */
  ma = [self->personPrintList mutableCopy];
  [ma replaceObjectAtIndex:[self currentColumnIndex] withObject:_newValue];
  [self->personPrintList release]; self->personPrintList = nil;
  self->personPrintList = [ma copy];
  [ma release]; ma = nil;
}
- (NSString *)currentPersonColumnSelection {
  return [self currentColumn];
}

- (void)setCurrentEnterpriseColumnSelection:(NSString *)_newValue {
  NSMutableArray *ma;
  
  if (![_newValue isNotEmpty])
    return;
  if ([_newValue isEqualToString:[self currentColumn]])
    return; /* didn't change */
  
  /* changed */
  ma = [self->enterprisePrintList mutableCopy];
  [ma replaceObjectAtIndex:[self currentColumnIndex] withObject:_newValue];
  [self->enterprisePrintList release]; self->enterprisePrintList = nil;
  self->enterprisePrintList = [ma copy];
  [ma release]; ma = nil;
}
- (NSString *)currentEnterpriseColumnSelection {
  return [self currentColumn];
}

- (id)addColumnToList:(NSArray **)_list default:(NSString *)_def {
  NSArray *cfglist;
  
  cfglist = [*_list arrayByAddingObject:_def];
  [*_list release]; *_list = nil;
  *_list = [cfglist copy];
  
  return nil; /* stay on page */
}
- (id)removeColumnFromList:(NSArray **)_list {
  NSMutableArray *cfglist;
  
  cfglist = [*_list mutableCopy];
  [*_list release]; *_list = nil;
  
  if ([cfglist isNotEmpty])
    [cfglist removeObjectAtIndex:([cfglist count] - 1)];
  
  *_list = [cfglist copy];
  [cfglist release]; cfglist = nil;
  
  return nil; /* stay on page */
}

- (id)addPersonColumn {
  return [self addColumnToList:&(self->personPrintList) default:@"name"];
}
- (id)addEnterpriseColumn {
  return [self addColumnToList:&(self->enterprisePrintList) default:@"name"];
}

- (id)removePersonColumn {
  return [self removeColumnFromList:&(self->personPrintList)];
}
- (id)removeEnterpriseColumn {
  return [self removeColumnFromList:&(self->enterprisePrintList)];
}
#endif

/* operations */

- (BOOL)_writeDefault:(NSString *)_name value:(id)_value {
  NSNumber *uid;
  
  if (![(uid = [[self account] valueForKey:@"companyId"]) isNotNull])
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

#if WITH_PRINTLIST_CONFIG
  if ([self->personPrintList isNotEmpty])
    [self _writeDefault:@"person_printlist" value:self->personPrintList];
  if ([self->enterprisePrintList isNotEmpty]) {
    [self _writeDefault:@"enterprise_printlist" 
	  value:self->enterprisePrintList];
  }
#endif
  
  if (self->isRoot) {
    [self _writeDefault:@"rootAccessformletter_kind"
          value:self->isFormletterKindEditable ? yes : no];
  }
  
  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  [[[self session] userDefaults] synchronize];

  return [self leavePage];
}

@end /* LSWAddressPreferences */
