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

#import <LSFoundation/LSDBObjectSetCommand.h>

@interface LSCheckoutDocumentVersionCommand : LSDBObjectSetCommand
@end

#import "common.h"

@implementation LSCheckoutDocumentVersionCommand

- (void)_prepareForExecutionInContext:(id)_context {
  id obj       = nil;
    
  [super _prepareForExecutionInContext:_context];

  obj = [[self object] valueForKey:@"toDoc"];

  // check constraints 
  [self assert:(![[obj valueForKey:@"isFolder"] boolValue]) 
        reason:@"cannot checkout folder!"];

  [self assert:([[obj valueForKey:@"status"] isEqualToString:@"released"])
        reason:@"document is already edited!"];
}

- (void)_executeInContext:(id)_context {
  id obj       = [self object];
  id doc       = [obj valueForKey:@"toDoc"];
  id account   = [_context valueForKey:LSAccountKey];
  id accountId = [account valueForKey:@"companyId"];

  [doc takeValue:@"edited" forKey:@"status"];

  [self assert:[[self databaseChannel] updateObject:doc]
        reason:[dbMessages description]];

  {
    id editing = [doc valueForKey:@"toDocumentEditing"];

    [editing takeValue:[obj valueForKey:@"title"]    forKey:@"title"];
    [editing takeValue:[obj valueForKey:@"abstract"] forKey:@"abstract"];
    [editing takeValue:[obj valueForKey:@"contact"]  forKey:@"contact"];
    [editing takeValue:[obj valueForKey:@"fileType"] forKey:@"fileType"];
    [editing takeValue:[obj valueForKey:@"fileSize"] forKey:@"fileSize"];
    [editing takeValue:[obj valueForKey:@"version"]  forKey:@"version"];
    [editing takeValue:[NSCalendarDate date]         forKey:@"checkoutDate"];
    [editing takeValue:[NSNumber numberWithBool:NO]  forKey:@"isAttachChanged"];
    [editing takeValue:[doc valueForKey:@"status"]   forKey:@"status"];
    [editing takeValue:accountId                     forKey:@"currentOwnerId"];

    [self assert:[[self databaseChannel] updateObject:editing]
          reason:[dbMessages description]];

    // copy attachment
    {
      BOOL           isOk;
      NSFileManager  *manager;
      NSString       *source, *dest;
      
      isOk     = NO;
      manager  = [NSFileManager defaultManager];

      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                    @"object", obj, nil);
      source = [obj valueForKey:@"attachmentName"];

      LSRunCommandV(_context, @"doc", @"get-attachment-name",
                    @"object", editing, nil);
      dest = [editing valueForKey:@"attachmentName"];
            
      if ([manager fileExistsAtPath:source]) {
      	if ([manager fileExistsAtPath:dest]) {
          isOk = [manager removeFileAtPath:dest handler:nil];
        }
        isOk = [manager copyPath:source toPath:dest handler:nil];
      }
  
      [self assert:isOk reason:@"error during save of editing attachment!"];
    }
  }
}

// initialize records

- (NSString *)entityName {
  return @"DocumentVersion";
}

@end
