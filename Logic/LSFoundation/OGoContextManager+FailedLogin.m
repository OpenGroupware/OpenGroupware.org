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

#include "OGoContextManager.h"
#include "OGoContextSession.h"
#include "LSBundleCmdFactory.h"
#include "common.h"
#include <NGExtensions/NGBundleManager.h>
#include <LSFoundation/LSFoundation.h>
#include <GDLAccess/EOSQLQualifier.h>
#include <NGMail/NGMail.h>

// TODO: needs a lot more cleanup, needs documentation

@implementation OGoContextManager(FailedLogin)

static NSString *FailMailContentTemplate =
  @"This is a message from the SKYRiX Application Server.\n\n"
  @"The account with the login '%@' was locked after "
  @"%d failed logins in the last %d minutes.\n\n"
  @"To unlock this "
  @"account do the following steps: \n\n"
  @"  - login as SKYRiX-administrator\n"
  @"  - open the administration application\n"
  @"  - search and open the account '%@'\n"
  @"  - open the edit panel\n"
  @"  - unlock the account and save\n\n"
  @"You can configure the 'login failed' behavior using the "
  @"following defaults:\n\n"
  @"  HandleFailedAuthorizations (YES/NO)               - "
  @"switch the 'failed login' handler on/off\n"
  @"  FailedLoginCount (number - default: 5)            - "
  @"number of retry counts\n"
  @"  MinutesBetweenFailedLogins (number - default: 15) - "
  @"minutes after a 'failed login' will be ignored\n"
  @"  FailedLoginLockInfoMailAddress (default: root)    - "
  @"this mail will be send to this email-address\n";

static int      HandleFailedAuthorizations = -1;
static int      MinutesBetweenFailed       = -1;
static int      FailedCount          = -1;
static NSString *LockInfoMail        = nil;

- (void)failLogin_initialize {
  NSUserDefaults *ud;
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  ud = [NSUserDefaults standardUserDefaults];

  MinutesBetweenFailed = [ud integerForKey:@"MinutesBetweenFailedLogins"];
  if (MinutesBetweenFailed < 1)
    MinutesBetweenFailed = 15;
  
  HandleFailedAuthorizations =
    [ud boolForKey:@"HandleFailedAuthorizations"] ? 1 : 0;

  FailedCount = [ud integerForKey:@"FailedLoginCount"];
  if (FailedCount < 1)
    FailedCount = 5;

  if (LockInfoMail == nil) {
    LockInfoMail = [[ud objectForKey:@"FailedLoginLockInfoMailAddress"] copy];
    if (LockInfoMail == nil)
      LockInfoMail = @"root";
  }
}

- (BOOL)failLogin_start {
  if (![self->adChannel isOpen]) {
    if (![self->adChannel openChannel]) {
      [self logWithFormat:@"couldn't open adaptor channel"];
      return NO;
    }
  }
  return YES;
}

- (EOSQLQualifier *)failLogin_qualifierForLogin:(NSString *)_login {
  EOSQLQualifier *q;

  q = [EOSQLQualifier alloc];
  q = [q initWithEntity:self->personEntity
	 qualifierFormat:@"(%A = '%@') AND (isAccount=1)",
	 @"login", _login];
  return [q autorelease];
}
- (EOSQLQualifier *)failLogin_qualifierForCompanyID:(NSNumber *)_uid {
  EOSQLQualifier *q;

  q = [EOSQLQualifier alloc];
  q = [q initWithEntity:self->personEntity
	 qualifierFormat:@"%A = %@", @"companyId", _uid];
  return [q autorelease];
}

- (NSDictionary *)failLogin_getAccount:(NSString *)_login uid:(NSNumber *)_uid{
  EOSQLQualifier *qualifier;
  NSException    *error;
  id             row;
  NSArray        *attrs;
  EOAttribute    *companyIdAttr, *isLockedAttr;
  id obj;
  
  companyIdAttr = [self->personEntity attributeNamed:@"companyId"];
  isLockedAttr  = [self->personEntity attributeNamed:@"isLocked"];
  attrs         = [NSArray arrayWithObjects:companyIdAttr, isLockedAttr, nil];
  row           = nil;

  qualifier = _login
    ? [self failLogin_qualifierForLogin:_login]
    : [self failLogin_qualifierForCompanyID:_uid];
  
  error = [self->adChannel selectAttributesX:attrs
	       describedByQualifier:qualifier fetchOrder:nil lock:NO];
  if (error != nil) {
    [self logWithFormat:@"ERROR: could not fetch login information: %@",
	    error];
    [self->adContext rollbackTransaction];
    return nil;
  }
  
  while ((obj = [self->adChannel fetchAttributes:attrs withZone:NULL]))
    row = obj;
  
  return row;
}


