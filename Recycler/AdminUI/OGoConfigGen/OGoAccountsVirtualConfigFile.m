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

#include "OGoAccountsVirtualConfigFile.h"
#include "common.h"
#include <LSFoundation/LSFoundation.h>

@implementation OGoAccountsVirtualConfigFile

static NSArray *coreFetchAttrs = nil;

+ (void)initialize {
  if (coreFetchAttrs == nil) {
    coreFetchAttrs = [[NSArray alloc] initWithObjects:
                                        @"companyId",
                                        @"emailAlias",
                                        @"login", @"nickname",
                                        @"firstname", 
                                        @"middlename", @"name", @"number",
                                        @"extendedAttributes",
                                      nil];
  }
}

- (void)dealloc {
  [self->localDomainPatterns release];
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
- (void)setIgnoreVirtualAddresses:(BOOL)_flag {
  self->ignoreVirtualAddresses = _flag;
}
- (BOOL)ignoreVirtualAddresses {
  return self->ignoreVirtualAddresses;
}
  
- (void)setIgnoreLocalDomains:(BOOL)_flag {
  self->ignoreLocalDomains = _flag;
}
- (BOOL)ignoreLocalDomains {
  return self->ignoreLocalDomains;
}
- (void)setLocalDomainPatterns:(NSArray *)_array {
  ASSIGNCOPY(self->localDomainPatterns, _array);
}
- (NSArray *)localDomainPatterns {
  return self->localDomainPatterns;
}
  
- (void)setGenerateEmail1:(BOOL)_flag {
  self->generateEmail1 = _flag;
}
- (BOOL)generateEmail1 {
  return self->generateEmail1;
}
- (void)setGenerateEmail2:(BOOL)_flag {
  self->generateEmail2 = _flag;
}
- (BOOL)generateEmail2 {
  return self->generateEmail2;
}
- (void)setGenerateEmail3:(BOOL)_flag {
  self->generateEmail3 = _flag;
}
- (BOOL)generateEmail3 {
  return self->generateEmail3;
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

- (BOOL)doNotExportLoginsWithNonASCIINames {
  return YES;
}

- (NSString *)localAddressForLogin:(NSString *)_login {
  /* properly convert umlauts etc */
  // TODO: should be a NSString category
  NSString *name;
  unsigned i, len;
  
  name = _login;
  if (![name isNotNull]) return nil;
  
  for (i = 0, len = [name length]; i < len; i++) {
    unichar c;

    c = [name characterAtIndex:i];
    if (c > 127) break;
  }
  if (i != len) {
    if ([self doNotExportLoginsWithNonASCIINames]) {
      [self logWithFormat:
              @"not exporting account with non-ASCII login: '%@'",
              name];
      return nil;
    }
    
    [self logWithFormat:@"TODO: login name is not ASCII, convert: '%@'", name];
    // TODO: convert
  }
  
  name = [name stringByReplacingString:@" " withString:@"_"];
  name = [name lowercaseString];
  
  return name;
}

- (NSException *)produceVirtualEntriesForAccountVirtuals:(NSDictionary *)_acc
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  /* generate virtual addresses of account */
  NSUserDefaults *defs;
  id       vaddrs;
  NSString *vaddr, *name, *ename;
  
  if ([self ignoreVirtualAddresses]) /* do not generate account virtuals .. */
    return nil;
  
  name = [_acc valueForKey:@"login"];
  if ((ename = [self localAddressForLogin:name]) == nil) {
    // TODO: return exception
    [self logWithFormat:@"ERROR: got no localaddress for account: %@", _acc];
    return nil;
  }
  
  defs = [self defaultsForAccount:_acc inContext:_ctx];
  vaddrs = [defs objectForKey:@"admin_vaddresses"];
  if ([vaddrs isKindOfClass:[NSString class]]) {
    // TODO: fix broken ^M chars! (textarea with Safari?)
    vaddrs = [vaddrs stringByReplacingString:@"\r" withString:@""];
    vaddrs = [vaddrs componentsSeparatedByString:@"\n"];
  }
  if (![vaddrs isKindOfClass:[NSArray class]]) {
    [self debugWithFormat:@"no vaddrs for account: '%@'", name];
    return nil;
  }
  
  [self debugWithFormat:@"account %@ gen vaddrs: %@", name, vaddrs];
  
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

- (NSException *)produceVirtualEntriesForAccountEmail123:(NSDictionary *)_acc
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  static NSString *emailKeys[4] = { @"email1", @"email2", @"email3", nil };
  NSException *error;
  NSString *name, *ename;
  unsigned i;
  
  [self debugWithFormat:@"produce email 123"];

  name = [_acc valueForKey:@"login"];
  if ((ename = [self localAddressForLogin:name]) == nil) {
    // TODO: return exception
    [self logWithFormat:@"ERROR: got no localaddress for account: %@", _acc];
    return nil;
  }

  for (i = 0; emailKeys[i]; i++) {
    NSString *k = emailKeys[i];
    NSString *email;
    
    if ((email = [_acc objectForKey:k]) == nil) continue;
    if (![email isNotNull]) continue;
    if ([email length] == 0) continue;
    
    if ([email hasSuffix:@"1"] && ![self generateEmail1])
      continue;
    else if ([email hasSuffix:@"2"] && ![self generateEmail2])
      continue;
    else if ([email hasSuffix:@"3"] && ![self generateEmail3])
      continue;
    
    error = [_consumer virtualConfigFile:self
                       forwardMailToAddress:email
                       toAddresses:[NSArray arrayWithObject:ename]];
    if (error) return error;
  }
  return nil;
}

- (void)cannotProcessPattern:(NSString *)_pat forAccount:(NSDictionary *)_a
  exception:(NSException *)_exc
{
  [self debugWithFormat:@"Note: cannot process pattern '%@' for '%@'!",
          _pat, [_a valueForKey:@"login"]];
}

- (NSException *)produceVirtualEntriesForAccount:(NSDictionary *)_acc
  inLocalDomain:(NSString *)_domain withMailbox:(NSString *)_mbox
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  NSException  *error = nil;
  NSEnumerator *pate;
  NSString     *pattern;

  pate = [[self localDomainPatterns] objectEnumerator];
  while ((pattern = [pate nextObject])) {
    /* eg: $login$ */
    NSString *leftSide;
    NSString *email;

    if ([pattern length] == 0)
      continue;
    
    NS_DURING
      leftSide = [pattern stringByReplacingVariablesWithBindings:_acc
                          stringForUnknownBindings:nil];
    NS_HANDLER {
      [self cannotProcessPattern:pattern forAccount:_acc
            exception:localException];
      *(&leftSide) = nil;
    }
    NS_ENDHANDLER;
    
    leftSide = [self localAddressForLogin:leftSide];
    if ([leftSide length] == 0) continue;
    
    email = [NSString stringWithFormat:@"%@@%@", leftSide, _domain];
    
    error = [_consumer virtualConfigFile:self
                       forwardMailToAddress:email
                       toAddresses:[NSArray arrayWithObject:_mbox]];
    if (error) return error;
  }
  return nil;
}

