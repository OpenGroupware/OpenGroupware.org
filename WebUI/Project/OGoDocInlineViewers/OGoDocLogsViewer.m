/*
  Copyright (C) 2005 Helge Hess

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

#include <OGoDocInlineViewers/OGoDocPartViewer.h>

@interface OGoDocLogsViewer : OGoDocPartViewer
{
  EODataSource *ds;
}

@end

#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoBase/SkyLogDataSource.h>
#include <NGExtensions/EOCacheDataSource.h>
#include "common.h"

@implementation OGoDocLogsViewer

static EOQualifier *actionDownloadQual = nil;

+ (void)initialize {
  if (actionDownloadQual == nil) {
    actionDownloadQual = 
      [[EOQualifier qualifierWithQualifierFormat:@"action='download'"] retain];
  }
}

- (void)dealloc {
  [self->ds release];
  [super dealloc];
}

/* notifications */

- (void)reset {
  [(EOCacheDataSource *)self->ds clear];
  [super reset];
}

/* accessors */

- (id)_commandContext {
  return [(OGoSession *)[self session] commandContext];
}

- (EOFetchSpecification *)_fspec {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"log"
                               qualifier:actionDownloadQual sortOrderings:nil];
}

- (EODataSource *)logDataSource {
  SkyLogDataSource *rds;
  
  if (self->ds)
    return self->ds;

  rds = [[SkyLogDataSource alloc] initWithContext:[self _commandContext]
				  globalID:[self->document globalID]];
  [rds setFetchSpecification:[self _fspec]];
  [rds autorelease];
  
  self->ds = [[EOCacheDataSource alloc] initWithDataSource:rds];
  return self->ds;
}

@end /* OGoDocLogsViewer */
