/*
  Copyright (C) 2006 Helge Hess

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

#include "GCalCalendar.h"
#include "GCalEvent.h"
#include "common.h"

@implementation GCalCalendar

- (id)initWithUserFolder:(id)_userFolder {
  if ((self = [super init]) != nil) {
    self->userFolder = [_userFolder retain];
  }
  return self;
}

- (void)dealloc {
  [self->calendarFolder release];
  [self->userFolder release];
  [self->visibility release];
  [self->projection release];
  [super dealloc];
}

/* accessors */

- (NSString *)nameInContainer {
  return [[self userFolder] nameInContainer];
}

- (NSString *)visibility {
  return self->visibility;
}
- (NSString *)projection {
  return self->projection;
}

- (id)userFolder {
  return self->userFolder;
}

/* lookup */

- (id)calendarFolderForVisibility:(NSString *)_vis inContext:(id)_ctx {
  if (![_vis isNotEmpty]) return nil;
  
  if ([_vis isEqualToString:@"public"]) {
    id pubFolder;

    pubFolder = [[self userFolder] lookupName:@"public" inContext:_ctx
				   acquire:NO];
    if (pubFolder == nil) {
      [self errorWithFormat:@"did not find 'public' folder!"];
      return nil;
    }
    if ([pubFolder isKindOfClass:[NSException class]])
      return pubFolder;
    
    return [pubFolder lookupName:@"Calendar" inContext:_ctx acquire:NO];
  }
  
  if ([_vis isEqualToString:@"private"]) {
    // TODO: maybe we should map that to 'Overview"?
    return [[self userFolder] lookupName:@"Calendar" inContext:_ctx
			      acquire:NO];
  }
  
  [self errorWithFormat:@"unsupported visibility: '%@'", _vis];
  return nil;
}

- (GCalEvent *)lookupEvent:(NSString *)_name inContext:(id)_ctx {
  // Note: we do not check the ID, this is done by the actions in the event
  return [[[GCalEvent alloc] initWithName:_name inContainer:self] autorelease];
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_flag {
  /* first step, set visibility */

  if (self->visibility == nil) {
    if (self->calendarFolder != nil) /* contains an error */
      return self->calendarFolder;
    
    self->calendarFolder =
      [[self calendarFolderForVisibility:_name inContext:_ctx]
             retain];
    if (self->calendarFolder == nil || 
	[self->calendarFolder isKindOfClass:[NSException class]])
      return nil;
    
    self->visibility = [_name copy];
    return self;
  }

  /* next step, set projection */

  if (self->projection == nil) {
    self->projection = [_name copy];
    return self;
  }
  
  /* now we either have an event-id in the URL or its a method */

  if (isdigit([_name characterAtIndex:0]))
    return [self lookupEvent:_name inContext:_ctx];
  
  /* treat everything else like a method */
  
  return [super lookupName:_name inContext:_ctx acquire:NO];
}

/* actions */

- (id)GETAction:(WOContext *)_ctx {
  // TODO: implement me
  [self logWithFormat:@"TODO: return feed ..."];
  return [_ctx response];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return YES; // TODO: make that a default
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" name='%@'", [self nameInContainer]];
  [ms appendFormat:@" projection=%@", [self projection]];
  [ms appendFormat:@" visibility=%@", [self visibility]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* GCalCalendar */
