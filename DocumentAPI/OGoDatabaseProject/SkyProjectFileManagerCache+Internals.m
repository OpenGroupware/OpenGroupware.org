/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

// TODO: needs cleanup

#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include <EOControl/EOQualifier.h>
#include "common.h"

#import "SkyProjectFileManagerCache.h"

#if 0

#define TIME_START(_timeDescription) { \
  struct timeval tv; double ti; NSString *timeDescription = nil; \
  *(&ti) = 0; *(&timeDescription) = nil;\
  timeDescription = [_timeDescription copy]; gettimeofday(&tv, NULL); \
  ti =  (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0); printf("{\n");

#define TIME_END \
  gettimeofday(&tv, NULL); \
  ti = (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0) - ti; \
  printf("}\n[%s] <%s> : time needed: %4.4fs\n", __PRETTY_FUNCTION__, \
  [timeDescription cString], ti < 0.0 ? -1.0 : ti); \
  [timeDescription release]; timeDescription = nil;  } 

#else

#define TIME_START(_timeDescription)
#define TIME_END

#endif



@class NSArray;
@class EOAdaptor, EOGlobalID, EOAdaptorChannel;

#include "common.h"

@interface EOQualifier(SqlExpression) /* implemented in EOAdaptorDataSource */
- (NSString *)sqlExpressionWithAdaptor:(EOAdaptor *)_adaptor
  attributes:(NSArray *)_attrs;
@end

@interface SkyProjectFileManagerCache(Caching_Internals)
- (void)takeCacheValue:(id)_v forKey:(NSString *)_k;
- (id)cacheValueForKey:(NSString *)_k;
@end

@interface SkyProjectFileManager(Extensions_Internals)
+ (void)setProjectID:(NSNumber *)_pid forDocID:(NSNumber *)_did
  context:(id)_cxt;
+ (NSNumber *)pidForDocId:(NSNumber *)_did context:(id)_ctx;
@end /* SkyProjectFileManager(Extensions_Internals) */

@interface SkyProjectFileManagerCache(Internals)
- (EOAdaptorChannel *)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
- (NSString *)buildPathWithParent:(NSString *)_parent doc:(NSDictionary *)_doc;
- (void)createCacheStructuresWithMap:(NGHashMap *)_map
  root:(NSDictionary *)_root;
- (void)initializeFolderNameCaches;
- (NSMutableDictionary *)pk2FileNameCache;
- (NGMutableHashMap *)parent2ChildDirectoriesCache;
- (NSMutableDictionary *)fileName2ChildAttrs;
- (NSMutableDictionary *)cacheChildsForFolderStatusCache;
- (NSMutableDictionary *)fileName2ChildNames;
- (NSMutableDictionary *)pk2GenRecCache;
- (NSMutableDictionary *)fileName2GIDCache;
- (NSMutableDictionary *)allVersionAttrsAtPathCache;
- (NSString *)buildSelectForSiblingSearch:(EOEntity *)_entity
  attrs:(NSArray *)_attrs;
- (NSString *)buildSelectForAllSubVersionsWithAttributes:(NSArray *)_attrs;
- (NSArray *)fetchDocsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  qualifier:(EOQualifier *)_qual;
- (NSDictionary *)fetchDocEditingsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  docPKeys:(NSArray *)_pkeys;
- (NSString *)accountLogin4PersonId:(NSNumber *)_personId;
- (void)cacheChildsForFolder:(NSString *)_folder
  orSiblingsForId:(NSNumber *)_sid;
- (NSDictionary *)rootFolderAttrs;
- (NSMutableDictionary *)fileAttributesAtPathCache;
- (void)cacheChildsForSiblings:(NSArray *)_siblingIds;
@end /* SkyProjectFileManagerCache(Internals) */

@implementation SkyProjectFileManagerCache(Internals)

static NSNumber *yesNum = nil, *noNum = nil;
static NSString *Pk2FileNameCache_key         = @"pk2FileNameCache";
static NSString *FileName2GIDCache_key        = @"fileName2GIDCache";
static NSString *PersonId2LoginCache_key      = @"personId2LoginCache";
static NSString *Path2FileAttributesCache_key = @"path2FileAttributesCache";
static NSString *Pk2GenRecCache_key           = @"pk2GenRecCache";
static NSString *FileName2ChildAttrsCache_key = @"fileNames2ChildAttrsCache";
static NSString *FileName2ChildNamesCache_key = @"fileName2ChildNamesCache";
static NSString *CacheChildsForKeyCache_key   = @"cacheChildsForKeyCache";
static NSString *Parent2ChildFolders_key      = @"parent2ChildFolders";
static NSString *VersionAttrsAtPathCache_key  = @"versionAttrsAtPathCache";
static int      MaxInQualifierCount           = -1;

- (void)initStaticVars {
  if (MaxInQualifierCount == -1) {
    MaxInQualifierCount =
      [[NSUserDefaults standardUserDefaults]
                       integerForKey:@"MaxInQualifierCount"];
    if (!MaxInQualifierCount)
      MaxInQualifierCount = 250;
  }
}

static inline NSNumber *boolNum(BOOL value) {
  if (value) {
    if (yesNum == nil)
      yesNum = [[NSNumber numberWithBool:YES] retain];
    return yesNum;
  }
  else {
    if (noNum == nil)
      noNum = [[NSNumber numberWithBool:NO] retain];
    return noNum;
  }
}

