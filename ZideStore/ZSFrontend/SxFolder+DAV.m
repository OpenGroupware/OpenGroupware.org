/*
  Copyright (C) 2002-2006 SKYRIX Software AG
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
#include "SxObject.h"
#include "OLDavPropMapper.h"
#include <Main/SxAuthenticator.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include <NGObjWeb/SoObjectResultEntry.h>
#include "mapiflags.h"
#include "common.h"

@implementation SxFolder(WebDAV)

/* common DAV attributes */

- (NSString *)davDisplayName {
  /* TODO: maybe display: lastname, firstname ? */
  return [self nameInContainer];
}
- (BOOL)davIsCollection {
  return YES;
}
- (BOOL)davIsFolder {
  /* this can be overridden by compound documents (aka filewrappers) */
  return [self davIsCollection];
}
- (BOOL)davHasSubFolders {
  return NO;
}

- (NSString *)davCollectionTag {
  NSString           *entityName, *ctag;
  LSCommandContext   *ctx;

  entityName = [[self class] entityName];
  ctx = [self commandContextInContext:[[WOApplication application] context]];
  ctag = nil;
  if ([entityName isNotNull])
  {
    ctag = [ctx runCommand:@"system::get-entity-ctag", 
                           @"entity", entityName, 
                           nil];
  }
  return ctag;
}

- (NSString *)davContentClass {
  NSString *fc = [self outlookFolderClass];
  
  if ([fc isEqualToString:@"IPF.Contact"])
    // TODO: should return "urn:content-classes:contactfolder" ?!
    return @"urn:content-classes:person";
  
  if ([fc isEqualToString:@"IPF.Task"])
    return @"urn:content-classes:taskfolder";
  
  if ([fc isEqualToString:@"IPF.Appointment"])
    // TODO: is this correct, the content class is "calendarfolder" ??
    //       I think it's correct
    return @"urn:content-classes:calendarfolder";
  
  if ([fc isEqualToString:@"IPF.Note"])
    return @"urn:content-classes:mailfolder";
  
  if ([fc isEqualToString:@"IPF.Journal"])
    return @"urn:content-classes:journalfolder";
  
  return @"urn:content-classes:mailfolder";
}

- (NSArray *)extractBulkPrimaryKeys:(EOFetchSpecification *)_fs {
  NSMutableArray *pkeys;
  NSArray  *davKeys;
  unsigned i, count;
  
  davKeys = [_fs davBulkTargetKeys];
  if ((count = [davKeys count]) == 0)
    return [NSArray array];
  
  pkeys = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *davKey = [davKeys objectAtIndex:i];
    int pkeyInt;
    
    if ([davKey rangeOfString:@"/"].length > 0) {
      [self errorWithFormat:
              @"cannot process complex bulk key: '%@'", davKey];
      continue;
    }
    
    if ((pkeyInt = [davKey intValue]) == 0) {
      [self errorWithFormat:
              @"could not process non-int key: '%@'", davKey];
      continue;
    }
    else if (pkeyInt < 8000)
      [self warnWithFormat:
              @"got weird bulk-key (<8000): '%@'", davKey];
    
    // TODO
    [pkeys addObject:[NSNumber numberWithInt:pkeyInt]];
  }
  return pkeys;
}

- (NSArray *)extractBulkGlobalIDs:(EOFetchSpecification *)_fs {
  /* first, morph query URLs into EOGlobalIDs ... */
  NSMutableArray *pkeys;
  NSArray  *davKeys;
  unsigned i, count;
  NSString *entityName;
  
  davKeys = [_fs davBulkTargetKeys];
  if ((count = [davKeys count]) == 0)
    return [NSArray array];
  
  entityName = [[self class] entityName];
  pkeys = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *davKey = [davKeys objectAtIndex:i];
    EOKeyGlobalID *gid;
    NSNumber *pkey;
    int      pkeyInt;
    
    davKey = [[davKeys objectAtIndex:i] stringByDeletingPathExtension];
    if ([davKey rangeOfString:@"/"].length > 0) {
      [self errorWithFormat:@"cannot process complex bulk key: '%@'", davKey];
      continue;
    }
    
    if ((pkeyInt = [davKey intValue]) == 0) {
      [self errorWithFormat:@"could not process non-int key: '%@'", davKey];
      continue;
    }
    else if (pkeyInt < 8000)
      [self warnWithFormat:@"got weird bulk-key (<8000): '%@'", davKey];
    
    pkey = [NSNumber numberWithInt:pkeyInt];
    gid  = [EOKeyGlobalID globalIDWithEntityName:entityName 
			  keys:&pkey keyCount:1 zone:NULL];
    [pkeys addObject:gid];
  }
  return pkeys;
}

