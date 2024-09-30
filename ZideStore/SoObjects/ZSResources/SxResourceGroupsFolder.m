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

#include "SxResourceGroupsFolder.h"
#include "SxResource.h"
#include <ZSFrontend/SxRendererFactory.h>
#include <ZSFrontend/SxMapEnumerator.h>
#include "common.h"

@implementation SxResourceGroupsFolder

/* accessors */

- (NSString *)entity {
  return @"Resource";
}

/* factory */

- (Class)recordClassForKey:(NSString *)_key {
  return [SxResource class];
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  return nil;
}

#if 0
- (Class)evoMapEnumeratorClass {
  return NGClassFromString(@"EvoGroupEnumerator");
}
#endif

- (BOOL)davHasSubFolders {
  /* Note: we just claim that, there might be no resource groups */
  return YES;
}

#if 0
- (NSEnumerator *)davChildKeysInContext:(id)_ctx {
  NSEnumerator *e;
  id groups;
  
  if ((e = [[self contactManagerInContext:_ctx] listGroups]) == nil)
    return nil;
  
  // cn
  groups = [[[NSArray alloc] initWithObjectsFromEnumerator:e] autorelease];
  groups = [groups valueForKey:@"cn"];
  
  return [groups objectEnumerator];
}
#endif

/* rendering */

#if 0
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
  cn   = [record objectForKey:@"cn"];
  pkey = [[record objectForKey:@"pkey"] stringValue];
  
  url = [NSString stringWithFormat:@"%@%@.vcf", [self baseURL], pkey];
  if ([cn length] > 0)
    url = [url stringByAppendingFormat:@"?cn=%@", [cn stringByEscapingURL]];
  
  [record setObject:url forKey:@"{DAV:}href"];
  [record setObject:cn forKey:@"davDisplayName"];
  
  /* render etag */
  
  if ([(tmp = [record objectForKey:@"version"]) isNotNull]) {
    tmp = [@":" stringByAppendingString:[tmp stringValue]];
    tmp = [pkey stringByAppendingString:tmp];
    [record setObject:tmp forKey:@"davEntityTag"];
  }

  return record;
}

- (id)renderDirListEntry:(id)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  NSMutableDictionary *record;
  NSString *url, *cn;
  
  if ((record = [_entry mutableCopy]) == nil)
    return nil;
  
  // getting: pkey, sn, givenname
  cn   = [record objectForKey:@"cn"];
  if (cn == nil)
    cn = [[record objectForKey:@"pkey"] stringValue];
  
  url = [[NSString alloc] initWithFormat:@"%@%@", [self baseURL], cn];
  [record setObject:url  forKey:@"{DAV:}href"];
  [url release];
  
  [record setObject:cn   forKey:@"davDisplayName"];
  [record setObject:@"collection" forKey:@"davResourceType"];
  return [record autorelease];
}

- (id)evoRendererInContext:(id)_ctx {
  static Class RendererClass = NULL;
  
  if (RendererClass == NULL) {
    if ((RendererClass = NGClassFromString(@"SxEvoGroupRenderer")) == Nil) {
      static BOOL didLog = NO;
      if (!didLog) {
	[self logWithFormat:@"no Evolution support installed"];
	didLog = YES;
      }
      return nil;
    }
  }
  return [RendererClass rendererWithFolder:self inContext:_ctx];
}
- (id)zideLookRendererInContext:(id)_ctx {
  static Class RendererClass = NULL;
  
  if (RendererClass == NULL) {
    if ((RendererClass = NGClassFromString(@"SxZLGroupRenderer")) == Nil) {
      static BOOL didLog = NO;
      if (!didLog) {
	[self logWithFormat:@"no ZideLook support installed"];
	didLog = YES;
      }
      return nil;
    }
  }
  return [RendererClass rendererWithFolder:self inContext:_ctx];
}