- (EOAdaptorChannel *)beginTransaction {
  if (![self->context isTransactionInProgress]) {
    self->commitTransaction = YES;
    [self->context begin];
  }
  else {
    self->commitTransaction = NO;
  }
  return [[self->context valueForKey:LSDatabaseChannelKey] adaptorChannel];
}


- (void)commitTransaction {
  if (self->commitTransaction) {
    self->commitTransaction = NO;
    [self->context commit];
  }
}
- (void)rollbackTransaction {
  [self->context rollback];
  self->commitTransaction = NO;
}

/* builds a NSFilePath with doc (fileType, title) and parent path */
- (NSString *)buildPathWithParent:(NSString *)_parent doc:(NSDictionary *)_doc {
  NSString *fn;
  NSString *ex;
  
  fn = [_doc valueForKey:@"title"];
  fn = [SkyProjectFileManager formatTitle:fn];
  
  if ([(ex = [_doc valueForKey:@"fileType"]) isNotNull])
    fn = [fn stringByAppendingPathExtension:ex];
  
  if (![_parent isNotNull])
    _parent = @"/";

  return [_parent stringByAppendingPathComponent:fn];
}

/*
  builds cache structure from Hashmap with title, fileType, documentId,
  parentDocumentId keyed by parentDocumentId
  build primary key -> fileName and fileName -> primary key cache.
  Need to be improved

  got 3185 objects
    Profiling now document hierachie got 104 objects ...  PROF 0.017s
    Profiling now document hierachie got 1061 objects ... PROF 0.171s
    ...
  PROF 0.540s  
*/
- (void)createCacheStructuresWithMap:(NGHashMap *)_map
  root:(NSDictionary *)_root
{
  int cnt = 0;
  NSArray             *childs;
  NSMutableDictionary *path2pk, *pk2path;
  NGMutableHashMap    *p2Childs;
  NSNumber            *pid;

  pid      = [self->project valueForKey:@"projectId"];
  pk2path  = [[NSMutableDictionary alloc] initWithCapacity:[_map count]]; 
  path2pk  = [[NSMutableDictionary alloc] initWithCapacity:[_map count]];
  p2Childs = [[NGMutableHashMap alloc] initWithCapacity:[_map count]];
  
  childs = nil;
  while (YES) {
    if (!childs) { /* take root */
      NSNumber      *docId;
      EOKeyGlobalID *gid;

      docId = [_root valueForKey:@"documentId"];
      gid   = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                             keys:&docId keyCount:1 zone:NULL];
      
      [pk2path setObject:@"/" forKey:docId];
      [path2pk setObject:gid forKey:@"/"];

      childs = [_map objectsForKey:docId];
    }
    else { /* handle childs */
      NSEnumerator   *enumerator;
      NSMutableArray *nextChilds;
      id             c;

      int hierCnt;

      hierCnt = 0;
        
      enumerator = [childs objectEnumerator];
      nextChilds = [NSMutableArray arrayWithCapacity:16];
      while ((c = [enumerator nextObject])) {
        NSString *path, *parent;
        NSNumber *docId;
        NSArray  *ch;

        hierCnt++;
        cnt++;

        docId  = [c valueForKey:@"documentId"];
        parent = [pk2path objectForKey:[c valueForKey:@"parentDocumentId"]];
        path   = [self buildPathWithParent:parent doc:c];

        [p2Childs addObject:[path lastPathComponent] forKey:parent];
        [pk2path  setObject:path                     forKey:docId];
        {
          EOKeyGlobalID *kid;
	  
          kid = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                               keys:&docId keyCount:1 zone:NULL];
          [path2pk setObject:kid forKey:path];
          [SkyProjectFileManager setProjectID:pid forDocID:docId
                                 context:self->context];
        }

        ch = [_map objectsForKey:docId];

        if ([ch isNotNull]) {
          [nextChilds addObjectsFromArray:ch];
        }
      }
      childs = nextChilds;
    }
    if ([childs count] == 0)
      break;
  }
  [self takeCacheValue:pk2path forKey:Pk2FileNameCache_key];
  [self takeCacheValue:path2pk forKey:FileName2GIDCache_key];
  [self takeCacheValue:p2Childs forKey:Parent2ChildFolders_key];
  [pk2path  release]; pk2path  = nil;
  [path2pk  release]; path2pk  = nil;
  [p2Childs release]; p2Childs = nil;
}

/* load foldernames into cache */
- (void)initializeFolderNameCaches {
  static NSArray *fileNameAttributes = nil;

  NGMutableHashMap  *map;
  NSDictionary      *rootDoc, *row;
  EOAdaptorChannel  *channel;
  EOSQLQualifier    *qualifier;
  EOEntity          *entity;
  int               cnt;

  TIME_START(@"...");
  
  cnt    = 0;
  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"Doc"];
  if (!fileNameAttributes) {
    fileNameAttributes = [[NSArray alloc]
                                   initWithObjects:
                                   [entity attributeNamed:@"documentId"],
                                   [entity attributeNamed:@"parentDocumentId"],
                                   [entity attributeNamed:@"title"],
                                   [entity attributeNamed:@"fileType"],
                                   nil];
  }
  channel = [self beginTransaction];

  qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                      qualifierFormat:@"%A = %@ AND %A = %@",
                                      @"projectId",
                                      [self->project valueForKey:@"projectId"],
                                      @"isFolder", boolNum(YES)];
  if (![channel selectAttributes:fileNameAttributes
                describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
    NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
          __PRETTY_FUNCTION__, qualifier, fileNameAttributes);
    [self rollbackTransaction];
    RELEASE(qualifier); qualifier = nil;
    return;
  }
  
  [qualifier release]; qualifier = nil;
  
  map     = [[NGMutableHashMap alloc] initWithCapacity:16];
  rootDoc = nil;
  while ((row = [channel fetchAttributes:fileNameAttributes withZone:NULL])) {
    NSNumber *parentDoc;
    cnt++;
    parentDoc = [row valueForKey:@"parentDocumentId"];

    if ([parentDoc isNotNull]) {
      [map addObject:row forKey:parentDoc];
    }
    else {
      rootDoc = row;
    }
  }
  /* now create folder name/id dict */
  [self createCacheStructuresWithMap:map root:rootDoc];
  RELEASE(map); map = nil;
  TIME_END;
}

