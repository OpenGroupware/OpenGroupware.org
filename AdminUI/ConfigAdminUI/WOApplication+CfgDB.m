/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "WOApplication+CfgDB.h"
#include <OGoConfigGen/OGoConfigDatabase.h>
#include "common.h"

@implementation WOApplication(CfgDB)

static OGoConfigDatabase *db = nil; // THREAD

- (OGoConfigDatabase *)configDatabase {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString *cfgDBPath;

  if (db) return db;
  
  cfgDBPath = [ud stringForKey:@"OGoConfigDatabasePath"];
  if ([cfgDBPath length] == 0) {
    [self logWithFormat:@"Note: no configuration database is configured!"];
  }
  else if (db == nil) {
    db = [[OGoConfigDatabase alloc] initWithSystemPath:cfgDBPath];
    if (db == nil) {
      [self logWithFormat:
              @"WARNING: could not initialize configuration database: '%@'",
              cfgDBPath];
    }
  }
  return db;
}

@end /* WOApplication(CfgDB) */
