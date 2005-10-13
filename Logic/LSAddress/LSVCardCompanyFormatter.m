/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include "LSVCardCompanyFormatter.h"
#include "LSVCardAddressFormatter.h"
#include "LSVCardLabelFormatter.h"
#include "LSVCardNameFormatter.h"
#include "NSString+VCard.h"
#include "common.h"

NSString *LSVUidPrefix = @"vcfuid://";

@implementation LSVCardCompanyFormatter

static NSString     *skyrixId          = nil;
static NSDictionary *telephoneMapping  = nil;
static NSDictionary *addressMapping    = nil;
static BOOL         renderOGoPhoneType = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  skyrixId = [ud stringForKey:@"skyrix_id"];
  skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
			         [[NSHost currentHost] name], skyrixId];
  
  addressMapping   = [[ud dictionaryForKey:@"LSVCard_AddressMapping"]   copy];
  telephoneMapping = [[ud dictionaryForKey:@"LSVCard_TelephoneMapping"] copy];
}

+ (id)formatter {
  return [[[self alloc] init] autorelease];
}

/* generic */

- (void)appendPreambleToString:(NSMutableString *)_ms {
  [_ms appendString:@"BEGIN:VCARD\r\n"];
  [_ms appendString:@"VERSION:3.0\r\n"];
  [_ms appendFormat:@"PRODID:-//OpenGroupware.org//LSAddress v%i.%i.%i\r\n",
         OGO_MAJOR_VERSION, OGO_MINOR_VERSION, OGO_SUBMINOR_VERSION];
  [_ms appendString:@"PROFILE:vCard\r\n"];
}
- (void)appendPostambleToString:(NSMutableString *)_ms {
  [_ms appendString:@"END:VCARD\r\n"];
}

/* vCard formatting */

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

/* common company stuff */

- (void)_appendIdentifier:(id)_contact toVCard:(NSMutableString *)_vCard {
  // UID, SOURCE
  NSString *sourceUrl;
  id tmp;
  
  if ([(sourceUrl = [_contact valueForKey:@"sourceUrl"]) isNotNull]) {
    NSRange r;
    
    r = [sourceUrl rangeOfString:@"://"];
    if (r.length == 0) {
      /* not a URL, use it as ID, prefix with UID prefix */
      tmp = [LSVUidPrefix stringByAppendingString:sourceUrl];
      [self _appendName:@"UID"    andValue:sourceUrl toVCard:_vCard];
      [self _appendName:@"SOURCE" andValue:tmp       toVCard:_vCard];
    }
    else {
      /* a URL, check for UID prefix, otherwise reuse the URL */
      tmp = [sourceUrl hasPrefix:LSVUidPrefix]
	? [sourceUrl substringFromIndex:[LSVUidPrefix length]]
	: sourceUrl;
      [self _appendName:@"UID"    andValue:tmp       toVCard:_vCard];
      [self _appendName:@"SOURCE" andValue:sourceUrl toVCard:_vCard];
    }
  }
  else {
    /* add internal OGo URL as UID _and_ SOURCE */
    sourceUrl = [skyrixId stringByAppendingString:
			    [[_contact valueForKey:@"companyId"] stringValue]];
    [self _appendName:@"UID"    andValue:sourceUrl toVCard:_vCard];
    [self _appendName:@"SOURCE" andValue:sourceUrl toVCard:_vCard];
  }
}

