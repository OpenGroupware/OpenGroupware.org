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
// $Id: OGoMailFilterManager.m 1 2004-08-20 11:17:52Z znek $

#include "OGoMailFilterManager.h"
#include "common.h"

// TODO: needs a lot of cleanup
// TODO: the actual forking code should be moved to the XML-RPC daemon
//       and get triggered using an XML-RPC action

@implementation OGoMailFilterManager

static NSString *LSAttachmentPath         = nil;
static NSString *SkyInstallSievePrefixVar = nil;
static NSString *MailServerHost           = nil;
static NSString *CyrusSieveTempPath       = nil;
static BOOL     ImapDebugEnabled      = NO;
static BOOL     UseSkyrixLoginForImap = NO;
static BOOL     SieveLogPassword      = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;

  LSAttachmentPath      = [[ud stringForKey:@"LSAttachmentPath"] copy];
  CyrusSieveTempPath    = [[ud stringForKey:@"cyrus_sieve_temp_path"] copy];
  ImapDebugEnabled      = [ud boolForKey:@"ImapDebugEnabled"];
  UseSkyrixLoginForImap = [ud boolForKey:@"UseSkyrixLoginForImap"];
  SieveLogPassword      = [ud boolForKey:@"SieveLogPassword"];
  MailServerHost        = [[ud stringForKey:@"imap_host"] copy];
  
  SkyInstallSievePrefixVar = 
    [[ud stringForKey:@"sieve_install_prefix_var"] copy];
  if (SkyInstallSievePrefixVar == nil)
    NSLog(@"ERROR: default 'sieve_install_prefix_var' is not set!");
}

+ (id)sharedMailFilterManager {
  static OGoMailFilterManager *sharedManager = nil; // THREAD
  
  if (sharedManager == nil)
    sharedManager = [[self alloc] init];
  return sharedManager;
}

/* accessors */

- (NSFileManager *)fileManager {
  return [NSFileManager defaultManager];
}

/* operations */

- (NSArray *)allFiltersForUser:(id)_user {
  NSFileManager *manager  = [self fileManager];
  NSString      *path     = nil;

  path = [self pathToFilterForUser:_user];
  
  return ([manager fileExistsAtPath:path])
    ? [[[NSArray alloc] initWithContentsOfFile:path] autorelease]
    : [NSArray array];
}

- (NSMutableArray *)filterForUser:(id)_user {
  NSEnumerator        *enumerator = nil;
  NSMutableDictionary *filter     = nil;
  id                  result      = nil;

  result     = [NSMutableArray arrayWithCapacity:16];
  enumerator = [[self allFiltersForUser:_user]objectEnumerator];
  while ((filter = [[enumerator nextObject] mutableCopy] )) {
    NSNumber *pos;
    
    if (![filter objectForKey:@"kind"]) {
      pos = [filter objectForKey:@"filterPos"];    
      
      [filter setObject:[NSNumber numberWithInt:[pos intValue]]
              forKey:@"filterPos"];
      [result addObject:filter];
    }
    
    // TODO: is this a retain bug?
    [filter release]; filter = nil;
  }
  return result;
}

- (NSMutableArray *)vacationForUser:(id)_user {
  NSEnumerator        *enumerator = nil;
  NSMutableDictionary *filter     = nil;
  id                  result      = nil;

  result     = [NSMutableArray arrayWithCapacity:5];
  enumerator = [[self allFiltersForUser:_user]objectEnumerator];

  while ((filter = [enumerator nextObject])) {
    if (![filter objectForKey:@"kind"])
      continue;

    [result addObject:filter];
  }
  return result;
}

- (BOOL)writeAllFilters:(NSArray *)_filter forUser:(id)_user {
  if (!_filter)
    _filter = [NSArray array];
  
  return [_filter writeToFile:
                  [self pathToFilterForUser:_user]
                  atomically:YES];
}

- (BOOL)writeFilter:(NSArray *)_filter forUser:(id)_user {
  NSMutableArray *vac;

  vac = [self vacationForUser:_user];
  [vac addObjectsFromArray:_filter];
  
  return [self writeAllFilters:vac forUser:_user];
}

- (BOOL)writeVacation:(NSArray *)_filter forUser:(id)_user {
  NSMutableArray *filter;

  filter = [self filterForUser:_user];
  [filter addObjectsFromArray:_filter];
  
  return [self writeAllFilters:filter forUser:_user];
}


- (NSString *)pathToFilterForUserWithPrimaryKey:(NSNumber *)_pkey {
  NSString *fileName;
  
  fileName = [_pkey stringValue];
  fileName = [fileName stringByAppendingPathExtension:@"imap-filter"];
  return [LSAttachmentPath stringByAppendingPathComponent:fileName];
}
- (NSString *)pathToFilterForUser:(id)_user {
  NSNumber *pkey;
  
  pkey = [_user valueForKey:@"companyId"];
  return [self pathToFilterForUserWithPrimaryKey:pkey];
}