- (NSArray *)davURLRecordsForChildGIDs:(NSArray *)_gids inContext:(id)_ctx {
  /* 
     Transform a set of child GIDs into records contained davURL and
     {DAV:}href
  */
  NSMutableArray *results;
  NSString       *folderURL, *ext;
  int i, count;

  if (_gids == nil) return nil;
  if ((count = [_gids count]) == 0) return [NSArray array];
  
  folderURL = [self baseURLInContext:_ctx];
  if (![folderURL hasSuffix:@"/"])
    folderURL = [folderURL stringByAppendingString:@"/"];
  ext = [self fileExtensionForChildrenInContext:_ctx];
  
  results = [NSMutableArray arrayWithCapacity:(count + 1)];
  for (i = 0; i < count; i++) {
    EOKeyGlobalID *gid;
    NSDictionary *values;
    NSString *entryName, *url;
    
    /* determine global-id */
    
    gid = [_gids objectAtIndex:i];
    if (![gid isNotNull]) continue;

    /* morph global-id to URL */
    
    entryName = [[gid keyValues][0] stringValue];
    if (ext) {
      entryName = [entryName stringByAppendingString:@"."];
      entryName = [entryName stringByAppendingString:ext];
    }
    entryName = [entryName stringByEscapingURL];
    url = [folderURL stringByAppendingString:entryName];
    if (url == nil) {
      [self logWithFormat:@"could not process global-id: %@", gid];
      continue;
    }
    
    /* create entry */
    values = [[NSDictionary alloc] initWithObjectsAndKeys:
				     url, @"davURL", 
				     url, @"{DAV:}href",
				   nil];
    [results addObject:values];
    [values release];
  }
  return results;
}

/* WebDAV operations */

- (id)davCreateObject:(NSString *)_name properties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  id child;
  
  if ((child = [self childForNewKey:_name inContext:_ctx]))
    return [child davCreateObject:_name properties:_props inContext:_ctx];
  
  [self logWithFormat:@"CREATE (no child for new key): %@: %@", _name,_props];
  
  return [NSException exceptionWithHTTPStatus:501 /* not implemented */
		      reason:@"object creation not available on this object"];
}

- (NSException *)davSetProperties:(NSDictionary *)_setProps
  removePropertiesNamed:(NSArray *)_delProps 
  inContext:(id)_ctx
{
  static NSString *remKeys[] = {
    /* remove "unpatchable" or unnecessary properties */
    @"cdoAccess",       @"cdoAccessLevel",      @"cdoAssocContentCount",
    @"cdoContentCount", @"cdoContentUnread",    @"cdoFolderTypeCode",
    @"cdoStatus",       @"cdoStoreSupportMask", @"cdoSubFolders",
    @"davDisplayName",  @"outlookFolderClass",  @"davHasSubFolders",
    @"unreadcount",
    /* special props of root */
    @"calendarFolderURL", @"contactsFolderURL", @"draftsFolderURL",
    @"inboxFolderURL",    @"journalFolderURL",  @"messageFolderRoot",
    @"msgSendURL",        @"outboxFolderURL",   @"sentFolderURL",
    @"taskFolderURL",     @"trashFolderURL",
    /* more */
    @"mapi0x36E2_int",
    @"encodedHomePageURL", /* cannot be set */
    nil
  };
  NSMutableDictionary *props;
  int i;
  id tmp;
  
  props = [[_setProps mutableCopy] autorelease];

  for (i = 0; remKeys[i]; i++)
    [props removeObjectForKey:remKeys[i]];
  
  if (![props isNotNull]) {
    [self logWithFormat:@"nothing to patch ..."];
    return nil;
  }
  
  if ((tmp = [props objectForKey:@"zlAssocContents"])) {
    [self setAssociatedContents:tmp];
    [props removeObjectForKey:@"zlAssocContents"];
  }
  if ([props isNotNull])
    [self debugWithFormat:@"should patch folder: %@", props];
  
  if ([_delProps isNotNull])
    [self logWithFormat:@"not deleting properties: %@", _delProps];
  
  return nil;
}

