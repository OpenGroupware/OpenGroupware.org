
#include "common.h"
#include "NGFileManager+DAV.h"

@interface SkyProject_GET : NSObject
@end /* SkyProject_GET */

@implementation SkyProject_GET

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response = nil;
  BOOL       isDir     = NO;
  NSString   *path     = nil;

  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);

  path = [_request uri];
  path = [path stringByUnescapingURL];

  if ([path length] == 0) {
    NSLog(@"WARNING[%s] missing path", __PRETTY_FUNCTION__);
    [response setStatus:404];
    return response;
  }
  if ([_fm fileExistsAtPath:path isDirectory:&isDir] == YES) {
    NSData *data = nil;
    if (isDir == YES) { /* data for browser */
      id       agent  = nil;
      NSString *agStr = nil;

      if ((agStr = [_request headerForKey:@"user-agent"]) != nil) {
        agent = [[NGHttpUserAgent alloc] initWithString:agStr];

        if ([agent isMozilla] == YES || [agent isInternetExplorer] == YES) {
          NSEnumerator    *enumerator = nil;
          NSString        *file       = nil;
          NSMutableString *content    = nil;
          NSData          *data       = nil;
          NSString        *url        = nil;
          NSMutableArray  *dirC       = nil;
          int             i           = 0;
          int             cnt         = 0;

          url     = [_request valueForKey:@"x-webobjects-server-url"];
          content = [[NSMutableString alloc] initWithCapacity:512];
          [content appendString:@"<HTML><BODY><TABLE>\n"];
          dirC    = [[_fm directoryContentsAtPath:path] mutableCopy];
          [dirC sortUsingSelector:@selector(compare:)];

          /* . */
          [content appendString:@"<TR><TD><A HREF=\""];
          [content appendString:url];
          [content appendString:path];
          [content appendString:@"\">"];
          [content appendString:@"."];
          [content appendString:@"</A>"];
          [content appendString:@"</TD></TR>\n"];

          /* .. */
          [content appendString:@"<TR><TD><A HREF=\""];
          [content appendString:url];
          [content appendString:[path stringByDeletingLastPathComponent]];
          [content appendString:@"\">"];
          [content appendString:@".."];
          [content appendString:@"</A>"];
          [content appendString:@"</TD></TR>\n"];

          cnt = [dirC count]; 
          for (i = 0; i < cnt; i++) {
            NSString *subDir  = nil;
            BOOL     isSubDir = YES;

            subDir = [dirC objectAtIndex:i];
            
            if ([_fm fileExistsAtPath:subDir isDirectory:&isSubDir] == YES) {
              if (isSubDir == YES) {
                [content appendString:@"<TR><TD>"];
                [content appendString:@"<A HREF=\""];
                [content appendString:url];
                [content appendString:
                         [path stringByAppendingPathComponent:subDir]];
                [content appendString:@"\">"];
                [content appendString:subDir];
                [content appendString:@"\\</A>"];
                [content appendString:@"</TD></TR>\n"];
                [dirC removeObjectAtIndex:i];
                cnt--; i--;
              }
            }
          }
          enumerator = [dirC objectEnumerator];
          while ((file = [enumerator nextObject])) {
            [content appendString:@"<TR><TD>"];
            [content appendString:@"<A HREF=\""];
            [content appendString:url];
            [content appendString:[path stringByAppendingPathComponent:file]];
            [content appendString:@"\">"];
            [content appendString:file];
            [content appendString:@"</A>"];
            [content appendString:@"</TD></TR>\n"];
          }
          [content appendString:@"</TABLE></BODY></HTML>\n"];
          data = [content dataUsingEncoding:[NSString defaultCStringEncoding]];
          [response setContent:data];
          [response setStatus:200];
          [response setHeader:@"text/html" forKey:@"content-type"];
          [response setHeader:[[NSNumber numberWithInt:[content length]]
                                         stringValue]
                    forKey:@"content-length"];
          RELEASE(content); content = nil;
          RELEASE(dirC);    dirC    = nil;
        }
        else
          [response setStatus:501];
      }
      else
        [response setStatus:501];
    }
    else if ((data = [_fm contentsAtPath:path]) != nil) {
      NSDictionary *attrs    = nil;
      NGMimeType   *mimeType = nil;
      NSNumber     *length   = nil;
        
      [response setStatus:200];
      [response setContent:data];
      attrs = [_fm fileAttributesAtPath:path traverseLink:YES];
      if ((mimeType = [attrs valueForKey:@"NSFileMimeType"]))
        [response setHeader:[mimeType stringValue]
                  forKey:@"content-type"];
      if ((length = [attrs valueForKey:@"NSFileSize"]))
        [response setHeader:[length stringValue] forKey:@"content-length"];
      [response setHeader:@"0" forKey:@"ETag"];
    }
  }
  else {
    NSLog(@"WARNING[%s] missing file at path %@", __PRETTY_FUNCTION__, path);
    [response setStatus:404];
  }
  return response;
}

@end /* SkyProject_GET */
