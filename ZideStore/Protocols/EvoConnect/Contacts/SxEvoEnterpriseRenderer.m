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
// $Id: SxEvoEnterpriseRenderer.m 1 2004-08-20 11:17:52Z znek $

#include "SxEvoEnterpriseRenderer.h"
#include "common.h"

@implementation SxEvoEnterpriseRenderer

- (id)renderEntry:(id)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.EML</key>
    <key name="davUid"        >$baseURL$/$pkey$.EML</key>
    <key name="davContentType">text/vcard</key>
    <key name="davDisplayName">$cn$</key>

    <key name="email1addrtype">SMTP</key>
    <key name="email1">$email1$</key>

    <key name="fileas"    >$cn$</key>
    <key name="cn"        >$cn$</key>
    <key name="sn"        >$cn$</key>
    <key name="nickname"  >$nickname$</key>
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
  NSString *cn;
  
  if ((record = [super renderEntry:_entry]) == nil)
    return nil;
  
  cn = [record valueForKey:@"cn"];
  
  /* render some compound names */
    
  // davContentType ?
  if (cn) [record setObject:cn forKey:@"davDisplayName"];
  
  /* enterprise */
  
  if (cn) {
    [record setObject:cn forKey:@"sn"];
    [record setObject:cn forKey:@"o"];
  }

  // cn already present
  [record setObject:@"Enterprise" forKey:@"title"];
  
  /* addresses */
#if 0 // TODO: first need to fix rendering format ...
  if ((tmp = [self renderAddressWithPrefix:@"bill" from:record]))
    [record setObject:tmp forKey:@"workaddress"];
  if ((tmp = [self renderAddressWithPrefix:@"ship" from:record]))
    [record setObject:tmp forKey:@"otherpostaladdress"];
#endif
  return record;
}

@end /* SxEvoEnterpriseRenderer */
