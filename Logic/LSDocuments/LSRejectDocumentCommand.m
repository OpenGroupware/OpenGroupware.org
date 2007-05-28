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

@interface LSRejectDocumentCommand : LSDBObjectSetCommand
@end

#import "common.h"

@implementation LSRejectDocumentCommand

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

  {
    NSString *fileName;

    [editing takeValue:[EONull null] forKey:@"attachmentName"];
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"object", editing, nil);
    fileName = [editing valueForKey:@"attachmentName"];

    isOk = [[NSData data] writeToFile:fileName atomically:YES];
  
    [self assert:isOk reason:@"error during clear of editing attachment"];
  }

  [editing takeValue:[EONull null] forKey:@"title"];
  [editing takeValue:[EONull null] forKey:@"abstract"];
  [editing takeValue:[EONull null] forKey:@"contact"];
  [editing takeValue:[EONull null] forKey:@"fileSize"];
  [editing takeValue:[EONull null] forKey:@"currentOwnerId"];
  [editing takeValue:[EONull null] forKey:@"version"];
  [editing takeValue:[EONull null] forKey:@"isAttachChanged"];
  [editing takeValue:[EONull null] forKey:@"checkoutDate"];

  [self assert:[[self databaseChannel] updateObject:editing]];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id obj = nil;
    
  [super _prepareForExecutionInContext:_context];

  obj = [self object];

  // check constraints 
  [self assert:(![[obj valueForKey:@"isFolder"] boolValue]) 
        reason:@"cannot checkout folder!"];

  [self assert:([[obj valueForKey:@"status"] isEqualToString:@"edited"]) 
        reason:@"document is released!"];
  
  [obj takeValue:@"released" forKey:@"status"];
  
  /*
    Note: this is funny because we bump our values. Not sure whether thats
          necessary, but its a safer choice for caching to make consumers
	  aware that something indeed did change.
  */
  [self bumpChangeTrackingFields];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  [self _clearDocumentEditingInContext:_context];
}

/* initialize records */

- (NSString *)entityName {
  return @"Doc";
}

@end
