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

#include "SkyImapContextHandler.h"
#include "SkyImapMailDataSource.h"
#include "common.h"
#include <NGStreams/NGSocketExceptions.h>

@implementation SkyImapContextHandler

static NSString *ImapContextKey = @"ImapContextKey";
static NSString *ImapDSKey      = @"ImapDSKey";

+ (id)sharedImapContextHandler {
  static SkyImapContextHandler *ch = nil; // THREAD
  if (ch == nil) ch = [[SkyImapContextHandler alloc] init];
  return ch;
}
+ (id)imapContextHandlerForSession:(id)_sn {
  return [self sharedImapContextHandler];
}

/* methods */

- (SkyImapMailDataSource *)mailDataSourceWithSession:(id)_session
  folder:(NGImap4Folder *)_folder
{
  SkyImapMailDataSource *ds;

  ds = [[_session commandContext] valueForKey:ImapDSKey];

  if (![ds isNotNull]) {
    ds = [[[SkyImapMailDataSource alloc] init] autorelease];
    [[_session commandContext] takeValue:ds forKey:ImapDSKey];
  }
  if (![[ds folder] isEqual:_folder])
    [ds setFolder:_folder];
  return ds;
}


- (NGImap4Context *)sessionImapContext:(id)_session {
  id ctx;

  ctx = [[_session commandContext] valueForKey:ImapContextKey];

  return ([ctx isNotNull])?ctx:nil;
}

- (NGImap4Context *)imapContextWithSession:(id)_session
  errorString:(NSString **)error_
{
  return [self imapContextWithSession:_session
	       password:nil login:NULL host:NULL
	       errorString:error_];
                                
}

- (void)_deleteDefault:(NSString *)_name session:(id)_sn {
  NSUserDefaults *defs = [_sn userDefaults];
  
  [_sn runCommand:@"userdefaults::delete", 
         @"key", _name, @"defaults", defs, nil];
}
- (void)_writeDefault:(NSString *)_name value:(id)_val session:(id)_sn {
  NSUserDefaults *defs = [_sn userDefaults];
  
  [_sn runCommand:@"userdefaults::write",
         @"key", _name, @"value", _val, @"defaults", defs, nil];
}

- (void)prepareForLogin:(NSString *)_login passwd:(NSString *)_passwd
  host:(NSString *)_host savePwd:(BOOL)_savePwd session:(id)_session
{
  NSUserDefaults *defs;
  
  defs = [_session userDefaults];
  
  if (!_savePwd) {
    [self _deleteDefault:@"imap_passwd" session:_session];
  }
  else {
    if (_passwd == nil) _passwd = @"";
    [self _writeDefault:@"imap_passwd" value:_passwd session:_session];
  }
  
  if (_login != nil)
    [self _writeDefault:@"imap_login" value:_login session:_session];
  if (_host != nil)
    [self _writeDefault:@"imap_host" value:_host session:_session];
}

