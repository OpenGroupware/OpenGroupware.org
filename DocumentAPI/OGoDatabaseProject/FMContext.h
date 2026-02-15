
#ifndef __OGoDatabaseProject_FMContext_H__
#define __OGoDatabaseProject_FMContext_H__

#import <Foundation/NSObject.h>

/**
 * @class FMContext
 * @brief Implements SkyProjectFileManagerContext for
 *        the database-backed project file manager.
 *
 * Wraps an LSCommandContext and provides helper
 * services used by SkyProjectFileManager, notably
 * resolving person IDs to account login names via a
 * cached database lookup.
 *
 * Also stores and forwards the attachment name command
 * and maintains a document-to-project cache on the
 * underlying command context.
 *
 * @see SkyProjectFileManager
 * @see SkyProjectFileManagerContext
 */

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
