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

#include <OGoFoundation/OGoComponent.h>

/*
  > document   // the SkyProjectDocument to show the logs
*/

@class EODataSource;
@class SkyProjectDocument;

@interface SkyP4DocumentDownloadLogList : OGoComponent
{
  SkyProjectDocument *document; // >              <= what does that mean??

  EODataSource *ds;
}

@end

#include "common.h"

@implementation SkyP4DocumentDownloadLogList

static EOQualifier *actionDownloadQual = nil;
static EOFetchSpecification *fspec = nil;

+ (void)initialize {
  if (actionDownloadQual == nil) {
    actionDownloadQual = 
      [[EOQualifier qualifierWithQualifierFormat:@"action='download'"] retain];
    
    fspec = [[EOFetchSpecification fetchSpecificationWithEntityName:@"log"
				   qualifier:actionDownloadQual 
				   sortOrderings:nil] retain];
  }
}

- (void)dealloc {
  [self->document release];
  [self->ds       release];
  [super dealloc];
}

/* accessors */

- (void)setDocument:(SkyProjectDocument *)_doc {
  ASSIGN(self->document, _doc);
}
- (SkyProjectDocument *)document {
  return self->document;
}

/* notifications */

- (void)sleep {
  [super sleep];
  [self->ds release]; self->ds = nil;
}

/* accessors */

- (id)_commandContext {
  return [(OGoSession *)[self session] commandContext];
}

- (EODataSource *)dataSource {
  SkyLogDataSource *rds;
  
  if (self->ds != nil)
    return self->ds;
  
  rds = [[SkyLogDataSource alloc] initWithContext:[self _commandContext]
				  globalID:[self->document globalID]];
  [rds setFetchSpecification:fspec];
  
  self->ds = [[EOCacheDataSource alloc] initWithDataSource:rds];
  [rds release];
  return self->ds;
}

@end /* SkyP4DocumentDownloadLogList */
