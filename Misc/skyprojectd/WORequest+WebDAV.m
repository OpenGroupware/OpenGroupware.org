// $Id$

#include "WORequest+WebDAV.h"
#include "common.h"

@implementation WORequest(WebDAVSupport)

- (NSString *)_parseDAVPath:(NSString *)_path {
  if ([_path indexOfString:@"http://"] == 0) { /* starts with real url */
    NSString *host     = nil;
    NSString *appPort  = nil;
    int      idxOfPath = 0;
    
    appPort = [[WOApplication port] stringValue];
    
    _path = [_path substringFromIndex:7]; /* remove http */
    
    idxOfPath = [_path indexOfString:@"/"]; /* start of path */
    host      = [_path substringToIndex:idxOfPath];
    _path     = [_path substringFromIndex:idxOfPath];
    
    if ([host indexOfString:[self applicationHost]] != 0 ||
        [host indexOfString:appPort] == NSNotFound) {
      NSLog(@"WARNING: try to edit path for different host _request %@,"
            @"host %@ [WOApplication application] port] stringValue] %@"
            @"[_request applicationHost] %@", self, host,
            [[WOApplication port] stringValue],
            [self applicationHost]);
    }
  }
  {
    char *dest   = NULL;
    char *src    = NULL;
    int  len     = 0;
    int  destLen = 0;
    int  i       = 0;

    len = [_path cStringLength];

    dest = malloc(sizeof(id) * len);
    src  = malloc(sizeof(id) * len);

    [_path getCString:src];
    
    for (i = 0; i < len; i++) {
      if (src[i] != '%')
        dest[destLen++] = src[i];
      else if (i < len - 2) {
        char qp[4];
        char dq[1];

        i++;
        qp[0] = '=';
        qp[1] = src[i++];
        qp[2] = src[i];
        qp[3] = '\0';
        NGDecodeQuotedPrintable(qp, 3, dq, 1);
        dest[destLen++] = dq[0];
      }
    }
    _path = [NSString stringWithCString:dest length:destLen];
    free(dest); dest = NULL;
    free(src);  src  = NULL;
  }
  return _path;
}

- (NSString *)destinationPath {
  return [self _parseDAVPath:[self headerForKey:@"destination"]];
}

@end /* WORequest(WebDAVSupport) */
