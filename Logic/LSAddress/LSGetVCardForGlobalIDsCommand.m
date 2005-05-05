/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command fetches vCards for globalIds (Person or Enterprise).
  It first fetches the current ids and version of the objects
  (during that the access is checked)
  and looks for cached vCards ( <id>.<version>.vcf in LSAttachmentPath)
  and builds new if needed.
  
  @see: RFC 2426
*/

@class NSString, NSArray;

@interface LSGetVCardForGlobalIDsCommand : LSDBObjectBaseCommand
{
  NSArray  *gids;
  BOOL     buildResponse;
  NSArray  *attributes; // valid: vCardData, companyId, globalID, objectVersion
                        // if not defined, array of iCalStrings is returned
  NSString *groupBy;    // one of the attributes
}

@end

// TODO: do we really need to have a dependency on WOResponse?
#include "NSString+VCard.h"
#include "common.h"
#include <NGObjWeb/WOResponse.h>

@implementation LSGetVCardForGlobalIDsCommand

static NSString     *LSAttachmentPath = nil;
static NSString     *skyrixId = nil;
static NSDictionary *addressMapping = nil;
static NSDictionary *telephoneMapping = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  skyrixId = [ud stringForKey:@"skyrix_id"];
  skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
			         [[NSHost currentHost] name], skyrixId];
  
  addressMapping   = [[ud dictionaryForKey:@"LSVCard_AddressMapping"]   copy];
  telephoneMapping = [[ud dictionaryForKey:@"LSVCard_TelephoneMapping"] copy];
  
  LSAttachmentPath = [[ud stringForKey:@"LSAttachmentPath"] copy];
  if ([LSAttachmentPath length] == 0)
    NSLog(@"ERROR: did not find 'LSAttachmentPath'!");
  else
    NSLog(@"Note: storing cached vCards files in: '%@'", LSAttachmentPath);
}

- (void)dealloc {
  [self->attributes release];
  [self->groupBy    release];
  [self->gids       release];
  [super dealloc];
}

/* command methods */

- (id)_prepareResultForCount:(int)_cnt {
  /* Note: results are retained */
  
  if (([self->attributes count] != 0) && ([self->groupBy length] > 0))
    return [[NSMutableDictionary alloc] initWithCapacity:_cnt+1];
  
  return [[NSMutableArray alloc] initWithCapacity:(_cnt + 1)];
}

- (void)_addVCard:(NSString *)_vCard ofRecord:(id)_record
  toResult:(id)_result
{
  NSMutableDictionary *entry;
  id tmp;
  id val;
  
  if (![_vCard isNotNull]) {
    [self logWithFormat:@"WARNING[%s]: got no vCard!", __PRETTY_FUNCTION__];
    return;
  }
  if ([self->attributes count] == 0) {
    [_result addObject:_vCard];
    return;
  }
  
  entry = [[NSMutableDictionary alloc] initWithCapacity:4];
  [entry setObject:_vCard forKey:@"vCardData"];
  if ([self->attributes containsObject:@"companyId"]) {
    if ((tmp = [_result valueForKey:@"companyId"]))
      [entry setObject:tmp forKey:@"companyId"];
  }
  if ([self->attributes containsObject:@"globalID"]) {
    if ((tmp = [_result valueForKey:@"globalID"]))
      [entry setObject:tmp forKey:@"globalID"];
  }
  if ([self->attributes containsObject:@"objectVersion"]) {
    if ((tmp = [_result valueForKey:@"objectVersion"]))
      [entry setObject:tmp forKey:@"objectVersion"];
  }
  
  if ([self->groupBy length] == 0) {
    [_result addObject:entry];
    return;
  }
      
  if ((tmp = [entry valueForKey:self->groupBy]) == nil) {
    NSLog(@"WARNING[%s]: cannot map entry %@ by key %@",
	  __PRETTY_FUNCTION__, entry, self->groupBy);
    return;
  }
  if ((val = [_result valueForKey:tmp]) != nil) {
    NSLog(@"WARNING[%s]: map already contains an entry for key %@: %@",
	  __PRETTY_FUNCTION__, tmp, val);
    return;
  }
  [(NSMutableDictionary *)_result setObject:entry forKey:tmp];
}

