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
// $Id$

#include <LSFoundation/LSDBObjectSetCommand.h>

@class NSData, NSString;

@interface LSSetDocumentCommand : LSDBObjectSetCommand
{
@private  
  id       folder;
  NSData   *data;
  NSString *filePath;
  NSString *fileContent;
  NSString *fileType;
  BOOL     autoRelease;
}

- (NSString *)_fileType;

@end

#include "common.h"
#include <EOControl/EOControl.h>

@interface NSObject(Private)
- (id)globalID;
@end

@implementation LSSetDocumentCommand

- (void)dealloc {
  [self->folder      release];
  [self->fileContent release];
  [self->data        release];
  [self->filePath    release];
  [self->fileType    release];
  [super dealloc];
}

/* operations */

- (NSString *)_fileType {
  NSString *ft;
  
  if (self->filePath == nil)
    return @"txt";
  
  ft = [self->filePath pathExtension];
  ft = ([ft length] == 0)
    ? @"txt"
    : (id)[ft lowercaseString];
  return ft;
}

- (BOOL)isRootAccountId:(NSNumber *)_accId {
  if (_accId == nil) return NO;
  return [_accId intValue] == 10000 ? YES : NO;
}

- (void)_validatePermissionsInContext:(id)_context {
  NSNumber *accountId;
  id account;
  
  if ([[self valueForKey:@"isFolder"] boolValue])
    return;
  if (![[self valueForKey:@"status"] isEqualToString:@"edited"])
    return;

  account   = [_context valueForKey:LSAccountKey];
  accountId = [account valueForKey:@"companyId"];
  
  [self assert:
	  (([accountId isEqual:[self valueForKey:@"currentOwnerId"]]) ||
	   [self isRootAccountId:accountId])
	reason:@"only current owner can edit an edited document!"];
}

- (void)_validateKeysForContext:(id)_context {
  [self _validatePermissionsInContext:_context];
  [super _validateKeysForContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSNumber *accountId;
  id       obj, account;

  account   = [_context valueForKey:LSAccountKey];
  accountId = [account valueForKey:@"companyId"];
  [self takeValue:accountId forKey:@"currentOwnerId"];
  
  ASSIGN(self->fileType, [[self object] valueForKey:@"fileType"]);
  
  [super _prepareForExecutionInContext:_context];
  
  obj = [self object];
  
  if (self->filePath) {
    [self assert:[[obj valueForKey:@"fileType"]
		       isEqualToString:[self _fileType]]
          format:@"wrong filetype for upload (expected %@, got %@) !",
            [self _fileType], [obj valueForKey:@"fileType"]];
    
    [obj takeValue:[self _fileType] forKey:@"fileType"];
  }
}

- (void)_autoReleaseDocumentInContext:(id)_context {
  id doc;
    
  doc = [[self object] valueForKey:@"toDoc"];
  [self assert:(doc != nil) reason:@"No document available for release!"];
  LSRunCommandV(_context, @"doc", @"release", @"object", doc, nil);
}

- (void)_executeInContext:(id)_context {
  BOOL     isOk;
  NSString *fileName;
  id       obj;

  isOk = YES;
  obj  = [self object];
  
  if (self->data != nil || self->fileContent != nil) {
    [obj takeValue:[NSNumber numberWithBool:YES] forKey:@"isAttachChanged"];
  }
  [super _executeInContext:_context];
  
  // save attachement

  [obj takeValue:[EONull null] forKey:@"attachmentName"];
  LSRunCommandV(_context, @"doc", @"get-attachment-name",
                @"object", obj, nil);
  fileName = [obj valueForKey:@"attachmentName"];
  if (self->data != nil || self->fileContent != nil) {
    if (self->data != nil)
      isOk = [self->data writeToFile:fileName atomically:YES];
    else if (self->fileContent != nil)
      isOk = [self->fileContent writeToFile:fileName atomically:YES];
    else
      isOk = YES;
  }
  if (self->fileType != nil) {
    if (![self->fileType isEqual:[[self object] valueForKey:@"fileType"]]) {
      NSFileManager *fm      = nil;
      NSString      *oldFN   = nil;

      oldFN = [[fileName stringByDeletingPathExtension]
                         stringByAppendingPathExtension:self->fileType];
      fm    = [NSFileManager defaultManager];

      if ([fm fileExistsAtPath:oldFN]) {

        if (!(isOk = [fm movePath:oldFN toPath:fileName handler:nil]))
          NSLog(@"ERROR[%s]: move failed", __PRETTY_FUNCTION__);
      }
      else {
        NSLog(@"ERROR[%s]: missing file for %@ with name %@",
              __PRETTY_FUNCTION__, [self object], fileName);
      }
    }
  }
  [self assert:isOk reason:@"error during save of attachment"];    
  
  if (self->autoRelease)
    [self _autoReleaseDocumentInContext:_context];
}

/* accessors */

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

- (void)setAutoRelease:(BOOL)_autoRelease {
  self->autoRelease = _autoRelease;
}
- (BOOL)autoRelease {
  return self->autoRelease;
}

- (void)setFileContent:(NSString *)_fileContent {
  ASSIGN(self->fileContent, _fileContent);
}
- (NSString *)fileContent {
  return self->fileContent;
}

/* initialize records */

- (NSString *)entityName {
  id o;

  o = [self object];
  if ([o isKindOfClass:[NSArray class]])
    o = [o lastObject];
  
  return [o entityName];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"data"]) {
    [self setData:_value];
    return;
  }
  if ([_key isEqualToString:@"filePath"]) {
    [self setFilePath:_value];
    return;
  }
  if ([_key isEqualToString:@"autoRelease"]) {
    [self setAutoRelease:[_value boolValue]];
    return;
  }
  if ([_key isEqualToString:@"fileContent"]) {
    [self setFileContent:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  if ([_key isEqualToString:@"autoRelease"])
    return [NSNumber numberWithBool:self->autoRelease];
  if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  
  return [super valueForKey:_key];
}

@end /* LSSetDocumentCommand */
