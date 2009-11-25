/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <OGoFoundation/LSWViewerPage.h>

@class NSString;
@class EOGlobalID, EODataSource;
@class WOComponent;
@class SkyProjectDocument;

@interface SkyProject4DocumentViewer : LSWViewerPage
{
  id                 fileManager;
  EODataSource       *historyDataSource;
  NSString           *documentPath;
  EOGlobalID         *documentGID;
  WOComponent        *viewerComponent;
  
  SkyProjectDocument *document;
  NSDictionary       *fsinfo;
  id                 item;
  id                 key;
  NSString           *folderPath;
  
  NSString            *activeTabKey;
  NSMutableDictionary *tabComponentCache;
  NSArray             *tabKeys;

  NSString *openerURL;
}

- (NSDictionary *)fileSystemInfo;
- (void)setFileManager:(id)_fm;
- (id)fileManager;
- (void)setDocumentPath:(NSString *)_path;
- (NSString *)documentPath;
- (NSString *)_documentPath;
- (EOGlobalID *)documentId;

- (void)setDocument:(id)_doc;
- (id)document;

- (BOOL)isAccountDesigner;
- (void)setTestMode:(BOOL)_flag;
- (BOOL)isTestMode;

@end

#include "NGUnixTool.h"
#include "NSData+SkyTextEditable.h"
#include "NSString+P4.h"
#include <OGoFoundation/OGoClipboard.h>
#include <NGMime/NGMimeType.h>
#include <LSFoundation/SkyAccessManager.h>
#include <NGExtensions/NGResourceLocator.h>
#include <NGExtensions/NGRuleEngine.h>
#include <OGoDatabaseProject/SkyDocumentHistoryDataSource.h>
#include "common.h"

@interface SkyProjectFileManager(Internals)
- (id)_genRecForDoc:(id)_doc;
@end /* SkyProjectFileManager(Internals) */

@interface WOSession(JSLogs)
- (NSString *)javaScriptLog;
- (id)clearJavaScriptLog;
- (id)commandContext;
@end

@interface NSObject(MailEditor)
- (void)addMimePart:(id)_c type:(NGMimeType *)_mt name:(NSString *)_n;
@end /* NSObject(MailEditor) */

@interface NSObject(SkyFSKey)
- (EOGlobalID *)projectGID;
@end /* NSObject(SkyFSKey) */

@interface OGoComponent(OGoDocPartViewerSelection)
+ (BOOL)canShowInDocumentViewer:(OGoComponent *)_viewer;
@end

@implementation SkyProject4DocumentViewer

static NSDictionary  *docViewerPlugins = nil;
static NSArray       *sortedViewerKeys = nil;
static NGRuleModel   *viewerRules      = nil;
static NGRuleContext *viewerRuleEngine = nil; // THREAD
static Class SkyFSDocumentClass  = NULL;
static Class SkySvnDocumentClass = NULL;
static Class SkyFSGlobalIDClass  = NULL;
static BOOL  debugOn             = NO;
static BOOL  hasEpoz             = NO;

static int sortByIntField(id obj1, id obj2, void *ctx) {
  int i1, i2;
  i1 = [[obj1 valueForKey:(id)ctx] intValue];
  i2 = [[obj2 valueForKey:(id)ctx] intValue];
  if (i1 == i2) return NSOrderedSame;
  if (i1 > i2)  return NSOrderedAscending;
  return NSOrderedDescending;
}

+ (void)initialize {
  static BOOL didInit = NO;
  NSUserDefaults      *ud;
  NSMutableDictionary *md;
  NGBundleManager   *bm;
  NGResourceLocator *locator;
  NSFileManager     *fm;
  NSString          *p;
  NSArray           *viewers;
  unsigned i, count;
  
  if (didInit) return;
  didInit = YES;
  
  bm = [NGBundleManager defaultBundleManager];
  ud = [NSUserDefaults standardUserDefaults];
  
  SkyFSDocumentClass  = NSClassFromString(@"SkyFSDocument");
  SkyFSGlobalIDClass  = NSClassFromString(@"SkyFSGlobalID");
  SkySvnDocumentClass = NSClassFromString(@"SkySvnDocument");

  /* Epoz */
  
  fm = [NSFileManager defaultManager];
  locator = [NGResourceLocator resourceLocatorForGNUstepPath:
                                 @"WebServerResources"
                               fhsPath:@"share/opengroupware.org-5.5/www"];
  p = [locator lookupFileWithName:@"epoz_script_main.js"];
  hasEpoz = [fm fileExistsAtPath:p];
  if (!hasEpoz) 
    NSLog(@"Note: doc-viewer did not find Epoz.");
  else
    NSLog(@"Note: Epoz support is installed.");
  
  /* tab plugins */
  
  viewers = [bm providedResourcesOfType:@"OGoDocViewers"];
  count   = [viewers count];
  md      = [[NSMutableDictionary alloc] initWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    NSDictionary *rec;

    rec = [viewers objectAtIndex:i];
    [md setObject:rec forKey:[rec objectForKey:@"name"]];
  }
  
  viewers = [viewers sortedArrayUsingFunction:sortByIntField 
		     context:@"sortkey"];
  sortedViewerKeys = [[viewers valueForKey:@"name"] copy];
  
  docViewerPlugins = [md copy];
  [md release]; md = nil;
  NSLog(@"Note: found doc-viewers %@", 
	[sortedViewerKeys componentsJoinedByString:@","]);
  
  /* viewer rules */
  
  if ([(viewers = [ud arrayForKey:@"OGoDocViewerRules"]) isNotEmpty]) {
    NSArray *defRules;
    
    NSLog(@"Note: using custom doc-viewers rules (#%i).", [viewers count]);
    
    if ((defRules = [ud arrayForKey:@"OGoDocViewerFallbackRules"]) != nil)
      viewers = [viewers arrayByAddingObjectsFromArray:defRules];
  }
  else {
    NSLog(@"Note: using default doc-viewer rules.");
    viewers = [ud arrayForKey:@"OGoDocViewerFallbackRules"];;
  }
  
  viewerRules      = [[NGRuleModel alloc] initWithPropertyList:viewers];
  viewerRuleEngine = 
    [(NGRuleContext *)[NGRuleContext alloc] initWithModel:viewerRules];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->document reload];

  [self->tabComponentCache release];
  [self->activeTabKey      release];
  [self->tabKeys           release];

  [self->openerURL         release];
  [self->fsinfo            release];
  [self->documentGID       release];
  [self->historyDataSource release];
  [self->document          release];
  [self->viewerComponent   release];
  [self->fileManager       release];
  [self->documentPath      release];
  [self->item              release];
  [self->key               release];
  [self->folderPath        release];
  [super dealloc];
}