/* build vCard */

- (void)_appendTextValue:(NSString *)_str toVCard:(NSMutableString *)_vCard {
  [_vCard appendString:[_str stringByEscapingUnsafeVCardCharacters]];
}

- (void)_appendName:(NSString *)_name andValue:(id)_value
  toVCard:(NSMutableString *)_vCard
{
  [_vCard appendString:_name];
  [_vCard appendString:@":"];
  if ([_value isKindOfClass:[NSArray class]]) {
    int cnt, i;
    
    for (i = 0, cnt = [_value count]; i < cnt; i++)
      [self _appendTextValue:[_value objectAtIndex:i] toVCard:_vCard];
  }
  else if ([_value isKindOfClass:[NSString class]])
    [self _appendTextValue:_value toVCard:_vCard];
  else 
    [self _appendTextValue:[_value description] toVCard:_vCard];
  [_vCard appendString:@"\r\n"];
}

/* BEGIN: Person specific */

- (void)_appendPersonName:(id)_person
  toVCard:(NSMutableString *)_vCard
{
  // FN and N are required
  NSString *tmp, *tmp2, *fn;
  
  // N, name components
  // FN, formated name
  tmp  = [_person valueForKey:@"name"];
  tmp2 = [_person valueForKey:@"firstname"];
  if (([tmp isNotNull] && ([tmp length] > 0)) &&
      ([tmp2 isNotNull] && ([tmp2 length] > 0))) {
    fn = [[tmp2 stringByAppendingString:@" "] stringByAppendingString:tmp];
  }
  else if ([tmp isNotNull] && [tmp length])
    fn = tmp;  // ok, lastname
  else if ([tmp2 isNotNull] && [tmp2 length])
    fn = tmp2; // take firstname
  else { // no firstname, no lastname, take id
    fn = [NSString stringWithFormat:@"Person: %@",
                   [_person valueForKey:@"companyId"]];
  }
  
  // N:lastname;givenname;additional names;honorific prefixes;
  //   honorifix suffixes
  [_vCard appendString:@"N:"];
  // lastname
  [self _appendTextValue:[tmp isNotNull] ? tmp : fn toVCard:_vCard];
  [_vCard appendString:@";"];
  // firstname
  tmp = tmp2;
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:_vCard];
  [_vCard appendString:@";"];
  // middlename
  tmp = [_person valueForKey:@"middlename"];
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:_vCard];
  [_vCard appendString:@";"];
  // degree
  tmp = [_person valueForKey:@"degree"];
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:_vCard];
  [_vCard appendString:@";"];
  // other title
  tmp = [_person valueForKey:@"other_title1"];
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:_vCard];
  if ([(tmp = [_person valueForKey:@"other_title2"]) isNotNull]) {
    [_vCard appendString:@","];
    [self _appendTextValue:tmp toVCard:_vCard];
  }
  [_vCard appendString:@"\r\n"];

  // FN: formated name
  [self _appendName:@"FN" andValue:fn toVCard:_vCard];
}

- (void)_appendPersonEmail:(id)_person toVCard:(NSMutableString *)_vCard {
  id tmp;
  // EMAIL
  if ([(tmp = [_person valueForKey:@"email1"]) isNotNull])
    [self _appendName:@"EMAIL;TYPE=internet,pref" andValue:tmp
          toVCard:_vCard];  
  if ([(tmp = [_person valueForKey:@"email2"]) isNotNull]) 
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];  
  if ([(tmp = [_person valueForKey:@"email3"]) isNotNull]) 
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];
}

