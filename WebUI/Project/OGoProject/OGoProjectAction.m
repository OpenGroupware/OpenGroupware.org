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

#include <NGObjWeb/WODirectAction.h>

@interface OGoProjectAction : WODirectAction
@end

#include "common.h"
#include <NGMime/NGMimeType.h>

@implementation OGoProjectAction

static NGMimeType *eoProjectType = nil;

+ (void)initialize {
  if (eoProjectType == nil)
    eoProjectType = [[NGMimeType mimeType:@"eo" subType:@"project"] retain];
}

/* accessors */

- (OGoNavigation *)navigation {
  return [[self existingSession] navigation];
}

/* actions */

- (id)newAction {
  return [[self session] instantiateComponentForCommand:@"new" 
			 type:eoProjectType];
}

- (id)error {
  NSString    *error;
  WOComponent *page;
  
  page = [[self navigation] activePage];
  if ((error = [[self request] formValueForKey:@"error"]))
    [page takeValue:error forKey:@"errorString"];
  return page;
}

@end /* OGoProjectAction */
