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

#include <LSFoundation/LSDBObjectDeleteCommand.h>

@class NSMutableArray;

@interface LSDeleteDocumentCommand : LSDBObjectDeleteCommand
{
  NSMutableArray *filesToRemove;
}

- (void)removeAllFiles;

@end

#include "common.h"

@implementation LSDeleteDocumentCommand

- (void)dealloc {
  [self->filesToRemove release];
  [super dealloc];
}

/* commands */

- (NSArray *)_getVersionEOsForDocId:(NSNumber *)_docId inContext:(id)_ctx {
  NSArray *versions;
  
  if (![_docId isNotNull]) return nil;
  versions = LSRunCommandV(_ctx, @"documentversion", @"get",
                           @"documentId", _docId,
                           @"returnType", intObj(LSDBReturnType_ManyObjects),
                           nil);
  return versions;
}

- (id)_getEditingEOForDocId:(NSNumber *)_docId inContext:(id)_ctx {
  id editing;

  if (![_docId isNotNull]) return nil;
  editing = LSRunCommandV(_ctx, @"documentediting", @"get",
                          @"documentId",       _docId,
                          @"checkPermissions", [NSNumber numberWithBool:NO],
                          nil);
  if ([editing isKindOfClass:[NSArray class]])
    editing = [editing lastObject];
  return editing;
}

/* operation */

- (void)_deleteVersionsInContext:(id)_context {
  NSArray       *versions;
  NSEnumerator  *enumerator;
  id            v;
  
  versions   = [self _getVersionEOsForDocId:
		       [[self object] valueForKey:@"documentId"]
		     inContext:_context];
  enumerator = [versions objectEnumerator];
  
  while ((v = [enumerator nextObject])) {
    LSRunCommandV(_context, @"documentversion", @"delete",
                  @"object", v, nil);
  }
}

- (id)docEditing:(id)_context {
  return [self _getEditingEOForDocId:[[self object] valueForKey:@"documentId"]
	       inContext:_context];
}

- (void)_deleteDocumentEditingInContext:(id)_context {
  BOOL isOk; 
  id   editing;
  
  editing = [self docEditing:_context];
  
  if (![editing isNotNull]) {
    [self logWithFormat:@"WARNING[%s] missing documentEditing for doc %@",
            __PRETTY_FUNCTION__, [self object]];
    return;
  }

  if ([self reallyDelete]) {
    if ((isOk = [[self databaseChannel] deleteObject:editing])) {
      NSString *fileName = nil;
    
      [editing takeValue:[EONull null] forKey:@"attachmentName"];
      // TODO: is this correct? should be documentEditing::get-attachmentName?
      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                      @"object", editing, nil);
      fileName = [editing valueForKey:@"attachmentName"];
      if (fileName)
	[self->filesToRemove addObject:fileName];
    }
  }
  else {
    [editing takeValue:@"archived" forKey:@"dbStatus"];
    isOk = [[self databaseChannel] updateObject:editing];
  }
  
  [self assert:isOk reason:[sybaseMessages description]];  
}

- (BOOL)isRootAccountId:(NSNumber *)_accId {
  if (_accId == nil) return NO;
  return [_accId intValue] == 10000 ? YES : NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  BOOL isFolder = NO;
  id   obj      = nil;

  [super _prepareForExecutionInContext:_context];

  obj      = [self object];

  [self assert:[[obj entityName] isEqual:@"Doc"]
        reason:@"LSDeleteDocumentCommand expect Doc"];
  
  isFolder = [[obj valueForKey:@"isFolder"] boolValue];
    
  if (isFolder) {
    int docsCount = 0;
    id  toD       = nil;
    
    if ([(toD = [obj valueForKey:@"toDoc"]) isKindOfClass:[NSArray class]])
      docsCount = [toD count];
    else if (![toD isNotNull])
      docsCount = 0;
    else
      docsCount = 1;
    
    [self assert:(docsCount == 0) reason:@"can only delete empty folder!"];
  }
  else if (![[obj valueForKey:@"isObjectLink"] boolValue]) {
    NSNumber *accountId;
    int versionCount = 0;
    id  versCount;
    id  status       = nil;
    id  account;
    id  docEdit;

    versCount = [obj valueForKey:@"versionCount"];
    account   = [_context valueForKey:LSAccountKey];
    accountId = [account valueForKey:@"companyId"];
    
    if (![docEdit = [self docEditing:_context] isNotNull])
      status = @"released";
    else {
      if ((status = [obj valueForKey:@"status"]) == nil)
	status = @"edited";
    }
    
    versionCount = (versCount == nil) ? 0 : [versCount intValue];
    
    if (![accountId isEqual:[obj valueForKey:@"firstOwnerId"]] &&
	![self isRootAccountId:accountId] &&
        [status isEqualToString:@"edited"]) {
      [self assert:(versionCount == 0 &&
                    [accountId isEqual:[obj valueForKey:@"currentOwnerId"]])
            reason:@"Only current owner can delete an edited document"
            @"with no versions!"];
    }
  }
}

- (void)_executeInContext:(id)_context {
  id obj = [self object];

  if (!self->filesToRemove)
    self->filesToRemove = [[NSMutableArray alloc] init];
  else
    [self->filesToRemove removeAllObjects];
  
  if (![obj isNotNull])
    obj = nil;
  
  NSAssert([obj isNotNull], @"no object available");
  
  if (![[obj valueForKey:@"isFolder"] boolValue] &&
      ![[obj valueForKey:@"isObjectLink"] boolValue]) {
    [self _deleteVersionsInContext:_context];
    [self _deleteDocumentEditingInContext:_context];
    [self _deleteRelations:[[self entity] relationships] inContext:_context];
  }

  [super _executeInContext:_context];

  if (![[obj valueForKey:@"isFolder"] boolValue] &&
      ![[obj valueForKey:@"isObjectLink"] boolValue]) {
    NSString *fileName;;
    
    [obj takeValue:[EONull null] forKey:@"attachmentName"];
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"object", obj, nil);
    fileName = [obj valueForKey:@"attachmentName"];
    if (fileName)
      [self->filesToRemove addObject:fileName];
    
  }
  [self removeAllFiles];
}

- (void)removeAllFiles {
  NSEnumerator  *enumerator;
  NSString      *fileName;
  NSFileManager *manager;

  manager    = [NSFileManager defaultManager];
  enumerator = [self->filesToRemove objectEnumerator];
  
  while ((fileName = [enumerator nextObject])) {
    if (!([manager fileExistsAtPath:fileName] && [self reallyDelete]))
      continue;
      
    if ([manager removeFileAtPath:fileName handler:nil])
      continue;
    
    [self logWithFormat:@"WARNING[%s] could not delete file '%@'",
	  __PRETTY_FUNCTION__, fileName];
  }
}

/* initialize records */

- (NSString *)entityName {
  return @"Doc";
}

@end /* LSDeleteDocumentCommand */