- (NSString *)pathToFilterInstallScript {
  NSDictionary *env;
  NSString     *sievePath;
  
  // TODO: add support for flattened
  // TODO: use Foundation file-search function to locate binary
  env       = [[NSProcessInfo processInfo] environment];
  sievePath =
    [NSString stringWithFormat:@"%@/Tools/%@/%@/%@/sky_install_sieve",
                [env objectForKey:SkyInstallSievePrefixVar],
                [env objectForKey:@"GNUSTEP_HOST_CPU"],
                [env objectForKey:@"GNUSTEP_HOST_OS"],
                [env objectForKey:@"LIBRARY_COMBO"]];
  
  if (![[self fileManager] isExecutableFileAtPath:sievePath]) {
    [self logWithFormat:@"ERROR: did not find executable sieve binary: '%@'",
	    sievePath];
    return nil;
  }
  
  return sievePath;
}

- (NSArray *)getTaskArgumentsAndDebugArguments:(NSArray **)_debugArgs 
  withAccountPrimaryKey:(NSNumber *)_pkey andSievePort:(NSString *)_port
  imapLogin:(NSString *)imapLogin imapHost:(NSString *)imapHost
  imapPassword:(NSString *)imapPwd
{
  NSArray *arguments, *debugArgs;
  NSString *filterPath, *tmppath;
  BOOL imapDeb;
  
  if (_debugArgs) *_debugArgs = nil;
  if (![_pkey isNotNull]) {
    [self logWithFormat:@"WARNING: got a null pkey!"];
    return nil;
  }
  
  imapDeb    = ImapDebugEnabled;
  debugArgs  = nil;
  filterPath = [self pathToFilterForUserWithPrimaryKey:_pkey];
  tmppath    = [[_pkey stringValue] stringByAppendingPathExtension:@"filter"];
  tmppath    = [CyrusSieveTempPath stringByAppendingPathComponent:tmppath];
  
  if (ImapDebugEnabled) {
      debugArgs = [NSArray arrayWithObjects:
			     @"-l",  imapLogin,
                             @"-p",  @"PASSWORD",
                             @"-s",  imapHost,
                             @"-po", _port,
                             @"-id", filterPath,
                             @"-t",  tmppath,
                             @"-ImapDebugEnabled", @"YES",
                             SieveLogPassword ? @"-SieveLogPassword" : nil,
                             SieveLogPassword ? @"YES" : nil,
                           nil];
  }
  
  arguments = [NSArray arrayWithObjects:
                         @"-l",  imapLogin,
                         @"-p",  imapPwd,
                         @"-s",  imapHost,
		         @"-po", _port,
		         @"-id", filterPath,
		         @"-t",  tmppath,
                         imapDeb ? @"-ImapDebugEnabled" : nil,
                         imapDeb ? @"YES" : nil,
                         SieveLogPassword ? @"-SieveLogPassword":nil,
                         SieveLogPassword ? @"YES":nil,
		       nil];
  
  if (_debugArgs && ImapDebugEnabled) *_debugArgs = debugArgs;
  return arguments;
}

- (void)exportFilterWithSession:(id)_session password:(NSString *)_pwd
  page:(id)_page
{
  id             sn;
  NSUserDefaults *defs;
  NSArray        *arguments, *debugArgs;
  NSString       *imapPwd   = nil;
  NSString       *imapHost  = nil;
  NSString       *sievePath = nil;
  NSString       *imapLogin = nil;
  
  sn   = _session;
  defs = [sn userDefaults];
  
  if (UseSkyrixLoginForImap) {
    LSCommandContext *cmdctx;
    
    cmdctx    = [_session commandContext];
    imapLogin = [[cmdctx valueForKey:LSAccountKey] valueForKey:@"login"];
    imapPwd   = [cmdctx valueForKey:@"LSUser_P_W_D_Key"];
    imapHost  = MailServerHost;
  }
  else {
    imapLogin = [defs stringForKey:@"imap_login"];
    imapPwd   = _pwd;
    imapHost  = [defs stringForKey:@"imap_host"];
  }

  if (imapPwd == nil)
    imapPwd = @"";
  
  if ([imapLogin length] == 0) {
    [self logWithFormat:@"%s: missing login", __PRETTY_FUNCTION__];
    return;
  }
  if ([imapHost length] == 0) {
    [self logWithFormat:@"%s: missing host", __PRETTY_FUNCTION__];
    return;
  }
  
  /* find sieve binary */
  
  sievePath = [self pathToFilterInstallScript];
  if ([sievePath length] < 2) {
    // TODO: fix labels?
    [_page setErrorString:@"Did not find filter install program !"];
    return;
  }
  
  arguments = [self getTaskArgumentsAndDebugArguments:&debugArgs
		    withAccountPrimaryKey:
		      [[sn activeAccount] valueForKey:@"companyId"]
		    andSievePort:[defs stringForKey:@"cyrus_sieve_port"]
		    imapLogin:imapLogin imapHost:imapHost 
		    imapPassword:imapPwd];
  
  {
    NSTask *task;
    int    ts;
    
    [self debugWithFormat:@"launchpath %@", sievePath];
    [self debugWithFormat:@"arguments %@",  debugArgs];
    
    task = [[NSTask alloc] init];
    
    [task setLaunchPath:sievePath];
    [task setArguments:arguments];
    [task launch];
    [task waitUntilExit];

    ts = [task terminationStatus];
    [self debugWithFormat:@"sky_install_sieve exit with %d \n", ts];
    
    switch (ts) {
      case 3:
        [_page setErrorString:@"login failed"];
        break;
      case 4:
        [_page setErrorString:@"missing sieve service or host"];
        break;
    }
    [task release]; task = nil;
  }
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return ImapDebugEnabled;
}

@end /* OGoMailFilterManager */
