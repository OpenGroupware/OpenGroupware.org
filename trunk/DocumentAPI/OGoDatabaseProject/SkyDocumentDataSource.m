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

#include <OGoDatabaseProject/SkyDocumentDataSource.h>
#include <OGoDatabaseProject/SkyProjectFolderDataSource.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include "common.h"

@implementation SkyDocumentDataSource

- (id)init {
#if DEBUG
  NSLog(@"ERROR(%s): invalid initializer, use 'initWithContext:'",
        __PRETTY_FUNCTION__);
#endif
  [self release];
  return nil;
}

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_pgid {
  SkyProjectFileManager      *fm;
  SkyProjectFolderDataSource *fds;
  
  NSLog(@"WARNING[%@] is DEPRECATED, use SkyProjectFolderDataSource ...",
        NSStringFromClass([self class]));
  
  fm  = [[SkyProjectFileManager alloc] initWithContext:_context
                                       projectGlobalID:_pgid];
  fds = [[fm dataSourceAtPath:@"/"] retain]; 
  RELEASE(fm); fm = nil;
  AUTORELEASE(self);
  return fds;
}

@end /* SkyDocumentDataSource */
