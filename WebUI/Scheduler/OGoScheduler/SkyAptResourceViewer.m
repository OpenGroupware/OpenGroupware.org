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

#include <OGoFoundation/LSWViewerPage.h>

@interface SkyAptResourceViewer : LSWViewerPage
{
}
@end

#include "common.h"
#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <GDLExtensions/GDLExtensions.h>
#include <NGMime/NGMimeType.h>

@implementation SkyAptResourceViewer

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id aptResource;
  
  if (![super prepareForActivationCommand:_command
	      type:_type configuration:_cmdCfg])
    return NO;

  aptResource = [self object];

  if ([[_type type] isEqualToString:@"eo-gid"]) {
      EOGlobalID *gid;
      
      if (![[_type subType] isEqualToString:@"appointmentresource"])
        return NO;
      
      gid = aptResource;
      
      aptResource =
        [self run:@"appointmentresource::get-by-globalid",
                @"gids",     [NSArray arrayWithObject:gid],
                nil];
      aptResource = [aptResource lastObject];
      
      [self setObject:aptResource];
  }

  if (aptResource == nil) {
    [self logWithFormat:@"ERROR: no appointment resource is set!"];
    return NO;
  }
  return YES;
}

/* accessors */

- (NSString *)notificationTime {
  NSNumber *timeNumber;
  id       labels;

  timeNumber = [[self object] valueForKey:@"notificationTime"];
  labels     = [self labels];
  
  if (timeNumber == nil)
    return [labels valueForKey:@"notSet"];

  return [NSString stringWithFormat:@"%@ %@",
                     [labels valueForKey:[timeNumber stringValue]],
                     [labels valueForKey:@"before"]];
}

- (id)aptResource {
  return [self object];
}

@end /* SkyAptResourceViewer */