- (NSException *)produceVirtualEntriesForAccount:(NSDictionary *)_acc
  inLocalDomains:(NSArray *)_domains
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  NSException  *error;
  NSString     *name, *ename;
  NSEnumerator *en;
  NSString     *domain;
  
  name = [_acc valueForKey:@"login"];
  if ((ename = [self localAddressForLogin:name]) == nil) {
    // TODO: return exception
    [self logWithFormat:@"ERROR: got no localaddress for account: %@", _acc];
    return nil;
  }
  [self debugWithFormat:@"produce local domains of '%@': %@", name,
          [_domains componentsJoinedByString:@", "]];
  
  en = [_domains objectEnumerator];
  while ((domain = [en nextObject])) {
    /* now for each pattern */
    error = [self produceVirtualEntriesForAccount:_acc 
                  inLocalDomain:domain withMailbox:ename
                  onConsumer:_consumer inContext:_ctx];
    if (error) return error;
  }
  
  return nil;
}

- (NSException *)produceVirtualEntriesForAccount:(NSDictionary *)_account
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  NSString     *login;
  NSDictionary *attrmap;
  NSException  *error   = nil;
  NSArray      *domains = nil;
  
  login   = [_account valueForKey:@"login"];
  attrmap = [_account valueForKey:@"attributeMap"];
  if (![login isNotNull]) {
    [self logWithFormat:@"ERROR: found no login in account: %@", _account];
    return nil;
  }

#if 0
  [self logWithFormat:@"do account: %@", login];
  [self logWithFormat:@"  dict: %@", _account];
