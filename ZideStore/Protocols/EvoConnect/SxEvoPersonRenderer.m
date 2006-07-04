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

#include "SxEvoPersonRenderer.h"
#include "common.h"

@implementation SxEvoPersonRenderer

- (id)renderEntry:(id)_entry {
  NSMutableDictionary *record;
  NSString *sn, *givenname, *fullname, *middlename;
  NSString *pkey, *dname;
  NSString *title, *affix;
  id tmp;
  
  if ((record = [super renderEntry:_entry]) == nil)
    return nil;

  pkey       = [[record valueForKey:@"pkey"] stringValue];
  sn         = [record valueForKey:@"sn"];
  givenname  = [record valueForKey:@"givenname"];
  middlename = ((tmp = [record valueForKey:@"middlename"]) != nil) 
    ? tmp : (id)@"";
  title      = ((tmp = [record valueForKey:@"nametitle"]) != nil)  
    ? tmp : (id)@"";
  affix      = ((tmp = [record valueForKey:@"nameaffix"]) != nil)  
    ? tmp : (id)@"";

  /* render some compound names */

  if ([sn length] == 0) {
    dname    = givenname;
    fullname = givenname;
  }
  else if ([givenname length] == 0) {
    dname    = sn;
    fullname = sn;
  }
  else {
    dname    = [NSString stringWithFormat:@"%@, %@", sn, givenname];

    fullname = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",
                         title, [title length] ? @" " : @"", 
                         givenname, [givenname length] ? @" " : @"", 
                         middlename, [middlename length] ? @" " : @"", 
                         sn, [sn length] ? @" " : @"", 
                         affix];
  }
  
  if (dname == nil) 
    dname = [NSString stringWithFormat:@"noname<%@>", pkey];
  if (fullname == nil) 
    fullname = dname;
  
  // davContentType ?
  if (dname) [record setObject:dname forKey:@"davDisplayName"];

  if (fullname) {
    [record setObject:fullname forKey:@"cn"];
  }
    
  /* person */

  if ((tmp = [record valueForKey:@"fileas"]) == nil) 
    [record setObject:fullname forKey:@"fileas"];

  // already present attributes:
  // - sn, nickname, bday, department, roomnumber, profession,
  // - manager, secretarycn, spousecn, weddinganiversary
  
  if ((tmp = [record valueForKey:@"givenname"]))
    [record setObject:tmp forKey:@"givenName"];
  if ((tmp = [record valueForKey:@"middlename"]))
    [record setObject:tmp forKey:@"middleName"];

  // TODO bs: name suffix is not working yet
  if ((tmp = [record valueForKey:@"namesuffix"]))
    [record setObject:tmp forKey:@"namesuffix"];
  
  // bday and weddinganiversary have to be re-formatted to match
  // the evolution format
  if ((tmp = [record valueForKey:@"bday"]))
    [record setObject:[tmp exDavDateValue] forKey:@"bday"];
  if ((tmp = [record valueForKey:@"weddinganniversary"]))
    [record setObject:[tmp exDavDateValue] forKey:@"weddinganniversary"];
  
  if ((tmp = [record valueForKey:@"associatedcompany"]))
    [record setObject:tmp forKey:@"o"];
  
  if ((tmp = [record valueForKey:@"jobtitle"]))
    [record setObject:tmp forKey:@"title"];

  /* phones */
  if ((tmp = [record valueForKey:@"tel01"]))
    [record setObject:tmp forKey:@"telephoneNumber"];
  if ((tmp = [record valueForKey:@"tel03"]))
    [record setObject:tmp forKey:@"mobile"];
  if ((tmp = [record valueForKey:@"tel05"]))
    [record setObject:tmp forKey:@"homePhone"];
  if ((tmp = [record valueForKey:@"tel10"]))
    [record setObject:tmp forKey:@"facsimiletelephonenumber"];
  
  /* addresses */
  if ((tmp = [self renderAddressWithPrefix:@"loc" from:record]))
    [record setObject:tmp forKey:@"workaddress"];
  if ((tmp = [self renderAddressWithPrefix:@"mail" from:record]))
    [record setObject:tmp forKey:@"otherpostaladdress"];
  if ((tmp = [self renderAddressWithPrefix:@"priv" from:record]))
    [record setObject:tmp forKey:@"homepostaladdress"];

  return [self postProcessRecord:record];
}

@end /* SxEvoPersonRenderer */
