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

#include <EOControl/EOControl.h>
#include "common.h"
#include "SkyBusinessCardGathering.h"
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyPersonDocument.h>

@implementation SkyBusinessCardGathering

- (NSUserDefaults *)userDefaults {
  return [(OGoSession *)[self session] userDefaults];
}

- (NSArray *)defPersonTeleTypes {
  return [[[self userDefaults] dictionaryForKey:@"LSTeleType"]
                 objectForKey:@"Person"];
}
- (NSArray *)defPersonGatheringPhones {
  return [[self userDefaults] arrayForKey:@"person_gathering_phones"];
}

- (void)_setupPhoneTypesFromDefaults {
  NSEnumerator   *p;
  NSMutableArray *array;
  id             obj;
  NSArray        *wanted;
  
  p      = [[self defPersonTeleTypes] objectEnumerator];
  wanted = [self defPersonGatheringPhones];
  array  = [[NSMutableArray alloc] initWithCapacity:16];
      
  while ((obj = [p nextObject]) != nil) {
    NSMutableDictionary *md;
        
    md = [NSMutableDictionary dictionaryWithObject:obj forKey:@"type"];
    if ([wanted containsObject:obj])
      [array addObject:md];
    else
      [self->otherPhones addObject:md];
  }
  self->phones = [array copy];
  [array release];
}

- (id)init {
  if ((self = [super init])) {
    self->gatheringPerson   = 
      [[NSMutableDictionary alloc] initWithCapacity:16];
    self->gatheringCompany  = 
      [[NSMutableDictionary alloc] initWithCapacity:16];
    self->companySearchList = 
      [[NSMutableArray alloc] initWithCapacity:64];
    self->addedCompanies    = 
      [[NSMutableArray alloc] initWithCapacity:64];
    self->otherPhones       = 
      [[NSMutableArray alloc] initWithCapacity:5];
    
    [self _setupPhoneTypesFromDefaults];
  }
  return self;
}

- (void)dealloc {
  [self->gatheringPerson    release];
  [self->gatheringCompany   release];
  [self->item               release];
  [self->companySearchList  release];
  [self->addedCompanies     release];
  [self->searchCompanyField release];
  [self->phones             release];
  [self->otherPhones        release];
  [self->categories         release];
  [super dealloc];
}

/* accessors */

- (NSMutableDictionary *)gatheringPerson {
  return self->gatheringPerson;
}

- (NSMutableDictionary *)gatheringCompany {
  return self->gatheringCompany;
}

- (void)setCompanySearchList:(NSMutableArray *)_list {
  ASSIGN(self->companySearchList, _list);
}
- (NSMutableArray *)companySearchList {
  return self->companySearchList;
}

- (void)setAddedCompanies:(NSMutableArray *)_comp {
  ASSIGN(self->addedCompanies, _comp);
}
- (NSMutableArray *)addedCompanies {
  return self->addedCompanies;
}

- (void)setSearchCompanyField:(NSString *)_field {
  ASSIGN(self->searchCompanyField, _field);
}
- (NSString *)searchCompanyField {
  return self->searchCompanyField;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSArray *)phones {
  return self->phones;
}

- (void)setCategoryIndex:(int)_idx {
  self->categoryIndex = _idx;
}
- (int)categoryIndex {
  return self->categoryIndex;
}

- (NSString *)nilDummy {
  return @"";
}

- (void)_setCategoryCount:(int)_cnt {
  [[self userDefaults] setObject:[NSNumber numberWithInt:_cnt]
                       forKey:@"person_gathering_category_count"];
}
- (int)categoryCount {
  unsigned cnt;
  
  cnt = [[[self userDefaults]
                objectForKey:@"person_gathering_category_count"] intValue];
  if (cnt < 1) {
    [self _setCategoryCount:1];
    return 1;
  }
  return cnt;
}

- (NSMutableArray *)categories {
  int cnt;
  
  cnt = [self categoryCount];
  if (self->categories == nil) {
    self->categories =
      [[NSMutableArray alloc] initWithCapacity:cnt];
  }
  while ([self->categories count] < cnt)
    [self->categories addObject:[self nilDummy]];
  while ([self->categories count] > cnt)
    [self->categories removeLastObject];
  
  return self->categories;
}

