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

#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoProject/NSString+XMLNamespaces.h>
#include <OGoDocuments/SkyDocumentType.h>
#include <NGExtensions/NGFileFolderInfoDataSource.h>
#include "SkyProjectFolderDataSource.h"
#include "SkyDocumentHistoryDataSource.h"
#include "common.h"


@interface SkyProjectFolderDataSource(Internals)
- (NSString *)path;
@end /* SkyProjectFolderDataSource(Internals) */

@interface SkyProjectDocumentType : SkyDocumentType
@end /* SkyDocumentType */

@implementation SkyProjectDocumentType
@end /* SkyProjectDocumentType */

@interface SkyProjectFileManager(Private)
- (NSString *)_defaultCompleteProjectDocumentNamespace;
@end

@interface SkyProjectDocument(Internals)
- (void)refetchFileAttrs;
- (void)refetchProperties;
- (void)_setFileAttributes:(NSDictionary *)_fAttrs;
- (void)_setExtendedAttributes:(NSDictionary *)_attrs;
  
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
@end /* SkyProjectDocument(Internals) */

@implementation SkyProjectDocument

static int DebugOn = -1;
static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  DebugOn = [ud boolForKey:@"SkyProjectDocumentDebug"] ? 1 : 0;

  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid
  fileManager:(SkyProjectFileManager *)_fm
{
#if DEBUG
  NSAssert1(_fm, @"missing filemanager argument for document %@ ..", _gid);
#endif
  
  if ((self = [super init])) {
    self->globalID    = RETAIN(_gid);
    self->fileManager = RETAIN(_fm);
    
    self->status.isValid        = YES;
    self->status.blobChanged    = NO;
    self->status.subjectChanged = NO;
    self->status.isEdited       = NO;
    self->status.isComplete     = YES;
    [self _registerForGID];
  }
  return self;
}
- (id)init {
  return [self initWithGlobalID:nil fileManager:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->blobAsDOM       release];
  [self->globalID        release];
  [self->fileManager     release];
  [self->blob            release];
  [self->fileAttributes  release];
  [self->attributes      release];
  [self->extendedAttributes release];
  [self->updateAttrs     release];
  [self->updateExtAttrs  release];
  [self->newAttrs        release];
  [self->newExtAttrs     release];
  [self->subject         release];
  [self->dataSource      release];
  [super dealloc];
}

/* SkyDocument subclass */

- (id)context {
  return [[self fileManager] context];
}

/* tracking modification */

- (BOOL)isValid {
#if DEBUG  
  if (!self->status.isValid) {
    NSLog(@"WARNING[%s]: call for invalid SkyProjectDocument",
          __PRETTY_FUNCTION__);
  }
#endif  
  return self->status.isValid;
}

- (void)invalidate {
  [self reload]; /* clear attrs */
  if (self->globalID) {
    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                           name:SkyGlobalIDWasDeleted
                           object:self->globalID];
    [self->globalID release]; self->globalID = nil;
  }
  self->status.isValid = NO;
}

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited) ? YES : NO;
}

- (BOOL)isComplete {
  if (![self isValid])
    return NO;

  return self->status.isComplete;
}

- (NSString *)path {
  return [[self fileAttributes] objectForKey:@"NSFilePath"];
}
- (NSString *)filename {
  return [[self fileAttributes] objectForKey:@"NSFileName"];
}
- (unsigned)size {
  return [[[self fileAttributes] objectForKey:@"NSFileSize"] unsignedIntValue];
}
- (BOOL)isVersioned {
  return [[self fileManager] supportsVersioningAtPath:[self path]];
}
- (BOOL)isReadable {
  return [[self fileManager] isReadableFileAtPath:[self path]];
}
- (BOOL)isWriteable {
  return [[self fileManager] isWritableFileAtPath:[self path]];
}
- (BOOL)isInsertable {
  if (![self isDirectory]) {
    return NO;
  }
  return [[self fileManager] isInsertableDirectoryAtPath:[self path]];
}  

- (BOOL)isDeletable {
  return [[self fileManager] isDeletableFileAtPath:[self path]];
}
- (BOOL)isLocked {
  if (![[self fileManager] supportsLockingAtPath:[self path]])
    return NO;
  
  return [[self fileManager] isFileLockedAtPath:[self path]];
}
- (BOOL)isDirectory {
  return [[[self fileAttributes]
                 objectForKey:NSFileType]
                 isEqualToString:NSFileTypeDirectory];
}

