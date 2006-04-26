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

#include "LSWImapMailFilterEditor.h"
#include "LSWImapMailFilterManager.h"
#include <OGoWebMail/LSWImapBuildFolderDict.h>
#include "common.h"

@interface NSObject(LSWImapMailFilterEditor)
- (NSString *)password;
@end

@interface LSWImapMailFilterEditor(Private)
- (NSArray *)folderList;
- (NSString *)folderString;
- (void)exportFilter;
- (void)launchInstallSieve;
@end

@implementation LSWImapMailFilterEditor

static NSArray      *andOrList = nil;
static BOOL         reuseOGoLoginForMailServer   = NO;
static NSArray      *OGoFilterEditor_FilterKinds = nil;
static NSArray      *OGoFilterEditor_Fields      = nil;
static NSDictionary *OGoFilterEditor_FieldLabels = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (andOrList == nil)
    andOrList = [[NSArray alloc] initWithObjects:@"and", @"or", nil];

  reuseOGoLoginForMailServer = [ud boolForKey:@"UseSkyrixLoginForImap"];
  
  OGoFilterEditor_FilterKinds =
    [[ud arrayForKey:@"OGoFilterEditor_FilterKinds"] copy];
  OGoFilterEditor_Fields =
    [[ud arrayForKey:@"OGoFilterEditor_Fields"] copy];
  OGoFilterEditor_FieldLabels =
    [[ud dictionaryForKey:@"OGoFilterEditor_FieldLabels"] copy];
  
  if (![OGoFilterEditor_Fields isNotEmpty])
    NSLog(@"ERROR: missing OGoFilterEditor_Fields default!");
  if (![OGoFilterEditor_FilterKinds isNotEmpty])
    NSLog(@"ERROR: missing OGoFilterEditor_FilterKinds default!");
}

- (id)init {
  if ((self = [super init]) != nil) {
    id account;
    
    // TODO: not really a good idea to access a session in -init (awake?)
    account = [[self session] activeAccount];
    
    self->isInNewMode = NO;
    self->matchList   = andOrList;
    self->filters     =
      [[LSWImapMailFilterManager filterForUser:account] mutableCopy];
    self->action = Action_Move;
  }
  return self;
}

- (void)dealloc {
  [self->filter     release];
  [self->filters    release];
  [self->entry      release];
  [self->item       release];
  [self->filterPos  release];
  [self->matchList  release];
  [self->folders    release];
  [self->rootFolder release];
  [self->password   release];
  [super dealloc];
}

/* accessors */

- (void)setSelectionForward:(BOOL)_b {
  if (_b) self->action = Action_Forward;
}
- (BOOL)selectionForward {
  return (self->action == Action_Forward) ? YES : NO;
}

- (void)setSelectionMove:(BOOL)_b {
  if (_b) self->action = Action_Move;
}
- (BOOL)selectionMove {
  return (self->action == Action_Move) ? YES : NO;
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self existingSession] userDefaults];
}
- (NSString *)defaultMailServerPassword {
  return [[self userDefaults] stringForKey:@"imap_passwd"];
}

- (NSArray *)filterFieldKeys {
  return OGoFilterEditor_Fields;
}
- (NSArray *)filterKinds {
  return OGoFilterEditor_FilterKinds;
}

/* context */

- (NSString *)passwordStoredInSession {
  return [[[self existingSession] commandContext] 
	         valueForKey:@"LSUser_P_W_D_Key"];
}
- (id)activeAccount {
  return [[self existingSession] activeAccount];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  
  [self setErrorString:nil];
  
  if (self->folders == nil) {
    self->folders = [[NSMutableDictionary alloc] initWithCapacity:32];
    if (self->rootFolder) {
      [LSWImapBuildFolderDict buildFolderDictionary:self->folders
                              folder:[NSArray arrayWithObject:self->rootFolder]
                              prefix:@""];
    }
  }
  
  /* setup password */
  
  [self->password release]; self->password = nil;
  
  if (reuseOGoLoginForMailServer)
    self->password = [[self passwordStoredInSession] copy];
  else if (self->password == nil || [self->password length] == 0)
    self->password = [[self defaultMailServerPassword] copy];
}

