
#ifndef SKYRIX_SKYLDAP_LDAPPERSONVIEWER_H
#define SKYRIX_SKYLDAP_LDAPPERSONVIEWER_H

#include <OGoFoundation/OGoContentPage.h>

@class LdapPersonDocument;
@class NSString;

@interface LdapPersonViewer : OGoContentPage 
{
@protected
  LdapPersonDocument *person;
  NSString           *viewerTitle;
  NSString           *tabKey;
}

- (void)setPerson:(LdapPersonDocument *)_person;
- (LdapPersonDocument *)person;

- (id)back;
- (id)edit;

- (BOOL)isEditEnabled;

@end

#endif /* SKYRIX_SKYLDAP_LDAPPERSONVIEWER_H */
