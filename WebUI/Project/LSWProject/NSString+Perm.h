// $Id$

#ifndef __LSWProject_NSString_Perm_H__
#define __LSWProject_NSString_Perm_H__

#import <Foundation/NSString.h>

@class NSMutableDictionary;

@interface NSString(Perm)

/* this turns: 'rwx' into {r:YES,w:YES,x:YES} */
- (NSMutableDictionary *)splitAccessPermissionString;

@end

#endif /* __LSWProject_NSString_Perm_H__ */
