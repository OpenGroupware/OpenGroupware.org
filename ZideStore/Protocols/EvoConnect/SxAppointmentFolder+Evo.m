// $Id: SxAppointmentFolder+Evo.m 1 2004-08-20 11:17:52Z znek $

#include <SoObjects/Appointments/SxAppointmentFolder.h>
#include "SxEvoAptQueryInfo.h"
#include "common.h"
#include <ZSBackend/SxAptManager.h>

@interface SxAppointmentFolder(UsedPrivates)
- (SxAptManager *)aptManagerInContext:(id)_ctx;
- (NSString *)uidForPrimaryKey:(id)_pkey url:(NSString *)_url;
@end

@implementation SxAppointmentFolder(Evo)

- (id)performDavUidAndModDateQuery:(EOFetchSpecification *)_fs 
  inContext:(id)_ctx 
{
  SxEvoAptQueryInfo *qinfo;
  NSCalendarDate *startDate = nil;
  NSCalendarDate *endDate   = nil;
  NSArray        *dateInfos;
  NSMutableArray *result;
  unsigned i, count;
  NSString *folderURL, *ext;
  
  qinfo =
    [[[SxEvoAptQueryInfo alloc] initWithFetchSpecification:_fs] autorelease];
  if (qinfo == nil) {
    [self logWithFormat:@"could not analyze qualifier .."];
    return nil;
  }
  
  startDate = [qinfo startDate];
  endDate   = [qinfo endDate];
  if (startDate == nil || endDate == nil) {
    /* could not process qualifier */
    [self logWithFormat:@"UNKNOWN QUAL: %@", [_fs qualifier]];
    return nil;
  }
  
  /* start query */
  
  [self debugWithFormat:@"from: %@", startDate];
  [self debugWithFormat:@"to:   %@", endDate];
  
  dateInfos = [[self aptManagerInContext:_ctx]
                     pkeysAndModDatesOfSet:[self aptSetID]
	             from:startDate to:endDate];
  //[self logWithFormat:@"date-infos: %@", dateInfos];
  if ([self doExplainQueries]) {
    [self logWithFormat:@"EXPLAIN: processing %i infos for group %@ ...",
            [dateInfos count], [self group]];
  }
  
  /* process results */
    
  folderURL = [self baseURLInContext:_ctx];
  if (![folderURL hasSuffix:@"/"])
    folderURL = [folderURL stringByAppendingString:@"/"];
  ext = [self fileExtensionForChildrenInContext:_ctx];
    
  count  = [dateInfos count];
  result = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSDictionary  *values;
    NSString *entryName, *url;
    NSString *uid;
    id lastModified;
    NSString *keys[4];
    id  vals[4];
    int p;
    
    values = [dateInfos objectAtIndex:i];
    //[self logWithFormat:@"date-info: %@", values];
      
    uid = [[values objectForKey:@"pkey"] stringValue];
    lastModified = [[values objectForKey:@"lastmodified"] exDavDateValue];
    
    /* morph global-id to URL */
      
    entryName = uid;
    if (ext) {
      entryName = [entryName stringByAppendingString:@"."];
      entryName = [entryName stringByAppendingString:ext];
    }
    url = [folderURL stringByAppendingString:entryName];
    if (url == nil) {
      [self logWithFormat:@"could not process id: %@", uid];
      continue;
    }
    
    /* create entry */
    p = 0;
    keys[p] = @"davUid"; vals[p] = [self uidForPrimaryKey:uid url:url]; p++;
    keys[p] = @"{DAV:}href"; vals[p] = url; p++;
    if (lastModified) {
      keys[p] = @"davLastModified"; vals[p] = lastModified; p++;
    }
    
    values = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
    [result addObject:values];
    [values release];
  }
  return result;
}

@end /* SxAppointmentFolder(Evo) */
