/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmDateDataSource.h>
#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoPalm/SkyPalmMemoDocument.h>
#include <OGoPalm/SkyPalmJobDocument.h>
#include <OGoPalm/SkyPalmConstants.h>

@interface SkyPalmJobDataSource : SkyPalmEntryDataSource
{}
@end

@interface SkyPalmJobGlobalIDResolver : SkyPalmDocumentGlobalIDResolver
{}
@end

@interface SkyPalmAddressDataSource : SkyPalmEntryDataSource
{}
@end

@interface SkyPalmAddressGlobalIDResolver : SkyPalmDocumentGlobalIDResolver
{}
@end

@interface SkyPalmMemoDataSource : SkyPalmEntryDataSource
{}
@end

@interface SkyPalmMemoGlobalIDResolver : SkyPalmDocumentGlobalIDResolver
{}
@end

@interface SkyPalmDateGlobalIDResolver : SkyPalmDocumentGlobalIDResolver
{}
@end


@interface SkyPalmEntryDataSource(PrivatMethods)
- (EOFetchSpecification *)defaultFetchSpec;
- (void)_insertDictionary:(id)_obj;
- (void)postDataSourceChangedNotification;
- (EOFetchSpecification *)fetchSpecification;
@end

@interface NSObject(SkyPalmEntryDataSource)
- (int)palmId;
@end

#include <OGoPalm/SkyPalmCategoryDataSource.h>
#include "common.h"

@interface EODataSource(SetFS)
- (void)setFetchSpecification:(EOFetchSpecification *)_fspec;
@end

@implementation SkyPalmEntryDataSource

static NSArray *dbs = nil;
static NSMutableDictionary *devicesCache = nil;

+ (void)initialize {
  dbs = [[NSArray alloc] initWithObjects:
                             @"AddressDB", @"DatebookDB",
                             @"MemoDB", @"ToDoDB", nil];
  devicesCache = [[NSMutableDictionary alloc] initWithCapacity:16];
}

+ (SkyPalmEntryDataSource *)dataSourceWithContext:(LSCommandContext *)_ctx
  forPalmDb:(NSString *)_palmDb
{
  id d;
  
  if ([_palmDb isEqualToString:@"AddressDB"])
    d = [[SkyPalmAddressDataSource alloc] initWithContext:_ctx];
  else if ([_palmDb isEqualToString:@"DatebookDB"])
    d = [[SkyPalmDateDataSource alloc] initWithContext:_ctx];
  else if ([_palmDb isEqualToString:@"MemoDB"])
    d = [[SkyPalmMemoDataSource alloc] initWithContext:_ctx];
  else if ([_palmDb isEqualToString:@"ToDoDB"])
    d = [[SkyPalmJobDataSource alloc] initWithContext:_ctx];
  else {
    NGBundleManager *bm;
    EOQualifier     *q;
    NSBundle        *bundle;

    bm = [NGBundleManager defaultBundleManager];
    q  = [EOQualifier qualifierWithQualifierFormat:
                      @"palmDb=%@", _palmDb];
    bundle = [bm bundleProvidingResourceOfType:@"SkyPalmDataSources"
                 matchingQualifier:q];
    if (bundle != nil) {
      if (![bundle load]) {
        NSLog(@"%s: failed to load bundle: %@", __PRETTY_FUNCTION__, bundle);
        return nil;
      }
      {
        id resources, resource, cname;
        resources = [bundle providedResourcesOfType:@"SkyPalmDataSources"];
        resources = [resources filteredArrayUsingQualifier:q];
        resource  = [resources lastObject];

        cname = [resource valueForKey:@"skyrixDataSource"];
        if ([cname length])
          d = [[NSClassFromString(cname) alloc] initWithContext:_ctx];
        else {
          NSLog(@"%s invalid class for palmDb: %@",
                __PRETTY_FUNCTION__, _palmDb);
          return nil;
        }
      }
    }
    else {
      NSLog(@"%s didn't find skyrixDataSource for palmDb: %@",
            __PRETTY_FUNCTION__, _palmDb);
      return nil;
    }
  }
  [d setFetchSpecification:[d defaultFetchSpec]];
  return AUTORELEASE(d);
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if ((self = [super init])) {
    self->ds = [[SkyAdaptorDataSource alloc] initWithContext:_ctx];
    
    self->categoryDataSource =
      [SkyPalmCategoryDataSource dataSourceWithContext:_ctx
                                 forPalmTable:[self palmDb]];
    RETAIN(self->categoryDataSource);

    ASSIGN(self->context,_ctx);
    self->sortOrderings = nil;
  }
  return self;
}

- (void)dealloc {
  [self->categoryDataSource release];
  [self->context        release];
  [self->ds             release];
  [self->sortOrderings  release];
  [self->devicesForUser release];
  [super dealloc];
}

/* default accessors */

- (NSString *)entityName {
  [self logWithFormat:@"ERROR(%s): subclass MUST override this method.",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)palmDb {
  [self logWithFormat:@"ERROR(%s): subclass MUST override this method.",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (SkyPalmDocument *)allocDocument {
  [self logWithFormat:@"ERROR(%s): subclass MUST override this method.",
	  __PRETTY_FUNCTION__];
  return [SkyPalmDocument alloc];
}
- (NSDictionary *)_bulkFetchSkyrixRecords:(NSArray *)_docs {
  [self logWithFormat:@"ERROR(%s): subclass MUST override this method.",
	  __PRETTY_FUNCTION__];
  return [NSDictionary dictionary];
}

// sortOrderings
- (void)setSortOrderings:(NSArray *)_so {
  ASSIGN(self->sortOrderings,_so);
}
- (NSArray *)sortOrderings {
  return self->sortOrderings;
}
- (void)_setFetchSpecification:(EOFetchSpecification *)_spec {
  // no overwriting
  if ([_spec isEqual:[self fetchSpecification]])
    return;

  [self setSortOrderings:[_spec sortOrderings]];
  [_spec setSortOrderings:nil];
   
  [self->ds setFetchSpecification:_spec];
  [self postDataSourceChangedNotification];
}
- (void)setFetchSpecification:(EOFetchSpecification *)_spec {
  [self _setFetchSpecification:_spec];
}
- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *spec;

  spec = [self->ds fetchSpecification];
  [spec setSortOrderings:self->sortOrderings];
  return spec;
}

- (EOFetchSpecification *)defaultFetchSpec {
  EOQualifier *qual;
  
  qual = [EOQualifier qualifierWithQualifierFormat:
                        @"company_id=%@", [self companyId]];
  return [EOFetchSpecification fetchSpecificationWithEntityName:
                               [self entityName]
                               qualifier:qual sortOrderings:nil];
}

- (void)setDefaultDevice:(NSString *)_dev {
  [super setDefaultDevice:_dev];
  [self->categoryDataSource setDefaultDevice:_dev];
}
- (NSString *)defaultDevice {
  NSString *dev = [super defaultDevice];
  if (dev == nil)
    return [[[self devices] objectEnumerator] nextObject];
  return dev;
}

/* fetching objects */

- (void)assignCategories:(NSArray *)_objs {
  [self->categoryDataSource assignCategoriesToDocuments:_objs
       ofTable:[self palmDb]];
}

- (NSArray *)_fetchDictionarys {
  return [self->ds fetchObjects];
}
- (NSArray *)fetchObjects {
  NSArray        *objs;
  NSMutableArray *docs;
  id             one   = nil;
  BOOL           fetchCats = YES;
  BOOL           fetchSkyRecs = NO;
  unsigned int i, cnt;

  objs = [self _fetchDictionarys];
  cnt  = [objs count];
  docs = [NSMutableArray arrayWithCapacity:cnt+1];

  for (i = 0; i < cnt; i++) {
    one = [objs objectAtIndex:i];
    [docs addObject:[self documentForObject:one]];
  }

  {
    NSDictionary *hints;
    id tmp;
    
    hints = [[self fetchSpecification] hints];
    if ((tmp = [hints valueForKey:@"fetchCategories"]) != nil)
      fetchCats = [tmp boolValue];
    if ((tmp = [hints valueForKey:@"fetchSkyrixRecords"]) != nil)
      fetchSkyRecs = [tmp boolValue];
  }
  
  if (fetchCats)
    [self assignCategories:docs];

  if (fetchSkyRecs) {
    /* bulk fetch skyrix records */
    NSDictionary *skyrixRecordMap;
    id skyId, skyRec;

    //NSLog(@"%s bulk fetching skyrix records for %d palm entries",
    //      __PRETTY_FUNCTION__, [docs count]);
    
    skyrixRecordMap = [self _bulkFetchSkyrixRecords:docs];
    cnt = [docs count];
    for (i = 0; i < cnt; i++) {
      one   = [docs objectAtIndex:i];
      skyId = [one skyrixId];
      if ([skyId intValue] > 1000) {
        skyRec = [skyrixRecordMap valueForKey:skyId];
        if ([skyRec isNotNull]) {
          [one _bulkFetch_setSkyrixRecord:skyRec];
        }
        else {
	  // ogo entry not found -> delete palm entry
	  [one setSkyrixId:0];
	  [one setSyncType:SYNC_TYPE_DO_NOTHING];
	  [one delete];
          //NSLog(@"%s[%@]: bulk fetch for skyrix-id '%@' failed",
          //      __PRETTY_FUNCTION__, [self palmDb], skyId);
        }
      }
    }
  }
  
  if (self->sortOrderings != nil)
    return [docs sortedArrayUsingKeyOrderArray:self->sortOrderings];
  
  return docs;
}

- (id)currentAccount {
  return [self->context valueForKey:LSAccountKey];
}
- (NSNumber *)companyId {
  return [[self currentAccount] valueForKey:@"companyId"];
}
- (NSString *)primaryKey {
  return [[self entityName] stringByAppendingString:@"_id"];
}
- (id)context {
  return self->context;
}
- (id)fetchDictionaryForDocument:(SkyPalmDocument *)_doc {
  SkyPalmEntryDataSource *das       = nil;
  NSString               *query     = nil;
  EOQualifier            *qual      = nil;
  NSNumber               *companyId = nil;
  NSNumber               *pKey      = nil;

  pKey      = [[[_doc globalID] keyValuesArray] objectAtIndex:0];
  das       = [SkyPalmEntryDataSource dataSourceWithContext:self->context
                                      forPalmDb:[self palmDb]];
  query     = [NSString stringWithFormat:@"(company_id=%%@) AND (%@=%%@)",
                        [self primaryKey]];
  companyId = [self companyId];
  qual = [EOQualifier qualifierWithQualifierFormat:query,
                      companyId, pKey];
  [das setFetchSpecification:
       [EOFetchSpecification fetchSpecificationWithEntityName:
                             [self entityName]
                             qualifier:qual sortOrderings:nil]];
  return [[das _fetchDictionarys] lastObject];
}

- (void)_insertDictionary:(id)_obj {
  if ([self fetchSpecification] == nil)
    [self setFetchSpecification:[self defaultFetchSpec]];
  
  [_obj setObject:[self companyId] forKey:@"company_id"];
  [self->ds insertObject:_obj];
}

- (void)insertObject:(id)_doc {
  id dict = [_doc asDictionary];
  [self _insertDictionary:dict];
  [_doc updateSource:dict fromDataSource:self];
  [self postDataSourceChangedNotification];
}

- (void)_updateDictionary:(id)_obj {
  if ([self fetchSpecification] == nil) {
    [self setFetchSpecification:[self defaultFetchSpec]];
  }

  [_obj setObject:[self companyId] forKey:@"company_id"];
  [_obj setObject:
        [[[_obj valueForKey:@"globalID"] keyValuesArray] objectAtIndex:0]
        forKey:[self primaryKey]];

  [self->ds updateObject:_obj];
}
- (void)updateObject:(id)_doc {
  id dict = [_doc asDictionary];
  [self _updateDictionary:dict];
  //  [_doc updateSource:dict fromDataSource:self];
  [self postDataSourceChangedNotification];
}
- (void)_deleteDictionary:(id)_obj {
  [self->ds deleteObject:_obj];
}
- (void)deleteObject:(SkyPalmDocument *)_doc {
  [self _deleteDictionary:[_doc asDictionary]];
  [self postDataSourceChangedNotification];
}

// accessors

- (SkyPalmDocument *)newDocument {
  SkyPalmDocument *doc = [super newDocument];

  [self->categoryDataSource setDefaultDevice:[self defaultDevice]];
  [doc takeValue:[self->categoryDataSource unfiledCategory]
       forKey:@"category"];
  return doc;
}

// devices
- (EOFetchSpecification *)_deviceFetchSpecForCompany:(NSNumber *)_compId
  dataSource:(SkyPalmEntryDataSource *)_ds {
  EOQualifier *qual;

  qual = [EOQualifier qualifierWithQualifierFormat:@"company_id = %@",
                      _compId];

  return [EOFetchSpecification fetchSpecificationWithEntityName:
                               [_ds entityName]
                               qualifier:qual sortOrderings:nil];
}

- (NSArray *)devicesForUser:(NSNumber *)_compId palmDb:(NSString *)_palmDb {
  NSEnumerator   *e;
  NSMutableArray *devs;
  id             dev;
  SkyPalmEntryDataSource *das;
  NSMutableDictionary  *hints;
  EOFetchSpecification *fetchSpec;
  
  devs = [NSMutableArray arrayWithCapacity:4];
  das = [SkyPalmEntryDataSource dataSourceWithContext:self->context
				forPalmDb:_palmDb];

  /* setup fetch spec */
  
  fetchSpec = [self _deviceFetchSpecForCompany:_compId dataSource:das];
  hints     = [[fetchSpec hints] mutableCopy];
  if (hints == nil)
    hints = [[NSMutableDictionary alloc] initWithCapacity:1];
  [hints setObject:[NSNumber numberWithBool:NO] forKey:@"fetchCategories"];
  [fetchSpec setHints:hints];
  [hints release]; hints = nil;
  
  [das setFetchSpecification:fetchSpec];
  
  /* fetch */
  
  e = [[das fetchObjects] objectEnumerator];
  while ((dev = [e nextObject])) {
    dev = [dev deviceId];
    if (![devs containsObject:dev])
      [devs addObject:dev];
  }
  return devs;
}
- (NSArray *)devicesForUser:(NSNumber *)_compId {
  NSArray *devs = nil;
  NSArray *array;
  
  if (_compId == nil)
    return [NSArray array];
  
  if ((array = [self->devicesForUser objectForKey:_compId]) != nil)
    return array;

  /*
    TODO:
    might be a problem for multipalm possibilities
    has to be checked!!!!
    but for now it's in here for speed enhancement
  */

  if (self->devicesForUser == nil)
    self->devicesForUser = [[NSMutableDictionary alloc] initWithCapacity:64];
    
  devs = [devicesCache valueForKey:[_compId stringValue]];
  if (devs != nil) return devs;
  
  devs = [self devicesForUser:_compId palmDb:[self palmDb]];
  if ((devs == nil) || ([devs count] == 0)) {
    NSEnumerator *e;
    id           one;
    
    e  = [dbs objectEnumerator];
    while ((one = [e nextObject]) != nil) {
      if (![one isEqualToString:[self palmDb]]) {
	devs = [self devicesForUser:_compId palmDb:one];
	if ((devs != nil) && ([devs count] > 0))
	  break;
      }
    }
      
    if ((devs == nil) || ([devs count] == 0)) {
      [self logWithFormat:
	      @"WARNING(%s): no valid deviceIds in the palm entities "
              @"(%@) for current user!",
              __PRETTY_FUNCTION__, [dbs componentsJoinedByString:@", "]];
      // no valid devices found for user
      return nil;
    }
  }
  
  [devicesCache setObject:devs forKey:_compId];
  
  array = devs;
  [self->devicesForUser setObject:array forKey:_compId];
  return array;
}
- (NSArray *)devices {
  return [self devicesForUser:[self companyId]];
}


// categories
- (EOFetchSpecification *)_categoryFetchSpecForDevice:(NSString *)_devId {
  EOQualifier *qual   = nil;
  NSString    *compId = nil;
  NSString    *device = nil;

  compId = [[self companyId] stringValue];
  device = _devId;
  qual = 
    [EOQualifier qualifierWithQualifierFormat:
                 @"company_id=%@ AND palm_table=%@ AND device_id=%@",
                 compId, [self palmDb], device];
  return [EOFetchSpecification fetchSpecificationWithEntityName:
                               @"palm_category"
                               qualifier:qual sortOrderings:nil];
}

- (NSArray *)categoriesForDevice:(NSString *)_dev {
  NSArray                   *cats  = nil;
  SkyPalmCategoryDataSource *catDs = nil;

  catDs =
    [SkyPalmCategoryDataSource dataSourceWithContext:self->context
                               forPalmTable:[self palmDb]];
  [catDs setDefaultDevice:_dev];
  [catDs setFetchSpecification:[self _categoryFetchSpecForDevice:_dev]];

  cats = [catDs fetchObjects];
  return cats;
}

// saving categories

- (void)_deleteCategoriesForDevice:(NSString *)_dev {
  NSEnumerator *e  = [[self categoriesForDevice:_dev] objectEnumerator];
  id           one = nil;

  while ((one = [e nextObject])) {
    [one delete];
  }
}

- (NSArray *)saveCategories:(NSArray *)_cats
                  forDevice:(NSString *)_dev
{
  NSEnumerator        *e    = [_cats objectEnumerator];
  NSMutableDictionary *dict = nil;
  id                  one   = nil;
  NSMutableArray      *all  = [NSMutableArray array];

  [self _deleteCategoriesForDevice:_dev];

  while ((one = [e nextObject])) {
    dict = [one asDictionary];
    
    [dict removeObjectForKey:@"globalID"];
    [dict removeObjectForKey:@"palm_category_id"];
    
    [dict takeValue:[self palmDb] forKey:@"palm_table"];
    [dict takeValue:_dev          forKey:@"device_id"];

    one = [(SkyPalmCategoryDataSource *)self->categoryDataSource
                                        newDocument];
    [one updateSource:dict fromDataSource:self->categoryDataSource];
    [one setIsModified:NO];

    [one saveWithoutReset];
    [all addObject:one];
  }

  return all;
}



- (EOFetchSpecification *)fetchSpecForIds:(NSArray *)_ids {
  NSString    *query     = nil;
  EOQualifier *qual      = nil;
  NSNumber    *companyId = nil;
  NSString    *pKeys     = nil;

  pKeys = [NSString stringWithFormat:@" OR %@=", [self primaryKey]];
  pKeys = [_ids componentsJoinedByString:pKeys];
  query = [NSString stringWithFormat:@"company_id=%%@ AND (%@=%%@)",
                        [self primaryKey]];
  companyId = [self companyId];
  
  qual  = [EOQualifier qualifierWithQualifierFormat:query,
                       companyId, pKeys];

  return [EOFetchSpecification fetchSpecificationWithEntityName:
                               [self entityName]
                               qualifier:qual sortOrderings:nil];
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  NSMutableArray      *ids;
  EOKeyGlobalID       *gid;
  unsigned i, max;

  if ((max = [_gids count]) == 0) return [NSArray array];
  
  ids = [[NSMutableArray alloc] initWithCapacity:[_gids count]];
  for (i = 0; i < max; i++) {
    gid  = [_gids objectAtIndex:i];
    [ids addObject:[gid keyValues][0]];
  }
  [self setFetchSpecification:[self fetchSpecForIds:ids]];
  RELEASE(ids);

  return [self fetchObjects];
}

// ogo sync
/*
  returns all available skyrix ids (primary key values) of ogo entries
  that are assigned to palm entries of this datasource
*/
- (NSArray *)assignedSkyrixIdsForDeviceId:(NSString *)_deviceId {
  /* qualifier
     SELECT DISTINCT skyrix_id
     FROM <palm_table>
     WHERE company_id = <user_id> AND skyrix_id > 0 AND
       is_deleted = 0 AND is_archived = 0 AND device_id = <device_id>
  */
  NSString *palmTable;
  id       userId;

  NSString         *qualifier;
  EOAdaptorChannel *channel = nil;

  NSMutableArray *assignedIds;
  id res;

  palmTable = [self entityName];
  userId    = [[[self context] valueForKey:LSAccountKey]
                      valueForKey:@"companyId"];

  channel = [[[self context]
                    valueForKey:LSDatabaseChannelKey] adaptorChannel];

  qualifier =
    [NSString stringWithFormat:
              @"SELECT DISTINCT skyrix_id "
              @"FROM %@ "
              @"WHERE "
              @"company_id = %@ AND "
              @"skyrix_id > 0 AND "
              @"is_deleted = 0 AND "
              @"is_archived = 0 AND "
              @"device_id = '%@'",
              palmTable, userId, _deviceId];

  assignedIds = [NSMutableArray arrayWithCapacity:64];
  [channel evaluateExpression:qualifier];
  while ((res = [channel fetchAttributes:[channel describeResults]
                         withZone:NULL]))
    {
      // adaptor makes skyrix_id -> skyrixId
      res = [res valueForKey:@"skyrixId"];
      if (res != nil) [assignedIds addObject:res];
    }

  return assignedIds;
}


@end /* SkyPalmEntryDataSource */

#include <OGoContacts/SkyCompanyDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>

@implementation SkyPalmAddressDataSource
- (NSString *)entityName {
  return @"palm_address";
}
- (NSString *)palmDb {
  return @"AddressDB";
}
- (SkyPalmDocument *)allocDocument {
  return [SkyPalmAddressDocument alloc];
}

- (EOFetchSpecification *)fetchSpecForSkyrixRecordIds:(NSArray *)_skyIds
                                           entityName:(NSString *)_entity
{
  EOQualifier *qual = nil;

  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"companyId=%@", _skyIds];
  return [EOFetchSpecification fetchSpecificationWithEntityName:_entity
                               qualifier:qual
                               sortOrderings:nil];
}


- (NSDictionary *)_bulkFetchSkyrixRecords:(NSArray *)_palmRecords {
  NSMutableArray         *personIds;
  NSMutableArray         *enterpriseIds;
  unsigned int           i, cnt;
  SkyPalmAddressDocument *doc;
  SkyCompanyDocument     *skyDoc;  
  id                     skyId;
  NSString               *type;
  EODataSource           *cds;
  NSMutableDictionary    *result;
  NSArray                *companies;
  
  cnt           = [_palmRecords count];
  personIds     = [[NSMutableArray alloc] initWithCapacity:(cnt + 1)];
  enterpriseIds = [[NSMutableArray alloc] initWithCapacity:(cnt + 1)];

  /* get person and enterprise ids */
  // TODO: move to own method
  for (i = 0; i < cnt ; i++) {
    doc = [_palmRecords objectAtIndex:i];
    skyId = [doc skyrixId];
    if ([skyId intValue] > 1000) {
      type = [doc skyrixType];
      
      if ([type isEqualToString:@"person"])
        [personIds addObject:skyId];
      else if ([type isEqualToString:@"enterprise"])
        [enterpriseIds addObject:skyId];
      else {
        NSLog(@"WARNING(%s): unknown OGo entity: %@",
              __PRETTY_FUNCTION__, type);
      }
    }
  }
  
  result = [NSMutableDictionary dictionaryWithCapacity:
                                  ([personIds count]+[enterpriseIds count]+1)];
  
  /* persons */
  // TODO: move to own method
  cds = [[SkyPersonDataSource alloc] initWithContext:[self context]];
  [cds setFetchSpecification:[self fetchSpecForSkyrixRecordIds:personIds
                                   entityName:@"Person"]];
  companies = [[[cds fetchObjects] retain] autorelease];
  [cds release];
  
  for (i = 0, cnt = [companies count]; i < cnt; i++) {
    skyDoc = [companies objectAtIndex:i];
    skyId  = [skyDoc globalID];
    skyId  = [(EOKeyGlobalID *)skyId keyValues][0];
    if (![skyId isKindOfClass:[NSNumber class]])
      skyId = [NSNumber numberWithInt:[skyId intValue]];
    [result setObject:skyDoc forKey:skyId];
  }

  /* enterprises */
  // TODO: move to own method
  cds =
    [[SkyEnterpriseDataSource alloc] initWithContext:[self context]];
  [cds setFetchSpecification:[self fetchSpecForSkyrixRecordIds:enterpriseIds
                                   entityName:@"Enterprise"]];
  companies = [cds fetchObjects];
  [cds release];
  cnt = [companies count];
  for (i = 0; i < cnt; i++) {
    skyDoc = [companies objectAtIndex:i];
    skyId  = [skyDoc globalID];
    skyId  = [(EOKeyGlobalID *)skyId keyValues][0];
    if (![skyId isKindOfClass:[NSNumber class]])
      skyId = [NSNumber numberWithInt:[skyId intValue]];
    [result setObject:skyDoc forKey:skyId];
  }

  [personIds     release];
  [enterpriseIds release];

  return result;
}

@end /* SkyPalmAddressDataSource */

#include <OGoJobs/SkyPersonJobDataSource.h>
#include <OGoJobs/SkyJobDocument.h>

@implementation SkyPalmJobDataSource

static EOQualifier *toDoJobTypeQualifier = nil;

+ (void)initialize {
  if (toDoJobTypeQualifier == nil) {
    toDoJobTypeQualifier = 
      [[EOKeyValueQualifier alloc] initWithKey:@"type"
                                   operatorSelector:EOQualifierOperatorEqual
                                   value:@"toDoJob"];
  }
}

- (NSString *)entityName {
  return @"palm_todo";
}
- (NSString *)palmDb {
  return @"ToDoDB";
}
- (SkyPalmDocument *)allocDocument {
  return [SkyPalmJobDocument alloc];
}

- (EOFetchSpecification *)_fetchSpecForSkyrixJobIDs:(NSArray *)_ids {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"job"
                               qualifier:toDoJobTypeQualifier 
                               sortOrderings:nil];
}
- (id)_qualifyAfterFetch:(NSArray *)_fetched ids:(NSArray *)_ids {
  unsigned int   i, cnt;
  id             one   = nil;
  EOKeyGlobalID  *gid  = nil;
  NSNumber       *pKey = nil;
  NSMutableArray *result;

  cnt    = [_fetched count];
  result = [NSMutableArray arrayWithCapacity:(cnt + 1)];

  for (i = 0; i < cnt; i++) {
    one = [_fetched objectAtIndex:i];
    gid  = [one globalID];
    pKey = [gid keyValues][0];
    if (([_ids containsObject:pKey]))
      [result addObject:one];
  }
  return result;
}

- (NSArray *)fetchSkyrixRecordsForIDs:(NSArray *)_ids {
  EOGlobalID             *personId;
  SkyPersonJobDataSource *jds;
  NSArray                *skyJobs  = nil;

  personId = [[self currentAccount] valueForKey:@"globalID"];
  
  jds = [[SkyPersonJobDataSource alloc] initWithContext:[self context]
                                        personId:personId];
  [jds setFetchSpecification:[self _fetchSpecForSkyrixJobIDs:_ids]];
  
  skyJobs = [[self _qualifyAfterFetch:[jds fetchObjects] ids:_ids] retain];
  [jds release];

  return [skyJobs autorelease];
}

- (NSDictionary *)_bulkFetchSkyrixRecords:(NSArray *)_palmRecords {
  NSMutableArray      *jobIds;
  SkyPalmJobDocument  *doc;
  NSArray             *skyJobs;
  SkyJobDocument      *skyDoc;
  NSMutableDictionary *docMap;
  unsigned int i, cnt;
  id skyId;
  
  cnt    = [_palmRecords count];
  jobIds = [NSMutableArray arrayWithCapacity:cnt+1];
  
  for (i = 0; i < cnt; i++) {
    doc   = [_palmRecords objectAtIndex:i];
    skyId = [doc skyrixId];
    
    if ([skyId intValue] > 1000)
      [jobIds addObject:skyId];
  }

  skyJobs = [self fetchSkyrixRecordsForIDs:jobIds];
  cnt     = [skyJobs count];

  docMap = [NSMutableDictionary dictionaryWithCapacity:cnt+1];
  for (i = 0; i < cnt; i++) {
    skyDoc = [skyJobs objectAtIndex:i];
    skyId  = [skyDoc globalID];
    skyId  = [skyId keyValues][0];
    if (![skyId isKindOfClass:[NSNumber class]])
      skyId = [NSNumber numberWithInt:[skyId intValue]];
    [docMap setObject:skyDoc forKey:skyId];
  }
  
  return docMap;
}

@end /* SkyPalmJobDataSource */

@implementation SkyPalmMemoDataSource
- (NSString *)entityName {
  return @"palm_memo";
}
- (NSString *)palmDb {
  return @"MemoDB";
}
- (SkyPalmDocument *)allocDocument {
  return [SkyPalmMemoDocument alloc];
}

- (NSDictionary *)_bulkFetchSkyrixRecords:(NSArray *)_palmRecords {  
  // TODO .. maybe
  /*
    bulk fetch for sky project documents doesn't seem as obvious, since
    they can be in different projects and there is no bulk fetch
    for documents from different projects implemented

    returning an empty map is the best to do here. single fetch
    via the palm documents is still enabled.
   */
  return [NSDictionary dictionary];
}

@end /* SkyPalmMemoDataSource */


/* gloabl ID resolvers */

@interface SkyPalmEntryDataSource(FetchingGIDs)
- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids;
@end

@implementation SkyPalmDocumentGlobalIDResolver

- (NSString *)entityName {
  NSLog(@"%s subclass", __PRETTY_FUNCTION__);
  return nil;
}
- (NSString *)palmDb {
  NSLog(@"%s subclass", __PRETTY_FUNCTION__);
  return nil;
}

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:[self entityName]])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyPalmEntryDataSource *ds;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [SkyPalmEntryDataSource dataSourceWithContext:[_dm context]
                               forPalmDb:[self palmDb]];
  if (ds == nil)
    return nil;
  
  return [(SkyPalmEntryDataSource *)ds _fetchObjectsForGlobalIDs:_gids];
}

/* NSCopying */
- (id)copyWithZone:(NSZone *)_zone {
  /* required by MacOSX */
  return [self retain];
}

@end /* SkyPalmDocumentGlobalIDResolver */

@implementation SkyPalmJobGlobalIDResolver
- (NSString *)entityName {
  return @"palm_todo";
}
- (NSString *)palmDb {
  return @"ToDoDB";
}
@end /* SkyPalmJobGlobalIDResolver */

@implementation SkyPalmAddressGlobalIDResolver
- (NSString *)entityName {
  return @"palm_address";
}
- (NSString *)palmDb {
  return @"AddressDB";
}
@end /* SkyPalmAddressGlobalIDResolver */

@implementation SkyPalmMemoGlobalIDResolver
- (NSString *)entityName {
  return @"palm_memo";
}
- (NSString *)palmDb {
  return @"MemoDB";
}
@end /* SkyPalmMemoGlobalIDResolver */

@implementation SkyPalmDateGlobalIDResolver
- (NSString *)entityName {
  return @"palm_date";
}
- (NSString *)palmDb {
  return @"DatebookDB";
}
@end /* SkyPalmDateGlobalIDResolver */
