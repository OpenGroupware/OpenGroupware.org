/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoProject/NSString+XMLNamespaces.h>

// #define DEBUG_DOCS_FOR_OBJS 1
// #define DEBUG_FILEATTRS_FOR_GIDS 1

@class NSArray, EOGenericRecord;

@interface SkyProjectFileManagerCache(Internals)
- (NSArray *)pathsForGIDs:(NSArray *)_gids manager:(id)_manager;
@end

@interface SkyProjectFileManager(Internals)
- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path flush:(BOOL)_doFlush;
- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path
  handler:(id)_handler flush:(BOOL)_doFlush;

- (void)_checkCWDFor:(NSString *)_source;
- (id)_project;
- (NSString *)_defaultCompleteProjectDocumentNamespace;
- (NSArray *)subDirectoryNamesForPath:(NSString *)_path;
- (NSString *)_makeAbsolute:(NSString *)_path;
- (void)_subpathsAtPath:(NSString *)_path array:(NSMutableArray *)_array;
- (BOOL)_copyPath:(NSString*)_src toPath:(NSString*)_dest handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handleru;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
 handler:(id)_handler;

@end /* SkyProjectFileManager(Internals) */

@interface SkyProjectDocument(Internals)
- (void)refetchFileAttrs;
- (void)refetchProperties;
- (void)_setFileAttributes:(NSDictionary *)_fAttrs;

- (void)_setBlobChanged:(BOOL)_b;
- (void)_setGlobalID:(EOGlobalID *)_gid;
- (BOOL)_subjectChanged;
- (void)_setSubjectChanged:(BOOL)_bool;
- (BOOL)_blobChanged;
- (void)_setBlobChanged:(BOOL)_bool;
- (void)_setIsEdited:(BOOL)_bool;
- (NSMutableDictionary *)_newAttrs;
- (NSMutableDictionary *)_updateAttrs;
- (NSMutableDictionary *)_newExtAttrs;
- (NSMutableDictionary *)_updateExtAttrs;
- (void)_takeAttributesFromDictionary:(NSDictionary *)_dict
  namespace:(NSString *)_ns isComplete:(BOOL)_isComplete;
- (void)_registerForGID;
- (void)setBlob:(id)_b;
- (id)blob;
@end

@interface SkyProjectFileManager(ErrorHandling_Internals)
- (void)_initializeErrorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
@end /* SkyProjectFileManager(ErrorHandling+Internals) */

@interface SkyProjectFileManager(Documents_Internals)
- (NSArray *)readOnlyDocumentKeys;
- (NSArray *)documentsForObjects:(NSArray *)_objs
  withAttributes:(NSArray *)_attrs;
- (void)fetchAttributes:(NSArray *)_attrs forDocs:(NSArray *)_objs;
- (NSMutableDictionary *)_mapAttrsNamespaces:(NSDictionary *)_dict
  forDoc:(SkyProjectDocument *)_doc;
- (NSArray *)_fileAttributesForDocGIDs:(NSArray *)_dGIDs;
@end

#include "common.h"

@implementation SkyProjectFileManager(Documents)

- (NSString *)defaultProjectDocumentNamespace {
  return @"http://www.skyrix.com/namespaces/project-document";
}

- (SkyProjectDocument *)documentAtPath:(NSString *)_path {
  EOGlobalID *gid;

  if (!(gid = [self globalIDForPath:_path])) {
    return nil;
  }
  return AUTORELEASE([[SkyProjectDocument alloc] initWithGlobalID:gid
                                                 fileManager:self]);
}

