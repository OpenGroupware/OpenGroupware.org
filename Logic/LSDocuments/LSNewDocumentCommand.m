/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#import "common.h"
#import "LSNewDocumentCommand.h"

@implementation LSNewDocumentCommand

- (void)dealloc {
  [self->folder      release];
  [self->project     release];
  [self->data        release];
  [self->filePath    release];
  [self->fileContent release];
  [super dealloc];
}

- (void)_setFileType {
  NSString *fileType;

  if (self->filePath == nil)
    fileType = @"txt";
  else {
    fileType = [[self->filePath componentsSeparatedByString:@"."] lastObject];

    if ([self->filePath isEqualToString:fileType])
      fileType = @"txt";
    else
      fileType = fileType;
  }
  [self takeValue:fileType forKey:@"fileType"];
}

- (void)_newDocumentEditingInContext:(id)_context {
  BOOL         isOk;
  id           doc, pkey, editing;
  EOEntity     *myEntity;
  NSDictionary *pk;

  doc      = [self object];
  pkey     = [doc valueForKey:[self primaryKeyName]];
  myEntity = [[self databaseModel] entityNamed:@"DocumentEditing"];
  pk       = [self newPrimaryKeyDictForContext:_context
                   keyName:@"documentEditingId"];
  editing  = [self produceEmptyEOWithPrimaryKey:pk entity:myEntity];

  [editing takeValue:[pk valueForKey:@"documentEditingId"]
           forKey:@"documentEditingId"];
  [editing takeValue:pkey                          forKey:@"documentId"];
  [editing takeValue:@"inserted"                   forKey:@"dbStatus"];  
  [editing takeValue:[doc valueForKey:@"title"]    forKey:@"title"];
  [editing takeValue:[doc valueForKey:@"abstract"] forKey:@"abstract"];
  [editing takeValue:[doc valueForKey:@"contact"]  forKey:@"contact"];
  [editing takeValue:[doc valueForKey:@"fileType"] forKey:@"fileType"];
  [editing takeValue:[doc valueForKey:@"fileSize"] forKey:@"fileSize"];
  [editing takeValue:[doc valueForKey:@"status"]   forKey:@"status"];
  [editing takeValue:[NSNumber numberWithBool:YES] forKey:@"isAttachChanged"];
  [editing takeValue:[NSCalendarDate date]         forKey:@"checkoutDate"];
  [editing takeValue:[NSNumber numberWithInt:0]    forKey:@"version"];
  [editing takeValue:[doc valueForKey:@"currentOwnerId"]
           forKey:@"currentOwnerId"];
  [editing takeValue:[doc valueForKey:@"projectId"] forKey:@"projectId"];

  isOk = [[self databaseChannel] insertObject:editing];

  [self assert:isOk reason:[sybaseMessages description]];

  {
    NSString *fileName, *editingFileName;

    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"object", doc, nil);
    fileName = [doc valueForKey:@"attachmentName"];

    LSRunCommandV(_context, @"documentEditing", @"get-attachment-name",
                  @"object", editing, nil);
    editingFileName = [editing valueForKey:@"attachmentName"];

    if (self->data != nil) {
      isOk = [self->data writeToFile:fileName atomically:YES];
      isOk = [self->data writeToFile:editingFileName atomically:YES];
    }
    else if (self->fileContent != nil) {
      isOk = [self->fileContent writeToFile:fileName atomically:YES];
      isOk = [self->fileContent writeToFile:editingFileName atomically:YES];
    }
    NSAssert2(isOk, @"error during save of attachment to %@ or %@",
              fileName, editingFileName);
  }
}  

- (void)_validateKeysForContext:(id)_context {
  [self assert:(self->project != nil) reason:@"no project set for document!"];

  [super _validateKeysForContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id   accountId;
  BOOL isFolder;

  accountId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];

  [self takeValue:accountId forKey:@"firstOwnerId"];
  [self takeValue:accountId forKey:@"currentOwnerId"];

  if ([self->folder isNotNull])
    [self takeValue:[self->folder valueForKey:@"documentId"]
          forKey:@"parentDocumentId"];
  
  if ([self->project isNotNull])
    [self takeValue:[self->project valueForKey:@"projectId"]
          forKey:@"projectId"];
  
  [self takeValue:[NSNumber numberWithBool:NO] forKey:@"isNote"];
  [self takeValue:[NSNumber numberWithInt:0]   forKey:@"versionCount"];
  [self takeValue:[NSCalendarDate date]        forKey:@"creationDate"];
  [self takeValue:[NSCalendarDate date]        forKey:@"lastmodifiedDate"];

  isFolder = [[self valueForKey:@"isFolder"] boolValue];
  if (!isFolder && ![[self valueForKey:@"isObjectLink"] boolValue]) {
    [self takeValue:@"edited" forKey:@"status"];
  }
  if (!isFolder) {
    [self _setFileType];
  }
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id obj; 
  
  [super _executeInContext:_context];
  obj = [self object];

  // save attachement and editing
  if (![[obj valueForKey:@"isFolder"] boolValue] &&
      ![[self valueForKey:@"isObjectLink"] boolValue]) {
    [self _newDocumentEditingInContext:_context];

    if (self->autoRelease) {
      [self assert:[[self databaseChannel] refetchObject:obj]];
      LSRunCommandV(_context, @"doc", @"release", @"object", obj,
                    @"checkAccess", [self valueForKey:@"checkAccess"], nil);
    }
  }
}

// accessors

- (void)setFileContent:(NSString *)_content {
  ASSIGN(self->fileContent, _content);
}
- (id)fileContent {
  return self->fileContent;
}

- (void)setFolder:(id)_folder {
  ASSIGN(self->folder, _folder);
}
- (id)folder {
  return self->folder;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setData:(NSData *)_data {
  ASSIGN(self->data, _data);
}
- (NSData *)data {
  return self->data;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGN(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

- (BOOL)autoRelease {
  return self->autoRelease;
}
- (void)setAutoRelease:(BOOL)_autoRelease {
  self->autoRelease = _autoRelease;
}

// initialize records

- (NSString *)entityName {
  return @"Doc";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"data"]) {
    [self setData:_value];
    return;
  }
  else if ([_key isEqualToString:@"folder"]) {
    [self setFolder:_value];
    return;
  }
  else if ([_key isEqualToString:@"project"]) {
    [self setProject:_value];
    return;
  }
  else if ([_key isEqualToString:@"filePath"]) {
    [self setFilePath:_value];
    return;
  }
  else if ([_key isEqualToString:@"autoRelease"]) {
    [self setAutoRelease:[_value boolValue]];
    return;
  }
  else if ([_key isEqualToString:@"fileContent"]) {
    [self setFileContent:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  else if ([_key isEqualToString:@"folder"])
    return self->folder;
  else if ([_key isEqualToString:@"project"])
    return [self project];
  else if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  else if ([_key isEqualToString:@"autoRelease"])
    return [NSNumber numberWithBool:self->autoRelease];
  else if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  return [super valueForKey:_key];
}

@end