- (void)_appendContactData:(id)_contact toVCard:(NSMutableString *)_vCard {
  // COMMENT, CATEGORIES, CLASS, URL
  id tmp;
  
  tmp = [[NSString alloc] initWithFormat:
                    @"vCard for contact with id %@ (v%@)",
                    [_contact valueForKey:@"companyId"],
                    [_contact valueForKey:@"objectVersion"]];
  [self _appendName:@"NAME" andValue:tmp toVCard:_vCard];
  [tmp release]; tmp = nil;
  
  /* COMMENT */
  tmp = [[_contact valueForKey:@"comment"] valueForKey:@"comment"];
  if ([tmp isNotNull])
    [self _appendName:@"NOTE" andValue:tmp toVCard:_vCard];

  /* CATEGORIES */
  if ([(tmp = [_contact valueForKey:@"keywords"]) isNotNull]) {
    tmp = [tmp componentsSeparatedByString:@","];
    [self _appendName:@"CATEGORIES" andValue:tmp toVCard:_vCard];
  }

  /* CLASS */
  
  if ([(tmp = [_contact valueForKey:@"sensitivity"]) isNotNull]) {
    NSString *v;
    
    if ([tmp intValue] == 2 /* private*/ || [tmp intValue] == 1 /* Personal */)
      v = @"PRIVATE";
    else if ([tmp intValue] == 3)
      v = @"CONFIDENTIAL";
    else if ([tmp intValue] == 0)
      v = @"PUBLIC";
    else {
      [self errorWithFormat:@"unknown sensitivity, using private: %@", tmp];
      v = @"PRIVATE";
    }
    [self _appendName:@"CLASS" andValue:v toVCard:_vCard];
  }

  /* URL */
  if ([(tmp = [_contact valueForKey:@"url"]) isNotNull]) {
    if ([tmp length] > 0)
      [self _appendName:@"URL" andValue:tmp toVCard:_vCard];
  }
  
  /* X-EVOLUTION-FILE-AS */
  if ([(tmp = [_contact valueForKey:@"fileas"]) isNotNull]) {
    if ([tmp length] > 0)
      [self _appendName:@"X-EVOLUTION-FILE-AS" andValue:tmp toVCard:_vCard];
  }
  
  /* X-EVOLUTION-MANAGER */
  if ([(tmp = [_contact valueForKey:@"bossName"]) isNotNull]) {
    if ([tmp length] > 0)
      [self _appendName:@"X-EVOLUTION-MANAGER" andValue:tmp toVCard:_vCard];
  }
  
  /* X-EVOLUTION-ASSISTANT */
  if ([(tmp = [_contact valueForKey:@"assistantName"]) isNotNull]) {
    if ([tmp length] > 0)
      [self _appendName:@"X-EVOLUTION-ASSISTANT" andValue:tmp toVCard:_vCard];
  }
  
  /* X-EVOLUTION-SPOUSE */
  if ([(tmp = [_contact valueForKey:@"partnerName"]) isNotNull]) {
    if ([tmp length] > 0)
      [self _appendName:@"X-EVOLUTION-SPOUSE" andValue:tmp toVCard:_vCard];
  }
  
  /* ROLE */
  if ([(tmp = [_contact valueForKey:@"occupation"]) isNotNull]) {
    /* 'profession' in Evo UI */
    if ([tmp length] > 0)
      [self _appendName:@"ROLE" andValue:tmp toVCard:_vCard];
  }
  
  /* X-AIM or X-ICQ or X-JABBER */
  if ([(tmp = [_contact valueForKey:@"imAddress"]) isNotNull]) {
    if ([tmp length] > 0) {
      if (isdigit([tmp characterAtIndex:0]))
	[self _appendName:@"X-ICQ" andValue:tmp toVCard:_vCard];
      else if ([tmp rangeOfString:@"@"].length > 0)
	[self _appendName:@"X-JABBER" andValue:tmp toVCard:_vCard];
      else
	[self _appendName:@"X-AIM" andValue:tmp toVCard:_vCard];
    }
  }
  
  /* X-EVOLUTION-ANNIVERSARY */
  if ([(tmp = [_contact valueForKey:@"anniversary"]) isNotNull]) {
    tmp = [[NSString alloc] initWithFormat:@"%04i-%02i-%02i",
			    [tmp yearOfCommonEra], [tmp monthOfYear],
			    [tmp dayOfMonth]];
    [self _appendName:@"X-EVOLUTION-ANNIVERSARY" andValue:tmp 
	  toVCard:_vCard];
    [tmp release];
  }
}

