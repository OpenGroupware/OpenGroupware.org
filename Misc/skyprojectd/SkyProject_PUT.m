// $Id$

#include "common.h"
#include "NGFileManager+DAV.h"

@interface SkyProject_PUT : NSObject
@end /* SkyProject_PUT */

@implementation SkyProject_PUT

- (BOOL)checkoutOnDemand {
  return YES;
}

- (int)createFileForRequest:(WORequest *)_request
  atPath:(NSString *)_path
  fileManager:(SkyProjectFileManager *)_fm
{
  BOOL   ok;
  NSData *content;
  
  if ((content = [_request content]) == nil) {
    [self logWithFormat:@"request has no content ?!"];
    return 500;
  }
  [self logWithFormat:@"creating file %@ size %i", _path, [content length]];
  
  ok = [_fm createFileAtPath:_path contents:content attributes:nil];
  
  if (!ok) {
    /* TODO: better error handling ... */
    return 403 /* forbidden */;
  }
  return 201 /* created */;
}

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  BOOL       isDir     = NO;
  BOOL       exist     = NO;
  NSString   *path     = nil;

  response = [[(WOResponse *)[WOResponse alloc] initWithRequest:_request] 
               autorelease];
  
  path = [[_request uri] stringByUnescapingURL];
  
  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path", __PRETTY_FUNCTION__);
    [response setStatus:409 /* conflict */];
    return response;
  }
  
  if ((exist = [_fm fileExistsAtPath:path isDirectory:&isDir])) {
    if (isDir) {
      NSLog(@"ERROR[%s] try to write dir atPath :%@", __PRETTY_FUNCTION__,
            path);
      [response setStatus:403 /* forbidden */];
      return response;
    }
    
    if (![[_request headerForKey:@"user-agent"]
                    isEqualToString:@"SKYRiX-FileManager"]) {
      NSDictionary *attrs;

      // TODO: why doesn't that use -isFileLockedAtPath: ?
      attrs = [_fm fileAttributesAtPath:path traverseLink:NO];
      if ([[attrs valueForKey:@"SkyStatus"]
                  isEqualToString:@"edited"] == YES) {
        /* work on a checked out file */
      }
      else if ([self checkoutOnDemand]) {
        [self logWithFormat:@"on-demand checkout: %@", path];
        
        // TODO: add error handler
        if (![_fm checkoutFileAtPath:path handler:nil]) {
          [self logWithFormat:@"ERROR: could not checkout file: %@", path];
          [response setStatus:403 /* forbidden */];
          return response;
        }
      }
      else {
        NSLog(@"ERROR[%s] file is not checked out: %@",
              __PRETTY_FUNCTION__, path);
        [response setStatus:403 /* forbidden */];
        return response;
      }
    }
    
    if (![_fm writeContents:[_request content] atPath:path handler:nil]) {
      /* eg can fail, if we didn't checkout the file ... */
      
      NSLog(@"ERROR[%s] writeContents atPath:%@ failed", __PRETTY_FUNCTION__,
            path);
      [response setStatus:500 /* server error */];
      return response;
    }
    
    [response setStatus:204 /* no content */];
  }
  else {
    /* create a new file */
    int code;
    
    code = [self createFileForRequest:_request atPath:path fileManager:_fm];
    [response setStatus:code];
  }
  
  return response;
}

@end /* SkyProject_PUT */