- (id)performListQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // TODO: add groups
  SxContactManager *cm;
  NSEnumerator   *e = nil;
  NSArray        *groups;
  NSMutableArray *ma;
  id tmp;
  
  /* fetch groups */
  
  cm = [self contactManagerInContext:_ctx];

  if ((e = [cm listGroups]) == nil) {
    [self logWithFormat:@"got no groups ..."];
    return nil;
  }
  groups = [[NSArray alloc] initWithObjectsFromEnumerator:e];
  
  /* add groups as files */
  
  e = [groups objectEnumerator];
  e = [SxMapEnumerator enumeratorWithSource:e 
                       object:self 
                       selector:@selector(renderListEntry:)];
  ma = [[NSMutableArray alloc] initWithObjectsFromEnumerator:e];
  
  /* add groups as folders */
  
  e = [groups objectEnumerator];
  e = [SxMapEnumerator enumeratorWithSource:e 
                       object:self 
                       selector:@selector(renderDirListEntry:)];
  while ((tmp = [e nextObject]))
    [ma addObject:tmp];
  
  e = [ma objectEnumerator];
  [ma     release];
  [groups release];
  return e;
}
#endif

/* name lookup */

- (id)iCalendarForGroup:(NSString *)_name inContext:(id)_ctx {
  /* support direct queries to the contained calendar */
  id folder;
  
  if ([_name hasSuffix:@".ics"])
    _name = [_name substringToIndex:[_name length] - 4];
    
  if ((folder = [self groupFolder:_name inContext:_ctx]) == nil)
    return nil;
    
  // TODO: hardcoded name ...
  folder = [folder lookupName:@"Calendar" inContext:_ctx acquire:NO];
  if (folder == nil) {
    [self logWithFormat:@"Note: did not find Calendar folder for team: %@",
	    _name];
    return nil;
  }
  
  /* lookup iCalendar object */
  return [folder lookupName:@"ics" inContext:_ctx acquire:NO];
}

- (id)groupFolder:(NSString *)_name inContext:(id)_ctx {
  id folder;
  
  if ([_name hasSuffix:@".ics"])
    return [self iCalendarForGroup:_name inContext:_ctx];
  
  folder = [[NGClassFromString(@"SxResourceGroupFolder") alloc] 
             initWithName:_name inContainer:self];
  return [folder autorelease];
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  if ([_key length] == 0) return nil;
  
  if (isdigit([_key characterAtIndex:0]))
    return [super lookupName:_key inContext:_ctx acquire:_flag];
  
  if ([_key isEqualToString:@"getIDsAndVersions"])
    return [self getIDsAndVersionsAction:_ctx];
  
  if ([_key rangeOfString:@"_"].length > 0) {
    // mh: ZideLook turns spaces into '_' (bug 1233 in bugzilla)
    NSString *ua;
    
    ua = [[(WOContext *)_ctx request] headerForKey:@"user-agent"];
    if ([ua rangeOfString:@"ZIDEStore"].length > 0) {
      _key = [[_key componentsSeparatedByString:@"_"]
                    componentsJoinedByString:@" "];
      [self logWithFormat:@"WARNING: replaced '_' in key with ' ': %@", _key];
    }
  }
  return [self groupFolder:_key inContext:_ctx];
}

/* queries */

