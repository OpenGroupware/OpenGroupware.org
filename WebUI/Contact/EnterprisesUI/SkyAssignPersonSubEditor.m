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

#import "common.h"
#include <OGoFoundation/SkyEditorComponent.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyPersonDocument.h>

@interface SkyAssignPersonSubEditor : SkyEditorComponent
{
  NSMutableArray      *resultList;
  NSMutableArray      *persons;
  NSMutableArray      *addedPersons;
  NSMutableArray      *removedPersons;
  NSString            *searchText;
  id                  item;     // non-retained
  BOOL                showExtended;
  SkyPersonDocument   *newPerson;
  SkyPersonDataSource *personDataSource;
}
@end /* SkyAssignPersonSubEditor */

@interface SkyPersonFormatter : NSFormatter
@end

@implementation SkyPersonFormatter
- (NSString *)stringForObjectValue:(id)_account {
  NSString *result = nil;

  if ((result = [_account valueForKey:@"name"]) == nil) {
    if ((result = [_account valueForKey:@"login"]) == nil) {
      if ((result = [_account valueForKey:@"nickname"]) == nil) {
        result = [NSString stringWithFormat:@"pkey<%@>",
                           [_account valueForKey:@"companyId"]];
      }
    }
  }
  else {
    NSString *fn = [_account valueForKey:@"firstname"];

    if ([fn isNotNull])
      result = [NSString stringWithFormat:@"%@, %@", result, fn];
  }
  return result;
}
@end

static int comparePersons(id e1, id e2, void* context) {
  static SkyPersonFormatter *formatter = nil;

  if (formatter == nil)
    formatter = [[SkyPersonFormatter alloc] init];

  return [[formatter stringForObjectValue:e1]
          caseInsensitiveCompare:[formatter stringForObjectValue:e2]];
}

@implementation SkyAssignPersonSubEditor

- (id)init {
  if ((self = [super init])) {
    LSCommandContext *c;

    self->resultList     = [[NSMutableArray alloc] initWithCapacity:4];
    self->removedPersons = [[NSMutableArray alloc] initWithCapacity:2];
    self->addedPersons   = [[NSMutableArray alloc] initWithCapacity:2];
    self->persons        = [[NSMutableArray alloc] initWithCapacity:4];
    
    c = [(OGoSession *)[self session] commandContext];
    self->personDataSource  = 
      [(SkyPersonDataSource *)[SkyPersonDataSource alloc] initWithContext:c];
  }
  return self;
}

- (void)dealloc {
  [self->resultList release];
  [self->persons release];
  [self->addedPersons release];
  [self->removedPersons release];
  [self->searchText release];
  [self->personDataSource release];
  [self->newPerson release];
  [super dealloc];
}

/* methods */

- (SkyEnterpriseDocument *)enterprise {
  return (SkyEnterpriseDocument *)[self document];
}

- (void)prepareEditor {
  NSArray *tmp;
  
  tmp = [[[self enterprise] personDataSource] fetchObjects];
  [self->persons release];
  self->persons = [[NSMutableArray alloc] initWithArray:tmp];
}

- (void)_updateNewPerson {
  if ([self->newPerson isValid]) {
    [self->persons addObject:self->newPerson];
    [self->newPerson release]; self->newPerson = nil;
  }
}

- (void)syncAwake {
  [super syncAwake];
  [self _updateNewPerson];
  [self->removedPersons removeAllObjects];
  [self->addedPersons   removeAllObjects];
}

- (void)syncSleep {
  self->item      = nil;
  [self->removedPersons removeAllObjects];
  [self->addedPersons   removeAllObjects];
  [super syncSleep];
}

- (void)setItem:(SkyPersonDocument *)_item {
  self->item = _item;
}
- (SkyPersonDocument *)item {
  return self->item;
}

- (NSString *)fullNameString {
  static SkyPersonFormatter *formatter = nil;

  if (formatter == nil)
    formatter = [[SkyPersonFormatter alloc] init];

  return [formatter stringForObjectValue:[self item]];
}

- (NSString *)enterprisesNameString {
  if (self->showExtended) {
    NSArray *ents;

    ents = [[[self item] enterpriseDataSource] fetchObjects];
    return [[ents valueForKey:@"name"] description];
  }

  return @"";
}

- (void)_updateAddedPersonList {
  int i, count;
  
  // persons selected in resultList
  for (i = 0, count = [self->addedPersons count]; i < count; i++) {
    id  partner;
    id  pkey;
    int j, count2;

    partner = [self->addedPersons objectAtIndex:i];
    pkey    = [partner valueForKey:@"companyId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of partner %@", self, partner);
      continue;
    }
    for (j = 0, count2 = [self->persons count]; j < count2; j++) {
      id opkey;

      opkey = [[self->persons objectAtIndex:j] valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // already in array
        pkey = nil;
        break;
      }
    }

    if (pkey) {
      [self->persons addObject:partner];
      [self->resultList removeObject:partner];
    }
  }
}