- (void)_appendPersonData:(id)_person
  toVCard:(NSMutableString *)_vCard
{
  // FN, N, EMAIL, NICKNAME, BDAY, TITLE, URL
  id tmp;
  [self _appendPersonName:_person toVCard:_vCard];  // FN, N
  [self _appendPersonEmail:_person toVCard:_vCard]; // EMAIL
  // NICKNAME
  if ([(tmp = [_person valueForKey:@"description"]) isNotNull])
    [self _appendName:@"NICKNAME" andValue:tmp toVCard:_vCard];
  // BDAY
  if ([(tmp = [_person valueForKey:@"birthday"]) isNotNull]) 
    [self _appendName:@"BDAY"
          andValue:[NSString stringWithFormat:@"%04i-%02i-%02i",
                             [tmp yearOfCommonEra], [tmp monthOfYear],
                             [tmp dayOfMonth]]
          toVCard:_vCard];
  // TITLE
  if ([(tmp = [_person valueForKey:@"job_title"]) isNotNull])
    [self _appendName:@"TITLE" andValue:tmp toVCard:_vCard];
}

/* END: Person specific */

/* BEGIN: Enterprise specific */

- (void)_appendEnterpriseData:(id)_enterprise
  toVCard:(NSMutableString *)_vCard
{
  // FN, N, ORG, EMAIL
  id tmp;
  tmp  = [_enterprise valueForKey:@"description"];
  if ([tmp length]) 
    tmp = [NSString stringWithFormat:@"Enterprise: %@",
                    [_enterprise valueForKey:@"companyId"]];
  // FN, formated name
  [self _appendName:@"FN" andValue:tmp toVCard:_vCard];
  // ORG
  [self _appendName:@"ORG" andValue:tmp toVCard:_vCard];
  // N
  [_vCard appendString:@"N:"];
  [self _appendTextValue:tmp toVCard:_vCard];
  if ([tmp = ([_enterprise valueForKey:@"number"]) isNotNull]) {
    [_vCard appendString:@";"];
    [self _appendTextValue:tmp toVCard:_vCard];
  }
  [_vCard appendString:@"\r\n"];

  if ([(tmp = [_enterprise valueForKey:@"email"]) isNotNull])
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];
}

/* END: Enterprise specific */

/* common contact data */
- (void)_appendContactData:(id)_contact toVCard:(NSMutableString *)_vCard {
  // UID, COMMENT, CATEGORIES, CLASS, URL
  id tmp;
  
  tmp = [skyrixId stringByAppendingString:
		    [[_contact valueForKey:@"companyId"] stringValue]];
  // UID
  [self _appendName:@"UID"
        andValue:tmp
        toVCard:_vCard];
  // SOURCE
  [self _appendName:@"SOURCE"
        andValue:[NSString stringWithFormat:
                           @"vCard generated by your OGo on '%@'; "
                           @"contact-id: %@",
                           [[NSHost currentHost] name], tmp]
        toVCard:_vCard];
  // NAME
  [self _appendName:@"NAME"
        andValue:[NSString stringWithFormat:
                           @"vCard for contact with id %@ version: %@",
                           [_contact valueForKey:@"companyId"],
                           [_contact valueForKey:@"objectVersion"]]
        toVCard:_vCard];
  // COMMENT
  if ([(tmp = [[_contact valueForKey:@"comment"] valueForKey:@"comment"])
            isNotNull])
    [self _appendName:@"NOTE" andValue:tmp toVCard:_vCard];
  // CATEGORIES
  if ([(tmp = [_contact valueForKey:@"keywords"]) isNotNull]) {
    tmp = [tmp componentsSeparatedByString:@","];
    [self _appendName:@"CATEGORIES" andValue:tmp toVCard:_vCard];
  }
  // CLASS
  if ([(tmp = [_contact valueForKey:@"isPrivate"]) isNotNull])
    [self _appendName:@"CLASS"
          andValue:[tmp boolValue] ? @"PRIVATE" : @"PUBLIC"
          toVCard:_vCard];
  // URL
  if ([(tmp = [_contact valueForKey:@"url"]) isNotNull])
    [self _appendName:@"URL" andValue:tmp toVCard:_vCard];
}

/* team data */

