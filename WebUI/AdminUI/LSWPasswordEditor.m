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

#include <OGoFoundation/LSWEditorPage.h>

@class NSString;

@interface LSWPasswordEditor : LSWEditorPage
{
@private
  NSString *oldPassword;
  NSString *newPassword;
  NSString *repeatPassword;
}

@end

@interface LSWPasswordEditor(AccountLog)
- (void)_logChangesOnAccount:(id)_eo;
@end /* LSWPasswordEditor(AccountLog) */

#include <OGoBase/LSCommandContext+Doc.h>
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoAccounts/SkyAccountDocument.h>

@interface EODataSource(SkyAccountLog)
- (void)logChangesOnAccount:(SkyAccountDocument *)_account;
@end /* EODataSource(SkyAccountLog) */

@implementation LSWPasswordEditor

static int minPwdLength = 0;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (minPwdLength == 0) {
    minPwdLength = [[ud objectForKey:@"SkyMinimumPasswordLength"] intValue];
    if (minPwdLength == 0)
      minPwdLength = 6;
  }
}

- (void)dealloc {
  [self->oldPassword    release];
  [self->newPassword    release];
  [self->repeatPassword release];
  [super dealloc];
}

- (BOOL)useLDAP {
  // TODO: ??
  return NO;
  return [LSCommandContext useLDAPAuthorization];
}

- (void)_resetInputFields {
  [self->oldPassword    release]; self->oldPassword    = nil;
  [self->newPassword    release]; self->newPassword    = nil;
  [self->repeatPassword release]; self->repeatPassword = nil;
}

- (BOOL)_checkOldPassword {
  NSString *oldUserPassword = nil;
  NSString *cryptedPasswd;

  if ([[self session] activeAccountIsRoot])
    return YES;

  if ([LSCommandContext useLDAPAuthorization])
    return YES;

  oldUserPassword = [[self object] valueForKey:@"password"];
  
  if (oldUserPassword == nil)
    return (self->oldPassword == nil) ? YES : NO;

  if (self->oldPassword == nil)
    return NO;

  cryptedPasswd = [self runCommand:@"system::crypt",
                              @"password", self->oldPassword,
                              @"salt"    , oldUserPassword,
                              nil];
  return [oldUserPassword isEqualToString:cryptedPasswd];
}

- (BOOL)_checkInputPasswords {
  if (self->repeatPassword == nil)
    return NO;

  return ([self->newPassword isEqualToString:self->repeatPassword]);
}

- (BOOL)_checkPasswordLength {
  if ([[self session] activeAccountIsRoot]) 
    return YES;
  
  return ([self->newPassword length] >= minPwdLength) ? YES : NO;
}

- (void)_setAccountPassword {
  NSString *cryptedPasswd;

  cryptedPasswd = [self runCommand:@"system::crypt",
                          @"password", self->newPassword, nil];
  
  [[self snapshot] takeValue:cryptedPasswd forKey:@"password"];
}

/* accessors */

- (void)setOldPassword:(NSString *)_oldPw {
  if (_oldPw && [_oldPw length] > 0) {
    ASSIGN(self->oldPassword, _oldPw);
  }
  else {
    RELEASE(self->oldPassword); self->oldPassword = nil;
  }
}
- (NSString *)oldPassword {
  return self->oldPassword;
}

- (void)setNewPassword:(NSString *)_newPw {
  ASSIGN(self->newPassword, _newPw);
}
- (NSString *)newPassword {
  return self->newPassword;
}

- (void)setRepeatPassword:(NSString *)_repPw {
  ASSIGN(self->repeatPassword, _repPw);
}
- (NSString *)repeatPassword {
  return self->repeatPassword;
}

- (NSDictionary *)account {
  return [self snapshot];
}

- (NSString *)updateNotificationName {
  return LSWUpdatedPasswordNotificationName;
}

/* constraints */