/*
  returns dictionary with doc-pkeys --> filename
  internal method
*/
- (NSMutableDictionary *)pk2FileNameCache {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:Pk2FileNameCache_key])) {
    [self initializeFolderNameCaches];
    dic = [self cacheValueForKey:Pk2FileNameCache_key];
    if (!dic) {
      NSLog(@"ERROR[%s]: missing pk2FileNameCache ...");
    }
  }
  return dic;
}

- (NGMutableHashMap *)parent2ChildDirectoriesCache {
  NGMutableHashMap *dic;
  
  if (!(dic = [self cacheValueForKey:Parent2ChildFolders_key])) {
    [self initializeFolderNameCaches];
    dic = [self cacheValueForKey:Parent2ChildFolders_key];
    if (dic == nil) {
      NSLog(@"ERROR[%s]: missing parent2ChildDirectoriesCache ...",
            __PRETTY_FUNCTION__);
    }
  }
  return dic;
}

/*
  dict with array with dict parent->childattrs
*/

- (NSMutableDictionary *)fileName2ChildAttrs {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:FileName2ChildAttrsCache_key])) {
    dic = [NSMutableDictionary dictionaryWithCapacity:16];
    [self takeCacheValue:dic forKey:FileName2ChildAttrsCache_key];
  }
  return dic;
}

/*
  cache status for folder or pk
*/
- (NSMutableDictionary *)cacheChildsForFolderStatusCache {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:CacheChildsForKeyCache_key])) {
    dic = [NSMutableDictionary dictionaryWithCapacity:16];
    [self takeCacheValue:dic forKey:CacheChildsForKeyCache_key];
  }
  return dic;

}

/*
  dict with array with dict parent->childnames
*/
- (NSMutableDictionary *)fileName2ChildNames {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:FileName2ChildNamesCache_key])) {
    dic = [NSMutableDictionary dictionaryWithCapacity:16];
    [self takeCacheValue:dic forKey:FileName2ChildNamesCache_key];
  }
  return dic;
}

/*
  dict with doc id -> version attrs
*/
- (NSMutableDictionary *)allVersionAttrsAtPathCache {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:VersionAttrsAtPathCache_key])) {
    dic = [NSMutableDictionary dictionaryWithCapacity:16];
    [self takeCacheValue:dic forKey:VersionAttrsAtPathCache_key];
  }
  return dic;
}

/*
  returns dictionary with pks --> GenRec
  internal method
*/
- (NSMutableDictionary *)pk2GenRecCache {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:Pk2GenRecCache_key])) {
    dic = [NSMutableDictionary dictionaryWithCapacity:127];
    [self takeCacheValue:dic forKey:Pk2GenRecCache_key];
  }
  return dic;
}

/*
  returns dictionary with filenames --> doc-pkeys
*/
- (NSMutableDictionary *)fileName2GIDCache {
  NSMutableDictionary *dic;
  
  if (!(dic = [self cacheValueForKey:FileName2GIDCache_key])) {
    [self initializeFolderNameCaches];
    dic = [self cacheValueForKey:FileName2GIDCache_key];
    if (!dic) {
      NSLog(@"ERROR[%s]: missing fileName2GIDCache ...");
    }
  }
  return dic;
}

/*
  builds string for dynamic select siblings
*/

