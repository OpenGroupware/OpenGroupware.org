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

#include "OGoNHSConduit.h"
#include <PPSync/PPSyncContext.h>
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>
#include <EOControl/EOControl.h>
#include <PPSync/PPTransaction.h>
#include <PPSync/PPPostSync.h>
#include <GDLAccess/GDLAccess.h>

#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmSyncMachine.h>
#include <OGoPalm/SkyPalmPostSync.h>
#include "OGoNHSDeviceDataSource.h"

@interface OGoNHSPostSync : PPPostSync
{
  SkyPalmPostSync *postSync;
  id commandContext;
}

- (id)initWithPostSync:(SkyPalmPostSync *)_postSync
               context:(id)_commandContext;

@end

@implementation OGoNHSConduit

- (void)dealloc {
  [self->companyId release];
  [self->deviceId  release];
  [self->cmdCtx    release];
  [super dealloc];
}

/* accessors */

- (void)setCommandContext:(LSCommandContext *)_ctx {
  ASSIGN(self->cmdCtx,_ctx);
}
- (LSCommandContext *)commandContext {
  return self->cmdCtx;
}

- (NSNumber *)companyId {
  return self->companyId;
}

- (NSString *)deviceId {
  return self->deviceId;
}

/* sync helper */

// logging
// log on server side
- (void)logWithString:(NSString *)_log {
  NSLog(@"[OGoNHSConduit %@] %@", self, _log);
}
- (void)logWithFormat:(NSString *)_fmt, ... {
  va_list  va;
  NSString *s;
  
  va_start(va, _fmt);
  s = [NSString stringWithFormat:_fmt arguments:va];
  va_end(va);

  [self logWithString:s];
}
// log on palm
- (void)syncLogWithString:(NSString *)_log {
  [self->ppSync syncLogWithString:[NSString stringWithFormat:@"%@\n", _log]];
}
- (void)syncLogWithFormat:(NSString *)_fmt, ... {
  va_list  va;
  NSString *s;
  
  va_start(va, _fmt);
  s = [NSString stringWithFormat:_fmt arguments:va];
  va_end(va);

  [self syncLogWithString:s];
}
// log on both
- (void)logBothWithString:(NSString *)_log {
  [self logWithString:_log];
  [self syncLogWithString:_log];
}
- (void)logBothWithFormat:(NSString *)_fmt, ... {
  va_list  va;
  NSString *s;
  
  va_start(va, _fmt);
  s = [NSString stringWithFormat:_fmt arguments:va];
  va_end(va);

  [self logBothWithString:s];
}

// login 
- (EOFetchSpecification *)_fetchSpecForLoginInfo {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"MemoDB"
                               qualifier:nil
                               sortOrderings:nil];
}

- (BOOL)_loginWithContext:(PPTransaction *)_ctx {
  NSEnumerator *memos   = nil;
  id           memo     = nil;

  NSString     *login   = nil;
  NSString     *pwd     = nil;

  memos =
    [[_ctx objectsWithFetchSpecification:[self _fetchSpecForLoginInfo]]
           objectEnumerator];

  while ((memo = [memos nextObject])) {
    NSString *text;

    text = [memo valueForKey:@"text"];
    if ([text hasPrefix:@"OGo"]) {
      NSArray *lines;

      if (![[memo valueForKey:@"isPrivate"] boolValue]) {
        [self logBothWithFormat:@"Palm-Memo 'OGo' is not set to private!"];
      }

      lines = [text componentsSeparatedByString:@"\n"];
      
      if ([lines count] < 2) {
        [self logWithFormat:@"No login found in 'OGo' memo"];
        continue;
      }

      login = [lines objectAtIndex:1];

      if ([lines count] > 2)
        pwd = [lines objectAtIndex:2];

      break;
    }
  }

  if (login == nil) {
    [self logBothWithFormat:@"No valid login-configuration found in MemoDB"];
    return NO;
  }
  if (pwd == nil) {
    [self logBothWithFormat:@"Leaving password empty"];
    pwd = @"";
  }

  {
    // creating OGo instance
    OGoContextManager *app;
    OGoContextSession *sn  = nil;
    
    if ((app = (id)[OGoContextManager defaultManager]) == nil) {
      [self logBothWithFormat:
              @"Could not start OGoContextManager. "
              @"Probably not configured yet"];
      return NO;
    }
    
    if (![app isLoginAuthorized:login password:pwd]) {
      [self logBothWithFormat:@"Login '%@' not authorized", login];
      return NO;
    }

    if ((sn = [app login:login password:pwd]) == nil) {
      [self logBothWithFormat:@"couldn't login '%@' into SKYRIX", login];
      return NO;
    }

    [sn activate];
    [self setCommandContext:[sn commandContext]];
    RELEASE(self->companyId);
    self->companyId = [[[self commandContext] valueForKey:LSAccountKey]
                              valueForKey:@"companyId"];
  }

  return YES;
}

