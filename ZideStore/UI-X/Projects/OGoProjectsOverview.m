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

#include "OGoProjectView.h"

@class NSString;
@class EODataSource;

@interface OGoProjectsOverview : OGoProjectView
{
  NSString     *projectName;
  EODataSource *docDS;
}

@end

#include "common.h"
#include <Projects/SxProjectsFolder.h>

@implementation OGoProjectsOverview

- (void)dealloc {
  [self->docDS       release];
  [self->projectName release];
  [super dealloc];
}

/* accessors */

- (void)setProjectName:(NSString *)_name {
  ASSIGN(self->projectName, _name);
}
- (NSString *)projectName {
  return self->projectName;
}

- (NSString *)pageTitle {
  return [[[[self clientObject] container] nameInContainer] capitalizedString];
}

- (NSString *)datefmt {
  return @"%Y-%m-%d";
}

/* URL generation */

- (NSString *)projectViewURL {
  // TODO: add a new namespace: "varx:href='$projectName$/view'"
  return [[[self valueForKey:@"project"] valueForKey:@"number"] 
	         stringByAppendingString:@"/view"];
}

/* model layer */

- (EODataSource *)rawContentDataSource {
  if (self->docDS) return self->docDS;
  self->docDS = [[[self clientObject] 
		   rawContentDataSourceInContext:[self context]] retain];
  return self->docDS;
}

/* notifications */

- (void)sleep {
  [self->docDS release]; self->docDS = nil;
  [super sleep];
}

@end /* OGoProjectsOverview */