/* navigation */

- (NSString *)label {
  NSString *p;
  NSString *l;
  NSString *v;

  p = [self _documentPath];
  l = [[p lastPathComponent] stringByDeletingPathVersion];
  v = [p pathVersion];
  
  if ([v isNotEmpty])
    l = [NSString stringWithFormat:@"%@ (%@)", l, v];
  
  return l;
}

- (BOOL)isVersion {
  return [[[self _documentPath] pathVersion] isNotEmpty];
}

- (BOOL)isViewerForSameObject:(id)_object {
  if ([_object isEqual:[self documentId]])
    return YES;
  
  return NO;
}

- (id)mailDocument:(SkyProjectDocument *)_object type:(NGMimeType *)_type {
  BOOL addPart = YES;
  id mailEditor;

  mailEditor =
    [[WOApplication application] pageWithName:@"LSWImapMailEditor"];

  if (mailEditor == nil) {
    [self setErrorString:@"missing mail editor !"];
    return nil;
  }
  if (SkySvnDocumentClass && [_object isKindOfClass:SkySvnDocumentClass]) {
    NGMimeType *mimeType;

    mimeType = [NGMimeType mimeType:[_object valueForKey:@"NSFileMimeType"]];
    [mailEditor addMimePart:[_object content]
                type:mimeType
                name:[_object valueForKey:NSFileName]];
  }
  if (SkyFSDocumentClass && [_object isKindOfClass:SkyFSDocumentClass]) {
    NGMimeType *mimeType;

    mimeType = [NGMimeType mimeType:[_object valueForKey:@"NSFileMimeType"]];
    [mailEditor addMimePart:[_object content]
                type:mimeType
                name:[_object valueForKey:NSFileName]];
    addPart = NO;
  }
  
  if (addPart) {
    id doceo;
    
    doceo = [[_object fileManager] genericRecordForDocGID:[_object globalID]];
    [mailEditor addAttachment:doceo type:[NGMimeType mimeType:@"eo/doc"]];
  }
  
  [mailEditor setContentWithoutSign:@""];
  return mailEditor;
}

- (id)activateDocument:(SkyProjectDocument *)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (debugOn)
    [self debugWithFormat:@"activateDocument %@ document: %@", _verb,_object];
  
  if ([_verb isEqualToString:@"view"]) {
    /* configure viewer */
    [self setDocument:_object];
    return self;
  }
  
  if ([_verb isEqualToString:@"mail"])
    return [self mailDocument:_object type:_type];
  
  [self logWithFormat:@"couldn't activate document %@", _object];
  return nil;
}

- (id)activateKeyGlobalID:(EOKeyGlobalID *)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  EOKeyGlobalID      *dgid; // document gid
  EOGlobalID         *pgid = nil; // project gid
  id                 fm   = nil;
  SkyProjectDocument *doc  = nil;
  NSString           *path = nil;
  Class              class;
    
  dgid = _object;
  if ((class = NSClassFromString(@"SkyProjectFileManager")) == Nil) {
    [self warnWithFormat:@"did not find SkyProjectFileManager class!"];
    return nil;
  }
  
  pgid = [class projectGlobalIDForDocumentGlobalID:dgid
                context:[(OGoSession *)[self session] commandContext]];
  if (pgid == nil) {
    [self debugWithFormat:
            @"did not find project gid for document %@", dgid];
    return nil;        
  }
    
  fm = [[[class alloc] initWithContext:
                         [(OGoSession *)[self session] commandContext]
                       projectGlobalID:pgid] 
                       autorelease];
  if (fm == nil) {
      [self logWithFormat:
              @"could not create filemanager for pgid %@, document %@",
              pgid, dgid];
      return nil;
  }
    
  if ((path = [fm pathForGlobalID:dgid]) == nil) {
      [[[self context] page]
              takeValue:@"DocumentViewer couldn't get path for gid .."
              forKey:@"errorString"];
      [self logWithFormat:
              @"couldn't get path for gid %@ using filemanager %@",
              dgid, fm];
      return nil;
  }

  if ((doc = [(SkyProjectFileManager *)fm documentAtPath:path]) == nil) {
      [[[self context] page]
              takeValue:@"DocumentViewer couldn't get document for path .."
              forKey:@"errorString"];
      [self logWithFormat:
              @"couldn't get document for path %@ using filemanager %@",
              path, fm];
      return nil;
  }

  return [self activateDocument:doc verb:_verb type:_type];
}

- (id)activateFSGlobalID:(id)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  NSString   *path;
  EOGlobalID *pid;
  id         fm, doc;
  
  if (SkyFSGlobalIDClass != Nil) {
    if (![_object isKindOfClass:SkyFSGlobalIDClass]) {
      [self logWithFormat:@"could not activate object %@", _object];
      return nil;
    }
  }
  pid  = [_object projectGID];
  path = [_object path];

  fm = [[OGoFileManagerFactory sharedFileManagerFactory]
         fileManagerInContext:[(OGoSession *)[self session] commandContext]
         forProjectGID:pid];
  if (fm == nil) {
    [self logWithFormat:@"couldn't activate object %@", _object];
    return nil;
  }
  doc = [(SkyProjectFileManager *)fm documentAtPath:path];
  return [self activateDocument:doc verb:_verb type:_type];
}

