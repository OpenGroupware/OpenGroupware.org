
// include OGoContentPage
#include <OGoFoundation/OGoContentPage.h>

@class SkyDBDataSource;

// all OGo page components inherit from OGoContentPage
@interface HelloDB : OGoContentPage
{
  SkyDBDataSource *dataSource;       /* the connection to the DB */
  NSString        *currentTableName; /* the name of the selected table */
}
@end 

#import <Foundation/Foundation.h>
#include <EOControl/EOControl.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoRawDatabase/SkyDBDataSource.h>

@implementation HelloDB

- (id)init {
  if ((self = [super init])) {
    LSCommandContext *cmdctx;
    
    /* find command context (connection to OGo database) */
    cmdctx = [[self session] commandContext];
    
    /* create a new database datasource connected to the OGo DB */
    self->dataSource = [[SkyDBDataSource alloc] initWithContext:(id)cmdctx];
    
    /* set an empty fetch specification in the datasource */
    [self->dataSource setFetchSpecification:
	   [[[EOFetchSpecification alloc] init] autorelease]];
  }
  return self;
}

- (void)dealloc {
  /* properly free objects in the instance variables */
  [self->currentTableName release];
  [self->dataSource       release];
  [super dealloc];
}

/* accessors */

- (void)setCurrentTableName:(NSString *)_name {
  ASSIGNCOPY(self->currentTableName, _name);
}
- (NSString *)currentTableName {
  return self->currentTableName;
}

- (void)setSelectedTableName:(NSString *)_name {
  /*
    Note: this is not possible:
            [[self->dataSource fetchSpecification] setEntityName:_name];
	  because the datasource returns a *copy* of the fetchspec for
	  good reasons.
	  The same is also the reason why we can't "just bind"
	    dataSource.fetchSpecification.entityName
	  in the .wod file.
  */
  EOFetchSpecification *fs;
  
  /* retrieve a copy, modify the copy, set the new copy */
  fs = [self->dataSource fetchSpecification];
  [fs setEntityName:_name];
  [self->dataSource setFetchSpecification:fs];
}
- (NSString *)selectedTableName {
  return [[self->dataSource fetchSpecification] entityName];
}

- (BOOL)hasEntityName {
  /* we can only fetch if we have a 'tablename' set */
#if 1
  return [[self selectedTableName] length] > 0 ? YES : NO;
#else
  return [[[self->dataSource fetchSpecification] entityName] length] > 0
    ? YES : NO;
#endif
}

- (EODataSource *)dataSource {
  return self->dataSource;
}

@end /* HelloDB */
