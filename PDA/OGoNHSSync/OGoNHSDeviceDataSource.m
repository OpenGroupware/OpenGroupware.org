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

#include "OGoNHSDeviceDataSource.h"

@interface OGoNHSAddressDataSource : OGoNHSDeviceDataSource
{}
@end

@interface OGoNHSDateDataSource : OGoNHSDeviceDataSource
{}
@end

@interface OGoNHSMemoDataSource : OGoNHSDeviceDataSource
{}
@end

@interface OGoNHSJobDataSource : OGoNHSDeviceDataSource
{}
@end

#include <OGoPalm/SkyPalmCategoryDataSource.h>
@interface OGoNHSCategoryDataSource : SkyPalmCategoryDataSource
{
}
- (id)initWithTable:(NSString *)_table;
@end
@interface SkyPalmCategoryDataSource(OGoNHS)
- (void)setPalmTable:(NSString *)_table;
@end

#import <Foundation/Foundation.h>
#import <GDLAccess/GDLAccess.h>
#include <EOControl/EOControl.h>

#include <PPSync/PPRecordDatabase.h>
#include <PPSync/PPAddressDatabase.h>
#include <PPSync/PPDatebookDatabase.h>
#include <PPSync/PPMemoDatabase.h>
#include <PPSync/PPToDoDatabase.h>
#include <PPSync/PPTransaction.h>

#include <PPSync/PPSyncContext.h>
#include <PPSync/PPGlobalID.h>

#if 0
#define id _pid
#  include <pisock/pi-dlp.h>
#  include <pisock/pi-appinfo.h>
//#  include <pisock/pi-datebook.h>
#undef id
#else
#define id _pid
#  include <pi-dlp.h>
#  include <pi-appinfo.h>
//#  include <pisock/pi-datebook.h>
#undef id
#endif


// #define OGoNHS_MAX_OR_EXPR 200
#define OGoNHS_MAX_OR_EXPR 0

#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoPalm/SkyPalmDateDocument.h>
#include <OGoPalm/SkyPalmMemoDocument.h>
#include <OGoPalm/SkyPalmJobDocument.h>

#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGBundleManager.h>

@interface OGoNHSDeviceDataSource(PrivatMethods)
- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec;
@end

@interface PPRecordDatabase(OGoNHS_Methods)
- (Class)databaseRecordClassForGlobalID:(EOGlobalID *)_oid;
- (NSData *)packRecord:(id)_eo;
@end

@implementation OGoNHSDeviceDataSource

- (id)initWithTransaction:(PPTransaction *)_ec
  deviceId:(NSString *)_deviceId
  companyId:(NSNumber *)_companyId
  palmDb:(NSString *)_palmDb
{
  if ((self = [self init])) {
    ASSIGN(self->companyId,_companyId);
    ASSIGN(self->deviceId,_deviceId);
    ASSIGN(self->palmDb,_palmDb);
    ASSIGN(self->tx,_ec);
    ppSync = [(PPSyncContext *)[_ec rootObjectStore] retain];
  }
  return self;
}

+ (id)dataSourceWithTransaction:(PPTransaction *)_ec
  deviceId:(NSString *)_deviceId
  companyId:(NSNumber *)_companyId
  palmDb:(NSString *)_palmDb
{
  id ds = nil;
  if ([_palmDb isEqualToString:@"AddressDB"])
    ds = [OGoNHSAddressDataSource alloc];
  else if ([_palmDb isEqualToString:@"DatebookDB"])
    ds = [OGoNHSDateDataSource alloc];
  else if ([_palmDb isEqualToString:@"MemoDB"])
    ds = [OGoNHSMemoDataSource alloc];
  else if ([_palmDb isEqualToString:@"ToDoDB"])
    ds = [OGoNHSJobDataSource alloc];
  else {
    NGBundleManager *bm;
    EOQualifier     *q;
    NSBundle        *bundle;

    bm = [NGBundleManager defaultBundleManager];
    q  = [EOQualifier qualifierWithQualifierFormat:
                      @"palmDb=%@", _palmDb];
    bundle = [bm bundleProvidingResourceOfType:@"OGoPalmDataSources"
                 matchingQualifier:q];
    if (bundle != nil) {
      if (![bundle load]) {
        NSLog(@"%s: failed to load bundle: %@", __PRETTY_FUNCTION__, bundle);
        return nil;
      }
      {
        id resources, resource, cname;
        resources = [bundle providedResourcesOfType:@"OGoPalmDataSources"];
        resources = [resources filteredArrayUsingQualifier:q];
        resource  = [resources lastObject];

        cname = [resource valueForKey:@"palmDataSource"];
        if ([cname length])
          ds = [NSClassFromString(cname) alloc];
        else {
          NSLog(@"%s invalid class for palmDb: %@",
                __PRETTY_FUNCTION__, _palmDb);
          return nil;
        }
      }
    }
    else {
      NSLog(@"%s didn't find palmDataSource for palmDb: %@",
            __PRETTY_FUNCTION__, _palmDb);
      return nil;
    }
  }

  ds = [ds initWithTransaction:_ec
           deviceId:_deviceId
           companyId:_companyId
           palmDb:_palmDb];

  return [ds autorelease];
}

- (void)dealloc {
  RELEASE(self->tx);
  RELEASE(self->deviceId);
  RELEASE(self->companyId);
  RELEASE(self->palmDb);
  RELEASE(self->ppSync);
  RELEASE(self->newPalmIds);
  RELEASE(self->ctx);
  RELEASE(self->lastInsertedGID);
  [super dealloc];
}

/* accessors */

- (NSString *)deviceId {
  return self->deviceId;
}

// helper
- (EOFetchSpecification *)_fetchSpecForObjects {
  return [EOFetchSpecification fetchSpecificationWithEntityName:[self palmDb]
                               qualifier:nil sortOrderings:nil];
}

// overwrite with call of super method
- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec {
  NSMutableDictionary *dict =
    [NSMutableDictionary dictionaryWithCapacity:32];

  return dict;
}
// overwrite
- (NSData *)packedDataForDocument:(SkyPalmDocument *)_doc {
  return nil;
}

- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec
  dataBase:(PPRecordDatabase *)_db
{
  NSMutableDictionary *dict    = nil;
  PPGlobalID          *gid     = nil;

  dict = [self _buildDictWithRecord:_rec];

  { // setting global id & palm id
    gid = (PPGlobalID *)[_db globalIDForObject:_rec];
    [dict takeValue:gid forKey:@"globalID"];
    [dict takeValue:[NSNumber numberWithInt:[gid uniqueID]]
          forKey:@"palm_id"];
  }
  { // category 
    [dict takeValue:
          [NSNumber numberWithInt:[_db indexOfCategory:[_rec category]]]
          forKey:@"category_index"];
  }

  [dict takeValue:self->deviceId  forKey:@"device_id"];
  [dict takeValue:self->companyId forKey:@"company_id"];
  
  [dict takeValue:[NSNumber numberWithBool:[_rec isDirty]]
        forKey:@"is_modified"];
  [dict takeValue:[NSNumber numberWithBool:[_rec isDeleted]]
        forKey:@"is_deleted"];
  [dict takeValue:[NSNumber numberWithBool:[_rec isPrivate]]
        forKey:@"is_private"];
  [dict takeValue:[NSNumber numberWithBool:[_rec isArchived]]
        forKey:@"is_archived"];

  [dict takeValue:[NSNumber numberWithBool:NO] forKey:@"is_new"];

  return dict;
}

// converting
- (SkyPalmDocument *)pp2Document:(PPRecord *)_ppObj
                      ppDatabase:(PPRecordDatabase *)_db
{
  return [self documentForObject:
               [self _buildDictWithRecord:_ppObj
                     dataBase:_db]];
}

- (NSData *)packedDataForDocument:(SkyPalmDocument *)_doc
                         category:(int *)_category
                            flags:(int *)_flags
{
  int flags;
  
  *_category  = [[_doc categoryId] intValue];

  flags = 0;
  if ([_doc isPrivate])
    flags |= dlpRecAttrSecret;
  if ([_doc isDeleted])
    flags |= dlpRecAttrDeleted;
  if ([_doc isModified])
    flags |= dlpRecAttrDirty;

  *_flags = flags;

  return [self packedDataForDocument:_doc];
}

// overwriting
- (NSString *)palmDb {
  return self->palmDb;
}
- (NSNumber *)companyId {
  return self->companyId;
}
- (BOOL)syncCategories {
  return YES;
}