/* activation */

- (void)_prepareNewCommand {
  self->action       = Action_Move;
  self->oldFilterPos = -1;
  self->isInNewMode  = YES;
  
  self->filter = [[NSMutableDictionary alloc] initWithCapacity:16];
  [self->filter setObject:[NSNumber numberWithInt:0] forKey:@"filterPos"];
  [self->filter setObject:@"<no entry>" forKey:@"name"];
  [self->filter setObject:@"and" forKey:@"match"];
}

- (void)_prepareEditCommand {
  NSDictionary *filterEntry;
  
  filterEntry = [[self existingSession] getTransferObject];
  self->isInNewMode  = NO;
  self->filter       = [[filterEntry objectForKey:@"filter"] mutableCopy];
  self->oldFilterPos = [[self->filter objectForKey:@"filterPos"] intValue];

  self->action = ([[self->filter objectForKey:@"folder"] length] > 0)
    ? Action_Move : Action_Forward;
  
  NSAssert((self->filter != nil), @"no selected filter was set");
}

- (void)_preprocessActivationFilterEntries {
    NSMutableArray *entries = nil;

    entries = [self->filter objectForKey:@"entries"];
    
    if (entries == nil) {
      entries = [NSMutableArray arrayWithCapacity:16];
      [entries addObject:[NSMutableDictionary dictionaryWithCapacity:8]];
      [self->filter setObject:entries forKey:@"entries"];
    }
    else {
      entries = [[entries mutableCopy] autorelease];
      [self->filter setObject:entries forKey:@"entries"];
      if ([entries count] == 0) {
        [entries addObject:[NSMutableDictionary dictionaryWithCapacity:8]];
      }
    }
}

- (void)_preprocessFilterPosition {
  unsigned cnt = 0, length = 0;
  
  [self->filterPos release]; self->filterPos = nil;
  
  self->filterPos = [[NSMutableArray alloc] initWithCapacity:64];
  
  for (length = [self->filters count], cnt = 0; cnt < length; cnt++)
    [self->filterPos addObject:[NSNumber numberWithInt:cnt]];
  
  if (self->isInNewMode)
    [self->filterPos addObject:[NSNumber numberWithInt:cnt]];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  [self->filter release]; self->filter = nil;
  
  if ([_command hasPrefix:@"new"])
    [self _prepareNewCommand];
  else if ([_command hasPrefix:@"edit"])
    [self _prepareEditCommand];
  
  [self _preprocessActivationFilterEntries];
  [self _preprocessFilterPosition];
  
  return YES;
}

/* accessors */

- (BOOL)forbidfewer {
  return ([[self->filter objectForKey:@"entries"] count] < 2) ? YES : NO;
}

- (BOOL)isSaveDisabled {
  return NO;
}

- (BOOL)isDeleteDisabled {
  return self->isInNewMode;
}

- (BOOL)isEditorPage {
  return YES;
}

- (NSString *)matchSuffix {
  NSString *result = [[self labels] valueForKey:self->item];
  return (result != nil) ? result : (NSString *)self->item;
}

- (NSString *)mailHeaderLabel {
  NSString *result;

  /*
    The user has specified an own filter label configuration. Either a simple:
      { "x-spam-status" = "Spam-Status"; }
    or a localized variant:
      {
        English = {
	  "x-spam-status" = "Spam-Status";
        };
        German = {
	  "x-spam-status" = "Spamwert";
        };
      }
    the latter is checked first.
  */
  if (OGoFilterEditor_FieldLabels != nil) {
    /* first check for the language */
    if ((result = [[self existingSession] primaryLanguage]) != nil) {
      NSDictionary *keyToLabel;
      NSRange r;
      
      r = [result rangeOfString:@"_"];
      if (r.length > 0) result = [result substringToIndex:r.location];
      keyToLabel = [OGoFilterEditor_FieldLabels objectForKey:result];
      
      if ((result = [keyToLabel objectForKey:self->item]) != nil)
	/* found a localized custom label */
	return result;
    }
    
    /* next check for the key directly (customized but not localized) */
    if ((result = [OGoFilterEditor_FieldLabels objectForKey:self->item])!=nil)
      return result;
  }
  
  /* now check the regular labels system for standard translations */
  result = [[self labels] valueForKey:self->item];
  return (result != nil) ? result : (NSString *)self->item;
}

