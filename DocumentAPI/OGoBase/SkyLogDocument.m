/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyLogDocument.h"
#include "SkyLogDataSource.h"
#import "common.h"

@interface SkyLogDocument(PrivateMethods)
- (id)_fetchAccount;
@end /* SkyLogDocument(PrivateMethods) */

@implementation SkyLogDocument

- (id)init {
  if ((self = [super init])) {
    self->status.isNew = YES;
  }
  return self;
}

- (id)initWithValues:(id)_values
          dataSource:(SkyLogDataSource *)_dataSource
{
  if ((self = [self init])) {
    ASSIGN(self->dataSource,_dataSource);

    self->globalID = ([_values respondsToSelector:@selector(globalID)])
      ? [_values globalID]
      : [_values valueForKey:@"globalID"];
    if (self->globalID == nil) {
      id key = [_values valueForKey:@"logId"];
      self->globalID = [[EOKeyGlobalID globalIDWithEntityName:@"log"
				       keys:&key keyCount:1 zone:NULL] retain];
    }

    self->objectId     = [[_values valueForKey:@"objectId"]     retain];
    self->creationDate = [[_values valueForKey:@"creationDate"] retain];
    self->logText      = [[_values valueForKey:@"logText"]      retain];
    self->accountId    = [[_values valueForKey:@"accountId"]    retain];
    self->action       = [[_values valueForKey:@"action"]       retain];
    
    self->status.isNew = NO;
  }
  return self;
}

- (id)initAsNewWithDataSource:(SkyLogDataSource *)_dataSource {
  if ((self = [self init])) {
    ASSIGN(self->dataSource,_dataSource);
    self->accountId =
      [[[[self->dataSource context] valueForKey:LSAccountKey]
	 valueForKey:@"companyId"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->objectId     release];
  [self->creationDate release];
  [self->logText      release];
  [self->accountId    release];
  [self->action       release];
  [self->dataSource   release];
  [self->globalID     release];
  [self->account      release];
  [super dealloc];
}

/* accessors */

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (void)_setGlobalID:(EOGlobalID *)_globalID {
  if (self->status.isNew) {
    ASSIGN(self->globalID,_globalID);
    self->status.isNew = NO;
  }
}

- (NSNumber *)objectId {
  return self->objectId;
}
- (void)setObjectId:(NSNumber *)_objectId {
  if (self->status.isNew)
    ASSIGN(self->objectId,_objectId);
}

- (NSCalendarDate *)creationDate {
  return self->creationDate;
}
- (void)_setCreationDate:(NSCalendarDate *)_date {
  if (self->status.isNew)
    ASSIGN(self->creationDate,_date);
}

- (NSString *)logText {
  return self->logText;
}
- (void)setLogText:(NSString *)_text {
  if (self->status.isNew)
    ASSIGN(self->logText,_text);
}

- (NSString *)action {
  return self->action;
}
- (void)setAction:(NSString *)_action {
  if (self->status.isNew)
    ASSIGN(self->action,_action);
}

- (NSNumber *)accountId {
  return self->accountId;
}

- (id)account {
  if (self->account == nil) {
    self->account = [self _fetchAccount];
    RETAIN(self->account);
  }
  return self->account;
}
- (id)actor {
  return [self account];
}

- (BOOL)isSaved {
  return (self->status.isNew) ? NO : YES;
}

- (BOOL)save {
  if (self->status.isNew) {
    [self->dataSource insertObject:self];
    return YES;
  }
  else 
    NSLog(@"ERROR[%s]: can only insert logs!!", __PRETTY_FUNCTION__);
  return NO;
}

@end /* SkyLogDocument */

#include <OGoDocuments/SkyDocumentManager.h>
#include <OGoBase/LSCommandContext+Doc.h>

@implementation SkyLogDocument(PrivateMethods)

- (id)_fetchAccount {
  id values[1];
  id gid = nil;

  values[0] = self->accountId;
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                       keys:values keyCount:1 zone:NULL];
  
  return [[[self->dataSource context] documentManager]
                             documentForGlobalID:gid];
}

@end /* SkyLogDocument(PrivateMethods) */
