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
 
#include "SkyProjectFileManager.h"
#include "common.h"

@interface SkyProjectFileManager(Extensions_Internals)
- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier;
+ (void)setProjectID:(NSNumber *)_pid forDocID:(NSNumber *)_did
  context:(id)_cxt;
+ (NSNumber *)pidForDocId:(NSNumber *)_did context:(id)_ctx;
+ (NSDictionary *)projectIdsForDocsInContext:(id)_ctx;
+ (void)setProjectIdsForDocs:(NSDictionary *)_dict inContext:(id)_ctx;
@end /* SkyProjectFileManager(Extensions_Internals) */

@implementation SkyProjectFileManager(FileAttributes)

static NSNumber *yesNum = nil, *noNum = nil;

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

+ (void)runGetAttachmentNameCommand:(id)_doc
  projectId:(NSNumber *)_projectId
  context:(id<SkyProjectFileManagerContext>)_ctx
{
  NSDictionary *dict;
  NSString     *key;
  id           getAttachmentNameCommand;
  NSNumber     *projectId;

  
  projectId = _projectId;
    
  if (projectId == nil) {
    NSLog(@"%s: missing projectId for %@", __PRETTY_FUNCTION__, _doc);
    return;
  }
  getAttachmentNameCommand = [_ctx getAttachmentNameCommand];

  key  = @"object";
  dict = [[NSDictionary alloc] initWithObjects:&_doc forKeys:&key count:1];
  if (getAttachmentNameCommand == nil) {
    getAttachmentNameCommand = [[_ctx  commandContext] 
                                      lookupCommand:@"get-attachment-name"
                                      inDomain:@"doc"];
    [_ctx setGetAttachmentNameCommand:getAttachmentNameCommand];
  }
  [getAttachmentNameCommand takeValuesFromDictionary:dict];
  [getAttachmentNameCommand takeValue:projectId
                            forKey:@"projectId"];

  [getAttachmentNameCommand runInContext:[_ctx commandContext]];

  [dict release]; dict = nil;
}

+ (NSException *)handleNameGetException:(NSException *)_exception
  selector:(SEL)_sel
{
  // TODO: not the best method name ... (why are those class methods anyway?)
  NSLog(@"ERROR[%@] catched exception during get-blob-name: %@", 
	NSStringFromSelector(_sel), _exception);
  return nil;
}

+ (NSString *)blobNameForDocument:(id)_doc globalID:(EOGlobalID *)_gid
  realDoc:(id)_realDoc manager:(id)_manager
  projectId:(id)_projectId
  context:(id<SkyProjectFileManagerContext>)_ctx
{
  NSString *blobName = nil;
  BOOL     isOk;

  if (![_doc isKindOfClass:[EOGenericRecord class]] &&
      ![_doc isKindOfClass:[NSMutableDictionary class]]) {
    _doc = [[_doc mutableCopy] autorelease];
  }
  NS_DURING {
    isOk = YES;
    [_doc setObject:_gid forKey:@"globalID"];

    if (_realDoc)
      if (_realDoc != _doc) 
	/* _doc is document-editing */
        [_doc setObject:_realDoc forKey:@"toDocument"];

    [SkyProjectFileManager runGetAttachmentNameCommand:_doc
                           projectId:_projectId
                           context:_ctx];
    
    blobName = [_doc valueForKey:@"attachmentName"];
  }
  NS_HANDLER {
    isOk = NO;
    [[self handleNameGetException:localException selector:_cmd] raise];
  }
  NS_ENDHANDLER;
  if (!isOk) {
    return nil;
  }
  if (![blobName isNotNull]) {
    /* couldn't get blob */
    NSLog(@"WARNING[%s]: did not find blob-name of document %@ '%@'",
          __PRETTY_FUNCTION__,
          [_doc valueForKey:@"documentId"],
          [_doc valueForKey:@"title"]);
    return nil;
  }
  return blobName;
}