- (NSString *)buildSelectForSiblingsSearch:(EOEntity *)_entity
  attrs:(NSArray *)_attrs
{
  NSMutableString *str;
  NSEnumerator    *enumerator;
  id              obj;
  BOOL            isDoc, isFirst;

  isDoc = [[_entity name] isEqualToString:@"Doc"];
  str   = [[NSMutableString alloc] initWithCapacity:256];

  [str appendString:@"SELECT"];

  enumerator = [_attrs objectEnumerator];
  isFirst    = YES;
  while ((obj = [enumerator nextObject])) {
    if (isFirst) {
      isFirst = NO;
      [str appendString:@" t1."];
    }
    else {
      [str appendString:@", t1."];
    }
    [str appendString:[obj columnName]];
  }
  if (isDoc) {
    NSString *docName, *docParentDocId;

    docName         = [_entity externalName];
    docParentDocId  = [[_entity attributeNamed:@"parentDocumentId"]                                  columnName];
    
    [str appendString:@" FROM "];
    [str appendString:docName];
    [str appendString:@" t1, "];
    [str appendString:docName];
    [str appendString:@" t2 where t1."];
    [str appendString:docParentDocId];
    [str appendString:@" = t2."];
    [str appendString:docParentDocId];
    [str appendString:@" AND t2."];
    [str appendString:[[_entity attributeNamed:@"projectId"] columnName]];
    [str appendString:@" = %@ AND t2."];
    [str appendString:[[_entity attributeNamed:@"documentId"] columnName]];
    [str appendString:@" in (%@)"];
  }
  else {
    EOEntity *docEntity;
    NSString *docName, *docParentDocId, *docDocId;

    docEntity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                                  entityNamed:@"Doc"];

    docName         = [docEntity externalName];
    docParentDocId  = [[docEntity attributeNamed:@"parentDocumentId"]
                                  columnName];
    docDocId        = [[docEntity attributeNamed:@"documentId"] columnName];
          
    [str appendString:@" FROM "];
    [str appendString:[_entity externalName]];
    [str appendString:@" t1, "];
    [str appendString:docName];
    [str appendString:@" t2, "];
    [str appendString:docName];
    [str appendString:@" t3 where t2."];
    [str appendString:[[docEntity attributeNamed:@"status"] columnName]];
    [str appendString:@" = 'edited' AND t1."];
    [str appendString:[[_entity attributeNamed:@"documentId"] columnName]];
    [str appendString:@" = t2."];
    [str appendString:docDocId];
    [str appendString:@" AND t2."];
    [str appendString:[[docEntity attributeNamed:@"isFolder"] columnName]];
    [str appendString:@" = 0 AND t2."];
    [str appendString:[[docEntity attributeNamed:@"projectId"] columnName]];
    [str appendString:@" = %@ AND t2."];
    [str appendString:docParentDocId];
    [str appendString:@" = t3."]; 
    [str appendString:docParentDocId];
    [str appendString:@" AND t3."];
    [str appendString:docDocId];
    [str appendString:@" in (%@)"];
  }
  {
    id tmp;

    tmp = str;
    str = [str copy];
    RELEASE(tmp); tmp = nil;
  }
  return AUTORELEASE(str);
}


- (NSString *)buildSelectForSiblingSearch:(EOEntity *)_entity
  attrs:(NSArray *)_attrs
{
  NSMutableString *str;
  NSEnumerator    *enumerator;
  id              obj;
  BOOL            isDoc, isFirst;

  isDoc = [[_entity name] isEqualToString:@"Doc"];
  str   = [[NSMutableString alloc] initWithCapacity:256];

  [str appendString:@"SELECT"];

  enumerator = [_attrs objectEnumerator];
  isFirst    = YES;
  while ((obj = [enumerator nextObject])) {
    if (isFirst) {
      isFirst = NO;
      [str appendString:@" t1."];
    }
    else {
      [str appendString:@", t1."];
    }
    [str appendString:[obj columnName]];
  }
  if (isDoc) {
    NSString *docName, *docParentDocId;

    docName         = [_entity externalName];
    docParentDocId  = [[_entity attributeNamed:@"parentDocumentId"]                                  columnName];
    
    [str appendString:@" FROM "];
    [str appendString:docName];
    [str appendString:@" t1, "];
    [str appendString:docName];
    [str appendString:@" t2 where t1."];
    [str appendString:docParentDocId];
    [str appendString:@" = t2."];
    [str appendString:docParentDocId];
    [str appendString:@" AND t2."];
    [str appendString:[[_entity attributeNamed:@"projectId"] columnName]];
    [str appendString:@" = %@ AND t2."];
    [str appendString:[[_entity attributeNamed:@"documentId"] columnName]];
    [str appendString:@" = %@"];
  }
  else {
    EOEntity *docEntity;
    NSString *docName, *docParentDocId, *docDocId;

    docEntity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                                  entityNamed:@"Doc"];

    docName         = [docEntity externalName];
    docParentDocId  = [[docEntity attributeNamed:@"parentDocumentId"]
                                  columnName];
    docDocId        = [[docEntity attributeNamed:@"documentId"] columnName];
          
    [str appendString:@" FROM "];
    [str appendString:[_entity externalName]];
    [str appendString:@" t1, "];
    [str appendString:docName];
    [str appendString:@" t2, "];
    [str appendString:docName];
    [str appendString:@" t3 where t2."];
    [str appendString:[[docEntity attributeNamed:@"status"] columnName]];
    [str appendString:@" = 'edited' AND t1."];
    [str appendString:[[_entity attributeNamed:@"documentId"] columnName]];
    [str appendString:@" = t2."];
    [str appendString:docDocId];
    [str appendString:@" AND t2."];
    [str appendString:[[docEntity attributeNamed:@"isFolder"] columnName]];
    [str appendString:@" = 0 AND t2."];
    [str appendString:[[docEntity attributeNamed:@"projectId"] columnName]];
    [str appendString:@" = %@ AND t2."];
    [str appendString:docParentDocId];
    [str appendString:@" = t3."]; 
    [str appendString:docParentDocId];
    [str appendString:@" AND t3."];
    [str appendString:docDocId];
    [str appendString:@" = %@"];
  }
  {
    id tmp;

    tmp = str;
    str = [str copy];
    RELEASE(tmp); tmp = nil;
  }
  return AUTORELEASE(str);
}

/*
  returns all docs for given parent; could be improved (set objectcs in C Array
*/

