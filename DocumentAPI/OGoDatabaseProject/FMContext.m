// $Id$

#include "SkyProjectDocumentDataSource.h"
#include "SkyProjectFileManager.h"
#include <OGoProject/SkyProjectDataSource.h>
#include "FMContext.h"
#include "common.h"

@implementation FMContext

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    self->context = [_ctx retain];
  }
  return self;
}

- (void)dealloc {
  [self->getAttachmentNameCommand release];
  [self->context     release];
  [self->personCache release];
  [super dealloc];
}

/* processing */

- (NSString *)accountLogin4PersonId:(NSNumber *)_personId {
  NSDictionary *dict;
  NSString     *result;
  
  if ((dict = self->personCache) == nil) {  
    static NSArray *personAttrs = nil;

    NSMutableDictionary *mdict;
    EOAdaptorChannel    *channel;
    EOSQLQualifier      *qualifier;
    EOEntity            *entity;
    NSDictionary        *row;
    BOOL                commitTransaction;
    

    entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                               entityNamed:@"Person"];
    if (personAttrs == nil) {
      personAttrs = [[NSArray alloc]
                              initWithObjects:
                              [entity attributeNamed:@"companyId"],
                              [entity attributeNamed:@"login"], nil];
    }
    if (![self->context isTransactionInProgress]) {
      commitTransaction = YES;
      [self->context begin];
    }
    else {
      commitTransaction = NO;
    }
    channel = [[self->context valueForKey:LSDatabaseChannelKey]
                              adaptorChannel];

    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A = %@",
                                        @"isPerson",
                                        [NSNumber numberWithBool:YES],nil];

    if (![channel selectAttributes:personAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, personAttrs);
      [self->context rollback];
      return nil;
    }
    mdict = [[NSMutableDictionary alloc] initWithCapacity:255];
    while ((row = [channel fetchAttributes:personAttrs withZone:NULL])) {
      NSString *l;
      NSNumber *cid;

      cid = [row valueForKey:@"companyId"];
      
      if (![cid isNotNull]) {
        NSLog(@"ERROR[%s]: missing companyId for account ...",
              __PRETTY_FUNCTION__);
        continue;
      }
      if (![l = [row valueForKey:@"login"] isNotNull])
        l = [cid stringValue];
      
      [mdict setObject:l forKey:cid];
    }
    dict = [[mdict copy] autorelease];
    [mdict     release]; mdict     = nil;
    [qualifier release]; qualifier = nil;

    ASSIGN(self->personCache, dict);
    //    [self takeCacheValue:dict forKey:PersonId2LoginCache_key];
    
    if (commitTransaction)
      [self->context commit];
  }
  if ((result = [dict objectForKey:_personId]) == nil) { 
    /* missing login, take key */
    result = [_personId stringValue];
  }
  return result;
}
- (id)commandContext {
  return self->context;
}
- (id)getAttachmentNameCommand {
  return self->getAttachmentNameCommand;
}
- (void)setGetAttachmentNameCommand:(id)_getCmd {
  ASSIGN(self->getAttachmentNameCommand, _getCmd);
}

- (id)docToProjectCache {
  return [self->context valueForKey:@"docToProjectCache"];
}
- (void)setDocToProjectCache:(id)_obj {
  [self->context takeValue:_obj forKey:@"docToProjectCache"];
}

@end /* FMContext */
