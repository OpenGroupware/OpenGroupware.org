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

@interface LSSetFolderCommand : LSDBObjectSetCommand
{
  id folder;
}

@end

#include "common.h"

@implementation LSSetFolderCommand

- (void)dealloc {
  [self->folder release];
  [super dealloc];
}

/* command methods */

- (void)_prepareForExecutionInContext:(id)_context {
  if ([self->folder isNotNull]) {
    [self takeValue:[self->folder valueForKey:@"documentId"]
          forKey:@"parentDocumentId"];
  }
  
  [super _prepareForExecutionInContext:_context];

  [self bumpChangeTrackingFields];
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

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"folder"]) {
    [self setFolder:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"folder"])
    return [self folder];
  return [super valueForKey:_key];
}

@end /* LSSetFolderCommand */