- (id)performWebDAVBulkQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  LSCommandContext *ctx;
  id result;
  
  result = nil;
  if ([self respondsToSelector:
              @selector(performBulkQuery:onGlobalIDs:inContext:)]) {
    NSArray *gids;
    
    if ((gids = [self extractBulkGlobalIDs:_fs]))
      result = [self performBulkQuery:_fs onGlobalIDs:gids inContext:_ctx];
  }
  else
    result = [super performWebDAVBulkQuery:_fs inContext:_ctx];
  
  if ((ctx = [self commandContextInContext:_ctx])) {
    if ([ctx isTransactionInProgress]) {
      [self debugWithFormat:@"rollback open transaction ..."];
      if (![ctx rollback])
	[self errorWithFormat:@"failed to rollback transaction !"];
    }
  }
  return result;
}

- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onSingleAttribute:(NSString *)_prop
  inContext:(id)_ctx
{
  if ([_prop isEqualToString:@"davURL"]) {
    if ([self respondsToSelector:@selector(performDavURLQuery:inContext:)]) {
      if ([self doExplainQueries])
	[self logWithFormat:@"EXPLAIN: selected dav-url query due to attr"];
      return @selector(performDavURLQuery:inContext:);
    }
    else if ([self doExplainQueries])
      [self logWithFormat:@"EXPLAIN: not selected unsupported URL query"];
  }
  if ([_prop isEqualToString:@"davEntityTag"]) {
    if ([self respondsToSelector:@selector(performETagsQuery:inContext:)]) {
      if ([self doExplainQueries])
	[self logWithFormat:@"EXPLAIN: selected dav-etag query due to attr"];
      return @selector(performETagsQuery:inContext:);
    }
    else if ([self doExplainQueries])
      [self logWithFormat:@"EXPLAIN: not selected unsupported etag query"];
  }
  return NULL;
}

- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)_attrSet
  inContext:(id)_ctx
{
  // TODO: document who calls this
  /*
    This method is often overridden by subclasses but usually called as
    super for fallback. It returns a selector which should be used to execute
    the WebDAV query.
    
    TODO: it would be better to let SOPE/product.plist map queries to
          selectors using some rule.
  */
  
  /* check some standard methods */
  
  if ([_attrSet count] == 1) {
    return [self fetchSelectorForQuery:_fs 
		 onSingleAttribute:[_attrSet anyObject]
		 inContext:_ctx];
  }
  
  return NULL;
}

- (SEL)defaultFetchSelectorForZLQuery {
  return NULL;
}
- (SEL)defaultFetchSelectorForEvoQuery {
  if ([self respondsToSelector:@selector(performEvoQuery:inContext:)])
    return @selector(performEvoQuery:inContext:);
  return NULL;
}
- (SEL)defaultFetchSelectorForListQuery {
  if ([self respondsToSelector:@selector(performListQuery:inContext:)])
    return @selector(performListQuery:inContext:);
  return NULL;
}
- (SEL)defaultFetchSelectorForETagsQuery {
  if ([self respondsToSelector:@selector(performETagsQuery:inContext:)])
    return @selector(performETagsQuery:inContext:);
  return NULL;
}

- (SEL)defaultFetchSelectorForUnknownUserAgent {
  return [self defaultFetchSelectorForListQuery];
}

