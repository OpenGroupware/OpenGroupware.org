/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyPalmDateViewer.h"
#include <OGoPalm/SkyPalmDateDocumentCopy.h>

@interface SkyPalmDateCopyViewer : SkyPalmDateViewer
{
}

@end

#import <Foundation/Foundation.h>
#include <OGoFoundation/OGoFoundation.h>

@implementation SkyPalmDateCopyViewer

- (SkyPalmDateDocumentCopy *)date {
  return (SkyPalmDateDocumentCopy *)[self record];
}

- (SkyPalmDateDocument *)origin {
  return [[self date] origin];
}

// actions
- (id)viewOrigin {
  id page;
  page = [[[self session] navigation] activateObject:[self origin]
                                      withVerb:@"view"];
  return page;
}

- (BOOL)isDetachable {
  return [[self origin] isEditable];
}
- (id)detach {
  id newDate = nil;

  if ((newDate = [[self date] detachFromOrigin]) == nil)
    return nil;

  // remove current viewer from navigation
  [self back];

  return [[[self session] navigation]
                 activateObject:newDate
                 withVerb:@"new"];
}

@end /* SkyPalmDateCopyViewer */
