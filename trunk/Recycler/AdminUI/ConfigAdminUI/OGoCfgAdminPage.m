/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include <OGoFoundation/OGoContentPage.h>

@class NSCalendarDate;
@class EODataSource;
@class OGoConfigFile;

@interface OGoCfgAdminPage : OGoContentPage
{
  EODataSource   *ds;
  OGoConfigFile  *configEntry;
  NSCalendarDate *lastExport;
}

@end

#include "WOApplication+CfgDB.h"
#include "common.h"
#include <OGoConfigGen/OGoConfigDatabase.h>
#include <OGoConfigGen/OGoConfigFile.h>
#include <OGoConfigGen/OGoConfigExporter.h>
#include <OGoConfigGen/OGoConfigGenTransaction.h>

@implementation OGoCfgAdminPage

static NSString *OGoConfigExportDirectory = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  OGoConfigExportDirectory =
    [[ud stringForKey:@"OGoConfigExportDirectory"] copy];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    [self registerAsPersistentInstance];
  }
  return self;
}

- (void)dealloc {
  [self->lastExport  release];
  [self->configEntry release];
  [self->ds          release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  
  if (self->ds == nil) {
    self->ds = [[[[self application] configDatabase] configDataSource] retain];
    if (self->ds == nil)
      [self setErrorString:@"Found no configuration database!"];
  }
}

- (void)sleep {
  [self->configEntry release]; self->configEntry = nil;
  [super sleep];
}

/* accessors */

- (EODataSource *)configDataSource {
  return self->ds;
}

- (void)setConfigEntry:(OGoConfigFile *)_entry {
  ASSIGN(self->configEntry, _entry);
}
- (OGoConfigFile *)configEntry {
  return self->configEntry;
}

- (NSString *)configEntryTypeLabel {
  id            labels;
  OGoConfigFile *entry;

  if ((entry = [self configEntry]) == nil)
    return nil;
  
  labels = [self labels];
  return [labels valueForKey:[entry configType]];
}

- (BOOL)hasLastExport {
  return self->lastExport ? YES : NO;
}
- (NSCalendarDate *)lastExportDate {
  return self->lastExport;
}
- (NSString *)exportTarget {
  return OGoConfigExportDirectory;
}

/* errors */

- (void)setErrorException:(NSException *)_error {
  // TODO: improve, OGoComponent should have NSException based errors!
  [self setErrorString:[_error description]];
}

/* actions */

- (id)configEntryClicked {
  return [[self navigation] activateObject:[self configEntry]
			    withVerb:@"view"];
}

- (id)exportAll {
  OGoConfigExporter       *exporter;
  OGoConfigDatabase       *db;
  OGoConfigGenTransaction *tx;
  NSException             *error;
  
  [self logWithFormat:@"Note: exporting all configurations ..."];

  if ((db = [[self application] configDatabase]) == nil) {
    [self setErrorString:@"Missing configuration database!"];
    return nil;
  }
  if ((exporter = [[OGoConfigExporter alloc] initWithConfigDatabase:db])==nil){
    [self setErrorString:@"Could not create configuration exporter!"];
    return nil;
  }
  exporter = [exporter autorelease];

  /* create transaction */
  
  if ((tx = [[[OGoConfigGenTransaction alloc] init] autorelease]) == nil) {
    [self setErrorString:@"Could not create config export transaction!"];
    return nil;
  }

  /* export */
  
  error = [exporter exportDatabaseInContext:[[self session] commandContext]
                    transaction:tx];
  if (error) {
    [self logWithFormat:@"ERROR: configuration export failed: %@", error];
    [self setErrorException:error];
    return nil;
  }
  
  /* write transaction */

  error = [tx writeTransactionToDirectoryPath:OGoConfigExportDirectory
              fileManager:[NSFileManager defaultManager]];
  if (error) {
    [self logWithFormat:@"ERROR: config transaction write failed: %@", error];
    [self setErrorException:error];
    return nil;
  }
  
  /* finish */
  
  ASSIGN(self->lastExport, [NSCalendarDate date]);
  
  return nil;
}

@end /* OGoCfgAdminPage */
