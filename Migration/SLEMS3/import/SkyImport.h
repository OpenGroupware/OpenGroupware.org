// $Id$

#ifndef __SkyImport_H__
#define __SkyImport_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSFileManager;
@class SkyTransactionHandler, SkyUidHandler;

@interface SkyImport : NSObject
{
  BOOL                  isChild;
  id                    commandContext;
  NSString              *login;
  NSString              *pwd;
  NSFileManager         *fm;
  SkyTransactionHandler *transactionHandler;
  SkyUidHandler         *uidHandler;
}

- (id)init;
- (id)initWithLogin:(NSString *)_login pwd:(NSString *)_pwd;

- (id)commandContext;
- (NSArray *)objects;

- (int)insertObjectInterval;

- (BOOL)handleObjectImport:(id)_obj;
- (BOOL)handleObjectIntervalImport:(NSArray *)_objs;

- (BOOL)importObjects:(NSArray *)_objs;
- (BOOL)import;

- (int)verifyObject:(id)_obj;

- (Class)uidHandlerClass;

@end /* SkyImport */

#import <Foundation/NSDictionary.h>

@interface NSDictionary(SkyImport)

- (NSArray *)arrayForKey:(id)_key;

@end /* NSDictionary(SkyImport) */

#endif /* __SkyImport_H__ */
