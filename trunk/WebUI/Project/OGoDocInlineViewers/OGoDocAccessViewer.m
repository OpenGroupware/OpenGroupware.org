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

@interface OGoDocAccessViewer : OGoDocPartViewer
{
}

@end

#include "common.h"

@implementation OGoDocAccessViewer

+ (BOOL)canShowInDocumentViewer:(OGoComponent *)_viewer {
  if ([[_viewer valueForKey:@"isVersion"] boolValue])
    return NO;
  
  if (![[_viewer valueForKey:@"fileManager"] supportAccessRights])
    return NO;
  
  return [super canShowInDocumentViewer:_viewer];
}

/* accessors */

- (NSDictionary *)accessIds {
  LSCommandContext *cmdctx;
  
  cmdctx = [(OGoSession *)[self session] commandContext];
  return [[cmdctx accessManager] 
	          allowedOperationsForObjectId:[self documentGlobalID]];
}

- (NSArray *)accessChecks {
  static NSArray *accessChecks = nil;
  if (accessChecks == nil)
    accessChecks = [[NSArray alloc] initWithObjects:@"r", @"w", nil];
  return accessChecks;
}

/* actions */

- (id)editAccess {
  WOComponent *page;

  // TODO: use activation?!
  if ((page = [self pageWithName:@"SkyCompanyAccessEditor"]) == nil) {
    [[[self context] page] setErrorString:@"could not find access editor !"];
    return nil;
  }
  
  [page takeValue:[self documentGlobalID] forKey:@"globalID"];
  [page takeValue:[self accessChecks]     forKey:@"accessChecks"];
  return page;
}

@end /* OGoDocAccessViewer */