- (NSString *)typeFromVCardTypeHack:(NSString *)type {
  if (![type isNotNull])       return nil;
  if (![type hasPrefix:@"V:"]) return nil;

      /* a vCard specific type */
      type = [type substringFromIndex:2];
      
      // remove counter (eg V:1work, V:2work)
      if ([type length] > 0 && isdigit([type characterAtIndex:0]))
        type = [type substringFromIndex:1];
      
      if ([type hasSuffix:@"untyped"]) /* imported VCF had no ADR type */
        type = nil;
      return type;
}

- (void)_appendAddressData:(id)_contact toVCard:(NSMutableString *)_vCard {
  // ADR, LABEL
  NSArray *addrs;
  int i, cnt;
  
  if (![(addrs = [_contact valueForKey:@"addresses"]) isNotNull]) {
    [self logWithFormat:@"WARNING: got no addresses for contact with id: %@",
          [_contact valueForKey:@"companyId"]];
    return;
  }
  
  for (i = 0, cnt = [addrs count]; i < cnt; i++) {
    NSString *s;
    NSString *type;
    id address;
    
    address = [addrs objectAtIndex:i];
    
    type = [address valueForKey:@"type"];
    
    type = ([type isNotNull] && [type hasPrefix:@"V:"])
      ? [self typeFromVCardTypeHack:type]
      : [addressMapping valueForKey:type];
    
    s = [[LSVCardAddressFormatter formatter] stringForObjectValue:address];
    if (s != nil) {
      [_vCard appendString:@"ADR"];
      if ([type length] > 0) [_vCard appendFormat:@";TYPE=%@", type];
      [_vCard appendString:@":"];
      [_vCard appendString:s];
      [_vCard appendString:@"\r\n"];
    }
    
    s = [[LSVCardLabelFormatter formatter] stringForObjectValue:address];
    if ([s length] > 0) {
      [_vCard appendString:@"LABEL"];
      if ([type length] > 0) [_vCard appendFormat:@";TYPE=%@", type];
      [_vCard appendString:@":"];
      [_vCard appendString:s];
      [_vCard appendString:@"\r\n"];
    }
  }
}

- (NSString *)vCardStringForTelInfo:(NSString *)info {
  NSMutableString *ms;
  
  if (![info isNotNull])  return nil;
  if ([info length] == 0) return nil;
  
  if (![info hasPrefix:@"V:"]) {
    info = [info stringByEscapingUnsafeVCardCharacters];
    return [@";X-OGO-INFO=" stringByAppendingString:info];
  }
  
  info = [info substringFromIndex:2];
  ms   = [NSMutableString stringWithCapacity:32];

  if ([info characterAtIndex:0] == '{') {
    NSDictionary *plist;
    NSEnumerator *e;
    NSString     *k;
	
    plist = [info propertyList];
    e  = [plist keyEnumerator];
    while ((k = [e nextObject]) != nil) {
	  [ms appendString:@";"];
	  [ms appendString:k];
	  [ms appendString:@"="];
	  [ms appendString:[[plist objectForKey:k] stringValue]];
    }
  }
  else {
    [ms appendString:@";"];
    [ms appendString:info];
  }
  return ms;
}

static int compareKey(id o1, id o2, void *ctx) {
  if (o1 == o2) return NSOrderedSame;
  return [(NSString *)[o1 valueForKey:ctx] compare:[o2 valueForKey:ctx]];
}