- (id)activateObject:(id)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (_object == nil)
    return nil;

  if ([_object isKindOfClass:[SkyDocument class]])
    return [self activateDocument:_object verb:_verb type:_type];

  if ([_object isKindOfClass:[SkyProjectHistoryDocument class]])
    return [self activateDocument:_object verb:_verb type:_type];
  
  if ([_object isKindOfClass:[EOKeyGlobalID class]])
    return [self activateKeyGlobalID:_object verb:_verb type:_type];

  if (SkyFSGlobalIDClass) {
    if ([_object isKindOfClass:SkyFSGlobalIDClass]) {
      return [self activateFSGlobalID:_object verb:_verb type:_type];
    }
  }
  [self logWithFormat:@"couldn't activate object %@", _object];
  return nil;
}

/* notifications */

- (void)sleep {
  [self->openerURL release]; self->openerURL = nil;
  [super sleep];
}

/* accessors */

- (void)setFolderPath:(NSString *)_path {
  ASSIGN(self->folderPath, _path);
}
- (NSString *)folderPath {
  return self->folderPath;
}

- (void)setDocumentId:(EOGlobalID *)_gid {
  [[NSNotificationCenter defaultCenter]
                         addObserver:self selector:@selector(clearAccess)
                         name:@"SkyAccessHasChangedNotification" object:_gid];
  ASSIGNCOPY(self->documentGID, _gid);
}
- (EOGlobalID *)documentId {
  if (self->document)
    return [self->document globalID];
  
  if ((self->documentGID == nil) && (self->documentPath != nil)) {
    EOGlobalID *gid;
    
    gid = [[[self fileManager]
                  fileAttributesAtPath:self->documentPath
                  traverseLink:NO]
                  objectForKey:@"globalID"];
    [self setDocumentId:gid];
  }
  return self->documentGID;
}

- (EOGlobalID *)documentGlobalID {
  return [self documentId];
}
- (EOGlobalID *)projectGlobalID {
  return [[self fileSystemInfo] objectForKey:@"NSFileSystemNumber"];
}

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (Class)historyDataSourceClass {
  return NSClassFromString(@"SkyDocumentHistoryDataSource");
}
- (EODataSource *)historyDataSource {
  if (![[self fileManager] supportsHistoryDataSource])
    return nil;
  
  if (self->historyDataSource)
    return self->historyDataSource;
    
  self->historyDataSource =
    [[[self historyDataSourceClass] alloc]
      initWithFileManager:[self fileManager]
      documentGlobalID:[self documentGlobalID]];
  return self->historyDataSource;
}

- (void)setDocumentPath:(NSString *)_p {
  ASSIGNCOPY(self->documentPath, _p);
}

- (NSString *)_documentPath {
  if (self->document)
    return [self->document path];
  
  if (self->documentGID)
    return [self->fileManager pathForGlobalID:self->documentGID];
  
  return [self documentPath];
}

- (NSString *)documentPath {
  if (self->documentPath)
    return self->documentPath;
  
  return [[self fileManager] pathForGlobalID:[self documentId]];
}
- (NSString *)documentName {
  return [[self _documentPath] lastPathComponent];
}
- (NSData *)documentContent {
  return [[self document] content];
}

- (void)setDocument:(id)_doc {
  id            fm;
  EOKeyGlobalID *gid;
  NSString      *path;
  
  if (self->document == _doc)
    return;

  [_doc reload]; // clear ?
    
  if ((fm = [(SkyProjectDocument *)_doc fileManager]) == nil) {
    [self logWithFormat:@"missing filemanager in document %@ !!", _doc];
    return;
  }
#if 0 /* todo: can be rmeoved ?? */
  // there are "documents" without own globalID. (SkyProjectHistoryDocument)
  if ((gid = (id)[_doc globalID]) == nil) {
      [self logWithFormat:@"missing global-id in document %@ !!", _doc];
      return;
  }
#endif
  gid = (id)[_doc globalID];
  if ((path = [_doc valueForKey:NSFilePath]) == nil) {
      [self logWithFormat:@"missing path in document %@ !!", _doc];
      return;
  }
    
  [self setFileManager:fm];
  [self setDocumentId:gid];
  [self setDocumentPath:path];
    
  ASSIGN(self->document, _doc);
    
  [self->fsinfo release]; self->fsinfo = nil;
}
- (id)document {
  id            fm;
  EOKeyGlobalID *gid;
  
  if (self->document)
    return self->document;
  
  if ((fm = [self fileManager]) == nil) {
    [self logWithFormat:@"called -document, but no filemanager is set !!"];
    return nil;
  }
  if ((gid = (id)[self documentId]) == nil) {
    [self logWithFormat:@"called -document, but no document-gid is set !!"];
    return nil;
  }

  if ([gid isKindOfClass:[EOKeyGlobalID class]]) {
    self->document =
      [[NSClassFromString(@"SkyProjectDocument") alloc]
                                                 initWithGlobalID:gid
                                                 fileManager:fm];
  
    if (debugOn)
      [self debugWithFormat:@"created 'document': %@", self->document];
    
    if ([self->document isNew]) {
      if (debugOn) {
	[self errorWithFormat:@"created *new* 'document' ???: %@",
	        self->document];
      }
    }
  }
  else if (SkyFSGlobalIDClass != Nil) {
    if ([gid isKindOfClass:SkyFSGlobalIDClass]) {
      NSString *lpath;

      lpath = [self->fileManager pathForGlobalID:gid];
      self->document =
	[[(SkyProjectFileManager *)self->fileManager documentAtPath:lpath] 
	  retain];
    }
  }
  return self->document;
}