- (void)_appendTeamData:(id)_team toVCard:(NSMutableString *)_vCard
{
  id tmp;
  tmp  = [_team valueForKey:@"description"];
  if ([tmp length]) 
    tmp = [NSString stringWithFormat:@"Team: %@",
                    [_team valueForKey:@"companyId"]];
  // FN, formated name
  [self _appendName:@"FN" andValue:tmp toVCard:_vCard];
  // N
  [_vCard appendString:@"N:"];
  [self _appendTextValue:tmp toVCard:_vCard];
  if ([tmp = ([_team valueForKey:@"number"]) isNotNull]) {
    [_vCard appendString:@";"];
    [self _appendTextValue:tmp toVCard:_vCard];
  }
  [_vCard appendString:@"\r\n"];

  if ([(tmp = [_team valueForKey:@"email"]) isNotNull])
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];

}

/* address data */

- (void)_appendAddressData:(id)_contact toVCard:(NSMutableString *)_vCard
  inContext:(id)_context
{
  // ADR, LABEL
  NSArray *addrs;
  int i, cnt;
  
  // fetch address data
  addrs = LSRunCommandV(_context,
                        @"address", @"get",
                        @"companyId",  [_contact valueForKey:@"companyId"],
                        @"returnType", intObj(LSDBReturnType_ManyObjects),
                        nil);
  for (i = 0, cnt = [addrs count]; i < cnt; i++) {
    NSString *label;
    id address;
    id type;
    NSString *name1, *name2, *name3, *street, *city, *zip, *country, *state;
    
    address = [addrs objectAtIndex:i];
    type    = [address valueForKey:@"type"];

    name1   = [address valueForKey:@"name1"];
    name2   = [address valueForKey:@"name2"];
    name3   = [address valueForKey:@"name3"];
    street  = [address valueForKey:@"street"];
    city    = [address valueForKey:@"city"];
    zip     = [address valueForKey:@"zip"];
    country = [address valueForKey:@"country"];
    state   = [address valueForKey:@"state"];

    if ([street length] || [city length] || [state length] ||
        [zip length] || [country length]) {
      // ADR: post office box;extended address;street address;city;region;
      //      postal code;country
      // @see Default: LSVCard_AddressMapping

      type = [addressMapping valueForKey:type];
      [_vCard appendString:@"ADR"];
      if ([type length]) [_vCard appendFormat:@";TYPE=%@", type];
      [_vCard appendFormat:@":;;"]; // no post office box; no extended address;
      [self _appendTextValue:street  toVCard:_vCard];
      [_vCard appendFormat:@";"];
      [self _appendTextValue:city    toVCard:_vCard];
      [_vCard appendFormat:@";"];
      [self _appendTextValue:state   toVCard:_vCard];
      [_vCard appendFormat:@";"];
      [self _appendTextValue:zip     toVCard:_vCard];
      [_vCard appendFormat:@";"];
      [self _appendTextValue:country toVCard:_vCard];
      [_vCard appendFormat:@"\r\n"];

    }

    if ([street length] || [city length] || [zip length] || [country length]
        || [name1 length] || [name2 length] || [name3 length]) {
      // LABEL
      label = @"";
      if ([name1 length])
        label = [label stringByAppendingFormat:@"%@\\n", name1];
      if ([name2 length])
        label = [label stringByAppendingFormat:@"%@\\n", name2];
      if ([name3 length])
        label = [label stringByAppendingFormat:@"%@\\n", name3];
    
      if ([street length])
        label = [label stringByAppendingFormat:@"%@\\n", street];
      if ([zip length])
        label = [label stringByAppendingFormat:@"%@ ", zip];
      if ([city length])
        label = [label stringByAppendingFormat:@"%@\\n", city];
      if ([country length])
        label = [label stringByAppendingFormat:@"%@", country];

      if ([label length]) {
        type = ([type length])
          ? [NSString stringWithFormat:@"LABEL;%@", type] : @"LABEL";
        [self _appendName:type andValue:label toVCard:_vCard];
      }
    }
  }
}