- (BOOL)checkConstraints {
  id l;

  l = [self labels];

  if ([self _checkOldPassword]) {
    if ([self _checkPasswordLength]) {
      if ([self _checkInputPasswords]) {
        //[self _setAccountPassword];
        //[self _resetInputFields];
        return NO;
      }
      else {
        [self setErrorString:[l valueForKey:@"Repeated input failed"]];
        [self _resetInputFields];
        return YES;
      }
    }
    else {
      NSString *key;
      NSString *msg;
      
      key = @"Password too short - must be at least 6 characters";
      msg = [l valueForKey:key];
      
      if (minPwdLength != 6) { /* hack, the label should be split up ! */
        NSString *s;
	
        s = [[NSString alloc] initWithFormat:@"%i", minPwdLength];
        msg = [msg stringByReplacingString:@"6" withString:s];
        [s release]; s = nil;
      }
      [self setErrorString:msg];
      
      [self _resetInputFields];
      return YES;
    }
  }
  [self setErrorString:[l valueForKey:@"Password check failed"]];
  [self _resetInputFields];
  return YES;
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

/* actions */

- (id)_changePasswordFrom:(NSString *)_old to:(NSString *)_new {
  return [self runCommand:@"account::change-password",
                   @"object",      [self object],
                   @"newPassword", _new,
                   @"oldPassword", _old,
	       nil];
}

- (NSException *)_handlePasswordException:(NSException *)_exception {
  if (![[_exception name] isEqualToString:@"LSDBObjectCommandException"])
    return _exception;
  
  // TODO: checking for a specific reason is less than ideal ...
  if (![[_exception reason] isEqualToString:@"Wrong ldap password"])
    return _exception;
  
  return nil;
}

- (id)updateObject {
  id result;
  
  NS_DURING /* if LDAP failed */
    result = [self _changePasswordFrom:self->oldPassword to:self->newPassword];
  NS_HANDLER {
    [[self _handlePasswordException:localException] raise];
    result = nil;
  }
  NS_ENDHANDLER;
  
  if (result == nil) {
    NSString *s;
    
    s = [[self labels] valueForKey:@"Password check failed"];
    [self setErrorString:s];
  }
  [self _resetInputFields];
  [self _logChangesOnAccount:result];
  return result;
}

/* AccountLog */

- (BOOL)_loadSkyAccountLogBundle {
  NGBundleManager *bm;
  NSBundle        *b;

  bm = [NGBundleManager defaultBundleManager];
  b  = [bm bundleForClassNamed:@"SkyAccountLogProject"];
  
  if (b == nil) {
    NSLog(@"WARNING[%s]: did not find SkyAccountLog-Bundle",
          __PRETTY_FUNCTION__);
    return NO;
  }

  if (![b load]) {
    NSLog(@"WARNING[%s]: unable to load bundle %@",
          __PRETTY_FUNCTION__, [b bundleName]);
    return NO;
  }
  return YES;
}

- (void)_logChangesOnAccount:(id)_eo {
  LSCommandContext *ctx;
  NSNumber     *keys[1];
  EOGlobalID   *gid;
  id           account;
  EODataSource *ds = nil;
  Class c;
  
  if (![[[self session] userDefaults] boolForKey:@"SkyLogAccounts"])
    return;

  if (![self _loadSkyAccountLogBundle])
    return;

  keys[0] = [_eo valueForKey:@"companyId"];
  gid     = [EOKeyGlobalID globalIDWithEntityName:@"Account"
			   keys:keys keyCount:1 zone:NULL];

  ctx = [(id)[self session] commandContext];

  if ((account = [[ctx documentManager] documentForGlobalID:gid]) == nil) {
    [self logWithFormat:
	    @"WARNING[%s]: could not fetch document for log for id %@",
            __PRETTY_FUNCTION__, keys[0]];
    return;
  }

  if ((c = NSClassFromString(@"SkyAccountLogDataSource")) == Nil) {
    [self logWithFormat:
	    @"WARNING[%s]: failed creating SkyAccountLogDataSource-class",
	    __PRETTY_FUNCTION__];
    return;
  }
  
  // TODO: wrong type
  ds = [(SkyAccessManager *)[c alloc] initWithContext:ctx];
  [ds logChangesOnAccount:account];
  [ds release]; ds = nil;
}

@end /* LSWPasswordEditor */