- (NSString *)objectUrlKey {
  EOGlobalID *gid;

  gid = (EOKeyGlobalID *)[self documentId];

  if (![gid isKindOfClass:[EOKeyGlobalID class]])
    return nil;
  
  return [[NSString stringWithFormat:
                      @"wa/LSWViewAction/viewDocument?documentId=%@",
                      [(EOKeyGlobalID *)[self documentId] keyValues][0]]
                      stringByEscapingURL];
}

- (BOOL)showOnlyForm { // TODO: DEPRECATED?
  [self logWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  return NO;
}

- (BOOL)canTestDocument { // TODO: DEPRECATED?
  [self logWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  return NO;
}

- (NSDictionary *)fileSystemInfo {
  if (self->fsinfo != nil)
    return self->fsinfo;
  
  self->fsinfo = [[[self fileManager]
                         fileSystemAttributesAtPath:[self _documentPath]]
                         copy];
  return self->fsinfo;
}
- (NSDictionary *)documentAttributes {
  return [[self fileManager]
                fileAttributesAtPath:[self _documentPath]
                traverseLink:YES];
}

- (BOOL)isDocumentLocked {
  if ([[self fileManager] supportsVersioningAtPath:[self _documentPath]]) {
    if (self->document)
      return [self->document isLocked];
  
    return [[self fileManager] isFileLockedAtPath:[self _documentPath]];
  }
  return NO;
}

/* download stuff */

- (NSString *)downloadURL {
  NSString *url;
  NSString *s;
  NSString *qs;
  
  s = [NSString stringWithFormat:@"/%@%@",
                  [[self fileSystemInfo] objectForKey:@"NSFileSystemName"],
                  [self _documentPath]];

  qs = [NSString stringWithFormat:@"wosid=%@&woinst=%@",
                   [[self session] sessionID],
                   [[self application] number]];
  
  url = [[self context] urlWithRequestHandlerKey:@"g"
                        path:s
                        queryString:qs];
  
  return url;
}
- (NSString *)documentMimeType {
  NSString *mimeType;
  
  if ((mimeType = [[self documentAttributes] objectForKey:@"NSFileMimeType"]))
    return [mimeType stringValue];
  
  return @"application/octet-stream";
}

- (NSString *)urlPattern {
  return [[[self session] userDefaults] stringForKey:@"project_docurlpat"];
}

- (NSString *)openerUrlForFile {
  NSMutableDictionary *bindings;
  NSDictionary *fs;
  NSString *pat;
  id tmp, user;

  if (self->openerURL != nil)
    return self->openerURL;
  
  pat = [self urlPattern];
  
  bindings = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  if ([(tmp = [self documentPath]) isNotEmpty])
    [bindings setObject:tmp forKey:@"path"];
  if ([(tmp = [self documentName]) isNotEmpty])
    [bindings setObject:tmp forKey:@"name"];
  
  if ([(tmp = [self documentId]) isKindOfClass:[EOKeyGlobalID class]])
    [bindings setObject:[[tmp keyValues][0] stringValue] forKey:@"doc_id"];
  
  /* project */

  fs = [self fileSystemInfo];

  if ([(tmp = [fs valueForKeyPath:@"object.projectId"]) isNotEmpty])
    [bindings setObject:[tmp stringValue] forKey:@"project_id"];
  else if ([(tmp =[self projectGlobalID]) isKindOfClass:[EOKeyGlobalID class]])
    [bindings setObject:[[tmp keyValues][0] stringValue] forKey:@"project_id"];
  
  if ([(tmp = [fs valueForKeyPath:@"object.name"]) isNotEmpty])
    [bindings setObject:[tmp stringValue] forKey:@"project_name"];
  else if ([(tmp = [fs valueForKey:@"NSFileSystemName"]) isNotEmpty])
    [bindings setObject:[tmp stringValue] forKey:@"project_name"];
  
  if ([(tmp = [fs valueForKeyPath:@"object.number"]) isNotNull])
    [bindings setObject:[tmp stringValue] forKey:@"project_number"];

  /* user info */

  user = [[self session] activeAccount];
  
  if ([(tmp = [user valueForKey:@"companyId"]) isNotNull])
    [bindings setObject:[tmp stringValue] forKey:@"user_id"];
  if ([(tmp = [user valueForKey:@"login"]) isNotNull])
    [bindings setObject:[tmp stringValue] forKey:@"user_login"];
  if ([(tmp = [user valueForKey:@"number"]) isNotNull])
    [bindings setObject:[tmp stringValue] forKey:@"user_number"];
  
  /* create URL */
  
  self->openerURL = [[pat stringByReplacingVariablesWithBindings:bindings
			  stringForUnknownBindings:@""] copy];
  
  [bindings release]; bindings = nil;
  
  return self->openerURL;
}

/* button config */

- (BOOL)hasMail {
  return [self isVersion] == NO;
}
- (BOOL)hasClip {
  return [self isVersion] == NO;
}

- (BOOL)hasEditAsNew {
  NSString *ext;
  NSString *mtype;

  if ([self isVersion]) return NO;
  
  mtype = [[self document] valueForKey:@"NSFileMimeType"];
  mtype = [mtype stringValue];
  if ([mtype hasPrefix:@"text/"])  return YES;
  if ([mtype hasPrefix:@"image/"]) return NO;
  
  ext = [[self _documentPath] pathExtension];
  return [ext isEditAsNewExtension];
}

- (BOOL)hasCheckout {
  if ([self isVersion])
    return NO;

  /* must not be checked out, must support versioning */
  if (![[self fileManager] supportsVersioningAtPath:[self _documentPath]])
    return NO;
  
  if ([self isDocumentLocked])
    /* document is already locked */
    return NO;
  
  if (![[self fileManager] isWritableFileAtPath:[self _documentPath]])
    /* account has no write access to the document */
    return NO;
  
  return YES;
}
- (BOOL)hasReject {
  if ([self isVersion])
    return NO;

  /* must be checked out, must support versioning */
  if (![[self fileManager] supportsVersioningAtPath:[self _documentPath]])
    return NO;

  if (![self isDocumentLocked])
    /* not checked out */
    return NO;
  
  if (![[self fileManager] isUnlockableFileAtPath:[self _documentPath]])
    return NO;

  return YES;
}
- (BOOL)hasRelease {
  if ([self isVersion])
    return NO;
  
  /* must be checked out, must support versioning */
  if (![[self fileManager] supportsVersioningAtPath:[self _documentPath]])
    return NO;
  
  if (![self isDocumentLocked])
    /* not checked out */
    return NO;

  if (![[self fileManager] isUnlockableFileAtPath:[self _documentPath]])
    return NO;
  
  return YES;
}

- (BOOL)hasLock {
  if ([self isVersion])
    return NO;

  /* must not be locked, must not support versioning, must support locking */
  if ([[self fileManager] supportsVersioningAtPath:[self _documentPath]])
    return NO;
  if (![[self fileManager] supportsLockingAtPath:[self _documentPath]])
    return NO;
  
  if ([self isDocumentLocked])
    /* already locked */
    return NO;
  
  if (![[self fileManager] isLockableFileAtPath:[self _documentPath]])
    return NO;

  return YES;
}
- (BOOL)hasUnlock {
  if ([self isVersion])
    return NO;

  /* must be locked, must not support versioning, must support locking */
  if ([[self fileManager] supportsVersioningAtPath:[self _documentPath]])
    return NO;
  if (![[self fileManager] supportsLockingAtPath:[self _documentPath]])
    return NO;
  
  if (![[self fileManager] isUnlockableFileAtPath:[self _documentPath]])
    return NO;
  
  return YES;
}

- (BOOL)hasRename {
  if ([self isVersion])
    return NO;
  
  return [[self document] isWriteable];
}

- (BOOL)hasTypeEdit {
  NSString *mimeType;
   
  if ([self isVersion])
    return NO;

  if (![[self document] isWriteable])
    return NO;
  
  mimeType = [[[self document] valueForKey:@"NSFileMimeType"] stringValue];
  if ([mimeType hasPrefix:@"image/"])  return NO;
  if ([mimeType hasPrefix:@"text/"])   return YES;
  if ([mimeType hasPrefix:@"skyrix/"]) return YES;
  if ([mimeType hasPrefix:@"video/"])  return NO;
  if ([mimeType hasPrefix:@"audio/"])  return NO;
  if ([mimeType hasPrefix:@"application/pdf"]) return NO;
  
  return [[[self document] content] isSkyTextEditable];
}
- (BOOL)hasUpload {
  if ([self isVersion]) // TODO: the version document should have that?
    return NO;
  
  return [[self document] isWriteable];
}
- (BOOL)hasDelete {
  if ([self isVersion]) // TODO: the version document should have that?
    return NO;
  
  return [[self document] isDeletable];
}
- (BOOL)hasMove {
  NSString *dirpath;
  
  if ([self isVersion]) // TODO: the version document should have that
    return NO;
  
  dirpath = [[self _documentPath] stringByDeletingLastPathComponent];
  
  return [[self fileManager] isOperation:@"d" allowedOnPath:dirpath];
}
- (BOOL)hasUnzip {
  NSString      *mimeType;
  NSFileManager *fm;

  mimeType = [[[self document] valueForKey:@"NSFileMimeType"] stringValue];
  fm       = [NSFileManager defaultManager];
  return
    ([[[self documentAttributes] objectForKey:NSFileSize] intValue] > 0) &&
    (([mimeType hasPrefix:@"application/zip"] &&
      [fm fileExistsAtPath:[NGUnixTool pathToUnzipTool]] &&
      [fm fileExistsAtPath:[NGUnixTool pathToZipInfoTool]]) ||
     ([mimeType hasPrefix:@"application/x-tar"] &&
      [fm fileExistsAtPath:[NGUnixTool pathToTarTool]]));
}

- (BOOL)hasNewest {
  return [self isVersion] && [[[self document] mainDocument] isWriteable];
                             // check if the document, this version is a part
                             // of, is writable
}

- (BOOL)hasSaveAs {
  return [self isVersion];
}

- (BOOL)hasOpenLocally {
  return [[self urlPattern] isNotEmpty];
}

/* operations */

- (BOOL)isAccountDesigner { // TODO: DEPRECATED?
  [self logWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  return [[self fileManager]
                isOperation:@"f"
                allowedOnPath:[self _documentPath]];
}

- (void)setTestMode:(BOOL)_flag { // TODO: DEPRECATED?
  [self logWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  [(OGoSession *)[self session] 
                 setObject:[NSNumber numberWithBool:_flag]
                 forKey:@"SkyP4FormTestMode"];
}
- (BOOL)isTestMode { // TODO: DEPRECATED?
  [self logWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  return [[(OGoSession *)[self session] 
                         objectForKey:@"SkyP4FormTestMode"] boolValue];
}

- (void)setDefaultProjectViewerTabKey:(NSString *)_key {
  [[[self session] userDefaults] setObject:_key 
				 forKey:@"skyp4_projectviewer_tab"];
}

- (Class)dbFileManagerClass {
  return NSClassFromString(@"SkyProjectFileManager");
}
- (BOOL)isDocumentInDBProject {
  Class clazz;
  
  if ((clazz = [self dbFileManagerClass]) == nil)
    return NO;
  return [[self fileManager] isKindOfClass:clazz];
}

/* actions */

- (id)clearJavaScriptLog {
  // TODO: deprecated forms support?
  [self logWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  [[self session] clearJavaScriptLog];
  return nil;
}

- (OGoContentPage *)newPageForClickedFolder {
  OGoContentPage   *page;
  LSCommandContext *ctx;
  EOGlobalID       *pgid1;
  Class class;
  id pgid2;
  id fm;
  
  page = [[(OGoSession *)[self session] navigation] activePage];

  /* activate the filemanager for non-DB projects */
  
  if (![self isDocumentInDBProject]) {
    if (![[page name] isEqual:@"SkyProject4Viewer"])
      /* if the previous page on the stack is not the project viewer */
      return [self activateObject:[self fileManager] withVerb:@"view"];
    
    return page;
  }

  /* more complex processing for DB ones */

  class = [self dbFileManagerClass];
  ctx   = [(OGoSession *)[self session] commandContext];
  
  pgid1 = [class projectGlobalIDForDocumentGlobalID:
		       [self documentId] context:ctx];
  
  if (![[page name] isEqual:@"SkyProject4Viewer"]) {
    /* if the previous page on the stack is not the project viewer */
    return [self activateObject:pgid1 withVerb:@"view"];
  }
  
  if ((fm = [(SkyProject4DocumentViewer *)page fileManager]) == nil) {
    // TODO: replace with a proper label
    [self setErrorString:
	    @"could not change current folder in last page.."];
    return self;
  }
  pgid2 = [[fm fileSystemAttributesAtPath:@"/"]
               objectForKey:NSFileSystemNumber];
  
  // TODO: this is kind of a hack, pgid SHOULD never be nil, but sometimes it
  //       is (probably because SkyDocumentIdHandler is not properly refreshed)
  if (pgid1 != nil && ![pgid1 isEqual:pgid2])
    page = [self activateObject:pgid1 withVerb:@"view"];
  
  return page;
}

- (id)folderClicked {
  NSString       *newpath;
  OGoContentPage *page;
  id fm;
  
  newpath = [self valueForKey:@"folderPath"];
  [self debugWithFormat:@"clicked on folder: %@", newpath];
  
  if (![[self fileManager] changeCurrentDirectoryPath:newpath]) {
    [self setErrorString:@"couldn't change current folder .."];
    return nil;
  }
  
  [[(OGoSession *)[self session] navigation] leavePage];
  
  /* determine new page to show */
  
  page = [self newPageForClickedFolder];
  
  /* fill new page with filemanager context */
  
  if ((fm = [(SkyProject4DocumentViewer *)page fileManager]) == nil) {
    [self setErrorString:@"couldn't change current folder in last page .."];
    return self;
  }
  if (![fm changeCurrentDirectoryPath:newpath]) {
    [self setErrorString:@"couldn't change current folder in last page .."];
    return self;
  }
  
  [self setDefaultProjectViewerTabKey:@"documents"];
  return page;
}

- (id)placeInClipboard {
  EOGlobalID *gid;
  
  gid = [self documentGlobalID];
  [[(OGoSession *)[self session] favorites] addObject:gid];
  return nil;
}

- (id)_showFileManagerError:(NSString *)_reason {
  NSException *e;
  
  if (_reason == nil)
    _reason = @"Error in filemanager processing";
  
  if ((e = [[self fileManager] lastException]) != nil) {
    _reason = [_reason stringByAppendingString:@": "];
    _reason = [_reason stringByAppendingString:[e description]];
  }
  
  [self setErrorString:_reason];
  return nil;
}

- (id)_performFileManagerOp:(SEL)_sel 
  clearEditorAfterOperation:(BOOL)_clear
  failText:(NSString *)_error
{
  BOOL (*op)(id, SEL, NSString *, id);
  BOOL ok;
  id lFm;
  
  if ((lFm = [self fileManager]) == nil) {
    [self setErrorString:@"No filemanager!"];
    return nil;
  }
  if ((op = (void *)[lFm methodForSelector:_sel]) == NULL) {
    [self setErrorString:@"Invalid filemanager operation!"];
    return nil;
  }
  
  ok = op(lFm, _sel, [self _documentPath], nil /* handler */);
  if (_clear) {
    [self->documentPath release]; self->documentPath = nil;
    [self->document     release]; self->document     = nil;
    [self->fsinfo       release]; self->fsinfo       = nil;
  }
  
  if (!ok) /* call failed */
    return [self _showFileManagerError:_error];
  
  /* everything is fine, stay on page */
  return nil;
}

- (id)checkoutDocument {
  return [self _performFileManagerOp:@selector(checkoutFileAtPath:handler:)
               clearEditorAfterOperation:NO
               failText:@"Could not checkout document"];
}
- (id)rejectDocument {
  return [self _performFileManagerOp:@selector(rejectFileAtPath:handler:)
               clearEditorAfterOperation:YES
               failText:@"Could not reject document"];
}
- (id)releaseDocument {
  return [self _performFileManagerOp:@selector(releaseFileAtPath:handler:)
               clearEditorAfterOperation:YES
               failText:@"Could not release document"];
}

- (id)lockDocument {
  return [self _performFileManagerOp:@selector(lockFileAtPath:handler:)
               clearEditorAfterOperation:NO
               failText:@"Could not lock document"];
}
- (id)unlockDocument {
  return [self _performFileManagerOp:@selector(unlockFileAtPath:handler:)
               clearEditorAfterOperation:NO
               failText:@"Could not unlock document"];
}

- (id)upload {
  return [self activateObject:[self document] withVerb:@"upload"];
}

- (BOOL)isEpozEnabled {
  WEClientCapabilities *cc;
  
  if (!hasEpoz)
    return NO;
  
  cc = [[[self context] request] clientCapabilities];
  if ([cc isInternetExplorer]) {
    if ([cc majorVersion] <= 4) {
      [self debugWithFormat:@"disable Epoz with IE <5"];
      return NO;
    }
    if ([cc majorVersion] == 5 && [cc minorVersion] <= 5) {
      [self debugWithFormat:@"disable Epoz with IE <5.5"];
      return NO;
    }
    [self debugWithFormat:@"enable Epoz with IE >=5.5"];
    return YES;
  }
  
  if ([cc isMozilla] || [cc isNetscape]) {
    [self debugWithFormat:@"enable Epoz with Mozilla: %@", cc];
    return YES;
  }
  
  return NO;
}

- (id)edit {
  id page;
  
  if ((page = [self activateObject:[self document] withVerb:@"edit"]) == nil)
    return nil;
  
  if ([self isEpozEnabled]) { 
    /* we have Epoz installed, check whether we are editing .html! */
    if ([[self documentMimeType] hasPrefix:@"text/html"])
      [page takeValue:[NSNumber numberWithBool:YES] forKey:@"isEpozEnabled"];
  }
  return page;
}

- (id)editProperties {
  WOComponent *page;
  
  if ((page = [self pageWithName:@"SkyObjectPropertyEditor"]) == nil) {
    [self setErrorString:@"Could not find property editor!"];
    return nil;
  }

  [page takeValue:[self documentGlobalID]          forKey:@"globalID"];
  [page takeValue:[[self fileManager] defaultProjectDocumentNamespace]
        forKey:@"defaultNamespace"];
  [page takeValue:[self labels] forKey:@"labels"];
  return page;
}

- (id)deleteDocument {
  NSString *path;
  NSString *trashPath;
  
  path      = [self _documentPath];
  trashPath = [[self fileManager] trashFolderForPath:path];
  
  if ([path hasPrefix:trashPath]) {
    /* delete */
    if (![[self fileManager] removeFileAtPath:path handler:nil]) {
      [self setErrorString:@"couldn't delete file"];
      return nil;
    }
  }
  else {
    /* move to trash */
    if (![[self fileManager] trashFileAtPath:path handler:nil]) {
      [self setErrorString:@"couldn't move file to trash folder"];
      return nil;
    }
  }
  
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)renameDocument {
  id page;
  
  page = [self activateObject:[self document] withVerb:@"rename"];
  [self->documentPath release]; self->documentPath = nil;
  [self->document release];     self->document     = nil;
  [self->fsinfo release];       self->fsinfo       = nil;
  return page;
}

- (id)editAsNew {
  if ([[[[self document] valueForKey:@"NSFileMimeType"]
               stringValue] hasPrefix:@"text/html"])
    [[self context] takeValue:[NSNumber numberWithBool:YES] forKey:@"UseEpoz"];

  return [self activateObject:[self document] withVerb:@"editAsNew"];
}
- (id)mailObject {
  if (SkyFSDocumentClass) {
    if ([[self document] isKindOfClass:SkyFSDocumentClass]) {
      return [self activateObject:[self document] withVerb:@"mail"];
    }
  }
  return [self activateObject:[self documentId] withVerb:@"mail"];
}

- (id)testDocument {
  [self setTestMode:YES];
  return nil;
}
- (id)disableTest {
  [self setTestMode:NO];
  return nil;
}
- (id)closeWindow {
  return [[[self session] navigation] leavePage];
}

- (id)unzipDocument {
  id unzipPanel = nil;
  unzipPanel = [self pageWithName:@"SkyP4UnzipPanel"];
  [unzipPanel takeValue:[self fileManager]        forKey:@"fileManager"];
  [unzipPanel takeValue:[self _documentPath]      forKey:@"fileName"];
  [unzipPanel takeValue:[[self document] content] forKey:@"zipData"];
  //[unzipPanel setVersion:[self versionToView]];
  return unzipPanel;
}

- (id)newest {
  id fm;
  LSCommandContext *cntx;
  NSString *p;

  fm   = [self fileManager];
  cntx = [(OGoSession *)[self session] commandContext];
  p    = [[self _documentPath] stringByDeletingPathVersion];
  [fm writeContents:[self documentContent] atPath:p];
  [cntx commit];

  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)saveAs {
  id page;

  page = [self pageWithName:@"SkyProject4DocumentVersionSave"];
  [page takeValue:[self fileManager]   forKey:@"fileManager"];
  [page takeValue:[self _documentPath] forKey:@"filePath"];
  return page;
}

/* access */

- (NSArray *)accessChecks {
  static NSArray *accessChecks = nil;
  if (accessChecks == nil)
    accessChecks = [[NSArray alloc] initWithObjects:@"r", @"w", nil];
  return accessChecks;
}

- (BOOL)canReadFile {
  return [[self fileManager] isReadableFileAtPath:[self _documentPath]];
}

- (id)editAccess {
  WOComponent *page;

  // TODO: use activation?!
  if ((page = [self pageWithName:@"SkyCompanyAccessEditor"]) == nil) {
    [self setErrorString:@"could not find access editor !"];
    return nil;
  }
  
  [page takeValue:[self documentGlobalID] forKey:@"globalID"];
  [page takeValue:[self accessChecks]     forKey:@"accessChecks"];
  return page;
}

- (NSDictionary *)accessIds {
  LSCommandContext *cmdctx;

  cmdctx = [(OGoSession *)[self session] commandContext];
  return [[cmdctx accessManager] 
	          allowedOperationsForObjectId:self->documentGID];
}

- (void)clearAccess {
}

- (id)editStandardAttrs {
  WOComponent *page;
  
  page = [self pageWithName:@"SkyDocumentAttributeEditor"];
  [page takeValue:[self document]  forKey:@"doc"];
  
  if (self->documentGID == nil)
    self->documentGID = [[self->document globalID] retain];
  
  [self->documentPath release]; self->documentPath = nil;
  [self->document release];     self->document     = nil;
  [self->fsinfo release];       self->fsinfo       = nil;
  
  return page;
}

- (NSDictionary *)docStandardAttrs {
  NSString *subj;
  
  subj = [[self document] subject];

  if (![subj isNotNull])
    subj = @"";
  
  return [NSDictionary dictionaryWithObject:subj forKey:@"subject"];
}

- (void)setItem:(id)_id {
  ASSIGN(self->item, _id);
}
- (id)item {
  return self->item;
}

- (void)setKey:(NSString *)_id {
  ASSIGNCOPY(self->key, _id);
}
- (NSString *)key {
  return self->key;
}

- (NSString *)defaultPropertyNamespace {
  return XMLNS_PROJECT_DOCUMENT;
}

- (BOOL)hasEditAttrs {
  if (![[self fileManager] isWritableFileAtPath:[self _documentPath]])
    return NO;
  
  return YES;
}

/* SkyPublisher */

- (BOOL)hasPublisher {
  static int hasPub = -1;
  if (hasPub == -1)
    hasPub = NSClassFromString(@"SkyPublisherModule") ? 1 : 0;
  return hasPub;
}
- (BOOL)hasPubPreview {
  NSString *ext;
  NSString *mtype;
  
  if (![self hasPublisher]) return NO;
  
  if ((mtype = [[[self document] valueForKey:@"NSFileMimeType"] stringValue]))
    if ([mtype isPubPreviewMimeType]) return YES;
  
  ext = [[[self document] path] pathExtension];
  return [ext isPubPreviewExtension];
}

- (BOOL)isPubDOMDocument {
  NSString *ext;
  NSString *mtype;
  
  if ((mtype = [[self document] valueForKey:@"NSFileMimeType"])) {
    mtype = [mtype stringValue];
    if ([mtype isPubDOMMimeType])    return YES;
    if ([mtype hasPrefix:@"image/"]) return NO;
  }
  
  ext = [[[self document] path] pathExtension];
  return [ext isPubDOMExtension];
}

- (BOOL)showPubPreview {
  NSString *mtype;
  
  mtype = [[self document] valueForKey:@"NSFileMimeType"];
  mtype = [mtype stringValue];
  return [mtype isPubPreviewMimeType];
}
- (BOOL)showPubSource {
  return [self isPubDOMDocument];
}
- (BOOL)showPubLinks {
  return [self isPubDOMDocument];
}

- (NSString *)pubPreviewURL {
  NSString *url;
  NSString *qs;
  
  if (![self hasPublisher])
    return nil;
  
  url = @"/SkyPubDirectAction/pubPreview";
  qs  = [[self document] valueForKey:@"NSFilePath"];
  url = [url stringByAppendingString:qs];
  
  qs = [[WORequestValueSessionID stringByAppendingString:@"="]
                                 stringByAppendingString:
                                   [[self session] sessionID]];
  
  return [[self context] urlWithRequestHandlerKey:
                           [WOApplication directActionRequestHandlerKey]
                         path:url queryString:qs];
}

/* actions */

- (id)refresh {
  NSAutoreleasePool *pool;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  [(SkyProjectFileManager *)[self fileManager] flush];
  if (![[self fileManager] fileExistsAtPath:[self _documentPath]
                           isDirectory:NULL]) {
    return [[[self session] navigation] leavePage];
  }
  [self->document reload];
  [pool release];
  return nil;
}

- (BOOL)supportsProperties {
  return [[self fileManager] supportsProperties];
}

/* dynamic tabs */

- (NSArray *)tabKeys {
  NSMutableArray *keys;
  NSEnumerator   *e;
  NSString       *k;

  if (self->tabKeys != nil)
    return self->tabKeys;
  
  /* determine viewer keys using rule engine */
  if (viewerRuleEngine != nil) {
    [viewerRuleEngine reset];
    [viewerRuleEngine takeStoredValue:self             forKey:@"page"];
    [viewerRuleEngine takeStoredValue:[self document]  forKey:@"document"];
    [viewerRuleEngine takeStoredValue:[self fileManager] 
		      forKey:@"fileManager"];
    
    e = [[viewerRuleEngine inferredValueForKey:@"tabkeys"] objectEnumerator];
    
    [viewerRuleEngine reset];
  }
  else
    e = [sortedViewerKeys objectEnumerator];
  
  keys = [[NSMutableArray alloc] initWithCapacity:8];
  while ((k = [e nextObject]) != nil) {
    NSDictionary *info;
    NSString     *tmp;
    
    if ((info = [docViewerPlugins objectForKey:k]) == nil) {
      /* rule selected key, but it isn't installed */
      [self warnWithFormat:@"did not find tab key: '%@'", k];
      continue;
    }
    
    if ((tmp = [info objectForKey:@"component"]) != nil) {
      /*
	Note: unfortunately we can't use EOQualifier's as gates, because they
	      do not allow for reasonable queries on boolean results.
	      (isVersion = 1 vs isVersion = YES vs isVersion = 'true' etc)
      */
      Class clazz;
      
      if ((clazz = NSClassFromString(tmp)) != Nil) {
	if (![clazz canShowInDocumentViewer:self])
	  continue;
      }
    }
    
    [keys addObject:k];
  }

  self->tabKeys = [keys copy];
  [keys release]; keys = nil;

  if (![self->tabKeys isNotEmpty]) {
    [self errorWithFormat:
	    @"got no tab keys from rule model: %@, rules=%@",
	    viewerRules, [viewerRules candidateRulesForKey:@"tabkeys"]];
    return nil;
  }
  return self->tabKeys;
}

- (void)setActiveTabKey:(NSString *)_path {
  ASSIGNCOPY(self->activeTabKey, _path);
}
- (NSString *)activeTabKey {
  return self->activeTabKey;
}

- (WOComponent *)componentForActiveTab {
  WOComponent  *plugin;
  NSDictionary *info;
  NSString *s;

  if ((plugin = [self->tabComponentCache objectForKey:self->activeTabKey]))
    return plugin;
  
  info = [docViewerPlugins objectForKey:self->activeTabKey];
  s    = [info objectForKey:@"component"];
  
  if ((plugin = [self pageWithName:s]) == nil) {
    [self errorWithFormat:@"did not find component: '%@'", s];
    return nil;
  }
  
  if (tabComponentCache == nil)
    tabComponentCache = [[NSMutableDictionary alloc] initWithCapacity:7];
  [tabComponentCache setObject:plugin forKey:self->activeTabKey];
  return plugin;
}

- (BOOL)showActiveTabKey {
  // check configured permissions etc
  return YES;
}

@end /* SkyProject4DocumentViewer */