- (void)_appendTelephoneData:(id)_company toVCard:(NSMutableString *)_vCard {
  /* TEL property */
  NSArray *telephones;
  int i, cnt;
  
  /* always render phones in the same ordering */
  telephones = [_company valueForKey:@"telephones"];
  telephones = [telephones sortedArrayUsingFunction:compareKey
                           context:@"type"];
  for (i = 0, cnt = [telephones count]; i < cnt; i++) {
    NSMutableString *name;
    NSString *num, *type, *info;
    id telephoneEO;
    
    telephoneEO = [telephones objectAtIndex:i];
    type        = [telephoneEO valueForKey:@"type"];
    info        = [telephoneEO valueForKey:@"info"];
    num         = [telephoneEO valueForKey:@"number"];
    
    if (![num isNotNull])  continue;
    if ([num length] == 0) continue;
    
    name = [[NSMutableString alloc] initWithCapacity:128];
    [name appendString:@"TEL"];
    
    if ([type isNotNull] && [type length] > 0) {
      if (renderOGoPhoneType) {
        [name appendString:@";X-OGO-TYPE="];
        [name appendString:type];
      }
      
      if ([type hasPrefix:@"V:"]) {
        if ((type = [self typeFromVCardTypeHack:type]) != nil) {
          [name appendString:@";TYPE="];
          [name appendString:type];
        }
      }
      else if ((type = [telephoneMapping valueForKey:type]) != nil) {
        NSEnumerator *e;
        
        e = [type isKindOfClass:[NSArray class]]
          ? [(id)type objectEnumerator]
          : [[type componentsSeparatedByString:@","] objectEnumerator];
        while ((type = [e nextObject]) != nil) {
          if ([type length] == 0) continue;
          [name appendString:@";TYPE="];
          [name appendString:type];
        }
      }
      else {
        [self logWithFormat:@"Note: did not find a mapping for phone: %@ / %@",
              [telephoneEO valueForKey:@"telephoneId"],
              [telephoneEO valueForKey:@"type"]];
      }
    }
    else {
      [self errorWithFormat:@"phone has no type: %@",
              [telephoneEO valueForKey:@"telephoneId"]];
    }
    
    if ((info = [self vCardStringForTelInfo:info]) != nil)
      [name appendString:info]; /* includes the preceding semicolon */
    
    [self _appendName:name andValue:num toVCard:_vCard];
    [name release]; name = nil;
  }
}

- (void)_appendExtraEmails:(id)_person markFirstAsPreferred:(BOOL)_pref
  toVCard:(NSMutableString *)_vCard
{
  id tmp;
  
  if ([(tmp = [_person valueForKey:@"email1"]) isNotNull]) {
    [self _appendName:(_pref ? @"EMAIL;TYPE=PREF" : @"EMAIL") andValue:tmp
          toVCard:_vCard];  
  }
  if ([(tmp = [_person valueForKey:@"email2"]) isNotNull]) 
    [self _appendName:@"EMAIL" andValue:tmp toVCard:_vCard];  
  if ([(tmp = [_person valueForKey:@"email3"]) isNotNull]) 
    [self _appendName:@"EMAIL" andValue:tmp toVCard:_vCard];
  if ([(tmp = [_person valueForKey:@"email4"]) isNotNull]) 
    [self _appendName:@"EMAIL" andValue:tmp toVCard:_vCard];
}

- (void)_appendExtendedAttributes:(id)_contact
  toVCard:(NSMutableString *)_vCard
{
  // todo: deliver company values eg as Kontact X- attributes
}

/* main entry */

- (void)appendContentForObject:(id)_company toString:(NSMutableString *)_ms {
  // override in subclasses
}

- (NSString *)stringForObjectValue:(id)_company {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:1024];
  [self appendPreambleToString:ms];
  [self appendContentForObject:_company toString:ms];
  [self appendPostambleToString:ms];
  return ms;
}

@end /* LSVCardCompanyFormatter */


@implementation LSVCardTeamFormatter

- (void)_appendTeamData:(id)_team toVCard:(NSMutableString *)_vCard {
  id tmp;
  
  tmp  = [_team valueForKey:@"description"];
  if (![tmp isNotNull] || [tmp length] == 0) {
    tmp = [NSString stringWithFormat:@"Team: %@",
                    [_team valueForKey:@"companyId"]];
  }
  // FN, formatted name
  [self _appendName:@"FN" andValue:tmp toVCard:_vCard];
  // N
  [_vCard appendString:@"N:"];
  [self _appendTextValue:tmp toVCard:_vCard];
  if ([tmp = ([_team valueForKey:@"number"]) isNotNull]) {
    [_vCard appendString:@";"];
    [self _appendTextValue:tmp toVCard:_vCard];
  }
  [_vCard appendString:@"\r\n"];
  
  /* EMAIL */

  if ([(tmp = [_team valueForKey:@"email"]) isNotNull])
    [self _appendName:@"EMAIL;TYPE=PREF" andValue:tmp toVCard:_vCard];
  [self _appendExtraEmails:_team markFirstAsPreferred:NO toVCard:_vCard];
}