#endif
  
  domains = [[self defaultsForAccount:_account inContext:_ctx] 
                   arrayForKey:@"admin_LocalDomainAliases"];
  if ([domains count] > 0) {
    error = [self produceVirtualEntriesForAccount:_account
                  inLocalDomains:domains
                  onConsumer:_consumer
                  inContext:_ctx];
  }
  else
    [self logWithFormat:@"Note: no local domains specified for: '%@'", login];
  
  /* virtual addresses from email1,2,3 */
  error = [self produceVirtualEntriesForAccountEmail123:_account
		onConsumer:_consumer
		inContext:_ctx];
  
  /* virtual addresses from defaults */
  error = [self produceVirtualEntriesForAccountVirtuals:_account
		onConsumer:_consumer
		inContext:_ctx];

  return nil;
}

- (NSDictionary *)fixupAccountDictionary:(NSDictionary *)_account {
  NSMutableDictionary *mdict;
  NSDictionary *attrmap;
  NSEnumerator *keys;
  id cv, v;
  
  mdict = [[_account mutableCopy] autorelease];
  [mdict removeObjectForKey:@"attributeMap"];
  [mdict removeObjectForKey:@"companyValue"];

  /* lastname */

  v = [_account objectForKey:@"lastname"];
  if (![v isNotNull]) {
    v = [_account objectForKey:@"name"];
    if ([v isNotNull]) [mdict setObject:v forKey:@"lastname"];
  }

  /* filter out null values */
  
  keys = [[mdict allKeys] objectEnumerator];
  while ((cv = [keys nextObject])) {
    if ([[mdict objectForKey:cv] isNotNull])
      continue;

    [mdict removeObjectForKey:cv];
  }
  
  /* process extended attributes */
  
  if ((attrmap = [_account valueForKey:@"attributeMap"]) == nil)
    /* no extended attributes */
    return mdict;

  if ((cv = [attrmap valueForKey:@"email1"])) {
    if ((v = [cv valueForKey:@"value"]))
      [mdict setObject:v forKey:@"email1"];
  }
  if ((cv = [attrmap valueForKey:@"email2"])) {
    if ((v = [cv valueForKey:@"value"]))
      [mdict setObject:v forKey:@"email2"];
  }
  if ((cv = [attrmap valueForKey:@"email3"])) {
    if ((v = [cv valueForKey:@"value"]))
      [mdict setObject:v forKey:@"email3"];
  }
  
  return mdict;
}

- (NSException *)produceVirtualEntriesForAccounts:(NSArray *)_accounts
  onConsumer:(id<OGoVirtualEntryConsumer>)_consumer
  inContext:(id)_ctx
{
  // TODO: use aggregate exceptions?
  NSException  *error;
  NSEnumerator *e;
  NSDictionary *account;
  
  [self debugWithFormat:@"producing virtual entries for %d accounts ...",
	  [_accounts count]];
  
  error = nil;
  e = [_accounts objectEnumerator];
  while ((account = [e nextObject]) && (error == nil)) {
    account = [self fixupAccountDictionary:account];
    
    if (![self shouldExportAccount:account inContext:_ctx]) {
      [self debugWithFormat:@"not exporting account: %@", 
              [account valueForKey:@"login"]];
      continue;
    }
    
    error = [self produceVirtualEntriesForAccount:account
		  onConsumer:_consumer
		  inContext:_ctx];
  }
  
  [self debugWithFormat:@"done: %@", error];
  return error;
}

- (NSException *)produceVirtualEntriesOnConsumer:(id<OGoVirtualEntryConsumer>)e
  inContext:(id)_ctx
{
  NSArray *gids, *accounts;
  
  if ([self ignoreExportFlag])
    /* do not export */
    return nil;
  
  if ((gids = [self fetchAccountGlobalIDsInContext:_ctx]) == nil) {
    [self logWithFormat:@"Note: could not fetch account global-ids!"];
    return nil;
  }
  //[self logWithFormat:@"gids: %@", gids];

  // TODO: fetch account attributes
  accounts = [_ctx runCommand:@"person::get-by-globalid",
                   @"gids", gids,
                   @"attributes", coreFetchAttrs,
                   nil];

  return [self produceVirtualEntriesForAccounts:accounts
	       onConsumer:e inContext:_ctx];
}

/* factory */

+ (NSArray *)configFileStorageKeys {
  static NSArray *cf = nil;
  if (cf) return cf;

  cf = [[NSArray alloc] initWithObjects:
                          @"ignoreExportFlag",   @"ignoreVirtualAddresses",
                          @"ignoreLocalDomains", @"localDomainPatterns",
                          @"generateEmail1",
                          @"generateEmail2",@"generateEmail3",
                          @"rawPrefix", @"rawSuffix",
                        nil];
  return cf;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return NO;
}

@end /* OGoAccountsVirtualConfigFile */
