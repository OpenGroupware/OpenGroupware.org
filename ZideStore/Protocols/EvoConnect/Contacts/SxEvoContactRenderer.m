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
// $Id: SxEvoContactRenderer.m 1 2004-08-20 11:17:52Z znek $

#include "SxEvoContactRenderer.h"
#include <Frontend/SxFolder.h>
#include "common.h"

@implementation SxEvoContactRenderer

+ (id)rendererWithFolder:(SxFolder *)_folder inContext:(id)_ctx {
  return [[[self alloc] initWithFolder:_folder inContext:_ctx]
                 autorelease];
}

- (id)initWithFolder:(SxFolder *)_folder inContext:(id)_ctx {
  if ((self = [super init])) {
    self->folder  = [_folder retain];
    self->baseURL = [[_folder baseURLInContext:_ctx] copy];
    self->context = _ctx;
  }
  return self;
}

- (void)dealloc {
  [self->ms      release];
  [self->baseURL release];
  [self->folder  release];
  [super dealloc];
}

/* rendering */

- (NSString *)defaultCountryName {
  return @"Germany";
}

- (NSString *)defaultStateName {
  return @"SA";
}

- (NSString *)defaultZipCode {
  return @"00000"; /* only numbers allowed ? */
}

- (NSString *)renderAddressWithPrefix:(NSString *)_prefix from:(id)_object
{
  NSString *n1, *n2, *n3;
  NSString *s, *z, *c, *co, *so;
  NSString *key;
  BOOL didAdd = NO;
  
  if (self->ms == nil) 
    self->ms = [[NSMutableString alloc] initWithCapacity:256];
  else
    [self->ms setString:@""];

  /* grep values */
  
  // TODO: improve: cache keys and use -valuesForKey:
#if 0 /* names are not used by evo ... */
  key = [_prefix stringByAppendingString:@"name1"];
  n1 = [_object valueForKey:key];
  key = [_prefix stringByAppendingString:@"name2"];
  n2 = [_object valueForKey:key];
  key = [_prefix stringByAppendingString:@"name3"];
  n3 = [_object valueForKey:key];
#else
  n1 = nil;
  n2 = nil;
  n3 = nil;
#endif
  key = [_prefix stringByAppendingString:@"street"];
  s  = [_object valueForKey:key];
  key = [_prefix stringByAppendingString:@"zip"];
  z  = [_object valueForKey:key];
  key = [_prefix stringByAppendingString:@"city"];
  c  = [_object valueForKey:key];
  key = [_prefix stringByAppendingString:@"country"];
  co = [_object valueForKey:key];
  key = [_prefix stringByAppendingString:@"state"];
  so = [_object valueForKey:key];
  
  /* render */

  /* Format is: 
     "$POBox TestStreet1TestStreet2\nTestCity, TestState  TestZip\nUnited States"
     "$street1$street2\n$city, $state  $zip\n$country"
  */
  didAdd = NO;
  
  /* Line A: name & street */
  {
    NSMutableArray *fields;
    
    // TODO: support PO-box
    fields = [[NSMutableArray alloc] initWithCapacity:6];
    if ([n1 length] > 0) [fields addObject:n1];
    if ([n2 length] > 0) [fields addObject:n2];
    if ([n3 length] > 0) [fields addObject:n3];
    if ([s length]  > 0) [fields addObject:s];
    if ([fields count] > 0) {
      [ms appendString:[fields componentsJoinedByString:@"|"]];
      didAdd = YES;
    }
    else
      [ms appendString:@"[street]"];
    [fields release];
  }
  [ms appendString:@"\n"];
  
  /* Line B: city, state zip */
  {
    if ([c length]  > 0) { [ms appendString:c]; didAdd = YES; }
    [ms appendString:@", "];
    if ([so length] > 0) { 
      [ms appendString:so]; 
      didAdd = YES; 
    }
    else {// need to add default for Evo addr editor
      [ms appendString:[self defaultStateName]];
    }
    [ms appendString:@"  "]; // two spaces as a separator
    
    if ([z length] > 0) { 
      [ms appendString:z]; 
      didAdd = YES; 
    }
    else // need to add default for Evo addr editor
      [ms appendString:[self defaultZipCode]];
  }
  [ms appendString:@"\n"];
  
  /* Line C: country */
  if ([co length] > 0) {
    [ms appendString:co];
    didAdd = YES;
  }
  else
    [ms appendString:[self defaultCountryName]];
  
  return didAdd ? [[ms copy] autorelease] : nil;
}

- (id)postProcessRecord:(id)_record {
  NSString *url;
  NSString *pkey;
  
  pkey = [[_record valueForKey:@"pkey"] stringValue];

  if ([_record valueForKey:@"cn"] == nil)
    [_record setObject:[NSString stringWithFormat:@"noname<%@>", pkey]
             forKey:@"cn"];
      
  /* process URL */
  
  if ((url = [NSString stringWithFormat:@"%@%@.EML", self->baseURL,
                       pkey])) {
    [_record setObject:url forKey:@"{DAV:}href"];
    [_record setObject:url forKey:@"davUid"];
  }

  return _record;
}

- (id)renderEntry:(id)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.EML</key>
    <key name="davUid"        >$baseURL$/$pkey$.EML</key>
    <key name="davContentType">text/vcard</key>
    <key name="davDisplayName">$sn$, $givenname$</key>

    <key name="email1addrtype">SMTP</key>
    <key name="email2addrtype">SMTP</key>
    <key name="email3addrtype">SMTP</key>
    <key name="email1">$email1$</key>
    <key name="email2">$email2$</key>
    <key name="email3">$email3$</key>

    <key name="fileas"    >$givenname$ $sn$</key>
    <key name="cn"        >$givenname$ $sn$</key>
    <key name="sn"        >$sn$</key>
    <key name="givenName" >$givenname$</key>
    <key name="middleName">$middlename$</key>
    <key name="title"     >$jobtitle$</key>
    <key name="nickname"  >$nickname$</key>
    <key name="bday"      >$bday$</key>
    <key name="businesshomepage">$url$</key>

    Also:
      namesuffix
      o           [TODO]
      department  [TODO]
      roomnumber  [TODO]
      profession ?
      manager     [TODO]
      secretarycn [TODO]
      spousecn    [TODO]
      weddinganniversary [TODO]
      fburl
      textdescription [TODO]

    <key name="telephoneNumber"         >$tel01$</key>
    <key name="homePhone"               >$tel02$</key>
    <key name="mobile"                  >$tel03$</key>
    <key name="facsimiletelephonenumber">$tel10$</key>
    <key name="homefax"                 >$tel15$</key>

    Also:
      callbackphone
      internationalisdnnumber
      organizationmainphone
      radioTelephoneNumber
      primaryTelephoneNumber
      homephone2
      otherfax
      pager
      telephonenumber2
      telexnumber
      ttytddphone
      secretaryphone
      othermobile
      otherTelephone

      workaddress        (loc)
      homepostaladdress  (priv)
      otherpostaladdress (mail)
  */
  NSMutableDictionary *record;
  id tmp;
  
  if ((record = [[_entry mutableCopy] autorelease]) == nil)
    return nil;
  
  /* email */
  [record setObject:@"SMTP" forKey:@"email1addrtype"];
  [record setObject:@"SMTP" forKey:@"email2addrtype"];
  [record setObject:@"SMTP" forKey:@"email3addrtype"];
  // email1,email2,email3 already present
  
  if ((tmp = [record valueForKey:@"url"])) {
    if (![tmp isEqualToString:@"http://"])
      [record setObject:tmp forKey:@"businesshomepage"];
  }
  return record;
}

@end /* SxEvoContactRenderer */
