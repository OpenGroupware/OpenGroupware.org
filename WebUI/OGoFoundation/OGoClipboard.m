/*
  Copyright (C) 2004 Helge Hess

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

#include "OGoClipboard.h"
#include "common.h"

@implementation OGoClipboard

static BOOL debugFavorites = YES;

- (id)initWithUserDefaults:(NSUserDefaults *)_ud {
  if ((self = [self init])) {
    self->defaults  = [_ud retain];
    self->favorites = [[NSMutableArray alloc] initWithCapacity:8];
  }
  return self;
}

- (void)dealloc {
  [self->favorites release];
  [self->defaults  release];
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return self->defaults;
}

- (int)maxFavoritesCount {
  return [[[self userDefaults] objectForKey:@"SkyMaxFavoritesCount"] intValue];
}

/* accessors */

- (BOOL)containsObjects { // DEPRECATED
  return [self isNotEmpty];
}

/* operations */

- (void)addObject:(id)_fav {
  int i, count;
  id  favGid;
  
  if ([_fav isKindOfClass:[EOGlobalID class]])
    favGid = _fav;
  else {
    favGid = [_fav respondsToSelector:@selector(globalID)]
      ? [_fav globalID]
      : (EOGlobalID *)[_fav valueForKey:@"globalID"];
  }
  
  if (![favGid isNotNull]) {
    if (debugFavorites)
      [self logWithFormat:@"got no global-id for favorite: %@", _fav];
    return;
  }
  
  [[_fav retain] autorelease];
  if (debugFavorites) {
    [self logWithFormat:@"favorite gid is %@, fav 0x%p<%@>", 
	    favGid, _fav, NSStringFromClass([_fav class])];
  }
  
  /* scan favorites for dups (should we push readded to the top?) */
  
  for (i = 0, count = [self->favorites count]; i < count; i++) {
    id efav;
    
    efav = [self->favorites objectAtIndex:i];
    
    if (efav == _fav) {
      /* already contains the object */
      if (debugFavorites)
	[self logWithFormat:@"  object is already in clipboard."];
      return;
    }
    
    if (favGid != nil) {
      if ([favGid isEqual:[efav valueForKey:@"globalID"]]) {
        /* already contains an object with the same gid */
        [self debugWithFormat:@"favorite %@ is already clipped !", favGid];
        return;
      }
    }
  }
  
  if (count >= [self maxFavoritesCount])
    [self->favorites removeLastObject];
  
  [self->favorites insertObject:_fav atIndex:0];

  if (debugFavorites) {
    [self logWithFormat:@"favorites contains %d items.", 
	    [self->favorites count]];
  }
}

- (void)removeObject:(id)_fav {
  NSMutableArray *newFavs;
  int            i, count;
  id             favGid;

  count   = [self->favorites count];
  favGid  = ([_fav valueForKey:@"globalID"]);
  newFavs = [[NSMutableArray alloc] initWithCapacity:count];
  
  for (i = 0; i < count; i++) {
    id efav;

    efav = [self->favorites objectAtIndex:i];
    
    if (efav == _fav) continue;
    if ([favGid isNotNull] && 
	[favGid isEqual:[efav valueForKey:@"globalID"]])
      continue;
    
    [newFavs addObject:efav];
  }
  ASSIGN(self->favorites, newFavs);
  [newFavs release];
}

/* fake being an array */

- (unsigned int)count {
  return [self->favorites count];
}
- (BOOL)isNotEmpty {
  return [self->favorites isNotEmpty];
}
- (id)objectAtIndex:(unsigned)_idx {
  return [self->favorites objectAtIndex:_idx];
}
- (NSEnumerator *)objectEnumerator {
  /* used by SkyProject4NewLink */
  return [self->favorites objectEnumerator];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugFavorites;
}

@end /* OGoClipboard */
