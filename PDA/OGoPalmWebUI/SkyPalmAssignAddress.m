/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoPalmUI/SkyPalmAssignEntry.h>

@interface SkyPalmAssignAddress : SkyPalmAssignEntry
{
  NSString   *addressType;
  NSArray    *addresses;
  NSString   *searchString;
}
@end /* SkyPalmAssignAddress */

#include "common.h"
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoPalm/SkyPalmConstants.h>

@interface EODataSource(FetchDS)
- (void)setFetchSpecification:(EOFetchSpecification *)_fspec;
@end

@interface SkyPalmAssignAddress(PrivatMethods)
- (void)setAddressType:(NSString *)_type;
- (void)setSearchString:(NSString *)_str;
- (BOOL)hasAddress;
- (id)searchAddresses;
- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc;
@end

@implementation SkyPalmAssignAddress

- (id)init {
  if ((self = [super init])) {
    [self setAddressType:@"person"];
    self->addresses = nil;
    [self setSearchString:@" "];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->addressType);
  RELEASE(self->addresses);
  RELEASE(self->searchString);
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  if ([super prepareForActivationCommand:_command
             type:_type configuration:_cfg])
    {
      if ([self assignToRecord]) {
        if (![self hasAddress]) {
          [self searchAddresses];
        }
      }

      return YES;
    }
  return NO;
}

/* accessors */

- (void)setAddressType:(NSString *)_type {
  ASSIGNCOPY(self->addressType,_type);
}
- (NSString *)addressType {
  return self->addressType;
}

- (NSArray *)addresses {
  return self->addresses;
}

- (id)address {
  return [self skyrixRecord];
}

- (void)setSearchString:(NSString *)_str {
  ASSIGN(self->searchString,_str);
}
- (NSString *)searchString {
  return self->searchString;
}

- (void)setItemName:(NSString *)_str {

}

// conditions
- (BOOL)hasAddress {
  return ([self createNewRecord])
    ? YES
    : (([self address] != nil)
       ? YES : NO);
}
- (BOOL)hasAddresses {
  if ([self isSingleSelection])
    return NO;
  return YES;
  // either multiple skyrix addresses
  // or multiple palm addresses to create new skyrix addresses
}
- (BOOL)hasAddressOrAddresses {
  if ([self hasAddress])
    return YES;
  return [self hasAddresses];
}
- (BOOL)selectTypeCond {
  if (([self createFromRecord]) || ([self assignToRecord]))
    if ([self hasAddress])
      return NO;
    return YES;
  if ([self createNewRecord])
    return YES;
  return (([self assignToRecord]) && (![self hasAddress]))
    ? YES
    : NO;
}
- (BOOL)hasSearchResult {
  return ((self->addresses != nil) && ([self->addresses count] > 0))
    ? YES
    : NO;
}

// action helper
- (EOQualifier *)_searchPersonsQualifier {
  // TODO: somewhere is a category for constructing such qualifiers
  NSString *query;

  query =
    @"(firstname LIKE '*%@*') OR "  // 1
    @"(name      LIKE '*%@*') OR "  // 2
    @"(nickname  LIKE '*%@*') OR "  // 3
    @"(login     LIKE '*%@*')";     // 4
  query = [NSString stringWithFormat:query,
                    self->searchString, self->searchString,   // 2
                    self->searchString, self->searchString];  // 4
  return [EOQualifier qualifierWithQualifierFormat:query];
}
- (EOQualifier *)_searchEnterprisesQualifier {
  // TODO: somewhere is a category for constructing such qualifiers
  NSString *query;
  
  query =
    @"(name     LIKE '*%@*') OR " // 1
    @"(number   LIKE '*%@*') OR " // 2
    @"(keywords LIKE '*%@*')";    // 3
  query = [NSString stringWithFormat:query,
                    self->searchString, self->searchString,   // 2
                    self->searchString];                      // 3
  return [EOQualifier qualifierWithQualifierFormat:query];
}
- (NSArray *)_sortOrderings {
  static NSArray *sos = nil;
  if (sos == nil) {
    EOSortOrdering *so;
    so = [EOSortOrdering sortOrderingWithKey:@"name" 
                         selector:EOCompareAscending];
    sos = [[NSArray alloc] initWithObjects:&so count:1];
  }
  return sos;
}
- (void)_searchCompaniesWithDS:(EODataSource *)_ds
  andQualifier:(EOQualifier *)_qual
{
  EOFetchSpecification *spec;
  id tmp;
  
  spec = [EOFetchSpecification fetchSpecificationWithEntityName:@"company"
                               qualifier:_qual
                               sortOrderings:[self _sortOrderings]];
  [_ds setFetchSpecification:spec];
  
  tmp = [_ds fetchObjects];
  ASSIGN(self->addresses, tmp);
}

