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

static NSString     *skyrixId = nil;
static NSDictionary *telephoneMapping = nil;
static NSDictionary *addressMapping = nil;

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
  [_ms appendString:@"BEGIN:vCard\r\n"];
  [_ms appendString:@"VERSION:3.0\r\n"];
  [_ms appendFormat:@"PRODID:-//OpenGroupware.org//LSAddress v%i.%i.%i\r\n",
         OGO_MAJOR_VERSION, OGO_MINOR_VERSION, OGO_SUBMINOR_VERSION];
  [_ms appendString:@"PROFILE:vCard\r\n"];
}
- (void)appendPostambleToString:(NSMutableString *)_ms {
  [_ms appendString:@"END:vCard\r\n"];
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
  // TODO: better map to sensitivity?
  if ([(tmp = [_contact valueForKey:@"isPrivate"]) isNotNull]) {
    [self _appendName:@"CLASS"
          andValue:[tmp boolValue] ? @"PRIVATE" : @"PUBLIC"
          toVCard:_vCard];
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
    
    if ([type isNotNull] && [type hasPrefix:@"V:"]) {
      /* a vCard specific type */
      type = [type substringFromIndex:2];
      
      // remove counter (eg V:1work, V:2work)
      if ([type length] > 0 && isdigit([type characterAtIndex:0]))
        type = [type substringFromIndex:1];
      
      if ([type hasSuffix:@"untyped"]) /* imported VCF had no ADR type */
        type = nil;
    }
    else
      type = [addressMapping valueForKey:type];
    
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

- (void)_appendTelephoneData:(id)_company toVCard:(NSMutableString *)_vCard {
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
    type      = ([type length] > 0)
      ? [NSString stringWithFormat:@"TEL;TYPE=%@", type] : @"TEL";
    telephone = [telephone valueForKey:@"realNumber"];

    if ([telephone length] > 0)
      [self _appendName:type andValue:telephone toVCard:_vCard];
  }
}

- (void)_appendExtendedAttributes:(id)_contact
  toVCard:(NSMutableString *)_vCard
{
  // todo: deliver company values
}

/* main entry */

- (void)appendContentForObject:(id)_company toString:(NSMutableString *)_ms {
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

- (void)_appendPersonEmail:(id)_person toVCard:(NSMutableString *)_vCard {
  id tmp;
  // TODO: 'email' column
  
  // EMAIL
  if ([(tmp = [_person valueForKey:@"email1"]) isNotNull]) {
    [self _appendName:@"EMAIL;TYPE=internet,pref" andValue:tmp
          toVCard:_vCard];  
  }
  if ([(tmp = [_person valueForKey:@"email2"]) isNotNull]) 
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];  
  if ([(tmp = [_person valueForKey:@"email3"]) isNotNull]) 
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];
}

- (void)_appendPersonData:(id)_person toVCard:(NSMutableString *)_vCard {
  // FN, N, EMAIL, NICKNAME, BDAY, TITLE, FBURL
  id tmp;
  
  [self _appendPersonName:_person  toVCard:_vCard];  // FN, N
  [self _appendPersonEmail:_person toVCard:_vCard]; // EMAIL
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
    [self logWithFormat:@"GEN FB: %@ (%@)", tmp, [tmp class]];
    [self _appendName:@"FBURL" andValue:tmp toVCard:_vCard];
  }
}

- (void)appendContentForObject:(id)_comp toString:(NSMutableString *)_ms {
  [self _appendPersonData:_comp toVCard:_ms];
  
  [self _appendIdentifier:_comp         toVCard:_ms];
  [self _appendContactData:_comp        toVCard:_ms];
  [self _appendAddressData:_comp        toVCard:_ms];
  [self _appendTelephoneData:_comp      toVCard:_ms];
  [self _appendExtendedAttributes:_comp toVCard:_ms];
}

@end /* LSVCardPersonFormatter */


@implementation LSVCardEnterpriseFormatter

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
  [self _appendName:@"ORG" andValue:tmp toVCard:_vCard];
  // N
  [_vCard appendString:@"N:"];
  [self _appendTextValue:tmp toVCard:_vCard];
  if ([tmp = ([_e valueForKey:@"number"]) isNotNull]) {
    [_vCard appendString:@";"];
    [self _appendTextValue:tmp toVCard:_vCard];
  }
  [_vCard appendString:@"\r\n"];

  if ([(tmp = [_e valueForKey:@"email"]) isNotNull])
    [self _appendName:@"EMAIL;TYPE=internet" andValue:tmp toVCard:_vCard];
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