+ (NSString *)formatTitle:(NSString *)_title {
  if (![_title isNotNull])
    return @"";

  if ([_title rangeOfString:@"/"].length == 0)
    return _title;
#if LIB_FOUNDATION_LIBRARY
  return [_title stringByReplacingString:@"/" withString:@"_"];
#else
#  warning FIXME: incorrect implementation for this Foundation library
  return _title;
#endif
}

+ (NSDictionary *)buildFileAttrsForDoc:(NSDictionary *)_doc
  editing:(NSDictionary *)_editing
  atPath:(NSString *)_path
  isVersion:(BOOL)_isVersion
  projectId:(NSNumber *)_projectId
  fileAttrContext:(id<SkyProjectFileManagerContext>)_context
{
  return [SkyProjectFileManager buildFileAttrsForDoc:_doc
                                editing:_editing
                                atPath:_path
                                isVersion:_isVersion
                                projectId:_projectId
                                projectName:nil
                                projectNumber:nil
                                fileAttrContext:_context];
                                
}

static BOOL isRootAccountID(NSNumber *cid) {
  return [cid intValue] == 10000 ? YES : NO;
}

+ (NSString *)faMimeTypeForExtension:(NSString *)_ext
  fileAttrContext:(id<SkyProjectFileManagerContext>)_context
{
  // TODO: this is not per user?! should use standard defaults, right?
  static NSDictionary *types = nil;
  NSString *mimeType;

  if ([types count] == 0) {
    NSUserDefaults *ud;
    
    ud    = [NSUserDefaults standardUserDefaults];
    types = [[ud dictionaryForKey:@"LSMimeTypes"] copy];
  }
  
  _ext     = [_ext lowercaseString];
  mimeType = [types objectForKey:_ext];
  
  if (mimeType == nil) {
    static NSMutableSet *warnedExt = nil;
    
    mimeType = @"application/octet-stream";
    
    if (warnedExt == nil)
      warnedExt = [[NSMutableSet alloc] initWithCapacity:16];
    
    if (![warnedExt containsObject:_ext]) {
      [self logWithFormat:
	      @"WARNING: did not find MIME type for extension %@: %@",
	      _ext, types];
      [warnedExt addObject:_ext];
    }
  }
  return mimeType;
}