- (NSArray *)fetchDocsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  qualifier:(EOQualifier *)_qual
{
  static NSArray *docAttrs = nil;

  NSMutableArray   *result;
  NSDictionary     *row;
  EOEntity         *entity;
  EOAdaptorChannel *channel;

  if (_parentId && _sid) {
    NSLog(@"ERROR[%s]: internal inconsistency, _parentId != nil and _sid != nil",
          __PRETTY_FUNCTION__);
    return nil;
  }
  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"Doc"];
  if (!docAttrs) {
    docAttrs = [[entity attributes] retain];
  }
  channel = [self beginTransaction];

  if ([_parentId isNotNull]) {
    EOSQLQualifier *qualifier;
    
    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A = %@ AND %A = %@",
                                        @"parentDocumentId", _parentId,
                                        @"projectId",
                                        [self->project valueForKey:@"projectId"]];

    if (![channel selectAttributes:docAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, docAttrs);
      [self rollbackTransaction];
      RELEASE(qualifier); qualifier = nil;
      return nil;
    }
    RELEASE(qualifier); qualifier = nil;
  }
  else if ([_sid isNotNull]) {
    static NSString *selExpr = nil;

    NSString *expression;

    if (selExpr == nil) {
      selExpr = [self buildSelectForSiblingSearch:entity attrs:docAttrs];
      RETAIN(selExpr);
    }

    expression = [[NSString alloc] initWithFormat:selExpr,
                                   [self->project valueForKey:@"projectId"],
                                   _sid];

    if (![channel evaluateExpression:expression]) {
      NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
            __PRETTY_FUNCTION__, expression, docAttrs);
      RELEASE(expression); expression = nil;
      [self rollbackTransaction];
      return nil;
    }
    RELEASE(expression); expression = nil;
  }
  else if ([_qual isNotNull]) {
    NSString         *expr;
    EOSQLQualifier   *qualifier;
    EOAdaptorChannel *channel;

    channel   = [self beginTransaction];
    expr      = [_qual sqlExpressionWithAdaptor:
                       [[channel adaptorContext] adaptor]
                       attributes:docAttrs];
#if LIB_FOUNDATION_LIBRARY
    expr      = [expr stringByReplacingString:@"%" withString:@"%%"];
#else
#  warning FIXME: incorrect implementation for this Foundation library
#endif
    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:expr];

    if (![channel selectAttributes:docAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, docAttrs);
      [self rollbackTransaction];
      [qualifier release]; qualifier = nil;
      return nil;
    }
    [qualifier release]; qualifier = nil;
  }
  else {
    NSLog(@"ERROR[%s]: internal error ", __PRETTY_FUNCTION__);
    //    abort();
    return nil;
  }

  result = [NSMutableArray arrayWithCapacity:32];
  while ((row = [channel fetchAttributes:docAttrs withZone:NULL]))
    [result addObject:row];
  
  return result;
}

- (NSArray *)fetchDocsForSiblingIds:(NSArray *)_sids {
  static NSArray *docAttrs = nil;
  NSMutableArray   *results;
  NSDictionary     *row;
  EOEntity         *entity;
  EOAdaptorChannel *channel;

  if (MaxInQualifierCount == -1)
    [self initStaticVars];
  
  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"Doc"];
  if (!docAttrs) {
    docAttrs = [[entity attributes] retain];
  }
  channel = [self beginTransaction];
  {
    static NSString *selExpr = nil;

    int      cnt, i;
    NSString *expression;

    if (selExpr == nil) {
      selExpr = [[self buildSelectForSiblingsSearch:entity attrs:docAttrs] 
		  retain];
    }
    cnt     = [_sids count];
    results = [NSMutableArray arrayWithCapacity:cnt];

    for (i = 0; i < cnt; i+=MaxInQualifierCount) {
      NSArray *sArray;

      sArray = [_sids subarrayWithRange:
                     NSMakeRange(i,
                                 (cnt-i  > MaxInQualifierCount)
                                 ?MaxInQualifierCount:cnt-i)];
      
      expression = [[NSString alloc] initWithFormat:selExpr,
                                     [self->project valueForKey:@"projectId"],
                                     [sArray componentsJoinedByString:@","]];

      if (![channel evaluateExpression:expression]) {
        NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
              __PRETTY_FUNCTION__, expression, docAttrs);
        [expression release]; expression = nil;
        [self rollbackTransaction];
        return nil;
      }
      [expression release]; expression = nil;
      
      while ((row = [channel fetchAttributes:docAttrs withZone:NULL]))
        [results addObject:row];
    }
  }
  return results;
}

/*
  fetch nesscary document-editing for the given folder id
*/
- (NSDictionary *)fetchDocEditingsForSiblingIds:(NSArray *)_sids {
  static NSArray *editingAttrs = nil;
  NSMutableDictionary *results;
  EOEntity            *entity;
  EOAdaptorChannel    *channel;
  NSDictionary        *row;

  if (MaxInQualifierCount == -1)
    [self initStaticVars];

  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"DocumentEditing"];
  if (editingAttrs == nil)
    editingAttrs = [[entity attributes] retain];
  
  channel = [self beginTransaction];
  {
    static NSString *selExpr = nil;
    NSString *expression;
    int      i, cnt;

    if (selExpr == nil) {
      selExpr = [[self buildSelectForSiblingsSearch:entity attrs:editingAttrs]
		  retain];
    }
    
    cnt     = [_sids count];
    results = [NSMutableDictionary dictionaryWithCapacity:cnt];

    for (i = 0; i < cnt; i+=MaxInQualifierCount) {
      NSArray *sArray;

      sArray = [_sids subarrayWithRange:
			NSMakeRange(i, (cnt-i  > MaxInQualifierCount)
				    ?MaxInQualifierCount:cnt-i)];
      
      expression = [[NSString alloc] initWithFormat:selExpr,
                                     [self->project valueForKey:@"projectId"],
                                     [sArray componentsJoinedByString:@","]];
      
      if (![channel evaluateExpression:expression]) {
        NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
              __PRETTY_FUNCTION__, expression, editingAttrs);
        [expression release]; expression = nil;
        [self rollbackTransaction];
        return nil;
      }
      [expression release]; expression = nil;
      
      while ((row = [channel fetchAttributes:editingAttrs withZone:NULL]))
        [results setObject:row forKey:[row objectForKey:@"documentId"]];
    }
  }
  return results;
}

- (NSDictionary *)fetchDocEditingsForParentId:(NSNumber *)_parentId
  siblingId:(NSNumber *)_sid
  docPKeys:(NSArray *)_pkeys
{
  // TODO: split up this huge method!
  static NSArray *editingAttrs = nil;
  NSMutableDictionary *result;
  EOEntity            *entity;
  EOAdaptorChannel    *channel;
  NSDictionary        *row;

  if (_parentId && _sid) {
    NSLog(@"ERROR[%s]: internal inconsistency, _parentId != nil and _sid != nil",
          __PRETTY_FUNCTION__);
    return nil;
  }
  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"DocumentEditing"];
  if (editingAttrs == nil)
    editingAttrs = [[entity attributes] retain];
  
  channel = [self beginTransaction];

  if (_parentId) {
    EOSQLQualifier *qualifier;

    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"(%A = %@)"
                                        @" AND (%A = '%@') AND (%A = %@)"
                                        @" AND (%A = %@)",
                                        @"toDoc.isFolder", boolNum(NO),
                                        @"toDoc.status",   @"edited",
                                        @"toDoc.parentDocumentId", _parentId,
                                        @"toDoc.projectId",
                                        [self->project
                                             valueForKey:@"projectId"]];
    if (![channel selectAttributes:editingAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, editingAttrs);
      [self rollbackTransaction];
      [qualifier release]; qualifier = nil;
      return nil;
    }
    [qualifier release]; qualifier = nil;
  }
  else if (_sid) { /* now sid */
    static NSString *selExpr = nil;

    NSString *expression;

    if (selExpr == nil) {
      selExpr = [self buildSelectForSiblingSearch:entity attrs:editingAttrs];
      RETAIN(selExpr);
    }

    expression = [[NSString alloc] initWithFormat:selExpr,
                                   [self->project valueForKey:@"projectId"],
                                   _sid];

    if (![channel evaluateExpression:expression]) {
      NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
            __PRETTY_FUNCTION__, expression, editingAttrs);
      RELEASE(expression); expression = nil;
      [self rollbackTransaction];
      return nil;
    }
    RELEASE(expression); expression = nil;
  }
  else if ([_pkeys count]) {
    EOSQLQualifier *qualifier;

    if ([_pkeys count] > 200) { // --> fetch all
      qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                          qualifierFormat:@"%A = %@"
                                          @" AND %A = '%@' AND %A = %@",
                                          @"toDoc.isFolder", boolNum(NO),
                                          @"toDoc.status", @"edited",
                                          @"toDoc.projectId",
                                          [self->project
                                               valueForKey:@"projectId"]];
    }
    else {
      qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                          qualifierFormat:@"%A = %@"
                                          @" AND %A = '%@' AND %A in (%@)"
                                          @" AND %A = %@",
                                          @"toDoc.isFolder", boolNum(NO),
                                          @"toDoc.status", @"edited",
                                          @"toDoc.documentId",
                                          [_pkeys componentsJoinedByString:@","],
                                          @"toDoc.projectId",
                                          [self->project
                                               valueForKey:@"projectId"]];
    
    }
    if (![channel selectAttributes:editingAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, editingAttrs);
      [self rollbackTransaction];
      [qualifier release]; qualifier = nil;
      return nil;
    }
    [qualifier release]; qualifier = nil;
  }
  else
    return [NSDictionary dictionary];

  result = [NSMutableDictionary dictionaryWithCapacity:127];
  while ((row = [channel fetchAttributes:editingAttrs withZone:NULL]))
    [result setObject:row forKey:[row objectForKey:@"documentId"]];
  
  return result;
}

/* returns an login for a person_id */

- (NSString *)accountLogin4PersonId:(NSNumber *)_personId {
  NSDictionary *dict;
  NSString     *result;
  
  if (!(dict = [self cacheValueForKey:PersonId2LoginCache_key])) {
    static NSArray *personAttrs = nil;

    NSMutableDictionary *mdict;
    EOAdaptorChannel    *channel;
    EOSQLQualifier      *qualifier;
    EOEntity            *entity;
    NSDictionary        *row;
    

    entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                               entityNamed:@"Person"];
    if (!personAttrs) {
      personAttrs = [[NSArray alloc]
                              initWithObjects:
                              [entity attributeNamed:@"companyId"],
                              [entity attributeNamed:@"login"], nil];
    }
    channel = [self beginTransaction];

    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A = %@",
                                        @"isPerson", boolNum(YES),nil];

    if (![channel selectAttributes:personAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, personAttrs);
      [self rollbackTransaction];
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
      if (![l = [row valueForKey:@"login"] isNotNull]) {
        l = [cid stringValue];
      }
      [mdict setObject:l forKey:cid];
    }
    dict = [mdict copy];
    RELEASE(mdict);     mdict     = nil;
    RELEASE(qualifier); qualifier = nil;
    
    [self takeCacheValue:dict forKey:PersonId2LoginCache_key];
    AUTORELEASE(dict);
  }
  if (!(result = [dict objectForKey:_personId])) { /* missing login, take key */
    result = [_personId stringValue];
  }
  return result;
}