- (SEL)defaultFetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)_attrSet
  inContext:(id)_ctx
{
  NSString *ua;

  ua = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  
  if ([self isETagsQuery:_fs]) {
    if ([self doExplainQueries])
      [self logWithFormat:@"select etags query for WebDAV etags set"];
    return [self defaultFetchSelectorForETagsQuery];
  }
  
  if ([self isWebDAVListQuery:_fs]) {
    if ([self doExplainQueries])
      [self logWithFormat:@"select list query for WebDAV list set"];
    return [self defaultFetchSelectorForListQuery];
  }
  
  if ([self doExplainQueries]) {
    [self logWithFormat:
	    @"unknown query-set and unknown user-agent: %@\n  set: %@",
	    ua, _attrSet];
  }
  return [self defaultFetchSelectorForUnknownUserAgent];
}

- (id)performWebDAVQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /*
    The task of this method is to decide which fetch method is actually
    invoked. It does that based on the user-agent, on the fetch-spec
    etc.
  */
  NSString *scope;
  NSArray  *bulkQueryKeys;
  SEL      handler;
  NSSet    *propNames;

  if (_fs == nil) return nil;
  
  if ((bulkQueryKeys = [_fs davBulkTargetKeys]))
    return [self performWebDAVBulkQuery:_fs inContext:_ctx];
  
  scope = [_fs scopeOfWebDAVQuery];
  if ([scope hasPrefix:@"self"])
    return [super performWebDAVQuery:_fs inContext:_ctx];
  
  /* classify flat request (deep is processed like flat) */
  
  propNames = [NSSet setWithArray:[_fs selectedWebDAVPropertyNames]];
  
  handler = [self fetchSelectorForQuery:_fs 
		  onAttributeSet:propNames
		  inContext:_ctx];

  if (handler == NULL) {
    handler = [self defaultFetchSelectorForQuery:_fs 
                    onAttributeSet:propNames
                    inContext:_ctx];
    if (handler != NULL && [self doExplainQueries]) {
      [self logWithFormat:
              @"using default handler to process unknown query[depth=%@]: %@", 
              [[(WOContext *)_ctx request] headerForKey:@"depth"], 
	      [[_fs selectedWebDAVPropertyNames] 
                    componentsJoinedByString:@","]];
    }
  }
  if (handler != NULL) {
    id (*m)(id, SEL, EOFetchSpecification *, id);
    
    if ([self doExplainQueries]) {
      [self logWithFormat:@"EXPLAIN: selected %@ to process query.",
	      NSStringFromSelector(handler)];
    }
    
    if ((m = (void *)[self methodForSelector:handler]) == NULL) {
      [self errorWithFormat:
              @"did not find method for selected handler '%@' !",
	      NSStringFromSelector(handler)];
      return [NSException exceptionWithHTTPStatus:500 /* server error */
			  reason:@"missing handler for attribute set !"];
    }
    return m(self, handler, _fs, _ctx);
  }
  
  if ([self doExplainQueries]) {
    [self warnWithFormat:
            @"found no default handler to process query[depth=%@]: %@", 
            [[(WOContext *)_ctx request] headerForKey:@"depth"], 
	    [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  return [super performWebDAVQuery:_fs inContext:_ctx];
}

/* folder allprop sets */

- (NSString *)folderAllPropSetName {
  return nil;
}
- (NSString *)entryAllPropSetName {
  return nil;
}

- (BOOL)isBulkQueryContext:(id)_ctx {
  WORequest *rq = [(WOContext *)_ctx request];
  if ([[rq method] isEqualToString:@"BPROPFIND"])    return YES;
  if ([[rq uri] rangeOfString:@"_range"].length > 0) return YES;
  return NO;
}

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  NSString *setName = nil;
  
  setName = [self isBulkQueryContext:_ctx]
    ? [self entryAllPropSetName]
    : [self folderAllPropSetName];
  if (setName == nil)
    return [super defaultWebDAVPropertyNamesInContext:_ctx];
  
  return [[self propertySetNamed:setName] allObjects];
}

- (id)cdoSearchKey {
  static NSString *sxID = nil;
  if (sxID == nil) {
    sxID = [[[NSUserDefaults standardUserDefaults] 
	      objectForKey:@"skyrix_id"] copy];
  }
  return [[sxID stringByAppendingString:[self nameInContainer]]
                exDavBase64Value];
}

@end /* SxFolder(WebDAV) */
