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

#include "OGoMailAddressSearch.h"
#include "LSWImapMailEditor.h"
#include "NSString+MailEditor.h"
#include "OGoMailAddressRecord.h"
#include "OGoMailAddressRecordResult.h"
#include <OGoWebMail/SkyImapMailRestrictions.h>
#include "common.h"
#include <NGExtensions/NSString+Ext.h>

// TODO: needs more cleanup, but much better than before ;-)
// TODO: document search restrictions!

/*
  Search restrictions are a bit 'weird' (to be efficient!)
  a) they apply to the initial company fetch! this means, that companies which
     may not even have an email will be included in the restriction, but sorted
     out later! (ie you can end up with 0 records, yet still being restricted!)
  b) same thing for permissions
  c) even at the logic-fetch, we already pass in the restriction
  In short: if a search was restricted, the search result is not deterministic-
  you may be lucky or not.
*/

@interface LSWImapMailEditor(UsedPrivates) // TODO: those should be formatters?
+ (NSString *)_eAddressLabelForPerson:(id)_person
  andAddress:(NSString *)_addr;
+ (NSString *)_eAddressForPerson:(id)_person;
+ (NSString *)_formatEmail:(NSString *)_email forPerson:(id)_person;
@end

static NSComparisonResult _comparePersons(id part1, id part2, void *context);

@implementation OGoMailAddressSearch

static NSNumber *manyKeyNum = nil;
static Class    DateClass   = Nil;

static BOOL profileOn                     = NO;
static BOOL showMultiResultsMessage       = NO;
static int  UseCCForMultipleAddressSearch = -1;
static int  SearchMailingLists            = -1;
static int  DefMaxSearchCount             = 10;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  UseCCForMultipleAddressSearch = 
    [ud boolForKey:@"UseCCForMultipleAddressSearch"] ? 1 : 0;
  SearchMailingLists = [ud boolForKey:@"UseMailingListManager"] ? 1 : 0;
  DefMaxSearchCount = 
    [ud integerForKey:@"OGoMailAddressSearch_MaxSearchCount"];
  
  profileOn = [ud boolForKey:@"OGoProfileMailAddressSearch"];
  showMultiResultsMessage = 
    [ud boolForKey:@"OGoMailAddressSearch_ShowMultiResultsWarning"];
  
  DateClass = [NSDate class];
  if (manyKeyNum == nil)
    manyKeyNum = [[NSNumber numberWithInt:LSDBReturnType_ManyObjects] copy];
}

- (id)initWithCommandContext:(LSCommandContext *)_ctx {
  if ((self = [super init])) {
    self->cmdctx         = [_ctx retain];
    self->maxSearchCount = DefMaxSearchCount;
  }
  return self;
}

- (void)dealloc {
  [self->mailRestrictions release];
  [self->labels release];
  [self->cmdctx release];
  [super dealloc];
}

/* accessors */

- (void)setMailRestrictions:(SkyImapMailRestrictions *)_restrictions {
  ASSIGN(self->mailRestrictions, _restrictions);
}
- (SkyImapMailRestrictions *)mailRestrictions {
  return self->mailRestrictions;
}

/* labels */

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  // TODO: should not be done in this place!
  return self->labels;
}

- (NSString *)label_prohibited {
  return [[self labels] valueForKey:@"label_prohibited"];
}

/* caches */

- (void)reset {
}

/* limits */

- (BOOL)canAddMoreMailEntries {
  return self->currentMailCount < self->maxSearchCount ? YES : NO;
}
- (BOOL)canFetchMoreMailEntries {
  return self->currentFetchCount < self->maxSearchCount ? YES : NO;
}

- (BOOL)doSearchForStringsContainingAt {
  return [[self->cmdctx userDefaults] boolForKey:@"mail_search_for_atstrings"];
}

/* searching in mailing lists */

- (EODataSource *)mailingListDS {
  EODataSource *ds;
  
  ds = [NSClassFromString(@"SkyMailingListDataSource") alloc];

  // TODO: fix prototype
  ds = [(SkyAccessManager *)ds initWithContext:cmdctx];
  return [ds autorelease];
}