/* fetch objects for fileattributes and path2gid cache */
- (void)cacheChildsForFolder:(NSString *)_folder
  orSiblingsForId:(NSNumber *)_sid
{
  // TODO: split up this method
  EOKeyGlobalID       *gid;
  NSMutableDictionary *pk2fn, *fn2gid, *faAtPath;

  if (_folder && _sid) {
    NSLog(@"ERROR[%s]: internal inconsistency _folder != nil && _sid != nil",
          __PRETTY_FUNCTION__);
    return;
  }
  if (![_sid isNotNull] && ![_folder cStringLength]) {
    return;
  }

  gid = nil;
  { /* cache status for unknown objects ... */
    id                  statObj;
    NSMutableDictionary *mdict;
    
    mdict = [self cacheChildsForFolderStatusCache];

    statObj = (_folder) ? (id)_folder : (id)_sid;
      
    if ([mdict objectForKey:statObj]) {
      return;
    }
    
    [mdict setObject:[NSNumber numberWithBool:YES] forKey:statObj];
  }
  
  if (_folder) {
    gid = [[self fileName2GIDCache] objectForKey:_folder];
    if (![gid isNotNull]) {
#if 0      
      NSLog(@"WARNING[%s]: missing gid for path %@", __PRETTY_FUNCTION__,
            _folder);
#endif      
      return;
    }
  }  

  if (_sid || gid) {
    NSArray        *docs;
    NSMutableArray *childAttrs, *childNames;
    NSDictionary   *docEditings;
    NSEnumerator   *enumerator;
    NSNumber       *parentId, *pid;
    id             doc;

    pid         = [self->project valueForKey:@"projectId"];
    childAttrs  = [NSMutableArray arrayWithCapacity:127];
    childNames  = [NSMutableArray arrayWithCapacity:127];

    parentId    = (gid) ? [gid keyValues][0] : nil;
    docs        = [self fetchDocsForParentId:parentId siblingId:_sid
                        qualifier:nil];
    docEditings = [self fetchDocEditingsForParentId:parentId siblingId:_sid
                        docPKeys:nil];
    enumerator  = [docs objectEnumerator];

    if (!_folder && [docs count]) { /* got parent from cache */
      static int recursionFlag = 0;
        
      NSNumber *key;

      if (recursionFlag > 10) {
        NSLog(@"ERROR[%s] internal inconsistency recursion during get attrs ..",
              __PRETTY_FUNCTION__);
        return;
      }
      recursionFlag++;
      key = [[docs lastObject] objectForKey:@"parentDocumentId"];
      if ([key isNotNull]) {
        EOKeyGlobalID *gid;
        
        gid = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                             keys:&key keyCount:1 zone:NULL];
        _folder = [self pathForGID:gid manager:nil];
      }
      recursionFlag--;
    }
    fn2gid   = [self fileName2GIDCache];
    pk2fn    = [self pk2FileNameCache];
    faAtPath = [self fileAttributesAtPathCache];
    while ((doc = [enumerator nextObject])) {
      NSDictionary  *fileAttrs;
      NSString      *path;
      EOKeyGlobalID *gid;

      fileAttrs = [SkyProjectFileManager buildFileAttrsForDoc:doc
                                         editing:[docEditings objectForKey:
                                             [doc objectForKey:@"documentId"]]
                                         atPath:_folder isVersion:NO
                                         projectId:[self->project
                                                        valueForKey:
                                                        @"projectId"]
                                         fileAttrContext:self];
      gid  = [fileAttrs objectForKey:@"globalID"];
      path = [fileAttrs objectForKey:@"NSFilePath"];

      [fn2gid   setObject:gid forKey:path];
      [pk2fn    setObject:path forKey:[gid keyValues][0]];
      [faAtPath setObject:fileAttrs forKey:path];
      [childAttrs addObject:fileAttrs];
      [childNames addObject:[fileAttrs objectForKey:@"NSFileName"]];
      [SkyProjectFileManager setProjectID:pid forDocID:[gid keyValues][0]
                             context:self->context];
    }
    [[childNames copy] autorelease];
    [[childAttrs copy] autorelease];
    if (_folder) {
      [[self fileName2ChildAttrs] setObject:childAttrs forKey:_folder];
      [[self fileName2ChildNames] setObject:childNames forKey:_folder];
    }
    else if ([childAttrs count]) {
      NSDictionary *child;

      child = [childAttrs lastObject];
      _folder = [[child objectForKey:NSFilePath]
                        stringByDeletingLastPathComponent];
      [[self fileName2ChildAttrs] setObject:childAttrs forKey:_folder];
      [[self fileName2ChildNames] setObject:childNames forKey:_folder];
    }
  }
}

