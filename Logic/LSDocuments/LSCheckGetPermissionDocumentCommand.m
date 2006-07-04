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

#include <LSFoundation/LSBaseCommand.h>

@interface LSCheckGetPermissionDocumentCommand : LSBaseCommand
@end

#include "common.h"
#include <LSFoundation/LSFoundation.h>

@implementation LSCheckGetPermissionDocumentCommand

/* command methods */

- (BOOL)_hasAccessToDocument:(id)obj inContext:(id)_ctx {
  NSString *status;
  int      versCount;
  id       coId;
  int      coIntId, loginId;
  
  if ([[obj valueForKey:@"isFolder"] boolValue])
    return YES;

  loginId = [[[_ctx valueForKey:LSAccountKey] valueForKey:@"companyId"]
                    intValue];
  
  coId      = [obj valueForKey:@"currentOwnerId"];
  coIntId   = (coId == nil) ? -1 : [coId intValue];
  status    = [obj valueForKey:@"status"];
  versCount = [[obj valueForKey:@"versionCount"] intValue];
  
  if (status != nil) {
    if ([status isEqualToString:@"edited"] && versCount == 0 &&
	!(coIntId == -1 || coIntId == loginId || coIntId == 10000)) {
      return NO;
    }
  }
  return YES;
}

- (void)_executeInContext:(id)_context {
  // TODO: cleanup method
  NSMutableArray   *permittedObjs = nil;
  id               obj            = nil;
  NGMutableHashMap *groupedObjs;
  NSEnumerator     *enumerator;
  id               projectId      = nil;
  
  enumerator  = [[self object] objectEnumerator];
  groupedObjs = [[NGMutableHashMap alloc] initWithCapacity:64];
  while ((obj = [enumerator nextObject])) {
    if (![self _hasAccessToDocument:obj inContext:_context])
      continue;
    
    [groupedObjs addObjects:&obj count:1 
		 forKey:[obj valueForKey:@"projectId"]];
  }
  
  permittedObjs = [[NSMutableArray allocWithZone:[self zone]] init];
  enumerator    = [groupedObjs keyEnumerator];
  
  while ((projectId = [enumerator nextObject])) {
    NSArray *result;
    
    if (![projectId isNotNull]) {
      [self logWithFormat:
	      @"LSCheckGetPermissionDocumentCommand: cannot check "
	      @"permission projectId isNull"];
      continue;
    }
    result = LSRunCommandV(_context, @"project", @"get",
                           @"projectId", projectId, nil);
    if (![result isNotEmpty])
      continue;
    
    [permittedObjs addObjectsFromArray:
		     [groupedObjs objectsForKey:projectId]];
  }
  [self setReturnValue:permittedObjs];
  [groupedObjs   release]; groupedObjs   = nil;
  [permittedObjs release]; permittedObjs = nil;
}

@end /* LSCheckGetPermissionDocumentCommand */
