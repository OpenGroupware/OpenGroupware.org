/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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
// $Id: SxPersonFolder.m 1 2004-08-20 11:17:52Z znek $

#include "SxPersonFolder.h"
#include "SxPerson.h"
#include <ZSFrontend/SxRendererFactory.h>
#include <ZSFrontend/SxMapEnumerator.h>
#include <ZSBackend/SxContactManager.h>
#include "common.h"

@implementation SxPersonFolder

/* factory */

- (NSString *)entity {
  return @"Person";
}
- (Class)recordClassForKey:(NSString *)_key {
  if ([_key length] == 0)
    return [super recordClassForKey:_key];

  if (!isdigit([_key characterAtIndex:0])) {
    // TODO: this should query the source_url! (eg "Donald%20Duck.EML")
    [self debugWithFormat:@"tried to lookup non-pkey key '%@'", _key];
    return [super recordClassForKey:_key];
  }
  
  return [SxPerson class];
}

/* rendering */

- (id)renderListEntry:(id)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.vcf?sn=$sn$</key>
    <key name="davContentType">text/vcard</key>
    <key name="davDisplayName">$sn$, $givenname$</key>
  */
  NSMutableDictionary *record;
  NSString *url, *dname;
  NSString *sn, *pkey;
  
  if ((record = [_entry mutableCopy]) == nil)
    return nil;
  
  // getting: pkey, sn, givenname
  sn   = [record objectForKey:@"sn"];
  pkey = [[record objectForKey:@"pkey"] stringValue];
  
  url = [NSString stringWithFormat:@"%@%@.vcf", [self baseURL], pkey];
  if ([sn length] > 0)
    url = [url stringByAppendingFormat:@"?sn=%@", [sn stringByEscapingURL]];
  
  [record setObject:url forKey:@"{DAV:}href"];

  dname = [NSString stringWithFormat:@"%@, %@",
                    sn,
                    [record objectForKey:@"givenname"]];
  [record setObject:dname forKey:@"davDisplayName"];
  return [record autorelease];
}

- (id)evoRendererInContext:(id)_ctx {
  static Class RendererClass = NULL;

  if (RendererClass == NULL) {
    if ((RendererClass = NSClassFromString(@"SxEvoPersonRenderer")) == Nil) {
      [self logWithFormat:@"Evolution support not installed!"];
      return nil;
    }
  }
  return [RendererClass rendererWithFolder:self inContext:_ctx];
}
- (id)zideLookRendererInContext:(id)_ctx {
  static Class RendererClass = NULL;

  if (RendererClass == NULL) {
    if ((RendererClass = NSClassFromString(@"SxZLPersonRenderer")) == Nil) {
      [self logWithFormat:@"ZideLook support not installed!"];
      return nil;
    }
  }
  return [RendererClass rendererWithFolder:self inContext:_ctx];
}

/* queries */

- (SxContactSetIdentifier *)contactSetID {
  if ([[self type] isEqualToString:@"public"])
    return [SxContactSetIdentifier publicPersons];
  if ([[self type] isEqualToString:@"account"])
    return [SxContactSetIdentifier accounts];
  
  return [SxContactSetIdentifier privatePersons];
}

- (id)performWebDAVBulkQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // TODO: this method should check which attributes are actually queried!
  // TODO: would be better to implement performBulkQuery:onGlobalIDs of
  //       SxFolder !
  id       renderer;
  NSArray  *pkeys;
  NSArray  *records;
  unsigned count;

  /* get primary keys */
  
  static Class RendererClass = NULL;

  if (RendererClass == NULL) {
    NSString *className = @"SxZLFullPersonRenderer";
    
    RendererClass = NSClassFromString(className);

    if (RendererClass == NULL) {
      [self logWithFormat:@"try to instantiate '%@'", className];
      return nil;
    }
  }

  if ((pkeys = [self extractBulkPrimaryKeys:_fs]) == nil)
    return nil;
  if ((count = [pkeys count]) == 0)
    return [NSArray array];
  if ([self doExplainQueries])
    [self logWithFormat:@"performing person bulk query on %i keys ...", count];
  
  /* fetch */
#if 0  
  records = [[self contactManagerInContext:_ctx]
                   fullPersonInfosForPrimaryKeys:pkeys];
#else
  records = [[self contactManagerInContext:_ctx]
                   fullObjectInfosForPrimaryKeys:pkeys
                   withSetIdentifier:[self contactSetID]];
#endif
  if ((count = [records count]) == 0)
    return [NSArray array];
  
  /* render to WebDAV */
  
#if 1 /* enable if the full renderer is fixed regarding the URL */
  renderer = [RendererClass rendererWithContext:_ctx
                                     baseURL:[self baseURL]];
  return [SxMapEnumerator enumeratorWithSource:[records objectEnumerator]
			  object:renderer selector:@selector(renderEntry:)];
#else
  {
    NSMutableArray *davEntries;
    unsigned       i;
    
#warning fix person full renderer to remove this junk
    davEntries = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
      NSString *url;
      id pkey;
      id record;
    
      record = [records objectAtIndex:i];
      if ((pkey = [record valueForKey:@"pkey"]) == nil) {
        [self logWithFormat:@"missing primary key in record: %@", record];
        continue;
      }
      pkey = [pkey stringValue];
    
      url = [[self baseURL] stringByAppendingString:pkey];
    
      renderer = [[SxZLFullPersonRenderer alloc] initWithContext:_ctx
                                                 baseURL:url];
      record = [renderer renderEntry:record];
      [renderer release];
    
      if (record == nil)
        continue;
    
      [davEntries addObject:record];
    }
    return davEntries;
  }
#endif
}

@end /* SxPersonFolder */
