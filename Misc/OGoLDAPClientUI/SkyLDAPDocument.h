// $Id$

#ifndef SKYRIX_SKYLDAP_SKYLDAPDOCUMENT_H
#define SKYRIX_SKYLDAP_SKYLDAPDOCUMENT_H

#include <OGoDocuments/SkyDocument.h>

@class NSDictionary, NSMutableDictionary;
@class NSString;
@class SkyLDAPDataSource;
@class EOGlobalID, EODataSource;

@interface SkyLDAPDocument : SkyDocument < SkyDocumentEditing >
{
@protected
  EOGlobalID          *globalID;
  SkyLDAPDataSource   *dataSource;
  NSDictionary        *record;
  NSMutableDictionary *newAttrs;
  NSMutableDictionary *updatedAttrs;
  NSMutableDictionary *removedAttrs;
  NSString            *dn;
}

//+ (id)documentWithDN:(NSString *)_dn newDocument:(BOOL)_new; // ?
//- (id)initWithDN:(NSString *)_dn newDocument:(BOOL)_new; // ?

- (id)initWithGlobalID:(EOGlobalID *)_gid record:(NSDictionary *)_record
  dataSource:(SkyLDAPDataSource *)_ds;

+ (Class)dataSourceClass;
- (SkyLDAPDataSource *)dataSource;

- (NSString *)dn;
- (NSDictionary *)record; // Data used/got during last save/load.

- (EOGlobalID *)globalID;

- (BOOL)isReadable; // Protocol: SkyDocumentEditing.
- (BOOL)isWriteable;
- (BOOL)isRemovable;
- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)load; // no protocol member
- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;

- (void)invalidate;

- (BOOL)isEqual:(id)_obj;
- (BOOL)isEqualToLDAPDocument:(SkyLDAPDocument *)_doc;

- (id)valueForKey:(id)_key;
- (void)takeValue:(id)_value forKey:(id)_key;

- (NSString *)description;

@end // SkyLDAPDocument.

#endif /* SKYRIX_SKYLDAP_SKYLDAPDOCUMENT_H */