- (BOOL)writeDocument:(SkyProjectDocument *)_doc toPath:(NSString *)_path {
  /*
    Kombinationen:

      1. Dokument hat keinen Filenamen (neu), _path ist unbelegt
         -> ungueltig
      2. Dokument hat keinen Filenamen (neu), _path ist ein File
         -> _path wird Dokument-Filename
      3. Dokument hat keinen Filenamen (neu), _path ist ein Directory
         -> neuer Filename wird durch _path+newKey erzeugt

      4. Dokument hat Filenamen, _path ist unbelegt
         -> Dokument wird unter eigenem Namen gespeichert
      5. Dokument hat Filenamen, _path ist ein File
         -> Dokument wird unter _path neu gespeichert (copy Operation)
      6. Dokument hat Filenamen, _path ist ein Directory
         -> neuer Filename wird durch _path+Filename erzeugt
  */
  EOGlobalID *gid;
  BOOL       isDir;
  NSString   *docPath;
  
  /* preconditions */

  if (_doc == nil) {
    return [self _buildErrorWithSource:_path dest:nil msg:39 handler:nil
                 cmd:_cmd];
  }
  if (![_doc isComplete]) {
    return [self _buildErrorWithSource:_path dest:nil msg:40 handler:nil
                 cmd:_cmd];
  }
  docPath = [_doc valueForKey:NSFilePath];
  
  if ((![_path length]) && (![docPath length])) {
    return [self _buildErrorWithSource:_path dest:nil msg:34 handler:nil
                 cmd:_cmd];
  }
  if (![_path length])
    _path = docPath;

  isDir = NO;
  if ([self fileExistsAtPath:_path isDirectory:&isDir]) {
    if (isDir) {
      /* destination path is a directory, autocreate document filename */
      NSString *tmpFilePath, *tmpFile;

      tmpFile     = @".skyrixautocreate.txt";
      tmpFilePath = [_path stringByAppendingPathComponent:tmpFile];

      while ([self fileExistsAtPath:tmpFilePath isDirectory:NULL]) {
        tmpFile     = [@"." stringByAppendingString:tmpFile];
        tmpFilePath = [_path stringByAppendingString:tmpFile];
      }
      if (![self createFileAtPath:tmpFilePath contents:[NSData data]
                 attributes:nil]) {
        NSLog(@"%s: couldn`t create %@", __PRETTY_FUNCTION__, tmpFilePath);
        return NO;
      }
      {
        NSString *pName, *gidStr;
        id       genRec;
        int      ec;

        genRec = [self->cache genericRecordForFileName:tmpFilePath manager:self];
        gidStr = [[(EOKeyGlobalID *)[genRec globalID] keyValues][0] stringValue];
        pName  = [gidStr stringByAppendingPathExtension:@"txt"];
        _path  = [_path stringByAppendingPathComponent:pName];
        NS_DURING {
          ec = 0;
          [[self->cache context] runCommand:@"doc::set",
                                 @"object", genRec,
                                 @"title", gidStr,
                                 @"fileType", @"txt", nil];
        }
        NS_HANDLER {
          ec = 41;
          [self setLastException:localException];
          fprintf(stderr, "%s: doc::set failed genrec %s, %s\n", __PRETTY_FUNCTION__,
                  [[genRec description] cString], [gidStr cString]);
                  
        }
        NS_ENDHANDLER;
        if (ec) {
          if (![self removeFileAtPath:tmpFilePath handler:nil]) {
            ec = 42;
          }
          return [self _buildErrorWithSource:_path dest:nil msg:ec handler:nil
                       cmd:_cmd];
        }
        [self flush];
      }
    }
    else { /* overwrite file */
      /* update will be done during update */
    }
  }
  else if (![self createFileAtPath:_path contents:[NSData data]
                  attributes:nil]) {
    NSLog(@"%s: couldn`t create file on path %@", __PRETTY_FUNCTION__, _path);
    return NO;
  }
  if (!(gid = [self globalIDForPath:_path])) {
    NSLog(@"%s: didn`t found gid for path %@", __PRETTY_FUNCTION__, _path);
    return NO;
  }
  if (![_doc globalID]) {
    [_doc takeValue:_path forKey:NSFilePath];
    [_doc _setGlobalID:gid];
  }
  return [self updateDocument:_doc];
}

