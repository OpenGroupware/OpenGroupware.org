
#include <OGoFoundation/OGoContentPage.h>

@class NSString;
@class EOFetchSpecification, EOCacheDataSource, EOQualifier;
@class LdapPersonDataSource, LdapPersonDocument;

@interface LdapViewerPanel: OGoContentPage 
{
  EOCacheDataSource  *dataSource;
  LdapPersonDocument *document;
  NSString           *searchInput;
  NSString           *searchFirstNameInput;
  NSString           *searchLastNameInput;
  NSString           *tabKey;
  BOOL               hideTree;
}

- (WOComponent *)searchAction;
- (WOComponent *)fileManagerSelectAction;
- (EOFetchSpecification *)fetchSpecification;

@end

#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <NGExtensions/EOCacheDataSource.h>
#include "common.h"
#include "LdapPersonDataSource.h"
#include "LdapPersonDocument.h"

@implementation LdapViewerPanel

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults       *ud     = nil;
    LdapPersonDataSource *ds     = nil;
    id                   account = nil;

    hideTree = NO;
    account = [(OGoSession *)[self session] activeAccount];

#if 0
    NSLog(@"%s aln = %@", __PRETTY_FUNCTION__,
          [(OGoSession *)[self session] activeLogin]);
    NSLog(@"%s log = %@", __PRETTY_FUNCTION__,
          [account valueForKey:@"login"]);
    NSLog(@"%s pas = %@", __PRETTY_FUNCTION__,
          [account valueForKey:@"password"]);
#endif

    ud = [NSUserDefaults standardUserDefaults];
    //ds = [[LdapPersonDataSource alloc] init]; // anonymous.
#if 0 /* auth using OGo account */
    ds = [[LdapPersonDataSource alloc]
                                initWithUID:[account valueForKey:@"login"]
                                credentials:@"gma611"]; 
#else /* auth using a configured account */
    ds = [[LdapPersonDataSource alloc]
           initWithUID:[ud stringForKey:@"LdapViewer_User"]
           credentials:[ud stringForKey:@"LdapViewer_Password"]];
#endif
    //[account valueForKey:@"password"]];
#if 0  /* geht nicht mit cache?? */
    if (ds) {
      self->dataSource = [[EOCacheDataSource alloc] initWithDataSource:ds];

      RELEASE(ds); ds = nil;
    }
#endif
    self->dataSource = (id)ds;
    self->tabKey = @"personSearch";
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->document);
  RELEASE(self->searchInput);
  RELEASE(self->searchFirstNameInput);
  RELEASE(self->searchLastNameInput);
  RELEASE(self->tabKey);

  [super dealloc];
}

/* Accessors */

- (void)setDataSource:(EODataSource *)_dataSource {
  ASSIGN(self->dataSource, _dataSource);
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setDocument:(id)_doc {
  ASSIGN(self->document, _doc);
}
- (id)document {
  return self->document;
}

- (void)setSearchInput:(NSString *)_text {
  ASSIGN(self->searchInput, _text);
}
- (NSString *)searchInput {
  return self->searchInput;
}

- (void)setSearchFirstNameInput:(NSString *)_text {
  ASSIGN(self->searchFirstNameInput, _text);
}
- (NSString *)searchFirstNameInput {
  return self->searchFirstNameInput;
}

- (void)setSearchLastNameInput:(NSString *)_text {
  ASSIGN(self->searchLastNameInput, _text);
}
- (NSString *)searchLastNameInput {
  return self->searchLastNameInput;
}

- (BOOL)hideTree {
  return self->hideTree;
}

- (id)doHideTree {
  self->hideTree = YES;
  return nil;
}

- (id)doShowTree {
  self->hideTree = NO;
  return nil;
}

- (BOOL)showFolderForm {
  return YES;
}

- (BOOL)showFolderContent {
  return YES;
}

- (id)back {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

// Actions.

- (WOComponent *)mainTabClicked {
  return [self searchAction];
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fspec;

  fspec = [[self->dataSource fetchSpecification] copy];
  
  if (fspec == nil)
    fspec = [[EOFetchSpecification alloc] init];

  return AUTORELEASE(fspec);
}

- (WOComponent *)searchAction {
  EOFetchSpecification *spec = [self fetchSpecification];
  EOQualifier          *qual = nil;
  NSString             *s    = nil;
  NSString             *fn   = nil;
  NSString             *ln   = nil;
  LdapPersonDataSource *ds   = nil;

  s = self->searchInput;
  if (s == nil) s = @"";
  fn = self->searchFirstNameInput;
  if (fn == nil) fn = @"";
  ln = self->searchLastNameInput;
  if (ln == nil) ln = @"";

  //NSLog(@"%s search for %@", __PRETTY_FUNCTION__, s);

  if ([self->tabKey isEqualToString:@"advancedSearch"])
    qual = [EOQualifier qualifierWithQualifierFormat:
             [NSString stringWithFormat:
                       @"givenName like '*%@*' AND sn like '*%@*'",
                       fn, ln]];
  else // personSearch
    qual = [EOQualifier qualifierWithQualifierFormat:
             [NSString stringWithFormat:
                       @"cn like '*%@*' OR sn like '*%@*' OR "
                       @"givenName like '*%@*' OR uid like '*%@*'",
                       s, s, s, s]];

  [spec setQualifier:qual];
  ds = (LdapPersonDataSource *)self->dataSource; // ... source];
  [ds setFetchSpecification:spec];
  //[self->dataSource clear];

  return nil;
}

- (WOComponent *)fileManagerSelectAction {
  return nil;
}

@end /* LdapViewerPanel */
