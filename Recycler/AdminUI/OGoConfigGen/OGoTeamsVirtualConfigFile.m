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

#include "OGoTeamsVirtualConfigFile.h"
#include "common.h"
#include <LSFoundation/LSFoundation.h>

@implementation OGoTeamsVirtualConfigFile

static BOOL debugOn = NO;

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

- (void)setIgnoreVirtualAddress:(BOOL)_flag {
  self->ignoreVirtualAddresses = _flag;
}
- (BOOL)ignoreVirtualAddresses {
  return self->ignoreVirtualAddresses;
}

- (BOOL)onlyGenerateTeamsWithEMail {
  return NO;
}
- (BOOL)doNotExportTeamsWithNonASCIINames {
  return YES;
}

- (void)setGenerateTeamEMail:(BOOL)_flag {
  self->generateTeamEMail = _flag;
}
- (BOOL)generateTeamEMail {
  return self->generateTeamEMail;
}
- (void)setDoNotGenerateAccountMails:(BOOL)_flag {
  self->doNotGenerateAccountMails = _flag;
}
- (BOOL)doNotGenerateAccountMails {
  return self->doNotGenerateAccountMails;
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

/* run */

- (NSString *)localAddressForTeam:(NSDictionary *)_team {
  /* properly convert umlauts etc */
  // TODO: should be a NSString category
  NSString *name;
  unsigned i, len;
  
  name = [_team valueForKey:@"description"];
  if (![name isNotNull]) return nil;
  
  for (i = 0, len = [name length]; i < len; i++) {
    unichar c;

    c = [name characterAtIndex:i];
    if (c > 127) break;
  }
  if (i != len) {
    if ([self doNotExportTeamsWithNonASCIINames]) {
      [self logWithFormat:@"not exporting team with non-ASCII name: '%@'",
              name];
      return nil;
    }
    
    [self logWithFormat:@"TODO: team name is not ASCII, convert: '%@'", name];
    // TODO: convert
  }

  name = [name stringByReplacingString:@" " withString:@"_"];
  name = [name lowercaseString];
  
  return name;
}

- (NSException *)produceVirtualEntriesForTeamVirtuals:(NSDictionary *)_team
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  /* generate virtual addresses of team */
  NSUserDefaults *defs;
  id       vaddrs;
  NSString *vaddr, *name, *ename;
  
  if ([self ignoreVirtualAddresses]) /* do not generate team virtuals .. */
    return nil;
  
  name  = [_team valueForKey:@"description"];
  if ((ename = [self localAddressForTeam:_team]) == nil) {
    // TODO: return exception
    [self logWithFormat:@"ERROR: got no localaddress for team: %@", _team];
    return nil;
  }
  
  defs = [self defaultsForTeam:_team inContext:_ctx];
  vaddrs = [defs objectForKey:@"admin_vaddresses"];
  if ([vaddrs isKindOfClass:[NSString class]]) {
    // TODO: fix broken ^M chars! (textarea with Safari?)
    vaddrs = [vaddrs stringByReplacingString:@"\r" withString:@""];
    vaddrs = [vaddrs componentsSeparatedByString:@"\n"];
  }
  if (![vaddrs isKindOfClass:[NSArray class]]) {
    [self debugWithFormat:@"no vaddrs for team: '%@'", name];
    return nil;
  }
  
  [self debugWithFormat:@"team %@ gen vaddrs: %@",  name, vaddrs];
  
  vaddrs = [vaddrs objectEnumerator];
  while ((vaddr = [vaddrs nextObject])) {
    NSException *error;
    
    vaddr = [vaddr stringByTrimmingSpaces];
    if ([vaddr length] == 0) continue;
    
    error = [_consumer virtualConfigFile:self
		       forwardMailToAddress:vaddr
		       toAddresses:[NSArray arrayWithObject:ename]];
    if (error) return error;
  }
  return nil;
}

