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

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoProject/NSString+XMLNamespaces.h>

// TODO: this needs serious cleanup
// TODO: use constants for error codes!

@class NSArray, EOGenericRecord;

@interface SkyProjectFileManagerCache(Internals)
- (NSArray *)pathsForGIDs:(NSArray *)_gids manager:(id)_manager;
@end

@interface SkyProjectFileManager(Internals)
- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path flush:(BOOL)_doFlush;
- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path
  handler:(id)_handler flush:(BOOL)_doFlush;

- (id)_project;
- (NSString *)_defaultCompleteProjectDocumentNamespace;

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

static BOOL debugDocMapping = NO;
static BOOL debugAttrFetch  = NO;

@implementation SkyProjectFileManager(Documents)

- (NSString *)defaultProjectDocumentNamespace {
  return @"http://www.skyrix.com/namespaces/project-document";
}

- (SkyProjectDocument *)documentAtPath:(NSString *)_path {
  EOGlobalID *gid;

  if ((gid = [self globalIDForPath:_path]) == nil)
    return nil;
  
  return [[[SkyProjectDocument alloc] initWithGlobalID:gid
				      fileManager:self] autorelease];
}

- (BOOL)writeDocument:(SkyProjectDocument *)_doc toPath:(NSString *)_path {
  /*
    Combinations:
    
      1. document has no filename (is new), _path is unassigned
         -> invalid
      2. document has no filename (is new), _path is a file
         -> _path becomes document filename
      3. document has no filename (is new), _path is a directory
         -> new filename is generated by _path+newKey

      4. document has filename, _path is unassigned
         -> document is saved under own name
      5. document has filename, _path is a file
         -> document is created under _path (copy operation)
      6. document has filename, _path is a directory
         -> new filename is generated by _path+filename
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
  
  if (([_path length] == 0) && ([docPath length] == 0)) {
    return [self _buildErrorWithSource:_path dest:nil msg:34 handler:nil
                 cmd:_cmd];
  }
  
  /* start processing */

  if ([_path length] == 0)
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

        genRec = [self->cache genericRecordForFileName:tmpFilePath 
		      manager:self];
        gidStr = [[(EOKeyGlobalID *)[genRec globalID] keyValues][0] 
								stringValue];
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
          fprintf(stderr, "%s: doc::set failed genrec %s, %s\n",
		  __PRETTY_FUNCTION__,
                  [[genRec description] cString], [gidStr cString]);
                  
        }
        NS_ENDHANDLER;
        if (ec != 0) {
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
  if ((gid = [self globalIDForPath:_path]) == nil) {
    NSLog(@"%s: did not found gid for path %@", __PRETTY_FUNCTION__, _path);
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

  if ([_path length] > 0) {
    if (![self createFileAtPath:_path contents:_contents attributes:nil])
      /* couldn't create file at the specified path */
      return nil;
  
    if ((doc = [self documentAtPath:_path]) == nil) {
      /* couldn't find created file at the specified path */
      NSLog(@"WARNING[%s]: internal error, "
	    @"cannot find file created at path '%@'",
            __PRETTY_FUNCTION__, _path);
      return nil;
    }

    /* apply attributes */
    if ([_attrs count] > 0) {
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
    doc = [doc autorelease];
    
    [doc setBlob:_contents];
    
    if ([_attrs count] > 0)
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

  if ((gid = [_doc globalID]) == nil) {
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
  exc = [[[self context] propertyManager]
	  removeAllPropertiesForGlobalID:gid checkAccess:NO];
  if (exc != nil) {
    NSLog(@"WARNING[%s]: remove of properties for %@ failed, got %@",
          __PRETTY_FUNCTION__, _doc, exc);
  }
  [_doc invalidate];
  return YES;
}

static BOOL isRootAccountId(NSNumber *aid) {
  return [aid intValue] == 10000 ? YES : NO;
}

- (BOOL)_fmdIsStatusValidForDocument:(id)_doc {
  NSString *status;
  NSNumber *aid;
  id a;
  
  status = [[_doc fileAttributes] objectForKey:@"SkyStatus"];
  
  if (![status isEqualToString:@"edited"])
    return YES;

  a   = [[self->cache context] valueForKey:LSAccountKey];
  aid = [a valueForKey:@"companyId"];

  if ([[[_doc fileAttributes] objectForKey:@"SkyOwnerId"] isEqual:aid])
    return YES;
  if (isRootAccountId(aid))
    return YES;
  
  return NO;
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

  if (![self _fmdIsStatusValidForDocument:_doc])
    return NO;
  
  if ((pm = [[self context] propertyManager]) == nil) {
    return [self _buildErrorWithSource:nil dest:nil msg:43 handler:nil
                 cmd:_cmd];
  }
  if ((gid = [_doc globalID]) == nil) {
    return [self _buildErrorWithSource:nil dest:nil msg:44 handler:nil
                 cmd:_cmd];
  }
  if ([_doc _blobChanged]) {
    if (![self writeContents:[_doc blob] 
	       atPath:[_doc valueForKey:@"NSFilePath"]
               handler:nil flush:NO])
      return NO;
    [_doc _setBlobChanged:NO];
  }
  if ([_doc _subjectChanged]) {
    NSDictionary *sattrs;
    NSString *docSub;
    
    if ((docSub = [_doc subject]) == nil)
      docSub = @"";

    sattrs = [NSDictionary dictionaryWithObject:docSub 
			   forKey:@"NSFileSubject"];
    if (![self changeFileAttributes:sattrs
               atPath:[_doc valueForKey:NSFilePath] flush:NO])
      return NO;
    [_doc _setSubjectChanged:NO];
  }
  if ([(attrs = [_doc _newAttrs]) count]) {
    tmpAttrs = [self _mapAttrsNamespaces:attrs forDoc:_doc];
    [attrs removeAllObjects];
  }
  if ([(attrs = [_doc _newExtAttrs]) count] > 0) {
    if (tmpAttrs != nil)
      [tmpAttrs addEntriesFromDictionary:attrs];
    else
      tmpAttrs = [[attrs mutableCopy] autorelease];
    [attrs removeAllObjects];
  }
  if (tmpAttrs) {
    /* remove EONull values */
    NSEnumerator *enumerator;
    id           obj;
      
    enumerator = [[tmpAttrs allKeys] objectEnumerator];
      
    while ((obj = [enumerator nextObject]) != nil) {
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
  if ([(attrs = [_doc _updateAttrs]) count] > 0) {
    tmpAttrs = [self _mapAttrsNamespaces:attrs forDoc:_doc];
    [attrs removeAllObjects];
  }
  if ([(attrs = [_doc _updateExtAttrs]) count] > 0) {
    if (tmpAttrs)
      [tmpAttrs addEntriesFromDictionary:attrs];
    else
      tmpAttrs = [[attrs copy] autorelease];
    [attrs removeAllObjects];
  }
  if (tmpAttrs) { /* keys with EONull as value will be removed */
    NSEnumerator *enumerator;
    id           obj, *delKeys;
    NSArray      *keys;
    int          cnt;

    keys       = [tmpAttrs allKeys];
    delKeys    = calloc([keys count] + 2, sizeof(id));
    enumerator = [keys objectEnumerator];
    cnt        = 0;
    while ((obj = [enumerator nextObject])) {
      if (![[tmpAttrs objectForKey:obj] isNotNull]) {
        delKeys[cnt] = [[obj retain] autorelease];
        cnt++;
        [tmpAttrs removeObjectForKey:obj];
      }
    }
    if (cnt > 0) {
      keys = [[NSArray alloc] initWithObjects:delKeys count:cnt];
      if ((exc = [pm removeProperties:keys globalID:gid]) != nil) {
        [self setLastException:exc];
        return [self _buildErrorWithSource:nil dest:nil msg:46 handler:nil
                     cmd:_cmd];
      }
      [keys release]; keys = nil;
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

@end /* SkyProjectFileManager(Documents) */


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
  
  if ([_objs count] == 0)
    return [NSArray array];
  
  /* wrap the objects into documents ... */
  
  if (GidClass == Nil) GidClass = [EOGlobalID class];
  if (DocClass == Nil) DocClass = [SkyProjectDocument class];
  
  skyDocs    = calloc([_objs count] + 2, sizeof(id));
  gids       = calloc([_objs count] + 2, sizeof(id));
  enumerator = [_objs objectEnumerator];
  gidCnt     = 0;
  skyDocCnt  = 0;
  
  /* split objects argument into global-ids and documents */
  
  while ((obj = [enumerator nextObject]) != nil) {
    BOOL isDict;

    isDict = YES;
    if ([obj isKindOfClass:GidClass]) {
      isDict       = NO;
      gids[gidCnt] = obj;
      gidCnt++;
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
        skyDocCnt++;
      }
    }
  }

  /* process global-ids */
  
  if (gidCnt > 0) {
    id      o;
    NSArray *gidArr;
    
    if (debugDocMapping) {
      [self logWithFormat:@"%s:  process %i gids ...", 
	      __PRETTY_FUNCTION__, gidCnt];
    }
    
    gidArr = [[NSArray alloc] initWithObjects:gids count:gidCnt];
    
    {
      NSAutoreleasePool *pool;
      
      pool = [[NSAutoreleasePool alloc] init];
      if (debugDocMapping) {
	[self logWithFormat:@"%s:    get attrsfor gids ...", 
	      __PRETTY_FUNCTION__];
      }
      
      enumerator = [[self _fileAttributesForDocGIDs:gidArr] objectEnumerator];
      if (debugDocMapping)
	[self logWithFormat:@"%s:    done.", __PRETTY_FUNCTION__];
      
      enumerator = [enumerator retain];
      [pool release];
      enumerator = [enumerator autorelease];
    }
    
    while ((o = [enumerator nextObject]) != nil) {
      skyDocs[skyDocCnt] =
        [[DocClass alloc]
                   initWithGlobalID:[o valueForKey:@"globalID"]
                   fileManager:self];
      [skyDocs[skyDocCnt] _setFileAttributes:o];
      skyDocCnt++;
    }
    
    [gidArr release]; gidArr = nil;
  }
  _objs = [[NSArray alloc] initWithObjects:skyDocs count:skyDocCnt];
  {
    int i;
    for (i = 0; i < skyDocCnt; i++)
      [skyDocs[i] release];
  }
  [_objs autorelease];
  if (gids)    free(gids);    gids    = NULL;
  if (skyDocs) free(skyDocs); skyDocs = NULL;
  
  /* fetch the attributes */
  
  if (debugDocMapping) {
    [self logWithFormat:@"%s:  fetching attrs %@ for %i docs ...",
	  __PRETTY_FUNCTION__, [_attrs componentsJoinedByString:@","],
	  [_objs count]];
  }
  
  [self fetchAttributes:_attrs forDocs:_objs];

  if (debugDocMapping) {
    [self logWithFormat:@"%s: returned %i docs.", 
	  __PRETTY_FUNCTION__, [_objs count]];
  }
  
  return _objs;
}

- (void)fetchAttributes:(NSArray *)_attrs forDocs:(NSArray *)_objs {
  NSArray                  *docKeys, *gids;
  NSString                 *ns, *attrName;
  NSMutableSet             *nameSpaces;
  SkyObjectPropertyManager *pm;
  NSEnumerator             *enumerator;
  
  if (!([_attrs isNotNull] && [_attrs count] > 0))
    return;

  /* extract namespaces */
  
  nameSpaces = [[NSMutableSet alloc] init];
  docKeys    = [self readOnlyDocumentKeys];
  enumerator = [_attrs objectEnumerator];
  while ((attrName = [enumerator nextObject]) != nil) {
    if ([docKeys containsObject:attrName])
      continue;
    
    ns = [attrName hasXMLNamespace]
      ? [attrName xmlNamespace]
      : [self defaultProjectDocumentNamespace];
    
    [nameSpaces addObject:ns];
  }
  if (debugAttrFetch) {
    [self logWithFormat:@"fetch namespaces: %@",
	  [[nameSpaces allObjects] componentsJoinedByString:@","]];
  }

  /* fetch */
  
  gids       = [_objs map:@selector(globalID)];
  enumerator = [nameSpaces objectEnumerator];
  pm         = [[self context] propertyManager];
  
  while ((ns = [enumerator nextObject]) != nil) {
    NSDictionary *nsRes;
    NSEnumerator *objEnum;
    id           o;

    /* fetch all properties of the given namespace */
    nsRes = [pm propertiesForGlobalIDs:gids namespace:ns];
    
    if (debugAttrFetch)
      [self logWithFormat:@"  fetched namespace '%@': %@", ns, nsRes];
    
    /* iterate the documents and fill the values */
    objEnum = [_objs objectEnumerator];
    while ((o = [objEnum nextObject]) != nil) {
      [o _takeAttributesFromDictionary:[nsRes objectForKey:[o globalID]]
	 namespace:ns isComplete:YES]; /* all default ns */
    }
  }
  [nameSpaces release]; nameSpaces = nil;
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
  keys       = calloc(dCnt + 2, sizeof(id));
  values     = calloc(dCnt + 2, sizeof(id));
  enumerator = [[_dict allKeys] objectEnumerator];
  cnt        = 0;
  ns         = [self _defaultCompleteProjectDocumentNamespace];
  
  while ((key = [enumerator nextObject]) != nil) {
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
  if (keys)   free(keys);   keys   = NULL;
  if (values) free(values); values = NULL;
  return [result autorelease];
}

- (NSArray *)_fileAttributesForDocGIDs:(NSArray *)_dGIDs {
  NSEnumerator *enumerator;
  NSArray      *paths;
  NSArray      *result;
  id           *objs, obj;
  int          cnt;

  if (![_dGIDs count])
    return [NSArray array];
  
  objs       = calloc([_dGIDs count] + 2, sizeof(id));
  cnt        = 0;
  paths      = [self->cache  pathsForGIDs:_dGIDs manager:self];
  enumerator = [paths objectEnumerator];
  
  while ((obj = [enumerator nextObject])) {
    objs[cnt] = [self->cache fileAttributesAtPath:obj manager:self];
    cnt++;
  }
  result = [NSArray arrayWithObjects:objs count:cnt];
  if (objs) free(objs); objs = NULL;
  return result;
}

@end /* Document_Internals */

