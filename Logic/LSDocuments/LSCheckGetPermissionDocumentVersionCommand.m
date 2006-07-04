/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <LSFoundation/LSBaseCommand.h>

@interface LSCheckGetPermissionDocumentVersionCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSCheckGetPermissionDocumentVersionCommand

/* command methods */

- (void)_executeInContext:(id)_context {
  NSMutableArray *permittedObjs;
  id             obj;
  unsigned int   i, cnt;
  
  cnt           = [obj count];
  permittedObjs = [[NSMutableArray alloc] initWithCapacity:cnt];

  obj = [self object];  
  for (i = 0; i < cnt; i++) {
    id       docVersion;
    NSNumber *docId;
    NSArray  *result    = nil;

    docVersion = [obj objectAtIndex:i];
    docId      = [docVersion valueForKey:@"documentId"];
    
    result = LSRunCommandV(_context, @"doc", @"get", @"documentId", docId,nil);
    if ([result isNotEmpty])
      [permittedObjs addObject:docVersion];
 
  }
  [self setReturnValue:permittedObjs];
  [permittedObjs release]; permittedObjs = nil;
}

@end /* LSCheckGetPermissionDocumentVersionCommand */
