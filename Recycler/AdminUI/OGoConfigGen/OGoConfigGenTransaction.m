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

#include "OGoConfigGenTransaction.h"
#include "OGoConfigGenTarget.h"
#include "OGoConfigDatabase.h"
#include "OGoConfigExporter.h"
#include "common.h"

@implementation OGoConfigGenTransaction

- (id)initWithConfigDatabase:(OGoConfigDatabase *)_db 
  andCoordinator:(OGoConfigExporter *)_exporter
{
  if ((self = [super init])) {
    self->database    = [_db       retain];
    self->coordinator = [_exporter retain];
  }
  return self;
}

- (void)dealloc {
  [[self->targets allValues] 
                  makeObjectsPerformSelector:@selector(_resetTransaction:) 
                  withObject:self];
  
  [self->targets     release];
  [self->database    release];
  [self->coordinator release];
  [super dealloc];
}

/* accessors */

- (OGoConfigDatabase *)configDatabase {
  return self->database;
}
- (OGoConfigExporter *)coordinator {
  return self->coordinator;
}

/* targets */

- (NSDictionary *)allTargets {
  return [[self->targets copy] autorelease];
}

- (OGoConfigGenTarget *)createNewTarget:(NSString *)_name {
  return [OGoConfigGenTarget targetWithName:_name inTransaction:self];
}

- (OGoConfigGenTarget *)targetWithName:(NSString *)_name {
  OGoConfigGenTarget *t;
  
  if ([_name length] == 0)
    return nil;
  
  if ((t = [self->targets objectForKey:_name]))
    return t;

  if ((t = [self createNewTarget:_name]) == nil) {
    [self logWithFormat:@"WARNING: could not create target named '%@'", _name];
    return nil;
  }
  
  if (self->targets == nil)
    self->targets = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  [self->targets setObject:t forKey:_name];
  return t;
}

/* commit transaction */

- (NSException *)writeTarget:(OGoConfigGenTarget *)_target
  toDirectoryPath:(NSString *)_path
  fileManager:(NSFileManager *)_fm
{
  NSString *s;
  NSString *tp;
  BOOL ok;
  
  tp = [_path stringByAppendingPathComponent:[_target name]];
  s  = [_target content];
  
  [self logWithFormat:@"Note: writing config %@ (%d bytes) ..",
          tp, [s length]];
  
  ok = [s writeToFile:tp atomically:YES];
  if (!ok) {
    [self logWithFormat:@"ERROR: could not write to file: %@", tp];
    return [NSException exceptionWithName:@"OGoConfigExportError"
                        reason:@"a configuration file could not be written!"
                        userInfo:nil];
  }
  return nil;
}

- (NSException *)writeTransactionToDirectoryPath:(NSString *)_path
  fileManager:(NSFileManager *)_fm
{
  OGoConfigGenTarget *target;
  NSEnumerator *e;
  NSException  *error;
  BOOL isDir;
  
  [self logWithFormat:@"shall commit tx to: %@", _path];

  /* check preconditions */
  
  if (_path == nil || ![_fm fileExistsAtPath:_path isDirectory:&isDir]) {
    return [NSException exceptionWithName:@"OGoConfigExportError"
                        reason:@"config export path does not exist!"
                        userInfo:nil];
  }
  if (!isDir) {
    return [NSException exceptionWithName:@"OGoConfigExportError"
                        reason:@"config export path is not a directory!"
                        userInfo:nil];
  }
  
  /* write configuration files */
  
  error = nil;
  e = [targets objectEnumerator];
  while ((target = [e nextObject]) && error == nil) {
    error = [self writeTarget:target
                  toDirectoryPath:_path
                  fileManager:_fm];
  }
  
  return error;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];

  if (self->database)
    [ms appendFormat:@" db=0x%p", self->database];
  if (self->coordinator)
    [ms appendFormat:@" master=0x%p", self->coordinator];

  if (self->targets)
    [ms appendFormat:@" #targets=%d", [self->targets count]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoConfigGenTransaction */
