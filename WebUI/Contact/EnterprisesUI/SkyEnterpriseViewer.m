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

#include <OGoFoundation/LSWViewerPage.h>

@class NSMutableDictionary, NSString, NSArray, EOArrayDataSource;

// TODO: this components still contains a LOT of document related code
//       which is unused. This needs to be extracted with care, as we
//       still seem to support 'overview' projects?

@interface SkyEnterpriseViewer : LSWViewerPage
{
@protected
  id       item;          // non-retained
  id       fakeProject;

  NSArray  *docs;
  id       doc;           // non-retained
  id       docFolder;
  id       subFolder;  
  id       rootDocument;
  id       indexDocument;
  id       externalDoc;
  unsigned navItemIndex;

  BOOL     fetchCurrentFolder;

  NSString *urlPrefix;
  
  // for tab view
  NSString *tabKey;

  BOOL newObjectLinkEnterprise;
  id   newObjectLinkEnterpriseObj;

  BOOL isProjectEnabled;
  BOOL isInConfigMode;
}

@end /* SkyEnterpriseViewer */

#include "common.h"
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <EOControl/EOArrayDataSource.h>
#include <NGMime/NGMimeType.h>
#include <OGoContacts/SkyAddressConverterDataSource.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>

@interface NSObject(SkyEnterpriseViewer)
- (void)setParentFolder:(id)_parent;
@end
 
@interface SkyEnterpriseViewer(PrivateMethods)
- (NSDictionary *)_idDict;
@end

@implementation SkyEnterpriseViewer

static inline void _newObjectLinkEnterprise(SkyEnterpriseViewer *self);
static int compareDocumentEntries(id document1, id document2, void *context);

static NSArray *accessChecks = nil;

+ (void)initialize {
  if (accessChecks == nil)
    accessChecks = [[NSArray alloc] initWithObjects:@"r", @"w", nil];
}

