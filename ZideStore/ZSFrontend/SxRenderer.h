// $Id: SxRenderer.h 1 2004-08-20 11:17:52Z znek $

#ifndef __ZideStore_SxRenderer_H__
#define __ZideStore_SxRenderer_H__

/*
  SxRenderer

  Informal protocol for renderer objects for rendering ZideStore objects
  to external representations (eg to a WebDAV record).
*/

@interface NSObject(SxRenderer)
- (id)renderEntry:(id)_entry;
@end

#endif /* __ZideStore_SxRenderer_H__ */
