// $Id$

#ifndef __SkyTransactionHandler_H__
#define __SkyTransactionHandler_H__

#import <Foundation/NSObject.h>

@interface SkyTransactionHandler : NSObject
{
  NSString      *path;
  NSFileManager *fm;
}

- (id)init;
- (id)initWithPath:(NSString *)_path;
- (void)dealloc;
- (NSString *)commitFile;
- (NSString *)transactionFile;
- (BOOL)isObjectInserted:(int)_objId;
- (void)beginInsert:(int)_objId;
- (void)commitInsert:(int)_objId;
- (void)rollbackIds;
- (NSArray *)failedIds;
@end /* SkyTransactionHandler */

#endif /* __SkyTransactionHandler_H__ */
