
#ifndef __WORequest_WebDAV_H__
#define __WORequest_WebDAV_H__

#include <NGObjWeb/WORequest.h>

@interface WORequest(WebDAVSupport)

- (NSString *)destinationPath;

@end

#endif /* __WORequest_WebDAV_H__ */
