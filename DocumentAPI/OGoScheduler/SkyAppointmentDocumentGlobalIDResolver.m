// $Id$

#include "SkyAppointmentDataSource.h"
#include "common.h"

@implementation SkyAppointmentDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Date"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyAppointmentDataSource *ds;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [[SkyAppointmentDataSource alloc] initWithContext:[_dm context]];
  if (ds == nil)
    return nil;

  {
    EOFetchSpecification *fSpec  = nil;
    NSDictionary         *hints  = nil;
    NSArray              *result = nil;

    hints = [NSDictionary dictionaryWithObjectsAndKeys:_gids,@"fetchGIDs",nil];
    fSpec = [[EOFetchSpecification alloc] init];
    [fSpec setHints:hints];
    [ds setFetchSpecification:fSpec];
    result = [ds fetchObjects];
    [fSpec release];
    [ds release];
    
    return result;
  }
}

@end /* SkyAppointmentDocumentGlobalIDResolver */
