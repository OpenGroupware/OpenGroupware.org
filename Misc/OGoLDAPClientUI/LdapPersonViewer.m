
#include <OGoFoundation/OGoContentPage.h>
#include <NGLdap/NGLdap.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <NGExtensions/EOCacheDataSource.h>
#include <OGoFoundation/OGoSession.h>
#include "common.h"
#include "LdapPersonViewer.h"
#include "LdapPersonDocument.h"

@implementation LdapPersonViewer

- (void)dealloc {
  RELEASE(self->person);
  RELEASE(self->viewerTitle);
  RELEASE(self->tabKey);
  [super dealloc];
}

/* Accessors */

- (NSString *)viewerTitle {
  if (! self->viewerTitle) {
    NSMutableString *str = nil;

    str = [NSMutableString stringWithCapacity:128];

    // The name of the person.

    [str appendString:[self->person valueForKey:@"sn"]];
    if ([[self->person valueForKey:@"givenName"] length] > 0) {
      [str appendString:@", "];
      [str appendString:[self->person valueForKey:@"givenName"]];
    }

    // Add private info.

    if ([[self->person valueForKey:@"isPrivate"] boolValue]) {
      [str appendString:@" ("];
      [str appendString:[[self labels] valueForKey:@"private"]];
      [str appendString:@")"];
    }

    // Add read-only info.

    if ([[self->person valueForKey:@"isReadonly"] boolValue]) {
      [str appendString:@" ("];
      [str appendString:[[self labels] valueForKey:@"readonly"]];
      [str appendString:@")"];
    }

    ASSIGN(self->viewerTitle, str);
  }

  return self->viewerTitle;
}

- (void)setPerson:(LdapPersonDocument *)_person {
  ASSIGN(self->person, _person);
}
- (LdapPersonDocument *)person {
  return self->person;
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (id)back {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)edit {
  LdapPersonViewer *page = nil;

  page = (id)[self pageWithName:@"LdapPersonEditor"];

  [page setPerson:self->person];

  return page;
}

- (BOOL)isEditEnabled {
  if ([(OGoSession *)[self session] activeAccountIsRoot])
    return YES;

  if ([[self->person valueForKey:@"uid"] isEqualToString:
                                  [(OGoSession *)[self session] activeLogin]])
    return YES;

  return NO;
}

@end /* LdapPersonViewer */
