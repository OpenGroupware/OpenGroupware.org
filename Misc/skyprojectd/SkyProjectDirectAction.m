
#include "WORequest+WebDAV.h"
#include "common.h"

@interface SkyProject_MKCOL : NSObject
@end /* SkyProject_MKCOL */

@interface SkyProject_DELETE : NSObject
@end /* SkyProject_DELETE */

@interface SkyProject_COPY : NSObject
@end /* SkyProject_COPY */

@interface SkyProject_MOVE : NSObject
@end /* SkyProject_MOVE */

@interface SkyProject_OPTIONS : NSObject
@end /* SkyProject_OPTIONS */

@interface SkyProject_POST : NSObject
@end /* SkyProject_POST */

@implementation SkyProject_MKCOL

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
    [response setStatus:404];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:NULL] == YES) {
    NSLog(@"WARNING[%s] file/directory already exist %@",
          __PRETTY_FUNCTION__, path);
    [response setStatus:405];
    return response;
  }
  if ([_fm createDirectoryAtPath:path attributes:nil] == NO) {
    [response setStatus:500];
    return response;
  }
  [response setStatus:201];
  return response;
}
@end /* SkyProject_MKCOL */


@implementation SkyProject_DELETE
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
    [response setStatus:404];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:NULL] == NO) {
    NSLog(@"WARNING[%s] missing file at path %@ to delete",
          __PRETTY_FUNCTION__, path);
    [response setStatus:424];
    return response;
  }
  if ([_fm removeFileAtPath:path handler:nil] == NO) {
    [response setStatus:500];
    return response;
  }
  [response setStatus:204];
  return response;
}
@end /* SkyProject_DELETE */

@implementation SkyProject_COPY
- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  NSString   *path     = nil;
  NSString   *destPath = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  path = [_request uri];
  path = [path stringByUnescapingURL];

  destPath = [_request destinationPath];
  
  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path", __PRETTY_FUNCTION__);
    [response setStatus:409];
    return response;
  }
  if ([destPath length] == 0) {
    NSLog(@"WARNING[%s] missing dest-path", __PRETTY_FUNCTION__);
    [response setStatus:409];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:NULL] == NO) {
    NSLog(@"WARNING[%s] missing file at path %@ to copy", __PRETTY_FUNCTION__,
          path);
    [response setStatus:409];
    return response;
  }
  if ([_fm fileExistsAtPath:destPath isDirectory:NULL] == YES) {
    NSLog(@"WARNING[%s] destination already exist %@ ",
          __PRETTY_FUNCTION__, destPath);
    [response setStatus:409];
    return response;
  }
  if ([_fm copyPath:path toPath:destPath handler:nil] == NO) {
    [response setStatus:500];
    return response;
  }
  [response setStatus:201];
  return response;
}
@end /* SkyProject_COPY */

@implementation SkyProject_MOVE
- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  NSString   *path     = nil;
  NSString   *destPath = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  path = [_request uri];
  path = [path stringByUnescapingURL];

  destPath = [_request destinationPath];
  
  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path", __PRETTY_FUNCTION__);
    [response setStatus:409];
    return response;
  }
  if ([destPath length] == 0) {
    NSLog(@"WARNING[%s] missing dest-path", __PRETTY_FUNCTION__);
    [response setStatus:409];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:NULL] == NO) {
    NSLog(@"WARNING[%s] missing file at path %@ to copy",
          __PRETTY_FUNCTION__, path);
    [response setStatus:409];
    return response;
  }
  if ([_fm fileExistsAtPath:destPath isDirectory:NULL] == YES) {
    NSLog(@"WARNING[%s] destination already exist %@ ",
          __PRETTY_FUNCTION__, destPath);
    [response setStatus:409];
    return response;
  }
  if ([_fm movePath:path toPath:destPath handler:nil] == NO) {
    [response setStatus:500];
    return response;
  }
  [response setStatus:201];
  return response;
}
@end /* SkyProject_MOVE */

@implementation SkyProject_OPTIONS

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  [response setHeader:@"0" forKey:@"content-length"];
  [response setHeader:@"OPTIONS, GET, PUT, POST, HEAD, DELETE, PROPFIND, COPY"
                      @", MOVE"
            forKey:@"Allow"];
  [response setHeader:@"SKYRiX skyprojectd DAV/1.0.2"
            forKey:@"Server"];
  [response setHeader:@"DAV" forKey:@"MS-Author-Via"];
  [response setStatus:200];
  return response;
}

@end /* SkyProject_OPTIONS */

@implementation SkyProject_POST

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  [response setStatus:409];
  return response;
}

@end /* SkyProject_POST */