- (void)setCommandContext:(LSCommandContext *)_ctx {
  ASSIGN(self->ctx,_ctx);
}
- (NSArray *)_extractPalmIds:(NSArray *)_objs {
  NSEnumerator   *e   = nil;
  id             one  = nil;
  NSMutableArray *all = nil;

  e   = [_objs objectEnumerator];
  all = [NSMutableArray array];
  
  while ((one = [e nextObject])) {
    [all addObject:[NSNumber numberWithInt:[one palmId]]];
  }

  return all;
}
- (EOQualifier *)_qualifierForDeletedWithoutIds {
  NSString *query =
    [NSString stringWithFormat:
              @"device_id=\"%@\" AND company_id=%@ AND is_archived=0 "
              @"AND NOT (palm_id=0 OR is_new=1)",
              self->deviceId, self->companyId];
  return [EOQualifier qualifierWithQualifierFormat:query];
}
- (EOQualifier *)_qualifierForDeletedWithIds:(NSArray *)_ids
{
  NSString *query =
    [NSString stringWithFormat:
              @"device_id=\"%@\" AND company_id=%@ AND is_archived=0 "
              @"AND NOT (palm_id=0 OR is_new=1) AND"
              @"NOT (palm_id=%@)",
              self->deviceId, self->companyId, 
              [_ids componentsJoinedByString:@" OR palm_id="]];
  return [EOQualifier qualifierWithQualifierFormat:query];
}
- (EOFetchSpecification *)_deleteFetchSpecForIds:(NSArray *)_ids
                                      entityName:(NSString *)_ename {
  EOFetchSpecification *spec = nil;
  EOQualifier          *qual = nil;
  id                   dict  = nil;

  // 250 is the limit of or expressions in FrontBase
  qual = (([_ids count] > 0) && ([_ids count] < OGoNHS_MAX_OR_EXPR))
    ? [self _qualifierForDeletedWithIds:_ids]
    : [self _qualifierForDeletedWithoutIds];

  spec = [EOFetchSpecification fetchSpecificationWithEntityName:_ename
                               qualifier:qual sortOrderings:nil];

  dict = [[spec hints] mutableCopy];
  if (dict == nil)
    dict = [[NSMutableDictionary alloc] initWithCapacity:1];

  [dict setObject:[NSNumber numberWithBool:NO] forKey:@"fetchCategories"];
  [spec setHints:dict];
  RELEASE(dict);

  return spec;
}
- (NSArray *)_deletedObjsWithFetched:(NSArray *)_fetched {
  NSAutoreleasePool      *pool = [[NSAutoreleasePool alloc] init];
  SkyPalmEntryDataSource *ds   = nil;
  NSArray                *objs = nil;
  NSArray                *fetchedPalmIds = nil;
  
#if 1
  ds  = [SkyPalmEntryDataSource dataSourceWithContext:self->ctx
                                forPalmDb:[self palmDb]];
  [ds setDefaultDevice:self->deviceId];

  fetchedPalmIds = [self _extractPalmIds:_fetched];
  [ds setFetchSpecification:
      [self _deleteFetchSpecForIds:fetchedPalmIds
            entityName:[ds entityName]]];
  
  objs = [ds fetchObjects];
#else
  {
    NSMutableArray *result;
    int            maxCount = 200;
    int            idCnt, currentPos;
    NSArray        *palmIds;

    palmIds = [self _extractPalmIds:_fetched];

    idCnt  = [palmIds count];
    result = [NSMutableArray arrayWithCapacity:idCnt];
    currentPos = 0;

    while (currentPos < idCnt) {
      NSArray *sub;
      int     idx;

      ds  = [SkyPalmEntryDataSource dataSourceWithContext:self->ctx
                                    forPalmDb:[self palmDb]];
      [ds setDefaultDevice:self->deviceId];
      
      idx = (currentPos+maxCount>idCnt)?idCnt-currentPos:maxCount;

      sub = [palmIds subarrayWithRange:NSMakeRange(currentPos, idx)];

      currentPos +=maxCount;

      [ds setFetchSpecification:[self _deleteFetchSpecForIds:sub
                                      entityName:[ds entityName]]];
      [result addObjectsFromArray:[ds fetchObjects]];
    }
    objs = result;
  }
#endif
  {
    NSEnumerator   *e   = [objs objectEnumerator];
    id             one  = nil;
    id             palmId;
    int            cnt  = 0;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[objs count]];

    // to prevent timeout
    [self dotLog];
    while ((one = [e nextObject])) {
      palmId = [NSNumber numberWithInt:[one palmId]];
      if (![fetchedPalmIds containsObject:palmId]) {
        [one setIsDeleted:YES];
        [result addObject:one];
      }
      cnt++;
      if (cnt == 500) {
        cnt = 0;
        // to prevent timeout
        [self dotLog];
      }
    }
    objs = result;
  }
  
  RETAIN(objs);
  RELEASE(pool);
  return AUTORELEASE(objs);
}

- (NSArray *)fetchObjects {
  id           ppObjs  = nil;
  NSEnumerator *e      = nil;
  id           one     = nil;
  id           db      = nil;
  int          cnt     = 0;

  ppObjs = [self->tx objectsWithFetchSpecification:
                [self _fetchSpecForObjects]];

  e      = [ppObjs objectEnumerator];
  ppObjs = [NSMutableArray array];
  db     = [self->ppSync openDatabaseNamed:[self palmDb]];

  // to prevent timeout
  [self dotLog];
  
  while ((one = [e nextObject])) {
    one = [self pp2Document:one
                ppDatabase:db];
    [ppObjs addObject:one];
    cnt++;
    if (cnt == 500) {
      // to prevent timeout
      cnt = 0;
      [self dotLog];
    }
  }
  // to prevent timeout
  [self dotLog];

  [ppObjs addObjectsFromArray:[self _deletedObjsWithFetched:ppObjs]];
  [self->ppSync closeDatabase:db];
  return ppObjs;
}

