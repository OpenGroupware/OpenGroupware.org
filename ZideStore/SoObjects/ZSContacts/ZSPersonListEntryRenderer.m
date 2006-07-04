/*
  Copyright (C) 2004 Helge Hess

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

#include "ZSPersonListEntryRenderer.h"
#include "common.h"

@implementation ZSPersonListEntryRenderer

static id sharedRenderer = nil; // THREAD

+ (id)sharedListEntryRenderer {
  if (sharedRenderer == nil)
    sharedRenderer = [[self alloc] init];
  return sharedRenderer;
}

/* rendering */

- (id)renderEntry:(id)_entry representingSoObject:(id)_object {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.vcf?sn=$sn$</key>
    <key name="davContentType">text/x-vcard</key>
    <key name="davDisplayName">$sn$, $givenname$</key>
  */
  NSMutableDictionary *record;
  NSString *url, *dname;
  NSString *sn, *gn, *pkey;
  id tmp;
  
  if ((record = [[_entry mutableCopy] autorelease]) == nil)
    return nil;

  // [self logWithFormat:@"RENDER: %@", record];
  
  // getting: pkey, sn, givenname
  sn   = [record objectForKey:@"sn"];
  gn   = [record objectForKey:@"givenname"];
  gn   = [gn isNotEmpty] ? gn : (NSString *)nil;
  sn   = [sn isNotEmpty] ? sn : (NSString *)nil;
  pkey = [[record objectForKey:@"pkey"] stringValue];
  
  /* get URL */
  
  // TODO: do not use formats
  url = [NSString stringWithFormat:@"%@%@.vcf", [_object baseURL], pkey];
  if ([sn length] > 0) {
    // TODO: this should be filtered based on the UA
    url = [url stringByAppendingFormat:@"?sn=%@", [sn stringByEscapingURL]];
  }
  
  [record setObject:url forKey:@"{DAV:}href"];
  [record setObject:@"text/x-vcard; charset='utf-8'" forKey:@"davContentType"];
  
  /* render display name */
  
  if (gn != nil && sn != nil)
    dname = [[sn stringByAppendingString:@", "] stringByAppendingString:gn];
  else
    dname = gn != nil ? gn : sn;
  
  if (dname != nil)
    [record setObject:dname forKey:@"davDisplayName"];

  /* render etag */
  
  if ([(tmp = [record objectForKey:@"version"]) isNotNull]) {
    tmp = [@":" stringByAppendingString:[tmp stringValue]];
    tmp = [pkey stringByAppendingString:tmp];
    [record setObject:tmp forKey:@"davEntityTag"];
  }
  
  return record;
}

@end /* ZSPersonListEntryRenderer */
