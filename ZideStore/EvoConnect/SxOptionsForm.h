// $Id$

#ifndef __Frontend_SxOptionsForm_H__
#define __Frontend_SxOptionsForm_H__

#import <Foundation/NSObject.h>

@interface SxOptionsForm : NSObject
{
  NSString *name;
  id       container;
}

- (id)initWithName:(NSString *)_name inContainer:(id)_folder;

@end

#endif /* __Frontend_SxOptionsForm_H__ */