- (SkyProjectDocument *)createDocumentAtPath:(NSString *)_path
                                    contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs
{
  SkyProjectDocument *doc;

  if ([_path length]) {
    if (![self createFileAtPath:_path contents:_contents attributes:nil])
      /* couldn't create file at the specified path */
      return nil;
  
    if (!(doc = [self documentAtPath:_path])) {
      /* couldn't find created file at the specified path */
      NSLog(@"WARNING[%s]: internal error, can't find file created at path '%@'",
            __PRETTY_FUNCTION__, _path);
      return nil;
    }

    /* apply attributes */
    if ([_attrs count]) {
      /* apply attributes */
      [doc takeValuesFromDictionary:_attrs];
      
      /* write attributes */
      if (![self writeDocument:doc toPath:nil]) {
        /* couldn't write attributes of document at the specified path */
      
        /* remove created file .. */
        if (![self removeFileAtPath:_path handler:nil]) {
          NSLog(@"WARNING[%s]: couldn't delete file created at path '%@'",
                __PRETTY_FUNCTION__, _path);
        }
        return nil;
      }
    }
  }
  else {
    doc = [[SkyProjectDocument alloc] initWithGlobalID:nil fileManager:self];
    AUTORELEASE(doc);
    
    [doc setBlob:_contents];
    
    if ([_attrs count])
      [doc takeValuesFromDictionary:_attrs];
  }
  /* finished document creation */
  return doc;
}

- (BOOL)deleteDocument:(SkyProjectDocument *)_doc {
  NSException *exc;
  EOGlobalID  *gid;
  
  if (![_doc isValid])
    return NO;

  if (!(gid = [_doc globalID])) {
    NSLog(@"WARNING[%s]: try to delete new document %@",
          __PRETTY_FUNCTION__, _doc);
    [_doc invalidate];
    return YES;
  }
  if (![self removeFileAtPath:[[_doc fileAttributes] valueForKey:NSFilePath]
	     handler:nil]) {
    return NO;
  }
  /* access already granted */
  if ((exc = [[[self context] propertyManager]
                     removeAllPropertiesForGlobalID:gid
                     checkAccess:NO]) != nil) {
    NSLog(@"WARNING[%s]: remove of properties for %@ failed, got %@",
          __PRETTY_FUNCTION__, _doc, exc);
  }
  [_doc invalidate];
  return YES;
}

