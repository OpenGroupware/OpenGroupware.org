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
// $Id: SxFetchContact.m 1 2004-08-20 11:17:52Z znek $

#include "SxFetchContact.h"
#include <EOControl/EOControl.h>
#include "common.h"
#include "NSString+rtf.h"

@implementation SxFetchContact

static inline NSString *attrV(id _v) {
  return [_v isNotNull] ? _v : @"";
}

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    ASSIGN(self->ctx, _ctx);
  }
  return self;
}

- (void)dealloc {
  [self->ctx release];
  [self clearVars];
  [super dealloc];
}

- (void)clearCache {
  [self->addr release]; self->addr = nil;
  [self->phones release]; self->phones = nil;
}

- (void)clearVars {
  self->eo = nil;
  [self->addr release]; self->addr = nil;
  [self->phones release]; self->phones = nil;
}

- (NSString *)entityName {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}

- (NSString *)getName {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}

- (NSString *)phoneForType:(NSString *)_type {
  if (self->phones == nil) {
    NSArray      *tels;
    NSEnumerator *enumerator;
    id           obj;
    NSString     *command;

    command = [NSString stringWithFormat:@"%@::get-telephones",
                        [[self entityName] lowercaseString]];

    self->phones = [[NSMutableDictionary alloc] initWithCapacity:8];

    tels       = [self->ctx runCommand:command, @"object", [self eo], nil];
    enumerator = [tels objectEnumerator];
    
    while ((obj = [enumerator nextObject])) {
      id o;

      if ((o = [obj valueForKey:@"number"])) {
        [self->phones setObject:o forKey:[obj valueForKey:@"type"]];
      }
      else {
        [self->phones setObject:@"" forKey:[obj valueForKey:@"type"]];
      }
    }
  }
  return [self->phones objectForKey:_type];
}

- (id)addressObjForType:(NSString *)_type {
  if (self->addr == nil) {
    NSEnumerator     *enumerator;
    id               obj;

    self->addr = [[NSMutableDictionary alloc] initWithCapacity:8];
    enumerator = [[self->ctx runCommand:@"address::get",
                       @"companyId",
                       [[self eo] valueForKey:@"companyId"],
                       @"returnType",
                       intObj(LSDBReturnType_ManyObjects), nil]
                             objectEnumerator];
    
    while ((obj = [enumerator nextObject])) {
      [self->addr setObject:obj forKey:[obj valueForKey:@"type"]];
    }
  }
  return [self->addr objectForKey:_type];
}

- (NSDictionary *)addressForType:(NSString *)_kind {
  NSDictionary        *address;
  NSMutableDictionary *res;
  
  address = [self addressObjForType:_kind];
  res     = [NSMutableDictionary dictionaryWithCapacity:5];
  
  [res setObject:attrV([address valueForKey:@"city"])    forKey:@"city"];
  [res setObject:attrV([address valueForKey:@"country"]) forKey:@"country"];
  [res setObject:attrV([address valueForKey:@"state"])   forKey:@"state"];
  [res setObject:attrV([address valueForKey:@"street"])  forKey:@"street"];
  [res setObject:attrV([address valueForKey:@"zip"])     forKey:@"zip"];
  return res;
}

- (NSDictionary *)phoneNumbers {
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:4];

  [dict setObject:attrV([self phoneForType:@"01_tel"])
        forKey:@"01_tel"];
  [dict setObject:attrV([self phoneForType:@"03_tel_funk"])
        forKey:@"03_tel_funk"];
  [dict setObject:attrV([self phoneForType:@"05_tel_private"])
        forKey:@"05_tel_private"];
  [dict setObject:attrV([self phoneForType:@"10_fax"])
        forKey:@"10_fax"];

  [dict setObject:attrV([self phoneForType:@"701_assisitantNumber"])
        forKey:@"701_assisitantNumber"];      /* Assistent */
  [dict setObject:attrV([self phoneForType:@"702_officeTelephoneNumber2"])
        forKey:@"702_officeTelephoneNumber2"];  /* gesch2 */
  [dict setObject:attrV([self phoneForType:@"703_confirmationNumber"])
        forKey:@"703_confirmationNumber"];    /* rueckmeldung */
  [dict setObject:attrV([self phoneForType:@"704_carTelephone"])
        forKey:@"704_carTelephone"];
  [dict setObject:attrV([self phoneForType:@"705_organizationmainphone"])
        forKey:@"705_organizationmainphone"];
  [dict setObject:attrV([self phoneForType:@"706_homePhone2"])
        forKey:@"706_homePhone2"];      /* private2" */
  [dict setObject:attrV([self phoneForType:@"707_homeFaxNumber"])
        forKey:@"707_homeFaxNumber"];         /* fax private */
  [dict setObject:attrV([self phoneForType:@"708_isdnNumber"])
        forKey:@"708_isdnNumber"];
  [dict setObject:attrV([self phoneForType:@"709_otherTelephone"])
        forKey:@"709_otherTelephone"];
  [dict setObject:attrV([self phoneForType:@"710_otherFaxNumber"])
        forKey:@"710_otherFaxNumber"];        /* weiteresFax */
  [dict setObject:attrV([self phoneForType:@"711_pagerNumber"])
        forKey:@"711_pagerNumber"];           /* pager */
  [dict setObject:attrV([self phoneForType:@"712_primaryTelephoneNumber"])
        forKey:@"712_primaryTelephoneNumber"];
  [dict setObject:attrV([self phoneForType:@"713_radioTelephoneNumber"])
        forKey:@"713_radioTelephoneNumber"];
  [dict setObject:attrV([self phoneForType:@"714_textPhoneNumber"])
        forKey:@"714_textPhoneNumber"];       /* texttelefon */
  [dict setObject:attrV([self phoneForType:@"715_telexNumber"])
        forKey:@"715_telexNumber"];       /* texttelefon */
  
  return dict;
}


