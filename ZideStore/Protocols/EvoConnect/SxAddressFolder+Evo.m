// $Id: SxAddressFolder+Evo.m 1 2004-08-20 11:17:52Z znek $

#include <SoObjects/Contacts/SxAddressFolder.h>
#include "SxEvoContactQueryInfo.h"
#include <ZSFrontend/SxMapEnumerator.h>
#include "common.h"

#include <ZSBackend/SxContactManager.h>

@interface SxAddressFolder(Evo)
- (id)performEvoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;
- (id)performEvoSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;
@end

@implementation SxAddressFolder(Evo)

/* Evolution */

- (id)evoRendererInContext:(id)_ctx {
  [self logWithFormat:
	  @"ERROR: subclass needs to override -evoRendererInContext:"];
  return nil; /* subclass */
}

- (NSEnumerator *)runEvoQueryWithContactManager:(SxContactManager *)_cm 
  prefix:(NSString *)_prefix
{
  SxContactSetIdentifier *sid = [self contactSetID];
  if (sid == nil) {
    [self logWithFormat:@"subclass needs to override evo-query method !"];
    return nil;
  }
  return [_cm evoContactsWithPrefix:_prefix inContactSet:[self contactSetID]];
}

- (NSEnumerator *)runEvoQueryWithContactManager:(SxContactManager *)_cm 
  fullsearch:(NSString *)_prefix
{
  return [self runEvoQueryWithContactManager:_cm prefix:_prefix];
}
- (NSEnumerator *)runEvoQueryWithContactManager:(SxContactManager *)_cm 
  emailPrefix:(NSString *)_prefix
{
  return [self runEvoQueryWithContactManager:_cm prefix:_prefix];
}

- (id)performEvoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  SxEvoContactQueryInfo *qInfo;
  SxContactManager *cm;
  NSEnumerator *e;
  
  /* classify request .. */
  
  qInfo = [[[SxEvoContactQueryInfo alloc] initWithFetchSpecification:_fs] 
            autorelease];
  
  /* execute */
  
  cm = [self contactManagerInContext:_ctx];
  
  if ([qInfo isFullSearchQuery]) {
    if ([self doExplainQueries]) {
      [self logWithFormat:@"EXPLAIN:   do a full-search: '%@'", 
              [qInfo fullSearch]];
    }
    e = [self runEvoQueryWithContactManager:cm fullsearch:[qInfo fullSearch]];
  }
  else if ([qInfo isEmailPrefixQuery]) {
    if ([self doExplainQueries]) {
      [self logWithFormat:@"EXPLAIN:   email-prefix: '%@'",
              [qInfo emailPrefix]];
    }
    e = [self runEvoQueryWithContactManager:cm
              emailPrefix:[qInfo emailPrefix]];
  }
  else if ([qInfo isPrefixQuery]) {
    if ([self doExplainQueries])
      [self logWithFormat:@"EXPLAIN:   prefix: '%@'", [qInfo prefix]];
    e = [self runEvoQueryWithContactManager:cm prefix:[qInfo prefix]];
  }
  else if ([qInfo isContactWithEmailQuery]) {
    if ([self doExplainQueries])
      [self logWithFormat:@"EXPLAIN:   fetch contacts with email1"];

    // TODO: implement ...
    e = [self runEvoQueryWithContactManager:cm prefix:nil];
  }
  else {
    if ([self doExplainQueries])
      [self logWithFormat:@"EXPLAIN:   no qualifier, fetch all"];
    e = [self runEvoQueryWithContactManager:cm prefix:nil];
  }
  
  return [SxMapEnumerator enumeratorWithSource:e
			  object:[self evoRendererInContext:_ctx]
			  selector:@selector(renderEntry:)];
}

- (id)performEvoSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // outlookFolderClass, unreadcount, davDisplayName, davHasSubFolders
  // TODO
  [self logWithFormat:@"cannot process subfolder query ..."];
  return [[NSArray array] objectEnumerator];
}

@end /* SxAddressFolder(Evo) */
