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

@class NSDictionary;

@interface SkyDockedProjects : OGoComponent
{
  BOOL           isInTextMode;
  NSDictionary   *dockInfo;
  int            maxDockWidth;
}
@end

#include "common.h"

@implementation SkyDockedProjects

- (void)dealloc {
  [self->dockInfo release];
  [super dealloc];
}

/* accessors */

/*
  hasIconData -> YES | NO
  iconData    -> content of "project.gif"
  title       -> project.name
  projectId   -> project.projectId
  globalId    -> globalId
*/

- (void)setDockInfo:(NSDictionary *)_dockInfo {
  ASSIGN(self->dockInfo, _dockInfo);
}
- (NSDictionary *)dockInfo {
  return self->dockInfo;
}

- (void)setIsInTextMode:(BOOL)_flag {
  self->isInTextMode = _flag;
}
- (BOOL)isInTextMode {
  return self->isInTextMode;
}

- (BOOL)disableLinks {
  return [[[[self session] navigation] activePage] isEditorPage];
}

- (int)maxDockLabelWidth {
  if (self->maxDockWidth == 0) {
    self->maxDockWidth = 
      [[[[self session] userDefaults] objectForKey:@"OGoDockLabelWidth"]
        intValue];
    if (self->maxDockWidth < 8) self->maxDockWidth = 16;
  }
  return self->maxDockWidth;
}

- (NSString *)currentDockLabel {
  NSString *s;
  int max;
  
  s = [[[self dockInfo] valueForKey:@"title"] stringValue];
  max = [self maxDockLabelWidth];
  if ([s length] > max) {
    s = [s substringToIndex:(max - 3)];
    s = [s stringByAppendingString:@"..."];
  }
  return s;
}

/* actions */

- (id)viewProject {
  id gid;
  
  gid = [self->dockInfo objectForKey:@"globalId"];
  
  /* check if the project is still there */
  if ([[[self runCommand:@"project::get-by-globalid",
              @"gid", gid, nil] lastObject] isNotNull])
    return [[[self session] navigation] activateObject:gid withVerb:@"view"];
  
  /* didn't find project, refetch */
  [[self session] fetchDockedProjectInfos];
  return nil;
}

@end /* SkyDockedProjects */
