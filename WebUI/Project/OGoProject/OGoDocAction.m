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

#include <NGObjWeb/WODirectAction.h>

@class NGFileManager;
@class EODataSource;

@interface OGoDocAction : WODirectAction
{
  NGFileManager *fileManager;
  EODataSource  *dataSource;
}

@end

#include "common.h"

@implementation OGoDocAction

static BOOL debugOn = YES;

- (void)dealloc {
  [self->fileManager release];
  [self->dataSource  release];
  [super dealloc];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

/* accessors */

- (id)fileManager {
  return self->fileManager;
}

- (id)dataSource {
  if (self->dataSource == nil)
    self->dataSource = [[[self fileManager] dataSourceAtPath:@"."] retain];
  return self->dataSource;
}

- (OGoNavigation *)navigation {
  return [[self existingSession] navigation];
}

/* actions */

- (id)newAction {
  if ([[[self request] formValueForKey:@"epoz"] boolValue]) {
    [[self context] takeValue:[NSNumber numberWithBool:YES]
		    forKey:@"UseEpoz"];
  }
  return [[self navigation]
	   activateObject:[[self dataSource] createObject]
	   withVerb:@"edit"];
}

@end /* OGoDocAction */
