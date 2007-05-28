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

#import <LSFoundation/LSDBObjectSetCommand.h>

@interface LSCheckoutDocumentCommand : LSDBObjectSetCommand
@end

#include "common.h"
#include <GDLAccess/EOEntity+Factory.h>
#include <GDLAccess/EOFault.h>

@implementation LSCheckoutDocumentCommand

/* commands */

- (NSString *)_fillAttachmentNameOfDocEO:(id)_doc inContext:(id)_context {
  if (![_doc isNotNull]) return nil;
  
  LSRunCommandV(_context, @"doc", @"get-attachment-name",
		@"object", _doc, nil);
  return [_doc valueForKey:@"attachmentName"];
}
- (NSString *)_fillAttachmentNameOfDocEditingEO:(id)_doc inContext:(id)_ctx {
  if (![_doc isNotNull]) return nil;
  
  LSRunCommandV(_ctx, @"documentEditing", @"get-attachment-name",
		@"object", _doc, nil);
  return [_doc valueForKey:@"attachmentName"];
}

- (id)_getEditingEOForDocId:(NSNumber *)_docId inContext:(id)_ctx {
  // TODO: document why 'checkPermissions' is turned off
  id obj;

  if (![_docId isNotNull]) return nil;
  
  obj = LSRunCommandV(_ctx, @"documentEditing", @"get",
		      @"documentId",       _docId,
		      @"checkPermissions", [NSNumber numberWithBool:NO],
		      nil);
  if ([obj isKindOfClass:[NSArray class]])
    obj = [obj lastObject];
  
  if ([EOFault isFault:obj]) {
    [self warnWithFormat:
	    @"toDocumentEditing for %@ is a fault: %@", _docId, obj];
  }
  return obj;
}

/* create new Primary Key */

- (id)produceEmptyEOWithPrimaryKey:(NSDictionary *)_pkey
  entity:(EOEntity *)_entity
{
  id obj;
  
  obj = [_entity produceNewObjectWithPrimaryKey:_pkey];
  [_entity setAttributesOfObjectToEONull:obj];

  return obj;
}

- (NSDictionary *)newPrimaryKeyDictForContext:(id)_ctx 
  keyName:(NSString *)_name
{
  id                     key;
  id<NSObject,LSCommand> nkCmd;

  nkCmd = LSLookupCommand(@"system", @"newkey");
  
  [nkCmd takeValue:[self entity] forKey:@"entity"];
  key = [nkCmd runInContext:_ctx];
  [self assert:(key != nil) reason:@"Could not get valid new primary key!\n"];
  return [NSDictionary dictionaryWithObject:key forKey:_name];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id obj;
  
  [super _prepareForExecutionInContext:_context];
  
  obj = [self object];
  // check constraints 
  [self assert:(![[obj valueForKey:@"isFolder"] boolValue]) 
        reason:@"cannot checkout folder!"];
}

- (void)_newDocumentEditingInContext:(id)_context {
  BOOL         isOk;
  id           doc, pkey, editing;
  EOEntity     *myEntity;
  NSDictionary *pk;
  
  doc      = [self object];
  pkey     = [doc valueForKey:@"documentId"];
  myEntity = [[self databaseModel] entityNamed:@"DocumentEditing"];
  
  pk      = [self newPrimaryKeyDictForContext:_context
                  keyName:@"documentEditingId"];
  editing = [self produceEmptyEOWithPrimaryKey:pk entity:myEntity];

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
  [editing takeValue:[NSNumber numberWithInt:1]    forKey:@"objectVersion"];
  [editing takeValue:[NSNumber numberWithInt:0]    forKey:@"version"];
  [editing takeValue:[doc valueForKey:@"currentOwnerId"]
           forKey:@"currentOwnerId"];
  [editing takeValue:[doc valueForKey:@"projectId"] forKey:@"projectId"];

  isOk = [[self databaseChannel] insertObject:editing];

  [self assert:isOk reason:[sybaseMessages description]];
  {
    NSString      *fileName, *editingFileName;
    NSFileManager *manager;
    
    fileName        = [self _fillAttachmentNameOfDocEO:doc inContext:_context];
    editingFileName = [self _fillAttachmentNameOfDocEditingEO:editing
			    inContext:_context];
    manager  = [NSFileManager defaultManager];

    if ([manager fileExistsAtPath:fileName]) {
      isOk = YES;
      if ([manager fileExistsAtPath:editingFileName])
        isOk = [manager removeFileAtPath:editingFileName handler:nil];
      if (isOk)
	isOk = [manager copyPath:fileName toPath:editingFileName handler:nil];
    }
    [self assert:isOk reason:@"error during save of editing attachment!"];
  }
}  

