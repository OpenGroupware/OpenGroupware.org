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

#import <Foundation/NSFormatter.h>
#import <OGoFoundation/SkyEditorComponent.h>

@class NSString, NSMutableArray;

@interface SkyContactSubEditor : SkyEditorComponent
{
  NSString       *searchText;
  NSMutableArray *selectedItems;
  NSMutableArray *resultList;
}
@end /* SkyContactSubEditor */

@interface SkyContactFormatter : NSFormatter
@end

#include <LSFoundation/LSCommandContext.h>
#import <OGoContacts/SkyCompanyDocument.h>
#import "common.h"

@implementation SkyContactFormatter

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

    if (fn != nil)
      result = [NSString stringWithFormat:@"%@, %@", result, fn];
  }
  return result;
}

@end /* SkyContactFormatter */

static NSComparisonResult compareAccounts(id e1, id e2, void* context) {
  static SkyContactFormatter *formatter = nil;

  if (formatter == nil)
    formatter = [[SkyContactFormatter alloc] init];

  return [[formatter stringForObjectValue:e1]
          caseInsensitiveCompare:[formatter stringForObjectValue:e2]];
}

@implementation SkyContactSubEditor

- (id)init {
  if ((self = [super init])) {
    self->resultList    = [[NSMutableArray alloc] init];
    self->selectedItems = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->searchText release];
  [self->resultList release];
  [self->selectedItems release];
  [super dealloc];
}

- (SkyCompanyDocument *)company {
  return (SkyCompanyDocument *)[self document];
}

/* accessors */

- (void)setSearchText:(NSString *)_text {
  if (self->searchText != _text) {
    RELEASE(self->searchText); self->searchText = nil;
    self->searchText = [_text copyWithZone:[self zone]];
  }
}
- (NSString *)searchText {
  return self->searchText;
}

- (void)setContactSelection:(id)_contact {
  [self->selectedItems removeAllObjects];
  if (_contact) [self->selectedItems addObject:_contact];
}

- (id)contactSelection {
  return [self->selectedItems lastObject];
}

- (void)setSelectedItems:(NSMutableArray *)_selectedItems {
  ASSIGN(self->selectedItems, _selectedItems);
}
- (NSMutableArray *)selectedItems {
  return self->selectedItems;
}

- (BOOL)isContactAssigned {
  return ([self contactSelection] != nil) ? YES : NO; 
}

- (NSArray *)resultList {
  return [self->resultList sortedArrayUsingFunction:compareAccounts
              context:NULL];
}

- (NSString *)noContactLabel {
  NSString *l = [[self labels] valueForKey:@"noContact"];

  return (l != nil) ? l : (NSString *)@"- no contact -";
}

- (NSString *)fullNameString {
  static SkyContactFormatter *formatter = nil;
  
  if (formatter == nil)
    formatter = [[SkyContactFormatter alloc] init];
  
  return [formatter stringForObjectValue:[self valueForKey:@"item"]];
}


/* actions */

- (void)prepareEditor {
  id contact = [[self company] contact];
  if ((contact = [[self company] contact]) != nil) {
    [self setContactSelection:contact];  
    [self->resultList addObject:contact];
  }
}

- (id)search {
  LSCommandContext     *ctx;
  Class                clazz;
  EOFetchSpecification *fspec;
  EOQualifier          *qual;
  EODataSource         *ds;
  
  [self->resultList removeAllObjects];

  if (!(self->searchText != nil && [self->searchText length] > 0))
    return nil;
  
  ctx   = [(OGoSession *)[self session] commandContext];
  clazz = NGClassFromString(@"SkyAccountDataSource");

  // TODO: fix type
  ds    = [(SkyAccessManager *)[clazz alloc] initWithContext:ctx];

  qual = [EOQualifier qualifierWithQualifierFormat:
                        [NSString stringWithFormat:
                        @"name like '*%@*' or firstname like '*%@*' or "
                        @"nickname like '*%@*' or login like '*%@*'",
                        self->searchText,
                        self->searchText,
                        self->searchText,
                        self->searchText]];
      
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
				qualifier:qual
				sortOrderings:nil];
  [ds setFetchSpecification:fspec];
  [self->resultList addObjectsFromArray:[ds fetchObjects]];
  [ds release];
  return nil;
}

- (BOOL)save {
  [[self company] setContact:[self contactSelection]];
  
  if (![[self valueForKey:@"accessBox"] boolValue])
    return YES;
  
  if ([self contactSelection]) {
    [[[[self session] valueForKey:@"commandContext"] accessManager]
	setOperation:@"wr"
	onObjectID:[[self company] valueForKey:@"globalID"]
	forAccessGlobalID:[[self contactSelection] globalID]];
  }
  return YES;
}


@end /* SkyContactSubEditor */
