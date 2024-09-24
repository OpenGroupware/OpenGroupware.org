/*
  Copyright (C) 2002-2005 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "SxFolder.h"
#include <NGObjWeb/SoObjectResultEntry.h>
#include "mapiflags.h"
#include "common.h"

@implementation SxFolder(ZL)

/* common CDO attributes */

- (int)cdoContentUnread {
  return 0;
}
- (int)unreadcount {
  return [self cdoContentUnread];
}

- (int)cdoContentCount {
  // TODO: perform (a cached !) query using the backend
  [self logWithFormat:@"should deliver content-count ..."];
  return 10000;
}

- (int)cdoDisplayType {
  return 0;
}

- (int)cdoAccessLevel {
  return 1; /* TODO: don't know what this means :-( */
}

- (id)cdoAccess {
  // TODO: use proxy to find out, how we are supposed to format the number
  unsigned int permissionMask = 0;

  static NSDictionary *typing = nil;
  if (typing == nil) {
    typing = [[NSDictionary alloc] 
	       initWithObjectsAndKeys:
		 @"int", 
	         @"{urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/}dt",
	       nil];
  }
  
  permissionMask = 0;
  
  if ([self isReadAllowed])         
    permissionMask |= MAPI_ACCESS_READ; // 0x02
  if ([self isModificationAllowed]) 
    permissionMask |= MAPI_ACCESS_MODIFY; // 0x01
  if ([self isItemCreationAllowed]) 
    permissionMask |= MAPI_ACCESS_CREATE_CONTENTS;  // 0x10
  if ([self isFolderCreationAllowed]) 
    permissionMask |= MAPI_ACCESS_CREATE_HIERARCHY; // 0x08
  if ([self isDeletionAllowed])
    permissionMask |= MAPI_ACCESS_DELETE; // 0x04
  
  permissionMask |= 0x00000020; // always add leading (create assoc?)
  
  // found out why 63:
  // 63  - 111111
  // x01 - 000001 - modify
  // x02 - 000010 - read
  // x04 - 000100 - delete
  // x08 - 001000 - create hier
  // x10 - 010000 - create item
  // x20 - 100000 - ? (create associated ?)
  // permissionMask = 63; // 0x3F
  
  return [SoWebDAVValue valueForObject:[NSNumber numberWithInt:permissionMask]
			attributes:typing];
}

- (int)cdoContainerContents {
  return 1; /* TODO: don't know what this means :-( */
}

- (int)cdoFolderTypeCode {
  return 1; /* TODO: don't know what this means :-( */
}

- (BOOL)showHomePageURL {
  return NO;
}

- (NSString *)homePageURL {
  return @"http://www.skyrix.de/";
}

- (id)encodedHomePageURL {
  return [[self homePageURL] asEncodedHomePageURL:[self showHomePageURL]];
}

/* folder version */

- (int)refreshInterval {
  static int ref = -1;
  if (ref == -1) {
    ref = [[[NSUserDefaults standardUserDefaults] 
             objectForKey:@"ZLFolderRefresh"] intValue];
  }
  return ref > 0 ? ref : 300; /* every five minutes */
}

- (int)zlGenerationCount {
  /* 
     This is used by ZideLook to track folder changes.
     TODO: implement folder-change detection ... (snapshot of last
     id/version set contained in the folder)
  */
  return (time(NULL) - 1047000000) / [self refreshInterval];
}

/* query detection */

- (id)performSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the third query by ZideLook, get all subfolder infos */
  /*
    davDisplayName,davResourceType,cdoDepth,cdoParentDisplay,cdoRowType,
    cdoAccess,cdoContainerClass,cdoContainerHierachy,cdoContainerContents,
    cdoDisplayType,outlookFolderClass
  */
  static Class entryClass = Nil;
  NSArray        *names;
  NSMutableArray *objects;
  NSArray        *queriedAttrNames;
  unsigned i, count;
  
  if (entryClass == Nil) 
    entryClass = NGClassFromString(@"SoObjectResultEntry");
  if ([self doExplainQueries]) {
    [self logWithFormat:@"ZL Subfolder Query [depth=%@]: %@",
            [[(WOContext *)_ctx request] headerForKey:@"depth"],
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  
  if ((names = (id)[self davChildKeysInContext:_ctx]) == nil) {
    [self logWithFormat:@"%s: missing names for fs %@",
          __PRETTY_FUNCTION__, _fs];
    return [NSArray array];
  }

  names = [[[NSArray alloc] 
             initWithObjectsFromEnumerator:(id)names] autorelease];
  if ((count = [names count]) == 0)
    return [NSArray array];
  
  if ([self doExplainQueries]) {
    [self logWithFormat:@"  deliver objects for davChildKeys: %@", 
	    [names componentsJoinedByString:@","]];
  }
  
  queriedAttrNames = [_fs selectedWebDAVPropertyNames];
  objects = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *name, *url;
    id child, rec;
    
    name  = [names objectAtIndex:i];
    child = [self lookupName:name inContext:_ctx acquire:NO];

    if (child == nil)             continue;
    if (![child davIsCollection]) continue;
    
    url = [child baseURLInContext:_ctx];
    rec = (queriedAttrNames == nil)
      ? child
      : (id)[child valuesForKeys:queriedAttrNames];
    rec = [[entryClass alloc] initWithURI:url object:child values:rec];
    [objects addObject:rec];
    [rec release];
  }
  return objects;
}

/* range queries */

- (id)lookupRangeQueryFolder:(NSString *)_name inContext:(id)_ctx {
  // This method should be deprecated, the SoWebDAVDispatcher catches
  // the _range_ query, turns it into a WebDAV bulk-query and patches the 
  // URI of the request
  NSString *s;
  NSArray  *ids;
  
  s   = [_name substringFromIndex:7];
  ids = [s componentsSeparatedByString:@"_"];
  
  // TODO: translate this into a BPROPFIND !
  
  [self logWithFormat:
          @"process range query (this method should not be called anymore !): "
          @"%@: %@", _name, ids];
  return nil;
}

@end /* SxFolder(ZL) */
