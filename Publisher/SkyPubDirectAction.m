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

#include <NGObjWeb/WODirectAction.h>
#include <NGExtensions/NGFileManager.h>
#include <NGJavaScript/NGJavaScriptObjectMappingContext.h>

@class SkyPubResourceManager, SkyDocument;

@interface SkyPubDirectAction : WODirectAction
{
  id<NSObject,NGFileManagerDataSources> fileManager;
  SkyPubResourceManager            *resourceManager;
  NGJavaScriptObjectMappingContext *jsMapContext;
  SkyDocument                      *document;
}
@end

#include "SkyPubResourceManager.h"
#include "SkyPubFileManager.h"
#include "SkyPubDataSource.h"
#include "SkyDocument+Pub.h"
#include "SkyDocument+PubResponse.h"
#include <OGoFoundation/LSWSession.h>
#include "common.h"
#include <OGoDocuments/SkyDocuments.h>

@interface SkyDocument(Clearing)
- (void)clearContent;
@end

@implementation SkyPubDirectAction

static BOOL debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SkyPubDebugEnabled"];
}

- (void)dealloc {
  [self->document        release];
  [self->jsMapContext    release];
  [self->resourceManager release];
  [self->fileManager     release];
  [super dealloc];
}

/* accessors */

- (NSString *)path {
  NSString *p;
  
  p = [[self request] formValueForKey:@"path"];
  
  if ([p length] == 0) {
    NSRange r;
    
    p = [[self request] requestHandlerPath];
    
    r = [p rangeOfString:@"?"];
    if (r.length > 0)
      p = [p substringToIndex:r.location];
    
    r = [p rangeOfString:@"SkyPubDirectAction/pubPreview"];
    if (r.length > 0) {
      p = [p substringFromIndex:
               (r.location + [@"SkyPubDirectAction/pubPreview" length])];
      return p;
    }
    
    [self logWithFormat:@"missing path form parameter .."];
    return @"/";
  }
  return p;
}
- (NSString *)templateName {
  NSString *n;
  
  n = [[self request] formValueForKey:@"template"];
  return ([n length] == 0) ? @"Main" : (id)n;
}

- (id)fileManager {
  /* TODO: hack to get preview filemanager ... */
  LSWSession *sn;
  id page;
  
  if ((sn = (LSWSession *)[self existingSession]) == nil) {
    [self logWithFormat:@"missing session ..."];
    return nil;
  }
  
  if ((page = [[sn navigation] activePage]) == nil) {
    [self logWithFormat:@"missing active page ..."];
    return nil;
  }
  
  if ([page respondsToSelector:@selector(fileManager)])
    return [page fileManager];
  
  return nil;
}

- (id)pubFileManager {
  id fm;

  if (self->fileManager)
    return self->fileManager;
  
  if ((fm = [self fileManager]) == nil) {
    [self logWithFormat:@"missing -fileManager !!!"];
    return nil;
  }
  
  self->fileManager = [[SkyPubFileManager alloc] initWithFileManager:fm];
  return self->fileManager;
}

- (WOResourceManager *)pubResourceManager {
  id fm;;
  
  if (self->resourceManager)
    return self->resourceManager;

  if ((fm = [self pubFileManager]) == nil) {
    [self logWithFormat:@"missing -pubFileManager !!!"];
    return nil;
  }
  
  self->resourceManager =
    [[SkyPubResourceManager alloc] initWithFileManager:fm];
  return self->resourceManager;
}

- (NGJavaScriptObjectMappingContext *)jsMapContext {
  if (self->jsMapContext)
    return self->jsMapContext;
  
  self->jsMapContext = [[NGJavaScriptObjectMappingContext alloc] init];
  return self->jsMapContext;
}

- (SkyDocument *)pubDocument {
  if (self->document)
    return self->document;
  
  self->document = [[[self pubFileManager] documentAtPath:[self path]] retain];
  return self->document;
}

/* constructing request */

- (WORequest *)prototypeRequest {
  return [self request];
}

- (WORequest *)requestForPath:(NSString *)_path {
  WORequest *r, *proto;
  
  proto = [self prototypeRequest];
  
  r = [[WORequest alloc]
                  initWithMethod:[proto method]
                  uri:_path
                  httpVersion:[proto httpVersion]
                  headers:[proto headers]
                  content:[proto content]
                  userInfo:[proto userInfo]];
  return [r autorelease];
}

/* direct actions */

- (id<WOActionResults>)pubPreviewDocument:(SkyDocument *)_doc {
  WORequest   *req;
  WOResponse  *response;
  WOContext   *templateCtx;
  WOResourceManager *rm;
  
  if (_doc == nil)
    return nil;
  
  if (debugOn) [self debugWithFormat:@"preview doc: %@", _doc];
  
  if ((req = [self requestForPath:[_doc valueForKey:@"NSFilePath"]]) == nil) {
    [self logWithFormat:@"got no request for document %@", _doc];
    return nil;
  }
  if ((templateCtx = [WOContext contextWithRequest:req]) == nil) {
    [self logWithFormat:@"got no context for request %@ on document %@",
            req, _doc];
    return nil;
  }

  if (debugOn) {
    [self debugWithFormat:@"  request: %@", req];
    [self debugWithFormat:@"  context: %@", templateCtx];
  }
  
  if ((rm = [self pubResourceManager]) == nil) {
    [self logWithFormat:@"missing -pubResourceManager !!!"];
    return nil;
  }
  [templateCtx takeValue:rm forKey:@"mainTemplateResourceManager"];
  
  response = (id)[_doc generatePubResponseInContext:templateCtx];
  
  if (debugOn) [self debugWithFormat:@"  response: %@", response];
  
  /* reset DOM structure */
  if ([_doc respondsToSelector:@selector(clearContent)])
    [(id)_doc clearContent];
  
  return response;
}

- (id<WOActionResults>)pubPreviewAction {
  SkyDocument *doc;
  
  if ([self existingSession] == nil) {
    // TODO: better UI for error handling
    [self logWithFormat:@"missing session ..."];
    return nil;
  }
  
  if ((doc = [self pubDocument]) == nil) {
    // TODO: better UI for error handling
    [self logWithFormat:@"got no document for path '%@'", [self path]];
    return nil;
  }
  
  if ([[doc valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
    SkyDocument *idx;
    
    if ((idx = [doc pubIndexDocument])) {
      [self logWithFormat:@"showing index document for folder %@", doc];
      doc = idx;
    }
  }
  
  return [self pubPreviewDocument:doc];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SkyPubDirectAction */
