// $Id$

#include "common.h"
#include "SkyProjectRequestHandler.h"
#include "Session.h"

@interface WORequest(Private)
- (NGHttpRequest *)httpRequest;
@end

@interface WOContext(Private)
- (void)setSession:(WOSession *)_session;
@end

@interface NSObject(Private)
- (id)globalID;
- (WOResponse *)handleRequest:(id)_req fileManager:(SkyProjectFileManager *)_fm;
@end

@implementation SkyProjectRequestHandler

static int logDavRequest  = -1;
static int logDavResponse = -1;

+ (int)version {
  return [super version] + 0 /* 2 */;
}

+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

#if !LIB_FOUNDATION_LIBRARY
- (void)dealloc {
  RELEASE(self->sessionIds4Auth);
  [super dealloc];
}
#endif

- (WOResponse *)handleRequest:(WORequest *)_request
  session:(Session *)_session
  commandContext:(LSCommandContext *)_ctx
{
  SkyProjectFileManager *fm = nil;
  WOResponse *response = nil;
  NSString   *method    = nil;

  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];
  
  if (_ctx == nil) {
    NSLog(@"WARNING[%s] no authorization", __PRETTY_FUNCTION__);
    [response setStatus:401];
    [response setHeader:@"Basic realm=\"SKYRiX\"" forKey:@"www-authenticate"];
    return response;
  }

  { /* search for filemanager */
    NSString *pCode;

    pCode = [_request headerForKey:@"x-skyrix-project-code"];

    if (![pCode isNotNull])
      pCode = nil;
    
    if ([pCode length]) {
      fm = [_session fileManagerForCode:pCode];
    }
  } 

  if (!fm) {
    if ((fm = [_session fileManager]) == nil) {
      [response setStatus:500];
      return response;
    }
  }
  if ((method = [[_request method] uppercaseString]) == nil) {
    NSLog(@"WARNING[%s] missing request method %@", __PRETTY_FUNCTION__,
          _request);
    [response setStatus:500];
    return response;
  }
  
  {
    NSString *className = nil;
    Class    daClass    = Nil;
    
    className = [@"SkyProject_" stringByAppendingString:method];
    
    if ((daClass = NSClassFromString(className)) == nil) {
      NSLog(@"WARNING[%s] missing class for handling method %@",
            __PRETTY_FUNCTION__, method);
      [response setStatus:500];
    }
    else {
      id         handler = nil;
      WOResponse *resp   = nil;

      handler = [[daClass alloc] init];
      resp = [handler handleRequest:_request fileManager:fm];
      RELEASE(handler);
      
      if (resp == nil) {
        NSLog(@"WARNING[%s] missing response from handler %@",
              __PRETTY_FUNCTION__, handler);
        [response setStatus:500];
      }
      else {
        id tmp;

        if ((tmp = [resp headerForKey:@"content-length"]) == nil) {
          NSData *content;

          if ((content = [resp content])) {
            tmp = [NSString stringWithFormat:@"%d", [content length]];
            [resp setHeader:tmp forKey:@"content-length"];
          }
        }
        
        response = resp;
      }
    }
  }
  
  return response;
}

- (LSCommandContext *)_commandContextForAuth:(NSString *)_cred
  inContext:(WOContext *)_ctx
{
  NSString *login = nil;
  NSString *pwd   = nil;
  id       lso    = nil;
  id       ctx    = nil;

  {
    NSRange r;
    r = [_cred rangeOfString:@" " options:NSBackwardsSearch];
    if (r.length == 0) {
      /* invalid _cred */
      NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
      return nil;
    }
  
    _cred = [_cred substringFromIndex:(r.location + r.length)];
    _cred = [_cred stringByDecodingBase64];
    r     = [_cred rangeOfString:@":"];
    login = [_cred substringToIndex:r.location];
    pwd   = [_cred substringFromIndex:r.location + r.length];
  }
  lso = [OGoContextManager defaultManager];
  ctx = [[LSCommandContext alloc] initWithManager:lso];
  
  if ([(LSCommandContext *)ctx login:login password:pwd] == NO) {
    NSLog(@"%s: login %@ was not authorized !", __PRETTY_FUNCTION__, login);
    return nil;
  }
  return ctx;
}

- (WOResponse *)handleRequest:(WORequest *)_request {
  Session       *session   = nil;
  WOApplication *app       = nil;
  WOContext     *context   = nil;
  NSString      *sessionId = nil;
  id            cred       = nil;
  WOResponse    *response  = nil;

  NSAutoreleasePool *pool = nil;

  pool = [[NSAutoreleasePool alloc] init];
  app  = [WOApplication application];
  
  if (logDavRequest == -1) {
    logDavRequest = [[NSUserDefaults standardUserDefaults]
                                      boolForKey:@"LogDAVRequest"] ? 1 : 0;
  }
  if (logDavRequest) {
    if ([[_request content] length] > 0) {
      NSString *s;
      
      s = [[NSString alloc] initWithData:[_request content]
                            encoding:[_request contentEncoding]];
      NSLog(@"DAV Request %@ on %@:\n%@", [_request method], [_request uri],s);
      NSLog(@"headers:\n%@", [_request headers]);
      RELEASE(s);
    }
    else {
      NSLog(@"Empty DAV Request %@ on %@", [_request method], [_request uri]);
      NSLog(@"headers:\n%@", [_request headers]);
    }
  }
  
  if (self->sessionIds4Auth == nil)
    self->sessionIds4Auth = [[NSMutableDictionary alloc] initWithCapacity:64];

  cred = [_request headerForKey:@"authorization"];
  
  if (cred == nil) {
    WOResponse *resp = nil;
    
    resp = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
    [resp setStatus:401 /* unauthorized */];
    [resp setHeader:@"basic realm=\"SKYRiX\"" forKey:@"www-authenticate"];
    return AUTORELEASE(resp);
  }
  
  sessionId = [self->sessionIds4Auth objectForKey:cred];
  
  NS_DURING {
    context = [WOContext contextWithRequest:_request];
    NSAssert(context, @"missing context ..");
    
    [[[NSThread currentThread] threadDictionary]
                setObject:context forKey:@"WOContext"];

    [app awake];

    /* retrieve session */
    [app lock];
    {
      if (sessionId != nil) {
        session = (Session *)[app restoreSessionWithID:sessionId
                                  inContext:context];
      }
      if (session == nil) {
        session = [[Session alloc] init];
        [(id)context setSession:session];
        AUTORELEASE(session);
        [self->sessionIds4Auth setObject:[session sessionID] forKey:cred];
      }
    }
    [app unlock];
    {
      [session awake];
      [session lock];
      
      NS_DURING {
        LSCommandContext *ctx = nil;
        
        if ((ctx = [session commandContext]) == nil) {
          ctx = [self _commandContextForAuth:cred
                      inContext:context];
          [session setCommandContext:ctx];
        }
        response = [self handleRequest:_request
                         session:session
                         commandContext:ctx];
        response = RETAIN(response);
        
      }
      NS_HANDLER {
        fprintf(stderr, "got exception %s\n",
                [[localException description] cString]);
        abort();
        [session unlock];
        [[session commandContext] rollback];
        response = [app handleException:localException inContext:context];
        response = RETAIN(response);
      }
      NS_ENDHANDLER;
      if ([response status] == 500)
        [[session commandContext] rollback];
      
      [session sleep];
      if (session != nil) {
        [app saveSessionForContext:context];
      }
      [session unlock];
    }
    [app sleep];
  }
  NS_HANDLER {
    fprintf(stderr, "got exception %s\n",
            [[localException description] cString]);
    abort();
    response = [app handleException:localException inContext:context];
    response = RETAIN(response);
  }
  NS_ENDHANDLER;
  
  [[[NSThread currentThread] threadDictionary] removeObjectForKey:@"WOContext"];
  RELEASE(pool);
  
  if (logDavResponse == -1) {
    logDavResponse = [[NSUserDefaults standardUserDefaults]
                                      boolForKey:@"LogDAVResponse"] ? 1 : 0;
  }
  if (logDavResponse) {
    NSLog(@"response %i headers: %@",
          [response status],
          [response headers]);
    if ([[response content] length] > 0) {
      NSString *s;
    
      s = [[NSString alloc] initWithData:[response content]
                            encoding:[response contentEncoding]];
      NSLog(@"DAV Response (%i):\n%@\n", [response status], s);
      RELEASE(s);
    }
  }
  
  return AUTORELEASE(response);
}

@end /* SkyP4DocumentRequestHandler */
