// $Id$

#ifndef __WebKitTest2_SOPEXWebConnection_H__
#define __WebKitTest2_SOPEXWebConnection_H__

#import <Foundation/NSObject.h>

@class NSURL, NSString, NSData, NSBundle;
@class NSURLResponse;

@interface SOPEXWebConnection : NSObject 
{
    NSURL    *url;
    NSString *sessionID;
    NSBundle *localResourceBundle;
    NSMutableDictionary *resourceCache;
    NSString *appPrefix;
}

- (id)initWithURL:(id)_url localResourceBundle:(NSBundle *)_resourceBundle;

    /* accessors */

- (NSURL *)url;
- (NSString *)sessionID;

    /* operations */

- (void)processResponse:(NSURLResponse *)_r data:(NSData *)_data;

- (BOOL)shouldRewriteRequestURL:(NSURL *)_url;
- (NSURL *)rewriteRequestURL:(NSURL *)_url;

@end

#endif /* __WebKitTest2_SOPEXWebConnection_H__*/
