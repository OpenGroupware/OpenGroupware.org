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

#include "SkyPubInlineViewer.h"

@class SkyPubLink;

@interface SkyPubLinks : SkyPubInlineViewer
{
  NSArray    *links;
  SkyPubLink *link; /* transient */
}
@end

#include "SkyPubLinkManager.h"
#include "SkyPubLink+Activation.h"
#include "common.h"
#include <DOM/EDOM.h>

@implementation SkyPubLinks

- (void)dealloc {
  RELEASE(self->link);
  RELEASE(self->links);
  [super dealloc];
}

/* notifications */

- (void)sleep {
  RELEASE(self->links); self->links = nil;
  RELEASE(self->link);  self->link = nil;
  [super sleep];
}

/* accessors */

- (NSArray *)links {
  if (self->links == nil) {
    id doc;
    id dom;
    
    if ((doc = [self document]) == nil) {
      [self logWithFormat:@"no document ???"];
      return nil;
    }
    if ((dom = [doc contentAsDOMDocument]) == nil) {
      [self logWithFormat:@"no DOM for document %@ ???", doc];
      return nil;
    }
    
    self->links = [[[self linkManager] allLinks] copy];
  }
  return self->links;
}

- (void)setLink:(SkyPubLink *)_link {
  ASSIGN(self->link, _link);
}
- (SkyPubLink *)link {
  return self->link;
}

- (NSString *)linkTargetURL {
  return [[self link] skyrixUrlInContext:[self context]];
}

@end /* SkyPubLinks */