- (BOOL)updateDocument:(SkyProjectDocument *)_doc {
  NSMutableDictionary      *attrs, *tmpAttrs;
  NSException              *exc;
  SkyObjectPropertyManager *pm;
  EOGlobalID               *gid;
  NSString                 *status;

  /* check for checkout */
  status   = [[_doc fileAttributes] objectForKey:@"SkyStatus"];
  tmpAttrs = nil;

  if ([status isEqualToString:@"edited"]) {
    id a   = nil;
    id aid = nil;

    a   = [[self->cache context] valueForKey:LSAccountKey];
    aid = [a valueForKey:@"companyId"];

    if (![[[_doc fileAttributes] objectForKey:@"SkyOwnerId"] isEqual:aid] &&
        ([aid intValue] != 10000))
      return NO;
  }
  
  if (!(pm = [[self context] propertyManager])) {
    return [self _buildErrorWithSource:nil dest:nil msg:43 handler:nil
                 cmd:_cmd];
  }
  if (!(gid = [_doc globalID])) {
    return [self _buildErrorWithSource:nil dest:nil msg:44 handler:nil
                 cmd:_cmd];
  }
  if ([_doc _blobChanged]) {
    if (![self writeContents:[_doc blob] atPath:[_doc valueForKey:@"NSFilePath"]
               handler:nil flush:NO])
      return NO;
    [_doc _setBlobChanged:NO];
  }
  if ([_doc _subjectChanged]) {
    NSString *docSub;
    
    if (!(docSub = [_doc subject]))
      docSub = @"";
    
    if (![self changeFileAttributes:[NSDictionary dictionaryWithObject:
                                                    docSub
                                                  forKey:@"NSFileSubject"]
               atPath:[_doc valueForKey:NSFilePath] flush:NO])
    return NO;
    [_doc _setSubjectChanged:NO];
  }
  if ([(attrs = [_doc _newAttrs]) count]) {
    tmpAttrs = [self _mapAttrsNamespaces:attrs forDoc:_doc];
    [attrs removeAllObjects];
  }
  if ([(attrs = [_doc _newExtAttrs]) count]) {
    if (tmpAttrs) {
      [tmpAttrs addEntriesFromDictionary:attrs];
    }
    else {
      tmpAttrs = [attrs mutableCopy];
      AUTORELEASE(tmpAttrs);
    }
    [attrs removeAllObjects];
  }
  if (tmpAttrs) {
    /* remove EONull values */
    NSEnumerator *enumerator;
    id           obj;
      
    enumerator = [[tmpAttrs allKeys] objectEnumerator];
      
    while ((obj = [enumerator nextObject])) {
      if (![[tmpAttrs objectForKey:obj] isNotNull])
        [tmpAttrs removeObjectForKey:obj];
    }
    if ((exc = [pm addProperties:tmpAttrs accessOID:nil globalID:gid])) {
      [self setLastException:exc];
      return [self _buildErrorWithSource:nil dest:nil msg:45 handler:nil
                   cmd:_cmd];
    }
  }
  tmpAttrs = nil;
  if ([(attrs = [_doc _updateAttrs]) count]) {
    tmpAttrs = [self _mapAttrsNamespaces:attrs forDoc:_doc];
    [attrs removeAllObjects];
  }
  if ([(attrs = [_doc _updateExtAttrs]) count]) {
    if (tmpAttrs) {
      [tmpAttrs addEntriesFromDictionary:attrs];
    }
    else {
      tmpAttrs = [attrs copy];
      AUTORELEASE(tmpAttrs);
    }
    [attrs removeAllObjects];
  }
  if (tmpAttrs) { /* keys with EONull as value will be removed */
    NSEnumerator *enumerator;
    id           obj, *delKeys;
    NSArray      *keys;
    int          cnt;

    keys       = [tmpAttrs allKeys];
    delKeys    = calloc([keys count], sizeof(id));
    enumerator = [keys objectEnumerator];
    cnt        = 0;
    while ((obj = [enumerator nextObject])) {
      if (![[tmpAttrs objectForKey:obj] isNotNull]) {
        delKeys[cnt] = [[obj retain] autorelease];
        cnt++;
        [tmpAttrs removeObjectForKey:obj];
      }
    }
    if (cnt) {
      keys = [[NSArray alloc] initWithObjects:delKeys count:cnt];
      if ((exc = [pm removeProperties:keys globalID:gid]) != nil) {
        [self setLastException:exc];
        return [self _buildErrorWithSource:nil dest:nil msg:46 handler:nil
                     cmd:_cmd];
      }
      RELEASE(keys); keys = nil;
    }
  }
  if ((exc = [pm updateProperties:tmpAttrs globalID:gid]) != nil) {
    [self setLastException:exc];
    return [self _buildErrorWithSource:nil dest:nil msg:47 handler:nil
                 cmd:_cmd];
  }
  [_doc _setIsEdited:NO];
  [self flush];
  return YES;
}
@end


@implementation SkyProjectFileManager(Document_Internals)

- (NSArray *)readOnlyDocumentKeys {
  static NSArray *readOnlyDocumentKeys = nil;

  if (readOnlyDocumentKeys == nil) {
    readOnlyDocumentKeys = [[NSArray alloc]
                                     initWithObjects:
                                     @"NSFileMimeType",
                                     @"NSFileModificationDate",
                                     @"NSFileName",
                                     @"NSFileOwnerAccountName",
                                     @"NSFileOwnerAccountNumber",
                                     @"NSFilePath",
                                     @"NSFileSize",
                                     @"NSFileType",
                                     @"SkyCreationDate",
                                     @"SkyFileName",
                                     @"SkyFilePath",
                                     @"SkyFirstOwnerId",
                                     @"SkyIsVersion",
                                     @"SkyLastModifiedDate",
                                     @"SkyOwnerId",
                                     @"SkyStatus",
                                     @"SkyVersionCount",
                                     @"creationDate",
                                     @"fileSize",
                                     @"fileType",
                                     @"filename",
                                     @"globalID",
                                     @"lastmodifiedDate",
                                     @"status",
                                     @"versionCount", nil];
  }
  return readOnlyDocumentKeys;
}

