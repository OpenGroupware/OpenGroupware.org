// $Id$

#include <OGoFoundation/OGoContentPage.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <NGExtensions/EOCacheDataSource.h>

#include "common.h"
#include "LdapPersonDocument.h"
#include "LdapPersonEditor.h"
#include "LdapPersonViewer.h"

@implementation LdapPersonEditor

#if 0
- (id)initWithDN:(NSString *)_dn {
  if ((self = [super init])) {
    self->person = [[LdapPersonDocument documentWithDN:_dn
                                        newDocument:NO] retain];
  }
  return self;
}
#endif

- (void)dealloc {
  [self->person release];
  [super dealloc];
}

// Accessors.

- (void)setPerson:(LdapPersonDocument *)_person {
  ASSIGN(self->person, _person);
}
- (LdapPersonDocument *)person {
  return self->person;
}

- (id)back {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (NSString *)fullName {
  return [NSString stringWithFormat:@"%@ %@",
                   [self->person valueForKey:@"givenName"],
                   [self->person valueForKey:@"sn"]];
}

- (NSString *)firstName {
  NSLog(@"%s fn = %@", __PRETTY_FUNCTION__,
        [self->person valueForKey:@"givenName"]);
  return [self->person valueForKey:@"givenName"];
}
- (void)setFirstName:(NSString *)_str {
  NSLog(@"%s fn = %@", __PRETTY_FUNCTION__, _str);

  [self->person takeValue:([_str length] ? _str : nil) forKey:@"givenName"];
}

- (NSString *)lastName {
  return [self->person valueForKey:@"sn"];
}
- (void)setLastName:(NSString *)_str {
  [self->person takeValue:([_str length] ? _str : nil) forKey:@"sn"];
}

- (NSString *)email {
  return [self->person valueForKey:@"mail"];
}
- (void)setEmail:(NSString *)_str {
  [self->person takeValue:([_str length] ? _str : nil) forKey:@"mail"];
}

- (id)save {
  LdapPersonViewer *page = nil;

  NSLog(@"%s person = %@", __PRETTY_FUNCTION__, self->person);

  [self->person save];

  page = (id)[self pageWithName:@"LdapPersonViewer"];

  [page setPerson:self->person];

  return page;
}

@end /* LdapPersonEditor */
