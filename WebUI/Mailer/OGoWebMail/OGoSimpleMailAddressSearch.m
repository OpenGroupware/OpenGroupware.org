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

#include "OGoMailAddressSearch.h"
#include "OGoMailAddressRecord.h"
#include "OGoMailAddressRecordResult.h"
#include "SkyImapMailRestrictions.h"
#include "common.h"

/*
  Notes

  - only searches for teams on demand
  - does not search in email2 and email3
  - does not search for enterprises
*/

@implementation OGoSimpleMailAddressSearch

static BOOL profileOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  profileOn = [ud boolForKey:@"OGoProfileMailAddressSearch"];
}

- (BOOL)shouldSearchMailingListsForString:(NSString *)_searchString {
  /* never search mailinglists in simple search */
  return NO;
}

/* fetch operations */

- (BOOL)shouldSearchTeams {
  return [[self->cmdctx userDefaults] 
           boolForKey:@"mail_simplesearch_include_teams"];
}
- (BOOL)shouldSearchEMail1 {
  return [[self->cmdctx userDefaults] 
           boolForKey:@"mail_simplesearch_include_email1"];
}

- (NSMutableArray *)_fetchAllCompanyEOsMatchingString:(NSString *)_search {
  NSArray        *persons, *teams;
  NSMutableArray *res;
  id             rec;
  
  if ([_search length] == 0)
    return nil;
  
  rec = [self->cmdctx runCommand:@"search::newrecord",
                    @"entity", @"Person", nil];
  
  [rec takeValue:_search forKey:@"name"];
  [rec takeValue:_search forKey:@"firstname"];
  [rec takeValue:_search forKey:@"description"];
  [rec takeValue:_search forKey:@"login"];
  
  {
    NSArray      *emailPersons, *tmp;
    NSMutableSet *extSearchResult;

    persons = [self fetchPersonsMatchingSearchRecord:rec];
    extSearchResult = [NSMutableSet setWithArray:persons];
    self->currentFetchCount += [persons count];

    rec = [self->cmdctx runCommand:@"search::newrecord", 
               @"entity", @"Person", nil];
    
    if ([self canFetchMoreMailEntries] && [self shouldSearchEMail1]) {
      id email1Rec;
      
      email1Rec = [self _emailSearchRecord:@"email1" value:_search];
      
      tmp          = [NSArray arrayWithObjects:rec, email1Rec, nil];
      emailPersons = [self fetchPersonsMatchingAllSearchRecords:tmp];
      [extSearchResult addObjectsFromArray:emailPersons];
      self->currentFetchCount += [emailPersons count];
    }
    
    persons = [extSearchResult allObjects];
  }
  
  if ([self shouldSearchTeams]) {
    teams = [self canFetchMoreMailEntries]
      ? [self fetchTeamsWithDescription:_search]
      : nil;
  }
  else
    teams = nil;
  
  res = [NSMutableArray arrayWithCapacity:[persons count] + [teams count]];
  
  if ([persons count] > 0)
    [res addObjectsFromArray:persons];
  if ([teams count] > 0)
    [res addObjectsFromArray:teams];
  
  return res;
}

@end /* OGoSimpleMailAddressSearch */