- (void)setCategory:(NSString *)_cat {
  NSMutableArray *ma = [self categories];
  if (self->categoryIndex >= [self categoryCount]) {
    NSLog(@"WARNING[%s]: invalid category index: %d [count: %d]",
          self->categoryIndex, [self categoryCount]);
    return;
  }
  [ma replaceObjectAtIndex:self->categoryIndex
      withObject:(_cat == nil) ? [self nilDummy] : _cat];
}
- (NSString *)category {
  NSString *cat;
  
  if ([[self categories] count] < (self->categoryIndex + 1)) 
    return nil;
  
  cat = [[self categories] objectAtIndex:self->categoryIndex];
  return (cat == [self nilDummy]) ? nil : cat;
}

- (BOOL)isLastCategory {
  return ((self->categoryIndex + 1) == [self categoryCount]);
}
- (BOOL)moreThan1Category {
  return ([self categoryCount] > 1);
}
- (BOOL)hasMoreCategories {
  return ([[[self session] categoryNames] count] > [self categoryCount]);
}

/* actions for the categories */
- (id)decreaseCategories {
  unsigned cnt = [self categoryCount];
  if (cnt > 1) [self _setCategoryCount:cnt-1];
  [[[self session] userDefaults] synchronize];
  return nil;
}
- (id)increaseCategories {
  [self _setCategoryCount:[self categoryCount] + 1];
  [[[self session] userDefaults] synchronize];
  return nil;
}

- (NSString *)phoneLabel {
  return [[self labels] valueForKey:
                          [(NSDictionary *)self->item objectForKey:@"type"]];
}

- (void)setPhoneInfo:(NSString *)_info {
  [self->item takeValue:_info forKey:@"info"];
}
- (NSString *)phoneInfo {
  return [self->item valueForKey:@"info"];
}
- (void)setPhoneNumber:(NSString *)_number {
  [self->item takeValue:_number forKey:@"number"];
}
- (NSString *)phoneNumber {
  return [self->item valueForKey:@"number"];
}

- (BOOL)isEditorPage {
  return YES;
}

/* commands */

- (NSArray *)_searchEnterpriseEOsWithDescription:(NSString *)_s {
  return [self runCommand:@"enterprise::extended-search",
                 @"operator",    @"OR",
                 @"description", _s,
               nil];
}

- (id)_createPersonWithParameters:(NSDictionary *)_record {
  return [self runCommand:@"person::new" arguments:self->gatheringPerson];
}
- (id)_createEnterpriseWithParameters:(NSDictionary *)_record {
  return [self runCommand:@"enterprise::new" arguments:self->gatheringPerson];
}

- (NSArray *)_fetchPersonEOsForEnterpriseEO:(id)_e {
  return [self runCommand:@"enterprise::get-persons", @"enterprise", _e, nil];
}

- (void)_setPersonEOs:(NSArray *)_persons forEnterpriseEO:(id)_enterprise {
  [self runCommand:@"enterprise::set-persons",
          @"group",   _enterprise,
          @"members", _persons, nil];        
}

- (id)_createAddressWithParameters:(NSDictionary *)_record {
  return [self runCommand:@"address::new" arguments:_record];
}
- (id)_updateAddressWithParameters:(NSDictionary *)_record {
  return [self runCommand:@"address::set" arguments:_record];
}

/* notifications */

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (void)postPersonCreated:(id)_person {
  [[self notificationCenter] postNotificationName:SkyNewPersonNotification
                             object:_person];
}
- (void)postEnterpriseCreated:(id)_enterprise {
  // TODO: shouldn't we add the enterprise as the parameter?
  [[self notificationCenter] postNotificationName:SkyNewEnterpriseNotification
                             object:nil];
}

/* actions */

- (id)companySearch {
  NSArray *result;

  [self->companySearchList removeAllObjects];
  result = [self _searchEnterpriseEOsWithDescription:self->searchCompanyField];
  if (result) [self->companySearchList addObjectsFromArray:result];
  return nil; /* stay on page */
}