- (NSDictionary *)emails {
  NSMutableDictionary *dict;
  id                  e;

  e    = [self eo];
  dict = [NSMutableDictionary dictionaryWithCapacity:8];
  
  [dict setObject:attrV([e valueForKey:@"email2"])
        forKey:@"email2"];
  [dict setObject:attrV([e valueForKey:@"email3"])
        forKey:@"email3"];
  [dict setObject:attrV([e valueForKey:@"showEmailAs"])
        forKey:@"showEmailAs"];
  [dict setObject:attrV([e valueForKey:@"showEmail2As"])
        forKey:@"showEmail2As"];
  [dict setObject:attrV([e valueForKey:@"showEmail3As"])
        forKey:@"showEmail3As"];
  [dict setObject:attrV([e valueForKey:@"url"])
       forKey:@"url"];
  
  return dict;
}

- (NSDictionary *)contactKeys {
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:1];

  [dict setObject:[self phoneNumbers] forKey:@"phoneNumbers"];

  return dict;
}

- (NSDictionary *)otherKeys {
  static NSString *CompressConst = @"ZideLook rich-text compressed comment: ";
  NSMutableDictionary *dict;
  NSString            *str;
  id                  e, tmp;

  e    = [self eo];
  dict = [NSMutableDictionary dictionaryWithCapacity:2];
  tmp  = [self->ctx runCommand:@"person::get-comment",
              @"object", e,
              @"isToMany", [NSNumber numberWithBool:NO], nil];

  if ([tmp isKindOfClass:[NSArray class]])
    tmp = [tmp lastObject];

  str = attrV([tmp valueForKey:@"comment"]);
  
  if ([str hasPrefix:CompressConst]) {
    str = [str substringFromIndex:[CompressConst length]];
  }
  else {
    str = [[str stringByEncodingRTF] stringByEncodingBase64];
  }
  [dict setObject:str forKey:@"comment-compressed"];
  
  if ((str = [e valueForKey:@"objectVersion"])) {
    [dict setObject:str forKey:@"objectVersion"];
    [dict setObject:str forKey:@"version"];
  }
  if ((str = [e valueForKey:@"companyId"]))
    [dict setObject:str forKey:@"pkey"];

  [dict setObject:attrV([e valueForKey:@"associatedCategories"])
        forKey:@"associatedCategories"];
  
  [dict setObject:attrV([(NSDictionary *)e objectForKey:@"associatedContacts"])
        forKey:@"associatedContacts"];
   
  [dict addEntriesFromDictionary:[self emails]];

  [dict setObject:attrV([e valueForKey:@"job_title"])
        forKey:@"title"];

  [dict setObject:attrV([e valueForKey:@"freebusyUrl"])
        forKey:@"fburl"];

  [dict setObject:attrV([e valueForKey:@"birthday"])
        forKey:@"bday"];

  [dict setObject:attrV([e valueForKey:@"anniversary"])
        forKey:@"anniversary"];

  [dict setObject:attrV([e valueForKey:@"assistantName"])
        forKey:@"assistantName"];
  
  [dict setObject:attrV([e valueForKey:@"dirServer"])
        forKey:@"netMeetingSettings"];

  [dict setObject:attrV([e valueForKey:@"associatedCompany"])
        forKey:@"associatedCompany"];

  [dict setObject:attrV([e valueForKey:@"imAddress"])
        forKey:@"imAddress"];

  [dict setObject:attrV([e valueForKey:@"bossName"])    forKey:@"bossName"];
  [dict setObject:attrV([e valueForKey:@"department"])  forKey:@"department"];
  [dict setObject:attrV([e valueForKey:@"office"])      forKey:@"office"];
  [dict setObject:attrV([e valueForKey:@"partnerName"])
        forKey:@"partnerName"];
  [dict setObject:attrV([e valueForKey:@"occupation"])
        forKey:@"profession"];

  return dict;
}

- (id)eo {
  return self->eo;
}

- (void)setEo:(id)_eo {
  ASSIGN(self->eo, _eo);
}

- (void)loadEOForID:(NSNumber *)_id {
  if (self->eo == nil) {
    self->eo = [self->ctx runCommand:[self getName], 
                    @"companyId", _id, nil];

    if ([self->eo isKindOfClass:[NSArray class]])
      self->eo = [self->eo lastObject];
  }
}

- (NSDictionary *)dictWithPrimaryKey:(NSNumber *)_number {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}

@end /* SxFetchContact */
