/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "SkyPubRequestHandler.h"
#include "SkyPubResourceManager.h"
#include "SkyDocument+Pub.h"
#include "SkyDocument+PubResponse.h"
#include "common.h"
#include <NGExtensions/NSProcessInfo+misc.h>
#include <NGExtensions/NGFileManager.h>

@interface NSAutoreleasePool(Privates)
- (unsigned)autoreleaseCount;
@end

@interface WOApplication(MiscPriv)
- (void)_initPubContext:(WOContext *)_ctx;
@end

static int profile = -1;

@implementation SkyPubRequestHandler

+ (int)version {
  return [super version] + 0 /* 2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (profile == -1) {
    profile = [[NSUserDefaults standardUserDefaults]
                               boolForKey:@"ProfilePubRequestHandler"]
      ? 1 : 0;
  }
}

- (id)initWithFileManager:(id)_fm resourceManager:(SkyPubResourceManager *)_rm{
  if ((self = [super init])) {
    self->fileManager     = [_fm retain];
    self->resourceManager = [_rm retain];
  }
  return self;
}
- (id)init {
  return [self initWithFileManager:nil resourceManager:nil];
}
- (void)dealloc {
  [self->resourceManager release];
  [self->fileManager     release];
  [super dealloc];
}

/* accessors */

- (id)fileManager {
  return self->fileManager;
}
- (SkyPubResourceManager *)resourceManager {
  return self->resourceManager;
}

- (NSURL *)baseURL {
  NSString *fmt;
  
  fmt = [NSString stringWithFormat:@"http://%@:%@",
                    [[NSHost currentHost] name],
                    [WOApplication port]];
  return [NSURL URLWithString:fmt];
}

- (void)_appendFooterToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [_response appendContentString:@"<hr />"];
  [_response appendContentString:@"<i>"];
  [_response appendContentString:@"SKYRiX Publishing Server at "];
  [_response appendContentString:[[self baseURL] host]];
  [_response appendContentString:@" Port "];
  [_response appendContentString:[[[self baseURL] port] stringValue]];
}

- (WOResponse *)_errorResponseForRequest:(WORequest *)_request
  code:(int)_code
  title:(NSString *)_title
  comment:(NSString *)_format, ...
{
  WOResponse *response;
  
  response = [WOResponse responseWithRequest:_request];
  [response setStatus:_code];
  if ([_title length] > 0) {
    [response appendContentString:@"<h2>"];
    [response appendContentHTMLString:_title];
    [response appendContentString:@"</h2>"];
  }
  
  if ([_format length] > 0) {
    va_list  ap;
    NSString *s;
    
    va_start(ap, _format);
    s = [[NSString alloc] initWithFormat:_format arguments:ap];
    va_end(ap);
    
    [response appendContentHTMLString:s];
    [s release];
  }

  [self _appendFooterToResponse:response inContext:nil];
  
  return response;
}

- (NSString *)masterTemplateName {
  return @"Main";
}
- (NSString *)templateExtension {
  return @"xtmpl";
}

- (WOResponse *)handleRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  SkyDocument *document;
  WOResponse  *response;
  NSDate      *date = nil;
  NSString    *path;
  NSURL       *url;
  BOOL        isDir;
  
  date = [NSDate date];
  response = nil;
  
  /* preprocess URL */
  
  url  = [NSURL URLWithString:[_req uri] relativeToURL:[self baseURL]];
  path = [url path];
  
  /* lookup filemanager */
  
  if (self->fileManager == nil) {
    /* Server Error: missing fileManager */
    
    return [self _errorResponseForRequest:_req
                 code:500 /* server error */
                 title:@"Server Error"
                 comment:@"Missing filemanager to process URL %@", path];
  }
  
  /* check whether file exists ... */
  
  isDir = NO;
  if (![self->fileManager fileExistsAtPath:path isDirectory:&isDir]) {
    /* Not Found */
    return [self _errorResponseForRequest:_req
                 code:404 /* not found */
                 title:@"Not Found"
                 comment:@"The requested URL %@ was not found on this server.",
                   path];
  }
  
  /* retrieve document for path ... */
  
  if ((document = (id)[self->fileManager documentAtPath:path]) == nil) {
    response = [self _errorResponseForRequest:_req
                     code:500 /* server error */
                     title:@"Server Error"
                     comment:@"Couldn't get document for URL %@", path];
  }
  else if (isDir) {  /* redirect directories to index page ... */
    /* no -> redirect */
    NSString   *newuri;
    
    if ((newuri = [[document pubIndexDocument] pubPath])) {
      response = [WOResponse responseWithRequest:_req];
      [response setStatus:302 /* moved */];
      [response setHeader:newuri forKey:@"location"];
    
      [response appendContentString:@"<h2>Moved</h2>"];
      [response appendContentString:@"Resource "];
      [response appendContentHTMLString:[_req uri]];
      [response appendContentString:@" moved to location <a href=\""];
      [response appendContentString:newuri];
      [response appendContentString:@"\">"];
      [response appendContentHTMLString:newuri];
      [response appendContentString:@"</a>."];
      [self _appendFooterToResponse:response inContext:_ctx];
    }
    else {
      response = [self _errorResponseForRequest:_req
                       code:404 /* not found */
                       title:@"Missing Index"
                       comment:@"Didn't find index document for path '%@'",
                         [_req uri]];
    }
  }
  else {
    [_ctx takeValue:self->resourceManager 
	  forKey:@"mainTemplateResourceManager"];
    response = [document generatePubResponseInContext:_ctx];
  }
  
  if (profile) {
    NSLog(@"handleRequest:inContext: %.3fs",
          [[NSDate date] timeIntervalSinceDate:date]);
  }
  
  return response;
}

- (WOResponse *)handleRequest:(WORequest *)_request {
  NSAutoreleasePool *pool;
  WOContext         *context;
  WOResponse        *response;
  WOApplication     *app;
  NSDate            *date;
  unsigned          vsizeStart;

  if (profile) {
    date       = [NSDate date];
    vsizeStart = [[NSProcessInfo processInfo] virtualMemorySize];
  }
  else {
    date = nil;
    vsizeStart = 0;
  }
  
  response = nil;
  app      = [WOApplication application];
  
  if ([[_request method] isEqualToString:@"OPTIONS"]) {
    response = [WOResponse responseWithRequest:_request];
    [response setStatus:200];
    [response setHeader:@"0" forKey:@"content-length"];
    return response;
  }
  if ([[_request method] isEqualToString:@"TRACE"]) {
    response = [WOResponse responseWithRequest:_request];
    [response setStatus:200];
    [response setHeader:@"0" forKey:@"content-length"];
    return response;
  }
  if ([[_request method] isEqualToString:@"DELETE"]) {
    response = [WOResponse responseWithRequest:_request];
    [response setStatus:404];
    [response setHeader:@"0" forKey:@"content-length"];
    return response;
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  {
    /* setup context */
    context = [WOContext contextWithRequest:_request];
    NSAssert(context, @"no context assigned ..");
    
    if ([app respondsToSelector:@selector(_initPubContext:)])
      [app _initPubContext:context];
    
    NS_DURING {
      [app awake];
      
      if ([[_request formValueForKey:@"refresh"] boolValue]) {
        [app logWithFormat:@"flushing filemanager ..."];
        [self->fileManager flush];
      }
      
      response = [[self handleRequest:_request inContext:context] retain];
      
      [app sleep];
    }
    NS_HANDLER {
      response = [app handleException:localException inContext:context];
      response = [response retain];
    }
    NS_ENDHANDLER;
  }
  
  if (profile) {
    NSLog(@"objects in pool: %d, %.3fs, memdiff=%d",
          [pool autoreleaseCount],
          [[NSDate date] timeIntervalSinceDate:date],
          [[NSProcessInfo processInfo] virtualMemorySize] - vsizeStart
          );
  }
  
  [pool release];
  
  if (profile) {
    NSLog(@"handleRequest(E): %.3fs, memdiff=%d",
          [[NSDate date] timeIntervalSinceDate:date],
          [[NSProcessInfo processInfo] virtualMemorySize] - vsizeStart);
  }
  
  return AUTORELEASE(response);
}

@end /* SkyPubRequestHandler */