/* commands */

- (NSArray *)_fetchSearchRecords:(NSArray *)_recs 
  withCommand:(NSString *)_command
  operator:(NSString *)_op
{
  NSDate *profStartDate;
  NSArray *res;
  if (_recs == nil) return nil;
  profStartDate = profileOn ? [NSDate date] : nil;
  
  res = [self->cmdctx runCommand:_command, 
             @"searchRecords", _recs, @"operator", _op, 
             @"maxSearchCount", 
               [NSNumber numberWithUnsignedInt:self->maxSearchCount],
             nil];
  
  if (profileOn) {
    NSTimeInterval ti = [[NSDate date] timeIntervalSinceDate:profStartDate];
    [self logWithFormat:
            @"PROF:   required search time %.3f (%d results): '%@' / %@",
            ti, [res count], _command, _op];
  }
  return res;
}
- (NSArray *)_fetchSearchRecord:(id)_record withCommand:(NSString *)_command
  operator:(NSString *)_op
{
  NSArray *recs;
  if (_record == nil) return nil;
  recs = [NSArray arrayWithObjects:&_record count:1];
  return [self _fetchSearchRecords:recs withCommand:_command operator:_op];
}

- (NSArray *)fetchPersonsMatchingSearchRecord:(id)_record {
  return [self _fetchSearchRecord:_record 
               withCommand:@"person::extended-search" operator:@"OR"];
}
- (NSArray *)fetchPersonsMatchingAllSearchRecords:(NSArray *)_recs {
  return [self _fetchSearchRecords:_recs
               withCommand:@"person::extended-search" operator:@"AND"];
}

- (NSArray *)fetchTeamsWithDescription:(NSString *)_search {
  return [self->cmdctx runCommand:@"team::get",
              @"description", _search,
              @"returnType", manyKeyNum, nil];
}

- (NSArray *)fetchEnterprisesMatchingSearchRecord:(id)_record {
  return [self _fetchSearchRecord:_record
               withCommand:@"enterprise::extended-search" operator:@"OR"];
}
- (NSArray *)fetchEnterprisesMatchingAllSearchRecords:(NSArray *)_recs {
  return [self _fetchSearchRecords:_recs
               withCommand:@"enterprise::extended-search" operator:@"AND"];
}

/* searching for persons */

- (id)_emailSearchRecord:(NSString *)_key value:(NSString *)_value {
  id rec;
  
  rec = [self->cmdctx runCommand:@"search::newrecord", 
             @"entity", @"CompanyValue",nil];
  [rec takeValue:_key   forKey:@"attribute"];
  [rec takeValue:_value forKey:@"value"];
  return rec;
}

- (NSMutableArray *)_fetchAllCompanyEOsMatchingString:(NSString *)_search {
  [self logWithFormat:
          @"ERROR(%s): method needs to be overridden in subclasses!",
          __PRETTY_FUNCTION__];
  return nil;
}


/* formatting objects (TODO: move to formatter class?) */

- (NSString *)_eAddressLabelForPerson:(id)_pEO andAddress:(NSString *)_addr {
  return [LSWImapMailEditor _eAddressLabelForPerson:_pEO andAddress:_addr];
}
- (NSString *)_formatEmail:(NSString *)_email forPerson:(id)_person {
  return [LSWImapMailEditor _formatEmail:_email forPerson:_person];
}
- (NSString *)_eAddressForPerson:(id)_person {
  return [LSWImapMailEditor _eAddressForPerson:_person];
}

/* processing an address */

- (NSString *)_preprocessSearchItem:(NSString *)searchItem {
  // TODO: Unicode!
  // TODO: this just trims leading spaces, right? => NGExtensions
  return [searchItem stringByTrimmingLeadSpaces];
}

