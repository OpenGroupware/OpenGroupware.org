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

#include "SkyLogDataSource.h"
#include "SkyLogDocument.h"
#import "common.h"

@interface SkyLogDataSource(PrivateMethods)
- (NSArray *)_morphDictsToDocuments:(NSArray *)_dicts;
- (Class)documentClass;
@end /* SkyLogDataSource(PrivateMethods) */

@interface SkyLogDocument(DataSourceMethods)
- (void)_setCreationDate:(NSCalendarDate *)_date;
- (void)_setGlobalID:(EOGlobalID *)_globalID;
- (id)initAsNewWithDataSource:(SkyLogDataSource *)_dataSource;
- (void)setObjectId:(NSNumber *)_objectId;
@end /* SkyLogDocument(AfterInsertMethods) */

@implementation SkyLogDataSource

- (id)init {
  if ((self = [super init])) {
    self->context  = nil;
    self->globalID = nil;
    self->fspec    = nil;
  }
  return self;
}

- (id)initWithContext:(id)_context globalID:(EOGlobalID *)_gid {
  NSAssert(_gid, @"Need globalID for logDataSource!!");
  if ((self = [self init])) {
    ASSIGN(self->context,_context);
    ASSIGN(self->globalID,_gid);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->context);
  RELEASE(self->globalID);
  RELEASE(self->fspec);
  [super dealloc];
}
#endif

- (EOGlobalID *)globalID {
  return self->globalID;
}
- (id)context {
  return self->context;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  ASSIGN(self->fspec,_fspec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fspec;
}

- (NSArray *)fetchObjects {
  NSArray *result = nil;

  result = [self->context runCommand:@"object::get-logs",
                @"object", self->globalID, nil];

  result = [self _morphDictsToDocuments:result];

  {
    EOQualifier *qual = [self->fspec qualifier];

    if (qual != nil)
      result = [result filteredArrayUsingQualifier:qual];
  }

  {
    NSArray *so = [self->fspec sortOrderings];

    if (so != nil)
      result = [result sortedArrayUsingKeyOrderArray:so];
  }

  return result;
}

- (void)insertObject:(SkyLogDocument *)_obj {
  id result = [self->context runCommand:@"object::add-log",
                   @"objectId", [_obj objectId],
                   @"logText",  [_obj logText],
                   @"action",   [_obj action],
                   nil];

  if (result) {
    [_obj _setCreationDate:[result valueForKey:@"creationDate"]];
    [_obj _setGlobalID:[result valueForKey:@"globalID"]];
  }
  else {
    NSLog(@"ERROR[%s]: failed to insert log document", __PRETTY_FUNCTION__);
    return;
  }
  [self postDataSourceChangedNotification];
}

- (id)createObject {
  SkyLogDocument *logDoc =
    [[[self documentClass] alloc] initAsNewWithDataSource:self];
  [logDoc setObjectId:[(EOKeyGlobalID *)self->globalID keyValues][0]];
  return AUTORELEASE(logDoc);
}

@end /* SkyLogDataSource */

@implementation SkyLogDataSource(PrivateMethods)

- (Class)documentClass {
  return [SkyLogDocument class];
}

- (NSArray *)_morphDictsToDocuments:(NSArray *)_dicts {
  int i, cnt = [_dicts count];
  id  *docs = malloc(sizeof(id) * cnt);

  NSArray *result;

  for (i = 0; i < cnt; i++) {
    docs[i] = [[[self documentClass]
                      alloc] initWithValues:[_dicts objectAtIndex:i]
                             dataSource:self];
    AUTORELEASE(docs[i]);
  }

  result = [NSArray arrayWithObjects:docs count:cnt];

  free(docs); docs = NULL;

  return result;
}

@end /* SkyLogDataSource(PrivateMethods) */
