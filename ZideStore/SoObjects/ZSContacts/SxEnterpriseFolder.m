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

#include "SxEnterpriseFolder.h"
#include "SxEnterprise.h"
#include "common.h"
#include <ZSBackend/SxContactManager.h>
#include <ZSFrontend/SxRendererFactory.h>
#include <ZSFrontend/SxMapEnumerator.h>

@implementation SxEnterpriseFolder

/* factory */

- (NSString *)entity {
  return @"Enterprise";
}

- (Class)recordClassForKey:(NSString *)_key {
  return [SxEnterprise class];
}

/* rendering */

- (id)evoRendererInContext:(id)_ctx {
  static Class EvoRenderer = Nil;
  if (EvoRenderer == Nil) {
    if ((EvoRenderer = NSClassFromString(@"SxEvoEnterpriseRenderer")) == nil) {
      static BOOL didLog = NO;
      if (!didLog) {
	[self logWithFormat:@"Note: no Evolution support installed!"];
	didLog = YES;
      }
    }
  }
  return [EvoRenderer rendererWithFolder:self inContext:_ctx];
}
- (id)zideLookRendererInContext:(id)_ctx {
  /* TODO: move to ZideLook bundle */
  static Class RendererClass = Nil;
  static BOOL didInit = NO;
  
  if (!didInit) {
    NSString *className = @"SxZLEnterpriseRenderer";
    didInit = YES;
    
    if ((RendererClass = NSClassFromString(className)) == Nil) {
      [self logWithFormat:@"ERROR: did not find class '%@'!", className];
      return nil;
    }
  }
  return [RendererClass rendererWithFolder:self inContext:_ctx];
}

- (id)renderListEntry:(id)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  // TODO: move to a renderer class
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.vcf?sn=$sn$</key>
    <key name="davContentType">text/vcard</key>
    <key name="davDisplayName">$sn$, $givenname$</key>
  */
  NSMutableDictionary *record;
  NSString *url, *cn, *pkey;
  id tmp;
  
  if ((record = [[_entry mutableCopy] autorelease]) == nil)
    return nil;
  
  // getting: pkey, sn, givenname
  if ((pkey = [[record valueForKey:@"pkey"] stringValue]) == nil)
    return nil;
  
  cn  = [record valueForKey:@"cn"];
  url = [NSString stringWithFormat:@"%@%@.vcf", [self baseURL], pkey];
  if ([cn length] > 0)
    url = [url stringByAppendingFormat:@"?cn=%@", [cn stringByEscapingURL]];
  
  [record setObject:url forKey:@"{DAV:}href"];
  [record setObject:cn?cn:pkey forKey:@"davDisplayName"];

  /* render etag */
  
  if ([(tmp = [record objectForKey:@"version"]) isNotNull]) {
    tmp = [@":" stringByAppendingString:[tmp stringValue]];
    tmp = [pkey stringByAppendingString:tmp];
    [record setObject:tmp forKey:@"davEntityTag"];
  }
  
  return record;
}

/* queries */

- (SxContactSetIdentifier *)contactSetID {
  return [[self type] isEqualToString:@"public"]
    ? [SxContactSetIdentifier publicEnterprises]
    : [SxContactSetIdentifier privateEnterprises];
}

- (Class)fullEnterpriseRendererClass {
  static Class RendererClass = NULL;
  static BOOL didInit = NO;
  
  if (!didInit) {
    NSString *className = @"SxZLFullEnterpriseRenderer";
    didInit = YES;
    
    if ((RendererClass = NSClassFromString(className)) == Nil)
      [self logWithFormat:@"ERROR: did not find renderer: '%@'", className];
  }
  return RendererClass;
}

- (id)performWebDAVBulkQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // TODO: this method should check which attributes are actually queried!
  // TODO: would be better to implement performBulkQuery:onGlobalIDs of
  //       SxFolder!
  id       renderer;
  NSArray  *pkeys;
  NSArray  *records;
  unsigned count;

  /* get primary keys */
  
  if ((pkeys = [self extractBulkPrimaryKeys:_fs]) == nil)
    return nil;
  if ((count = [pkeys count]) == 0)
    return [NSArray array];
  if ([self doExplainQueries])
    [self logWithFormat:@"performing enterprise bulk query on %i keys ...",
          count];

  /* fetch */

  records = [[self contactManagerInContext:_ctx]
                   fullObjectInfosForPrimaryKeys:pkeys
                   withSetIdentifier:[self contactSetID]];
#if 0 /* old code */
  records = [[self contactManagerInContext:_ctx]
                   fullEnterpriseInfosForPrimaryKeys:pkeys];
#endif

  if ((count = [records count]) == 0)
    return [NSArray array];
  
  /* render to WebDAV */

  /* TODO: check whether the full renderer is fixed regarding the URL */
  renderer = [self fullEnterpriseRendererClass];
  renderer = [renderer rendererWithContext:_ctx baseURL:[self baseURL]];
  return [SxMapEnumerator enumeratorWithSource:[records objectEnumerator]
			  object:renderer selector:@selector(renderEntry:)];
}

@end /* SxEnterpriseFolder */