/* telephone data */
- (void)_appendTelephoneData:(id)_company toVCard:(NSMutableString *)_vCard
{
  // TEL
  NSArray *telephones;
  int i, cnt;
  
  telephones = [_company valueForKey:@"telephones"];
  for (i = 0, cnt = [telephones count]; i < cnt; i++) {
    id telephone;
    id type;

    telephone = [telephones objectAtIndex:i];
    type      = [telephone valueForKey:@"type"];
    type      = [telephoneMapping valueForKey:type];
    type      = ([type length])
      ? [NSString stringWithFormat:@"TEL;TYPE=%@", type] : @"TEL";
    telephone = [telephone valueForKey:@"realNumber"];

    if ([telephone length]) 
      [self _appendName:type andValue:telephone toVCard:_vCard];
  }
}

- (void)_appendExtendedAttributes:(id)_contact
  toVCard:(NSMutableString *)_vCard
{
  // todo
}

- (NSString *)_buildVCardForContact:(id)_comp inContext:(id)_context {
  NSMutableString *vCard;
  EOKeyGlobalID   *gid;

  vCard = [NSMutableString stringWithCapacity:32];
  [vCard appendString:@"BEGIN:vCard\r\n"];
  [vCard appendString:@"VERSION:3.0\r\n"];
  [vCard appendString:@"PRODID:-//OpenGroupware.org//LSAddress v5.1.0\r\n"];
  [vCard appendString:@"PROFILE:vCard\r\n"];

  gid = [_comp valueForKey:@"globalID"];

  if (([[gid entityName] isEqualToString:@"Team"])) {
    [self _appendTeamData:_comp toVCard:vCard];
    [self _appendContactData:_comp toVCard:vCard];
  }
  else {
    if ([[gid entityName] isEqualToString:@"Person"]) 
      [self _appendPersonData:_comp toVCard:vCard];
    else
      [self _appendEnterpriseData:_comp toVCard:vCard];

    [self _appendContactData:_comp toVCard:vCard];
    [self _appendAddressData:_comp toVCard:vCard inContext:_context];
    [self _appendTelephoneData:_comp toVCard:vCard];
    [self _appendExtendedAttributes:_comp toVCard:vCard];
  }

  [vCard appendString:@"END:vCard\r\n"];

  return vCard;
}


/* fetching */
- (NSArray *)_fetchIdsAndVersionsInContext:(id)_context {
  static NSArray *attrs = nil;
  NSMutableArray *result;
  NSMutableArray *persons;
  NSMutableArray *enterprises;
  NSMutableArray *teams;
  EOKeyGlobalID  *gid;
  int cnt;

  if (attrs == nil) {
    attrs = [[NSArray alloc] initWithObjects:
                             @"companyId", @"globalID",
                             @"objectVersion", nil];
  }

  cnt = [self->gids count];
  if (cnt == 0) return [NSArray array];

  persons     = [[NSMutableArray alloc] initWithCapacity:cnt];
  enterprises = [[NSMutableArray alloc] initWithCapacity:cnt];
  teams       = [[NSMutableArray alloc] initWithCapacity:cnt];

  while (cnt--) {
    gid = [self->gids objectAtIndex:cnt];
    if ([[gid entityName] isEqualToString:@"Person"])
      [persons addObject:gid];
    else if ([[gid entityName] isEqualToString:@"Enterprise"])
      [enterprises addObject:gid];
    else if ([[gid entityName] isEqualToString:@"Team"])
      [teams addObject:gid];
    else {
      [self assert:NO
            reason:[NSString stringWithFormat:@"invalid entityName '%@' "
                             @"(Person and Enterprise accepted)",
                             [gid entityName]]];
    }
  }

  result =
    [NSMutableArray arrayWithCapacity:[persons count]+[enterprises count]+
                    [teams count]];
  if ([persons count] > 0)
    [result addObjectsFromArray:
            LSRunCommandV(_context,
                          @"person",     @"get-by-globalid",
                          @"gids",       persons,
                          @"attributes", attrs,
                          nil)];

  if ([enterprises count] > 0)
    [result addObjectsFromArray:
            LSRunCommandV(_context,
                          @"enterprise", @"get-by-globalid",
                          @"gids",       enterprises,
                          @"attributes", attrs,
                          nil)];

  if ([teams count] > 0)
    [result addObjectsFromArray:
            LSRunCommandV(_context,
                          @"team", @"get-by-globalid",
                          @"gids",       teams,
                          @"attributes", attrs,
                          nil)];


  [persons     release];
  [enterprises release];
  [teams       release];
  return result;
}