- (OGoMailAddressRecord *)_multiEntry {
  /* this will create the "multi results" entry in the popup */
  NSString *l;
  
  l = [[self labels] valueForKey:@"multiple_searchresults"];
  return [OGoMailAddressRecord mailRecordForEMail:@"" andLabel:l];
}
- (OGoMailAddressRecord *)_emptyEntry {
  /* this will create the "ignore" entry in the popup */
  NSString *l;
  
  l = [[self labels] valueForKey:@"ignore"];
  return [OGoMailAddressRecord mailRecordForEMail:@"" andLabel:l];
}
- (OGoMailAddressRecord *)_restrictedSearchEntry:(NSString *)_s {
  NSString *l;
  
  l = [[self labels] valueForKey:@"restricted_mailaddrsearch_fmt"];
  l = [NSString stringWithFormat:l, _s];
  return [OGoMailAddressRecord mailRecordForEMail:@"" andLabel:l];
}

- (OGoMailAddressRecord *)recordForEmail:(NSString *)_email 
  label:(NSString *)_label 
{
  return [OGoMailAddressRecord mailRecordForEMail:_email andLabel:_label];
}

- (OGoMailAddressRecord *)recordForEmail:(NSString *)_e ofPerson:(id)person {
  NSString *l, *e;
  
  if ([_e length] == 0 || person == nil) return nil;
  e = [person valueForKey:_e];
  if (![e isNotNull]) return nil;
  
  l = [self _eAddressLabelForPerson:person andAddress:e];
  e = [self _formatEmail:e forPerson:person];
  return [self recordForEmail:e label:l];
}

- (OGoMailAddressRecord *)recordForEmail:(NSString *)_e 
  ofEnterprise:(id)_enterprise 
{
  NSString *l, *e, *d;
  OGoMailAddressRecord *r;
  
  if ([_e length] == 0 || _enterprise == nil) return nil;
  e = [_enterprise valueForKey:_e];
  if (![e isNotNull]) return nil;
  
  d = [_enterprise valueForKey:@"description"];
  l = [[NSString alloc] initWithFormat:@"%@ <%@>", d, e];
  r = [self recordForEmail:e label:l];
  [l release];
  return r;
}

- (void)_processPerson:(id)person andAddRecordsToArray:(NSMutableArray *)_ma {
  OGoMailAddressRecord *record;
  
  if (![self canAddMoreMailEntries]) return;
  
  if ((record = [self recordForEmail:@"email1" ofPerson:person]))
    [_ma addObject:record];
  if ((record = [self recordForEmail:@"email2" ofPerson:person]))
    [_ma addObject:record];
  if ((record = [self recordForEmail:@"email3" ofPerson:person]))
    [_ma addObject:record];
}

- (void)_processTeam:(id)_team andAddRecordsToArray:(NSMutableArray *)_ma {
  NSString *la, *e, *l;
  
  if (![self canAddMoreMailEntries]) return;
  
  la = [_team valueForKey:@"email"];
  
  if (![la isNotNull]) {
    NSArray         *members;
    NSMutableString *eAddrs;
    int             i, cnt;
    BOOL            first;

    first   = YES;
    eAddrs  = [NSMutableString stringWithCapacity:32];
    la      = [_team valueForKey:@"description"];
    members = [_team valueForKey:@"members"];

    if (members == nil) {
      // restrict fetch?
      members = [self->cmdctx runCommand:@"team::members",
                     @"object", _team, nil];
      members = [_team valueForKey:@"members"];
    }
    for (i = 0, cnt = [members count]; i < cnt; i++) {
      NSString *a;
      id       p;

      p = [members objectAtIndex:i];
      a = [self _formatEmail:[self _eAddressForPerson:p]
                forPerson:p];
      a = [a stringByRemovingCharacter:','];
      a = [a stringByRemovingCharacter:'\''];
                
      if (a != nil) {
        if (!first) 
          [eAddrs appendString:@","];
        else 
          first = NO;
        [eAddrs appendString:a];
      }
    }
    e = eAddrs;
    l = [NSString stringWithFormat:@"%@: %@",
                  [_team valueForKey:@"description"],
                  [e shortened:80]];
  }
  else {
    e = la;
    l = [NSString stringWithFormat:@"%@ <%@>",
                  [_team valueForKey:@"description"], e];
  }
  
  [_ma addObject:[self recordForEmail:e label:l]];
}

