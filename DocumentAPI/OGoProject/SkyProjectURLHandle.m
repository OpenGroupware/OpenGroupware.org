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
// $Id$

#import <Foundation/NSURLHandle.h>
#import <Foundation/NSURL.h>

@class NSDictionary, NSData, EOGlobalID;

/*
  handles URLs like this:
  
    skyrixproject://localhost/MyProject/folder/file.txt
*/

@interface NSObject(PreventWarnings)
- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;
@end /* NSObject(PreventWarnings) */

@interface SkyProjectURLHandle : NSURLHandle
{
  NSURL             *url;
  NSString          *projectName; /* project name in URL */
  NSString          *filePath;    /* file path in URL */
  
  BOOL              shallCache;
  NSURLHandleStatus status;
  NSData            *cachedData;
  NSDictionary      *cachedProperties;
}
@end

#include <LSFoundation/LSFoundation.h>
#include "SkyProjectDataSource.h"
#include "common.h"

@interface NSObject(Gid)
- (EOGlobalID *)globalID;
@end

@implementation NSHost(CheckLocalAddress)

+ (BOOL)isLocalHost:(NSString *)_host {
  if (_host == nil)
    return YES;
  if ([_host isEqualToString:@"localhost"])
    return YES;
  if ([_host isEqualToString:@"127.0.0.1"])
    return YES;

  if ([[[NSHost currentHost] names] containsObject:_host])
    return YES;
  if ([[[NSHost currentHost] addresses] containsObject:_host])
    return YES;
  
  return NO;
}

@end /* NSHost(CheckLocalAddress) */

@implementation SkyProjectURLHandle

+ (BOOL)canInitWithURL:(NSURL *)_url {
  if (![[_url scheme] isEqualToString:@"skyrixproject"])
    return NO;
  
  /* check for localhost */
  
  if (![NSHost isLocalHost:[_url host]])
    /* remote skyrix host address, use another handle for that */
    return NO;
  
  /* check whether a project is given */
  if ([[[_url path] pathComponents] count] < 2)
    /* not enough path components */
    return NO;
  
  return YES;
}

- (id)initWithURL:(NSURL *)_url cached:(BOOL)_flag {
  if (![[_url scheme] isEqualToString:@"skyrixproject"]) {
    NSLog(@"%s: invalid URL scheme %@ for SkyProjectURLHandle !",
          __PRETTY_FUNCTION__, [_url scheme]);
    RELEASE(self);
    return nil;
  }

  self->shallCache = _flag;
  self->status     = NSURLHandleNotLoaded;

  /* disassemble URL */
  
  self->url = [_url copy];
  {
    NSMutableArray *pcs;
    
    pcs = [[[_url path] pathComponents] mutableCopy];
    if ([pcs count] < 2) {
      /* not enough path-components (at least '/','projectName' required) */
      RELEASE(pcs);
      RELEASE(self);
      return nil;
    }
    
    self->projectName = [[pcs objectAtIndex:1] copy];
    [pcs removeObjectAtIndex:1];
    self->filePath = [[NSString pathWithComponents:pcs] copy];
    RELEASE(pcs); pcs = nil;
  }
  
  return self;
}
- (void)dealloc {
  RELEASE(self->cachedData);
  RELEASE(self->cachedProperties);
  RELEASE(self->projectName);
  RELEASE(self->filePath);
  RELEASE(self->url);
  [super dealloc];
}

- (NSData *)loadInForeground {
  /* where to get the context ?? */
  EOGlobalID       *pgid;
  LSCommandContext *cmdctx;
  
  RELEASE(self->cachedProperties); self->cachedProperties = nil;
  RELEASE(self->cachedData);       self->cachedData       = nil;
  
  if ((cmdctx = [LSCommandContext activeContext]) == nil) {
    NSLog(@"%s: need active command-context for resolution of URL %@ !",
          __PRETTY_FUNCTION__, self->url);
    return nil;
  }
  
  /* find project */
  {
    EOFetchSpecification *fspec;
    EOQualifier          *qualifier;
    id      pds;
    id      project;
    NSArray *projects;
    
    qualifier = [EOQualifier qualifierWithQualifierFormat:@"name=%@",
                               self->projectName];
    fspec = [[EOFetchSpecification alloc] initWithEntityName:nil
                                          qualifier:qualifier
                                          sortOrderings:nil
                                          usesDistinct:YES isDeep:NO 
					  hints:nil];
    
    pds = [[SkyProjectDataSource alloc] initWithContext:cmdctx];
    [pds setFetchSpecification:fspec];
    
    projects = [pds fetchObjects];
  
    if ([projects count] == 1) {
      project = [projects objectAtIndex:0];
      //NSLog(@"using project: %@", project);
    }
    else {
      project = nil;
    }
    
    pgid = [project valueForKey:@"globalID"];
    
    RELEASE(fspec); fspec = nil;
    RELEASE(pds);   pds = nil;
  }
  
  if (pgid == nil) {
    NSLog(@"%s: got no project id ..", __PRETTY_FUNCTION__);
    return nil;
  }
  
  /* open file manager */
  {
    Class class;
    id fm;

    NSLog(@"WARNING[%s] depricated call ...", __PRETTY_FUNCTION__);

    if (!(class = NSClassFromString(@"SkyProjectFileManager"))) {
      class = NSClassFromString(@"SkyFSFileManager");
    }
    fm = nil;
    if (class)
    fm = [[class alloc] initWithContext:cmdctx projectGlobalID:pgid];

    if (fm == nil) {
      NSLog(@"%s: got no filemanager for project gid %@ (ctx=%@)",
            __PRETTY_FUNCTION__, pgid, cmdctx);
      return nil;
    }
    
    self->cachedData = [fm contentsAtPath:self->filePath];
    RETAIN(self->cachedData);
    
    if (self->cachedData == nil) {
      NSLog(@"%s: got no data from fileManager %@ for project gid %@: "
            @"path %@ (ctx=%@)",
            __PRETTY_FUNCTION__, fm, pgid, self->filePath, cmdctx);
    }
    
    self->cachedProperties = [[fm fileAttributesAtPath:self->filePath
                                  traverseLink:YES]
                                  copy];

    [fm release]; fm = nil;
  }
  
  return self->cachedData;
}
- (void)loadInBackground {
  [self loadInForeground];
}

- (void)flushCachedData {
  RELEASE(self->cachedData);       self->cachedData       = nil;
  RELEASE(self->cachedProperties); self->cachedProperties = nil;
}

- (NSData *)resourceData {
  NSData *data;
  
  if (self->cachedData)
    return AUTORELEASE([self->cachedData copy]);
  
  data = [self loadInForeground];

  data = [data copy];
  
  if (!self->shallCache)
    [self flushCachedData];
  
  return AUTORELEASE(data);
}

- (NSData *)availableResourceData {
  return AUTORELEASE([self->cachedData copy]);
}

- (NSURLHandleStatus)status {
  return self->status;
}
- (NSString *)failureReason {
  if (self->status != NSURLHandleLoadFailed)
    return nil;
  
  return @"loading of SKYRiX URL failed";
}

/* properties */

- (id)propertyForKey:(NSString *)_key {
  if (self->cachedProperties)
    return [self->cachedProperties objectForKey:_key];
  
  if ([self loadInForeground]) {
    id value;
    
    value = [self->cachedProperties objectForKey:_key];

    RETAIN(value);
    
    if (!self->shallCache)
      [self flushCachedData];

    return AUTORELEASE(value);
  }
  else {
    [self flushCachedData];
    return nil;
  }
}
- (id)propertyForKeyIfAvailable:(NSString *)_key {
  return [self->cachedProperties objectForKey:_key];
}

/* writing */

- (BOOL)writeData:(NSData *)_data {
  [self flushCachedData];

  return NO;
}

@end /* SkyProjectURLHandle */
