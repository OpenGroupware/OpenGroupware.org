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

#import "common.h"
#import "LSGetDocumentVersionCommand.h"

@implementation LSGetDocumentVersionCommand

// command methods

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  [self setObject:LSRunCommandV(_context,
                                @"documentversion", @"check-get-permission",
                                @"object", [self object], nil)];

  //get attachment name

  LSRunCommandV(_context, @"documentversion", @"get-attachment-name",
                @"documentVersions", [self object], nil);
}

// record initializer

- (NSString *)entityName {
  return @"DocumentVersion";
}

@end
