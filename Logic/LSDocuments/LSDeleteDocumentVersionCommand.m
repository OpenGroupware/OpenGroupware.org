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

@interface LSDeleteDocumentVersionCommand : LSDBObjectDeleteCommand
@end

#include "common.h"

@implementation LSDeleteDocumentVersionCommand

- (void)_executeInContext:(id)_context {
  id            obj;
  NSFileManager *manager;
  NSString      *fileName;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no object available"];

  [super _executeInContext:_context];

  manager  = [NSFileManager defaultManager];
  LSRunCommandV(_context, @"doc", @"get-attachment-name",
                @"object", obj, nil);
  fileName = [obj valueForKey:@"attachmentName"];

  if ([manager fileExistsAtPath:fileName] && [self reallyDelete]) {
    if (![manager removeFileAtPath:fileName handler:nil])
      [self logWithFormat:@"WARNING[%s]: couldn`t delete file at path %@",
            __PRETTY_FUNCTION__, fileName];
  }
}

/* initialize records */

- (NSString *)entityName {
  return @"DocumentVersion";
}

@end /* LSDeleteDocumentVersionCommand */