- (NSString *)descriptionForConnectException:(NSException *)_ex {
  [self logWithFormat:@"%s: catched exception %@: %@", __PRETTY_FUNCTION__, 
	  [_ex name], [_ex reason]];
  
  if ([_ex isKindOfClass:[NGCouldNotResolveHostNameException class]])
    return @"Could not resolve host name";
  
  if ([_ex isKindOfClass:[NGIOException class]])
    return @"Could not connect to host";
  
  if ([_ex isKindOfClass:[NGImap4Exception class]])
    return [_ex reason];
  
  return @"Unexpected Error";
}
- (NGImap4Context *)imapContextWithSession:(id)_session
  password:(NSString *)_pwd login:(NSString **)login_
  host:(NSString **)host_ errorString:(NSString **)error_
{
  NGImap4Context   *imapCtx;
  NSString         *login = nil, *host = nil;
  NSUserDefaults   *defs, *ud;
  LSCommandContext *cmdCtx;
  BOOL             result;
  NSDictionary     *condict;
  id tmp;

  if (login_ == NULL) login_ = &login;
  if (host_  == NULL) host_  = &host;
  
  imapCtx = [[_session commandContext] valueForKey:ImapContextKey];
  if ([imapCtx isNotNull])
    return imapCtx;
  
  *error_ = nil;
  defs    = [_session userDefaults];
  ud      = [NSUserDefaults standardUserDefaults];
  cmdCtx  = [_session commandContext];
  
  if ([ud boolForKey:@"UseSkyrixLoginForImap"]) {
    *login_ = [[cmdCtx valueForKey:LSAccountKey] valueForKey:@"login"];
    _pwd    = [cmdCtx valueForKey:@"LSUser_P_W_D_Key"];
    *host_  = [ud stringForKey:@"imap_host"]; 
  }
  else {
    *login_ = [defs stringForKey:@"imap_login"];
    *host_  = [defs stringForKey:@"imap_host"];
  }
  if (([*login_ length] == 0) || ([*host_ length] == 0) || (_pwd == nil))
      return nil;
  
  condict = [NSDictionary dictionaryWithObjectsAndKeys:
			    *login_, @"login",
			    _pwd  , @"passwd",
			    *host_,  @"host", nil];
  imapCtx = [[NGImap4Context alloc] initWithConnectionDictionary:condict];
  [imapCtx enterSyncMode];

  result = YES;
  NS_DURING {
    if (![imapCtx openConnection]) {
      NSException *localException;
	
      if ((localException = [imapCtx lastException]))
	*error_ = [self descriptionForConnectException:localException];
	
      imapCtx = nil;
    }
  }
  NS_HANDLER {
    /* should never happen ... */
    *error_ = [[[localException description] copy] autorelease];
    imapCtx = nil;
  }
  NS_ENDHANDLER;
  
  if (imapCtx == nil)
    return nil;
  
  ud = [_session userDefaults];
  
  if ((tmp = [ud objectForKey:@"mail_show_unsubscribed_folder"]))
    [imapCtx setShowOnlySubscribedInSubFolders:[tmp boolValue]];
  if ((tmp = [ud objectForKey:@"mail_show_unsubscribed_folder_in_root"]))
    [imapCtx setShowOnlySubscribedInRoot:[tmp boolValue]];
  
  [[_session commandContext] takeValue:imapCtx forKey:ImapContextKey];
  return imapCtx;
}

- (void)resetImapContextWithSession:(id)_session {
  NGImap4Context *ctx;

  if ((ctx = [self sessionImapContext:_session]) == nil)
    return;
  
  [ctx removeAllFromRefresh];
  [[_session commandContext] takeValue:[NSNull null] forKey:ImapContextKey];
}

/* old class methods, deprecated! */

+ (SkyImapMailDataSource *)mailDataSourceWithSession:(id)_session
  folder:(NGImap4Folder *)_folder
{
  return [[self imapContextHandlerForSession:_session]
	        mailDataSourceWithSession:_session folder:_folder];
}
+ (NGImap4Context *)sessionImapContext:(id)_sn {
  return [[self imapContextHandlerForSession:_sn] sessionImapContext:_sn];
}

+ (NGImap4Context *)imapContextWithSession:(id)_sn errorString:(NSString **)e_{
  return [[self imapContextHandlerForSession:_sn] 
	        imapContextWithSession:_sn errorString:e_];
}

+ (void)prepareForLogin:(NSString *)_login passwd:(NSString *)_passwd
  host:(NSString *)_host savePwd:(BOOL)_savePwd session:(id)_session
{
  [[self imapContextHandlerForSession:_session]
         prepareForLogin:_login passwd:_passwd
         host:_host savePwd:_savePwd session:_session];
}

+ (NGImap4Context *)imapContextWithSession:(id)_session
  password:(NSString *)_pwd login:(NSString **)login_
  host:(NSString **)host_ errorString:(NSString **)error_
{
  return [[self imapContextHandlerForSession:_session]
	   imapContextWithSession:_session
	   password:_pwd login:login_
	   host:host_ errorString:error_];
}

+ (void)resetImapContextWithSession:(id)_session {
  [[self imapContextHandlerForSession:_session]
         resetImapContextWithSession:_session];
}

@end /* SkyImapContextHandler */