- (NSString *)filterKindLabel {
  NSString *result = [[self labels] valueForKey:self->item];
  return (result != nil) ? result : (NSString *)self->item;
}

- (NSString *)theLabel {
  NSString *match;
  
  match = [self->filter objectForKey:@"match"];
  if (self->index == 0)
    return [[self labels] valueForKey:@"the"];

  if ([match isEqual:@"or"])
    return [[self labels] valueForKey:@"orThe"];
  
  return [[self labels] valueForKey:@"andThe"];
}

- (void)setPassword:(NSString *)_pwd {
  /* Note: do not use ASSIGNCOPY for passwords */
  ASSIGN(self->password, _pwd);
}
- (NSString *)password {
  return self->password;
}

- (BOOL)hasPassword {
  return [self->password isNotEmpty];
}

/* actions */

- (id)more {
  [[self->filter objectForKey:@"entries"]
                 addObject:[NSMutableDictionary dictionaryWithCapacity:8]];
  return nil;
}

- (id)fewer {
  if (![self forbidfewer])
    [[self->filter objectForKey:@"entries"] removeLastObject];
  
  return nil;
}

- (id)save {
  /* TODO: split up this big method */
  int            i, cnt, pos;
  NSMutableArray *entries;
  NSEnumerator   *enumerator;
  NSDictionary   *obj;
  id             la;

  la = [self labels];

  if (![self->password isNotEmpty]) {
    [self setErrorString:[la valueForKey:@"missing password"]];
    return nil;
  }
  if (self->action == Action_Forward) {
    if (![[self->filter objectForKey:@"forwardAddress"] isNotEmpty]) {
      [self setErrorString:[la valueForKey:@"missing forward address"]];
      return nil;
    }
    [self->filter removeObjectForKey:@"folder"];
  }
  else {
    [self->filter removeObjectForKey:@"forwardAddress"];
    if ([[self->filter objectForKey:@"folder"]
                       rangeOfString:@"/"].length == 0) {
      [self setErrorString:[la valueForKey:@"missing folder to move"]];
      return nil;
    }
  }
  
  enumerator = [[self->filter objectForKey:@"entries"] objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ([[obj objectForKey:@"string"] isNotEmpty])
      break;
  }
  if (obj == nil) {
    NSString *s;

    // TODO: replace with proper label!
    s = [la valueForKey:@"missing conditional for selecting message"];
    [self setErrorString:s];
    return nil;
  }
  if (self->oldFilterPos != -1)
    [self->filters removeObjectAtIndex:self->oldFilterPos];

  if ([self->filter valueForKey:@"name"] == nil)
    [self->filter setObject:@"<no entry>" forKey:@"name"];
  
  entries = [self->filter objectForKey:@"entries"];
  for (i = 0, cnt = [entries count]; i < cnt; i++) {
    if ([[entries objectAtIndex:i] valueForKey:@"string"] != nil)
      continue;

    [entries removeObjectAtIndex:i];
    i--;
    cnt--;
  }
  
  pos = [[self->filter valueForKey:@"filterPos"] intValue];

  if (pos > [self->filters count] - 1)
    [self->filters addObject:self->filter];
  else
    [self->filters insertObject:self->filter atIndex:pos];

  /* setpos */
  for (i = 0, cnt = [self->filters count]; i < cnt; i++) {
    NSNumber *n;
    
    n = [NSNumber numberWithInt:i];
    [(NSMutableDictionary *)[self->filters objectAtIndex:i] 
                                           setObject:n forKey:@"filterPos"];
  }
  [LSWImapMailFilterManager writeFilter:self->filters 
			    forUser:[self activeAccount]];
  [self exportFilter];
  return nil;
}