/* feature check */

- (BOOL)supportsFeature:(NSString *)_featureURI {
  if ([self isDirectory])
    return [super supportsFeature:_featureURI];
  
  if ([_featureURI isEqualToString:SkyDocumentFeature_BLOB])
    return YES;
  if ([_featureURI isEqualToString:SkyDocumentFeature_STRINGBLOB])
    return YES;
  if ([_featureURI isEqualToString:SkyDocumentFeature_DOMBLOB])
    return YES;
  
  return [super supportsFeature:_featureURI];
}

/* accessors */

- (NSDictionary *)fileAttributes {
  if (self->fileAttributes == nil)
    [self refetchFileAttrs];
  
  return self->fileAttributes;
}

- (NSString *)subject {
  if (self->subject == nil) {
    self->subject = 
      [[[self fileAttributes] objectForKey:@"NSFileSubject"] copy];
  }
  return self->subject;
}
- (void)setSubject:(NSString *)_subj {
  if (![self isValid])
    return;
  
  if (_subj == nil)
    _subj = (id)[NSNull null];
  
  if (_subj != [self subject]) {
    ASSIGN(self->subject, _subj);
    [(NSMutableDictionary *)[self fileAttributes] setObject:self->subject
                            forKey:@"NSFileSubject"];
    self->status.subjectChanged = YES;
  }
}

/* SkyDocumentFeature_BLOB */

- (void)setBlob:(NSData *)_blob {
  // deprecated
  [self setContent:_blob];
}
- (NSData *)blob {
  // deprecated
  return [self content];
}

- (void)setContent:(NSData *)_blob {
  NSData *b;

  if (![self isValid])
    return;
  
  b = [self content];
  
  if (_blob != b) {
    [self->blobAsDOM release]; self->blobAsDOM = nil;
    
    if ([_blob isKindOfClass:[NSString class]]) {
      _blob = [(NSString *)_blob dataUsingEncoding:
                           [NSString defaultCStringEncoding]];
    }
    ASSIGN(self->blob, _blob);
    self->status.blobChanged = YES;
  }
}
- (NSData *)content {
  NSString *dpath;
  
  if (![self isValid])
    return nil;

  if (!((self->globalID != nil) && (self->blob == nil)))
    return self->blob;
    
  [self->blobAsDOM release]; self->blobAsDOM = nil;

  if ((dpath = [self path]))
    return [self->fileManager contentsAtPath:dpath];
  
  return self->blob;
}

- (void)clearContent {
  if (self->status.blobChanged)
    return;
  
  [self->blobAsDOM release]; self->blobAsDOM = nil;
  [self->blob      release]; self->blob      = nil;
}

/* SkyDocumentFeature_STRINGBLOB */

- (NSStringEncoding)stringEncodingInBLOB {
  return NSISOLatin1StringEncoding;
}

- (void)setContentString:(NSString *)_string {
  if (_string == nil)
    [self setContent:nil];
  else
    [self setContent:[_string dataUsingEncoding:[self stringEncodingInBLOB]]];
}
- (NSString *)contentAsString {
  NSData   *data;
  NSString *s;
  
  if ((data = [self content]) == nil)
    return nil;
  
  s = [[NSString alloc] initWithData:data
                        encoding:[self stringEncodingInBLOB]];
  return [s autorelease];
}

- (void)setContentAsString:(NSString *)_string {
  // DEPRECATED
  NSLog(@"DEPRECATED: %s", __PRETTY_FUNCTION__);
  [self setContentString:_string];
}

- (void)setString:(NSString *)_string {
  // DEPRECATED
  NSLog(@"DEPRECATED: %s", __PRETTY_FUNCTION__);
  [self setContentString:_string];
}
- (NSString *)string {
  // DEPRECATED
  NSLog(@"DEPRECATED: %s", __PRETTY_FUNCTION__);
  return [self contentAsString];
}

/* extended attributes */

- (NSDictionary *)extendedAttributes {
  if (self->extendedAttributes == nil)
    [self refetchProperties];
  
  return self->extendedAttributes;
}

- (NSDictionary *)attributes {
  if (self->attributes == nil)
    [self refetchProperties];
  
  return self->attributes;
}

