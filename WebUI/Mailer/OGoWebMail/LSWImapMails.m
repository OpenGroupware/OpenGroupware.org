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

#include "LSWImapMails.h"
#include "LSWImapMailMove.h"
#include "LSWImapMailEditor.h"
#include "LSWImapMailViewer.h"
#include "LSWImapMailFolderMove.h"
#include "LSWImapMailFilterManager.h"
#include <NGStreams/NGSocketExceptions.h>
#include "common.h"
#include <WEExtensions/WEClientCapabilities.h>
#include "SkyImapMailDataSource.h"
#include "SkyImapMailListState.h"
#include "SkyImapContextHandler.h"

@interface NSObject(LSWImapMailFilter)
- (void)setRootFolder:(NGImap4Folder *)_rootFolder;
- (void)setFolderForFilter:(NGImap4Folder *)_folder;
@end

@interface LSWImapMails(Private)
- (BOOL)initializeImap;
- (NSArray *)mails;
- (void)registerFolderWithFilterForRefresh;
- (BOOL)initializeImapWithPasswd:(NSString *)_passwd;
- (BOOL)isLogin;
- (id)folderClicked;
@end

static NSString *RawResp              = @"RawResponse";
static NSString *RespRes              = @"ResponseResult";
static NSString *Descr                = @"description";
static NSString *MailBoxAlreadyExists = @"Mailbox already exists";
static NSString *FolderDeleteHelpText =
              @"The trash already contains a folder named '%@'.\n"
              @"Please either empty the trash or rename this folder.";

@implementation LSWImapMails

static int UseSkyrixLoginForImap  = -1;
static int ShowVacationPanel      = -1;
static int ShowMailingListManager = -1;
static BOOL debugOn = NO;
static int  EnableVac  = -1;
static int  DisableVac = -1;
static int  EnableFilter  = -1;
static int  DisableFilter = -1;

+ (void)initialize {
  static BOOL didInit = NO;
  id o;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (didInit) return;
  didInit = YES;
  
  UseSkyrixLoginForImap = [ud boolForKey:@"UseSkyrixLoginForImap"] ? 1 : 0;
  EnableVac     = [ud boolForKey:@"EnableSieveVacation"]  ? 1 : 0;
  DisableVac    = [ud boolForKey:@"DisableSieveVacation"] ? 1 : 0;
  EnableFilter  = [ud boolForKey:@"EnableSieveFilter"]    ? 1 : 0;
  DisableFilter = [ud boolForKey:@"DisableSieveFilter"]   ? 1 : 0;
  debugOn       = [ud boolForKey:@"OGoImapMailsDebugOn"];
  
  o = [ud objectForKey:@"ShowVacationPanel"];
  ShowVacationPanel = (o == nil) ? 1 : ([o boolValue] ? 1 : 0);

  o = [ud objectForKey:@"UseMailingListManager"];
  ShowMailingListManager = (o == nil) ? 1 : ([o boolValue] ? 1 : 0);
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil; // THREAD
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}
- (SkyImapContextHandler *)imapCtxHandler {
  return [SkyImapContextHandler imapContextHandlerForSession:[self session]];
}
- (NGImap4Context *)hImapContext {
  return [[self imapCtxHandler] sessionImapContext:[self session]];
}

