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

#include <LSFoundation/LSDBObjectNewCommand.h>

@class NSString;

@interface LSNewNoteCommand : LSDBObjectNewCommand
{
@private  
  id       project;
  id       folder;
  NSString *filePath;
  NSString *fileContent;
}
@end

#include "common.h"

@implementation LSNewNoteCommand

- (void)dealloc {
  [self->project     release];
  [self->fileContent release];
  [self->filePath    release];
  [self->folder      release];
  [super dealloc];
}

/* operations */

- (NSString *)_fileType {
  NSString *fileType = nil;

  if (self->filePath == nil)
    return @"txt";

  fileType = [[self->filePath componentsSeparatedByString:@"."] lastObject];
  
  if ([self->filePath isEqualToString:fileType])
    return @"txt";
  
  return [fileType lowercaseString];
}

- (void)_validateKeysForContext:(id)_context {
  if (self->project != nil) {
    id rootFolder = nil;
  
    LSRunCommandV(_context, @"project",  @"get-root-document",
                  @"object",  self->project,
                  @"relationKey", @"rootDocument", nil);

    rootFolder = [self->project valueForKey:@"rootDocument"];

    ASSIGN(self->folder, rootFolder);

    [self assert:((self->folder != nil) &&
                  [[self->folder valueForKey:@"isFolder"] boolValue])
          reason:@"No folder set for note!"];
  }
  [super _validateKeysForContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id obj = nil;
  
  if (![[self valueForKey:@"isFolder"] boolValue]) {
    id account   = [_context valueForKey:LSAccountKey];
    id accountId = [account valueForKey:@"companyId"];

    [self takeValue:accountId forKey:@"currentOwnerId"];
  }

  if (self->project != nil) {
    [self takeValue:[self->project valueForKey:@"projectId"]
          forKey:@"projectId"];
  }
  [self takeValue:[NSCalendarDate date] forKey:@"creationDate"];
  
  [super _prepareForExecutionInContext:_context];

  obj = [self object];
  
  [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isNote"];
  [obj takeValue:[NSNumber numberWithBool:NO]  forKey:@"isFolder"];
  [obj takeValue:[self _fileType] forKey:@"fileType"];

  if (self->project != nil) {
    [obj takeValue:[self->folder valueForKey:@"documentId"]
         forKey:@"parentDocumentId"];
  }
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  // save attachement
  if (self->fileContent != nil) {
    id       obj       = nil;
    NSString *path     = nil;
    NSString *fileName = nil;
    
    obj  = [self object];
    path = [[_context userDefaults] stringForKey:@"LSAttachmentPath"];
    
    fileName = [[[obj valueForKey:@"documentId"] stringValue]
                 stringByAppendingPathExtension:[obj valueForKey:@"fileType"]];
    fileName = [path stringByAppendingPathComponent:fileName];

    [self assert:[self->fileContent writeToFile:fileName atomically:YES]
          reason:@"Error during save of note attachment!"];
  }
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGN(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

- (void)setFileContent:(NSString *)_fileContent {
  ASSIGN(self->fileContent, _fileContent);
}
- (NSString *)fileContent {
  return self->fileContent;
}

- (void)setFolder:(id)_folder {
  ASSIGN(self->folder, _folder);
}
- (id)folder {
  return self->folder;
}

/* initialize records */

- (NSString *)entityName {
  return @"Note";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"])
    [self setProject:_value];
  else if ([_key isEqualToString:@"folder"])
    [self setFolder:_value];
  else if ([_key isEqualToString:@"filePath"])
    [self setFilePath:_value];
  else if ([_key isEqualToString:@"fileContent"])
    [self setFileContent:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  else if ([_key isEqualToString:@"project"])
    return [self project];
  else if ([_key isEqualToString:@"folder"])
    return [self folder];
  else if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  return [super valueForKey:_key];
}

@end /* LSNewNoteCommand */