- (void)_processEnterprise:(id)_en andAddRecordsToArray:(NSMutableArray *)_ma {
  OGoMailAddressRecord *record;

  if (![self canAddMoreMailEntries]) return;
  
  if ((record = [self recordForEmail:@"email" ofEnterprise:_en]))
    [_ma addObject:record];
  if ((record = [self recordForEmail:@"email2" ofEnterprise:_en]))
    [_ma addObject:record];
  if ((record = [self recordForEmail:@"email3" ofEnterprise:_en]))
    [_ma addObject:record];
}

- (void)_searchMailingListsForString:(NSString *)_searchString 
  andAddRecordsToArray:(NSMutableArray *)emails
{
  NSArray      *mailingLists;
  NSString     *str;
  NSEnumerator *enumerator;
  NSDictionary *obj;
  
  if (![self canAddMoreMailEntries]) return;
  
  mailingLists = [[self mailingListDS] fetchObjects];
  enumerator   = [mailingLists objectEnumerator];
  str          = [_searchString lowercaseString];
  
  while ((obj = [enumerator nextObject])) {
    NSString *s, *l;
    
    s = [[obj objectForKey:@"name"] lowercaseString];
    if ([s rangeOfString:str].length == 0)
      /* not found */
      continue;
    
    s = [obj objectForKey:@"name"];
    s = [[NSString alloc] initWithFormat:@"@@MAILING_LIST_STRING@@:%@", s];
    l = [[NSString alloc] initWithFormat:
                    [[self labels] valueForKey:@"MailingListAddr"],
                    [obj objectForKey:@"name"],
                    [[obj objectForKey:@"emails"] count]];
                              
    [emails addObject:[self recordForEmail:s label:l]];
    [s release]; [l release];
    
    self->currentMailCount++;
    if (self->currentMailCount > self->maxSearchCount)
      break;
  }
}

- (void)_processCompany:(id)_company andAddRecordsToArray:(NSMutableArray *)_a{
  if (_company == nil) return;
  
  if ([[_company valueForKey:@"isPerson"] boolValue])
    [self _processPerson:_company andAddRecordsToArray:_a];
  else if ([[_company valueForKey:@"isTeam"] boolValue])
    [self _processTeam:_company andAddRecordsToArray:_a];
  else if ([[_company valueForKey:@"isEnterprise"] boolValue])
    [self _processEnterprise:_company andAddRecordsToArray:_a];
  else
    [self logWithFormat:@"do not know how to deal with object: %@", _company];
}

- (BOOL)shouldSearchForString:(NSString *)_searchString {
  if (![_searchString doesLookLikeMailAddressWithDomain])
    return YES;
  if ([self doSearchForStringsContainingAt])
    return YES;
  
  [self debugWithFormat:@"not searching for string: '%@'", _searchString];
  return NO;
}

- (OGoMailAddressRecordResult *)resultSetForMails:(NSArray *)_emails
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo
{
  OGoMailAddressRecordResult *addresses;
  
  addresses = [[[OGoMailAddressRecordResult alloc] init] autorelease];
  [addresses setEMails:_emails];

  if (_addFirstFoundAsTo)
    /* first entry will be marked as 'to' */
    [addresses setHeader:@"to"];
  else
    [addresses setHeader:UseCCForMultipleAddressSearch ? @"cc" : @"to"];
  
  if ([_emails isNotEmpty])
    [addresses setEMail:[_emails objectAtIndex:0]];
  
  return addresses;
}

