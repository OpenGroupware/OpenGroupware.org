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

#include "SkyImapMailRestrictions.h"
#include "common.h"
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>
#include <EOControl/EOKeyGlobalID.h>

@implementation SkyImapMailRestrictions

- (id)initWithContext:(id)_context {
  NSNumber *accId;

  accId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  return [self initWithContext:_context companyId:accId];
}
- (id)initWithContext:(id)_context companyId:(NSNumber *)_cId {
  if ((self = [self init])) {
    self->companyId = [_cId     copy];
    self->context   = [_context retain];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->restrictionsConfig);
  RELEASE(self->restrictions);
  RELEASE(self->companyId);
  RELEASE(self->context);
  [super dealloc];
}

/* accessors */

- (NSDictionary *)restrictionsConfig {
  if (self->restrictionsConfig == nil) {
    NSString            *filename;
    NSMutableDictionary *md;
    NSMutableArray      *ma;

    filename = [[[NSProcessInfo processInfo] environment]
                                objectForKey:@"GNUSTEP_USER_ROOT"];
    filename = [filename stringByAppendingPathComponent:@"config"];
    filename = [filename stringByAppendingPathComponent:
                         @"MailRestrictions.plist"];
    if (filename != nil) {
      NSEnumerator *e  = nil;
      id           key = nil;
      id           one = nil;
      
      self->restrictionsConfig =
        [NSDictionary dictionaryWithContentsOfFile:filename];

      if (self->restrictionsConfig == nil) return nil;

      md = [NSMutableDictionary dictionaryWithCapacity:
                                [self->restrictionsConfig count]];
      ma = [NSMutableArray array];
      e  = [self->restrictionsConfig keyEnumerator];
      
      while ((key = [e nextObject])) {
        if ([key intValue] > 10000)
          // check if valid company_id
          // root is ignored, root may not have restrictions
          [md setObject:[self->restrictionsConfig valueForKey:key]
              forKey:key];
        else
          // assume that it's a team description
          [ma addObject:key];
      }

      e = [ma objectEnumerator];
      while ((key = [e nextObject])) {
        one = [self->context runCommand:@"team::get",
                   @"description", key, nil];
        if ([one count] == 0) {
          NSLog(@"%s Didn't find team with description %@!",
                __PRETTY_FUNCTION__, key);
        }
        else if ([one count] != 1) {
          NSLog(@"%s Team description %@ isn't unique!",
                __PRETTY_FUNCTION__, key);
        }
        else {
          [md setObject:[self->restrictionsConfig valueForKey:key]
              forKey:[[[one lastObject] valueForKey:@"companyId"]
                            stringValue]];
        }
      }

      self->restrictionsConfig = [md copy];
    }
  }
  return self->restrictionsConfig;
}

- (NSNumber *)companyId {
  if (self->companyId == nil)
    self->companyId = [self->context valueForKey:LSAccountKey];
  return self->companyId;
}

// may be team id or company id
// fetches only what is in the config file
- (NSArray *)restrictionsForCompanyId:(NSNumber *)_cId {
  return [[self restrictionsConfig] valueForKey:[_cId stringValue]];
}

// nil means no restriction to any address
// empty array means no permition to any address
- (NSArray *)restrictions {
  if (self->notRestricted) 
    return nil;
  if (self->restrictions == nil) {
    NSMutableArray *ma;
    id             keys[1];
    id             gid;
    BOOL           noAccountRestr = NO;

    keys[0] = [self companyId];
    gid     = [EOKeyGlobalID globalIDWithEntityName:@"Account"
                             keys:keys keyCount:1 zone:NULL];
    ma      = [NSMutableArray arrayWithCapacity:4];

    if ([[self companyId] intValue] == 10000) {// root
      self->notRestricted = YES;
      return nil;
    }

    if ([self restrictionsConfig] == nil) { // no file found
      self->notRestricted = YES;
      return nil;
    }

    {
      NSArray *accountRestr = [self restrictionsForCompanyId:[self companyId]];
      if (accountRestr == nil)
        noAccountRestr = YES;
      else
        [ma addObjectsFromArray:accountRestr];
    }


    { // fetching teams
      NSArray      *teams;
      NSEnumerator *e;
      id           one;

      teams = [self->context runCommand:@"account::teams",
                   @"account",        gid,
                   @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                   nil];

      if (([teams count] == 0) && noAccountRestr) {
        // account has no teams and account has no restrictions
        self->notRestricted = YES;
        return nil;
      }
      
      e     = [teams objectEnumerator];

      while ((one = [e nextObject])) {
        one = [self restrictionsForCompanyId:[one keyValues][0]];
        if (one == nil) {
          // not set means no restrictions
          self->notRestricted = YES;
          return nil;
        }
        // if array is empty it means restricted but no domains added
        [ma addObjectsFromArray:one];
      }
      self->restrictions = [ma copy];
    }
  }
  return self->restrictions;
}

- (BOOL)emailAddressAllowed:(NSString *)_email {
  NSRange  r;
  NSString *domain;
  NSArray  *restr;

  if (self->notRestricted) return YES;

  r = [_email rangeOfString:@"@"];
  if (r.length == 0) {
    // no domain (@) found ... so allowed
    // sendmail will add localhost or as configured
    return YES;
  }

  domain = [_email substringFromIndex:(r.location + r.length)];

  restr = [self restrictions];
  if (restr == nil) {
    // no restrictions
    // so allowed
    return YES;
  }
  
  
  if (![restr containsObject:domain]) {
    // no permition found
    return NO;
  }
  return YES;
}

- (NSArray *)allowedDomains {
  return [self restrictions];
}

@end /* SkyImapMailRestrictions */