- (void)insertObject:(SkyPalmDocument *)_doc {
  NSData   *data    = nil;
  id       db       = nil;
  int      category = 0;
  int      flags    = 0;
  id       gid      = nil;
  char     catID    = 0;

  data = [self packedDataForDocument:_doc category:&category flags:&flags];

  db   = [self->ppSync openDatabaseNamed:[self palmDb]];

  if (![[self palmDb] isEqualToString:@"DatebookDB"])
    //    catID = [db categoryIDAtIndex:category];
    catID = [db categoryIDAtIndex:category];

  // not categoryID but category Index
  gid = [self->ppSync insertRecord:data
             intoDatabase:db
             isPrivate:[_doc isPrivate]
             categoryID:catID];
  ASSIGN(self->lastInsertedGID,gid);
#if 0
  {
    // save new id for assignment
    NSDictionary *dict   = nil;
    NSNumber     *palmId = nil;
    id           recId   = nil;
    
    
    palmId  = [NSNumber numberWithInt:[gid uniqueID]];
    recId   = [[_doc globalID] keyValuesArray];
    if ([recId count] < 1) {
      recId = [[_doc asDictionary] valueForKey:[_doc primaryKey]];
    }
    else {
      recId   = [[[_doc globalID] keyValuesArray] objectAtIndex:0];
    }
    dict    = [NSDictionary dictionaryWithObjectsAndKeys:
                            palmId, @"palm_id",
                            recId,  @"skyrix_id",
                            nil];
    [self->newPalmIds addObject:dict];
  }
#endif
}

- (void)updateObject:(SkyPalmDocument *)_doc {
  NSData   *data    = nil;
  id       db       = nil;
  int      category = 0;
  int      flags    = 0;
  id       gid      = nil;

  if ([_doc palmId] == 0) {
    [self insertObject:_doc];
    return;
  }

  data = [self packedDataForDocument:_doc category:&category flags:&flags];
  db   = [self->ppSync openDatabaseNamed:[self palmDb]];

  gid  = [PPGlobalID ppGlobalIDForCreator:[db creator]
                     type:[(PPDatabase *)db type]
                     databaseName:[db databaseName]
                     uniqueID:[_doc palmId]];

  if (![self->ppSync updateRecord:data
            inDatabase:db
            flags:flags
            categoryID:(unsigned char)category
            oid:gid])
    {
      // failed
      NSLog(@"WARNING %s update of object %@ failed",
            __PRETTY_FUNCTION__, gid);
      return;
    }
}

- (void)deleteObject:(SkyPalmDocument *)_doc {
  id db  = nil;
  id gid = nil;

  db  = [self->ppSync openDatabaseNamed:[self palmDb]];
  gid = [PPGlobalID ppGlobalIDForCreator:[db creator]
                    type:[(PPDatabase *)db type]
                    databaseName:[db databaseName]
                    uniqueID:[_doc palmId]];

  if (![self->ppSync deleteRecord:gid inDatabase:db]) {
    // failed
    NSLog(@"WARNING %s delete of object %@ failed", __PRETTY_FUNCTION__, gid);
  }
}

- (NSArray *)devices {
  return [NSArray arrayWithObject:self->deviceId];
}


- (void)prepareSync {
  RELEASE(self->newPalmIds);
  self->newPalmIds = [[NSMutableArray alloc] initWithCapacity:8];
}
- (id)lastInsertedGID {
  return self->lastInsertedGID;
}
- (void)addMappingWithSkyId:(id)_skyId palmId:(id)_palmId {
  [self->newPalmIds addObject:
       [NSDictionary dictionaryWithObjectsAndKeys:
                     _palmId, @"palm_id",
                     _skyId,  @"skyrix_id",
                     nil]];
}
- (void)mapLastInsertedToSkyId:(id)_skyId {
  [self addMappingWithSkyId:_skyId
        palmId:[NSNumber numberWithInt:[[self lastInsertedGID] uniqueID]]];
}

- (EOFetchSpecification *)_specificationWithIds:(NSArray *)_recIds
                                     entityName:(NSString *)_e
                                     primaryKey:(NSString *)_p
{
  NSString    *query = nil;
  EOQualifier *qual  = nil;

  if ((_recIds != nil) && ([_recIds count] > 0)) {
    query = [NSString stringWithFormat:@" OR %@=", _p];
    query = [NSString stringWithFormat:@"%@=%@", _p,
                      [_recIds componentsJoinedByString:query]];
  }
  else {
    query = @"company_id=0";
  }
    
  qual = [EOQualifier qualifierWithQualifierFormat:query];
  return [EOFetchSpecification fetchSpecificationWithEntityName:_e
                               qualifier:qual
                               sortOrderings:nil];
}
- (NSArray *)_fetchSkyDocs:(NSArray *)_ids
               withContext:(LSCommandContext *)_ctx {
  SkyPalmEntryDataSource *ds;

  ds = [SkyPalmEntryDataSource dataSourceWithContext:_ctx
                               forPalmDb:self->palmDb];
#if 0
  [ds setFetchSpecification:[self _specificationWithIds:_ids
                                  entityName:[ds entityName]
                                  primaryKey:[ds primaryKey]]];
  return [ds fetchObjects];
#else
  {
    NSMutableArray *result;
    int            maxCount = 200;
    int            idCnt, currentPos;

    idCnt  = [_ids count];
    result = [NSMutableArray arrayWithCapacity:idCnt];
    currentPos = 0;

    while (currentPos < idCnt) {
      NSArray *sub;
      int     idx;

      idx = (currentPos+maxCount>idCnt)?idCnt-currentPos:maxCount;

      sub = [_ids subarrayWithRange:NSMakeRange(currentPos, idx)];

      currentPos +=maxCount;

      [ds setFetchSpecification:[self _specificationWithIds:sub
                                       entityName:[ds entityName]
                                       primaryKey:[ds primaryKey]]];
      [result addObjectsFromArray:[ds fetchObjects]];
    }
    return result;
  }
#endif
}