- (NSException *)produceVirtualEntriesForTeam:(NSDictionary *)_team
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
#warning TODO: support team-mailboxes
  NSException    *error;
  EOGlobalID     *teamGID;
  NSString       *email, *name, *ename;
  NSArray        *memberGIDs, *members;
  NSEnumerator   *e;
  NSDictionary   *member;
  NSMutableArray *memberMailboxes;
  
  teamGID = [_team valueForKey:@"globalID"];
  email   = [_team valueForKey:@"email"];
  name    = [_team valueForKey:@"description"];
  
  if (![email isNotNull] && [self onlyGenerateTeamsWithEMail])
    return nil;
  
  if ((ename = [self localAddressForTeam:_team]) == nil) {
    // TODO: return exception
    if (![self doNotExportTeamsWithNonASCIINames])
      [self logWithFormat:@"ERROR: got no localaddress for team: %@", _team];
    return nil;
  }
  
  [self debugWithFormat:@"produce ventry for team '%@': '%@'", name, ename];
  
  memberGIDs = [self fetchAccountGlobalIDsForTeamGlobalID:teamGID 
		     inContext:_ctx];
  if ([memberGIDs count] == 0) {
    // TODO: currently a requirement, we might want to support "team" mailboxes
    [self debugWithFormat:@"  team without members, generate nothing: '%@'",
	    name];
    return nil;
  }
  
  /* member mapping */
  
  memberMailboxes = nil;
  members = [self fetchAccountLoginsForGlobalIDs:memberGIDs inContext:_ctx];
  e = [members objectEnumerator];
  while ((member = [e nextObject])) {
    if (![self shouldExportAccount:member inContext:_ctx]) {
      [self debugWithFormat:@"    export of account disabled: %@", 
	      [member valueForKey:@"login"]];
      continue;
    }
    
    if (memberMailboxes == nil)
      memberMailboxes = [NSMutableArray arrayWithCapacity:128];
    [memberMailboxes addObject:[member valueForKey:@"login"]];
  }
  if ([memberMailboxes count] == 0) {
    [self debugWithFormat:
	    @"  team has no exportable members, generate nothing: '%@'", name];
    return nil;
  }
  
  error = [_consumer virtualConfigFile:self
		     forwardMailToAddress:ename
		     toAddresses:memberMailboxes];
  if (error) return error;
  
  /* team email */
  
  if ([email isNotNull] && [self generateTeamEMail]) {
    /* generate an alias for the mail address set for the team */
    error = [_consumer virtualConfigFile:self
		       forwardMailToAddress:email
		       toAddresses:[NSArray arrayWithObject:ename]];
    if (error) return error;
  }
  
  /* virtual addresses from defaults */
  error = [self produceVirtualEntriesForTeamVirtuals:_team
		onConsumer:_consumer
		inContext:_ctx];
  
  return nil;
}

- (NSException *)produceVirtualEntriesForTeams:(NSArray *)_teams
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  // TODO: use aggregate exceptions?
  NSException  *error;
  NSEnumerator *e;
  NSDictionary *team;
  
  [self debugWithFormat:@"producing virtual entries for %d teams ...",
	  [_teams count]];
  
  error = nil;
  e = [_teams objectEnumerator];
  while ((team = [e nextObject]) && (error == nil)) {
    if (![self shouldExportTeam:team inContext:_ctx]) {
      [self debugWithFormat:@"not exporting team: %@", team];
      continue;
    }

    error = [self produceVirtualEntriesForTeam:team 
		  onConsumer:_consumer
		  inContext:_ctx];
  }
  
  [self debugWithFormat:@"done: %@", error];
  return error;
}  

- (NSException *)produceVirtualEntriesOnConsumer:(id<OGoVirtualEntryConsumer>)e
  inContext:(id)_ctx
{
  NSArray *teams;
  
  if ([self ignoreExportFlag])
    /* do not export */
    return nil;
  
  if ((teams = [self fetchTeamGlobalIDsInContext:_ctx]) == nil) {
    [self logWithFormat:@"Note: could not fetch teams GIDs!"];
    return nil;
  }
  if ((teams = [self fetchTeamEmailsForGlobalIDs:teams inContext:_ctx])==nil) {
    [self logWithFormat:@"Note: could not fetch team email information!"];
    return nil;
  }
  
  return [self produceVirtualEntriesForTeams:teams 
	       onConsumer:e inContext:_ctx];
}

/* testing */

- (void)doSomeStuffInContext:(LSCommandContext *)_ctx {
  id tmp;
  
  tmp = [self fetchTeamGlobalIDsInContext:_ctx];
  [self logWithFormat:@"team-gids: %@", tmp];
  [self logWithFormat:@"  emails: %@", 
	  [self fetchTeamEmailsForGlobalIDs:tmp inContext:_ctx]];
  
  tmp = [self fetchAccountGlobalIDsForTeamGlobalID:[tmp objectAtIndex:0] 
	      inContext:_ctx];
  [self logWithFormat:@"  accounts: %@", tmp];
  
#if 0
  tmp = [self fetchAllTeamEOsInContext:_ctx];
  [self logWithFormat:@"team-EOs: %@", tmp];
  [self logWithFormat:@"  emails: %@", [tmp valueForKey:@"email"]];
  [self logWithFormat:@"  description: %@", [tmp valueForKey:@"description"]];
#endif
}

/* factory */

+ (NSArray *)configFileStorageKeys {
  static NSArray *cf = nil;
  if (cf) return cf;

  cf = [[NSArray alloc] initWithObjects:
                          @"ignoreExportFlag",  @"ignoreVirtualAddresses",
                          @"generateTeamEMail", @"doNotGenerateAccountMails",
                          @"rawPrefix", @"rawSuffix",
                        nil];
  return cf;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoTeamsVirtualConfigFile */
