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

#include <OGoFoundation/LSWViewerPage.h>

@class NSArray, NSString, NSMutableArray, NSMutableString;

@interface LSWDocumentViewer : LSWViewerPage
{
@private
  NSArray         *versions;
  NSString        *tabKey;
  NSString        *documentPath;
  id              version;
  id              editing;
  BOOL            fetchVersions;
  BOOL            documentMove;
  id              item;
  NSMutableArray  *folders;  
  NSMutableString *fileName;
  unsigned        folderIndex;

  NSDictionary    *properties;
  id              property;
  
  /* cache */
  id inlineViewer;
}

- (NSString *)inlineContentUrl;

@end

#include "common.h"

@interface NSObject(Private)
- (id)globalID;
- (id)commandContext;
@end

@interface LSWDocumentViewer(PrivateMethods)
- (BOOL)isEditEnabled;
@end

@implementation LSWDocumentViewer

static NSNumber   *yesNum = nil;
static NSNumber   *noNum  = nil;
static NGMimeType *gidPropType = nil;

+ (int)version {
  return 2;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
	    @"invalid superclass (%@) version %i !",
	    NSStringFromClass([self superclass]), [super version]);

  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];

  gidPropType = [[NGMimeType mimeType:@"gid" subType:@"property"] retain];
}

- (NSTimeZone *)timeZone {
  return [(OGoSession *)[self session] timeZone];
}

/* operations */

static int compareDocumentVersions(id version1, id version2, void *context) {
  NSNumber *no1 = [version1 valueForKey:@"version"];
  NSNumber *no2 = [version2 valueForKey:@"version"];
  return [no2 compare:no1];
}

- (void)_handleEditingAttachment {
  [self runCommand:@"documentediting::get-attachment-name",
          @"documentEditing", self->editing, nil];
  [self->editing run:@"documentediting::get-current-owner",
                   @"relationKey", @"currentOwner", nil];
}

- (void)_fetchVersions {
  NSTimeZone     *tz;
  NSCalendarDate *cD, *rD;
  id obj;
  id docId;
  id myVersions  = nil;
  
  if ([self object] == nil)
    return;

  tz    = [(OGoSession *)[self session] timeZone];
  obj   = [self object];
  docId = [obj valueForKey:@"documentId"];
    
  NSAssert(obj,   @"missing object");
  NSAssert1(docId, @"missing docId in object %@", obj);
    
  [self runCommand:@"doc::get", @"documentId", docId, nil];
    
  myVersions = [obj valueForKey:@"toDocumentVersion"];
    
  cD = [obj valueForKey:@"creationDate"];
  rD = [obj valueForKey:@"lastmodifiedDate"];    
  [cD setTimeZone:tz];
  [rD setTimeZone:tz];
    
  [self->versions release]; self->versions = nil;
  self->versions = [myVersions mutableCopy];

  [[self->versions mappedArrayUsingSelector:@selector(objectForKey:)
                   withObject:@"archiveDate"]
                   makeObjectsPerformSelector:@selector(setTimeZone:)
                   withObject:tz];

  [(NSMutableArray *)self->versions sortUsingFunction:compareDocumentVersions
		                    context:self];

  NSAssert(self->versions, @"missing versions");
    
  [self runCommand:@"documentVersion::get-last-owner",
            @"objects",     self->versions,
            @"relationKey", @"lastOwner", nil];
  [self runCommand:@"documentversion::get-attachment-name",
            @"documentVersions", self->versions, nil];
}

- (void)_fetchDoc {
  id             obj;
  NSTimeZone     *tz;
  NSCalendarDate *cD, *lD;

  if ([self object] == nil)
    return;
  
  obj = [self object];
  
  [self runCommand:@"doc::get",
            @"documentId",
            [obj valueForKey:@"documentId"], nil];
  
  tz = [self timeZone];
  cD = [obj valueForKey:@"creationDate"];
  lD = [obj valueForKey:@"lastmodifiedDate"];
  [cD setTimeZone:tz];
  [lD setTimeZone:tz];

  [self runCommand:@"doc::get-attachment-name", @"document", obj, nil];
  [obj run:@"doc::get-current-owner", @"relationKey", @"currentOwner", nil];
}

- (void)_fetchEditing {
  NSTimeZone     *tz;
  NSCalendarDate *cD;
  
  if ([self object] == nil)
    return;
  
  tz = [self timeZone];

  [self runCommand:@"documentediting::get",
            @"documentEditingId",
            [self->editing valueForKey:@"documentEditingId"], nil];
    
  cD = [self->editing valueForKey:@"checkoutDate"];
  [cD setTimeZone:tz];
  
  [self _handleEditingAttachment];
}

- (void)_setDocumentPath {
  id             obj  = [self object];
  NSMutableArray *f  = [NSMutableArray arrayWithCapacity:5];
  id             pFolder;
  NSString *tmp;

  [self runCommand:@"doc::get",
        @"documentId", [obj valueForKey:@"documentId"], nil];

  pFolder = [obj valueForKey:@"toParentDocument"];
  
  [self->folders release]; self->folders = nil;
  
  self->folders = [[NSMutableArray alloc] initWithCapacity:16];
  
  while ([pFolder isNotNull]) {
    [self->folders insertObject:pFolder atIndex:0];
    [f insertObject:[pFolder valueForKey:@"title"] atIndex:0];
    pFolder = [pFolder valueForKey:@"toParentDocument"];
  }

  [self->fileName release]; self->fileName = nil;
  self->fileName = [[obj valueForKey:@"title"] mutableCopy];
  [self->fileName appendString:@"."];
  [self->fileName appendString:[obj valueForKey:@"fileType"]];
  
  [f addObject:[obj valueForKey:@"title"]];
  tmp = [f componentsJoinedByString:@" / "];
  tmp = [tmp stringByAppendingString:@"."];
  tmp = [tmp stringByAppendingString:[obj valueForKey:@"fileType"]];
  self->documentPath = [tmp copy];
}

- (id)init {
  if ((self = [super init])) {
    self->tabKey = @"contents";

    [self registerForNotificationNamed:LSWUpdatedDocumentNotificationName];
    [self registerForNotificationNamed:LSWUpdatedTextDocumentNotificationName];
    [self registerForNotificationNamed:LSWMovedDocumentNotificationName];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->inlineViewer release];
  [self->versions     release];
  [self->tabKey       release];
  [self->documentPath release];
  [self->editing      release];
  [self->folders      release];
  [self->item         release];
  [self->fileName     release];
  [self->property     release];
  [self->properties   release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command 
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id             obj;
  NSTimeZone     *tz;
  NSCalendarDate *cD;
  
  if (![super prepareForActivationCommand:_command type:_type
              configuration:_cmdCfg])
    return NO;
    
  obj = [self object];
    
  if ([[_type type] isEqualToString:@"eo-gid"]) {
    EOGlobalID *gid;
      
    if (![[_type subType] isEqualToString:@"doc"])
      return NO;
      
    gid = obj;
    obj = [[self run:@"doc::get", @"gid", gid, nil] lastObject];
    [self setObject:obj];
  }
    
  if (obj == nil) {
    [self logWithFormat:@"Note: no document for viewer!"];
    return NO;
  }
    
  tz = [self timeZone];
  // editing

  self->editing = [[obj valueForKey:@"toDocumentEditing"] retain];
      
  cD = [self->editing valueForKey:@"checkoutDate"];
  [cD setTimeZone:tz];

  [self _handleEditingAttachment];
  [self _setDocumentPath];
  return YES;
}

/* notifications */

- (void)sleep {
#if 0
  [self->inlineViewer release]; self->inlineViewer = nil;
#endif
  [self->properties release]; self->properties = nil;
  [self->property release];   self->property   = nil;
  [super sleep];
}

- (void)syncAwake {
  [super syncAwake];
  
  if ([self object] != nil) {
    id document = [self object];
    id owner    = nil;

    owner = [document valueForKey:@"toFirstOwner"];
    owner = [owner valueForKey:@"toPerson"];
    [document takeValue:owner forKey:@"firstOwner"];
  }
  if (self->fetchVersions) {
    [self _setDocumentPath];
    [self _fetchVersions];
    [self _fetchEditing];
    self->fetchVersions = NO;
  }
  if (self->documentMove) {
    [self _setDocumentPath];
    self->documentMove = NO;
  }
  [self->properties release]; self->properties = nil;
  [self->property   release]; self->property   = nil;
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWUpdatedDocumentNotificationName] ||
      [_cn isEqualToString:LSWUpdatedTextDocumentNotificationName]) {
    self->fetchVersions = YES;
  }
  else if ([_cn isEqualToString:LSWMovedDocumentNotificationName]) {
    self->documentMove = YES;
  }
}

/* accessors */

- (id)document {
  return [self object];
}
- (id)editing {
  return self->editing;
}

- (void)setVersion:(id)_version {
  self->version = _version;
}
- (id)version {
  return self->version;
}

- (NSString *)_downloadAction:(NSString *)_name forDocument:(id)_doc {
  return [NSString stringWithFormat:@"%@/%@.%@",
		   _name,
                   [[_doc valueForKey:@"title"]    stringByEscapingURL],
                   [[_doc valueForKey:@"fileType"] stringByEscapingURL]];
}

- (NSString *)downloadDirectActionName {
  return [self _downloadAction:@"get" forDocument:[self document]];
}
- (NSString *)downloadEditingDirectActionName {
  return [self _downloadAction:@"getEditing" forDocument:[self editing]];
}
- (NSString *)downloadVersionDirectActionName {
  return [self _downloadAction:@"getVersion" forDocument:[self version]];
}

- (NSArray *)versions {
  return self->versions;
}

- (void)setTabKey:(NSString *)_key {
  ASSIGNCOPY(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (NSString *)_gifForDocEO:(id)_doc {
  NSString *fileType;
  id cfg;
  
  fileType = [_doc valueForKey:@"fileType"];
  cfg      = [[self config] valueForKey:@"icons"];
  
  if (fileType == nil)
    fileType = @"";
  
  if ([[[cfg valueForKey:@"download"] allKeys] containsObject:fileType])
    return [[cfg valueForKey:@"download"] valueForKey:fileType];
  
  return [cfg valueForKey:@"unknown"];
}
- (NSString *)_labelForDocEO:(id)_doc {
  NSString *fileType;
  
  fileType = [_doc valueForKey:@"fileType"];
  if (fileType == nil) fileType = @"unknown";
  return [[self labels] valueForKey:fileType];
}

- (NSString *)gifForEditingType {
  return [self _gifForDocEO:[self object]];
}
- (NSString *)gifForVersionType {
  return [self _gifForDocEO:self->version];
}

- (NSString *)labelForEditingType {
  return [self _labelForDocEO:[self object]];
}
- (NSString *)labelForVersionType {
  return [self _labelForDocEO:self->version];
}

- (NSString *)documentPath {
  return self->documentPath;
}

- (NSString *)docTitle {
  NSString *fn;
  NSString *ft;

  fn = [self->editing valueForKey:@"title"];
  ft = [self->editing valueForKey:@"fileType"];
  
  if (fn == nil || ft == nil)
    return @"";
  
  return [NSString stringWithFormat:@"%@.%@", fn, ft];
}

- (NSString *)versionTitle {
  id       obj;
  NSString *fn;
  NSString *ft;

  obj = self->version;
  fn = [obj valueForKey:@"title"];
  ft = [obj valueForKey:@"fileType"];
  return [NSString stringWithFormat:@"%@.%@", fn, ft];
}

- (NSString *)txtDocContent {
  NSString *fn;
  
  fn = [[self object] valueForKey:@"attachmentName"];
  return fn ? [NSString stringWithContentsOfFile:fn] : nil;
}

- (BOOL)isReleaseDisabled {
  BOOL isEnabled;
  id   sn, account, accountId, obj, status;

  if (![self isEditEnabled])
    return YES;
  
  sn        = [self session];
  account   = [sn activeAccount];
  accountId = [account valueForKey:@"companyId"];
  obj       = [self object];  
  status    = [obj valueForKey:@"status"];
  
  isEnabled = (([accountId isEqual:
                           [self->editing valueForKey:@"currentOwnerId"]]
                || [sn activeAccountIsRoot])
               && ![status isEqualToString:@"released"]);

  return !isEnabled;
}
- (BOOL)isReleaseEnabled {
  return [self isReleaseDisabled] ? NO : YES;
}

- (BOOL)isRejectDisabled {
  // TODO: almost a DUP to isReleaseDisabled!
  BOOL       isEnabled;
  OGoSession *sn;
  id       account, obj;
  NSNumber *accountId;
  NSString *status;

  if (![self isEditEnabled])
    return YES;
  
  sn        = [self session];
  account   = [sn activeAccount];
  accountId = [account valueForKey:@"companyId"];
  obj       = [self object];  
  status    = [obj valueForKey:@"status"];

  isEnabled = 
    (([accountId isEqual:[self->editing valueForKey:@"currentOwnerId"]]
      || [sn activeAccountIsRoot])
     && [status isEqualToString:@"edited"]);
  
  return !isEnabled;
}
- (BOOL)isRejectEnabled {
  return [self isRejectDisabled] ? NO : YES;
}

- (BOOL)isEditDisabled {
  BOOL isEnabled;
  OGoSession *sn;
  id       account;
  NSNumber *accountId;
  id       obj;
  NSString *status;
  
  sn        = [self session];
  account   = [sn activeAccount];
  accountId = [account valueForKey:@"companyId"];
  obj       = [self object];  
  status    = [obj valueForKey:@"status"];

  isEnabled = ([status isEqualToString:@"edited"] &&
               (([accountId isEqual:
                          [self->editing valueForKey:@"currentOwnerId"]]) ||
                ([sn activeAccountIsRoot])));

  return !isEnabled;
}
- (BOOL)isEditEnabled {
  return [self isEditDisabled] ? NO : YES;
}

- (BOOL)isCheckoutEnabled {
  return ([[[self object] valueForKey:@"status"] isEqualToString:@"released"]);
}
- (BOOL)isReleased {
  id document;
  id status;

  document = [self valueForKey:@"document"];
  status   = [document valueForKey:@"status"];
  return [status isEqualToString:@"released"];
}

- (BOOL)isDeleteDisabled {
  BOOL       isEnabled;
  OGoSession *sn;
  id         myAccount;
  NSNumber   *accountId;
  id         obj;

  if ([[[self object] valueForKey:@"isIndexDoc"] boolValue])
    return YES;

  sn        = [self session];
  myAccount = [sn activeAccount];
  accountId = [myAccount valueForKey:@"companyId"];
  obj       = [self object];  
  
  isEnabled = (([accountId isEqual:[obj valueForKey:@"firstOwnerId"]]) ||
	       ([sn activeAccountIsRoot]));
  isEnabled = isEnabled && [self isCheckoutEnabled];

  return isEnabled ? NO : YES;
}
- (BOOL)isDeleteEnabled {
  return [self isDeleteDisabled] ? NO : YES;
}

- (BOOL)isMoveDisabled {
  // TODO: almost DUP to isDeleteDisabled
  BOOL isEnabled = NO;
  id   sn        = [self session];
  id   myAccount = [sn activeAccount];
  id   accountId = [myAccount valueForKey:@"companyId"];
  id   obj       = [self object];  
  
  if ([[[self object] valueForKey:@"isIndexDoc"] boolValue])
    return YES;
  
  isEnabled = (([accountId isEqual:[obj valueForKey:@"firstOwnerId"]]) ||
	       ([sn activeAccountIsRoot]));
    
  isEnabled = isEnabled && [self isCheckoutEnabled];
  
  return isEnabled ? NO : YES;
}
- (BOOL)isMoveEnabled {
  return [self isMoveDisabled] ? NO : YES;
}

- (BOOL)isTextEditDisabled {
  id value;

  if (![self isEditEnabled])
    return YES;

  value = [[self object] valueForKey:@"fileType"];
  
  return (value == nil) ? YES : ![value isEqualToString:@"txt"];
}
- (BOOL)isTextEditEnabled {
  return [self isTextEditDisabled] ? NO : YES;
}

- (BOOL)isContactAttrEnabled {
  return [[[self session] userDefaults]
                 boolForKey:@"SkyEnableContactAttrInDocuments"];
}

- (NSString *)versionAttachmentTarget {
  NSString *fileType;

  fileType = [self->version valueForKey:@"fileType"];
  return ([fileType isEqualToString:@"txt"]
          || [fileType isEqualToString:@"htm"]
          || [fileType isEqualToString:@"html"]
          || [fileType isEqualToString:@"gif"]
          || [fileType isEqualToString:@"jpg"])
    ? [[self->version valueForKey:@"documentId"] stringValue]
    : @"";
}

- (NSString *)attachmentTarget {
  // TODO: almost a DUP to versionAttachmentTarget
  NSString *fileType = [[self object] valueForKey:@"fileType"];

  return ([fileType isEqualToString:@"txt"]
          || [fileType isEqualToString:@"htm"]
          || [fileType isEqualToString:@"html"]
          || [fileType isEqualToString:@"gif"]
          || [fileType isEqualToString:@"jpg"])
    ? [[[self object] valueForKey:@"documentId"] stringValue]
    : @"";
}

- (BOOL)isVersionCheckedOut {
  return ([[self->editing valueForKey:@"version"]
            isEqual:[self->version valueForKey:@"version"]]) ? YES : NO; 
}

- (BOOL)isDocumentDownloadEnabled {
  BOOL isEnabled;
  id   obj       = [self object];
    
  isEnabled = ([[obj valueForKey:@"status"] isEqualToString:@"released"] ||
              ([[obj valueForKey:@"versionCount"] intValue] > 0 &&
               [[obj valueForKey:@"status"] isEqualToString:@"edited"]));

  return isEnabled;
}

- (NSString *)objectUrlKey {
  return [NSString stringWithFormat:
                     @"wa/activate?oid=%@",
                     [[self object] valueForKey:@"documentId"]];
}

- (NSCalendarDate *)checkoutDate {
  NSCalendarDate *cD = [editing valueForKey:@"checkoutDate"];
  return (cD == nil) ? nil : cD;
}

- (NSString *)currentEditor {
  id l = [[editing valueForKey:@"currentOwner"] valueForKey:@"login"];
  return [l isNotNull] ? l : @"";
}

/* actions */

- (id)edit {
  NSNumber *wRel;
  id   obj, edit;
  BOOL wasReleased;
  
  if ((obj = [self object]) == nil) {
    [self setErrorString:@"No object available for edit operation."];
    return nil;
  }
  edit        = self->editing;
  wasReleased = [[obj valueForKey:@"status"] isEqualToString:@"released"];
  wRel        = wasReleased ? yesNum : noNum;

  if (wasReleased) {
      [self runCommand:@"doc::checkout" object:obj];
      if (![self commit]) {
        [self rollback];
        [self setErrorString:@"Could not commit doc::checkout !"];
        return nil;
      }
  }
    
  [edit takeValue:noNum forKey:@"attrEdit"];
  [edit takeValue:wRel                         forKey:@"wasReleased"];
  [edit takeValue:obj                          forKey:@"toDoc"];
      
  [self runCommand:@"documentediting::get-attachment-name",
                     @"documentEditing", edit, nil];      

  return [self activateObject:edit withVerb:@"edit"];
}

- (id)editAttributes {
  // TODO: almost a DUP to -edit
  NSNumber *wRel;
  id   obj, edit;
  BOOL wasReleased;
  
  if ((obj = [self object]) == nil) {
    [self setErrorString:@"No object available for edit operation."];
    return nil;
  }

  edit        = self->editing;
  wasReleased = [[obj valueForKey:@"status"] isEqualToString:@"released"];
  wRel        = wasReleased ? yesNum : noNum;

  if (wasReleased) {
      [self runCommand:@"doc::checkout" object:obj];
      if (![self commit]) {
        [self rollback];
        [self setErrorString:@"Could not commit document checkout !"];
        return nil;
      }
  }

  [edit takeValue:yesNum forKey:@"attrEdit"];
  [edit takeValue:wRel                          forKey:@"wasReleased"];
  [edit takeValue:obj                           forKey:@"toDoc"];
      
  [self runCommand:@"documentediting::get-attachment-name",
                     @"documentEditing", edit, nil];      
  
  return [self activateObject:edit withVerb:@"edit"];
}

- (id)editTextDocument {
  // TODO: almost a DUP to -edit
  NSNumber *wRel;
  id   obj, edit;
  BOOL wasReleased;

  if ((obj = [self object]) == nil) {
    [self setErrorString:@"No object available for edit operation."];
    return nil;
  }

  edit        = self->editing;
  wasReleased = [[obj valueForKey:@"status"] isEqualToString:@"released"];
  wRel        = wasReleased ? yesNum : noNum;

  if (wasReleased) {
      [self runCommand:@"doc::checkout" object:obj];
      if (![self commit]) {
        [self rollback];
        [self setErrorString:@"Could not commit document checkout !"];
        return nil;
      }
  }

  [edit takeValue:noNum forKey:@"attrEdit"];
  [edit takeValue:wRel  forKey:@"wasReleased"];
  [edit takeValue:obj   forKey:@"toDoc"];

  [self runCommand:@"documentediting::get-attachment-name",
                     @"documentEditing", edit, nil];

  return [self activateObject:edit withVerb:@"editTextDocument"];
}

- (id)tabClicked {
  if ([self->tabKey isEqualToString:@"versions"]) {
    [self _fetchVersions];
    [self _fetchEditing];
  }
  else {
    [self _fetchDoc];
  }
  return nil;
}

- (id)releaseDocument {
  id result;

  result = [self runCommand:@"doc::release" object:[self object]];

  if (result) {
    if (![self commit]) {
      [self rollback];
      [self setErrorString:@"Could not commit document release !"];
      return nil;
    }
    
    [self postChange:LSWUpdatedDocumentNotificationName 
	  onObject:[self object]];
    [self _fetchVersions];
    [self _fetchDoc];
    [self _fetchEditing];
    [self _setDocumentPath];
  }
  return nil;
}

- (id)delete {
  [self setWarningOkAction:@"reallyDelete"];
  [self setWarningPhrase:@"Really Delete"];
  [self setIsInWarningMode:YES];

  return nil;
}

- (id)rejectDocument {
  id obj;
  id result;

  obj = [self object];
  if ([[obj valueForKey:@"versionCount"] intValue] == 0 &&
      [[obj valueForKey:@"status"] isEqualToString:@"edited"]) {
    return [self delete];
  }
  if ((result = [self runCommand:@"doc::reject" object:[self object]])) {
    if (![self commit]) {
      [self setErrorString:@"Could not reject document !"];
      [self rollback];
      return nil;
    }
    [self _fetchVersions];
    [self _fetchEditing];
  }
  return nil;
}

- (id)moveDocument {
  return [self activateObject:[self object] withVerb:@"move"];
}

- (id)mailDocument {
  id mailEditor = [[self application] pageWithName:@"LSWImapMailEditor"];

  if (mailEditor) {
    [mailEditor setSubject:@"Document"];
    [mailEditor addAttachment:[self object]
                type:[NGMimeType mimeType:@"eo/doc"]];
    [self enterPage:mailEditor];
  }
  return nil;
}

- (id)refresh {
  [self _fetchVersions];  
  [self _fetchEditing];
  [self _fetchDoc];
  return nil;
}

- (id)checkout {
  id obj    = nil;
  id result = nil;
  id tmp    = nil;
  
  [self runCommand:@"doc::get",
        @"documentId", [[self object] valueForKey:@"documentId"], nil];

  obj = [self object];
  
  if ([self isCheckoutEnabled]) {
    result = [self runCommand:@"doc::checkout" object:obj];
    if (result) {
      if (![self commit]) {
        [self rollback];
        [self setErrorString:@"Could not commit document checkout !"];
        return nil;
      }
    }
    else {
      tmp = [NSString stringWithString:[self errorString]];
      [self rollback];
    }
    [self _fetchEditing];
  }
  else {
    [self _fetchVersions];
    [self _fetchDoc];
    [self _fetchEditing];
  }

  if ([tmp length]) {
    [self setErrorString:[NSString stringWithFormat:@"%@ %@", tmp,
                           [self errorString] ? [self errorString] : @""]];
  }
  return nil;
}

- (id)checkoutVersion {
  id result     = nil;
  NSString *tmp = nil;

  [self runCommand:@"doc::get",
          @"documentId", [[self object] valueForKey:@"documentId"], nil];

  if ([self isCheckoutEnabled]) {
    result = [self runCommand:@"documentversion::checkout" 
		   object:self->version];
    if (result) {
      if (![self commit]) {
        [self setErrorString:@"Could not commit document-version checkout !"];
        [self rollback];
        return nil;
      }
    }
    else {
      [self rollback];
      tmp = [NSString stringWithString:[self errorString]];
    }

    [self _fetchEditing];
  }
  else {
    [self _fetchVersions];
    [self _fetchDoc];
    [self _fetchEditing];
  }

   if ([tmp length]) {
    [self setErrorString:[NSString stringWithFormat:@"%@ %@", tmp,
                           [self errorString] ? [self errorString] : @""]];
  }

  return nil;
}

- (id)reallyDelete {
  // TODO: cleanup
  id result = nil;

  if ([[[self object] valueForKey:@"status"] isEqualToString:@"released"]) {
    result = [self runCommand:@"doc::checkout" object:[self object]];

    if (result) {
      if (![self commit]) {
        [self setErrorString:@"Could not commit checkout !"];
        [self rollback];
        [self _fetchEditing];
        return nil;
      }
    }
  }
  
  [self setIsInWarningMode:NO];

  result = [[self object] run:@"doc::delete", @"reallyDelete", yesNum, nil];
  
  if (result) {
    if (![self commit]) {
      [self rollback];
      [self setErrorString:@"Could not commit document delete !"];
      return nil;
    }
    [self postChange:LSWDeletedDocumentNotificationName onObject:result];
    [self back];
  }
  return nil;
}

- (id)folderLink {
  id project = nil;

  project = [self runCommandInTransaction:@"project::get",
                  @"projectId",  [self->item valueForKey:@"projectId"],
                  @"returnType", intObj(LSDBReturnType_OneObject), nil];

  if ([(NSArray *)project count] == 1) {
    project = [project lastObject];
  }
  else {
    [self setErrorString:@"No project for document available."];
  }
  if (project != nil) {
    BOOL isFake = [[project valueForKey:@"isFake"] boolValue];

    if (isFake) {
      NSArray *eps = nil;
            
      [self runCommandInTransaction:@"project::get-enterprises",
            @"project", project, nil];
      eps = [project valueForKey:@"enterprises"];

      if ([eps count] > 0) {
        WOSession   *sn;
        id          ep;
        NGMimeType  *mt;
        WOComponent *ct = nil;

        sn = [self session];
        ep = [eps objectAtIndex:0];
        mt = [NGMimeType mimeType:@"eo" subType:@"enterprise"];
              
        [sn transferObject:ep owner:self];
        ct = [sn instantiateComponentForCommand:@"view" type:mt];
        [ct performSelector:@selector(prepareWithDoc:) withObject:self->item];
        [[self navigation] enterPage:(id)ct];
      }
    }
    else {
      NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"project"];
      WOComponent *ct = nil;

      [[self session] transferObject:project owner:self];
      ct = [[self session] instantiateComponentForCommand:@"view" type:mt];
      [ct performSelector:@selector(prepareWithDoc:) withObject:self->item];
      [[self navigation] enterPage:(id)ct];
    }
  }
  return nil;
}

- (BOOL)showContentInline {
  NSArray      *pluginEnabledBrowsers;
  NSEnumerator *e;
  NSString     *s;
  NSString     *browser;
  BOOL         doShow;
  
  doShow = [[[self session] userDefaults] boolForKey:@"LSPluginViewerEnabled"];
  if (!doShow)
    return NO;

  /*
      IE4.5/Mac:  'Mozilla/4.0 (compatible; MSIE 4.5; Mac_PowerPC)'
      IE5/Win:    'Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt)'
      NS4.61/Mac: 'Mozilla/4.61 (Macintosh; I; PPC)'
      NS4.61/Win: 'Mozilla/4.61 [en] (WinNT; I)'
  */

  pluginEnabledBrowsers =
    [[[self session] userDefaults] arrayForKey:@"LSPluginEnabledUserAgents"];
  
  if (!pluginEnabledBrowsers)
    return NO;
    
  if ((browser = [[[self context] request] headerForKey:@"user-agent"]) != nil)
    return NO;
  
  e = [pluginEnabledBrowsers objectEnumerator];
  while ((s = [e nextObject]) != nil) {
    NSRange r;
	  
    r = [browser rangeOfString:s];
    if (r.length > 0)
      return YES;
  }
  return NO;
}

- (BOOL)showAsEmbeddedObject {
  NSString *fileType;
  
#if 0
  if (![self showContentInline])
    return NO;
#endif
  
  fileType = [[self object] valueForKey:@"fileType"];
  if ([fileType isEqualToString:@"gif"] ||
      [fileType isEqualToString:@"jpg"] ||
      [fileType isEqualToString:@"jpeg"])
    return NO;
  
  return YES;
}

- (NSString *)inlineObjectMimeType {
  NSDictionary *mimeTypes;
  NSString     *fileType;
  
  fileType  = [[self object] valueForKey:@"fileType"];
  mimeTypes = [[[self session] userDefaults] dictionaryForKey:@"LSMimeTypes"];
  fileType  = [mimeTypes valueForKey:fileType];
  
  if (fileType == nil)
    fileType = @"application/octet-stream";
#if 0
  fileType = [fileType stringByAppendingString:@"; filename="];
  fileType = [fileType stringByAppendingString:self->fileName];
#endif
  
  return fileType;
}
- (NSData *)inlineObjectData {
  NSString *path;
  
  if ((path = [[self object] valueForKey:@"attachmentName"]))
    return [NSData dataWithContentsOfFile:path];
  
  return nil;
}

- (BOOL)isInlineViewerAvailable {
  NGMimeType *mimeType;
  
  if (self->inlineViewer)
    return YES;

  mimeType = [NGMimeType mimeType:[self inlineObjectMimeType]];
  
  self->inlineViewer =
    [[[self session] instantiateComponentForCommand:@"docview-inline"
                     type:mimeType] retain];
  
  [self->inlineViewer takeValue:[self inlineObjectData] forKey:@"object"];
  [self->inlineViewer takeValue:mimeType                forKey:@"contentType"];
  [self->inlineViewer takeValue:self->fileName          forKey:@"fileName"];
  [self->inlineViewer takeValue:[self inlineContentUrl] forKey:@"uri"];
  
  return self->inlineViewer != nil ? YES : NO;
}
- (id)inlineObjectViewer {
  return self->inlineViewer;
}

- (BOOL)showAsImage {
  NSString *fileType = [[self object] valueForKey:@"fileType"];

#if 0
  if (![self showContentInline])
    return NO;
#endif

  if ([fileType isEqualToString:@"gif"] ||
      [fileType isEqualToString:@"jpg"] ||
      [fileType isEqualToString:@"jpeg"])
    return YES;

  return NO;
}

- (NSString *)inlineContentUrl {
  NSString     *da, *sid;
  NSDictionary *qd;
  NSNumber     *pkey;
  
  da = [@"LSWDocumentDownloadAction/" stringByAppendingString:
         [self downloadDirectActionName]];
  
  pkey = [[self valueForKey:@"document"] valueForKey:@"documentId"];
  sid  = [[[self context] session] sessionID];
  qd = [NSDictionary dictionaryWithObjectsAndKeys:
                       pkey, @"pkey", sid, WORequestValueSessionID, nil];
  
  return [[self context] directActionURLForActionNamed:da
                         queryDictionary:qd];
}

- (id)folders  {
  return self->folders;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setFolderIndex:(unsigned)_index {
  self->folderIndex = _index;
}
- (unsigned)folderIndex {
  return self->folderIndex;
}

- (NSString *)itemTitle {
  id       myItem;
  NSString *title;
  
  myItem = self->item;
  title  = [myItem valueForKey:@"title"];
  if (self->folderIndex == 0) {
    NSString *projectLabel;
    
    projectLabel = [[self labels] valueForKey:@"project"];
    title = [title stringByAppendingString:@" ("];
    title = [title stringByAppendingString:projectLabel];
    title = [title stringByAppendingString:@")"];
  }
  return title;
}

- (id)fileName {
  return self->fileName;
}

- (id)editProperties {
  id page = nil;

  page = [[self session] instantiateComponentForCommand:@"edit"
                         type:gidPropType];
  [page takeValue:[[self object] globalID] forKey:@"gid"];
  [page takeValue:@"http://www.skyrix.com/Project" forKey:@"namespace"];  
  [self enterPage:page];
  return nil;
}

static NSString *ProjectNamespace = @"http://www.skyrix.com/Project";

- (id)properties {
  if (self->properties == nil) {
    SkyObjectPropertyManager *propMan = nil;
  
    propMan          = [[[self session] commandContext] propertyManager];
    self->properties = [[propMan propertiesForGlobalID:[[self object] globalID]
                                 namespace:ProjectNamespace] retain];
  }
  return [self->properties allKeys];
}

- (id)propertyValue {
  return [self->properties objectForKey:self->property];
}
- (id)propertyName {
  return [self->property substringFromIndex:[ProjectNamespace length] + 2];
}

- (void)setPropertyItem:(id)_p {
  ASSIGN(self->property, _p);
}
- (id)propertyItem {
  return self->property;
}

/* actions */

- (id)editProperty {
  id page = nil;

  page = [[self session] instantiateComponentForCommand:@"edit" 
			 type:gidPropType];
  [page takeValue:[[self object] globalID] forKey:@"gid"];
  [page takeValue:self->property forKey:@"key"];
  [page takeValue:[self->properties objectForKey:self->property] 
	forKey:@"value"];
  [self enterPage:page];
  return nil;
}

- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;  
}

@end /* LSWDocumentViewer */