- (void)_updateRemovedPersonList {
  int i, count;
    
  // persons not selected in persons list
  for (i = 0, count = [self->removedPersons count]; i < count; i++) {
    id  partner;
    id  pkey;
    int j, count2, removeIdx = -1;

    partner = [self->removedPersons objectAtIndex:i];
    pkey    = [partner valueForKey:@"companyId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of partner %@", self, partner);
      continue;
    }

    for (j = 0, count2 = [self->persons count]; j < count2; j++) {
      id opkey;

      opkey = [[self->persons objectAtIndex:j] valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // found in array
        removeIdx = j;
        break;
      }
    }

    if (removeIdx != -1) {
      [self->persons removeObjectAtIndex:removeIdx];
      [self->resultList addObject:partner];
    }
  }
}

- (id)invokeActionForRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  [self _ensureSyncAwake];
  [self _updateAddedPersonList];
  [self _updateRemovedPersonList];

  return [super invokeActionForRequest:_request inContext:_ctx];
}

- (void)setShowExtended:(BOOL)_flag {
  self->showExtended = _flag;
}
- (BOOL)showExtended {
  return self->showExtended;
}

- (NSArray *)persons {
  return [self->persons sortedArrayUsingFunction:comparePersons context:NULL];
}

- (NSArray *)resultList {
  return self->resultList;
}

- (void)setAddedPersons:(NSMutableArray *)_addedPersons {
  ASSIGN(self->addedPersons, _addedPersons);
}
- (NSMutableArray *)addedPersons {
  return self->addedPersons;
}

- (void)setRemovedPersons:(NSMutableArray *)_removedPersons {
  ASSIGN(self->removedPersons, _removedPersons);
}
- (NSMutableArray *)removedPersons {
  return self->removedPersons;
}

- (void)setIsPersonChecked:(BOOL)_flag {
  if (!_flag) [self->removedPersons addObject:[self item]];
}
- (BOOL)isPersonChecked {
  return YES;
}

- (void)setSearchText:(NSString *)_text {
  if (self->searchText != _text) {
    RELEASE(self->searchText); self->searchText = nil;
    self->searchText = [_text copyWithZone:[self zone]];
  }
}
- (NSString *)searchText {
  return self->searchText;
}

- (BOOL)hasPersonSelection {
  return ([self->persons count] + [self->resultList count]) > 0 ? YES : NO;
}

- (void)_removeDuplicateAccountListEntries {
  int i, count;

  for (i = 0, count = [self->persons count]; i < count; i++) {
    int j, count2;
    id  pkey;

    pkey = [[self->persons objectAtIndex:i] valueForKey:@"companyId"];
    if (pkey == nil) continue;

    for (j = 0, count2 = [self->resultList count]; j < count2; j++) {
      id anAccount = [self->resultList objectAtIndex:j];

      if ([[anAccount valueForKey:@"companyId"] isEqual:pkey]) {
        [self->resultList removeObjectAtIndex:j];
        break; // must break, otherwise 'count2' will be invalid
      }
    }
  }
}

- (id)search {
  [self->resultList removeAllObjects];

  // search in persons
  if ([self->searchText length] > 0) {
    EOFetchSpecification *fspec = nil;
    EOQualifier          *qual  = nil;
    NSString             *sText = nil;

    sText = [NSString stringWithFormat:@"*%@*", self->searchText];
    qual  = [EOQualifier qualifierWithQualifierFormat:
                         @"name like %@ or firstname like %@ or "
                         @"nickname like %@ or login like %@",
                         sText, sText, sText, sText];

    fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                                  qualifier:qual
                                  sortOrderings:nil];

    [self->personDataSource setFetchSpecification:fspec];
    [self->resultList
         addObjectsFromArray:[self->personDataSource fetchObjects]];
  }
  [self _removeDuplicateAccountListEntries];
  [self->resultList sortUsingFunction:comparePersons context:NULL];
  return nil;
}

- (BOOL)save {
  EODataSource *ds;
  NSArray *oldPersons;
  int     i, cnt;

  [self _updateAddedPersonList];
  [self _updateRemovedPersonList];
  ds = [[self enterprise] personDataSource];
  
  oldPersons = [ds fetchObjects];

  for (i = 0, cnt = [oldPersons count]; i < cnt; i++) {
    id p;

    p = [oldPersons objectAtIndex:i];
    if (![self->persons containsObject:p])
      [ds deleteObject:p];
  }
  for (i = 0, cnt = [self->persons count]; i < cnt; i++) {
    id p;

    p = [self->persons objectAtIndex:i];
    if (![oldPersons containsObject:p])
      [ds insertObject:p];
  }
  return YES;
}

- (id)newPerson {
  LSCommandContext *ctx;
  EODataSource     *ds;
  
  ctx = [[self session] commandContext];
  
  ASSIGN(self->newPerson, nil);
  self->newPerson = 
    [(SkyPersonDocument *)[SkyPersonDocument alloc] initWithContext:ctx];
  
  ds = [self->newPerson enterpriseDataSource];
  NSAssert1(ds != nil, @"missing enterprise-datasource for person %@",
            self->newPerson);
  [ds insertObject:[self enterprise]];

  return [self activateObject:self->newPerson withVerb:@"edit"];
}

@end /* SkyAssignPersonSubEditor */