// load the datasource
- (EOFetchSpecification *)_skyFetchSpecForEntity:(NSString *)_entity {
  EOQualifier *qual = nil;

  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"company_id=%@ AND "
                      @"device_id=%@",
                      self->companyId, self->deviceId];
  return
    [EOFetchSpecification fetchSpecificationWithEntityName:_entity
                          qualifier:qual sortOrderings:nil];
}

- (SkyPalmEntryDataSource *)skyrixDSForPalmDB:(NSString *)_palmDb {
  SkyPalmEntryDataSource *ds = nil;

  ds = [SkyPalmEntryDataSource dataSourceWithContext:
                               [self commandContext]
                               forPalmDb:_palmDb];

  [ds setFetchSpecification:[self _skyFetchSpecForEntity:[ds entityName]]];
  [ds setDefaultDevice:self->deviceId];

  return ds;
}

- (OGoNHSDeviceDataSource *)palmDSForTransaction:(PPTransaction *)_ec
  palmDb:(NSString *)_palmDb
{
  OGoNHSDeviceDataSource *ds = nil;

  ds = [OGoNHSDeviceDataSource dataSourceWithTransaction:_ec
                               deviceId:self->deviceId
                               companyId:self->companyId
                               palmDb:_palmDb];
  [ds setCommandContext:[self commandContext]];
  return ds;
}

- (void)_loadOptionsForSyncMachine:(SkyPalmSyncMachine *)_syncer {
  NSUserDefaults *ud = [[self commandContext] valueForKey:LSUserDefaultsKey];

  [_syncer setSyncWithSkyrixRecordBefore:
           [ud boolForKey:@"OGoPalmSync_preSyncWithSkyrix"]];
  self->registerPostSyncs =
    [ud boolForKey:@"OGoPalmSync_postSyncWithSkyrix"];
  if (self->registerPostSyncs) {
    [self logWithFormat:@"postsync enabled"];
  }
  else {
    [self logWithFormat:@"postsync disabled"];
  }
  //[_syncer setSyncWithSkyrixRecordAfter:
  //         [ud boolForKey:@"OGoPalmSync_postSyncWithSkyrix"]];
}

- (PPPostSync *)postSyncForSkyrixDataSource:(SkyPalmEntryDataSource *)_ds
		    skyIdsOfDeletedPalmRecs:(NSArray *)_deletedIds {
  SkyPalmPostSync *palmPostSync;
  OGoNHSPostSync  *ppPostSync;

  palmPostSync = [SkyPalmPostSync postSyncForPalmDataSource:_ds
                                  deviceId:self->deviceId];
  [palmPostSync setSkyIdsOfDeleted:_deletedIds];
  ppPostSync = [[OGoNHSPostSync alloc] initWithPostSync:palmPostSync
                                       context:[self commandContext]];
  return [ppPostSync autorelease];
}

// conduit API
- (void)syncWithTransaction:(PPTransaction *)_ec {
  SkyPalmSyncMachine     *syncer   = nil;
  OGoNHSDeviceDataSource *palmDS   = nil;
  SkyPalmEntryDataSource *skyDS    = nil;
  NSArray                *conduits = nil;
  NSEnumerator           *e        = nil;
  NSString               *conduit  = nil;

  self->ppSync   = (PPSyncContext *)[_ec rootObjectStore];
  self->deviceId = [[self->ppSync valueForKey:@"userName"] copy];
  

  if (![self _loginWithContext:_ec]) {
    return;
  }

  if (![self->deviceId length]) {
    RELEASE(self->deviceId);
    self->deviceId = [[[self commandContext] valueForKey:LSAccountKey]
                             valueForKey:@"login"];
    RETAIN(self->deviceId);
    [self logWithFormat:@"device id unset, setting to %@", self->deviceId];
    [self->ppSync takeValue:self->deviceId forKey:@"userName"];
  }

  {
    NSUserDefaults *ud  = nil;
    NSString       *abr = nil;
    NSTimeZone     *tz  = nil;

    ud  = [[self commandContext] valueForKey:LSUserDefaultsKey];
    abr = [ud valueForKey:@"pda_timezone"];
    if (abr == nil) abr = [ud valueForKey:@"timezone"];
    if (abr == nil) abr = [ud valueForKey:@"TimeZoneName"];
    if (abr == nil) abr = @"MET";
    
    tz = [NSTimeZone timeZoneWithAbbreviation:abr];
    [self->ppSync setPilotTimeZone:tz];

    conduits = [ud valueForKey:@"OGoPalm_sync_conduits"];
    if (conduits == nil)
      conduits = [NSArray arrayWithObjects:
                          @"AddressDB", @"DatebookDB",
                          @"MemoDB", @"ToDoDB", nil];
  }
  [[self commandContext] begin];

  syncer = [[SkyPalmSyncMachine alloc] init];
  [syncer setCategorySyncMode:SYNC_CATEGORY_FROM_PALM];
  [syncer setLogLabel:[self description]];

  [self _loadOptionsForSyncMachine:syncer];

  e = [conduits objectEnumerator];

  while ((conduit = [e nextObject])) {
    palmDS = [self palmDSForTransaction:_ec palmDb:conduit];
    [palmDS prepareSync];
    [syncer setPalmDataSource:palmDS];
    skyDS = [self skyrixDSForPalmDB:conduit];
    [syncer setSkyrixDataSource:skyDS];
    // sync
    if ([palmDS syncCategories])
      [syncer syncCategoriesForDeviceId:self->deviceId];
    [syncer syncRecordsWithDeviceId:self->deviceId];
    [syncer assignRecords:[palmDS newSkyPalmMapping]];

    if (self->registerPostSyncs) {
      NSArray *deletedIds;
      deletedIds = [syncer skyIdsOfDeletedPalmRecords];
      [_ec registerPostSync:
	     [self postSyncForSkyrixDataSource:skyDS
		   skyIdsOfDeletedPalmRecs:deletedIds]];
    }

    [self syncLogWithString:
          [NSString stringWithFormat:@"%@ done.", conduit]];
  }

  [syncer release];

  [[self commandContext] commit];

  [self->ppSync updateSuccessfulSyncDate];
  [self logBothWithString:@"Sync finished."];
}

- (NSString *)description { // appears in sync log
  return @"OpenGroupware.org PalmApp";
}

@end /* OGoNHSConduit */

@implementation OGoNHSPostSync

- (id)initWithPostSync:(SkyPalmPostSync *)_postSync
               context:(id)_commandContext
{
  if ((self = [super init])) {
    self->postSync       = [_postSync retain];
    self->commandContext = [_commandContext retain];
  }
  return self;
}

- (void)dealloc {
  [self->postSync       release];
  [self->commandContext release];
  [super dealloc];
}

- (BOOL)run {
  BOOL result;
  result = [self->postSync postSync];
  if (result) {
    [self->commandContext commit];
  }
  else {
    //NSLog(@"%s postsync: %@ failed",
    //      __PRETTY_FUNCTION__, self->postSync);
  }
  return result;
}

@end /* OGoNHSPostSync */