- (void)appendContentForObject:(id)_comp toString:(NSMutableString *)_ms {
  [self _appendTeamData:_comp    toVCard:_ms];
  [self _appendIdentifier:_comp  toVCard:_ms];
  [self _appendContactData:_comp toVCard:_ms];
}

@end /* LSVCardTeamFormatter */


@implementation LSVCardPersonFormatter

- (void)_appendPersonName:(id)_person toVCard:(NSMutableString *)_vCard {
  // FN and N are required
  NSString *s;
  
  // N:lastname;givenname;additional names;honorific prefixes;
  //   honorifix suffixes
  s = [[LSVCardNameFormatter formatter] stringForObjectValue:_person];
  [_vCard appendString:@"N:"];
  [_vCard appendString:s];
  [_vCard appendString:@"\r\n"];
  
  s = [[LSVCardFormattedNameFormatter formatter] stringForObjectValue:_person];
  [_vCard appendString:@"FN:"];
  [_vCard appendString:s];
  [_vCard appendString:@"\r\n"];
}

- (void)_appendOrg:(id)_person toVCard:(NSMutableString *)_vCard {
  // sequence: company,department,office
  NSString *org, *dep, *office;
  
  // thats tricky, we might want to map 'org' to the first company?
  org    = [_person valueForKey:@"associatedCompany"]; // TODO: CSV?
  dep    = [_person valueForKey:@"department"];
  office = [_person valueForKey:@"office"];
  if (![org    isNotNull] || [org    length] == 0) org    = nil;
  if (![dep    isNotNull] || [dep    length] == 0) dep    = nil;
  if (![office isNotNull] || [office length] == 0) office = nil;
  
  if (org == nil && dep == nil && office == nil)
    return;
  
  [_vCard appendString:@"ORG:"];
  [_vCard appendString:(org != nil) 
          ? [org stringByEscapingUnsafeVCardCharacters] : @""];
  if (dep != nil || office != nil) {
    [_vCard appendString:@";"];
    [_vCard appendString:(dep != nil) 
            ? [dep stringByEscapingUnsafeVCardCharacters] : @""];
  }
  if (office != nil) {
    [_vCard appendString:@";"];
    [_vCard appendString:[office stringByEscapingUnsafeVCardCharacters]];
  }
  
  [_vCard appendString:@"\r\n"];
}

- (void)_appendPersonData:(id)_person toVCard:(NSMutableString *)_vCard {
  // FN, N, EMAIL, NICKNAME, BDAY, TITLE, FBURL
  id tmp;
  
  [self _appendPersonName:_person  toVCard:_vCard]; // FN, N
  
  // EMAIL
  [self _appendExtraEmails:_person markFirstAsPreferred:YES toVCard:_vCard];
  if ([(tmp = [_person valueForKey:@"email"]) isNotNull])
    [self _appendName:@"EMAIL" andValue:tmp toVCard:_vCard];  
  
  // NICKNAME
  if ([(tmp = [_person valueForKey:@"description"]) isNotNull])
    [self _appendName:@"NICKNAME" andValue:tmp toVCard:_vCard];
  // BDAY
  if ([(tmp = [_person valueForKey:@"birthday"]) isNotNull]) {
    tmp = [[NSString alloc] initWithFormat:@"%04i-%02i-%02i",
			    [tmp yearOfCommonEra], [tmp monthOfYear],
			    [tmp dayOfMonth]];
    [self _appendName:@"BDAY" andValue:tmp toVCard:_vCard];
    [tmp release];
  }
  // TITLE
  if ([(tmp = [_person valueForKey:@"job_title"]) isNotNull])
    [self _appendName:@"TITLE" andValue:tmp toVCard:_vCard];
  
  // TODO: add support for ZideStore CalURLs? (CALURI:)
  // TODO: add support for ZideStore FreeBusy URLs?
  // FBURL
  if ([(tmp = [_person valueForKey:@"freebusyUrl"]) isNotNull]) {
    //[self logWithFormat:@"GEN FB: %@ (%@)", tmp, [tmp class]];
    [self _appendName:@"FBURL" andValue:tmp toVCard:_vCard];
  }
}

