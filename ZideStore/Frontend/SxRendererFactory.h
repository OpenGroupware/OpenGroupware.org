// $Id$

#ifndef __ZideStore_SxRendererFactory_H__
#define __ZideStore_SxRendererFactory_H__

#import <Foundation/NSObject.h>

/*
  SxRendererFactory
  
  Informal protocol for factories able to create renderer objects
  for rendering records into external representations.
*/

@class NSString;

@interface NSObject(RendererFactory)
- (id)rendererWithFolder:(id)_folder inContext:(id)_ctx;
- (id)rendererWithContext:(id)_ctx baseURL:(NSString *)_url;
@end

#endif /* __ZideStore_SxRendererFactory_H__ */