/* caching */
- (id)_cachedVCardForRecord:(id)_record inContext:(id)_context {
  NSString       *path;
  NSString       *file;
  NSFileManager  *manager;
  id cId, oV;

  [self assert:(_record != nil) reason:@"no record to fetch vCard for!"];

  cId = [_record valueForKey:@"companyId"];
  oV  = [_record valueForKey:@"objectVersion"];
  if (cId == nil || oV == nil) {
    NSLog(@"%s: missing companyId and/or objectVersion in record: %@",
          __PRETTY_FUNCTION__, _record);
    return nil;
  }
  
  path = LSAttachmentPath;
  
  file = [[NSString alloc] initWithFormat:@"%@.%@.vcf", cId, oV];
  path = [path stringByAppendingPathComponent:file];
  [file release]; file = nil;
  
  manager = [NSFileManager defaultManager];
  
  if ([manager fileExistsAtPath:path]) 
    return [NSString stringWithContentsOfFile:path];  
  return nil;
}

- (void)_cacheVCard:(NSString *)_vCard forContact:(id)_comp
  inContext:(id)_context
{
  NSString       *path;
  NSString       *file;
  NSFileManager  *manager;
  BOOL           ok;
  id cId, oV;

  [self assert:(_vCard != nil) reason:@"no vCard to save!"];
  [self assert:(_comp != nil)  reason:@"no record to save vCard for!"];

  cId = [_comp valueForKey:@"companyId"];
  oV  = [_comp valueForKey:@"objectVersion"];
  if (cId == nil || oV == nil) {
    NSLog(@"%s: missing companyId and/or objectVersion in record: %@",
          __PRETTY_FUNCTION__, _comp);
    return;
  }

  path = LSAttachmentPath;
  file = [NSString stringWithFormat:@"%@.%@.vcf", cId, oV];
  path = [path stringByAppendingPathComponent:file];

  manager = [NSFileManager defaultManager];
  
  if ([manager fileExistsAtPath:path])
    [manager removeFileAtPath:path handler:nil];
  
  ok = [_vCard writeToFile:path atomically:YES];
  [self assert:ok reason:@"error during save of vCard cache file"];
}

/* execution */

- (void)_buildAndCacheVCardsForContacts:(NSArray *)_uncachedContacts
  type:(NSString *)_type // person, enterprise
  result:(id)_result
  inContext:(id)_context
{
  NSArray        *globalIDs;
  NSArray        *contacts;
  NSString       *vCard;
  id             contact;
  int            cnt, i;

  globalIDs = [_uncachedContacts valueForKey:@"globalID"];
  contacts  = LSRunCommandV(_context, _type, @"get-by-globalid",
                            @"gids", globalIDs, nil);

  cnt = [contacts count];

  for (i = 0; i < cnt; i++) {
    contact = [contacts objectAtIndex:i];
    vCard   = [self _buildVCardForContact:contact inContext:_context];
    if (vCard == nil) {
      NSLog(@"%s: failed building vCard for contact:%@", __PRETTY_FUNCTION__,
            contact);
      continue;
    }
    [self _cacheVCard:vCard forContact:contact inContext:_context];
    [self _addVCard:vCard ofRecord:contact toResult:_result];
  }

}

- (id)_buildResponseForVCards:(id)_vCards inContext:(id)_context {
  // TODO: this does not belong here, the command should only provide the
  //       NSData or NSString objects
  NSString *s;
  NSData   *data;
  id       response;
  
  if ([_vCards isKindOfClass:[NSDictionary class]]) 
    _vCards = [_vCards allValues];
  if ([self->attributes count])
    _vCards = [_vCards valueForKey:@"vCardData"];
  
  s    = [_vCards componentsJoinedByString:@""];
  data = [s dataUsingEncoding:NSUTF8StringEncoding];
  response = [[[NSClassFromString(@"WOResponse") alloc] init] autorelease];
  [response setStatus:200];
  [response setHeader:@"text/x-vcard; charset=utf-8" forKey:@"content-type"];
  [response setHeader:@"identity" forKey:@"content-encoding"];
  [response setContent:data];
  
  return response;
}