- (id)delete {
  int            i, cnt;
  NSMutableArray *allF  = nil;

  if (![self->password isNotEmpty]) {
    [self setErrorString:[[self labels] valueForKey:@"missing password"]];
    return nil;
  }

  allF = [[self->filters mutableCopy] autorelease];
  
  [allF removeObjectAtIndex:self->oldFilterPos];
  for (i = 0, cnt = [allF count]; i < cnt; i++) {
    NSNumber *n;
    
    n = [NSNumber numberWithInt:i];
    [(NSMutableDictionary *)[allF objectAtIndex:i] 
                            setObject:n forKey:@"filterPos"];
  }
  [LSWImapMailFilterManager writeFilter:allF
                            forUser:[[self session] activeAccount]];
  [self exportFilter];
  return nil;
}

- (id)cancel {
  [self leavePage];
  return nil;
}


/* Folder copied from LSWMailMove */

- (NSArray *)folderList {
  NSArray *list =  [self->folders allKeys];
  return [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *)folderString {
  NSString *newFolderName;
  NSArray  *items;
  unsigned i;
  
  items = [self->item componentsSeparatedByString:@"@ @"];
  for (i = 0, newFolderName = @""; i < [items count] - 1; i++)
    newFolderName = [newFolderName stringByAppendingString:@"-- "];
  
  return [newFolderName stringByAppendingString:[items lastObject]];
}

- (void)setFilterFolder:(NSString *)_name {
  NSString *folderName;
  
  if ((folderName = [[self->folders objectForKey:_name] absoluteName]) != nil)
    [self->filter setObject:folderName forKey:@"folder"];
}

- (void)setFolderForFilter:(NGImap4Folder *)_folder {
  NSString *folderName;

  if ((folderName = [_folder absoluteName]) != nil)
    [self->filter setObject:folderName forKey:@"folder"];
}

- (id)filterFolder {
  id           folderName, obj;
  NSEnumerator *enumerator;
  
  if ((folderName = [self->filter objectForKey:@"folder"]) == nil)
    return nil;
  
  enumerator = [self->folders keyEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ([[[self->folders objectForKey:obj] absoluteName]
                         isEqualToString:folderName]) {
      return obj;
    }
  }
  return nil;
}

// TODO: we should properly type those object parameters

- (void)setFilter:(id)_id {
  ASSIGN(self->filter,    _id);
}
- (void)setEntry:(id)_id {
  ASSIGN(self->entry,     _id);
}
- (void)setFilterPos:(id)_id {
  ASSIGN(self->filterPos, _id);
}
- (void)setItem:(id)_id {
  ASSIGN(self->item,      _id);
}
- (void)setMatchList:(id)_id {
  ASSIGN(self->matchList, _id);
}
- (void)setFolders:(id)_id {
  ASSIGN(self->folders,   _id);
}
- (void)setFolder:(id)_id {
  ASSIGN(self->folder,    _id);
}
- (void)setIndex:(int)_index {
  self->index = _index;
}
- (void)setRootFolder:(NGImap4Folder *)_folder {
  ASSIGN(self->rootFolder, _folder);
}
 
- (id)filter    {
  return self->filter;
}
- (id)entry     {
  return self->entry;
}
- (id)filterPos {
  return self->filterPos;
}
- (id)item      {
  return self->item;
}
- (id)matchList {
  return self->matchList;
}
- (id)folders   {
  return self->folders;
}
- (id)folder    {
  return self->folder;
}
- (int)index    {
  return self->index;
}
- (NGImap4Folder *)rootFolder {
  return self->rootFolder;
}

- (void)exportFilter {
  [self setErrorString:nil];
  [LSWImapMailFilterManager exportFilterWithSession:[self session]
                            pwd:self->password
                            page:self];
  if (![[self errorString] isNotEmpty]) {
    [self postChange:@"LSWImapFilterChanged" onObject:nil];
    [self leavePage];
  }
}

@end /* LSWImapMailFilterEditor */
