/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoFoundation/LSWEditorPage.h>

@interface SkyAssignProjectToJobEditor : LSWEditorPage
{
  id project;
}

@end /* SkyAssignProjectToJobEditor */

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>

@implementation SkyAssignProjectToJobEditor

- (void)dealloc {
  [self->project release];
  [super dealloc];
}

/* accessors */

- (id)job {
  return [self object];
}

- (void)setProject:(id)_project {
  ASSIGN(self->project,_project);
}
- (id)project {
  return self->project;
}
  
- (BOOL)isInNewMode {
  return NO;
}

- (NSString *)updateNotificationName {
  return LSWJobHasChanged;
}

/* constraints */

- (BOOL)checkConstraintsForSave {
  if (self->project == nil) {
    [self setErrorString:
          [[self labels] valueForKey:@"error_noProjectSelected"]];
    return NO;
  }
  return [super checkConstraintsForSave];
}

/* actions */

- (id)updateObject {
  NSString *logText;
  
  logText = [[[self project] valueForKey:@"name"] stringValue];
  logText = [@"assigned project " stringByAppendingString:logText];
  
  return [self runCommand:@"job::assign-to-project",
               @"job",     [self job],
               @"project", [self project],
               @"logText", logText,
               nil];
}

@end /* SkyAssignProjectToJobEditor */
