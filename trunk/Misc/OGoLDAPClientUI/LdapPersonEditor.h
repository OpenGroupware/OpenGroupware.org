
#include <OGoFoundation/OGoContentPage.h>

@class EOCacheDataSource;
@class NSString;
@class NSMutableDictionary;
@class LdapPersonDocument;

@interface LdapPersonEditor: OGoContentPage 
{
  LdapPersonDocument *person;

  BOOL addressesCollapsibleOpened;
  BOOL personCollapsibleOpened;
}

//- (id)initWithDN:(NSString *)_dn;

- (void)setPerson:(LdapPersonDocument *)_person;
- (LdapPersonDocument *)person;

- (NSString *)fullName;

- (NSString *)firstName;
- (void)setFirstName:(NSString *)_str;

- (NSString *)lastName;
- (void)setLastName:(NSString *)_str;

- (NSString *)email;
- (void)setEmail:(NSString *)_str;

- (id)save;
- (id)back;

@end // LdapPersonEditor.