- (NSArray *)failLogin_getSessionLogInfoForEntity:(EOEntity *)_entity 
  sqlQualifier:(EOSQLQualifier *)_qual
{
  NSArray        *attrs;
  NSMutableArray *result;
  NSException    *error;
  id obj;

  attrs = [NSArray arrayWithObjects:
                   [_entity attributeNamed:@"sessionLogId"],
                   [_entity attributeNamed:@"logDate"], nil];

  result = [NSMutableArray arrayWithCapacity:5];
  
  error = [self->adChannel selectAttributesX:attrs
	       describedByQualifier:_qual fetchOrder:nil lock:NO];
  if (error != nil) {
    [self->adContext rollbackTransaction];
    [self logWithFormat:@"could not fetch session log infos: %@", error];
    return nil;
  }
  
  while ((obj = [self->adChannel fetchAttributes:attrs withZone:NULL]))
    [result addObject:obj];
  
  return result;
}

- (NSArray *)failLogin_sessionLogInfoForAccountID:(NSNumber *)companyId
  minutes:(int)_minutes
{
  NSCalendarDate *date;
  NSString       *dateStr;
  EOEntity       *sLogEntity;
  id             tmp;
  EOSQLQualifier *qual;
  NSMutableArray *array;
  NSEnumerator   *enumerator;

  date       = [NSCalendarDate dateWithTimeIntervalSinceNow:
                               (NSTimeInterval)(_minutes*60*-1)];
  sLogEntity = [self->model entityNamed:@"SessionLog"];
  dateStr    = [self->adaptor formatValue:date
                    forAttribute:[sLogEntity attributeNamed:@"logDate"]];
  qual       = [[[EOSQLQualifier alloc] initWithEntity:sLogEntity
                                        qualifierFormat:@"(logDate > %@) AND "
                                        @"(%A = '%@') AND (%A = %@)",
                                        dateStr, 
					@"action",    @"Account Changed",
                                        @"accountId", companyId] autorelease];
  tmp = [self failLogin_getSessionLogInfoForEntity:sLogEntity 
	      sqlQualifier:qual];
  
  array = (tmp)
    ? [[tmp mutableCopy] autorelease]
    : [NSMutableArray arrayWithCapacity:10];
  
  qual    = [[[EOSQLQualifier alloc] initWithEntity:sLogEntity
                                     qualifierFormat:@"(%A > %@) AND"
                                     @" (%A = '%@') AND (%A = %@)",
				     @"logDate",   dateStr, 
				     @"action",    @"login",
                                     @"accountId", companyId] autorelease];
  tmp = [self failLogin_getSessionLogInfoForEntity:sLogEntity 
	      sqlQualifier:qual];
  if (tmp)
    [array addObjectsFromArray:tmp];

  enumerator = [array objectEnumerator];

  while ((tmp = [enumerator nextObject])) {
    tmp = [tmp valueForKey:@"logDate"];
    if ([date compare:tmp] == NSOrderedAscending)
      date = tmp;
  }

  dateStr = [self->adaptor formatValue:date
		 forAttribute:[sLogEntity attributeNamed:@"logDate"]];

  qual = [[[EOSQLQualifier alloc] initWithEntity:sLogEntity
				    qualifierFormat:@"(%A > %@) AND "
                                    @"(%A = '%@') AND (%A = %@)",
                                    @"logDate",   dateStr, 
				    @"action",    @"Login Failed",
                                    @"accountId", companyId] autorelease];
  return [self failLogin_getSessionLogInfoForEntity:sLogEntity 
	       sqlQualifier:qual];
}