// new sky_ids mapped with palm_ids
- (NSArray *)newSkyPalmMapping
{
  return self->newPalmIds;
}

- (struct CategoryAppInfo)_categoryInfoForDb:(PPRecordDatabase *)_db
{
  NSData                 *data        = nil;
  struct CategoryAppInfo categoryInfo;
  const unsigned char    *record;
  int                    len, i;

  data   = [self->ppSync readAppBlockOfDatabase:_db];
  record = [data bytes];
  len    = [data length];

  i = unpack_CategoryAppInfo(&categoryInfo, (char *)record, len);
  if ((!record) || (i == 0)) {
    NSLog(@"WARNING %s Failed decoding appinfo", __PRETTY_FUNCTION__);
  }
  return categoryInfo;
}

- (NSArray *)_categoriesForDb:(PPRecordDatabase *)_db {
  struct CategoryAppInfo cI;
  int                    i;
  NSMutableArray         *all;
  NSString               *category;

  cI  = [self _categoryInfoForDb:_db];
  all = [NSMutableArray array];

  for (i = 0; i < 16; i++) {
    category = [NSString stringWithCString:cI.name[i]];
    if (category != nil) {
      int          p     = cI.ID[i];
      EOGlobalID   *gid  = nil;
      NSDictionary *dict = nil;
      id           *objs = calloc(1, sizeof(id));
      int          r     = cI.renamed[i];
      
      objs[0] = [NSNumber numberWithInt:p];

      gid = [EOKeyGlobalID globalIDWithEntityName:[self palmDb]
                           keys:objs keyCount:1 zone:nil];
      dict = 
        [NSDictionary dictionaryWithObjectsAndKeys:
                      category,                          @"category_name",
                      [NSNumber numberWithInt:p],        @"palm_id",
                      [NSNumber numberWithInt:i],        @"category_index",
                      [NSNumber numberWithInt:r],        @"is_modified",
                      [self deviceId],                   @"device_id",
                      @" ",                              @"md5hash",
                      gid,                               @"globalID",
                      nil];
      [all addObject:dict];
    }
  }

  return all;
}

// category sync
- (NSArray *)categoriesForDevice:(NSString *)_dev {
  NSEnumerator             *e   = nil;
  id                       one  = nil;
  PPRecordDatabase         *db  = nil;
  OGoNHSCategoryDataSource *ds  = nil;
  NSMutableArray           *all = nil;
  
  if (![[self deviceId] isEqualToString:_dev])
    return [NSArray array];

  ds = [[OGoNHSCategoryDataSource alloc] initWithTable:[self palmDb]];
  [ds setDefaultDevice:_dev];
  db = (PPRecordDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]];

  e   = [[self _categoriesForDb:db] objectEnumerator];
  all = [NSMutableArray array];
  
  while ((one = [e nextObject])) {
    one = [ds documentForObject:one];
    [all addObject:one];
  }

  RELEASE(ds);

  return all;
}

- (struct CategoryAppInfo)_defaultCategories {
  struct CategoryAppInfo info;
  int                    i, k;
  NSString               *name = @"";
  char                   buf[16];

  for (i = 0; i < 16; i++) {
    [name getCString:buf maxLength:15];
    for (k = 0; k < 16; k++) {
      info.name[i][k] = buf[k];
      if (buf[k] == '\0')
        k = 32;
    }
    info.ID[i]   = (char)0;
  }

  return info;
}

- (NSData *)_packCategories:(NSArray *)_cats
{
  NSEnumerator           *e;
  int                    i;
  id                     one;
  struct CategoryAppInfo info;
  char                   record[2+16*16+16+4];
  // modified/names/ids/lastuniqueid
  int                    len     = 0;

  //  info = [self _defaultCategories];
  info =
    [self _categoryInfoForDb:
          (PPRecordDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]]];

  e   = [_cats objectEnumerator];
  while ((one = [e nextObject])) {
    char buf[16];
    int  k;
    i = [[one valueForKey:@"category_index"] intValue];
    [[one valueForKey:@"category_name"] getCString:buf maxLength:15];
    
    for (k = 0; k < 16; k++) {
      info.name[i][k] = buf[k];
      if (buf[k] == '\0')
        k = 32;
    }
    info.ID[i]   = (char)[[one valueForKey:@"palm_id"] intValue];
    info.renamed[i] = 0;  // not modified
  }

  if (!record)
    NSLog(@"%s WARNING record is invalid");

  len = pack_CategoryAppInfo(&info, (char *)record, sizeof(record));

  return [NSData dataWithBytes:record length:len];
}

- (NSArray *)saveCategories:(NSArray *)_cats 
                  forDevice:(NSString *)_dev
{
  NSEnumerator     *e;
  NSMutableArray   *all;
  id               one;
  PPRecordDatabase *db;

  e   = [_cats objectEnumerator];
  all = [NSMutableArray array];
  db  = (PPRecordDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]];
  
  while ((one = [e nextObject])) {
    [all addObject:[one asDictionary]];
  }
  
#if 0
  [self->ppSync
       writeAppBlock:[self _packCategories:all]
       ofDatabase:db];
#else
  [self _packCategories:all];
#endif

  return [self categoriesForDevice:_dev];
}

- (void)dotLog {
  [self->ppSync syncLogWithString:@". "];
}

@end /* OGoNHSDeviceDataSource */

@implementation OGoNHSAddressDataSource

- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec {
  NSMutableDictionary *dict = [super _buildDictWithRecord:_rec];
  PPAddressRecord     *rec  = (PPAddressRecord *)_rec;

  [dict takeValue:[rec valueForKey:@"address"]   forKey:@"address"];
  [dict takeValue:[rec valueForKey:@"city"]      forKey:@"city"];
  [dict takeValue:[rec valueForKey:@"company"]   forKey:@"company"];
  [dict takeValue:[rec valueForKey:@"country"]   forKey:@"country"];
  [dict takeValue:[rec valueForKey:@"firstName"] forKey:@"firstname"];
  [dict takeValue:[rec valueForKey:@"lastName"]  forKey:@"lastname"];
  [dict takeValue:[rec valueForKey:@"note"]      forKey:@"note"];
  [dict takeValue:[rec valueForKey:@"state"]     forKey:@"state"];
  [dict takeValue:[rec valueForKey:@"title"]     forKey:@"title"];
  [dict takeValue:[rec valueForKey:@"zip"]       forKey:@"zipcode"];
  [dict takeValue:[rec valueForKey:@"custom1"]   forKey:@"custom1"];
  [dict takeValue:[rec valueForKey:@"custom2"]   forKey:@"custom2"];
  [dict takeValue:[rec valueForKey:@"custom3"]   forKey:@"custom3"];
  [dict takeValue:[rec valueForKey:@"custom4"]   forKey:@"custom4"];

  { // phone values
    NSEnumerator *e    = [[rec valueForKey:@"phoneKeys"] objectEnumerator];
    id           one   = nil;
    NSNumber     *pos  = nil;
    int          cnt   = 0;

    static NSDictionary *mapping = nil;
    if (mapping == nil) {
      mapping = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:0], @"phoneWork",
                              [NSNumber numberWithInt:1], @"phoneHome",
                              [NSNumber numberWithInt:2], @"phoneFax",
                              [NSNumber numberWithInt:3], @"phoneOther",
                              [NSNumber numberWithInt:4], @"phoneEmail",
                              [NSNumber numberWithInt:5], @"phoneMain",
                              [NSNumber numberWithInt:6], @"phonePager",
                              [NSNumber numberWithInt:7], @"phoneMobile",
                              nil];
      RETAIN(mapping);
    }
    
    while (((one = [e nextObject])) && (cnt < 5)) {
      pos = [mapping valueForKey:one];

      // check for display phone
      if ([one isEqualToString:[rec valueForKey:@"showPhone"]])
        [dict setObject:pos forKey:@"display_phone"];

      // setting value and label_id
      [dict setObject:[rec valueForKey:one]
            forKey:[NSString stringWithFormat:@"phone%d", cnt]];
      [dict setObject:pos
            forKey:[NSString stringWithFormat:@"phone_label_id%d", cnt]];
      
      cnt++;
    }
    
  }

  return dict;
}

- (NSData *)packedDataForDocument:(SkyPalmDocument *)_doc {
  PPAddressRecord   *rec    = nil;
  PPAddressDatabase *db     = nil;
  NSData            *result = nil;

  SkyPalmAddressDocument *doc = (SkyPalmAddressDocument *)_doc;

  db  = (PPAddressDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]];
  rec = [[PPAddressRecord alloc] init];

  [rec takeValue:[doc address]   forKey:@"address"];
  [rec takeValue:[doc city]      forKey:@"city"];
  [rec takeValue:[doc company]   forKey:@"company"];
  [rec takeValue:[doc country]   forKey:@"country"];
  [rec takeValue:[doc firstname] forKey:@"firstName"];
  [rec takeValue:[doc lastname]  forKey:@"lastName"];
  [rec takeValue:[doc note]      forKey:@"note"];
  [rec takeValue:[doc state]     forKey:@"state"];
  [rec takeValue:[doc title]     forKey:@"title"];
  [rec takeValue:[doc zipcode]   forKey:@"zip"];
  [rec takeValue:[doc custom1]   forKey:@"custom1"];
  [rec takeValue:[doc custom2]   forKey:@"custom2"];
  [rec takeValue:[doc custom3]   forKey:@"custom3"];
  [rec takeValue:[doc custom4]   forKey:@"custom4"];

  { // phone values
    NSString *val = nil;
    id       key = nil;
    int      i    = 0;
    int      pos  = 0;
    
    static NSArray *keys = nil;
    

    if (keys == nil) {
      keys = [NSArray arrayWithObjects:
                      @"phoneWork",  @"phoneHome",
                      @"phoneFax",   @"phoneOther",
                      @"phoneEmail", @"phoneMain",
                      @"phonePager", @"phoneMobile",
                      nil];
      RETAIN(keys);
    }

    for (i = 0; i < 8; i++) {
      val = [doc valueForKey:[NSString stringWithFormat:@"phone%d", i]];

      if ((val == nil) || ([val isEqualToString:@""]))
        continue;
      
      key = [doc valueForKey:
                 [NSString stringWithFormat:@"phoneLabelId%d", i]];
      pos = [key intValue];
      key = [keys objectAtIndex:pos];

      // set values
      [rec takeValue:val forKey:key];

      // displayPhone
      if (pos == [doc displayPhone]) {
        [rec takeValue:key forKey:@"showPhone"];
      }
    }
  }

  result = [db packRecord:rec];
  RELEASE(rec);

  return result;
}