- (NSDictionary *)extendedAttributesForNamespace:(NSString *)_ns {
  NSMutableDictionary *dict;
  NSEnumerator        *enumerator;
  id                  k;
  NSString            *ns;

  if (![self isValid])
    return nil;

  if (!_ns)
    return nil;
  
  if ([_ns isEqualToString:
             [self->fileManager defaultProjectDocumentNamespace]])
    return [self attributes];
  
  ns         = [NSString stringWithFormat:@"{%@}", _ns];
  dict       = [NSMutableDictionary dictionaryWithCapacity:64];
  enumerator = [[[self extendedAttributes] allKeys] objectEnumerator];
  
  while ((k = [enumerator nextObject])) {
    if ([k rangeOfString:_ns].length == 0)
      continue;
    
    [dict setObject:[[self extendedAttributes] objectForKey:k] forKey:k];
  }
  return dict;
}

- (NSArray *)documentKeys {
  NSMutableArray *ma;

  ma = [[[[self fileAttributes] allKeys] mutableCopy] autorelease];
  [ma addObjectsFromArray:[[self attributes] allKeys]];
  [ma addObjectsFromArray:[[self extendedAttributes] allKeys]];
  return ma;
}

- (NSArray *)readOnlyDocumentKeys {
  return [self->fileManager readOnlyDocumentKeys];
}

- (SkyProjectFileManager *)fileManager {
  return self->fileManager;
}

- (EODataSource *)folderDataSource {
  SkyProjectFolderDataSource *ds;
  NSString   *p;
  EOGlobalID *pgid;
  
  if (![self isDirectory])
    return nil;
  
  p    = [self path];
  pgid = [[self->fileManager fileSystemAttributesAtPath:p]
                             objectForKey:@"NSFileSystemNumber"];
  
  ds = [SkyProjectFolderDataSource alloc];
  ds = [ds initWithContext:[self->fileManager context]
           folderGID:[self globalID]
           projectGID:pgid
           path:p
           fileManager:self->fileManager];
  return [ds autorelease];
}

- (EODataSource *)historyDataSource {
  SkyDocumentHistoryDataSource *ds;
  EOGlobalID                   *pgid;
  NSString                     *p;

  if (![[[self fileAttributes]
               objectForKey:@"NSFileType"]
               isEqualToString:NSFileTypeRegular])
    return nil;
  
  p    = [self path];
  pgid = [[self->fileManager fileSystemAttributesAtPath:p]
                             objectForKey:@"NSFileSystemNumber"];
  
  ds = [SkyDocumentHistoryDataSource alloc];
  ds = [ds initWithContext:[self->fileManager context]
           documentGlobalID:[self globalID]
           projectGlobalID:pgid];
  return [ds autorelease];
}

/* identification */


- (BOOL)isEqual:(id)_obj {
  if (_obj == self)
    return YES;

  if ([_obj isKindOfClass:[SkyProjectDocument class]])
    return [self isEqualToDocument:_obj];
  
  return NO;
}

- (BOOL)isEqualToDocument:(SkyProjectDocument *)_doc {
  if (_doc == self)
    return YES;
  
  return [[self globalID] isEqual:[_doc globalID]];
}

- (EOGlobalID *)globalID {
  return self->globalID;
}

/* typing */

- (SkyDocumentType *)documentType {
  static SkyProjectDocumentType *docType = nil;
  
  if (!docType)
    docType = [[SkyProjectDocumentType alloc] init];

  return docType;
}

/* actions */

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
}

