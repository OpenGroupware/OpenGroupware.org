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

#include <OGoConfigGen/OGoConfigDatabase.h>
#include <OGoConfigGen/OGoConfigExporter.h>
#include <OGoConfigGen/OGoConfigGenTransaction.h>
#include <OGoConfigGen/OGoConfigGenTarget.h>
#include "OGoLogicTool.h"
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@interface OGoCfgGenTool : OGoLogicTool
{
  OGoConfigDatabase *db;
  OGoConfigExporter *exporter;
}

- (int)run:(NSArray *)_args;

@end

@implementation OGoCfgGenTool

- (int)prepareForRun {
  self->db = [[OGoConfigDatabase alloc] initWithSystemPath:@"../configdb/"];
  [self logWithFormat:@"Database: %@", self->db];

  self->exporter = [[OGoConfigExporter alloc] initWithConfigDatabase:self->db];
  [self logWithFormat:@"Exporter: %@", exporter];
  
  return 0;
}

- (int)run:(NSArray *)_args {
  NSException *error;
  OGoConfigGenTransaction *tx;
  NSString *entryName;
  id       entry;
  
  if ([self prepareForRun] != 0)
    return 1;
  if (![self doLogin]) {
    [self logWithFormat:@"could not login into OGo."];
    return 2;
  }
  
#if 0
  [self logWithFormat:@"Entries: %@", 
	  [[self->db fetchEntryNames] componentsJoinedByString:@", "]];
#endif
  
  tx = [[[OGoConfigGenTransaction alloc] init] autorelease];
  [self->cmdctx takeValue:tx forKey:@"cfgtx"];
  
  entryName = ([_args count] > 1) ? [_args objectAtIndex:1] : nil;
  
  if (entryName == nil) {
    error = [exporter exportDatabaseInContext:self->cmdctx
                      transaction:tx];
  }
  else {
    entry = [self->db fetchEntryWithName:entryName];
    [self logWithFormat:@"process entry: %@", entry];
    
    error = [exporter exportConfigEntry:entry inContext:self->cmdctx
                      transaction:tx];
  }
  
  if (error) {
    [self logWithFormat:@"  export error: %@", error];
  }
  else {
    unsigned i, count;
    NSArray  *targets;
    
    [self logWithFormat:@"exported: %@", tx];
    
    targets = [[tx allTargets] allValues];
    for (i = 0, count = [targets count]; i < count; i++) {
      OGoConfigGenTarget *target = [targets objectAtIndex:i];
      
      [self logWithFormat:@"TARGET: %@\n---snip---", [target name]];
      printf("%s---snap---\n", [[target content] cString]);
    }
  }
  
  return 0;
}

@end /* OGoCfgGenTool */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  OGoCfgGenTool *tool;
  int rc;

  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY  
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  tool = [[[OGoCfgGenTool alloc] init] autorelease];
  rc = [tool run:[[NSProcessInfo processInfo] argumentsWithoutDefaults]];

  [pool release];
  exit(rc); return rc;
}
