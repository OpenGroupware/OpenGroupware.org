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

#import <Foundation/Foundation.h>

@interface TestConduit : NSObject
{
}

@end

#include "OGoNHSDeviceDataSource.h"
#include <PPSync/PPSyncContext.h>
#include <PPSync/PPTransaction.h>
#include <EOControl/EOControl.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmSyncMachine.h>
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>

@interface SkyPalmSyncMachine(UsedPrivates)
- (NSDictionary *)_comparePalmRecords:(NSArray *)_palmRecs
  withSkyRecords:(NSArray *)_skyRecs;
@end

@implementation TestConduit

- (OGoNHSDeviceDataSource *)_dsForDevice:(NSString *)_dev
  tx:(PPTransaction *)_ec
{
  return [OGoNHSDeviceDataSource dataSourceWithTransaction:_ec
                                 deviceId:_dev
                                 companyId:[NSNumber numberWithInt:22292]
                                 palmDb:@"AddressDB"];
}

- (LSCommandContext *)_skyrix {
  OGoContextManager *app = nil;
  OGoContextSession *sn  = nil;

  app = (id)[OGoContextManager defaultManager];
  sn  = [app login:@"mh" password:@""];
  [sn activate];

  return [sn commandContext];
}

- (EOFetchSpecification *)_skyFetchSpec {
  EOQualifier *qual = nil;

  qual = [EOQualifier qualifierWithQualifierFormat:
                        @"(company_id=22292) AND "
                        @"(device_id=\"Martin Hoerning\")"];
  return
    [EOFetchSpecification fetchSpecificationWithEntityName:@"palm_address"
                          qualifier:qual sortOrderings:nil];
}

- (SkyPalmEntryDataSource *)_skyDs {
  SkyPalmEntryDataSource *ds = nil;
  ds = [SkyPalmEntryDataSource dataSourceWithContext:[self _skyrix]
                               forPalmDb:@"AddressDB"];
  [ds setFetchSpecification:[self _skyFetchSpec]];
  [ds setDefaultDevice:@"Martin Hoerning"];
  return ds;
}

- (void)syncWithTransaction:(PPTransaction *)_ec {
  OGoNHSDeviceDataSource *palmDS    = nil;
  SkyPalmEntryDataSource *skyDS     = nil;
  NSString               *deviceId  = nil;
  PPSyncContext          *ppSync    = nil;

  ppSync   = (PPSyncContext *)[_ec rootObjectStore];
  deviceId = [[ppSync valueForKey:@"userName"] copy];
  
  palmDS = [self _dsForDevice:deviceId tx:_ec];
  skyDS  = [self _skyDs];

  {
    SkyPalmSyncMachine *syncer = nil;
    NSArray *palmRecs = nil;
    NSArray *skyRecs  = nil;
    NSDictionary *compared = nil;

    NSLog(@"Fetching palm recs");
    palmRecs = [palmDS fetchObjects];
    NSLog(@"Fetching sky recs");
    skyRecs  = [skyDS fetchObjects];

    NSLog(@"Preparing syncer");
    syncer = [[SkyPalmSyncMachine alloc] init];

    NSLog(@"Comparing");
    // TODO: fix warning!
    compared = [syncer _comparePalmRecords:palmRecs withSkyRecords:skyRecs];

    NSLog(@"Compared: %@", compared);

    [syncer release];
  }
}
  
@end /* TestConduit */
