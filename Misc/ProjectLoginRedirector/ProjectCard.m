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

#include <NGObjWeb/WOComponent.h>

@class NSURL;

@interface ProjectCard : WOComponent
{
  NSURL *instanceURL;
  id project;
}

@end

#include "PLRConnectionSet.h"
#include "common.h"

@implementation ProjectCard

- (void)dealloc {
  [self->instanceURL release];
  [self->project     release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->project     release]; self->project     = nil;
  [self->instanceURL release]; self->instanceURL = nil;
  [super sleep];
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setInstanceURL:(NSURL *)_url {
  ASSIGNCOPY(self->instanceURL, _url);
}
- (NSURL *)instanceURL {
  return self->instanceURL;
}

- (NSString *)datefmt {
  return @"%Y-%m-%d";
}

- (BOOL)hasProjectLead {
  return [[[[self project] valueForKey:@"leader"] 
                  valueForKey:@"login"] isNotNull];
}
- (NSString *)projectLeadMail {
  return [[self project] valueForKeyPath:@"leader.extendedAttrs.email1"];
}
- (NSString *)projectLeadLink {
  NSString *m;
  
  if ((m = [self projectLeadMail]) == nil)
    return nil;
  
  return [m length] > 0 ? [@"mailto:" stringByAppendingString:m] : nil;
}

/* operations */

@end /* ProjectCard */