- (void)_searchPersons {
  id ctx = [(id)[self session] commandContext];
  id das = [[SkyPersonDataSource alloc] initWithContext:ctx];
  [self _searchCompaniesWithDS:das
        andQualifier:[self _searchPersonsQualifier]];
  RELEASE(das);
}
- (void)_searchEnterprises {
  id ctx = [(id)[self session] commandContext];
  id das = [[SkyEnterpriseDataSource alloc] initWithContext:ctx];
  [self _searchCompaniesWithDS:das
        andQualifier:[self _searchEnterprisesQualifier]];
  RELEASE(das);
}

// actions
- (id)searchAddresses {
  if ([[self addressType] isEqualToString:@"person"])
    [self _searchPersons];
  if ([[self addressType] isEqualToString:@"enterprise"])
    [self _searchEnterprises];
  if ([self->addresses count] == 1)
    [self setSkyrixRecord:[self->addresses objectAtIndex:0]];
  return nil;
}

- (id)changeAddress {
  [self setSkyrixRecord:nil];
  return nil;
}
- (id)changeAddresses {
  [self->skyrixRecords removeAllObjects];
  [self setSkyrixRecord:nil];
  return nil;
}

- (id)selectAddress {
  [self setSkyrixRecord:self->item];
  return nil;
}

- (id)save {
  if (([self createNewRecord]) && ([self isSingleSelection])) {
    id skyRec;
    if ((skyRec = [self newSkyrixRecordForPalmDoc:[self doc]]) == nil)
      return nil;
    [self setSkyrixRecord:skyRec];
    [self setSyncType:SYNC_TYPE_PALM_OVER_SKY];
  }

  [(SkyPalmAddressDocument *)[self doc] setSkyrixType:[self addressType]];

  return [super save];
}

// overwriting
- (id)fetchSkyrixRecord {
  return [[self doc] skyrixRecord];
}
- (void)setDoc:(SkyPalmDocument *)_doc {
  NSString *search = nil;
  NSString *type   = nil;
  [super setDoc:_doc];

  type   = [(SkyPalmAddressDocument *)_doc skyrixType];
  search = [(SkyPalmAddressDocument *)_doc lastname];
  if ((search == nil) || ([search length] == 0))
    search = [(SkyPalmAddressDocument *)_doc firstname];
  if ((search == nil) || ([search length] == 0)) {
    search = [(SkyPalmAddressDocument *)_doc company];
    if ((search == nil) || ([search length] == 0))
      search = @"";
    else if (![(SkyPalmAddressDocument *)_doc hasSkyrixRecord])
      type = @"enterprise";
  }

  if (type == nil)
    type = @"person";
  [self setSearchString:search];
  [self setAddressType:type];
}
- (NSString *)primarySkyKey {
  return @"companyId";
}

- (void)validateSkyrixRecordForSave:(SkyCompanyDocument *)_skyDoc
                       palmDocument:(SkyPalmDocument *)_doc
{
  if ([self->addressType isEqualToString:@"person"]) {
    // check person values
    SkyPersonDocument *person = (SkyPersonDocument *)_skyDoc;
    if (![[person name] length])
      [person setName:@"person created from Palm entry without a name"];
  }
  else {
    SkyEnterpriseDocument *enterprise;
    enterprise = (SkyEnterpriseDocument *)_skyDoc;
    if (![[enterprise name] length])
      [enterprise setName:
                  @"enterprise created from Palm entry without a name"];
    NSLog(@"%s enterprise name: >%@<",
          __PRETTY_FUNCTION__, [enterprise name]);
  }
}

- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc {
  LSCommandContext *ctx;
  EODataSource     *das = nil;
  id               rec  = nil;
  Class            dsClass;
  
  ctx = [(id)[self session] commandContext];

  dsClass = [self->addressType isEqualToString:@"person"]
    ? [SkyPersonDataSource class]
    : [SkyEnterpriseDataSource class];
  
  das = [[[dsClass alloc] initWithContext:(id)ctx] autorelease];
  
  [(SkyPalmAddressDocument *)_doc setSkyrixType:[self addressType]];
  rec = [das createObject];
  [_doc putValuesToSkyrixRecord:rec];
  [self validateSkyrixRecordForSave:rec palmDocument:_doc];
  if (![(SkyCompanyDocument *)rec save]) {
    [self setErrorString:@"failed saving enterprise"];
    return nil;
  }
  
  return rec;
}


@end /* SkyPalmAssignAddress */
