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

#import "common.h"
#import "LSWTextDocumentEditor.h"

@implementation LSWTextDocumentEditor

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->fileContent);
  RELEASE(self->parentFolder);
  RELEASE(self->project);
  RELEASE(self->doc);
  [super dealloc];
}
#endif

- (void)clearEditor {
  RELEASE(self->fileContent);  self->fileContent  = nil;
  RELEASE(self->parentFolder); self->parentFolder = nil;
  RELEASE(self->project);      self->project      = nil;
  RELEASE(self->doc);          self->doc          = nil;
  [super clearEditor];
}

- (BOOL)prepareForNewCommand:(NSString *)_command type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSDictionary *binding;
  
  binding = [[[self session] userDefaults]
                            dictionaryForKey:@"SkyNewDocumentBindings"];

  if (binding) {
    NSCalendarDate      *today;
    NSMutableDictionary *snp;
    NSArray             *bindings;
    int i, cnt;

    bindings = [binding allKeys];
    snp      = [self snapshot];
    today    = [NSCalendarDate date];
    [today setTimeZone:[[self session] timeZone]];
    
    for (i = 0, cnt = [bindings count]; i < cnt; i++) {
      NSString *value;
      NSString *key;

      key   = [bindings objectAtIndex:i];
      value = [binding valueForKey:key];

      if ([key isEqualToString:@"title"])    key = @"abstract";
      if ([key isEqualToString:@"fileName"]) key = @"title";
      
      if ([value hasPrefix:@"%"]) 
        value = [today descriptionWithCalendarFormat:value];
      
      [snp setObject:value forKey:key];
    }
  }
  self->fileContent = [[NSMutableString alloc] init];

  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id       obj       = [self object]; 
  id       pj        = [obj valueForKey:@"project"];
  NSString *fileName = [obj valueForKey:@"attachmentName"];

  if (pj != nil) {
    ASSIGN(self->project, pj);
  }
      
  self->fileContent = [NSString stringWithContentsOfFile:fileName];
  RETAIN(self->fileContent);

  self->wasReleased = [[obj valueForKey:@"wasReleased"] boolValue];
  [obj removeObjectForKey:@"wasReleased"];

  {
    id d = [obj valueForKey:@"toDoc"];

    ASSIGN(self->doc, d);
  }

  if ([[self->doc valueForKey:@"isIndexDoc"] boolValue]) {
    self->autoRelease = YES;
  }
  
  return YES;
}

// accessors

- (BOOL)autoRelease {
  return self->autoRelease;
}
- (void)setAutoRelease:(BOOL)_autoRelease {
  self->autoRelease = _autoRelease;
}

- (void)setProject:(id)_project { 
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setParentFolder:(id)_folder { 
  ASSIGN(self->parentFolder, _folder);
}
- (id)parentFolder {
  return self->parentFolder;
}
- (NSMutableDictionary *)document {
  return [self snapshot];
}

- (void)setFileContent:(NSString *)_fileContent {
  if (self->fileContent != _fileContent) {
    RELEASE(self->fileContent); self->fileContent = nil;
    self->fileContent = [_fileContent copyWithZone:[self zone]];
  }
}
- (NSString *)fileContent {
  return self->fileContent;
}

- (BOOL)isContactAttrEnabled {
  return [[[self session] userDefaults]
                 boolForKey:@"SkyEnableContactAttrInDocuments"];
}

- (NSString *)insertNotificationName {
  return LSWNewTextDocumentNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedTextDocumentNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedTextDocumentNotificationName;
}

// actions

- (BOOL)checkConstraints {
  NSMutableString *error  = [NSMutableString stringWithCapacity:128];
  NSString        *pTitle = [[self snapshot] valueForKey:@"title"];
  
  if (![pTitle isNotNull] || [pTitle length] == 0)
    [error appendString:@" No document title set."];

  if ([error length] > 0) {
    [self setErrorString:error];
    return YES;
  }
  else {
    [self setErrorString:nil];
    return NO;
  }
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

- (id)insertObject {
  int      flength  = 0;
  id       document = [self snapshot];
  NSNumber *aRel    = [NSNumber numberWithBool:self->autoRelease];
  
  if (![self->fileContent isNotNull]) self->fileContent = @"";

  flength = [self->fileContent length];
  
  [document takeValue:aRel                             forKey:@"autoRelease"];
  [document takeValue:self->fileContent                forKey:@"fileContent"];
  [document takeValue:[NSNumber numberWithBool:NO]     forKey:@"isFolder"];
  [document takeValue:self->parentFolder               forKey:@"folder"];
  [document takeValue:self->project                    forKey:@"project"];
  [document takeValue:[NSNumber numberWithInt:flength] forKey:@"fileSize"];
  
  return [self runCommand:@"doc::new" arguments:document];
}

- (id)updateObject {
  int      flength  = 0;
  id       document = [self snapshot];
  NSNumber *aRel    = [NSNumber numberWithBool:self->autoRelease];

  if (![self->fileContent isNotNull]) self->fileContent = @"";

  flength = [self->fileContent length];

  [document takeValue:aRel                             forKey:@"autoRelease"];
  [document takeValue:self->fileContent                forKey:@"fileContent"];
  [document takeValue:[NSNumber numberWithInt:flength] forKey:@"fileSize"];

  if (self->project != nil) {
    [document takeValue:self->project forKey:@"project"];
  }
 
  return [self runCommand:@"doc::set" arguments:document];
}

- (BOOL)isDeleteDisabled {
  if (![self isInNewMode] &&
      ![[self->doc valueForKey:@"isIndexDoc"] boolValue]) {
    BOOL isEnabled = NO;
    id   sn        = [self session];
    id   myAccount = [sn activeAccount];
    id   accountId = [myAccount valueForKey:@"companyId"];
    id   obj       = self->doc;  
  
    isEnabled = (([accountId isEqual:[obj valueForKey:@"firstOwnerId"]]) ||
                  ([sn activeAccountIsRoot]));

    return !isEnabled;
  }
  return YES;
}

- (id)reallyDelete {
  id result = [self->doc run:@"doc::delete",
                             @"reallyDelete", [NSNumber numberWithBool:YES],
                             nil];
  if (result) {
    [self postChange:LSWDeletedTextDocumentNotificationName onObject:result];
    [self back];
    [self back];
  }
  return nil;
}

- (id)cancel {
  if([self checkConstraintsForCancel]) {
    if(self->wasReleased) {
      id result;

      if ((result = [self->doc run: @"doc::reject", nil]) == nil)
        return nil;
    }
    return [self back];
  }
  return nil;
}

@end

