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

#include "SkyContactAction+PrivateMethods.h"
#include "common.h"

@implementation SkyContactAction(PrivateMethods)

- (id)documentManager {
  return [[self commandContext] documentManager];
}

- (NSArray *)_globalIDsForURLs:(NSArray *)_urls {
  id result;
  NSMutableArray *retArray;
  NSEnumerator *resEnum;
  id resEntry;
  
  if (_urls == nil)
    return nil;

  // speedup for single urls
  if ([_urls count] == 1) {
    id gid;

    gid = [[self documentManager] globalIDForURL:[_urls objectAtIndex:0]];
    if (gid != nil)
      return [NSArray arrayWithObject:gid];
    else {
      [self logWithFormat:@"Invalid URL: %@", [_urls objectAtIndex:0]];
      return nil;
    }
  }

  result = [[self documentManager] globalIDsForURLs:_urls];

  // filter out empty strings returned by the documentManager
  resEnum = [result objectEnumerator];
  retArray = [NSMutableArray arrayWithCapacity:[result count]];
  
  while ((resEntry = [resEnum nextObject])) {
    if ([resEntry isKindOfClass:[EOGlobalID class]])
      [retArray addObject:resEntry];
  }
  return retArray;  
}

- (NSString *)_urlStringForGlobalId:(id)_gid {
  id dm;
  
  dm = [self documentManager];
  return [[dm urlForGlobalID:_gid] absoluteString];
}

- (void)_ensureCurrentTransactionIsCommitted {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    if ([ctx isTransactionInProgress]) {
      if (![ctx commit]) {  
        [self logWithFormat:@"couldn't commit transaction ..."];
      }
    }
  }
}

@end /* SkyContactAction(PrivateMethods) */