- (id)init {
  if ((self = [super init]) != nil) {
    NGBundleManager *bm = nil;

    bm = [NGBundleManager defaultBundleManager];

    if ([bm bundleProvidingResource:@"SkyProject4Desktop"
            ofType:@"WOComponents"] != nil)
      self->isProjectEnabled = YES;

    self->urlPrefix = [[[self context] urlSessionPrefix]
                              copyWithZone:[self zone]];

    [self registerForNotificationNamed:LSWUpdatedEnterpriseNotificationName];
    
    [self registerForNotificationNamed:LSWNewFolderNotificationName];
    [self registerForNotificationNamed:LSWUpdatedFolderNotificationName];

    [self registerForNotificationNamed:LSWNewDocumentNotificationName];
    [self registerForNotificationNamed:LSWUpdatedDocumentNotificationName];
    [self registerForNotificationNamed:LSWDeletedDocumentNotificationName];
    [self registerForNotificationNamed:LSWMovedDocumentNotificationName];
    
    [self registerForNotificationNamed:LSWNewObjectLinkNotificationName];
    [self registerForNotificationNamed:LSWUpdatedObjectLinkNotificationName];
    [self registerForNotificationNamed:LSWDeletedObjectLinkNotificationName];
    
    [self registerForNotificationNamed:LSWNewTextDocumentNotificationName];
    [self registerForNotificationNamed:LSWUpdatedTextDocumentNotificationName];
    [self registerForNotificationNamed:LSWDeletedTextDocumentNotificationName];
    [self registerForNotificationNamed:
          LSWNewObjectLinkEnterpriseNotificationName];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->rootDocument  release];
  [self->indexDocument release];
  [self->docs          release];
  [self->docFolder     release];
  [self->subFolder     release];  
  [self->externalDoc   release];
  [self->fakeProject   release];
  [self->tabKey        release];
  [self->urlPrefix     release];
  [self->newObjectLinkEnterpriseObj release];
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (NSArray *)publicExtendedEnterpriseAttributes {
  return [[self userDefaults]
                arrayForKey:@"SkyPublicExtendedEnterpriseAttributes"];
}

- (NSArray *)privateExtendedEnterpriseAttributes {
  return [[self userDefaults] 
                arrayForKey:@"SkyPrivateExtendedEnterpriseAttributes"];
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  // TODO: split up, clean up
  [super noteChange:_cn onObject:_object];
  
  if ([_cn isEqualToString:LSWNewFolderNotificationName]) {
    self->fetchCurrentFolder = YES;
  }
  else if ([_cn isEqualToString:LSWUpdatedFolderNotificationName]) {
    // no action
  }

  else if ([_cn isEqualToString:LSWNewDocumentNotificationName]   ||
           [_cn isEqualToString:LSWNewObjectLinkNotificationName] ||
           [_cn isEqualToString:LSWNewTextDocumentNotificationName]) {
    self->fetchCurrentFolder = YES;
  }
  else if ([_cn isEqualToString:LSWUpdatedDocumentNotificationName]   ||
           [_cn isEqualToString:LSWUpdatedObjectLinkNotificationName] ||
           [_cn isEqualToString:LSWUpdatedTextDocumentNotificationName]) {
    id obj = nil;
  
    if ([[[_object entity] name]
                          isEqualToString:@"DocumentEditing"]) {
      obj = [_object valueForKey:@"toDoc"];

      [obj run:@"doc::get-current-owner",
           @"relationKey", @"currentOwner", nil];
    }
    else {
      obj = _object;
      [obj run:@"doc::get-current-owner",
           @"relationKey", @"currentOwner", nil];
    }
    {
      NSTimeZone     *tz = [[self session] timeZone];
      NSCalendarDate *cD = [obj valueForKey:@"creationDate"];
      NSCalendarDate *rD = [obj valueForKey:@"lastmodifiedDate"];

      if (cD != nil) [cD setTimeZone:tz];
      if (rD != nil) [rD setTimeZone:tz];
    }
  }
  else if ([_cn isEqualToString:LSWDeletedDocumentNotificationName]   ||
           [_cn isEqualToString:LSWDeletedObjectLinkNotificationName] ||
           [_cn isEqualToString:LSWDeletedTextDocumentNotificationName]) {
    self->fetchCurrentFolder = YES;
  }
  else if ([_cn isEqualToString:LSWMovedDocumentNotificationName]) {
    id obj = _object;
    id f   = nil;
  
    [self runCommand:@"doc::get",
            @"documentId", [obj valueForKey:@"documentId"], nil];

    f = [obj valueForKey:@"toParentDocument"];
    ASSIGN(self->docFolder, f);
    self->fetchCurrentFolder = YES;
  }
  else if ([_cn isEqualToString:LSWNewObjectLinkEnterpriseNotificationName]) {
    ASSIGN(self->newObjectLinkEnterpriseObj, _object);
    self->newObjectLinkEnterprise = YES;
    
  }
}

/* misc */

- (void)_fetchCurrentOwnersAndHandleAttachments {
  int i, cnt = [self->docs count];

  for (i = 0; i < cnt; i++) {
    id             myDoc = [self->docs objectAtIndex:i];
    NSTimeZone     *tz   = [[self session] timeZone];
    NSCalendarDate *cD   = [myDoc valueForKey:@"creationDate"];
    NSCalendarDate *rD   = [myDoc valueForKey:@"lastmodifiedDate"];

    if (cD != nil) [cD setTimeZone:tz];
    if (rD != nil) [rD setTimeZone:tz];
  }
  
  [self runCommand:@"doc::get-current-owner",
          @"objects",     self->docs,
          @"relationKey", @"currentOwner", nil];

  [self runCommand:@"doc::get-attachment-name", @"documents", self->docs, nil];
}

- (void)_fetchCurrentFolder {
  id d = nil;
  
  [self runCommand:@"doc::get",
        @"documentId", [self->docFolder valueForKey:@"documentId"], nil];

  d = [self->docFolder valueForKey:@"toDoc"];
  d = [d sortedArrayUsingFunction:compareDocumentEntries context:self];
  ASSIGN(self->docs, d);

  [self _fetchCurrentOwnersAndHandleAttachments];
}

- (void)_fetchFakeProject {
  id obj = [self object];

  obj = [obj globalID];
  obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
  obj = [obj lastObject];
  [self->fakeProject release]; self->fakeProject = nil;
  self->fakeProject = [[obj run:@"enterprise::get-fake-project", nil] retain];
  
  /* get documents */
  
  if (self->fakeProject == nil)
    return;
  
  if (self->rootDocument == nil) {
      [self->fakeProject run:@"project::get-root-document",
                         @"relationKey", @"rootDocument", nil];
      self->rootDocument =
        [[self->fakeProject valueForKey:@"rootDocument"] retain];
      
      ASSIGN(self->docFolder, self->rootDocument);
  }

  [self->indexDocument release]; self->indexDocument = nil;
  [self->fakeProject run:@"project::get-index-document",
                       @"relationKey", @"indexDocument", nil];
  self->indexDocument = 
    [[self->fakeProject valueForKey:@"indexDocument"] retain];
    
  [self runCommand:@"doc::get-attachment-name",
          @"document", self->indexDocument, nil];

  [self _fetchCurrentFolder];
}

- (LSCommandContext *)commandContext {
  return [[self session] commandContext];
}

- (void)_fetchDoc {
  id             obj;
  NSTimeZone     *tz;
  NSCalendarDate *cD = nil;
  NSCalendarDate *lD = nil;
  
  if (self->doc == nil) /* hm, is this correct? */
    return;
  
  obj = self->doc;
  tz  = [[self session] timeZone];

  [self runCommand:@"doc::get",
            @"documentId",
            [obj valueForKey:@"documentId"], nil];
  
  cD = [obj valueForKey:@"creationDate"];
  lD = [obj valueForKey:@"lastmodifiedDate"];
  if (cD != nil) [cD setTimeZone:tz];
  if (lD != nil) [lD setTimeZone:tz];
  
  [obj run:@"doc::get-attachment-name", nil];
  [obj run:@"doc::get-current-owner", @"relationKey", @"currentOwner", nil];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id sn, tb, obj;
  
  if (![super prepareForActivationCommand:_command type:_type
              configuration:_cmdCfg])
    return NO;

  if ((obj = [self object]) == nil)
    return NO;
    
  if (![obj isKindOfClass:[SkyEnterpriseDocument class]]) {
      id ctx;

      if ([obj isKindOfClass:[EOGlobalID class]]) {
        obj = [[self runCommand:@"enterprise::get-by-globalid",
                     @"gid", obj, nil] lastObject];
      }
      ctx = [self commandContext];
      obj = [[SkyEnterpriseDocument alloc] initWithEO:obj context:ctx];
      [self setObject:obj];
      [obj release];
  }
    
  sn  = [self session];
  tb  = [[sn userDefaults] objectForKey:@"enterprise_sub_view"]; 
    
  self->tabKey = (tb != nil) ? [tb copy] : (id)@"documents";

  if ([self->tabKey isEqualToString:@"overview"])
    [self _fetchFakeProject];
  if ([self->tabKey isEqualToString:@"documents"])
    [self _fetchFakeProject];
  
  return YES;
}

- (void)prepareWithDoc:(id)_doc {
  [self _fetchFakeProject];

  if ([[_doc valueForKey:@"isFolder"] boolValue]) {
    ASSIGN(self->docFolder, _doc);
  }
  else {
    id pd = [_doc valueForKey:@"toParentDocument"];
    ASSIGN(self->docFolder, pd);
  }
  ASSIGN(self->externalDoc, _doc);
  [self _fetchCurrentFolder];
  self->tabKey = @"documents";
}

/* accessors */

- (void)setIsInConfigMode:(BOOL)_flag {
  self->isInConfigMode = _flag ? 1 : 0;
}
- (BOOL)isInConfigMode {
  return self->isInConfigMode ? YES : NO;
}

- (void)setRootDocument:(id)_rootDocument {
  ASSIGN(self->rootDocument, _rootDocument);
}
- (id)rootDocument {
  return self->rootDocument;
}

- (void)setIndexDocument:(id)_indexDocument {
  ASSIGN(self->indexDocument, _indexDocument);
}
- (id)indexDocument {
  return self->indexDocument;
}

- (void)setDocFolder:(id)_docFolder {
  ASSIGN(self->docFolder, _docFolder);
}
- (id)docFolder {
  return self->docFolder;
}

- (void)setSubFolder:(id)_subFolder {
  ASSIGN(self->subFolder, _subFolder);
}
- (id)subFolder {
  return self->subFolder;
}

- (void)setDocs:(NSArray *)_docs {
  ASSIGN(self->docs, _docs);
}
- (NSArray *)docs {
  return self->docs;
}

- (void)setDoc:(id)_doc {
  self->doc = _doc;
}
- (id)doc {
  return self->doc;
}

- (void)setNavItemIndex:(unsigned)_idx {
  self->navItemIndex = _idx;
}
- (unsigned)navItemIndex {
  return self->navItemIndex;
}

- (void)setExternalDoc:(id)_doc {
  ASSIGN(self->externalDoc, _doc);
}
- (id)externalDoc {
  return self->externalDoc;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setFakeProject:(id)_fakeProject {
  ASSIGN(self->fakeProject, _fakeProject);
}
- (id)fakeProject {
  return self->fakeProject;
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
  [[[self session] userDefaults] setObject:_key forKey:@"enterprise_sub_view"];
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (id)enterprise {
  return [self object];
}

- (BOOL)isEditDisabled {
  return ![[[self commandContext] accessManager]
                   operation:@"w" allowedOnObjectID:
                   [[self object] valueForKey:@"globalID"]];
}
- (BOOL)isEditEnabled {
  return ![self isEditDisabled];
}

- (BOOL)isProjectEnabled {
  return self->isProjectEnabled;
}

- (BOOL)isLogTabEnabled {
  return YES;
}
- (BOOL)isLinkTabEnabled {
  return YES;
}

- (BOOL)hasDocs {
  return ([self->tabKey isEqualToString:@"documents"] && (self->fakeProject));
}

- (NSString *)objectUrlKey {
  return [@"x/activate?oid=" stringByAppendingString:
	     [[[self object] valueForKey:@"companyId"] stringValue]];
}

- (NSString *)indexDocContent {
  NSString *fileName = [self->indexDocument valueForKey:@"attachmentName"];
  return fileName ? [NSString stringWithContentsOfFile:fileName] : nil;
}

- (NSString *)indexDocTitle {
  id       obj       = self->indexDocument;
  NSString *fileName = [obj valueForKey:@"title"];
  NSString *fileType = [obj valueForKey:@"fileType"];

  return [NSString stringWithFormat:@"%@.%@", fileName, fileType];
}

- (NSString *)viewerTitle {
  NSMutableString *str;
  id eo;

  str = [NSMutableString stringWithCapacity:128];
  eo  = [self enterprise];

  /* the name of the enterprise */
  [str appendString:[[eo valueForKey:@"name"] stringValue]];

  /* add private info */
  if ([[eo valueForKey:@"isPrivate"] boolValue]) {
    [str appendString:@" ("];
    [str appendString:[[self labels] valueForKey:@"private"]];
    [str appendString:@")"];
  }

  /* add read-only info */
  if ([[eo valueForKey:@"isReadonly"] boolValue]) {
    [str appendString:@" ("];
    [str appendString:[[self labels] valueForKey:@"readonly"]];
    [str appendString:@")"];
  }
  return str;
}

- (NSString *)privateLabel {
  NSString *l = [[self labels] valueForKey:@"privateLabel"];

  return (l != nil) ? l : (NSString *)@"private";
}

- (NSString *)checkKeyName {
  return @"isDocumentChecked";
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->newObjectLinkEnterprise) {
    _newObjectLinkEnterprise(self);
    self->newObjectLinkEnterprise = NO;
  }
  if (self->fetchCurrentFolder) {
    [self _fetchCurrentFolder];
    self->fetchCurrentFolder = NO;
  }
}

/* actions */

- (id)viewDocuments {
  [self _fetchFakeProject];
  return nil;
}

- (id)viewOverview {
  [self _fetchFakeProject];
  return nil;
}

- (id)showColumnConfigEditor {
  [self setIsInConfigMode:YES];
  return nil; /* start on page */
}

- (id)assignPerson {
  WOSession   *sn = [self session];
  WOComponent *ct;
  NGMimeType  *mt;
  
  [sn transferObject:[self object] owner:self];
  mt = [NGMimeType mimeType:@"objc" subType:@"SkyEnterpriseDocument"];
  ct = [sn instantiateComponentForCommand:@"assignPerson" type:mt];
  [self enterPage:(id)ct];
  return nil;
}

- (BOOL)isIndexDocEditDisabled {
  BOOL     isEnabled;
  id       account, obj, editing;
  NSNumber *accountId;
  NSString *status;
  
  account   = [[self session] activeAccount];
  accountId = [account valueForKey:@"companyId"];
  obj       = self->indexDocument;  
  status    = [obj valueForKey:@"status"];
  editing   = [obj valueForKey:@"toDocumentEditing"];

  isEnabled = ([status isEqualToString:@"released"] ||
               ([status isEqualToString:@"edited"] &&
                [accountId isEqual:[obj valueForKey:@"currentOwnerId"]] &&
                [accountId isEqual:[editing valueForKey:@"currentOwnerId"]]));

  return !isEnabled;
}

- (BOOL)_transferFakeFMDocument {
  // TODO: rewrite to just return the fake-fm
  Class pClass;
  id ctx, pgid, fm, d;
  
  ctx  = [self commandContext];
  pgid = [[self fakeProject] globalID];

  if ((pClass = NSClassFromString(@"SkyProjectFileManager")) == nil) {
    [self logWithFormat:
            @"WARNING[%s] couldn`t found SkyProjectFileManager class",
            __PRETTY_FUNCTION__];
    return NO;
  }

  fm = [[pClass alloc] initWithContext:ctx projectGlobalID:pgid];
  d  = [fm pathForGlobalID:[self->indexDocument globalID]];
  d  = [[(id)[fm documentAtPath:d] retain] autorelease];
  [fm release];
  
  [[self session] transferObject:d owner:self];
  
  return YES;
}

- (id)viewIndexDocument {
  if (self->indexDocument == nil) 
    return nil;
  
  // get a SkyProjectDocument
  // TODO: use activate?
  if ([self _transferFakeFMDocument])
    [self executePasteboardCommand:@"view"];
  
  return nil;
}

- (id)editIndexDocument {
  if (self->indexDocument) {
    if ([self _transferFakeFMDocument])
      [self executePasteboardCommand:@"edit"];
  }
  else {
    [self setErrorString:@"No object available for edit operation."];
  }
  return nil;
}

static int compareDocumentEntries(id document1, id document2, void *context) {
  BOOL doc1IsFolder     = [[document1 valueForKey:@"isFolder"] boolValue];
  BOOL doc2IsFolder     = [[document2 valueForKey:@"isFolder"] boolValue];
  BOOL doc1IsObjectLink = [[document1 valueForKey:@"isObjectLink"] boolValue];
  BOOL doc2IsObjectLink = [[document2 valueForKey:@"isObjectLink"] boolValue];
  NSString *title1      = [document1 valueForKey:@"title"];
  NSString *title2      = [document2 valueForKey:@"title"];
    
  if (doc1IsFolder != doc2IsFolder)
    return doc1IsFolder ? -1 : 1;
  
  if (doc1IsObjectLink != doc2IsObjectLink)
    return doc1IsObjectLink ? 1 : -1;
  
  if (title1 == nil)
    title1 = @"";
  if (title2 == nil)
    title2 = @"";
  
  return [title1 compare:title2];
}

- (void)_newObjectLinkEnterprise {
  NSDictionary        *obj;
  id                  accountId  = nil;
  NSMutableDictionary *objLink   = nil;

  obj       = self->newObjectLinkEnterpriseObj;
  accountId = [[[self session] activeAccount] valueForKey:@"companyId"];
  
  objLink = [[NSMutableDictionary alloc] initWithCapacity:16];
  [objLink setObject:[obj objectForKey:@"LinkUrl"]   forKey:@"objectLink"];
  [objLink setObject:[obj objectForKey:@"LinkTitle"] forKey:@"title"]; 
  [objLink setObject:[obj objectForKey:@"fileType"]  forKey:@"fileType"];
  [objLink setObject:accountId                       forKey:@"firstOwnerId"];
  [objLink setObject:accountId                       forKey:@"currentOwnerId"];
  [objLink setObject:[NSNumber numberWithBool:YES]   forKey:@"isObjectLink"];
  [objLink setObject:[NSNumber numberWithBool:NO]    forKey:@"isFolder"];
  [objLink setObject:self->docFolder                 forKey:@"folder"];
  [objLink setObject:self->fakeProject               forKey:@"project"];
  
  [self runCommand:@"doc::new" arguments:objLink];
  self->fetchCurrentFolder = YES;
}
static inline void _newObjectLinkEnterprise(SkyEnterpriseViewer *self) {
  [self _newObjectLinkEnterprise];
}

- (id)formLetterTarget {
  return [[self context] contextID];
}

- (NSArray *)_selectedDocuments {
  NSEnumerator   *docEnum;
  NSMutableArray *docList;
  NSString       *keyName;
  id             myDoc;

  docEnum  = [self->docs objectEnumerator];
  docList  = [NSMutableArray arrayWithCapacity:16];
  keyName  = [self checkKeyName];
  
  while ((myDoc = [docEnum nextObject]) != nil) {
    if ([[myDoc valueForKey:keyName] boolValue]) {
      [myDoc takeValue:[NSNumber numberWithBool:NO] forKey:keyName];
      [docList addObject:myDoc];
    }
  }
  return docList;
}

- (NSDictionary *)_idDict {
  NSMutableDictionary *result;
  NSNumber            *compId;
  
  result = [NSMutableDictionary dictionaryWithCapacity:2];
  compId = [[self object] valueForKey:@"companyId"];
  [result setObject:compId                 forKey:@"companyId"];
  [result setObject:[[self object] entity] forKey:@"entity"];
  
  return result;
}

- (NSArray *)accessChecks {
  return accessChecks;
}

- (BOOL)isAccessRightEnabled {
  // TODO: deprecated
  return YES;
}

- (id)editAccess {
  WOComponent *page;
  
  if ([self isAccessRightEnabled]) {  
    if ((page = [self pageWithName:@"SkyCompanyAccessEditor"])) {
      [page takeValue:[[self enterprise] globalID] forKey:@"globalID"];
      [page takeValue:[self accessChecks] forKey:@"accessChecks"];
      return page;
    }
  }
  [self setErrorString:@"could not find access editor !"];
  return nil;
}

- (id)accessIds {
  return [[[self commandContext] accessManager]
                 allowedOperationsForObjectId:[[self enterprise] globalID]];
}

@end /* SkyEnterpriseViewer */
