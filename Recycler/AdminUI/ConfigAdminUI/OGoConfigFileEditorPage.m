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

#include "OGoConfigFileEditorPage.h"
#include "WOApplication+CfgDB.h"
#include "common.h"
#include <OGoConfigGen/OGoConfigDatabase.h>
#include <OGoConfigGen/OGoConfigFile.h>
#include <OGoConfigGen/OGoConfigGenTransaction.h>
#include <OGoConfigGen/OGoConfigGenTarget.h>
#include <OGoConfigGen/OGoConfigExporter.h>

@implementation OGoConfigFileEditorPage

- (void)dealloc {
  [self->database release];
  [self->object   release];
  [super dealloc];
}

/* activation */

- (id)activateGlobalID:(EOGlobalID *)_gid {
  if ((self->database = [[[self application] configDatabase] retain]) == nil) {
    [self logWithFormat:@"ERROR: cannot activate gid without cfg-database."];
    return nil;
  }
  
  self->object = [[self->database fetchEntryForGlobalID:_gid] retain];
  if (self->object == nil) {
    [self setErrorString:@"did not find object for global-id"];
    return nil;
  }
  
  return self;
}

- (id)activateObject:(id)_object verb:(NSString *)_verb type:(NGMimeType *)_mt{
  if (_object == nil) 
    return nil;
  if (![_object isKindOfClass:[EOGlobalID class]])
    return [self activateObject:[(id)_object globalID] verb:_verb type:_mt];
  
  return [self activateGlobalID:_object];
}

/* accessors */

- (id)object {
  return self->object;
}

/* generator */

- (NSDictionary *)previewTargets {
  LSCommandContext        *cmdctx;
  OGoConfigGenTransaction *tx;
  OGoConfigExporter       *exporter;
  NSException *error;
  
  /* context */
  cmdctx = [[self session] commandContext];
  tx = [[[OGoConfigGenTransaction alloc] init] autorelease];
#if 0
  [cmdctx takeValue:tx forKey:@"cfgtx"];
#endif
  
  /* exporter */
  exporter = [[OGoConfigExporter alloc] initWithConfigDatabase:self->database];

  error = [exporter exportConfigEntry:[self object] inContext:cmdctx
                    transaction:tx];
  
  if (error) {
    [self setErrorString:[error description]];
    return nil;
  }

  [exporter release];
  [cmdctx takeValue:[NSNull null] forKey:@"cfgtx"];
  
  return [tx allTargets];
}

- (OGoConfigGenTarget *)previewTarget {
  NSDictionary *targets;
  
  targets = [self previewTargets];
  return [[targets allValues] lastObject];
}
- (NSString *)previewContent {
  // TODO: should use targets
  return [[self previewTarget] content];
}

/* editor page */

- (BOOL)isEditorPage {
  return NO; // YES; (admin will know what he does - hopefully ;-)
}

@end /* OGoConfigFileEditorPage */
