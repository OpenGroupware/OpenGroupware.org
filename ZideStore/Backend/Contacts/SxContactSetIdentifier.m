/*
  Copyright (C) 2000-2003 SKYRIX Software AG

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

#include "SxContactManager.h"
#include "common.h"

@implementation SxContactSetIdentifier

+ (id)publicPersons {
  static SxContactSetIdentifier *Sid = nil;

  if (Sid == nil) {
    Sid = [[self alloc] init];
    Sid->public = YES;
  }
  return Sid;
}

+ (id)privatePersons {
  static SxContactSetIdentifier *Sid = nil;

  if (Sid == nil) {
    Sid = [[self alloc] init];
  }
  return Sid;
}

+ (id)groups {
  static SxContactSetIdentifier *Sid = nil;

  if (Sid == nil) {
    Sid = [[self alloc] init];
    Sid->public = YES;
    Sid->groups = YES;
  }
  return Sid;
}

+ (id)accounts {
  static SxContactSetIdentifier *Sid = nil;

  if (Sid == nil) {
    Sid = [[self alloc] init];
    Sid->public   = YES;
    Sid->accounts = YES;
  }
  return Sid;
}

+ (id)publicEnterprises {
  static SxContactSetIdentifier *Sid = nil;

  if (Sid == nil) {
    Sid = [[self alloc] init];
    Sid->public      = YES;
    Sid->enterprises = YES;
  }
  return Sid;
}

+ (id)privateEnterprises {
  static SxContactSetIdentifier *Sid = nil;

  if (Sid == nil) {
    Sid = [[self alloc] init];
    Sid->enterprises = YES;
  }
  return Sid;
}

/* accessors */

- (BOOL)isGroupSet {
  return self->groups;
}

- (BOOL)isPublicSet {
  return self->public;
}
- (BOOL)isEnterpriseSet {
  return self->enterprises;
}
- (BOOL)isAccountSet {
  return self->accounts;
}

- (NSString *)cachePrefixInContext:(id)_ctx {
  NSString *suff, *pref;
  
  suff = self->public
    ? (NSString *)@""
    : (NSString *)[@"_" stringByAppendingString:
                    [[_ctx valueForKey:LSAccountKey] valueForKey:@"login"]];

  if (self->enterprises)
    pref = @"enterprises";
  else if (self->groups)
    pref = @"groups";
  else
    pref = @"person";

  if (self->public)
    return pref;
  
  suff = [[_ctx valueForKey:LSAccountKey] valueForKey:@"login"];
  suff = [@"_" stringByAppendingString:suff];
  return [pref stringByAppendingString:suff];
}

/* equality */

// TODO: add -hash

- (BOOL)isEqualToIdentifier:(SxContactSetIdentifier *)_sid {
  if (_sid == self) return YES;
  if (_sid == nil)  return NO;
  if ([self isPublicSet]     != [_sid isPublicSet])     return NO;
  if ([self isEnterpriseSet] != [_sid isEnterpriseSet]) return NO;
  if ([self isAccountSet]    != [_sid isAccountSet])    return NO;
  return YES;
}
- (BOOL)isEqual:(id)_sid {
  if (_sid == self) return YES;
  if (_sid == nil)  return NO;
  if (![_sid isKindOfClass:[SxContactSetIdentifier class]]) 
    return NO;
  return [self isEqualToIdentifier:_sid];
}

@end /* SxContactSetIdentifier */
