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

#include <LSFoundation/LSDBObjectGetCommand.h>

@interface LSGetDocumentCommand : LSDBObjectGetCommand
{
  BOOL loadPath;
}
@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@implementation LSGetDocumentCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->loadPath = YES;
  }
  return self;
}

/* command methods */

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  [self setObject:LSRunCommandV(_context,
                                @"doc",    @"check-get-permission",
                                @"object", [self object], nil)];
  
  // get attachment name
  if (self->loadPath) {
    LSRunCommandV(_context, @"doc", @"get-attachment-name",
                  @"objects", [self object], nil);
  }
}

/* record initializer */

- (NSString *)entityName {
  return @"Doc";
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"]) {
    _key   = @"documentId";
    _value = [_value keyValues][0];
  }
  else if ([_key isEqualToString:@"loadPath"]) {
    self->loadPath = [_value boolValue];
    return;
  }
  [super takeValue:_value forKey:_key];  
}

- (id)valueForKey:(id)_key {
  id v;

  if ([_key isEqualToString:@"gid"]) {
    v = [super valueForKey:@"documentId"];
    v = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                       keys:&v keyCount:1
                       zone:NULL];
  }
  else if  ([_key isEqualToString:@"loadPath"])
    v = [NSNumber numberWithBool:self->loadPath];
  else
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetDocumentCommand */
