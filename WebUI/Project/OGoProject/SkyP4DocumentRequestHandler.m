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

#include "SkyP4DocumentRequestHandler.h"
#include <LSFoundation/OGoContextManager.h>
#include "common.h"

// TODO: should be replaced with a SOPE mechanism or probably moved to 
//       ZideStore alltogether so that the instances is freed from
//       content delivery

@interface WOApplication(LSO)
- (id)lsoServer;
@end

@implementation WOContext(SkyP4DocumentRequestHandler)

- (NSString *)p4documentURLForProjectNamed:(NSString *)_pname
  path:(NSString *)_path
  versionTag:(NSString *)_versionTag
  disposition:(NSString *)_disposition
{
  // Note: this is used by SkyP4DownloadLink !
  // ***DEPRECATED***
  NSMutableString *mpath;
  BOOL     doEscape;
  NSString *pname;
  NSArray  *pc;
  unsigned i, count;
  NSString *href;
  NSString *qs;
  
  if ([_pname length] == 0)
    return nil;
  if ([_path length] == 0)
    return nil;
  
  doEscape = YES;
  {
    WEClientCapabilities *cc = [[self request] clientCapabilities];

    if ([cc isNetscape] && ([cc majorVersion] < 5))
      doEscape = NO;
  }
  
  pname = doEscape ? [_pname stringByEscapingURL] : _pname;
  
  mpath = [NSMutableString stringWithCapacity:100];
  [mpath appendString:@"/"];
  [mpath appendString:pname];
  
  pc = [_path pathComponents];

  for (i = 0, count = [pc count]; i < count; i++) {
    NSString *pcc;
    NSString *pe;
    
    pcc = [pc objectAtIndex:i];
    
    if ([pcc isEqualToString:@"/"])
      continue;

    [mpath appendString:@"/"];
      
    pe  = [pcc pathExtension];
    pcc = [pcc stringByDeletingPathExtension];
      
    if (doEscape)
      pcc = [pcc stringByEscapingURL];
      
    [mpath appendString:pcc];
      
    if ([pe length] > 0) {
      [mpath appendString:@"."];
      [mpath appendString:pe];
    }
  }
  
  if ([_versionTag length] > 0) {
    [mpath appendString:@";"];
    [mpath appendString:
             doEscape ? [_versionTag stringByEscapingURL] : _versionTag];
  }

  qs = [NSString stringWithFormat:@"wosid=%@&woinst=%@",
                   [[self session] sessionID],
                   [[WOApplication application] number]];
  
  if ([_disposition isNotNull]) {
    qs = [qs stringByAppendingString:@"&disposition="];
    qs = [qs stringByAppendingString:_disposition];
  }

  href = [self urlWithRequestHandlerKey:@"g"
               path:mpath
               queryString:qs];
  
  return href;
}

- (NSString *)p4documentURLForProjectNamed:(NSString *)_pname
  path:(NSString *)_path
  versionTag:(NSString *)_versionTag
{
  // ***DEPRECATED***
  return [self p4documentURLForProjectNamed:_pname path:_path
               versionTag:_versionTag disposition:nil];
}

- (NSString *)p4documentURLForProjectWithGlobalID:(EOGlobalID *)_gid
  path:(NSString *)_path
  versionTag:(NSString *)_versionTag
{
  return [self p4documentURLForProjectWithGlobalID:_gid path:_path
               versionTag:_versionTag disposition:nil];
               
}
- (NSString *)p4documentURLForProjectWithGlobalID:(EOGlobalID *)_gid
  path:(NSString *)_path
  versionTag:(NSString *)_versionTag
  disposition:(NSString *)_disposition
{
  NSMutableString *mpath;
  BOOL     doEscape;
  NSArray  *pc;
  unsigned i, count;
  NSString *href;
  NSString *qs;

  if (_gid == nil)
    return nil;
  if ([_path length] == 0)
    return nil;
  
  doEscape = YES;
  {
    WEClientCapabilities *cc = [[self request] clientCapabilities];

    if ([cc isNetscape] && ([cc majorVersion] < 5))
      doEscape = NO;
  }
  
  mpath = [NSMutableString stringWithCapacity:100];
  [mpath appendString:@"/"];
  [mpath appendString:[[(EOKeyGlobalID *)_gid keyValues][0] stringValue]];
  
  pc = [_path pathComponents];

  for (i = 0, count = [pc count]; i < count; i++) {
    NSString *pcc;
    NSString *pe;
    
    pcc = [pc objectAtIndex:i];
    
    if ([pcc isEqualToString:@"/"])
      continue;

    [mpath appendString:@"/"];
      
    pe  = [pcc pathExtension];
    pcc = [pcc stringByDeletingPathExtension];
      
    if (doEscape)
      pcc = [pcc stringByEscapingURL];
      
    [mpath appendString:pcc];
      
    if ([pe length] > 0) {
      [mpath appendString:@"."];

      if (doEscape)
	pe = [pe stringByEscapingURL];
        
      [mpath appendString:pe];
    }
  }
  
  if ([_versionTag length] > 0) {
    [mpath appendString:@";"];
    [mpath appendString:
             doEscape ? [_versionTag stringByEscapingURL] : _versionTag];
  }

  qs = [NSString stringWithFormat:@"wosid=%@&woinst=%@",
                   [[self session] sessionID],
                   [[WOApplication application] number]];

  if ([_disposition isNotNull]) {
    qs = [qs stringByAppendingString:@"&disposition="];
    qs = [qs stringByAppendingString:_disposition];
  }

  href = [self urlWithRequestHandlerKey:@"g"
               path:mpath
               queryString:qs];
  
  return href;
}

@end /* WOContext(SkyP4DocumentRequestHandler) */

@implementation SkyP4DocumentRequestHandler

static NSCharacterSet *digits = nil;

+ (int)version {
  return [super version] + 0 /* 2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (digits == nil)
    digits = [[NSCharacterSet decimalDigitCharacterSet] retain];
}

- (void)_logDownloadOfPath:(NSString *)_path
  fileManager:(SkyProjectFileManager *)_fm
  session:(WOSession *)_session
{
  SkyProjectDocument *doc;
  NSUserDefaults *ud;
  NSRange r;

  ud = [(OGoSession *)_session userDefaults];
  if (![[ud objectForKey:@"skyp4_log_documentdownload"] boolValue])
    return;
  
  r = [_path rangeOfString:@";"];
  if (r.length == 0) {
    doc = [_fm documentAtPath:_path];
    [doc logDownload];
    return;
  }

  doc = (id)[_fm documentAtPath:[_path substringToIndex:r.location]];
  _path = [_path substringFromIndex:(r.location + r.length)];
  [doc logDownloadOfVersion:_path];
}

- (void)_processGET:(WORequest *)_request withResponse:(WOResponse *)_r
  session:(WOSession *)_session
  fileManager:(SkyProjectFileManager *)_fm path:(NSString *)_path
{
  NSData  *data;
  
  if (![_fm isReadableFileAtPath:_path]) {
    [_r setStatus:403 /* forbidden */];            
    return;
  }
  
  if ((data = [_fm contentsAtPath:_path]) == nil)
    return;
  
  [_r setStatus:200 /* OK */];
  [_r setContent:data];
  
  /* log download */
  [self _logDownloadOfPath:_path fileManager:_fm session:_session];
}

- (void)_processRequest:(WORequest *)_request withResponse:(WOResponse *)_r
  session:(WOSession *)_session
  fileManager:(SkyProjectFileManager *)_fm path:(NSString *)_path
{
  NSString *m;

  m = [_request method];
  if ([m isEqualToString:@"GET"]) {
    [self _processGET:_request withResponse:_r session:_session
	  fileManager:_fm path:_path];
    return;
  }
  if ([m isEqualToString:@"HEAD"]) {
    [_r setStatus:200 /* OK */];
    return;
  }
  if ([m isEqualToString:@"OPTIONS"]) {
    [_r setStatus:200 /* OK */];
    return;
  }
  
  if ([m isEqualToString:@"PROPFIND"]) {
    NSString *s;
    
    s = [[NSString alloc] initWithData:[_request content]
			  encoding:NSUTF8StringEncoding];
    [self logWithFormat:@"PROPFIND: %@", s];
    [self logWithFormat:@"HEADER: %@", [_request headers]];
    [s release]; s = nil;
          
    [_r setStatus:501 /* not implemented */];
    return;
  }

  if ([m isEqualToString:@"PROPPATCH"]) {
    [_r setStatus:501 /* not implemented */];
    return;
  }
  
  [self logWithFormat:@"unknown request method: %@", m];
  [_r setStatus:501 /* not implemented */];
}

- (void)_postProcessResponse:(WOResponse *)_r
  fileManager:(SkyProjectFileManager *)_fm path:(NSString *)_path
  disposition:(NSString *)_disposition
{
  NSDictionary *info;
  NSString     *mimeType;
  
  if ((info = [_fm fileAttributesAtPath:_path traverseLink:YES]) == nil)
    return;
    
  if ((mimeType = [info objectForKey:@"NSFileMimeType"]))
    [_r setHeader:mimeType forKey:@"content-type"];
  if ([_disposition isNotNull])
    [_r setHeader:_disposition forKey:@"content-disposition"];
}

- (WOResponse *)handleRequest:(WORequest *)_request
  session:(WOSession *)_session
  commandContext:(LSCommandContext *)_ctx
{
  /* TODO: split up this huge method! */
  WOApplication *app;
  NSString   *path;
  NSString   *pname;
  WOResponse *response;
  EOGlobalID *pgid;
  NSData     *data;
  NSString   *disposition;
  NSRange    r;
  /* TODO: type should be replaced with a protocol */
  SkyProjectFileManager *fm;
  BOOL isDir;
  
  app = [WOApplication application];
  
  response = [[[WOResponse alloc] initWithRequest:_request] autorelease];
  if (_ctx == nil) {
    [app logWithFormat:@"missing command-context .."];
    [response setStatus:500];
    return response;
  }

  path = [_request requestHandlerPath];
  path = [path stringByUnescapingURL];

  if ([path length] == 0) {
    [response setStatus:404];
    return response;
  }

  disposition = nil;
  
  r = [path rangeOfString:@"?"];
  if (r.length > 0) {
    NSString     *arg;
    NSEnumerator *enumerator;
    
    arg  = [path substringFromIndex:(r.location + r.length)];
    path = [path substringToIndex:r.location];
    
    enumerator = [[arg componentsSeparatedByString:@"&"] objectEnumerator];
    while ((arg = [enumerator nextObject])) {
      NSRange  r;
      NSString *k;
      
      r = [arg rangeOfString:@"="];
      if (r.length == 0)
	continue;
	
      k = [arg substringToIndex:r.location];

      if (![k isEqualToString:@"disposition"])
	continue;

      disposition = [arg substringFromIndex:(r.location + r.length)];
      disposition = [NSString stringWithFormat:@"%@; filename=%@",
				disposition, [path lastPathComponent]];
      break;
    }
  }
  
  r = [path rangeOfString:@"/"];
  if (r.length == 0) {
    [app logWithFormat:@"invalid document path: '%@'", path];
    [response setStatus:404];
    return response;
  }
  
  pname = [path substringToIndex:r.location];
  path  = [path substringFromIndex:r.location];
  
  [app debugWithFormat:@"shall download document '%@' from project '%@'",
         path, pname];
  
  if ([pname length] == 0) {
    [app logWithFormat:@"  missing project-id in download URL (%@)...",
           [_request requestHandlerPath]];
    [response setStatus:404];
    return response;
  }
  
  if ([path length] == 0)
    path = @"/";
  
  /* find project */
  if (![digits characterIsMember:[pname characterAtIndex:0]]) {
    /* first char is not a number */
    /* TODO: move to separate method ... */
    EOFetchSpecification *fspec;
    EOQualifier          *qualifier;
    SkyProjectDataSource *pds;
    id      project;
    NSArray *projects;
    
    qualifier = [EOQualifier qualifierWithQualifierFormat:@"name=%@", pname];
    fspec = [[EOFetchSpecification alloc] initWithEntityName:nil
                                          qualifier:qualifier
                                          sortOrderings:nil
                                          usesDistinct:YES isDeep:NO 
					  hints:nil];

    pds = [SkyProjectDataSource alloc]; // sep line to make gcc happy
    pds = [pds initWithContext:(id)_ctx];
    
    [pds setFetchSpecification:fspec];
    
    projects = [pds fetchObjects];
  
    if ([projects count] == 1) {
      project = [projects objectAtIndex:0];
      NSLog(@"using project: %@", project);
    }
    else {
      NSLog(@"projects: %@", projects);
      project = nil;
    }
    
    pgid = [project valueForKey:@"globalID"];
    
    [fspec release]; fspec = nil;
    [pds   release];   pds = nil;
  }
  else {
    NSNumber *pkey;
    
    pkey = [NSNumber numberWithInt:[pname intValue]];
    pgid = [[_ctx typeManager] globalIDForPrimaryKey:pkey];
  }
  
  if (pgid == nil) {
    [app logWithFormat:@"%s: got no project id ..", __PRETTY_FUNCTION__];
    [response setStatus:404];
    return response;
  }

  data = nil;
  
  /* open file manager */

  if (pgid == nil)
    return response;
  
  fm = [[OGoFileManagerFactory fileManagerInContext:_ctx
			       forProjectGID:pgid] 
	                       retain];
  if (fm == nil) {
    [self logWithFormat:
	    @"%s: got no filemanager for project gid %@ (ctx=%@)",
            __PRETTY_FUNCTION__, pgid, _ctx];
    [response setStatus:500 /* server error */];
    return response;
  }

  if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
    [self logWithFormat:
	    @"%s: got no data from fileManager %@ for project gid %@: "
	    @"path %@ (ctx=%@)",
            __PRETTY_FUNCTION__, fm, pgid, path, _ctx];
    [fm release];
    [response setStatus:404 /* Not Found */];
    return response;
  }
  
  [self _processRequest:_request withResponse:response session:_session
	fileManager:fm path:path];
  
  [self _postProcessResponse:response fileManager:fm path:path
	disposition:disposition];
  
  [fm release];
  
  return response;
}

- (LSCommandContext *)_commandContextForRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  /* TODO: can we split up this method? */
  OGoContextManager *lso;
  NSString *authType;
  NSString *authUser;
  NSString *auth;
  NSRange  r;
  id       sn;

  authType = [_request headerForKey:@"x-webobjects-auth-type"];
  authUser = [[authType lowercaseString] isEqualToString:@"basic"]
    ? [_request headerForKey:@"x-webobjects-remote-user"]
    : nil;
  
  if ([authUser length] == 0) {
    /* missing auth */
    NSLog(@"%s: missing auth user (url=%@) ..",
          __PRETTY_FUNCTION__, [_request uri]);
    return nil;
  }

  if ((auth = [_request headerForKey:@"authorization"]) == nil) {
    /* missing auth */
    NSLog(@"%s: missing auth header (authuser=%@, url=%@)",
          __PRETTY_FUNCTION__, authUser, [_request uri]);
    return nil;
  }
  
  r = [auth rangeOfString:@" " options:NSBackwardsSearch];
  if (r.length == 0) {
    /* invalid auth */
    NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
    return nil;
  }
  
  auth = [auth substringFromIndex:(r.location + r.length)];
  auth = [auth stringByDecodingBase64];
  
  r = [auth rangeOfString:@":"];
  auth = (r.length > 0)
    ? [auth substringFromIndex:(r.location + r.length)]
    : nil;
  
  if (auth == nil) {
    /* invalid auth */
    NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
    return nil;
  }
  
  if ([auth length] <= 0)
    return nil;
  
  lso = [[WOApplication application] lsoServer];
  if (![lso isLoginAuthorized:authUser password:auth]) {
    [self logWithFormat:@"%s: login %@ was not authorized !", 
	  __PRETTY_FUNCTION__, authUser];
    return nil;
  }
  
  if ((sn = [lso login:authUser password:auth]) == nil) {
    [self logWithFormat:
	    @"%s: login %@ couldn't login !", __PRETTY_FUNCTION__, authUser];
    return nil;
  }
  
  [self logWithFormat:
	  @"%s: created lso-session for login '%@'", __PRETTY_FUNCTION__,
	  authUser];

  // TODO: Note: the 'sn' is not an OGoSession! but the LSFoundation sn
  return [(OGoSession *)sn commandContext];
}

- (WOResponse *)handleRequest:(WORequest *)_request {
  NSAutoreleasePool *pool;
  WOResponse    *response;
  WOApplication *app;
  NSString      *sessionId  = nil;
  WOSession     *session    = nil;
  WOContext     *context    = nil;

  response = nil;
  session  = nil;
  context  = nil;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  app = [WOApplication application];
  NSAssert(app, @"missing WOApplication object ..");
  
  {
    /* check session id */
    *(&session)   = nil;
    
    *(&sessionId) = [_request formValueForKey:WORequestValueSessionID];
    if ([sessionId length] == 0) {
      *(&sessionId) = [_request cookieValueForKey:[app name]];
      
      if ([sessionId isEqual:@"nil"])
        sessionId = nil;
    }
  }
  
  if (sessionId == nil) {
    [app logWithFormat:@"missing session for document query (url=%@)..",
           [_request uri]];
  }
  
  NS_DURING {
    /* setup context */
    context = [WOContext contextWithRequest:_request];
    NSAssert(context, @"no context assigned ..");
    [[[NSThread currentThread] threadDictionary]
                setObject:context forKey:@"WOContext"];
    
    [app awake];
    
    /* retrieve session */
    [app lock];
    {
      if (sessionId) {
        NSAssert(app,     @"missing application object ..");
        NSAssert(context, @"missing context ..");
        
        session = [app restoreSessionWithID:sessionId
                       inContext:context];
        if (session == nil) {
          NSLog(@"%s: couldn't restore session with id '%@' (url=%@)",
                __PRETTY_FUNCTION__, sessionId, [_request uri]);
        }
      }
    }
    [app unlock];
    
    {
      [session lock];
      
      NS_DURING {
        LSCommandContext *ctx;
        
        if ((ctx = [(OGoSession *)session commandContext]) == nil) {
          if (session) {
            NSLog(@"%s: session %@ has no command context ?",
                  __PRETTY_FUNCTION__, session);
          }
          
          ctx = [self _commandContextForRequest:_request
                      inContext:context];
        }
        
        response = [self handleRequest:_request
                         session:session
                         commandContext:ctx];
        
        response = [response retain];
        
        if (session)
          [app saveSessionForContext:context];
      }
      NS_HANDLER {
        [session unlock];
        response = [app handleException:localException inContext:context];
        response = [response retain];
      }
      NS_ENDHANDLER;
      
      [session unlock];
    }
    
    [app sleep];
  }
  NS_HANDLER {
    response = [app handleException:localException inContext:context];
    response = [response retain];
  }
  NS_ENDHANDLER;
  
  [[[NSThread currentThread] threadDictionary] removeObjectForKey:@"WOContext"];
  [pool release];
  
  return [response autorelease];
}

@end /* SkyP4DocumentRequestHandler */