- (id)save {
  // TODO: clean up this mess
  NSNumber *ownerId = nil;
  id       person   = nil;
  
  if ([self->gatheringPerson valueForKey:@"name"] == nil) {
    [self setErrorString:@"no name for person is set"];
    return nil;
  }
  if (([self->gatheringCompany valueForKey:@"description"] == nil) &&
      ([self->addedCompanies count] == 0)) {
    [self setErrorString:@"no name for enterprise is set"];
    return nil;
  }

  [self->gatheringPerson
       setObject:[self->gatheringPerson objectForKey:@"nickname"]
       forKey:@"description"];
  
  ownerId = [[[self session] activeAccount] valueForKey:@"companyId"];    
  {
    NSArray        *t;
    NSMutableArray *tels;

    tels = [NSMutableArray arrayWithArray:self->otherPhones];
    [tels addObjectsFromArray:self->phones];

    t= [tels sortedArrayUsingKeyOrderArray:
             [NSArray arrayWithObject:
                      [EOSortOrdering sortOrderingWithKey:@"type"
                                      selector:EOCompareAscending]]];

    [self->gatheringPerson setObject:t forKey:@"telephones"];
  }

  [self->gatheringPerson takeValue:ownerId forKey:@"ownerId"];
  {
    NSMutableString *str = [NSMutableString stringWithCapacity:128];
    NSEnumerator    *e   = [self->categories objectEnumerator];
    NSString        *one = nil;
    int             idx  = -1;

    while ((one = [e nextObject])) {
      idx++;
      if (one == [self nilDummy]) continue;
      if ([self->categories indexOfObject:one] == idx) {
        // no double categories
        if ([str length] == 0) [str appendString:one];
        else                   [str appendFormat:@", %@", one];
      }
    }

    [self->gatheringPerson setObject:str forKey:@"keywords"];
  }
  person = [self _createPersonWithParameters:self->gatheringPerson];
  [self postPersonCreated:person];
  
  if ([self->addedCompanies count] > 0) {
    NSEnumerator   *enumerator;
    NSMutableArray *persons    = nil;
    id             obj         = nil;

    enumerator  = [self->addedCompanies objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      [persons release]; persons = nil;
      persons = [[self _fetchPersonEOsForEnterpriseEO:obj] mutableCopy];
      
      if ([persons containsObject:person])
        continue;
      
      [persons addObject:person];
      [self _setPersonEOs:persons forEnterpriseEO:obj];
      [self _fetchPersonEOsForEnterpriseEO:obj]; /* rerun to update faults */
    }
    [persons release]; persons = nil;
  }
  else {
    id company = nil;
    
    [self->gatheringCompany
         setObject:[self->gatheringPerson objectForKey:@"comment"]
         forKey:@"comment"];
    [self->gatheringCompany
         setObject:[self->gatheringPerson objectForKey:@"keywords"]
         forKey:@"keywords"];
    [self->gatheringCompany
         setObject:[NSArray arrayWithObject:person]
         forKey:@"persons"];
    [self->gatheringCompany setObject:ownerId forKey:@"ownerId"];
    [self->gatheringCompany setObject:[EONull null] forKey:@"contactId"];    
    
    company = [self _createPersonWithParameters:self->gatheringCompany];
    [self postEnterpriseCreated:company];
    
    {
      NSEnumerator *enumerator;
      id           obj;
      
      // TODO: replace access of relationship fault
      enumerator = [[company valueForKey:@"toAddress"] objectEnumerator];
      
      while ((obj = [enumerator nextObject]) != nil) {
        if (![[obj valueForKey:@"type"] isEqual:@"bill"])
          continue;
        
        [self->gatheringCompany setObject:[obj valueForKey:@"addressId"]
                                forKey:@"addressId"];
      }
    }
    
    [self->gatheringCompany setObject:@"bill" forKey:@"type"];
    [self->gatheringCompany setObject:[company valueForKey:@"companyId"]
                            forKey:@"companyId"];
    
    if ([self->gatheringCompany valueForKey:@"addressId"] == nil)
      [self _createAddressWithParameters:self->gatheringCompany];
    else
      [self _updateAddressWithParameters:self->gatheringCompany];
  }
  [self leavePage];
  return nil;;
}

- (id)cancel {
  [self leavePage];
  return nil;
}

/* KVC */

- (void)presetGatheringPerson:(id)_person {
  NSDictionary *values = nil;
  if ([_person isKindOfClass:[SkyPersonDocument class]]) {
    values = [_person asDict];
  }
  else if ([_person isKindOfClass:[NSDictionary class]])
    values = _person;

  if (values != nil)
    [self->gatheringPerson addEntriesFromDictionary:values];
  else {
    NSLog(@"%s: unable to preset values from object: %@ (%@)",
          __PRETTY_FUNCTION__, _person, NSStringFromClass([_person class]));
    [self setErrorString:@"unable to preset values"];
  }
}

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"presetGatheringPerson"]) {
    [self presetGatheringPerson:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

@end /* SkyBusinessCardGathering */
