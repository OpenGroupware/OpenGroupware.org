/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include <LSFoundation/LSDBObjectSetCommand.h>

@class NSString;

@interface LSSetNoteCommand : LSDBObjectSetCommand
{
  id       project;
  NSString *filePath;
  NSString *fileContent;
}

@end

#include "common.h"

@implementation LSSetNoteCommand

- (void)dealloc {
  [self->project     release];
  [self->fileContent release];
  [self->filePath    release];
  [super dealloc];
}

/* accessors */

- (NSString *)_fileType {
  // TODO: DUP code with LSNewNoteCommand!
  NSString *fileType = nil;
  NSRange r;
  
  if (![self->filePath isNotEmpty])
    return @"txt";

  // TBD: search backwards
  r = [self->filePath rangeOfString:@"."];
  if (r.length == 0)
    return @"txt";
  
  fileType = [[self->filePath componentsSeparatedByString:@"."] lastObject];
  if ([self->filePath isEqualToString:fileType])
    return @"txt";
  
  return [fileType lowercaseString];
}

- (void)_validateKeysForContext:(id)_context {
  /* check constraints  */
  
  /* dont check access if edited during delete of assigned appointment */
  if (![[self valueForKey:@"dontCheckAccess"] boolValue]) {
    id       account;
    NSNumber *accountId;
    NSNumber *ownerPKey;
    
    account   = [_context valueForKey:LSAccountKey];
    accountId = [account valueForKey:@"companyId"];
    
    [self assert:[_context isNotNull]  reason:@"missing context!"];
    [self assert:[accountId isNotNull] reason:@"missing login-id in context!"];
    
    ownerPKey = [[self object] valueForKey:@"currentOwnerId"];
    [self assert:[ownerPKey isNotNull] reason:@"missing owner of object!"];
    
    [self assert:
            ([accountId isEqual:ownerPKey] || ([accountId intValue] == 10000))
          reason:@"only owner can edit an edited note!"];
  }
  
  [super _validateKeysForContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSString *fileType = nil;
  
  if (![[self valueForKey:@"isFolder"] boolValue]) {
    id       account;
    NSNumber *accountId;
    
    account   = [_context valueForKey:LSAccountKey];
    accountId = [account valueForKey:@"companyId"];

    [self takeValue:accountId forKey:@"currentOwnerId"];
    fileType = [self _fileType];
  }
  if (self->project != nil) {
    [self takeValue:[self->project valueForKey:@"projectId"]
          forKey:@"projectId"];
  }
  
  [super _prepareForExecutionInContext:_context];

  [self assert:
        ([[[self object] valueForKey:@"fileType"] isEqualToString:fileType])
        reason:@"wrong filetype for upload!"];
  
  [[self object] takeValue:fileType forKey:@"fileType"];
  
  [self bumpChangeTrackingFields];
}

- (void)_saveAttachmentInContext:(id)_context {
  id       obj;
  NSString *path, *fileName;
  NSNumber *pkey;
  
  if (self->fileContent == nil)
    return;

  obj      = [self object];
  pkey     = [obj valueForKey:@"documentId"];
    
  path     = [[NSUserDefaults standardUserDefaults] 
                              stringForKey:@"LSAttachmentPath"];
    
  fileName = [pkey stringValue];
  fileName = [fileName stringByAppendingPathExtension:
                         [obj valueForKey:@"fileType"]];
  fileName = [path stringByAppendingPathComponent:fileName];
    
  [self assert:[self->fileContent writeToFile:fileName atomically:YES]
        reason:@"error during save of attachment"];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  [self _saveAttachmentInContext:_context];
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGNCOPY(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

- (void)setFileContent:(NSString *)_fileContent {
  /* Note content is not supposed to be big, so we copy it */
  ASSIGNCOPY(self->fileContent, _fileContent);
}
- (NSString *)fileContent {
  return self->fileContent;
}

/* initialize records */

- (NSString *)entityName {
  return @"Note";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"project"]) {
    [self setProject:_value];
    return;
  }
  if ([_key isEqualToString:@"filePath"]) {
    [self setFilePath:_value];
    return;
  }
  if ([_key isEqualToString:@"fileContent"]) {
    [self setFileContent:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  if ([_key isEqualToString:@"project"])
    return [self project];
  if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  
  return [super valueForKey:_key];
}

@end /* LSSetNoteCommand */
