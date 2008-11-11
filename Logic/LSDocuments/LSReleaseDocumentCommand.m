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

@interface LSReleaseDocumentCommand : LSDBObjectSetCommand
@end

#include "common.h"

@implementation LSReleaseDocumentCommand

- (id)_checkedOutVersionForVersionId:(NSNumber *)_vers
  inContext:(id)_context
{
  id      obj;
  NSArray *versions;
  int     i, cnt;
  id      vers;

  obj      = [self object];
  versions = [obj valueForKey:@"toDocumentVersion"];
  cnt      = [versions count];
  
  for (i = 0; i < cnt; i++) {
    vers = [versions objectAtIndex:i];
    if ([[vers valueForKey:@"version"] isEqual:_vers])
      break;
  }
  return vers;
}

- (void)_clearDocumentEditingInContext:(id)_context {
  BOOL           isOk      = NO;
  id             editing   = nil;
  id             document;
  NSUserDefaults *defaults;
  NSString       *path;
  
  document = [self object];
  defaults = [_context userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  
  editing = [document valueForKey:@"toDocumentEditing"];

  [editing takeValue:[EONull null] forKey:@"title"];
  [editing takeValue:[EONull null] forKey:@"abstract"];
  [editing takeValue:[EONull null] forKey:@"contact"];
  [editing takeValue:[EONull null] forKey:@"fileSize"];
  [editing takeValue:[EONull null] forKey:@"currentOwnerId"];
  [editing takeValue:[EONull null] forKey:@"version"];
  [editing takeValue:[EONull null] forKey:@"isAttachChanged"];
  [editing takeValue:[EONull null] forKey:@"checkoutDate"];

  [self assert:[[self databaseChannel] updateObject:editing]];

  {
    NSString *fileName;

    [editing takeValue:[EONull null] forKey:@"attachmentName"];
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"object", editing, nil);
    fileName = [editing valueForKey:@"attachmentName"];

    isOk = [[NSData data] writeToFile:fileName atomically:YES];
  
    [self assert:isOk reason:@"error during clear of editing attachment"];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  int cnt     = 0;
  id  obj;
  id  editing;
  
  [super _prepareForExecutionInContext:_context];

  obj = [self object];
  
  if ((editing = [obj valueForKey:@"toDocumentEditing"]) == nil) {
    editing = LSRunCommandV(_context, @"documentediting", @"get",
                            @"documentEditingId", 
                            [obj valueForKey:@"documentId"],
                            nil);
  }
  [self assert:editing != nil reason:@"missing documentEditing"];
  // check constraints 
  {
    id account   = [_context valueForKey:LSAccountKey];
    id accountId = [account valueForKey:@"companyId"];
    
    [self assert:
            (([accountId isEqual:[editing valueForKey:@"currentOwnerId"]])||
             ([accountId intValue] == 10000)) // TODO: make that a method
          reason:@"only current owner can release!"];

    [self assert:(![[obj valueForKey:@"isFolder"] boolValue]) 
          reason:@"cannot release folder!"];

    [self assert:(![[obj valueForKey:@"status"] isEqualToString:@"released"]) 
          reason:@"document is always released!"];
  }
  
  cnt = [[obj valueForKey:@"versionCount"] intValue] + 1;
  
  [obj takeValue:@"released"                       forKey:@"status"];
  [obj takeValue:[NSNumber numberWithInt:cnt]      forKey:@"versionCount"];
  [obj takeValue:[editing valueForKey:@"title"]    forKey:@"title"];
  [obj takeValue:[editing valueForKey:@"abstract"] forKey:@"abstract"];
  [obj takeValue:[editing valueForKey:@"contact"]  forKey:@"contact"];
  [obj takeValue:[editing valueForKey:@"fileType"] forKey:@"fileType"];
  [obj takeValue:[editing valueForKey:@"fileSize"] forKey:@"fileSize"];
  [obj takeValue:[editing valueForKey:@"currentOwnerId"]
       forKey:@"currentOwnerId"];
  
  [self bumpChangeTrackingFields];
}

- (void)_executeInContext:(id)_context {
  // TODO: split up this big method
  id   vers                = nil;
  id   obj;
  id   editing;
  NSCalendarDate *now;
  NSUserDefaults *defaults;
  NSFileManager  *manager;

  obj      = [self object];
  editing  = [obj valueForKey:@"toDocumentEditing"];
  now      = [NSCalendarDate date];
  defaults = [_context userDefaults];
  manager  = [NSFileManager defaultManager];
  
  [obj takeValue:now forKey:@"lastmodifiedDate"];

  [super _executeInContext:_context];

  // copy attachment from editing to document
  {
    BOOL     isOk;     
    NSString *source, *dest;
    
    isOk = NO;
    [editing takeValue:[EONull null] forKey:@"attachmentName"];
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"object", editing, nil);
    source = [editing valueForKey:@"attachmentName"];
    
    [obj takeValue:[EONull null] forKey:@"attachmentName"];
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"object", obj, nil);
    dest = [obj valueForKey:@"attachmentName"];
    
    if ([manager fileExistsAtPath:source]) {
      if ([manager fileExistsAtPath:dest]) {
        isOk = [manager removeFileAtPath:dest handler:nil];
      }
      isOk = [manager copyPath:source toPath:dest handler:nil];
    }
    [self assert:isOk reason:@"error during save of document attachment!"];
  } 
  [obj takeValue:[EONull null] forKey:@"attachmentName"];
  LSRunCommandV(_context, @"doc", @"get-attachment-name", @"object", obj, nil);
  
  vers = LSRunCommandV(_context, @"documentversion", @"new",
                       @"documentId",   [obj valueForKey:@"documentId"],
                       @"lastOwnerId",  [obj valueForKey:@"currentOwnerId"],
                       @"creationDate", [obj valueForKey:@"creationDate"],
                       @"archiveDate",  now,
                       @"isPacked",     [NSNumber numberWithBool:NO],
                       @"version",      [obj valueForKey:@"versionCount"],
                       @"title",        [obj valueForKey:@"title"],
                       @"abstract",     [obj valueForKey:@"abstract"],
                       @"contact",      [obj valueForKey:@"contact"],
                       @"fileType",     [obj valueForKey:@"fileType"],
                       @"fileSize",     [obj valueForKey:@"fileSize"],
                       @"checkAccess",  [self valueForKey:@"checkAccess"],
                       @"dbStatus",     @"inserted", nil);
  
  /*
    copy attachment from editing to version or link to former checked out 
    version
  */
  {
    BOOL     isOk    = NO;
    NSString *source = nil;
    NSString *dest   = nil;
    NSNumber *vId    = nil;

    vId = [editing valueForKey:@"version"];

    if (![[editing valueForKey:@"isAttachChanged"] boolValue] &&
        [vId intValue] % 5 != 0) {   
      id v = nil;

      v = [self _checkedOutVersionForVersionId:vId inContext:_context];
      [v takeValue:[obj valueForKey:@"fileType"] forKey:@"fileType"];

      [v takeValue:[EONull null] forKey:@"attachmentName"];
      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                    @"object", v, nil);
      source = [v valueForKey:@"attachmentName"];

      [vers takeValue:[obj valueForKey:@"fileType"] forKey:@"fileType"];

      [vers takeValue:[EONull null] forKey:@"attachmentName"];
      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                    @"object", vers, nil);
      dest = [vers valueForKey:@"attachmentName"];
      isOk = [manager createSymbolicLinkAtPath:source pathContent:dest];
    }
    else {
      [editing takeValue:[EONull null] forKey:@"attachmentName"];
      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                    @"object", editing, nil);
      source = [editing valueForKey:@"attachmentName"];

      [vers takeValue:[obj valueForKey:@"fileType"] forKey:@"fileType"];
      [vers takeValue:[EONull null] forKey:@"attachmentName"];
      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                    @"object", vers, nil);
      dest = [vers valueForKey:@"attachmentName"];

      if ([manager fileExistsAtPath:source]) {
        if ([manager fileExistsAtPath:dest]) {
          isOk = [manager removeFileAtPath:dest handler:nil];
        }
        isOk = [manager copyPath:source toPath:dest handler:nil];
      }
    }
    [self assert:isOk reason:@"Error during save of version attachment!"];

    [self _clearDocumentEditingInContext:_context];
  }
}

/* initialize records */

- (NSString *)entityName {
  return @"Doc";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"document"]) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"document"])
    return [self object];
  return [super valueForKey:_key];
}

@end /* LSReleaseDocumentCommand */
