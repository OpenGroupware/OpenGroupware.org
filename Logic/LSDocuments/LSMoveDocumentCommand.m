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

@interface LSMoveDocumentCommand : LSDBObjectSetCommand
{
  id folder;
}

@end

#include "common.h"

@implementation LSMoveDocumentCommand

- (void)dealloc {
  [self->folder release];
  [super dealloc];
}

/* validation */

- (void)_validateKeysForContext:(id)_context {
  [self assert:((self->folder != nil) &&
                [[self->folder valueForKey:@"isFolder"] boolValue])
        reason:@"no folder set for document!"];

  [super _validateKeysForContext:_context];
}

/* operation */

- (BOOL)isRootAccountId:(NSNumber *)_accId {
  if (_accId == nil) return NO;
  return [_accId intValue] == 10000 ? YES : NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSNumber *accountId;
  id  obj;
  int versionCount;
  id  versCount, status, account;
  
  obj = [self object];
  [obj takeValue:[self->folder valueForKey:@"documentId"]
       forKey:@"parentDocumentId"];
  [super _prepareForExecutionInContext:_context];
  
  versCount = [obj valueForKey:@"versionCount"];
  status    = [obj valueForKey:@"status"];
  account   = [_context valueForKey:LSAccountKey];
  accountId = [account valueForKey:@"companyId"];

  if (status == nil)
    status = @"edited";

  versionCount = (versCount == nil) ? 0 : [versCount intValue];

  if (![self isRootAccountId:accountId]) {
    if (![[obj valueForKey:@"isFolder"] boolValue]) {
      if ([status isEqualToString:@"edited"]) {
	[self assert:[accountId isEqual:[obj valueForKey:@"currentOwnerId"]]
	      reason:@"Only current owner can move edited documents"];
      }
    }
  }
}

/* accessors */

- (void)setFolder:(id)_folder {
  ASSIGN(self->folder, _folder);
}
- (id)folder {
  return self->folder;
}

/* initialize records */

- (NSString *)entityName {
  return @"Doc";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"folder"]) {
    [self setFolder:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"folder"])
    return [self folder];
  return [super valueForKey:_key];
}

@end /* LSMoveDocumentCommand */