- (void)_executeInContext:(id)_context {
  NSNumber *accountId;
  id       obj, account;
  id       editing;

  obj       = [self object];
  account   = [_context valueForKey:LSAccountKey];
  accountId = [account valueForKey:@"companyId"];

  /* validate type */
  
  if ([[obj valueForKey:@"isObjectLink"] boolValue]) {
    [self logWithFormat:@"try to checkout object link"];
    return;
  }
  if ([[obj valueForKey:@"isFolder"] boolValue]) {
    [self logWithFormat:@"try to checkout folder"];
    return;
  }
  
  /* first update master document */

  [obj takeValue:@"edited" forKey:@"status"];
  [self bumpChangeTrackingFields];
  [super _executeInContext:_context];
  

  /* locate editing object or create a new one */
  
  editing = [self _getEditingEOForDocId:[obj valueForKey:@"documentId"]
		  inContext:_context];
  if (editing == nil) {
    [self _newDocumentEditingInContext:_context];
    return;
  }

  /* update editing object_version */
  
  {
    id           v   = [editing valueForKey:@"objectVersion"];
    unsigned int ver = [v isNotNull] ? [v unsignedIntValue] : 0;
    ver++;
    [editing takeValue:[NSNumber numberWithUnsignedInt:ver] 
	     forKey:@"objectVersion"];
  }
  
  /* update editing */
  
  {
    BOOL           isOk;
    NSFileManager  *manager;
    NSString       *source, *dest;
      
    if ([EOFault isFault:obj])
      [self warnWithFormat:@"obj is a fault: %@", obj];

    [editing takeValue:[obj valueForKey:@"title"]         forKey:@"title"];
    [editing takeValue:[obj valueForKey:@"abstract"]      forKey:@"abstract"];
    [editing takeValue:[obj valueForKey:@"contact"]       forKey:@"contact"];
    [editing takeValue:[obj valueForKey:@"fileType"]      forKey:@"fileType"];
    [editing takeValue:[obj valueForKey:@"fileSize"]      forKey:@"fileSize"];
    [editing takeValue:[obj valueForKey:@"versionCount"]  forKey:@"version"];
    [editing takeValue:[NSCalendarDate date]        forKey:@"checkoutDate"];
    [editing takeValue:[NSNumber numberWithBool:NO] forKey:@"isAttachChanged"];
    [editing takeValue:[obj valueForKey:@"status"]  forKey:@"status"];
    [editing takeValue:accountId                    forKey:@"currentOwnerId"];

    [self assert:[[self databaseChannel] updateObject:editing]
	  reason:[sybaseMessages description]];
    
    /* copy attachment */

    manager  = [NSFileManager defaultManager];
    [editing takeValue:[EONull null] forKey:@"attachmentName"];
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
		  @"object", editing, nil);
    dest = [editing valueForKey:@"attachmentName"];
    
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
		  @"object", obj, nil);
    source = [obj valueForKey:@"attachmentName"];
    
    isOk = NO;
    if ([manager fileExistsAtPath:source]) {
      isOk = YES;
      
      if ([manager fileExistsAtPath:dest])
	isOk = [manager removeFileAtPath:dest handler:nil];
	  
      if (isOk)
	isOk = [manager copyPath:source toPath:dest handler:nil];
    }
    
    [self assert:isOk reason:@"error during save of editing attachment!"];
  }
}

/* initialize records */

- (NSString *)entityName {
  return @"Doc";
}

@end /* LSCheckoutDocumentCommand */