#if 0
- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the second query by ZideLook, get basic message infos */
  /* davDisplayName,davResourceType,outlookMessageClass,cdoDisplayType */
  if ([self doExplainQueries]) {
    [self logWithFormat:@"ZL Groups Messages Query [depth=%@]: %@",
	    [[(WOContext *)_ctx request] headerForKey:@"depth"],
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  
  /* TODO: check whether the following is correct ? */
  // probably at least the outlookMessageClass is broken ...
  return [[self contactManagerInContext:_ctx] evoGroupsWithPrefix:nil];
}

static int compareGroupRecords(id obj1, id obj2, void *ctx) {
  NSString *n1, *n2;
  n1 = [obj1 valueForKey:@"davDisplayName"];
  n2 = [obj2 valueForKey:@"davDisplayName"];
  return [n1 caseInsensitiveCompare:n2];
}
#endif

- (NSString *)contactFolderClass {
  return @"IPF.Contact";
}

#if 0
- (id)performEvoSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // outlookFolderClass, unreadcount, davDisplayName, davHasSubFolders
  // TODO
  NSMutableArray *a;
  NSEnumerator   *e;
  NSString       *folderURL;
  NSDictionary   *object;
  NSArray        *deniedGroups;

  deniedGroups = [[[self commandContextInContext:_ctx] userDefaults]
                         arrayForKey:@"ZLGroupSelection"];
  
  folderURL    = [self baseURLInContext:_ctx];
  if (![folderURL hasSuffix:@"/"])
    folderURL = [folderURL stringByAppendingString:@"/"];
  
  if ((e = [[self contactManagerInContext:_ctx] listGroups]) == nil)
    return nil;
  
  a = [NSMutableArray arrayWithCapacity:16];
  while ((object = [e nextObject])) {
    NSDictionary *record;
    NSString *name, *url;
    
    name = [object valueForKey:@"cn"];
    if ([self omitAllIntranet]) {
      if ([name isEqualToString:@"all intranet"])
	continue;
    }
    if ([deniedGroups containsObject:name])
      continue;
    
    // TODO: extension
    url = [folderURL stringByAppendingString:name];
    
    record = [[NSDictionary alloc] initWithObjectsAndKeys:
				     url,  @"{DAV:}href",
				     name, @"davDisplayName",
				     @"0", @"unreadcount",
				     @"1", @"davHasSubFolders",
				     [self contactFolderClass], 
                                     @"outlookFolderClass",
				     nil];
    [a addObject:record];
    [record release];
  }
  [a sortUsingFunction:compareGroupRecords context:self];
  return [a objectEnumerator];
}

- (id)performSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the third query by ZideLook, get all subfolder infos */
  /*
    davDisplayName,davResourceType,cdoDepth,cdoParentDisplay,cdoRowType,
    cdoAccess,cdoContainerClass,cdoContainerHierachy,cdoContainerContents,
    davDisplayName,cdoDisplayType,outlookFolderClass
  */
  // TODO
  NSMutableArray *a;
  NSEnumerator   *e;
  NSString       *folderURL;
  NSDictionary   *object;
  NSArray        *deniedGroups;

  deniedGroups = [[[self commandContextInContext:_ctx]
                         userDefaults] arrayForKey:@"ZLGroupSelection"];
  folderURL    = [self baseURLInContext:_ctx];
  
  if (![folderURL hasSuffix:@"/"])
    folderURL = [folderURL stringByAppendingString:@"/"];
  
  if ((e = [[self contactManagerInContext:_ctx] listGroups]) == nil)
    return nil;
  
  a = [NSMutableArray arrayWithCapacity:16];
  while ((object = [e nextObject])) {
    NSDictionary *record;
    NSString *name, *url;
    id access;
    NSString *keys[12];
    id  vals[12];
    int p;
    
    name = [object valueForKey:@"cn"];
    if ([self omitAllIntranet]) {
      if ([name isEqualToString:@"all intranet"])
	continue;
    }
    if ([deniedGroups containsObject:name])
      continue;
    
    // TODO: extension
    url = [folderURL stringByAppendingString:name];
    
    access = [self cdoAccess]; // TODO: use flags of target ...
    
    // TODO:
    // row-type, containerclass,container-contents,display-type,foldertype
    
    p = 0;
    keys[p] = @"{DAV:}href";         vals[p] = url;            p++;
    keys[p] = @"davDisplayName";     vals[p] = name;           p++;
    keys[p] = @"davResourceType";    vals[p] = @"collection";  p++;
    keys[p] = @"{DAV:}resourcetype"; vals[p] = @"collection";  p++;
    keys[p] = @"cdoAccess";          vals[p] = access;         p++;
    keys[p] = @"outlookFolderClass"; vals[p] = [self contactFolderClass]; p++;
    
    // evo
    keys[p] = @"unreadcount";        vals[p] = @"0"; p++;
    keys[p] = @"davHasSubFolders";   vals[p] = @"1"; p++;
    keys[p] = @"outlookFolderClass"; vals[p] = [self contactFolderClass]; p++;
    
    // zidelook
    keys[p] = @"cdoContentCount"; vals[p] = @"0"; p++;
    
    record = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
    [a addObject:record];
    [record release];
  }
  [a sortUsingFunction:compareGroupRecords context:self];
  return [a objectEnumerator];
}
#endif

@end /* SxResourceGroupsFolder */
