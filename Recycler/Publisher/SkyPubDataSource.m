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

#include "SkyPubDataSource.h"
#include "SkyDocument+Pub.h"
#include "SkyPubFileManager.h"
#include "common.h"

@implementation EODataSource(PubDS)

- (SkyPubDataSource *)asPubDataSource {
  return [[[SkyPubDataSource alloc] initWithDataSource:self] autorelease];
}

@end /* EODataSource(PubDS) */

@implementation SkyPubDataSource

static BOOL debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"WODebuggingEnabled"];
}

- (id)initWithFileManager:(SkyPubFileManager *)_fm
  dataSource:(EODataSource *)_ds
{
  if ((self = [super initWithDataSource:_ds])) {
    self->fm = [_fm retain];
  }
  return self;
}
- (void)dealloc {
  [self->fm release];
  [super dealloc];
}

/* accessors */

- (SkyPubDataSource *)asPubDataSource {
  return self;
}

/* operations */

- (NSArray *)fetchObjects {
  NSMutableArray *array;
  NSArray  *res;
  unsigned i, count;

  if (debugOn) [self debugWithFormat:@"fetching from: %@", [self source]];
  res = [super fetchObjects];
  if (debugOn) [self debugWithFormat:@"  fetched %d documents.", [res count]];
  
  if (self->fm == nil) {
    NSLog(@"WARNING(%s): fetching without filemanager ...",
          __PRETTY_FUNCTION__);
    return res;
  }
  
  if ((count = [res count]) == 0)
    return res;
  
  array = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    SkyDocument *doc;
    NSString    *path;
    SkyDocument *pdoc;
    
    doc  = [res objectAtIndex:i];
    path = [doc valueForKey:@"NSFilePath"];
    [self debugWithFormat:@"fetched path: %@", path];
    
    if ((pdoc = [self->fm documentCachedAtPath:path]) == nil) {
      pdoc = doc;
      [self->fm addDocumentToCache:pdoc];
      [self debugWithFormat:@"  added document to cache: %@", path];
    }
    
    if (pdoc) [array addObject:pdoc];
  }
  
  return array;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SkyPubDataSource */
