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

#include "OGoMailAddressSearch.h"
#include "OGoMailAddressRecord.h"
#include "OGoMailAddressRecordResult.h"
#include <OGoWebMail/SkyImapMailRestrictions.h>
#include "common.h"

@implementation OGoComplexMailAddressSearch

static BOOL profileOn          = NO;
static int  SearchMailingLists = -1;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  profileOn          = [ud boolForKey:@"OGoProfileMailAddressSearch"];
  SearchMailingLists = [ud boolForKey:@"UseMailingListManager"] ? 1 : 0;
}

/* fetching */

- (id)_personSearchRecord {
  return [self->cmdctx runCommand:@"search::newrecord", 
              @"entity", @"Person", nil];
}
- (id)_personSearchRecordForString:(NSString *)_search {
  id rec;
  
  rec = [self _personSearchRecord];
  [rec takeValue:_search forKey:@"name"];
  [rec takeValue:_search forKey:@"firstname"];
  [rec takeValue:_search forKey:@"description"];
  [rec takeValue:_search forKey:@"login"];
  return rec;
}

- (id)_enterpriseSearchRecord {
  return [self->cmdctx runCommand:@"search::newrecord",
              @"entity", @"Enterprise", nil];
}
- (id)_enterpriseSearchRecordForString:(NSString *)_search {
  id rec;
  
  rec = [self _enterpriseSearchRecord];
  [rec takeValue:_search forKey:@"description"];
  [rec takeValue:_search forKey:@"email"];
  return rec;
}

- (NSMutableArray *)_fetchAllCompanyEOsMatchingString:(NSString *)_search {
  NSArray        *persons, *teams, *enterprises;
  NSMutableArray *res;
  id             rec, email1Rec, email2Rec, email3Rec;
  
  if ([_search length] == 0)
    return nil;
  
  rec       = [self _personSearchRecordForString:_search];
  email1Rec = [self _emailSearchRecord:@"email1" value:_search];
  email2Rec = [self _emailSearchRecord:@"email2" value:_search];
  email3Rec = [self _emailSearchRecord:@"email3" value:_search];
  
  {
    NSArray      *emailPersons, *tmp;
    NSMutableSet *extSearchResult;
    
    persons = [self fetchPersonsMatchingSearchRecord:rec];
    extSearchResult = [NSMutableSet setWithArray:persons];
    self->currentFetchCount += [persons count];
    
    rec = [self _personSearchRecord];
    
    if ([self canFetchMoreMailEntries]) {
      tmp          = [NSArray arrayWithObjects:rec, email1Rec, nil];
      emailPersons = [self fetchPersonsMatchingAllSearchRecords:tmp];
      [extSearchResult addObjectsFromArray:emailPersons];
      self->currentFetchCount += [emailPersons count];
    }
    
    if ([self canFetchMoreMailEntries]) {
      tmp          = [NSArray arrayWithObjects:rec, email2Rec, nil];
      emailPersons = [self fetchPersonsMatchingAllSearchRecords:tmp];
      [extSearchResult addObjectsFromArray:emailPersons];
      self->currentFetchCount += [emailPersons count];
    }
    
    if ([self canFetchMoreMailEntries]) {
      tmp          = [NSArray arrayWithObjects:rec, email3Rec, nil];
      emailPersons = [self fetchPersonsMatchingAllSearchRecords:tmp];
      [extSearchResult addObjectsFromArray:emailPersons];
      self->currentFetchCount += [emailPersons count];
    }
    
    persons = [extSearchResult allObjects];
  }

  rec       = [self _enterpriseSearchRecordForString:_search];
  email2Rec = [self _emailSearchRecord:@"email2" value:_search];
  email3Rec = [self _emailSearchRecord:@"email3" value:_search];
  {
    NSArray      *tmp;
    NSMutableSet *extSearchResult;
    
    enterprises = [self fetchEnterprisesMatchingSearchRecord:rec];
    self->currentFetchCount += [enterprises count];
      
    extSearchResult = [NSMutableSet setWithArray:enterprises];

    rec = [self _enterpriseSearchRecord];
      
    if ([self canFetchMoreMailEntries]) {
      tmp         = [NSArray arrayWithObjects:rec, email2Rec, nil];
      enterprises = [self fetchEnterprisesMatchingAllSearchRecords:tmp];
      [extSearchResult addObjectsFromArray:enterprises];
      self->currentFetchCount += [enterprises count];
    }
    
    if ([self canFetchMoreMailEntries]) {
      tmp         = [NSArray arrayWithObjects:rec, email3Rec, nil];
      enterprises = [self fetchEnterprisesMatchingAllSearchRecords:tmp];
      [extSearchResult addObjectsFromArray:enterprises];
      self->currentFetchCount += [enterprises count];
    }
      
    enterprises = [extSearchResult allObjects];
  }
  
  teams = [self canFetchMoreMailEntries]
    ? [self fetchTeamsWithDescription:_search]
    : nil;
  
  res = [NSMutableArray arrayWithCapacity:[persons count] + [teams count]];
  
  if ([persons count] > 0)
    [res addObjectsFromArray:persons];
  if ([teams count] > 0)
    [res addObjectsFromArray:teams];

  if ([enterprises count] > 0)
    [res addObjectsFromArray:enterprises];

  return res;
}

@end /* OGoComplexMailAddressSearch */

