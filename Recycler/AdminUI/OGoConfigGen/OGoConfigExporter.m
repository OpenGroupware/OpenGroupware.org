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

#include "OGoConfigExporter.h"
#include "OGoConfigEntryExporter.h"
#include "OGoConfigDatabase.h"
#include "common.h"

@interface NSObject(ConfigExporting)
- (id)exporterInContext:(id)_ctx;
@end

@implementation OGoConfigExporter

- (id)initWithConfigDatabase:(OGoConfigDatabase *)_db {
  if ((self = [super init])) {
    self->database = [_db retain];
  }
  return self;
}
- (id)init {
  return [self initWithConfigDatabase:nil];
}

- (void)dealloc {
  [self->database release];
  [super dealloc];
}

/* accessors */

- (OGoConfigDatabase *)configDatabase {
  return self->database;
}

/* exporting */

- (id)exporterForEntry:(id)_entry inContext:(id)_ctx {
  if (_entry == nil) return nil;
  
  if ([_entry respondsToSelector:@selector(exporterInContext:)])
    return [_entry exporterInContext:_ctx];
  
  return nil;
}

- (NSException *)exportConfigEntry:(id)_entry inContext:(id)_ctx 
  transaction:(OGoConfigGenTransaction *)_tx
{
  id exporter;
  
  if (_entry == nil) return nil;
  
  if ((exporter = [self exporterForEntry:_entry inContext:_ctx]) == nil) {
    // TODO: return exception?
    [self logWithFormat:@"ERROR: found no exporter for entry: %@", _entry];
    return nil;
  }
  
  return [exporter exportConfigEntry:_entry inContext:_ctx transaction:_tx];
}
- (NSException *)exportConfigEntryWithName:(NSString *)_entryName 
  inContext:(id)_ctx 
{
  OGoConfigGenTransaction *tx = nil;
  id entry = nil;
  
  if ([_entryName length] == 0) 
    return nil;
  
  if ((entry = [[self configDatabase] fetchEntryWithName:_entryName]) == nil) {
    // TODO: return exception?
    [self logWithFormat:@"WARNING: did not find config entry: '%@'",
	    _entryName];
    return nil;
  }
  
  if ((tx = [_ctx valueForKey:@"cfgtx"]) == nil) {
    // TODO: generate exception
    [self logWithFormat:@"ERROR: missing config gen transaction!"];
    return nil;
  }
  
  return [self exportConfigEntry:entry inContext:_ctx transaction:tx];
}

- (NSException *)exportDatabaseInContext:(id)_ctx
  transaction:(OGoConfigGenTransaction *)_tx
{
  // TODO: aggregate exceptions?
  NSArray      *names;
  NSEnumerator *en;
  NSString     *entryName;
  
  names = [[self configDatabase] fetchEntryNames];
  en = [names objectEnumerator];
  while ((entryName = [en nextObject])) {
    NSException *e;
    id entry;
    
    if ((entry = [[self configDatabase] fetchEntryWithName:entryName])==nil) {
      // TODO: return exception?
      [self logWithFormat:@"WARNING: did not find config entry: '%@'",
	      entryName];
      return nil;
    }
    
    if ((e = [self exportConfigEntry:entry inContext:_ctx transaction:_tx])) {
      [self logWithFormat:@"Export of entry failed: %@", entry];
      return e;
    }
  }
  return nil;
}
- (NSException *)exportDatabaseInContext:(id)_ctx {
  OGoConfigGenTransaction *tx;
  
  if ((tx = [_ctx valueForKey:@"cfgtx"]) == nil) {
    // TODO: generate exception
    [self logWithFormat:@"ERROR: missing config gen transaction!"];
    return nil;
  }
  
  return [self exportDatabaseInContext:_ctx transaction:tx];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->database) [ms appendFormat:@" db=0x%08X", self->database];
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoConfigExporter */
