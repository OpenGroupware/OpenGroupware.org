
#include "common.h"
#include "NGFileManager+DAV.h"

@interface SkyProject_HEAD : NSObject
@end /* SkyProject_HEAD */

@implementation SkyProject_HEAD

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse   *response = nil;
  BOOL         isDir     = NO;
  NSString     *path     = nil;
  NSDictionary *attrs    = nil;
  NGMimeType   *mimeType = nil;
  NSNumber     *length   = nil;
  
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  
  path = [_request uri];
  path = [path stringByUnescapingURL];
  
  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path (uri=%@)", __PRETTY_FUNCTION__,
          [_request uri]);
    [response setStatus:404 /* not found */];
    return response;
  }

  if (![_fm fileExistsAtPath:path isDirectory:&isDir]) {
    [response setStatus:404 /* not found */];
    return response;
  }
  
  if (isDir == YES) {
    NSLog(@"WARNING[%s] got HEAD action for directory '%@'",
          __PRETTY_FUNCTION__, path);
    [response setStatus:501];
    return response;
  }
  
  if ((attrs = [_fm fileAttributesAtPath:path traverseLink:YES]) == nil) {
    NSLog(@"WARNING[%s] did not get attributes for path '%@'",
          __PRETTY_FUNCTION__, path);
    [response setStatus:501];
    return response;
  }
  
  [response setStatus:200];
  
  if ((mimeType = [attrs valueForKey:@"NSFileMimeType"]))
    [response setHeader:[mimeType stringValue] forKey:@"content-type"];
  
  if ((length = [attrs valueForKey:@"NSFileSize"]))
    [response setHeader:[length stringValue] forKey:@"content-length"];
  
  [response setHeader:@"0" forKey:@"ETag"];
  return response;
}

@end /* SkyProject_HEAD */
