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

#include "OGoQuotaTabConfigFile.h"
#include "OGoQuotaTabExporter.h"
#include "common.h"

@implementation OGoQuotaTabConfigFile

- (void)dealloc {
  [self->rawPrefix release];
  [self->rawSuffix release];
  [super dealloc];
}

/* accessors */

- (void)setIgnoreExportFlag:(BOOL)_flag {
  self->ignoreExportFlag = _flag;
}
- (BOOL)ignoreExportFlag {
  return self->ignoreExportFlag;
}
- (void)setIgnoreTeamsFlag:(BOOL)_flag {
  self->ignoreTeamsFlag = _flag;
}
- (BOOL)ignoreTeamsFlag {
  return self->ignoreTeamsFlag;
}

- (void)setRawPrefix:(NSString *)_s {
  ASSIGNCOPY(self->rawPrefix, _s);
}
- (NSString *)rawPrefix {
  return self->rawPrefix;
}
- (void)setRawSuffix:(NSString *)_s {
  ASSIGNCOPY(self->rawSuffix, _s);
}
- (NSString *)rawSuffix {
  return self->rawSuffix;
}

/* exporter */

- (id)exporterInContext:(id)_ctx {
  return [OGoQuotaTabExporter sharedQuotaTabExporter];
}

/* fetching */

- (NSDictionary *)quotaTabEntryForAccount:(id)_account inContext:(id)_ctx {
  NSString *login;
  id       quota;
  
  login = [_account valueForKey:@"login"];
  if (![login isNotNull]) {
    [self logWithFormat:@"WARNING: account has no login: %@", _account];
    return nil;
  }
  
  if (![self shouldExportAccount:_account inContext:_ctx]) {
    [self debugWithFormat:@"export of account disabled: %@", login];
    return nil;
  }
    
  quota = [[self defaultsForAccount:_account inContext:_ctx] 
                 objectForKey:@"admin_mailquota"];
  if (![quota isNotNull]) quota = nil;
  
  if (quota == nil)
    return [NSDictionary dictionaryWithObject:login forKey:@"mailbox"];
  
  return [NSDictionary dictionaryWithObjectsAndKeys:login, @"mailbox",
                         quota, @"quota", nil];
}

- (NSDictionary *)quotaTabEntryForTeam:(id)_team inContext:(id)_ctx {
  NSUserDefaults *defs;
  NSString *tname;
  
  tname = [_team valueForKey:@"description"];
  if (![tname isNotNull]) {
    [self logWithFormat:@"WARNING: team has no name: %@", _team];
    return nil;
  }
  if (![self shouldExportTeam:_team inContext:_ctx]) {
    [self debugWithFormat:@"Note: export of team disabled: %@", tname];
    return nil;
  }
  
  if ((defs = [self defaultsForTeam:_team inContext:_ctx]) == nil) {
    [self logWithFormat:@"Note: got no defaults object for team: %@", tname];
    return nil;
  }
  
  tname = [defs stringForKey:@"admin_team_mailbox"];
  if (![tname isNotNull]) return nil;
  tname = [tname stringByTrimmingSpaces];
  if ([tname length] == 0) return nil;
  
  return [NSDictionary dictionaryWithObject:tname forKey:@"mailbox"];
}

- (NSArray *)generateQuotaTabEntriesInContext:(id)_ctx {
  NSMutableArray *ma;
  NSArray  *accounts, *teams;
  unsigned i, count;
  
  ma = [NSMutableArray arrayWithCapacity:256];

  /* process account mailboxes */
  
  accounts = [self fetchAllAccountEOsInContext:_ctx];
  for (i = 0, count = [accounts count]; i < count; i++) {
    NSDictionary *entry;

    entry = [self quotaTabEntryForAccount:[accounts objectAtIndex:i]
                  inContext:_ctx];
    if (entry == nil) continue;
    
    [ma addObject:entry];
  }
  
  /* process team mailboxes */
  if (![self ignoreTeamsFlag]) {
    teams = [self fetchAllTeamEOsInContext:_ctx];
    for (i = 0, count = [teams count]; i < count; i++) {
      NSDictionary *entry;
      
      entry = [self quotaTabEntryForTeam:[teams objectAtIndex:i]
                    inContext:_ctx];
      if (entry == nil) continue;
    
      [ma addObject:entry];
    }
  }
  
  return ma;
}

/* KVC */

- (void)takeValue:(id)_val forKey:(NSString *)_key {
  // dummy
}

/* factory */

+ (NSArray *)configFileStorageKeys {
  static NSArray *cf = nil;
  if (cf) return cf;

  cf = [[NSArray alloc] initWithObjects:
                          @"ignoreExportFlag",  @"ignoreTeamsFlag",
                          @"rawPrefix", @"rawSuffix",
                        nil];
  return cf;
}

@end /* OGoQuotaTabConfigFile */
