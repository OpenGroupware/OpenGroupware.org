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
// $Id: LSWMailPreferences.m 1 2004-08-20 11:17:52Z znek $

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSUserDefaults, NSMutableDictionary;

@interface LSWMailPreferences : LSWContentPage
{
  id             account;
  id             item;
  NSUserDefaults *defaults;
  BOOL           isRoot;

  id             trashFolder;
  id             sentFolder;
  id             draftsFolder;

  /* values */
  /* access */
  id                  imapContext;
  NSMutableDictionary *folders;
}

- (void)setItem:(id)_item;
- (id)item;
- (NSString *)accountEmail;

@end

#include "SkyImapContextHandler.h"
#include "LSWImapMails.h"
#include "common.h"
#include <NGExtensions/NSString+Ext.h>

@interface NSObject(MailFormattingManager)
- (NSString *)_eAddressForPerson:(id)_person;
- (NSString *)_formatEmail:(NSString *)_email forPerson:(id)_person;
@end

@implementation LSWMailPreferences

static NSArray *FieldKeys                  = nil;
static int     MailEditorUploadFieldCount  = 0;
static int     IsEpozEnabled               = -1;
static NSArray *NumberOfUploadFieldsValues = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  FieldKeys = [[ud arrayForKey:@"mail_prefs_fieldkeys"] copy];
  
  IsEpozEnabled = [ud boolForKey:@"DisableEpozEditor"] ? 0 : 1;
  
  MailEditorUploadFieldCount = 
    [ud integerForKey:@"MailEditorUploadFieldCount"];
  if (MailEditorUploadFieldCount < 1)
    MailEditorUploadFieldCount = 10;
  
  if (NumberOfUploadFieldsValues == nil) {
    NSMutableArray *ma;
    int i;
    
    ma = [[NSMutableArray alloc] initWithCapacity:MailEditorUploadFieldCount];
    for (i = 0; i < MailEditorUploadFieldCount; i++)
      [ma addObject:[[NSNumber numberWithInt:(i + 1)] stringValue]];
  
    NumberOfUploadFieldsValues = [ma copy];
    [ma release]; ma = nil;
  }
}

- (void)dealloc {
  [self->item           release];
  [self->account        release];
  [self->defaults       release];
  [self->folders        release];
  [self->imapContext    release];
  [self->trashFolder    release];
  [self->sentFolder     release];
  [self->draftsFolder   release];
  [super dealloc];
}

/* IMAP4 context */

- (id)imapContext {
  if (self->imapContext == nil) {
    self->imapContext =
      [[[SkyImapContextHandler imapContextHandlerForSession:[self session]]
			       sessionImapContext:[self session]] retain];
  }
  return self->imapContext;
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
  [self setItem:nil];
  [super sleep];
}

- (void)syncAwake {
  if (self->imapContext == nil || self->folders == nil) {
    [self->folders release]; self->folders = nil;
      
    self->folders = [[NSMutableDictionary alloc] initWithCapacity:32];
    
    [LSWImapBuildFolderDict buildFolderDictionary:self->folders
                            folder:[[[self imapContext] serverRoot] subFolders]
                            prefix:@""];
  }
  [super syncAwake];  
}

/* accessors */

- (NSString *)folder {
  NSString *newFolderName;
  NSArray  *items;
  int      i;

  newFolderName = @"";
  items         = [self->item componentsSeparatedByString:@"@ @"];
  i             = 0;

  for (; i < ([items count] - 1); i++)
    newFolderName = [newFolderName stringByAppendingString:@"-- "];
  
  return [newFolderName stringByAppendingString:[items lastObject]];
}