- (void)failLogin_sendInfoMailInCommandContext:(LSCommandContext *)_ctx
  to:(NSString *)_to from:(NSString *)_from
  account:(NSString *)_account 
  numberOfFails:(int)_failedCnts
  timeRange:(int)_minute
{
  NGMimeMessage    *message;
  NGMutableHashMap *map;
  NSString         *text;
  
  map = [NGMutableHashMap hashMapWithCapacity:10];

  [map setObject:_to forKey:@"to"];

  if ([_from isNotNull]) {
    if ([_from length] > 0)
      [map setObject:_from forKey:@"from"];
  }

  [map setObject:
	 [NSString stringWithFormat:@"OGo: Account '%@' locked", _account]
       forKey:@"subject"];
  
  message = [[[NGMimeMessage alloc] initWithHeader:map] autorelease];
  
  text = [[NSString alloc] initWithFormat:FailMailContentTemplate,
                   _account, _failedCnts, _minute, _account];
  [message setBody:text];
  [text release]; text = nil;

  LSRunCommandV(_ctx, @"email", @"deliver",
                @"copyToSentFolder", [NSNumber numberWithBool:NO],
                @"address", _to,
                @"mimePart", message, nil);
}
                         
- (void)handleFailedAuthorization:(NSString *)_login {
  // TODO: split up this huge method
  
  LSCommandContext *cmdCtx;
  id               companyId;
  BOOL             isLocked;
  NSDictionary     *row;
  BOOL             closeConnection;
  int              cint;
  NSArray          *slInfos;

  [self failLogin_initialize];
  
  if (!HandleFailedAuthorizations)
    return;
  
  if (![self failLogin_start]) {
    [self logWithFormat:@"%s: openchannel failed ", __PRETTY_FUNCTION__];
    return;
  }
  closeConnection = NO;
  
  if (![self->adContext hasOpenTransaction]) {
    [self->adContext beginTransaction];
    closeConnection = YES;
  }
  row = [self failLogin_getAccount:_login uid:nil];
  if (closeConnection)
    [self->adContext commitTransaction];

  if (row == nil) {
    [self logWithFormat:@"Did not find account for login: '%@'", _login];
    [self->adContext commitTransaction];
    [self->adChannel closeChannel];
    return;
  }

  if ((isLocked  = [[row objectForKey:@"isLocked"] boolValue]))
    // already locked
    return;
  
  companyId = [row objectForKey:@"companyId"];
  cint = [companyId intValue];
      
  if (!(cint > 0 && cint != 10000)) {
    [self logWithFormat:@"Did not find account for login: '%@'", _login];
    return;
  }

  cmdCtx = [[LSCommandContext alloc] initWithManager:self];
  [cmdCtx begin];

  LSRunCommandV(cmdCtx, @"sessionlog", @"add",
		@"accountId", companyId,
		@"action",    @"Login Failed",
		nil);
	
  if (![self failLogin_start]) {
    [self logWithFormat:
	    @"%s: open channel failed %@", __PRETTY_FUNCTION__,
	    self->adChannel];
    [cmdCtx rollback];
    [cmdCtx release]; cmdCtx = nil;
    return;
  }

  if (![self->adContext hasOpenTransaction]) {
    [self->adContext beginTransaction];
    closeConnection = YES;
  }
  slInfos = [self failLogin_sessionLogInfoForAccountID:companyId
		  minutes:MinutesBetweenFailed];
  
  if ([slInfos count] >= FailedCount) {
    id      root, person;

    root = [self failLogin_getAccount:nil 
		 uid:[NSNumber numberWithInt:10000]];
	    
    [self logWithFormat:
	    @"Max retry count was reached, lock account '%@', "
	    @"send a message to %@.", _login, LockInfoMail];
    
    [cmdCtx takeValue:root forKey:LSAccountKey];

    person = LSRunCommandV(cmdCtx, @"person", @"get",
			   @"checkAccess", [NSNumber numberWithBool:NO],
			   @"companyId", companyId, nil);

    if ([person isKindOfClass:[NSArray class]]) {
      person = [person lastObject];
    }

    if (person) {
      [person takeValue:[NSNumber numberWithBool:YES]
	      forKey:@"isLocked"];
            
      LSRunCommandV(cmdCtx, @"person", @"set",
		    @"object", person,
		    @"checkAccess", [NSNumber numberWithBool:NO], nil);
    }
    else {
      NSLog(@"%s: couldn't fetch person for id %@", __PRETTY_FUNCTION__,
	    companyId);
    }
    [self failLogin_sendInfoMailInCommandContext:cmdCtx
	  to:LockInfoMail
	  from:[root valueForKey:@"email1"]
	  account:_login 
	  numberOfFails:FailedCount
	  timeRange:MinutesBetweenFailed];
	    
    if (closeConnection)
      [self->adContext commitTransaction];
  }
  
  [cmdCtx commit];
  [cmdCtx release]; cmdCtx = nil;
}

@end /* OGoContextManager(FailedLogin) */
