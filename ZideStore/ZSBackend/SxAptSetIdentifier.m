/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxAptManager.h"
#include "common.h"

@implementation SxAptSetIdentifier

+ (id)privateAptSet {
  return [[[self alloc] init] autorelease];
}
+ (id)privateOverviewSet {
  SxAptSetIdentifier *sid = [[[self alloc] init] autorelease];
  sid->overview = YES;
  return sid;
}
+ (id)aptSetForGroup:(NSString *)_group {
  SxAptSetIdentifier *sid = [[[self alloc] init] autorelease];
  sid->group = [_group copy];
  return sid;
}
+ (id)overviewSetForGroup:(NSString *)_group {
  SxAptSetIdentifier *sid = [[[self alloc] init] autorelease];
  sid->group = [_group copy];
  sid->overview = YES;
  return sid;
}

- (void)dealloc {
  [self->group release];
  [super dealloc];
}

/* accessors */

- (BOOL)isOverviewSet {
  return self->overview;
}
- (NSString *)group {
  return self->group;
}

/* filename key */

- (NSString *)flatKey {
  if ([self->group length] > 0) {
    NSString *s;
    s = [self->group stringByEscapingURL];
    return [self->overview ? @"aptoverview-" : @"apt-" stringByAppendingString:s];
  }
  else
    return self->overview ? @"aptoverview-private" : @"apt-private";
}

/* caching */

- (NSString *)cachePrefixInContext:(id)_ctx {
  NSString *loginKey;
  NSString *s;
  
  if ([self->group length] > 0) {
    s = self->overview
      ? [self->group stringByAppendingString:@"-overview"]
      : self->group;
    return [@"calgroup-" stringByAppendingString:s];
  }
  
  loginKey = [[_ctx valueForKey:LSAccountKey] valueForKey:@"login"];
  if (![loginKey isNotNull]) {
    [self logWithFormat:@"got no login from context %@ !", _ctx];
    return nil;
  }
  s = self->overview
    ? [loginKey stringByAppendingString:@"-overview"]
    : loginKey;
  return [@"caluser-" stringByAppendingString:s];
}

/* equality */

- (unsigned)hash {
  return [self->group hash] + (self->overview?1:0);
}

- (BOOL)isEqualToAptSetIdenitifer:(SxAptSetIdentifier *)_other {
  if (_other == nil)  return NO;
  if (_other == self) return YES;
  if (self->overview != _other->overview) return NO;
  return [self->group isEqualToString:_other->group];
}

- (BOOL)isEqual:(id)_obj {
  if (_obj == self) return YES;
  if (![_obj isKindOfClass:[self class]]) return NO;
  return [_obj isEqualToAptSetIdenitifer:self];
}

/* NSCopying */

- (id)copyWithZone:(NSZone *)_zone {
  /* identifiers are immutable */
  return [self retain];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  
  if ([[self group] length] > 0)
    [ms appendFormat:@" group=%@", [self group]];
  else
    [ms appendString:@" private"];
  if ([self isOverviewSet])
    [ms appendString:@" overview"];
  [ms appendString:@">"];
  return ms;
}

@end /* SxAptSetIdentifier */