- (NSArray *)folderList {
  NSArray *list;
  
  list =  [self->folders allKeys];
  
  return [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)_initFolder {
  // TODO: looks broken, use ASSIGN?!
  NSString       *fName;
  
  /* trash */

  if ((fName = [self->defaults objectForKey:@"mail_trashFolderName"])) {
    [self->trashFolder release]; self->trashFolder = nil;
    self->trashFolder = [[[self imapContext] folderWithName:fName] retain];
  }
  if (self->trashFolder == nil)
    self->trashFolder = [[[self imapContext] trashFolder] retain];

  /* sent */
  
  if ((fName = [self->defaults objectForKey:@"mail_sentFolderName"])) {
    ASSIGN(self->sentFolder, nil);
    self->sentFolder = [[[self imapContext] folderWithName:fName] retain];
  }
  if (self->sentFolder == nil)
    self->sentFolder = [[[self imapContext] sentFolder] retain];

  /* drafts */
  
  if ((fName = [self->defaults objectForKey:@"mail_draftsFolderName"])) {
    ASSIGN(self->draftsFolder, nil);
    self->draftsFolder = [[[self imapContext] folderWithName:fName] retain];
  }
  if (self->draftsFolder == nil)
    self->draftsFolder = [[[self imapContext] draftsFolder] retain];
}

- (void)appendToResponse:(id)_rep inContext:(id)_ctx {
  [self _initFolder];

  if ([self->defaults valueForKey:@"mail_fromPopupList"] == nil) {
    if (![[self->account valueForKey:@"isTemplateUser"] boolValue])
      [self->defaults takeValue:[NSArray arrayWithObject:[self accountEmail]]
           forKey:@"mail_fromPopupList"];
  }
  [super appendToResponse:_rep inContext:_ctx];
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
  obj      = [self->defaults objectForKey:_defName];

  return obj ? [obj boolValue] : YES;
}

- (void)setAccount:(id)_account {
  NSUserDefaults *ud;

  ASSIGN(self->account, _account);
  [self->defaults release]; self->defaults = nil;
  
  ud = _account
    ? [self runCommand:@"userdefaults::get", @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];

  self->defaults = [ud retain];
}
- (id)account {
  return self->account;
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemLabel {
  return [[self labels] valueForKey:[self item]];
}

/* values */

- (void)setDefaults:(NSUserDefaults *)_defaults {
  ASSIGN(self->defaults, _defaults);
}
- (NSUserDefaults *)defaults {
  return self->defaults;
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)save {
  id uid, ctx;

  [self setErrorString:nil];

  uid = [[self account] valueForKey:@"companyId"];

  if ((ctx = [self imapContext])) {
    NSString *tmp;
    
    if (![[ctx sentFolder] isEqual:self->sentFolder])
      [ctx setSentFolder:self->sentFolder];

    if ([(tmp = [self->sentFolder absoluteName]) length] > 0)
      [self->defaults takeValue:tmp forKey:@"mail_sentFolderName"];
      
    if (![[ctx trashFolder] isEqual:self->trashFolder])
      [ctx setTrashFolder:self->trashFolder];

    if ([(tmp = [self->trashFolder absoluteName]) length] > 0)
      [self->defaults takeValue:tmp forKey:@"mail_trashFolderName"];

    if (![[ctx draftsFolder] isEqual:self->draftsFolder])
      [ctx setDraftsFolder:self->draftsFolder];

    if ([(tmp = [self->draftsFolder absoluteName]) length] > 0)
      [self->defaults takeValue:tmp forKey:@"mail_draftsFolderName"];
  }
  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  [self->defaults synchronize];
  
  return [self leavePage];
}

- (NSString *)sentFolder {
  return [[self->folders allKeysForObject:self->sentFolder] lastObject];
}
- (void)setSentFolder:(id)_id {
  ASSIGN(self->sentFolder, nil);
  self->sentFolder = [[self->folders objectForKey:_id] retain];
}

- (NSString *)trashFolder {
  return [[self->folders allKeysForObject:self->trashFolder] lastObject];
}

- (void)setTrashFolder:(id)_id {
  ASSIGN(self->trashFolder, nil);
  self->trashFolder = [[self->folders objectForKey:_id] retain];
}

- (NSString *)draftsFolder {
  return [[self->folders allKeysForObject:self->draftsFolder] lastObject];
}
- (void)setDraftsFolder:(id)_id {
  ASSIGN(self->draftsFolder, nil);
  self->draftsFolder = [[self->folders objectForKey:_id] retain];
}

- (BOOL)isEditSpezialFolderEnabled {
  return ([self imapContext] == nil) ? NO : YES;
}

- (NSArray *)fieldsForKey:(NSString *)_key {
  NSMutableArray *a;
  NSString *str;
  
  str = [self->defaults stringForKey:_key];
  
  if ([str length] == 0)
    return FieldKeys;
  
  if ([FieldKeys containsObject:str])
      return FieldKeys;

  a = [FieldKeys mutableCopy];
  [a insertObject:str atIndex:0];
  [a autorelease];
  return a;
}

- (NSArray *)sortedMailListBlockSizeFields {
  return [self fieldsForKey:@"SearchMailListBlockSize"];
}
- (NSArray *)mailListBlockSizeFields {
  return [self fieldsForKey:@"MailListBlockSize"];
}

- (NSArray *)numberOfUploadFieldsValues {
  return NumberOfUploadFieldsValues;
}

- (id)mailFormattingManager {
  // TODO: weird ...
  return NSClassFromString(@"LSWImapMailEditor");
}

- (NSString *)accountEmail {
  id       ac;
  NSString *str;

  ac = (self->account != nil)
     ? self->account : [[self session] activeAccount];
  
  if ((str = [[self mailFormattingManager] _eAddressForPerson:ac]) == nil)
    str = [ac valueForKey:@"login"];
  
  str = [[self mailFormattingManager] _formatEmail:str forPerson:ac];
  
  return (str == nil) ? (NSString *)@"<empty>" : str;
}

- (NSArray *)fromPopupValues {
  NSMutableArray *res;
  NSEnumerator   *enumerator;
  id             obj;
  NSString       *str;

  enumerator = [[[self->defaults valueForKey:@"mail_fromPopupInitialValues"]
                                componentsSeparatedByString:@"\n"]
                                 objectEnumerator];
  res = [NSMutableArray arrayWithCapacity:16];

  while ((obj = [enumerator nextObject])) {
    if ([[obj stringByTrimmingSpaces] length] > 0) {
      if (![res containsObject:obj])
          [res addObject:obj];
    }
  }
  if (![[self->account valueForKey:@"isTemplateUser"] boolValue]) {
    str = [self accountEmail];
    if (![res containsObject:str])
      [res insertObject:str atIndex:0];
  }
  return res;
}

- (BOOL)useEpozMailEditorEnabled {
  return IsEpozEnabled ? YES : NO;
}

- (BOOL)isFromPopupEnabled {
  return ([self isRoot] ||
          [self->defaults boolForKey:@"isEditable_mail_fromPopupList"]);
}

@end /* LSWMailPreferences */