- (void)_executeInContext:(id)_context {
  NSArray *records;
  id      result; 
  int     cnt;

  /* fetch data */

  records = [self _fetchIdsAndVersionsInContext:_context];
  
  /* process data */
  
  if ((cnt = [records count])) {
    NSMutableArray *uncachedPersons;
    NSMutableArray *uncachedEnterprises;
    NSMutableArray *uncachedTeams;
    id cached, record;
    
    result = [self _prepareResultForCount:cnt]; // retained

    uncachedPersons     = [[NSMutableArray alloc] initWithCapacity:8];
    uncachedEnterprises = [[NSMutableArray alloc] initWithCapacity:8];
    uncachedTeams       = [[NSMutableArray alloc] initWithCapacity:8];
    
    while (cnt--) {
      record = [records objectAtIndex:cnt];
      cached = [self _cachedVCardForRecord:record inContext:_context];
      if (cached) {
        [self _addVCard:cached ofRecord:record toResult:result];
      }
      else {
        EOKeyGlobalID *gid;
	
        gid = [record valueForKey:@"globalID"];
        if ([[gid entityName] isEqualToString:@"Person"])
          [uncachedPersons addObject:record];
        else if ([[gid entityName] isEqualToString:@"Enterprise"])
          [uncachedEnterprises addObject:record];
        else if ([[gid entityName] isEqualToString:@"Team"])
          [uncachedTeams addObject:record];
        else {
	  NSString *error;
	  
	  error = [NSString stringWithFormat:
                                 @"invalid entityName '%@' "
                                 @"(Person, Enterprise and Team accepted)",
			    [gid entityName]];
          [self assert:NO reason:error];
        }
      }
    }

    if ([uncachedPersons count] > 0) {
      [self _buildAndCacheVCardsForContacts:uncachedPersons
            type:@"person"
            result:result
            inContext:_context];
    }
    
    if ([uncachedEnterprises count] > 0) {
      [self _buildAndCacheVCardsForContacts:uncachedEnterprises
            type:@"enterprise"
            result:result
            inContext:_context];
    }
    
    if ([uncachedTeams count] > 0) {
      [self _buildAndCacheVCardsForContacts:uncachedTeams
            type:@"team"
            result:result
            inContext:_context];
    }
    

    [uncachedPersons     release];
    [uncachedEnterprises release];
    [uncachedTeams       release];

  }
  else
    result = [[NSArray alloc] init];

  // TODO: the build response should not be used
  [self setReturnValue:(self->buildResponse)
	? [self _buildResponseForVCards:result inContext:_context]
	: result];
  [result release];
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  ASSIGN(self->gids,_gids);
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:[NSArray arrayWithObject:_gid]];
}
- (EOGlobalID *)globalID {
  return [[self globalIDs] lastObject];
}

- (void)setBuildResponse:(BOOL)_flag {
#if DEBUG
  if (_flag) {
    [self logWithFormat:
	    @"Note: uses vcard command to generate WOResponse which is "
	    @"deprecated"];
  }
#endif
  self->buildResponse = _flag;
}
- (BOOL)buildResponse {
  return self->buildResponse;
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes,_attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setGroupBy:(NSString *)_group {
  ASSIGN(self->groupBy,_group);
}
- (NSString *)groupBy {
  return self->groupBy;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if ([_key isEqualToString:@"buildResponse"])
    [self setBuildResponse:[_value boolValue]];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];
  else if ([_key isEqualToString:@"groupBy"])
    [self setGroupBy:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if ([_key isEqualToString:@"buildResponse"])
    v = [NSNumber numberWithBool:[self buildResponse]];
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"groupBy"])
    v = [self groupBy];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetVCardForGlobalIDsCommand */
