
#include "common.h"
#include "NGFileManager+DAV.h"

@interface SkyProject_LOCK : NSObject
@end /* SkyProject_LOCK */

@interface SkyProject_UNLOCK : NSObject
@end /* SkyProject_UNLOCK */

@implementation SkyProject_LOCK
- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse   *response = nil;
  NSString     *path     = nil;
  NSString     *tmp      = nil;
  NSDictionary *attrs    = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  path = [_request uri];
  path = [path stringByUnescapingURL];

  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path", __PRETTY_FUNCTION__);
    [response setStatus:409];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:NULL] == NO) {
    NSLog(@"WARNING[%s] missing file at path %@ to lock", __PRETTY_FUNCTION__,
          path);
    [response setStatus:412];
    return response;
  }
  attrs = [_fm fileAttributesAtPath:path traverseLink:NO];

  if ([_fm isFileLockedAtPath:path] == YES) {
    if ([_fm isWritableFileAtPath:path] == NO) {
      [response setStatus:409];
      return response;
    }
  }
  else {
    if ((tmp = [_request headerForKey:@"timeout"]) != nil) {
      if ([tmp indexOfString:@"Second-"] == 0) {
        int            i   = 0;
        NSString       *si = nil;

        si = [tmp substringFromIndex:7];
        if (sscanf([si cString],"%d", &i) == 1) {
          NSTimeInterval ti  = 0;

          ti = (NSTimeInterval)i;
          if ([_fm lockFileAtPath:path timeout:ti] == NO) {
            NSLog(@"WARNING[%s] couldn`t lock path %@ for timeout %d",
                  __PRETTY_FUNCTION__, path, ti);
            [response setStatus:423];
            return response;
          }
        }
        else {
          NSLog(@"WARNING[%s] couldn`t get format for %@ ",
                __PRETTY_FUNCTION__, tmp);
          [response setStatus:423];
          return response;
        }
      }
      else if ([tmp indexOfString:@"Infinite"] == 0) {
        if ([_fm lockFileAtPath:path handler:NULL] == NO) {
          NSLog(@"WARNING[%s] couldn`t lock path %@ ",
                __PRETTY_FUNCTION__, path);
          [response setStatus:423];
          return response;
        }
      }
    }      
    else if ([_fm lockFileAtPath:path handler:NULL] == NO) {
      NSLog(@"WARNING[%s] couldn`t lock path %@ ", __PRETTY_FUNCTION__, path);
      [response setStatus:423];
      return response;
    }
  }
  {
    NSString *content = nil;

    content = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      @"<D:prop xmlns:D=\"DAV:\">\n"
      @"<D:lockdiscovery>\n"
      @"<D:activelock>\n"
      @"<D:locktype><D:write/></D:locktype>\n"
      @"</D:activelock>\n"
      @"</D:lockdiscovery>\n"
      @"</D:prop>\n";
    [response setContent:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [response setHeader:@"text/xml; charset=\"utf-8\"" forKey:@"content-type"];
    [response setHeader:[[NSNumber numberWithInt:[content length]] stringValue]
              forKey:@"content-length"];
  }
  [response setStatus:200];
  return response;
}
@end /* SkyProject_LOCK */

@implementation SkyProject_UNLOCK
- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  NSString   *path     = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  path = [_request uri];
  path = [path stringByUnescapingURL];

  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path", __PRETTY_FUNCTION__);
    [response setStatus:409];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:NULL] == NO) {
    NSLog(@"WARNING[%s] missing file at path %@ to unlock",
          __PRETTY_FUNCTION__, path);
    [response setStatus:412];
    return response;
  }
  if ([_fm isFileLockedAtPath:path] == YES) {
    if ([_fm unlockFileAtPath:path handler:NULL] == NO) {
      NSLog(@"WARNING[%s] couldn`t unlock path %@ ", __PRETTY_FUNCTION__, path);
      [response setStatus:409];
      return response;
    }
  }
  [response setStatus:200];
  return response;
}
@end /* SkyProject_UNLOCK */