@end /* OGoNHSAddressDataSource */

@implementation OGoNHSDateDataSource

- (BOOL)syncCategories { return NO; }

- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec {
  NSMutableDictionary *dict = [super _buildDictWithRecord:_rec];
  PPDatebookRecord    *rec  = (PPDatebookRecord *)_rec;
  double              advance = 0.0;
  int                 alarm   = 0;
  int                 unit    = 0;

  unit    = [[rec valueForKey:@"alarmAdvanceUnit"] intValue];
  advance = [[rec valueForKey:@"alarmAdvance"] doubleValue]; // secs
  [dict takeValue:[NSNumber numberWithInt:unit]
        forKey:@"alarm_advance_time"];
  switch (unit) {
    case 0: // minutes
      alarm = advance / 60.0;
      break;
    case 1: // hours
      alarm = advance / 3600.0;
      break;
    case 2: // days
      alarm = advance / (3600.0*24.0);
  }
  [dict takeValue:[NSNumber numberWithInt:alarm]
        forKey:@"alarm_advance_unit"];
  [dict takeValue:[rec valueForKey:@"title"]    forKey:@"description"];
  [dict takeValue:[rec valueForKey:@"endDate"]  forKey:@"enddate"];
  [dict takeValue:[rec valueForKey:@"hasAlarm"] forKey:@"is_alarmed"];
  [dict takeValue:[rec valueForKey:@"isEvent"]  forKey:@"is_untimed"];
  [dict takeValue:[rec valueForKey:@"note"]     forKey:@"note"];
  [dict takeValue:[rec valueForKey:@"cycleEndDate"]
        forKey:@"repeat_enddate"];
  [dict takeValue:[rec valueForKey:@"cycleFrequency"]
        forKey:@"repeat_frequency"];
  [dict takeValue:[rec valueForKey:@"cycleWeekStart"]
        forKey:@"repeat_start_week"];
  [dict takeValue:[rec valueForKey:@"startDate"]
        forKey:@"startdate"];
  
  { // repeat type
    int repeatType = [[rec valueForKey:@"cycleType"] intValue];
    int repeatOn   = 0;

    [dict takeValue:[NSNumber numberWithInt:repeatType]
          forKey:@"repeat_type"];
    
    if (repeatType == 3) // monthlyByDay
      repeatOn = [[rec valueForKey:@"dayCycle"] intValue];
    else if (repeatType == 2) { // weekly
      NSArray *days = [rec valueForKey:@"cycleDays"];
      int i;
      for (i = 0; i < 7; i++) {
        if ([[days objectAtIndex:i] boolValue])
          repeatOn |= 1 << i;
      }
    }

    [dict takeValue:[NSNumber numberWithInt:repeatOn]
          forKey:@"repeat_on"];
  } /* repeatType */

  { // exceptions
    NSString     *excepts = nil;
    NSEnumerator *e       = nil;
    id           one      = nil;

    e = [[rec valueForKey:@"cycleExceptionsArray"] objectEnumerator];
    while ((one = [e nextObject]) != nil) {
      one = [one descriptionWithCalendarFormat:@"%Y-%m-%d"];
      excepts = (excepts == nil)
        ? one
        : (id)[excepts stringByAppendingFormat:@",%@", one];
    }
    [dict takeValue:((excepts == nil)
                     ? (NSString *)@""
                     : excepts)
          forKey:@"exceptions"];
  } /* exceptions */

  return dict;
}