- (id)emailAddressesForStaticMailAddress:(NSString *)_email 
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo
  prohibited:(NSArray **)prohibited_ 
{
  OGoMailAddressRecordResult *addresses = nil;
  NSMutableArray *prohibited, *emails;
  NSString       *e, *l;
  
  if (prohibited_) *prohibited_ = nil;
  if (!(_email != nil && [_email isNotEmpty]))
    return nil;

  prohibited = [NSMutableArray arrayWithCapacity:2];
  emails     = [NSMutableArray arrayWithCapacity:2];
  
  /* create entry ... */

  e = _email;
  l = _email;
  if (![[self mailRestrictions] emailAddressAllowed:e]) {
    [prohibited addObject:e];
    
    e = @"";
    l = [l stringByAppendingFormat:@" (%@)", [self label_prohibited]];
  }
  [emails addObject:[self recordForEmail:e label:l]];
  [emails addObject:[self _emptyEntry]];
  
  /* setup email result object */
  addresses = [self resultSetForMails:emails 
                    addFirstFoundAsTo:_addFirstFoundAsTo];
  
  if (prohibited_)
    *prohibited_ = [prohibited isNotEmpty] ? prohibited : (NSMutableArray*)nil;
  
  return addresses;
}

- (BOOL)shouldSearchMailingListsForString:(NSString *)_searchString {
  if (SearchMailingLists && self->currentMailCount < self->maxSearchCount)
    return YES;
  
  return NO;
}

- (OGoMailAddressRecordResult *)findEmailAddressesForSearchString:(NSString *)_searchString 
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo
  prohibited:(NSArray **)prohibited_ 
{
  // TODO: split up this big method! (already reduced from huge to big ;-)
  /*
    The result is a 'dictionary' which contains the keys:
      'email':  the primary/first email address, best match? (dictionaries)
      'emails': all addresses (an array of dictionaries)
      'header': a string containing the header field (eg 'to')
  */
  OGoMailAddressRecordResult *addresses = nil;
  NSMutableArray *prohibited;
  NSMutableArray *companies;
  NSString       *searchItem, *l;
  NSDate         *profStartDate;
  NSMutableArray *emails;
  int            i, cnt;
  
  // TODO: if the string contains an '@', we should only search in mailaddrs
  
  profStartDate = profileOn ? [NSDate date] : nil;
  
  if (prohibited_) *prohibited_ = nil;
  if (!(_searchString != nil && [_searchString isNotEmpty]))
    return nil;
  
  self->currentMailCount  = 0;
  self->currentFetchCount = 0;
  prohibited = [NSMutableArray array];
  
  [self debugWithFormat:@"search for: '%@'", _searchString];
  searchItem = _searchString;
  
  companies = [self _fetchAllCompanyEOsMatchingString:searchItem];
  if (profileOn)
    [self logWithFormat:@"  got %d company records", [companies count]];
  [companies sortUsingFunction:_comparePersons context:nil];
  
  cnt    = [companies count];    
  emails = [NSMutableArray arrayWithCapacity:(cnt + 2)];
  
  for (i = 0; i < cnt && (self->currentMailCount<self->maxSearchCount);i++) {
    NSMutableArray *array;
    NSEnumerator   *enumerator;
    NSDictionary   *obj;
    id             company;
          
    company = [companies objectAtIndex:i];
    array   = [NSMutableArray arrayWithCapacity:3];
    
    [self _processCompany:company andAddRecordsToArray:array];
    
    /* scan mails in 'array' for prohibited ones */
          
    enumerator = [array objectEnumerator];
    while ((obj = [enumerator nextObject]) != nil) {
      NSString *e, *l;
            
      e = [obj objectForKey:@"email"];
      l = [obj objectForKey:@"label"];
      
      if (![[self mailRestrictions] emailAddressAllowed:e]) {
        [prohibited addObject:e];
        
        l = [l stringByAppendingFormat:@" (%@)", [self label_prohibited]];
        e = @"";
      }
      [emails addObject:[self recordForEmail:e label:l]];
      self->currentMailCount++;
      if (self->currentMailCount > self->maxSearchCount)
        break;
    }
  }
  
  /* search mailing lists */
  
  if ([self shouldSearchMailingListsForString:searchItem])
    [self _searchMailingListsForString:searchItem andAddRecordsToArray:emails];

  /* add the "raw" mail address as an option */
  
  l = searchItem;
  if ((![[self mailRestrictions] emailAddressAllowed:searchItem])) {
    [prohibited addObject:searchItem];
    l = [l stringByAppendingFormat:@" (%@)", [self label_prohibited]];
    searchItem = @"";
  }
  [emails addObject:[self recordForEmail:searchItem label:l]];
  [emails addObject:[self _emptyEntry]];
  
  if (self->currentMailCount >= self->maxSearchCount)
    [emails insertObject:[self _restrictedSearchEntry:searchItem] atIndex:0];
  else if (showMultiResultsMessage && [emails count] > 2)
    [emails insertObject:[self _multiEntry] atIndex:0];
  
  /* setup email result object */
  addresses = [self resultSetForMails:emails 
                    addFirstFoundAsTo:_addFirstFoundAsTo];
  
  if (prohibited_)
    *prohibited_ = [prohibited isNotEmpty] ? prohibited : (NSMutableArray*)nil;
  
  if (profileOn) {
    NSTimeInterval ti = [[NSDate date] timeIntervalSinceDate:profStartDate];
    [self logWithFormat:@"PROF: required search time %.3f (%d results): '%@'",
            ti, [addresses count], _searchString];
  }
  
  return addresses;
}

