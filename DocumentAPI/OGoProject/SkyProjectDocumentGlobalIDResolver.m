
#include "SkyProjectDataSource.h"
#include "SkyProject.h"
#include "common.h"

@interface SkyProjectDataSource(UsedPrivates)
- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids;
@end

@implementation SkyProjectDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];
  
  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Project"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyProjectDataSource *ds;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [[[SkyProjectDataSource alloc] initWithContext:[_dm context]] 
	 autorelease];
  
  return [ds _fetchObjectsForGlobalIDs:_gids];
}

@end /* SkyProjectDocumentGlobalIDResolver */