- (NSArray *)documentsForObjects:(NSArray *)_objs
  withAttributes:(NSArray *)_attrs
{
  static Class GidClass = Nil;
  static Class DocClass = Nil;
  id           *skyDocs, *gids, obj;
  int          gidCnt, skyDocCnt;
  NSEnumerator *enumerator;

  if (![_objs count])
    return [NSArray array];
  
  /* wrap the objects into documents ... */
  
  if (GidClass == Nil) GidClass = [EOGlobalID class];
  if (DocClass == Nil) DocClass = [SkyProjectDocument class];
  
  skyDocs    = calloc([_objs count], sizeof(id));
  gids       = calloc([_objs count], sizeof(id));
  enumerator = [_objs objectEnumerator];
  gidCnt     = 0;
  skyDocCnt  = 0;
  
  while ((obj = [enumerator nextObject])) {
    BOOL isDict;

    isDict = YES;
    if ([obj isKindOfClass:GidClass]) {
      isDict         = NO;
      gids[gidCnt++] = obj;
    }
    else {
      EOGlobalID *gid;
      
      if ((gid = [obj valueForKey:@"globalID"]) == nil) {
        NSLog(@"WARNING[%s]:got no global id for doc %@ during creating "
              @"SkyProjectDocument, doc will be ignored", __PRETTY_FUNCTION__,
              obj);
      }
      else {
        skyDocs[skyDocCnt] = [[DocClass alloc] initWithGlobalID:gid
                                               fileManager:self];
        [skyDocs[skyDocCnt] _setFileAttributes:obj];
        //#warning do not autorelease 10000 objects
        //        AUTORELEASE(skyDocs[skyDocCnt]);
        skyDocCnt++;
      }
    }
  }
  if (gidCnt > 0) {
    id      o;
    NSArray *gidArr;
    
#if DEBUG_DOCS_FOR_OBJS
    NSLog(@"%s:  process %i gids ...", __PRETTY_FUNCTION__, gidCnt);
#endif
    
    gidArr = [[NSArray alloc] initWithObjects:gids count:gidCnt];
    
    {
      NSAutoreleasePool *pool;
      
      pool = [[NSAutoreleasePool alloc] init];
#if DEBUG_DOCS_FOR_OBJS
      NSLog(@"%s:    get attrsfor gids ...", __PRETTY_FUNCTION__);
#endif
      
      enumerator = [[self _fileAttributesForDocGIDs:gidArr] objectEnumerator];
#if DEBUG_DOCS_FOR_OBJS
      NSLog(@"%s:    done.", __PRETTY_FUNCTION__);
#endif
      RETAIN(enumerator);
      RELEASE(pool);
      AUTORELEASE(enumerator);
    }
    
    while ((o = [enumerator nextObject])) {
      skyDocs[skyDocCnt] =
        [[DocClass alloc]
                   initWithGlobalID:[o valueForKey:@"globalID"]
                   fileManager:self];
      [skyDocs[skyDocCnt] _setFileAttributes:o];
      //#warning do not autorelease 10000 objects
      //      AUTORELEASE(skyDocs[skyDocCnt]);
      skyDocCnt++;
    }
    
    RELEASE(gidArr); gidArr = nil;
  }
  _objs = [[NSArray alloc] initWithObjects:skyDocs count:skyDocCnt];
  {
    int i;
    for (i=0; i<skyDocCnt; i++) {
      [skyDocs[i] release];
    }
  }
  AUTORELEASE(_objs);
  free(gids);    gids    = NULL;
  free(skyDocs); skyDocs = NULL;
  
  /* fetch the attributes */
  
#if DEBUG_DOCS_FOR_OBJS
  NSLog(@"%s:  fetching attrs for %i docs ...",
        __PRETTY_FUNCTION__, [_objs count]);
#endif
  [self fetchAttributes:_attrs forDocs:_objs];
#if DEBUG_DOCS_FOR_OBJS
  NSLog(@"%s: returned %i docs.", __PRETTY_FUNCTION__, [_objs count]);
#endif
  
  return _objs;
}