- (NSArray *)findEmailAddressesForSearchStrings:(NSArray *)_searchStrings
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo
  prohibited:(NSArray **)prohibited_ 
{
  /* 
     This method returns an array of results, which are supposed to map
     1:1 to the popups in the UI.
     You can specify multiple searches in the UI by separating entries
     using a ",".
  */
  NSAutoreleasePool *pool;
  NSMutableArray *resultSets = nil;
  NSMutableArray *prohibited = nil;
  NSEnumerator   *e;
  NSString       *searchString;
  
  if (prohibited_) *prohibited_ = nil;
  if ([_searchStrings count] == 0) {
    if (prohibited_) *prohibited_ = nil;
    return nil;
  }
  
  prohibited = [NSMutableArray array];

  pool = [[NSAutoreleasePool alloc] init];

  e = [_searchStrings objectEnumerator];
  while ((searchString = [e nextObject]) != nil) {
    OGoMailAddressRecordResult *addrset;
    NSArray      *subproh = nil;
    NSString     *searchItem;
    
    searchItem = [self _preprocessSearchItem:searchString];
    
    if ([self shouldSearchForString:searchString]) {
      addrset = [self findEmailAddressesForSearchString:searchItem
                      addFirstFoundAsTo:_addFirstFoundAsTo
                      prohibited:&subproh];
    }
    else {
      addrset = [self emailAddressesForStaticMailAddress:searchItem
                      addFirstFoundAsTo:_addFirstFoundAsTo
                      prohibited:&subproh];
    }
    
    if (subproh) [prohibited addObjectsFromArray:subproh];
    if (addrset == nil) continue;
    
    if (resultSets == nil) 
      resultSets = [[NSMutableArray alloc] initWithCapacity:4];
    [resultSets addObject:addrset];
  }
  
  [pool release];
  
  if (prohibited_)
    *prohibited_ = [prohibited isNotEmpty] ? prohibited : (NSMutableArray*)nil;
  
  return [resultSets autorelease];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return profileOn;
}

@end /* OGoMailAddressSearch */

static NSComparisonResult _comparePersons(id part1, id part2, void *context) {
  BOOL isP1Account, isP2Account;

  isP1Account = [[part1 valueForKey:@"isAccount"] boolValue];
  isP2Account = [[part2 valueForKey:@"isAccount"] boolValue];
  
  /* always sort accounts to top */
  
  if (isP1Account && !isP2Account)
    return NSOrderedAscending;
  if (!isP1Account && isP2Account)
    return NSOrderedDescending;

  /* for two accounts, compare the login */
  
  if (isP1Account && isP2Account) { /* both accounts */
    return [[part1 valueForKey:@"login"]
                   caseInsensitiveCompare:[part2 valueForKey:@"login"]];
  }
  
  /* TODO: compare login for non-accounts?? - probably wrong */
  return [[part1 valueForKey:@"login"]
                 caseInsensitiveCompare:[part2 valueForKey:@"login"]];
}