- (void)appendContentForObject:(id)_comp toString:(NSMutableString *)_ms {
  [self _appendPersonData:_comp toVCard:_ms];
  
  [self _appendIdentifier:_comp         toVCard:_ms];
  [self _appendContactData:_comp        toVCard:_ms];
  [self _appendAddressData:_comp        toVCard:_ms];
  [self _appendTelephoneData:_comp      toVCard:_ms];
  [self _appendOrg:_comp                toVCard:_ms];
  [self _appendExtendedAttributes:_comp toVCard:_ms];
}

@end /* LSVCardPersonFormatter */


@implementation LSVCardEnterpriseFormatter

- (void)_appendOrg:(id)_contact toVCard:(NSMutableString *)_vCard {
  // sequence: company,department,office
  NSString *org, *dep, *office;
  
  org    = [_contact valueForKey:@"description"];
  dep    = [_contact valueForKey:@"department"];
  office = [_contact valueForKey:@"office"];
  if (![org    isNotNull] || [org    length] == 0) org    = nil;
  if (![dep    isNotNull] || [dep    length] == 0) dep    = nil;
  if (![office isNotNull] || [office length] == 0) office = nil;
  
  if (org == nil && dep == nil && office == nil)
    return;
  
  [_vCard appendString:@"ORG:"];
  [_vCard appendString:(org != nil) 
          ? [org stringByEscapingUnsafeVCardCharacters] : @""];
  if (dep != nil || office != nil) {
    [_vCard appendString:@";"];
    [_vCard appendString:(dep != nil) 
            ? [dep stringByEscapingUnsafeVCardCharacters] : @""];
  }
  if (office != nil) {
    [_vCard appendString:@";"];
    [_vCard appendString:[office stringByEscapingUnsafeVCardCharacters]];
  }
  
  [_vCard appendString:@"\r\n"];
}

- (void)_appendEnterpriseData:(id)_e toVCard:(NSMutableString *)_vCard{
  // FN, N, ORG, EMAIL
  id tmp;
  
  tmp  = [_e valueForKey:@"description"];
  if ([tmp length] == 0) {
    tmp = [NSString stringWithFormat:@"Enterprise: %@",
                    [_e valueForKey:@"companyId"]];
  }
  // FN, formatted name
  [self _appendName:@"FN" andValue:tmp toVCard:_vCard];

  // ORG
  [self _appendOrg:_e toVCard:_vCard];
  
  // N
  [_vCard appendString:@"N:"];
  [self _appendTextValue:tmp toVCard:_vCard];
  if ([tmp = ([_e valueForKey:@"number"]) isNotNull]) {
    [_vCard appendString:@";"];
    [self _appendTextValue:tmp toVCard:_vCard];
  }
  [_vCard appendString:@"\r\n"];
  
  if ([(tmp = [_e valueForKey:@"email"]) isNotNull])
    [self _appendName:@"EMAIL;TYPE=PREF" andValue:tmp toVCard:_vCard];
  
  [self _appendExtraEmails:_e markFirstAsPreferred:NO toVCard:_vCard];
}

- (void)appendContentForObject:(id)_comp toString:(NSMutableString *)_ms {
  [self _appendEnterpriseData:_comp toVCard:_ms];
  
  [self _appendIdentifier:_comp         toVCard:_ms];
  [self _appendContactData:_comp        toVCard:_ms];
  [self _appendAddressData:_comp        toVCard:_ms];
  [self _appendTelephoneData:_comp      toVCard:_ms];
  [self _appendExtendedAttributes:_comp toVCard:_ms];
}

@end /* LSVCardEnterpriseFormatter */