- (void)fetchAttributes:(NSArray *)_attrs forDocs:(NSArray *)_objs {
  if (_attrs && [_attrs count]) {
    NSArray                  *docKeys, *gids;
    NSString                 *obj, *ns;
    NSMutableSet             *nameSpaces;
    SkyObjectPropertyManager *pm;
    NSEnumerator             *enumerator;
    
    nameSpaces = [[NSMutableSet alloc] init];
    docKeys    = [self readOnlyDocumentKeys];
    enumerator = [_attrs objectEnumerator];
    
    while ((obj = [enumerator nextObject])) {
      if ([docKeys containsObject:obj])
        continue;

      ns = [obj hasXMLNamespace]
        ? [obj xmlNamespace]
        : [self defaultProjectDocumentNamespace];
      
      [nameSpaces addObject:ns];
    }
    gids       = [_objs map:@selector(globalID)];
    enumerator = [nameSpaces objectEnumerator];
    pm         = [[self context] propertyManager];
    
    while ((ns = [enumerator nextObject])) {
      NSDictionary *nsRes;
      NSEnumerator *objEnum;
      id           o;

      nsRes   = [pm propertiesForGlobalIDs:gids namespace:ns];
      objEnum = [_objs objectEnumerator];
      
      while ((o = [objEnum nextObject])) {
        [o _takeAttributesFromDictionary:[nsRes objectForKey:[o globalID]]
           namespace:ns isComplete:YES]; /* all default ns */
      }
    }
    RELEASE(nameSpaces); nameSpaces = nil;
  }
}
- (NSMutableDictionary *)_mapAttrsNamespaces:(NSDictionary *)_dict
  forDoc:(SkyProjectDocument *)_doc
{
  id           *keys, *values, key;
  int          dCnt, cnt;
  NSEnumerator *enumerator;
  NSDictionary *result;
  NSString     *ns;

  dCnt       = [_dict count];
  keys       = calloc(dCnt, sizeof(id));
  values     = calloc(dCnt, sizeof(id));
  enumerator = [[_dict allKeys] objectEnumerator];
  cnt        = 0;
  ns         = [self _defaultCompleteProjectDocumentNamespace];
  
  while ((key = [enumerator nextObject])) {
    NSString *vkey;
    id       vvalue;
    
    vkey   = [ns stringByAppendingString:key];
    vvalue = [_dict objectForKey:key];
    
    keys[cnt]   = vkey;
    values[cnt] = vvalue;
    cnt++;
  }
  result = [[NSMutableDictionary alloc]
                                 initWithObjects:values forKeys:keys count:cnt];
  free(keys);   keys   = NULL;
  free(values); values = NULL;
  return AUTORELEASE(result);
}

- (NSArray *)_fileAttributesForDocGIDs:(NSArray *)_dGIDs {
  NSEnumerator *enumerator;
  NSArray      *paths;
  NSArray      *result;
  id           *objs, obj;
  int          cnt;

  if (![_dGIDs count])
    return [NSArray array];
  
  objs       = malloc(sizeof(id) * [_dGIDs count]);
  cnt        = 0;
  paths      = [self->cache  pathsForGIDs:_dGIDs manager:self];
  enumerator = [paths objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    objs[cnt++] = [self->cache fileAttributesAtPath:obj manager:self];
  }
  result = [NSArray arrayWithObjects:objs count:cnt];
  free(objs); objs = NULL;
  return result;
}

@end /* Document_Internals */