- (NSData *)packedDataForDocument:(SkyPalmDocument *)_doc {
  PPDatebookRecord   *rec    = nil;
  PPDatebookDatabase *db     = nil;
  NSData            *result  = nil;
  int               advance  = 0;
  double            factor   = 1.0;

  SkyPalmDateDocument *doc = (SkyPalmDateDocument *)_doc;

  db  = (PPDatebookDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]];
  rec = [[PPDatebookRecord alloc] init];

  advance = [doc alarmAdvanceTime];
  switch (advance) {
    case 0: // minutes
      factor = 60.0;
      break;
    case 1: // hours
      factor = 3600.0;
      break;
    case 2: // days
      factor = 3600.0*24.0;
      break;
  }
  [rec takeValue:[NSNumber numberWithInt:advance]
       forKey:@"alarmAdvanceUnit"];
  [rec takeValue:[NSNumber numberWithDouble:factor*[doc alarmAdvanceUnit]]
       forKey:@"alarmAdvance"];
  [rec takeValue:[doc description] forKey:@"title"];
  [rec takeValue:[doc enddate]     forKey:@"endDate"];
  [rec takeValue:[NSNumber numberWithBool:[doc isAlarmed]]
       forKey:@"hasAlarm"];
  [rec takeValue:[NSNumber numberWithBool:[doc isUntimed]]
       forKey:@"isEvent"];
  [rec takeValue:[doc note]        forKey:@"note"];
  [rec takeValue:[doc repeatEnddate] forKey:@"cycleEndDate"];
  [rec takeValue:[NSNumber numberWithBool:
                           ([doc repeatEnddate] == nil) ? YES : NO]
       forKey:@"cycleEndIsDistantFuture"];
  [rec takeValue:[NSNumber numberWithInt:[doc repeatFrequency]]
       forKey:@"cycleFrequency"];
  [rec takeValue:[NSNumber numberWithInt:[doc repeatStartWeek]]
       forKey:@"cycleWeekStart"];
  [rec takeValue:[doc startdate]   forKey:@"startDate"];
  [rec takeValue:[doc exceptions] forKey:@"cycleExceptionsArray"];

  { // repeat type
    [rec takeValue:[NSNumber numberWithInt:[doc repeatType]]
         forKey:@"cycleType"];

    if ([doc repeatType] == 3) // monthlyByDay
      [rec takeValue:[NSNumber numberWithInt:[doc repeatOn]]
           forKey:@"dayCycle"];
    else if ([doc repeatType] == 2) { // weekly
      int      on        = [doc repeatOn];
      int      i         = 0;
      NSMutableArray* cycleDays = [NSMutableArray array];

      for (i = 0; i < 7; i++) {
        [cycleDays addObject:
                   [NSNumber numberWithBool:
                             ((on & 1) == 1) ? YES : NO]];
        on >>= 1;
      }
      [rec takeValue:cycleDays forKey:@"cycleDays"];
    }
  }

  result = [db packRecord:rec];
  RELEASE(rec);

  return result;
}

@end /* OGoNHSDateDataSource */

@implementation OGoNHSMemoDataSource

- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec {
  NSMutableDictionary *dict = [super _buildDictWithRecord:_rec];
  PPMemoRecord        *rec  = (PPMemoRecord *)_rec;

  [dict takeValue:[rec valueForKey:@"text"] forKey:@"memo"];
  
  return dict;
}

- (NSData *)packedDataForDocument:(SkyPalmDocument *)_doc {
  PPMemoRecord   *rec    = nil;
  PPMemoDatabase *db     = nil;
  NSData         *result = nil;

  SkyPalmMemoDocument *doc = (SkyPalmMemoDocument *)_doc;

  db  = (PPMemoDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]];
  rec = [[PPMemoRecord alloc] init];

  [rec takeValue:[doc memo] forKey:@"text"];

  result = [db packRecord:rec];
  RELEASE(rec);

  return result;
}

@end /* OGoNHSMemoDataSource */

@implementation OGoNHSJobDataSource

- (NSMutableDictionary *)_buildDictWithRecord:(PPRecord *)_rec {
  NSMutableDictionary *dict = [super _buildDictWithRecord:_rec];
  PPToDoRecord        *rec  = (PPToDoRecord *)_rec;

  [dict takeValue:[rec valueForKey:@"title"]       forKey:@"description"];
  [dict takeValue:[rec valueForKey:@"due"]         forKey:@"duedate"];
  [dict takeValue:[rec valueForKey:@"note"]        forKey:@"note"];
  [dict takeValue:[rec valueForKey:@"priority"]    forKey:@"priority"];
  [dict takeValue:[rec valueForKey:@"isCompleted"] forKey:@"is_completed"];
  
  return dict;
}

- (NSData *)packedDataForDocument:(SkyPalmDocument *)_doc {
  PPToDoRecord   *rec    = nil;
  PPToDoDatabase *db     = nil;
  NSData         *result = nil;

  SkyPalmJobDocument *doc = (SkyPalmJobDocument *)_doc;

  db  = (PPToDoDatabase *)[self->ppSync openDatabaseNamed:[self palmDb]];
  rec = [[PPToDoRecord alloc] init];

  [rec takeValue:[doc description] forKey:@"title"];
  [rec takeValue:[doc duedate]     forKey:@"due"];
  [rec takeValue:[doc note]        forKey:@"note"];
  [rec takeValue:[NSNumber numberWithInt:[doc priority]]
       forKey:@"priority"];
  [rec takeValue:[NSNumber numberWithBool:[doc isCompleted]]
       forKey:@"isCompleted"];
  
  result = [db packRecord:rec];
  RELEASE(rec);

  return result;
}

@end /* OGoNHSJobDataSource */

@implementation OGoNHSCategoryDataSource

- (id)initWithTable:(NSString *)_table {
  if ((self = [super init])) {
    [self setPalmTable:_table];
  }
  return self;
}

@end /* OGoNHSCategoryDataSource */
