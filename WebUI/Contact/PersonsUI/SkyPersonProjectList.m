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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray;

@interface SkyPersonProjectList : OGoContentPage
{
@protected
  id person;
}

- (id)person;

@end

#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include <NGObjWeb/NGObjWeb.h>
#include <OGoContacts/SkyPersonDocument.h>
#include "common.h"

@implementation SkyPersonProjectList

- (void)dealloc {
  [self->person release];
  [super dealloc];
}

/* accessors */

- (void)setPerson:(id)_person {
  ASSIGN(self->person, _person);
}
- (id)person {
  return self->person;
}

/* actions */

- (id)assignProject {
  id obj;
  
  if (self->person == nil)
    return nil;
  
  obj = [(id)self->person globalID];
  obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
  obj = [obj lastObject];
  return [self activateObject:obj withVerb:@"assignPersonProjects"];
}

/* conditions */

- (BOOL)isNewAllowed {
  // TODO: use correct type
  id am;
  
  am = [[[self session] valueForKey:@"commandContext"] accessManager];
  return [am operation:@"w" 
	     allowedOnObjectID:[self->person valueForKey:@"globalID"]];
}

@end /* SkyPersonProjectList */
