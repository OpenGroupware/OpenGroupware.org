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

#import <LSFoundation/LSDBObjectSetCommand.h>

@interface LSSetObjectLinkCommand : LSDBObjectSetCommand
{
@private  
  id folder;
}

@end

#import "common.h"

@implementation LSSetObjectLinkCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->folder);
  [super dealloc];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  if (self->folder != nil) {
    [self takeValue:[self->folder valueForKey:@"documentId"]
          forKey:@"parentDocumentId"];
  }
  [self takeValue:[NSCalendarDate date] forKey:@"lastmodifiedDate"];
  [super _prepareForExecutionInContext:_context];
}

// accessors

- (void)setFolder:(id)_folder {
  ASSIGN(self->folder, _folder);
}
- (id)folder {
  return self->folder;
}

// initialize records

- (NSString *)entityName {
  return @"Doc";
}

// key/value coding

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

@end
