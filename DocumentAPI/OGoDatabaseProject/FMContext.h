// $Id$

#ifndef __OGoDatabaseProject_FMContext_H__
#define __OGoDatabaseProject_FMContext_H__

#import <Foundation/NSObject.h>

@class NSNumber, NSDictionary;

@interface FMContext : NSObject<SkyProjectFileManagerContext>
{
  id           getAttachmentNameCommand;
  id           context;
  NSDictionary *personCache;
}

- (id)initWithContext:(id)_ctx;

- (NSString *)accountLogin4PersonId:(NSNumber *)_personId;

- (id)commandContext;
- (id)getAttachmentNameCommand;
- (void)setGetAttachmentNameCommand:(id)_id;

@end

#endif /* __OGoDatabaseProject_FMContext_H__ */