- (void)cacheChildsForSiblings:(NSArray *)_siblingIds {
  NSMutableDictionary *pk2fn, *fn2gid, *faAtPath;
  NSArray             *docs;
  NSDictionary        *docEditings;
  NSEnumerator        *enumerator;
  id                  doc;
  NSNumber            *pid;
  
  pid         = [self->project valueForKey:@"projectId"];
  docs        = [self fetchDocsForSiblingIds:_siblingIds];
  docEditings = [self fetchDocEditingsForSiblingIds:_siblingIds];
  enumerator  = [docs objectEnumerator];

  fn2gid   = [self fileName2GIDCache];
  pk2fn    = [self pk2FileNameCache];
  faAtPath = [self fileAttributesAtPathCache];
  while ((doc = [enumerator nextObject])) {
    NSDictionary  *fileAttrs;
    NSString      *path;
    EOKeyGlobalID *gid;
    NSString      *folder;

    {
      NSNumber *key;
        
      key = [doc objectForKey:@"parentDocumentId"];
      
      if ([key isNotNull]) {
        gid = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                             keys:&key keyCount:1 zone:NULL];
        folder = [self pathForGID:gid manager:nil];
      }
      else {
        NSLog(@"ERROR[%s] missing parentDocumentId", __PRETTY_FUNCTION__);
        continue;
      }
    }
    fileAttrs = [SkyProjectFileManager buildFileAttrsForDoc:doc
                                       editing:[docEditings objectForKey:
                                              [doc objectForKey:@"documentId"]]
                      atPath:folder isVersion:NO
                                       projectId:[self->project
                                                      valueForKey:@"projectId"]
                                       fileAttrContext:self];
    gid  = [fileAttrs objectForKey:@"globalID"];
    path = [fileAttrs objectForKey:@"NSFilePath"];

    [fn2gid   setObject:gid forKey:path];
    [pk2fn    setObject:path forKey:[gid keyValues][0]];
    [faAtPath setObject:fileAttrs forKey:path];
    [SkyProjectFileManager setProjectID:pid forDocID:[gid keyValues][0]
                           context:self->context];
    {
      NSMutableArray *array;

      if (!(array = [[self fileName2ChildAttrs] objectForKey:folder])) {
          array = [NSMutableArray arrayWithCapacity:8];
          [[self fileName2ChildAttrs] setObject:array forKey:folder];
      }
      [array addObject:fileAttrs];
      if (!(array = [[self fileName2ChildNames] objectForKey:folder])) {
          array = [NSMutableArray arrayWithCapacity:8];
          [[self fileName2ChildNames] setObject:array forKey:folder];
      }
      [array addObject:[fileAttrs objectForKey:NSFileName]];
    }          
  }
}

- (NSException *)handleRootFolderAttrsException:(NSException *)_exception {
  NSLog(@"ERROR[-rootFolderAttrs]: catched exception: %@", _exception);
  return nil;
}
- (NSDictionary *)rootFolderAttrs {
  id   root;
  BOOL isOk;
    
  NS_DURING {
    isOk = YES;
    [self->context runCommand:@"project::get-root-document",
         @"object",      self->project,
         @"relationKey", @"rootDocument",
         nil];
  }
  NS_HANDLER {
    isOk = NO;
    [[self handleRootFolderAttrsException:localException] raise];
  }
  NS_ENDHANDLER;
  if (!isOk)
    return nil;
  
  root = [self->project valueForKey:@"rootDocument"];

  return [SkyProjectFileManager buildFileAttrsForDoc:root
                                editing:nil atPath:nil
                                isVersion:NO
                                projectId:[self->project
                                               valueForKey:@"projectId"]
                                fileAttrContext:self];
}

- (NSMutableDictionary *)fileAttributesAtPathCache {
  NSMutableDictionary *dict;
  NSDictionary *rootAttrs;
  
  if ((dict = [self cacheValueForKey:Path2FileAttributesCache_key]) != nil)
    return dict;
  
  if ((rootAttrs = [self rootFolderAttrs]) == nil) {
    [self logWithFormat:@"missing root-folder attributes?!"];
    return nil;
  }
  
  dict = [NSMutableDictionary dictionaryWithCapacity:16];
  [dict setObject:rootAttrs forKey:@"/"];
  [self takeCacheValue:dict forKey:Path2FileAttributesCache_key];
  return dict;
}

- (NSString *)buildSelectForAllSubVersionsWithAttributes:(NSArray *)_attrs {
  NSMutableString *str;
  NSEnumerator    *enumerator;
  id              obj;
  BOOL            isFirst;
  EOEntity        *docEntity, *docVersionEntity;
  EOModel         *model;
  
  model            = [[[self->context valueForKey:LSDatabaseKey] adaptor] model];
  docVersionEntity = [model entityNamed:@"DocumentVersion"];
  docEntity        = [model entityNamed:@"Doc"];
  str              = [[NSMutableString alloc] initWithCapacity:256];
  enumerator       = [_attrs objectEnumerator];
  isFirst          = YES;

  [str appendString:@"SELECT"];
  
  while ((obj = [enumerator nextObject])) {
    if (isFirst) {
      isFirst = NO;
      [str appendString:@" t2."];
    }
    else {
      [str appendString:@", t2."];
    }
    [str appendString:[obj columnName]];
  }
  {
    NSString *docName, *docParentDocId, *docId;

    docName         = [docEntity externalName];
    docParentDocId  = [[docEntity attributeNamed:@"parentDocumentId"]
                                  columnName];
    docId           = [[docEntity attributeNamed:@"documentId"]
                                  columnName];
    
    [str appendString:@" FROM "];
    [str appendString:docName];
    [str appendString:@" t1, "];
    [str appendString:[docVersionEntity externalName]];
    [str appendString:@" t2 where (t1."];
    [str appendString:docParentDocId];
    [str appendString:@" = %@) AND (t2."];
    [str appendString:[[docVersionEntity attributeNamed:@"documentId"]
                                         columnName]];
    [str appendString:@" = t1."];
    [str appendString:docId];
    [str appendString:@")"];
  }
  {
    id tmp;
    
    tmp = str;
    str = [str copy];
    [tmp release]; tmp = nil;
  }
  return [str autorelease];
}


@end /* SkyProjectFileManagerCache(Internals) */
