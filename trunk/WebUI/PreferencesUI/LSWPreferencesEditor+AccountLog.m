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

#include "LSWPreferencesEditor.h"
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoDocuments/LSCommandContext+Doc.h>
#include <OGoAccounts/SkyAccountDocument.h>

@interface EODataSource(SkyAccountLog)
- (void)logChangesOnAccount:(SkyAccountDocument *)_account;
@end /* EODataSource(SkyAccountLog) */

@implementation LSWPreferencesEditor(AccountLog)

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
  if ([[[self session] userDefaults] boolForKey:@"SkyLogAccounts"]) {
    
    id           keys[1], gid, account, ctx;
    EODataSource *ds;

    ds = nil;
    
    if (![self _loadSkyAccountLogBundle])
      return;

    keys[0] = [_eo valueForKey:@"companyId"];
    gid     = [EOKeyGlobalID globalIDWithEntityName:@"Account"
                             keys:keys keyCount:1 zone:NULL];
    ctx     = [(id)[self session] commandContext];
    account = [[ctx documentManager] documentForGlobalID:gid];

    if (account == nil) {
      NSLog(@"WARNING[%s]: could not fetch document for log for id %@",
            __PRETTY_FUNCTION__, keys[0]);
      return;
    }
    {
      Class c;
      
      if ((c = NSClassFromString(@"SkyAccountLogDataSource")) == Nil) {
        NSLog(@"WARNING[%s]: failed creating SkyAccountLogDataSource-class",
              __PRETTY_FUNCTION__);
        return;
      }
      // TODO: fix prototype
      ds = [(SkyAccessManager *)[c alloc] initWithContext:ctx];
    }
    [ds logChangesOnAccount:account];
    [ds release]; ds = nil;
  }
}

@end /* LSWPreferencesEditor(AccountLog) */