- (id)init {
  id p = nil;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  if ((self = [super init])) {
    [self registerAsPersistentInstance];
    [self initializeImap];

    self->tabKey = (UseSkyrixLoginForImap)
      ? @"mail"
      : [self isLogin] ? @"mail" : @"login";
    
    self->note = [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  // TODO: not really save at all to do this in dealloc!!
  [[self imapCtxHandler] resetImapContextWithSession:[self session]];
  [self->selectedFolder release];
  [self->rootFolder     release];
  [self->tabKey         release];
  [self->filterList     release];
  [self->filter         release];
  [self->note           release];
  [self->login          release];
  [self->passwd         release];
  [self->host           release];
  [self->mailDataSource release];
  [self->mailListState  release];
  [self->toDeletedMails release];
  [super dealloc];
}

/* datasource stuff */

- (SkyImapMailDataSource *)mailDataSource {
  return self->mailDataSource;
}
- (SkyImapMailListState *)mailListState {
  return self->mailListState;
}

/* error accessors */

- (void)setErrorStringFromContext {
  NSException *exc;
  id l;

  if ((exc = [[self imapContext] lastException]) == nil)
    return;
  
  if ([self errorString] != nil)
    return;

  l = [self labels];
  
  if ([exc isKindOfClass:[NGCouldNotResolveHostNameException class]])
    [self setErrorString:[l valueForKey:@"Couldn`t resolve host name"]];
  else if ([exc isKindOfClass:[NGIOException class]])
    [self setErrorString:[l valueForKey:@"Couldn`t connect to host"]];
  else if ([exc isKindOfClass:[NGImap4Exception class]])
    [self setErrorString:[l valueForKey:[exc reason]]];
  else
    [self setErrorString:[l valueForKey:@"Unexpected Error"]];
}

/* response generation */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  if ([self->tabKey isEqualToString:@"mail"]) {
    if ([[[_ctx request] clientCapabilities] doesSupportUTF8Encoding])
      [_response setContentEncoding:NSUTF8StringEncoding];
  }
  [self setErrorStringFromContext];
  [super appendToResponse:_response inContext:_ctx];
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  if ([_cn isEqualToString:@"LSWImapFilterChanged"]) {
    [self->filterList release]; 
    self->filterList = nil;
  }
  if ([_cn isEqualToString:@"LSWImapMailFolderWasDeleted"])
    [self->note setObject:_object forKey:_cn];
}

- (void)_postMailsClearSelections {
  [[self notificationCenter]
         postNotificationName:@"LSWImapMailsShouldClearSelections" object:nil];
}
- (void)_postMailFlagsChanged {
  [[self notificationCenter]
	 postNotificationName:@"LSWImapMailFlagsChanged" object:nil];
}

/* accessors */

- (NSString *)mailListName {
  // TODO: use [ctx isSentFolder:..]
  return ([self->selectedFolder isEqual:[[self hImapContext] sentFolder]])
    ? @"SentMailList"
    : @"MailList";
}

- (BOOL)initializeImap {
  return [self initializeImapWithPasswd:
               [[[[self session] userDefaults] objectForKey:@"imap_passwd"]
                        stringValue]];
}

- (void)clearVars {
  [[self hImapContext] closeConnection];
  [[self imapCtxHandler] resetImapContextWithSession:[self session]];

  [self->selectedFolder release];     self->selectedFolder = nil;
  [self->rootFolder     resetFolder];
  [self->rootFolder     release];     self->rootFolder     = nil;
  [self->mailDataSource release];     self->mailDataSource = nil;
  [self->mailListState  release];     self->mailListState  = nil;
  [self->toDeletedMails release];     self->toDeletedMails = nil;
}

- (BOOL)initializeImapWithPasswd:(NSString *)_passwd {
  // TODO: split up
  NSUserDefaults *defs;
  NSString       *error;
  id             imapCtx;

  [self setErrorString:nil];
  
  if (self->loginFailed)
    return NO;

  defs = [[self session] userDefaults];
  
  if ((imapCtx = [self hImapContext]) == nil) {
    ASSIGN(self->login, nil);
    ASSIGN(self->host,  nil);
    
    [self clearVars];

    imapCtx = [[self imapCtxHandler] imapContextWithSession:[self session]
                                     password:_passwd login:&self->login
                                     host:&self->host errorString:&error];

    self->login = [self->login retain];
    self->host  = [self->host retain];
  
    if (!imapCtx) {
      [self setErrorString:[[self labels] valueForKey:error]];
      [self clearVars];
      self->loginFailed = YES;
      return NO;
    }
  }
  if (self->mailDataSource == nil || self->rootFolder == nil ||
      self->selectedFolder == nil) {
    id localException;

    ASSIGN(self->rootFolder,     [imapCtx serverRoot]);
    ASSIGN(self->selectedFolder, [imapCtx inboxFolder]);

    ASSIGN(self->mailListState, nil);

    ASSIGN(self->mailDataSource,
           [[self imapCtxHandler] mailDataSourceWithSession:[self session]
                                  folder:self->selectedFolder]);
    self->mailListState  = [[SkyImapMailListState  alloc]
                                                  initWithDefaults:defs];
    
    [self->mailListState  setFolder:self->selectedFolder];
      
    [self->mailListState setName:[self mailListName]];
    [self->mailListState setCurrentBatch:1];

    [self _postMailsClearSelections];
    
    {
      NSString *fName;
      id       f;

      if ((fName = [defs valueForKey:@"mail_sentFolderName"])) {
        if ((f = [imapCtx folderWithName:fName]))
          [imapCtx setSentFolder:f];
      }
      if ((fName = [defs valueForKey:@"mail_trashFolderName"])) {
        if ((f = [imapCtx folderWithName:fName]))
          [imapCtx setTrashFolder:f];
      }
    }
    /* get or create trash and sent folder */
    [self registerFolderWithFilterForRefresh];
    
    if ((localException = [imapCtx lastException])) {
      id l;

      l = [self labels];
      
      if ([localException isKindOfClass:[NGIOException class]]) {
        [self setErrorString:[l valueForKey:@"Couldn`t connect to host"]];
      }
      else  if ([localException isKindOfClass:[NGImap4Exception class]]) {
        [self setErrorString:[l valueForKey:[localException reason]]];
      }
      else {
        [self setErrorString:[localException description]];
      }
    }
  }
  return YES;
}

- (void)syncAwake {
  // TODO: splitup
  id obj;

  if (debugOn) [self logWithFormat:@"syncAwake: begin"];
    
  self->loginFailed       = NO;
  self->trashFolderFailed = NO;
  self->inboxFolderFailed = NO;

    [[self imapContext] resetLastException];
    [self setErrorString:nil];
    if ([self imapContext] == nil) {
      if (![self initializeImap]) {
        [self setErrorStringFromContext];
        return;
      }
    }
    [[self imapContext] resetSync];

    if (![self isInWarningMode]) {
      [self->toDeletedMails release];  self->toDeletedMails  = nil;
    }

    obj = nil;
    
    if ([self imapContext] != nil) {
      int oldExists, oldUnseen;

      oldExists = [self->mailDataSource oldExists];
      oldUnseen = [self->mailDataSource oldUnseen];

      if (!(obj = [self->note objectForKey:@"LSWImapMailFolderWasDeleted"])) {
        if (![[self imapContext] refreshFolder]) {
          [self setErrorStringFromContext];
          [self clearVars];
        }
#if 0        
        if (self->selectedFolder) {
          if (![self->selectedFolder noselect]) {
            if (![self->selectedFolder status]) {
              [self setErrorStringFromContext];
              [self clearVars];
            }
          }
        }
#endif        
      }
      if (obj) {
        if ([self->selectedFolder isEqual:obj] &&
            ![obj isEqual:[[self imapContext] trashFolder]]) {
          [self->selectedFolder release]; self->selectedFolder = nil;
          
          self->selectedFolder = [[(NGImap4Folder *)obj parentFolder] retain];

          [self->mailDataSource setFolder:self->selectedFolder];
          [self->mailListState  setName:[self mailListName]];
          [self->mailListState  setFolder:self->selectedFolder];
          [self->mailListState  setCurrentBatch:1];
	  
	  [self _postMailsClearSelections];
        }
        [self->note removeObjectForKey:@"LSWImapMailFolderWasDeleted"];
      }
      else if (oldExists != [self->selectedFolder exists])
        [self->mailDataSource setFolder:self->selectedFolder];
      else if (oldUnseen != [self->selectedFolder unseen])
	[self _postMailFlagsChanged];
      
      if (self->filterList == nil) {
        id a;

        a = [[self session] activeAccount];
        
        self->filterList = [[LSWImapMailFilterManager filterForUser:a] retain];
        [self registerFolderWithFilterForRefresh];
      }
    }
    if ([[self imapContext] lastException] || [self errorString]) {
      [self setErrorStringFromContext];
      [self clearVars];
    }
    
  [super syncAwake];  
  if (debugOn) [self logWithFormat:@"syncAwake: done"];
}

- (void)registerFolderWithFilterForRefresh {
  NSMutableSet   *folderWithFilter;
  NSEnumerator   *enumerator;
  NGImap4Context *imapCtx;
  NSDictionary   *filterEntry;
  id             obj;
  OGoSession     *s;

  if (self->rootFolder == nil)
    return;

  if (debugOn) [self logWithFormat:@"registerFolderWithFilterForRefresh"];

  s                = [self session];
  imapCtx          = [self imapContext];
  folderWithFilter = [[NSMutableSet alloc] initWithCapacity:64];
  
  [folderWithFilter addObject:self->rootFolder];
  [imapCtx removeAllFromRefresh];
  
  enumerator = [[LSWImapMailFilterManager filterForUser:[s activeAccount]]
                                          objectEnumerator];
  while ((filterEntry = [enumerator nextObject])) {
    NGImap4Folder *f;
    
    f = [imapCtx folderWithName:[filterEntry objectForKey:@"folder"]];
    
    if (f != nil)
      [folderWithFilter addObject:f];
  }
  enumerator = [folderWithFilter objectEnumerator];
  while ((obj = [enumerator nextObject]))
    [imapCtx registerForRefresh:obj];

  [folderWithFilter release]; folderWithFilter = nil;

  if (debugOn) 
    [self logWithFormat:@"registerFolderWithFilterForRefresh: done"];
}

/* accessors */

- (void)setShowTree:(BOOL)_hideTree {
  [[[self session] userDefaults]
          setBool:_hideTree
          forKey:@"mailpage_showtree"];
}
- (BOOL)showTree {
  id obj;
  
  obj = [[[self session] userDefaults] objectForKey:@"mailpage_showtree"];

  return (obj == nil)
    ? [[[[self context] request] clientCapabilities] isFastTableBrowser]
    : [obj boolValue];
}


- (void)setSelectedFolder:(id)_selectedFolder {
  ASSIGN(self->selectedFolder, _selectedFolder);
}
- (id)selectedFolder {
  return self->selectedFolder;
}

- (BOOL)isTrashFolder {
  // TODO: should use something like [ctx isTrashFolder:self->selectedFolder]
  return [self->selectedFolder isEqual:[[self hImapContext] trashFolder]];
}

- (NGImap4Folder *)inboxFolder {
  NGImap4Folder *f;

  if (!self->inboxFolderFailed) {
    if ((f = [[self imapContext] inboxFolder]))
      return f;
  }
  self->inboxFolderFailed = YES;
  return nil;
}

- (NGImap4Folder *)trashFolder {
  NGImap4Folder *f;

  if (!self->trashFolderFailed) {
    if ((f = [[self imapContext] trashFolder]))
      return f;
  }
  self->trashFolderFailed = YES;
  return nil;
}

- (BOOL)isNotTrashFolder {
  return ![self isTrashFolder];
}

- (BOOL)isTrashEmpty {
  NGImap4Folder *trash;

  trash = [[self imapContext] trashFolder];

  return ([trash exists] == 0) && ([[trash subFolders] count] == 0);
}

- (BOOL)canDeleteFolder {
  NSString *aName;

  if (self->selectedFolder == self->rootFolder ||
      [self->selectedFolder isEqual:[self inboxFolder]])
    return NO;

  aName =  [[[self imapContext] trashFolder] absoluteName];
  return (![aName hasPrefix:[self->selectedFolder absoluteName]]);
}

- (BOOL)canEditFolder {
  if (self->selectedFolder == self->rootFolder)
    return NO;
  else if ([self->selectedFolder isEqual:[self inboxFolder]])
    return NO;
  else
    return YES;
}

- (BOOL)canNewFolder {
  return [self->selectedFolder noinferiors] ? NO : YES;
}

- (BOOL)canMoveFolder {
  if (self->selectedFolder == self->rootFolder)
    return NO;
  if ([self->selectedFolder isEqual:[self inboxFolder]])
    return NO;

  return YES;
}

- (BOOL)allowNewFilter {
  return (self->selectedFolder == self->rootFolder) ? NO : YES;
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (id)tabClicked {
  return nil;
}

/* filter accessors */

- (id)filterList {
  return self->filterList;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescendingForFilterList:(BOOL)_isDescending {
  self->isDescendingForFilterList = _isDescending;
}
- (BOOL)isDescendingForFilterList {
  return self->isDescendingForFilterList;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  self->selectedAttribute = _selectedAttribute;
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setFilter:(NSDictionary *)_filter {
  ASSIGN(self->filter, _filter);
}
- (NSDictionary *)filter {
  return self->filter;
}

/* actions */

- (id)moveFolder {
  LSWImapMailFolderMove *page;

  page = [self pageWithName:@"LSWImapMailFolderMove"];
  
  [page setFolder:self->selectedFolder];
  [page setRootFolder:self->rootFolder];
  return page;
}

- (BOOL)deleteFolderImmediately {
  static int DeleteFolderImmediately = -1;

  if (DeleteFolderImmediately == -1) {
    DeleteFolderImmediately =
      ([[NSUserDefaults standardUserDefaults]
                        boolForKey:@"DeleteImapFolderImmediately"])?1:0;
  }
  return DeleteFolderImmediately;
}

- (id)deleteFolder {
  [self setWarningOkAction:@"reallyDeleteFolder"];
  
  [self setWarningPhrase:[self deleteFolderImmediately]
	  ? @"reallyImmRemoveFolder" : @"reallyRemoveFolder"];
  
  [self setIsInWarningMode:YES];
  return nil;
}

- (void)_postDeleteFolderNotifications:(NGImap4Folder *)_folder {
  NSNotificationCenter *nc;

  nc = [self notificationCenter];
  [self _postMailsClearSelections];
  [nc postNotificationName:@"LSWImapMailFolderWasDeleted" object:_folder];
  [nc postNotificationName:@"LSWImapMailWasDeleted"       object:nil];
}

/* error handling */

- (void)_processImap4ResponseException:(NGImap4ResponseException *)_exception 
  folderName:(NSString *)_folderName
{
  NSString *str;

  // TODO: fix this junk
  str = [(NSDictionary *)[(NSDictionary *)[[_exception userInfo] 
                                 objectForKey:RawResp]
	                         objectForKey:RespRes]
                                 objectForKey:Descr];

  [self setErrorString:str];
  if ([str isEqualToString:MailBoxAlreadyExists]) {
    NSString *s, *l;
    
    l = [[self labels] valueForKey:FolderDeleteHelpText];
    s = [NSString stringWithFormat:l, _folderName];
    [self setErrorString:s];
  }
}

- (void)_processIOException:(NGIOException *)_exception {
  NSString *s;
  
  // TODO: pass over raw reason? no good, need an error code ...
  s = [[self labels] valueForKey:[_exception reason]];
  [self setErrorString:s];
  [self clearVars]; 
}
- (void)_processImap4Exception:(NGImap4Exception *)_exception {
  // Note: this passes over the raw reason
  [self setErrorString:[_exception description]];
  [self clearVars];
}
- (void)_processUnknownException:(NSException *)_exception {
  [self logWithFormat:@"Error(%s): got exception %@", __PRETTY_FUNCTION__,
	  _exception];
  // TODO: fix label
  [self setErrorString:[[self labels] valueForKey:@"Unexpected Error"]];
}

- (void)_processReallyDeleteFolderException:(NSException *)_exception
  folderName:(NSString *)_fname
{
  if (_exception == nil)
    return;
  
  // TODO: better use double dispatch?
  if ([_exception isKindOfClass:[NGImap4ResponseException class]])
    [self _processImap4ResponseException:(id)_exception folderName:_fname];
  else if ([_exception isKindOfClass:[NGIOException class]])
    [self _processIOException:(id)_exception];
  else if ([_exception isKindOfClass:[NGImap4Exception class]])
    [self _processImap4Exception:(id)_exception];
  else 
    [self _processUnknownException:_exception];
}

- (id)reallyDeleteFolder {
  NGImap4Folder *tmp;
  
  [self->selectedFolder resetLastException];

  tmp = self->selectedFolder;

  self->selectedFolder = [[self->selectedFolder parentFolder] retain];
    
  if ([tmp isInTrash] || [self deleteFolderImmediately])
    [self->selectedFolder deleteSubFolder:tmp];
  else
    [self->selectedFolder moveSubFolder:tmp to:[self trashFolder]];
  
  [self->mailDataSource setFolder:self->selectedFolder];
  [self->mailListState  setCurrentBatch:1];
  [self->mailListState  setFolder:self->selectedFolder];
  [self setIsInWarningMode:NO];
  
  [self _postDeleteFolderNotifications:tmp];
  
  [self _processReallyDeleteFolderException:
	  [self->selectedFolder lastException]
	folderName:[tmp name]];
  [tmp release]; tmp = nil;
  
  [self folderClicked];
  return nil;
}

- (id)emptyTrash {
  [self setWarningOkAction:@"reallyEmptyTrash"];
  [self setWarningPhrase:@"reallyEmptyTrash"];
  [self setIsInWarningMode:YES];
  return nil;
}

- (void)_postEmptyTrashNotifications:(NGImap4Folder *)_trash {
  NSNotificationCenter *nc;
  
  nc = [self notificationCenter];
  [nc postNotificationName:@"LSWImapMailFolderWasDeleted" object:_trash];
  [nc postNotificationName:@"LSWImapMailWasDeleted"       object:nil];
}

- (void)_processReallyEmptyTrashFolderException:(NSException *)_exception {
  id l;
  
  if (_exception == nil)
    return;

  l = [self labels];
  if ([_exception isKindOfClass:[NGImap4Exception class]]) {
    NSString *str;
    
    str = [l valueForKey:[_exception reason]];
    str = [NSString stringWithFormat:@"%@: '%@'.",
                      [l valueForKey:@"EmptyTrashFailedWithReason"],
                      str];
        
    [self setErrorString:str];
  }
  else if ([_exception isKindOfClass:[NGIOException class]]) {
    [self setErrorString:[_exception reason]];
    [self clearVars];
  }
  else {
    [self logWithFormat:@"ERROR(%s): got exception: %@", __PRETTY_FUNCTION__,
            _exception];
    [self setErrorString:[l valueForKey:@"Unexpected error"]];
  }
  
  [[self imapContext] resetLastException];
}

- (id)reallyEmptyTrash {
  NSEnumerator  *enumerator;
  NGImap4Folder *trash, *f;
  
  trash = [self trashFolder];
  
  [self->selectedFolder resetLastException];
  if ([self->selectedFolder isInTrash])
    [self setSelectedFolder:trash];
  
  [self->mailDataSource setFolder:self->selectedFolder];
  [self->mailListState  setCurrentBatch:1];
  [self->mailListState  setFolder:self->selectedFolder];
  
  enumerator = [[trash subFolders] objectEnumerator];
  while ((f = [enumerator nextObject])) {
    if (![trash deleteSubFolder:f])
      break;
  }
  [trash deleteAllMessages];
  [self setIsInWarningMode:NO];
  [self _postEmptyTrashNotifications:trash];

  [self _processReallyEmptyTrashFolderException:
	  [[self imapContext] lastException]];
  
  [trash resetFolder];
  [self folderClicked];
  return nil;
}


- (id)newFolder {
  return [self activateObject:self->selectedFolder withVerb:@"new"];
}
- (id)editFolder {
  return [self activateObject:self->selectedFolder withVerb:@"edit"];
}

- (id)newMail {
  NGMimeType  *mt;
  id          ct;

  mt = [NGMimeType mimeType:@"objc" subType:@"NGImap4Message"];

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  [ct setImapContext:[self imapContext]];
  return ct;
}

- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;
}

/* private methodes */

- (id)rootFolder {
  return self->rootFolder;
}

- (id)folderClicked {
  if (debugOn) [self logWithFormat:@"folderClicked: expunge"];
  [(NGImap4Folder *)self->selectedFolder expunge];
  
  if (debugOn) [self logWithFormat:@"folderClicked: cfg datasource"];
  [self->mailDataSource setFolder:self->selectedFolder];

  if (debugOn) [self logWithFormat:@"folderClicked: cfg mailstate"];
  [self->mailListState setFolder:self->selectedFolder];
  [self->mailListState setName:[self mailListName]];
  [self->mailListState setCurrentBatch:1];

  [self->toDeletedMails release]; self->toDeletedMails = nil;
  
  if (debugOn) [self logWithFormat:@"folderClicked: notification"];
  [self _postMailsClearSelections];
  if (debugOn) [self logWithFormat:@"folderClicked: done"];
  return nil;
}

/* filter actions */

- (id)newFilter {
  NGMimeType   *mt;
  WOComponent  *ct;

  mt = [NGMimeType mimeType:@"objc" subType:@"imap-filter"];
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  [ct setRootFolder:self->rootFolder];  
  return ct;
}

- (id)editFilter {
  NGMimeType          *mt;
  WOComponent         *ct;
  NSMutableDictionary *dic;

  mt  = [NGMimeType mimeType:@"objc" subType:@"imap-filter"];
  dic = [NSMutableDictionary dictionaryWithCapacity:2];
  
  [dic setObject:self->filter forKey:@"filter"];

  // TODO: why not activate?
  [[self session] transferObject:dic owner:self];
  ct = [[self session] instantiateComponentForCommand:@"edit" type:mt];
  [ct setRootFolder:self->rootFolder];
  return ct;
}

- (id)newFilterForFolder {
  NGMimeType   *mt;
  WOComponent  *ct;

  mt = [NGMimeType mimeType:@"objc" subType:@"imap-filter"];
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  
  if (self->selectedFolder != nil)
    [ct setFolderForFilter:self->selectedFolder];
  [ct setRootFolder:self->rootFolder];  
  return ct;
}

- (NGImap4Context *)imapContext {
  if (self->loginFailed)
    return nil;
  
  if (UseSkyrixLoginForImap)
    [self initializeImap];
  
  if (![self hImapContext])
    return nil;
  
  if (self->mailDataSource == nil || self->rootFolder == nil ||
      self->selectedFolder == nil) {
    [self initializeImap];
  }
  return [self hImapContext];
}

- (BOOL)mustLogin {
  return ([self imapContext] == nil) ? YES : NO;
}

- (BOOL)isLogin {
  // TODO: give that a proper name (eg: isLoggedIn)
  if (UseSkyrixLoginForImap)
    [self initializeImap];
  
  return ([self imapContext] == nil) ? NO : YES;
}
- (NSNumber *)isLoginNumber {
  return [NSNumber numberWithBool:([self imapContext] == nil) ? NO : YES];
}

- (NSString *)leftKey {
  return [self isLogin] ? @"mail" : @"login";
}

- (id)doLogout {
  NSUserDefaults *defs;
  id             sn;

  sn   = [self session];
  defs = [sn userDefaults];  

  [self clearVars];
  
  self->savePasswd = NO;
  
  [sn runCommand:@"userdefaults::delete", @"key", @"imap_passwd",
      @"defaults", defs,
      nil];

  [self->passwd release]; self->passwd = nil;
  ASSIGN(self->tabKey, @"login");
  return nil;
}


- (id)doLogin {
  self->loginFailed = NO;
  [self clearVars];

  [[self imapCtxHandler] prepareForLogin:self->login
                         passwd:self->passwd
                         host:self->host
                         savePwd:self->savePasswd
                         session:[self session]];
  
  [self initializeImapWithPasswd:self->passwd];
  [self->passwd release]; self->passwd = nil;
  
  if (![self isLogin])
    return nil;
  
  ASSIGN(self->tabKey, @"mail");
  return nil;
}

- (void)setHost:(id)_id {
  ASSIGN(self->host, _id);
}
- (id)host {
  return self->host;
}
- (void)setLogin:(id)_id {
  ASSIGN(self->login, _id);
}
- (id)login {
  return self->login;
}
- (void)setPassword:(id)_id {
  ASSIGN(self->passwd, _id);
}

- (id)password {
  return self->passwd;
}

- (BOOL)savePassword {
  return self->savePasswd;
}
- (void)setSavePassword:(BOOL)_passwd {
  self->savePasswd = _passwd;
}

- (BOOL)serverHasVacation {
  int version;

  if (![[[self imapContext] serverKind] isEqualToString:@"cyrus"])
    return NO;
  
  if (DisableVac == 1) return NO;
  if (EnableVac  == 1) return YES;
  
  version = [[[self imapContext] serverVersion] intValue];
  if (version > 1)
    return YES;
  
  return NO;
}

- (BOOL)serverHasFilter {
  int version, subversion, tag;
  id  ctx;
  
  if (DisableFilter) return NO;
  if (EnableFilter)  return YES;
  
  if (![[[self imapContext] serverKind] isEqualToString:@"cyrus"])
    return NO;

  ctx        = [self imapContext];
  version    = [[ctx serverVersion]    intValue];
  subversion = [[ctx serverSubVersion] intValue];
  tag        = [[ctx serverTag]        intValue];
    
  if (version > 1)
    return YES;
  
  if (version == 1) {
    if (subversion > 6)
      return YES;
    else if (subversion == 6) {
      if (tag >= 22)
	return YES;
    }
  }
  return NO;
}

- (NSString *)serverName {
  return [[self imapContext] serverName];
}

- (BOOL)showLoginPanel {
  return !UseSkyrixLoginForImap;
}

- (BOOL)serverError {
  if (UseSkyrixLoginForImap) {
    if (![self imapContext])
      return YES;
  }
  return NO;
}

- (BOOL)showVacationPanel {
  return ShowVacationPanel;
}

- (BOOL)showMailingListManager {
  return ShowMailingListManager;
}

- (void)setToDeletedMails:(NSArray *)_mails {
  ASSIGN(self->toDeletedMails, _mails);
}

- (id)reallyDeleteMails {
  NGImap4Folder *f;
  
  if ([self->toDeletedMails count] == 0)
    return nil;
  
  f = [[self->toDeletedMails lastObject] folder];
  [f deleteMessages:self->toDeletedMails]; // TODO: add sanity checks!
  
  [[self notificationCenter] 
         postNotificationName:@"LSWImapMailWasDeleted" object:nil];
  [self->toDeletedMails release]; self->toDeletedMails = nil;
  [self setIsInWarningMode:NO];
  
  [self _postMailsClearSelections];
  return nil;
}

@end /* LSWImapMails */
