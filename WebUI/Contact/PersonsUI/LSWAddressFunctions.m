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

#include "common.h"
#include "LSWAddressFunctions.h"

id _createResponse(id self, NSData *_data, NSString *_contentType) {
  WOResponse *response = nil;
  id         content   = nil;
  
  response = [WOResponse responseWithRequest:[[self context] request]];
  [response setStatus:200];
  [response setHeader:_contentType forKey:@"content-type"];

  content = _data;

  [response setHeader:@"identity" forKey:@"content-encoding"];

  [response setContent:content];
  
  return response;
}

NSString *_getObj(id self, id _obj, NSString *_field) {
  NSEnumerator *fields = [[_field componentsSeparatedByString:@"."]
                                  objectEnumerator];
  id           field   = nil;
  id           result  = nil;

  result = _obj;

  while ((field = [fields nextObject])) {
    result = [result valueForKey:field];
  }
  if (result == nil || ![result isNotNull])
    result = @"";
  return result;
}

NSData *_createData(id self, NSString *_formKind, NSArray *_records) {
  NSString       *key    = nil;
  NSDictionary   *format = nil;
  NSString       *kind   = nil;
  NSUserDefaults *ud;

  ud = [[self session] userDefaults];

  key = [NSString stringWithFormat:@"LS%@FormLetter", _formKind];

  format = [ud objectForKey:key];
  kind   = [ud objectForKey:@"formletter_kind"];
  
  if (kind == nil)
    kind = @"framemaker";
  
  format = [format objectForKey:kind];

  if (format == nil) {
    NSLog(@"WARNING: unknown FormLetter format");
    return [[[NSData alloc] init] autorelease];
  }
  else {
    NSString        *sep        = nil;
    NSString        *begin      = nil;
    NSString        *end        = nil;
    NSEnumerator    *enumerator = nil;
    id              obj         = nil;
    NSMutableString *result     = nil;
    NSArray         *fields     = nil;
    NSString        *recEnd     = nil;

    sep    = [format objectForKey:@"FormLetterFieldSeperator"];
    begin  = [format objectForKey:@"FormLetterFieldBegin"];
    end    = [format objectForKey:@"FormLetterFieldEnd"];
    recEnd = [format objectForKey:@"RecordEnd"];    
    fields = [format objectForKey:@"FormLetterFields"];

    result = [NSMutableString stringWithCapacity:4096];
    enumerator = [_records objectEnumerator];

    while ((obj = [enumerator nextObject])) {
      id           field      = nil;
      NSEnumerator *fieldEnum = nil;

      fieldEnum = [fields objectEnumerator];
      while ((field = [fieldEnum nextObject])) {
        id strObj = _getObj(self, obj, field);
        
        [result appendString:begin];
        [result appendString:strObj];
        [result appendString:end];        
        [result appendString:sep];
      }
      [result appendString:recEnd];
    }
    return [result dataUsingEncoding:[NSString defaultCStringEncoding]];
  }
  return nil;
}

NSData *_createVCardData(id self, id _obj) {
  NSMutableString *result = [NSMutableString string];

  [result appendString:
   @"BEGIN:vCard\n"
   @"VERSION:3.0\n"
   @"FN:Frank Dawson\n"
          //   @"ORG:Lotus Development Corporation\n"
          //   @"ADR;TYPE=WORK,POSTAL,PARCEL:;;6544 Battleford Drive;Raleigh;"
          //   @"NC;27613-3502;U.S.A.\n"
          //   @"TEL;TYPE=VOICE,MSG,WORK:+1-919-676-9515\n"
          //   @"TEL;TYPE=FAX,WORK:+1-919-676-9564\n"
          //   @"EMAIL;TYPE=INTERNET,PREF:Frank_Dawson@Lotus.com\n"
          //   @"EMAIL;TYPE=INTERNET:fdawson@earthlink.net\n"
          //   @"URL:http://home.earthlink.net/~fdawson\n"
   @"END:vCard\n"];

  /*
  [result appendString:
          @"begin:vcard\n"
          @"n:Spindler;Martin\n"
          @"x-mozilla-html:TRUE\n"
          @"adr:;;;;;;\n"
          @"version:2.1\n"
          @"email;internet:ms@mdlink.de\n"
          @"fn:Martin Spindler\n"
          @"end:vcard\n"];

  [result appendString:_getObj(self, _obj, @"firstname")];
  [result appendString:@" "];
  [result appendString:_getObj(self, _obj, @"middlename")];
  [result appendString:@" "];
  [result appendString:_getObj(self, _obj, @"name")];

  [result appendString:@"\nURL:"];
  [result appendString:_getObj(self, _obj, @"url")];
  [result appendString:@"\nEND:vCard"];
  
  NSLog(@"address is %@", _obj);
  NSLog(@"address is %@", [_obj valueForKey:@"address"]);
  NSLog(@"result is %@", result);
  */
  return [result dataUsingEncoding:[NSString defaultCStringEncoding]];
          
          
/*

birthday = <EONull 327228>;
    companyId = 14510;
    contactId = <EONull 327228>;
    dbStatus = inserted;
    degree = aa;
    description = a;
    imapPasswd = <EONull 327228>;
    isAccount = <EONull 327228>;
    isCustomer = <EONull 327228>;
    isExtraAccount = <EONull 327228>;
    isIntraAccount = <EONull 327228>;
    isLocked = <EONull 327228>;
    isPerson = 1;
    isPrivate = 0;
    isReadonly = 0;
    keywords = <EONull 327228>;
    login = LS14510;
    middlename = AA;
    number = LS14510;
    ownerId = 12885;
    password = <EONull 327228>;
    priority = <EONull 327228>;
    salutation = "01_dear_ms";
    sex = <EONull 327228>;
    url = <EONull 327228>;

  
   ADR;TYPE=WORK,POSTAL,PARCEL:;;6544 Battleford Drive
    ;Raleigh;NC;27613-3502;U.S.A.
   TEL;TYPE=VOICE,MSG,WORK:+1-919-676-9515
   TEL;TYPE=FAX,WORK:+1-919-676-9564
   EMAIL;TYPE=INTERNET,PREF:Frank_Dawson@Lotus.com
   EMAIL;TYPE=INTERNET:fdawson@earthlink.net
   URL:http://home.earthlink.net/~fdawson
   END:vCard
   */
}
