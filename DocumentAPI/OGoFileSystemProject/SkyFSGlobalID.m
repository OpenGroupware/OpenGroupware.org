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
//$Id: SkyFSGlobalID.m 1 2004-08-20 11:17:52Z znek $

#include "SkyFSGlobalID.h"
#include "common.h"

@implementation SkyFSGlobalID

- (id)initWithPath:(NSString *)_path projectGID:(EOGlobalID *)_pid {
  if ((self = [super init])) {
    self->path       = [_path copy];
    self->projectGID = [_pid retain];
  }
  return self;
}

- (void)dealloc {
  [self->path       release];
  [self->projectGID release];
  [super dealloc];
}

/* accessors */

- (EOGlobalID *)projectGID {
  return self->projectGID;
}

- (NSString *)path {
  return self->path;
}

/* NSCopying */

- (SkyFSGlobalID *)copyWithZone:(NSZone *)_zone {
  return [[SkyFSGlobalID alloc] initWithPath:self->path
                                projectGID:self->projectGID];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->path)       [ms appendFormat:@" path=%@", self->path];
  if (self->projectGID) [ms appendFormat:@" project=%@", self->projectGID];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SkyFSGlobalID */