- (BOOL)save {
  BOOL     result;
  NSString *path;
  
  if (self->fileManager == nil) {
    NSLog(@"ERROR(%s): document has no filemanager: %@ !",
          __PRETTY_FUNCTION__, self);
    return NO;
  }
  if (self->dataSource) {
    NSString *dsPath;

    dsPath = [self->dataSource path];
    
    if (([(path = [self path]) length])) {
      ;
    }
    else if (([(path = [self filename]) length]) > 0)
      path = [dsPath stringByAppendingPathComponent:path];
    else
      path = dsPath;
  }
  else {
    path = [self path];
  }
  NS_DURING {
    *(&result) = [self->fileManager
                      writeDocument:self
                      toPath:path];
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  if (result)
    [self clearContent];
  
#if DEBUG
  if (!result) {
    NSLog(@"WARNING(%s): couldn't save document %@: %@ path: <%@>",
          __PRETTY_FUNCTION__, self, [self->fileManager lastException], path);
  }
#endif
  return result;
}

- (BOOL)delete {
  BOOL result;
  
  NS_DURING {
    result = [self->fileManager deleteDocument:self];
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;

  if (result)
    [self clearContent];
  
  return result;
}

- (BOOL)reload {
  if (![self isValid])
    return NO;

  [self clearContent];
  
  [self->blob           release];     self->blob               = nil;
  [self->blobAsDOM      release];     self->blobAsDOM          = nil;
  [self->fileAttributes release];     self->fileAttributes     = nil;
  [self->extendedAttributes release]; self->extendedAttributes = nil;
  [self->attributes     release];     self->attributes         = nil;
  [self->updateAttrs    release];     self->updateAttrs        = nil;
  [self->newAttrs       release];     self->newAttrs           = nil;
  [self->updateExtAttrs release];     self->updateExtAttrs     = nil;
  [self->newExtAttrs    release];     self->newExtAttrs        = nil;
  [self->subject        release];     self->subject            = nil;

  return YES;
}

- (BOOL)checkoutDocumentWithHandler:(id)_handler {
  return [[self fileManager] checkoutFileAtPath:[self path] handler:_handler];
}
- (BOOL)checkoutDocument {
  return [self checkoutDocumentWithHandler:nil];
}

- (BOOL)lockDocumentWithHandler:(id)_handler {
  return [[self fileManager] lockFileAtPath:[self path] handler:_handler];
}
- (BOOL)lockDocument {
  return [self lockDocumentWithHandler:nil];
}

- (BOOL)releaseDocumentWithHandler:(id)_handler {
  return [[self fileManager] releaseFileAtPath:[self path] handler:_handler];
}
- (BOOL)releaseDocument {
  return [self releaseDocumentWithHandler:nil];
}

- (BOOL)unlockDocumentWithHandler:(id)_handler {
  return [[self fileManager] unlockFileAtPath:[self path] handler:_handler];
}
- (BOOL)unlockDocument {
  return [self unlockDocumentWithHandler:nil];
}

/* KVC */

static Class DOMNodeClass = Nil;

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  /* TODO: split up this big method */
  NSString *ns, *defNS;

  if (![self isValid]) {
    [NSException raise:@"invalid document"
                 format:@"cannot takeValue:forKey:%@, document %@ is invalid",
                   _key, self];
    return;
  }
  
  if (![self isComplete]) {
    [NSException raise:@"document is not comlete, use reload"
                 format:
                   @"cannot takeValue:forKey:%@, document %@ is incomplete",
                   _key, self];
    return;
  }
  
  if ([_key isEqualToString:@"content"] ||
      [_key isEqualToString:@"contentAsString"] ||
      [_key isEqualToString:@"contentAsDOMDocument"]) {
    if (DOMNodeClass == Nil)
      DOMNodeClass = NSClassFromString(@"DOMNode");
    
    if ([_value isKindOfClass:[NSString class]])
      [self setContentAsString:_value];
    else if ([_value isKindOfClass:[NSData class]])
      [self setContent:_value];
    else if ([_value isKindOfClass:DOMNodeClass])
      [self setContentDOMDocument:_value];
    else
      [self setContentString:[_value stringValue]];
    return;
  }
  
  if ([_key isEqualToString:@"subject"] ||
      [_key isEqualToString:@"NSFileSubject"]) {
    [self setSubject:_value];
    return;
  }
  
  ns    = [_key xmlNamespace];
  defNS = [self->fileManager defaultProjectDocumentNamespace];
  
  if ((ns == nil) || [ns isEqualToString:defNS]) {
    NSString *k;
    id       roKeys;
    
    k      = (!ns) ? _key : [_key stringByRemovingXMLNamespace];
    roKeys = [self->fileManager readOnlyDocumentKeys];
    
    if ((ns == nil) && [roKeys containsObject:_key]) {
      if (self->globalID == nil) {
        [self fileAttributes];
        
        if (!self->fileAttributes) {
          self->fileAttributes = [[NSMutableDictionary alloc] init];
          [self->fileAttributes setObject:_value forKey:_key];
          self->status.isEdited = YES;
        }
        else {
          if (![[self->fileAttributes objectForKey:_key] isEqual:_value]) {
            [self->fileAttributes setObject:_value forKey:_key];
            self->status.isEdited = YES;
          }
        }
      }
      else {
        NSLog(@"ERROR[%s]: try to write read only attribute %@",
              __PRETTY_FUNCTION__, _key);
      }
    }
    else {
      if (![[[self attributes] objectForKey:k] isEqual:_value])
        self->status.isEdited = YES;

    
      if ([[[self attributes] allKeys] containsObject:k]) {
        if (!self->updateAttrs)
          self->updateAttrs = [[NSMutableDictionary alloc] initWithCapacity:8];
      
        [self->updateAttrs setObject:_value forKey:k];
      }
      else {
        if (!self->newAttrs)
          self->newAttrs = [[NSMutableDictionary alloc] initWithCapacity:8];
      
        [self->newAttrs setObject:_value forKey:k];
      }
      [[self attributes] takeValue:_value forKey:k];
    }
  }
  else {
    if (![[[self extendedAttributes] objectForKey:_key] isEqual:_value])
      self->status.isEdited = YES;

    if ([[[self extendedAttributes] allKeys] containsObject:_key]) {
      if (!self->updateExtAttrs)
        self->updateExtAttrs = [[NSMutableDictionary alloc] initWithCapacity:8];
      [self->updateExtAttrs setObject:_value forKey:_key];
    }
    else {
      if (!self->newExtAttrs)
        self->newExtAttrs = [[NSMutableDictionary alloc] initWithCapacity:8];
      [self->newExtAttrs setObject:_value forKey:_key];
    }
    [[self extendedAttributes] takeValue:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  id v = nil;
  
  if (![self isValid])
    return nil;

  if ([_key isEqualToString:@"globalID"])
    return [self globalID];

  /* first check for file attr */
  
  if ([_key hasPrefix:@"NS"]) {
    if ((v = [[self fileAttributes] valueForKey:_key]))
      return v;
  }

  /* content */
  
  if ([_key isEqualToString:@"content"])
    return [self content];
  else if ([_key isEqualToString:@"contentAsString"])
    return [self contentAsString];
  else if ([_key isEqualToString:@"contentAsDOMDocument"])
    return [self contentAsDOMDocument];
  
  /* JS compatibility */
  
  if ([_key hasPrefix:@"is"]) {
    if ([_key isEqualToString:@"isVersioned"])
      return [self isVersioned] ? yesNum : noNum;
    else if ([_key isEqualToString:@"isReadable"])
      return [self isReadable] ? yesNum : noNum;
    else if ([_key isEqualToString:@"isWriteable"])
      return [self isWriteable] ? yesNum : noNum;
    else if ([_key isEqualToString:@"isDeletable"])
      return [self isDeletable] ? yesNum : noNum;
    else if ([_key isEqualToString:@"isLocked"])
      return [self isLocked] ? yesNum : noNum;
    else if ([_key isEqualToString:@"isEdited"])
      return [self isEdited] ? yesNum : noNum;
  }
  else if ([_key isEqualToString:@"path"])
    return [self path];
  else if ([_key isEqualToString:@"name"])
    return [self filename];
  else if ([_key isEqualToString:@"subject"])
    return [self subject];
  
  /* check whether key has a namespace */
  
  if ([_key hasXMLNamespace]) {
    NSString *defNS;
    
    defNS = [self->fileManager defaultProjectDocumentNamespace];
    
    if ([[_key xmlNamespace] isEqualToString:defNS])
      return [self valueForKey:[_key stringByRemovingXMLNamespace]];

#if 0    
    /* check whether key is a new attribute */
  
    if ((v = [self->newExtAttrs valueForKey:_key]))
      return v;
  
    /* check whether key is an updated attribute */
  
    if ((v = [self->updateExtAttrs valueForKey:_key]))
      return v;
#endif
    /* check whether key is an existing attribute */

    v = [[self extendedAttributes] valueForKey:_key];
    
    return v;
  }
  
  /* check whether key is a file attribute */
  
  if ((v = [[self fileAttributes] valueForKey:_key]))
    return v;
#if 0  
  /* check whether key is a new attribute */
  
  if ((v = [self->newAttrs valueForKey:_key]))
    return v;
  
  /* check whether key is an updated attribute */
  
  if ((v = [self->updateAttrs valueForKey:_key]))
    return v;
#endif  
  /* check whether it's an existing attribute */
  
  if ((v = [[self attributes] valueForKey:_key]))
    return v;
  
  /* did not find attribute ? */
#if DEBUG && 0
  NSLog(@"%s: DID NOT FIND ATTRIBUTE %@\n"
        @"attrs: %@\nextattrs: %@\nnewattrs: %@\nupdattrs: %@",
        __PRETTY_FUNCTION__, _key,
        [self attributes],
        [self extendedAttributes],
        self->newAttrs, self->updateAttrs);
#endif
  
  return nil;
}

/* description */

- (NSString *)description {
  NSMutableString *s;

  s = [NSMutableString stringWithCapacity:32];
  [s appendFormat:@"<%@[0x%08X]:", NSStringFromClass([self class]), self];

  if ([self isNew]) {
    [s appendString:@" new"];
  }
  else {
    [s appendFormat:@" path='%@'", [self path]];
    [s appendFormat:@" gid='%@'", [self globalID]];
  }
  
  if (![self isComplete]) [s appendString:@" incomplete"];
  if (![self isValid])    [s appendString:@" invalid"];
  
  if (!self->fileManager)
    [s appendString:@" [filemanager missing]"];
  
  [s appendFormat:@">"];
  return s;
}

@end /* SkyProjectDocument */

@implementation SkyProjectDocument(Internals)

- (void)_setGlobalID:(EOGlobalID *)_gid {
  if (self->globalID) {
    if ([self->globalID isEqual:_gid])
      return;
    
    NSLog(@"ERROR[%s]: globalID is already set %@", __PRETTY_FUNCTION__, self);
    return;
  }
  
  self->globalID = [_gid retain];
  [self _registerForGID];
}

- (BOOL)_subjectChanged {
  return self->status.subjectChanged;
}
- (void)_setSubjectChanged:(BOOL)_bool {
  self->status.subjectChanged = _bool;
}

- (BOOL)_blobChanged {
  return self->status.blobChanged;
}
- (void)_setBlobChanged:(BOOL)_bool {
  self->status.blobChanged = _bool;
  if (_bool) {
    ASSIGN(self->blobAsDOM, (id)nil);
  }
}

- (void)_setIsEdited:(BOOL)_bool {
  self->status.isEdited = _bool;
}

- (NSMutableDictionary *)_newAttrs {
  return self->newAttrs;
}

- (NSMutableDictionary *)_updateAttrs {
  return self->updateAttrs;
}

- (NSMutableDictionary *)_newExtAttrs {
  return self->newExtAttrs;
}

- (NSMutableDictionary *)_updateExtAttrs {
  return self->updateExtAttrs;
}

- (void)refetchFileAttrs {
  NSString *path;
  
  if (![self isValid])
    return;
  
  [self->fileAttributes release]; self->fileAttributes = nil;
  [self->subject        release]; self->subject        = nil;

  if (self->globalID == nil) {
    self->fileAttributes = [[NSMutableDictionary alloc] init];
    return;
  }
    
#if DEBUG
  NSAssert(self->fileManager, @"missing filemanager ..");
#endif
    
  path = [self->fileManager pathForGlobalID:self->globalID];
  self->fileAttributes =
    [[self->fileManager fileAttributesAtPath:path traverseLink:NO]mutableCopy];
}

- (void)refetchProperties {
  /* TODO: split up big method */
  if (DebugOn) {
    [self logWithFormat:
            @"%s: refetching doc=0x%08X,path=%@: attrs=%s, ext=%s",
          __PRETTY_FUNCTION__, self, [self path],
          self->attributes         ? "yes" : "no",
          self->extendedAttributes ? "yes" : "no"];
  }
  
  if (self->extendedAttributes == nil)
    self->extendedAttributes =
      [[NSMutableDictionary alloc] initWithCapacity:64];
  else
    [self->extendedAttributes removeAllObjects];
  
  if (self->attributes == nil)
    self->attributes = [[NSMutableDictionary alloc] initWithCapacity:64];
  else
    [self->attributes removeAllObjects];
  
  [self->updateAttrs    removeAllObjects];
  [self->newAttrs       removeAllObjects];
  [self->updateExtAttrs removeAllObjects];
  [self->newExtAttrs    removeAllObjects];
  
  if (self->globalID) {
    NSDictionary             *allProps;
    NSEnumerator             *keyEnum;
    NSString                 *key, *defaultNS;
    SkyObjectPropertyManager *pm;
    NSAutoreleasePool *pool;
    
    if (DebugOn) {
      NSLog(@"%s: refetching props of '%@' (instance=0x%08X) ...",
            __PRETTY_FUNCTION__, [self path], self);
    }
    
    pool = [[NSAutoreleasePool alloc] init];
    
    defaultNS = [self->fileManager _defaultCompleteProjectDocumentNamespace];
    
    if (![self isValid])
      return;
    
    if ((pm = [[self->fileManager context] propertyManager]) == nil) {
      NSLog(@"ERROR[%s]: missing propertyManager for %@",
            __PRETTY_FUNCTION__, self->fileManager);
      return;
    }
    
    allProps = [pm propertiesForGlobalID:self->globalID];
    keyEnum  = [[allProps allKeys] objectEnumerator];
    
    while ((key = [keyEnum nextObject])) {
      if ([key hasPrefix:defaultNS]) {
        /* default-namespace attribute */
        NSString *localKey;
        
        if ((localKey = [key stringByRemovingXMLNamespace])) {
#if DEBUG
          NSAssert(self->attributes, @"missing attributes dict ..");
#endif
          
          [self->attributes
               setObject:[allProps objectForKey:key]
               forKey:localKey];
          continue;
        }
        else {
          NSLog(@"WARNING(%s): couldn't remove XML namespace from key %@",
                __PRETTY_FUNCTION__, key);
        }
      }
      
      /* different-namespace attribute */
      if (DebugOn)
        NSLog(@"add extended attribute %@ (def-ns=%@) ..", key, defaultNS);
      [self->extendedAttributes setObject:[allProps objectForKey:key]
                                forKey:key];
      
    }
    
    RELEASE(pool); pool = nil;
  }
}

- (void)_setFileAttributes:(NSDictionary *)_attrs {
  if (self->fileAttributes != (id)_attrs) {
    RELEASE(self->fileAttributes);
    self->fileAttributes = [_attrs mutableCopy];
    RELEASE(self->subject); self->subject = nil;
    self->status.subjectChanged = YES;
    self->status.isEdited       = YES;
  }
}
- (void)_setExtendedAttributes:(NSDictionary *)_attrs {
  if (self->extendedAttributes != (id)_attrs) {
    RELEASE(self->extendedAttributes);
    self->extendedAttributes = [_attrs mutableCopy];
    self->status.isEdited    = YES;
  }
}

- (void)_takeAttributesFromDictionary:(NSDictionary *)_dict
  namespace:(NSString *)_ns
  isComplete:(BOOL)_isComplete
{
  NSString *defNS;

  self->status.isComplete = _isComplete;
  
  defNS = [self->fileManager defaultProjectDocumentNamespace];
  
  /* TODO: split up */
  if (_ns == nil || [_ns isEqualToString:defNS]) {
    NSEnumerator *enumerator;
    id           k;
    
    if (!self->attributes)
      self->attributes = [[NSMutableDictionary alloc] initWithCapacity:128];
    
    enumerator = [[_dict allKeys] objectEnumerator];
    while ((k = [enumerator nextObject])) {
      [self->attributes setObject:[_dict objectForKey:k] forKey:
           [k stringByRemovingXMLNamespace]];
    }
  }
  else {
    if (!self->extendedAttributes) {
      self->extendedAttributes = [[NSMutableDictionary alloc]
                                                       initWithCapacity:128];
    }
    [self->extendedAttributes addEntriesFromDictionary:_dict];
  }
}

- (void)_registerForGID {
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"DebugDocumentRegistration"]) {
    NSLog(@"++++++++++++++++++ Warning: register Document"
          @" in NotificationCenter(%s)",
          __PRETTY_FUNCTION__);
  }

  if (self->globalID) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(invalidate)
                                          name:SkyGlobalIDWasDeleted
                                          object:self->globalID];
  }
}

- (void)setDataSource:(SkyProjectFolderDataSource *)_ds {
  ASSIGN(self->dataSource, _ds);
}

@end /* SkyProjectDocument(Internals) */