+ (NSDictionary *)buildFileAttrsForDoc:(NSDictionary *)_doc
  editing:(NSDictionary *)_editing
  atPath:(NSString *)_path
  isVersion:(BOOL)_isVersion
  projectId:(NSNumber *)_projectId
  projectName:(NSString *)_pName
  projectNumber:(NSString *)_pNumber
  fileAttrContext:(id<SkyProjectFileManagerContext>)_context
{
  // TODO: split up this huge method
  id                  realDoc, doc, tmp;
  BOOL                isLink;
  NSMutableDictionary *attrs;
  NSDictionary        *result;
  NSAutoreleasePool   *pool;

  if (![_doc isNotNull]) {
    NSLog(@"ERROR[%s] missing doc ...");
    return nil;
  }
  pool = [[NSAutoreleasePool alloc] init];
  
  isLink = NO;
  
  if ((tmp = [_doc valueForKey:@"isObjectLink"]))
    isLink = [tmp boolValue];

  attrs = [[NSMutableDictionary alloc] initWithCapacity:12];

  /* determine primary document */

  if (_editing != nil) {
    NSNumber *acc;

    [attrs takeValue:[_editing valueForKey:@"documentEditingId"]
           forKey:@"__documentEditingId__"];
           
    acc = [[[_context commandContext] valueForKey:LSAccountKey]
                  valueForKey:@"companyId"];
    if ([acc isEqual:[_editing valueForKey:@"currentOwnerId"]] ||
	isRootAccountID(acc)) {
      doc = _editing;
    }
    else
      doc = _doc;
  }
  else
    doc = _doc;
  
  realDoc = _doc;
  
  // TODO: document what this does? Can we use an NSFormatter?
  tmp = [SkyProjectFileManager formatTitle:[doc valueForKey:@"title"]];
  [attrs setObject:tmp forKey:@"filename"];
  
  if ((tmp = [doc valueForKey:@"abstract"])) {
    /* abstract is title ... */
    [attrs setObject:tmp forKey:@"title"];
    [attrs setObject:tmp forKey:@"NSFileSubject"];
  }
  
  if ((tmp = [doc valueForKey:@"fileType"]))
    [attrs setObject:tmp forKey:@"fileType"];
  
  if ((tmp = [doc valueForKey:@"fileSize"]))
    [attrs setObject:tmp forKey:@"fileSize"];
  
  if (!_isVersion) {
    if (_editing == nil) {
      [attrs setObject:@"released" forKey:@"status"];
    }
    else if ((tmp = [doc valueForKey:@"status"]))
      [attrs setObject:tmp forKey:@"status"];
    else
      [attrs setObject:@"released" forKey:@"status"];
  }
  
  {
    // TODO: move to own method
    EOKeyGlobalID *gid;
    NSNumber      *uid;
    NSString      *entityName;
    
    if (_isVersion) {
      entityName = @"DocumentVersion";
      uid        = [doc valueForKey:@"documentVersionId"];
    }
    else {
      entityName = @"Doc";
      uid        = [doc valueForKey:@"documentId"];
    }
    {
      NSNumber *pid;

      if (![(pid = [realDoc valueForKey:@"projectId"]) isNotNull])
        pid = _projectId;
      
      [SkyProjectFileManager setProjectID:pid
                             forDocID:uid context:[_context commandContext]];
    }
    
    gid = [EOKeyGlobalID globalIDWithEntityName:entityName
                         keys:&uid keyCount:1 zone:NULL];
    
    [attrs setObject:gid forKey:@"globalID"];
  }
  if (!_isVersion) {
    if ((tmp = [realDoc valueForKey:@"versionCount"]))
      [attrs setObject:tmp forKey:@"versionCount"];
    
    if ((tmp = [realDoc valueForKey:@"lastmodifiedDate"]))
      [attrs setObject:tmp forKey:@"lastmodifiedDate"];
  }
  if ((tmp = [realDoc valueForKey:@"creationDate"]))
    [attrs setObject:tmp forKey:@"creationDate"];

  {
    NSString *fn, *fp, *ex;

    fn = [SkyProjectFileManager formatTitle:[doc valueForKey:@"title"]];
    
    if ([(ex = [doc valueForKey:@"fileType"]) isNotNull]) {
      if ([ex length] > 0)
        if (![ex hasPrefix:@" "])
          fn = [fn stringByAppendingPathExtension:ex];
    }

    if ([fn length] > 0) {
      [attrs setObject:fn forKey:@"SkyFileName"];
      [attrs setObject:fn forKey:NSFileName];
    }
    
    if ([_path length] > 0) {
      fp = (_path != nil)
        ? [_path stringByAppendingPathComponent:fn]
        : fn;

      if (fp) {
        if (_isVersion) {
          if ((tmp = [[doc valueForKey:@"version"] stringValue]))
            fp = [fp stringByAppendingPathVersion:tmp];
        }
        [attrs setObject:fp forKey:@"SkyFilePath"];
        [attrs setObject:fp forKey:NSFilePath];
      }
    }
    else if (_projectId != nil) { /* got root */
      if (![fn length]) {
        [attrs setObject:@"/" forKey:@"SkyFileName"];
        [attrs setObject:@"/" forKey:NSFileName];
        [attrs setObject:@"/" forKey:@"fileName"];
      }
      [attrs setObject:@"/"   forKey:@"SkyFilePath"];
      [attrs setObject:@"/"   forKey:NSFilePath];
      
      if (![[attrs objectForKey:@"fileType"] length])
        [attrs setObject:[EONull null]  forKey:@"fileType"];
      
      if (![attrs objectForKey:@"fileSize"])
        [attrs setObject:[NSNumber numberWithInt:0] forKey:@"fileSize"];
      if (![attrs objectForKey:@"NSFileSize"])
        [attrs setObject:[NSNumber numberWithInt:0] forKey:@"NSFileSize"];
    }
    {
      NSNumber *pid;
      
      if (![(pid = [realDoc valueForKey:@"projectId"]) isNotNull])
        pid = _projectId;
      [attrs setObject:pid forKey:@"projectId"];
    }
  }
  if (!_isVersion) {
    NSNumber *pid;
    
    if ((pid = [realDoc valueForKey:@"parentDocumentId"]) == nil) {
      [attrs setObject:boolNum(YES) forKey:@"SkyIsRootDirectory"];
    }
    else {
      EOGlobalID *pgid;

      pgid = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                            keys:&pid keyCount:1 zone:NULL];
      
      [attrs setObject:boolNum(NO) forKey:@"SkyIsRootDirectory"];
      [attrs setObject:pid  forKey:@"SkyParentId"]; 
      [attrs setObject:pgid forKey:@"SkyParentGID"];
    }
  }
  if (!_isVersion && [[realDoc valueForKey:@"isFolder"] boolValue]) {
    [attrs setObject:NSFileTypeDirectory forKey:NSFileType];
    [attrs setObject:@"x-skyrix/filemanager-directory"
           forKey:@"NSFileMimeType"];
  }
  else if (!_isVersion && isLink) {
    [attrs setObject:NSFileTypeSymbolicLink forKey:NSFileType];
    [attrs setObject:@"x-skyrix/filemanager-link"
           forKey:@"NSFileMimeType"];
    if (([tmp = [realDoc valueForKey:@"objectLink"] isNotNull]))
      [attrs setObject:tmp forKey:@"SkyLinkTarget"];
  }
  else if (_path != nil || _projectId == nil) {
    NSString   *blobName = nil;
    {
      static Class EOGenericRecordClass      = nil;
      static Class NSMutableDictionaryClass  = nil;

      NSString   *docBlob, *edBlob;
      NSNumber   *number;
      BOOL       removeCache;

      if (EOGenericRecordClass == nil) {
        EOGenericRecordClass     = [EOGenericRecord class];
        NSMutableDictionaryClass = [NSMutableDictionary class];
      }

      number  = [_editing valueForKey:@"documentEditingId"];

      if ([doc isKindOfClass:EOGenericRecordClass] ||
          [doc isKindOfClass:NSMutableDictionaryClass]) {
        removeCache = YES;
        [doc removeObjectForKey:@"attachmentName"];
      }
      else
        removeCache = NO;
      
      docBlob = [SkyProjectFileManager blobNameForDocument:doc
                                       globalID:
					 [attrs objectForKey:@"globalID"]
                                       realDoc:realDoc manager:nil
                                       projectId:
					 [attrs objectForKey:@"projectId"]
                                       context:_context];
      if (docBlob)
	[attrs setObject:docBlob forKey:@"__docBlobPath__"];
      else {
	[self logWithFormat:
		@"ERROR(%s): could not retrieve BLOB name for document: %@\n"
  	        @"  attributes: %@",
	        __PRETTY_FUNCTION__, doc, attrs];
      }
      
      edBlob = nil;
      if (number != nil) {
	EOKeyGlobalID *gid;
	
        if (removeCache)
          [doc removeObjectForKey:@"attachmentName"];
        
	gid = [EOKeyGlobalID globalIDWithEntityName:@"DocumentEditing"
			     keys:&number keyCount:1 zone:NULL];
        edBlob  =
          [SkyProjectFileManager blobNameForDocument:doc
                                 globalID:gid
                                 realDoc:realDoc manager:nil
                                 projectId:
				   [attrs objectForKey:@"projectId"]
                                 context:_context];
        
        [attrs setObject:edBlob  forKey:@"__editBlobPath__"];

        if (removeCache)
          [doc removeObjectForKey:@"attachmentName"];
      }

      if (doc == _editing) {
        if (edBlob) {
          blobName = edBlob;
        }
      }
      else
        blobName = docBlob;
    }

    if (blobName) {
      NSFileManager *fm;
      id            len;

      fm  = [NSFileManager defaultManager];
      len = [[fm fileAttributesAtPath:blobName traverseLink:YES]
                 objectForKey:NSFileSize];
      if (len > 0) {
	// TODO: the mime type should not be dependend on filesize?
        NSString *mimeType;
        
        [attrs setObject:NSFileTypeRegular forKey:NSFileType];
        [attrs setObject:len forKey:NSFileSize];
	
	mimeType = [self faMimeTypeForExtension:
			   [[attrs objectForKey:NSFileName] pathExtension]
			 fileAttrContext:_context];
        [attrs setObject:mimeType forKey:@"NSFileMimeType"];
      }
      else
        [attrs setObject:NSFileTypeUnknown forKey:NSFileType];
      
      [attrs setObject:blobName forKey:@"SkyBlobPath"];
    }
    else {
      [attrs setObject:NSFileTypeUnknown forKey:NSFileType];
    }
  }
  if ([[attrs objectForKey:NSFilePath] isEqualToString:@"/"])
    [attrs setObject:NSFileTypeDirectory forKey:NSFileType];
  
  /* apply document attrs */
  {
    id tmp;
    
    if ((tmp = [realDoc valueForKey:@"firstOwnerId"])) {
      EOGlobalID *gid;

      gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                           keys:&tmp keyCount:1 zone:NULL];
      if (gid)
        [attrs setObject:gid forKey:@"SkyFirstOwnerId"];
    }

    if (_isVersion) {
      tmp = [doc valueForKey:@"lastOwnerId"];
    }
    else {
      tmp =  (_editing) ? [_editing valueForKey:@"currentOwnerId"]
                        : [doc valueForKey:@"currentOwnerId"];
    }
    if (tmp != nil) {
      NSString *accountLogin;

#if !LIB_FOUNDATION_LIBRARY
      [attrs setObject:tmp forKey:NSFileOwnerAccountID];
#else
      [attrs setObject:tmp forKey:NSFileOwnerAccountNumber];
#endif
      [attrs setObject:tmp forKey:@"SkyOwnerId"];

      accountLogin = [_context accountLogin4PersonId:tmp];
      
      if ([accountLogin length] > 0)
        [attrs setObject:accountLogin forKey:NSFileOwnerAccountName];
    }
    if (_isVersion) {
      if ((tmp = [[doc valueForKey:@"version"] stringValue])) {
        [attrs setObject:tmp forKey:@"SkyVersionName"];
        tmp = [NSNumber numberWithInt:[tmp intValue]];
        [attrs setObject:tmp forKey:@"SkyVersionNumber"];
      }
      
      [attrs setObject:boolNum(YES) forKey:@"SkyIsVersion"];
    }
    else {
      [attrs setObject:boolNum(NO) forKey:@"SkyIsVersion"];
    }
    if ((tmp = [doc valueForKey:@"abstract"]))
      [attrs setObject:tmp forKey:@"SkyTitle"];
    if ((tmp = [realDoc valueForKey:@"creationDate"]))
      [attrs setObject:tmp forKey:@"SkyCreationDate"];

    if (!_isVersion) {
      if ((tmp = [doc valueForKey:@"status"]))
        [attrs setObject:tmp forKey:@"SkyStatus"];
      else
        [attrs setObject:@"released" forKey:@"SkyStatus"];
        
      if ((tmp = [realDoc valueForKey:@"versionCount"]))
        [attrs setObject:tmp forKey:@"SkyVersionCount"];
    }
    tmp = (!_isVersion)
      ? [realDoc valueForKey:@"lastmodifiedDate"]
      : [doc valueForKey:@"archiveDate"];
    
    if (tmp) {
      [attrs setObject:tmp forKey:@"SkyLastModifiedDate"];
      [attrs setObject:tmp forKey:NSFileModificationDate];
    }
  }
  if (_pNumber != nil)
    [attrs setObject:_pNumber forKey:@"projectNumber"];

  if (_pName != nil)
    [attrs setObject:_pName forKey:@"projectName"];
  
  if ((tmp = _projectId) != nil)
    [attrs setObject:tmp forKey:@"projectId"];
  
  /* finish up, copy attributes, release pool */
  
  result = [attrs copy];
  
  [attrs release]; attrs = nil;
  [pool  release]; pool  = nil;
  
  return [result autorelease];
}

@end /*SkyProjectFileManager(FileAttributes) */
