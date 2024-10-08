/*
  Copyright (C) 2002-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "SxUserFolder.h"
#include "NSObject+ExValues.h"
#include "NGResourceLocator+ZSF.h"
#include "common.h"

#include "SxMsgRootFolder.h"
#include "ExStoreEntryID.h"
#include <NGExtensions/NGPropertyListParser.h>
#include <SaxObjC/XMLNamespaces.h>

#define USE_ZIDELOOK_HACK 1

@interface NSObject(PubFolder)
- (id)publicFolder:(NSString *)_name container:(id)_c;
@end

@implementation SxUserFolder

static NSArray      *storeRootKeys     = nil;
static NSArray      *folderRootKeys    = nil;
static NSArray      *flatRootKeys      = nil;
static int          zlRefreshInMinutes = 2;
static NSDictionary *personalFolderMap = nil;

+ (void)initialize {
  NSUserDefaults    *ud;
  NSDictionary      *info;
  NGResourceLocator *locator;
  NSString *path;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  locator = [NGResourceLocator zsfResourceLocator];
  path = [locator lookupFileWithName:@"PersonalFolderInfo.plist"];
  info = [path length] > 2
    ? [NSDictionary skyDictionaryWithContentsOfFile:path]
    : nil;
  if (info == nil)
    [self logWithFormat:@"ERROR: could not load folder info: '%@' !", path];
  
  storeRootKeys     = [[info objectForKey:@"storeRootKeys"]  copy];
  folderRootKeys    = [[info objectForKey:@"folderRootKeys"] copy];
  flatRootKeys      = [[info objectForKey:@"flatRootKeys"]   copy];
  personalFolderMap = [[info objectForKey:@"keymap"]         copy];

  zlRefreshInMinutes = [[ud objectForKey:@"ZLRefreshInterval"] intValue];
  if (zlRefreshInMinutes < 1) zlRefreshInMinutes = 2;
}

- (id)initWithLogin:(NSString *)_login {
  if ((self = [super init])) {
    self->login = [_login copy];
  }
  return self;
}

- (id)init {
  return [self initWithLogin:nil];
}

- (void)dealloc {
  [self->msgFolderRoot release];
  [self->login         release];
  [super dealloc];
}

/* SoObject */

- (NSString *)nameInContainer {
  return self->login;
}

- (id)container {
  return [WOApplication application];
}

/* security */

- (NSString *)ownerID {
  return [self nameInContainer];
}

- (NSString *)ownerInContext:(id)_ctx {
  return [self ownerID];
}

/* subfolders */

- (BOOL)useSeparateRootInContext:(id)_ctx {
  NSString *ua;
  
  if (_ctx == nil)
    _ctx = [(WOApplication *)[WOApplication application] context];
  
  ua = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  if ([ua rangeOfString:@"ZideLook"].length > 0)
    return YES;
  return NO;
}

- (NSEnumerator *)davChildKeysInContext:(id)_ctx {
  /* this returns the top-level folders */
  NSString *ua;
  
  if ([self useSeparateRootInContext:_ctx]) /* usually ZideLook */
    return [storeRootKeys objectEnumerator] ;
  
  ua = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  if ([ua isEqualToString:@"MacOSXDAVFS"])
    return [flatRootKeys objectEnumerator];
  
  return [folderRootKeys objectEnumerator];
}
- (NSArray *)toManyRelationshipKeys {
  NSEnumerator *e;
  
  [self debugWithFormat:@"toManyRelationshipKeys was called ..."];
  if ((e = [self davChildKeysInContext:nil]) == nil)
    return nil;
  return [[[NSArray alloc] initWithObjectsFromEnumerator:e] autorelease];
}

- (NSArray *)toOneRelationshipKeys {
  [self debugWithFormat:
	  @"toOneRelationshipKeys was called (returns nothing) ..."];
  return nil;
}

/* personal IPM folders */


/* iCal handlers */

- (id)iCalendarForName:(id)_key inContext:(id)_ctx {
  id defCalendar;
  
  defCalendar = [self lookupName:@"Calendar" inContext:_ctx acquire:NO];
  if (defCalendar == nil) {
    [self logWithFormat:@"WARNING: did not find default-calendar !"];
    return nil;
  }
  return [defCalendar lookupName:_key inContext:_ctx acquire:NO];
}

/* lookup */

#if USE_ZIDELOOK_HACK

- (NSString *)baseURLInContext:(id)_ctx {
  NSString *uri;
  
  uri = [[(WOContext *)_ctx request] uri];
  if ([uri hasPrefix:@"/H_chste_Ebene_der_Pers_nlichen_Ordner"]) {
    uri = [self rootURLInContext:_ctx];
    if (![uri hasSuffix:@"/"]) uri = [uri stringByAppendingString:@"/"];
    uri = [uri stringByAppendingString:
                 @"H_chste_Ebene_der_Pers_nlichen_Ordner/"];
  }
  return [super baseURLInContext:_ctx];
}

#endif

- (id)msgRootFolder:(NSString *)_key inContext:(id)_ctx {
  if (![self useSeparateRootInContext:_ctx]) {
    [self logWithFormat:@"returning self as root ..."];
    return self;
  }
  else {
    id folder; // TODO: folder-class
    folder = [[NGClassFromString(@"SxMsgRootFolder") alloc] 
               initWithName:_key inContainer:self];
    return [folder autorelease];
  }
}
- (id)storeInfoFolder:(NSString *)_key inContext:(id)_ctx {
  id folder; // TODO: folder-class
  folder = [[NGClassFromString(@"SxStoreInfoFolder") alloc] 
             initWithName:_key inContainer:self];
  return [folder autorelease];
}

- (id)_checkLicenseInContext:(id)_ctx {
#if 0
  static int isLicensed = -1;
#else
  static int isLicensed = 1;
#endif
  id ctx;
  
  if ((ctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"no command-context when accessing UserFolder ?"];
    return nil;
  }
  
  if (isLicensed == -1) {
#if 0 
    isLicensed = [ctx isModuleLicensed:@"ZideStore"] ? 1 : 0;
    if (isLicensed)
      [self logWithFormat:@"successfully validated the ZideStore license !"];
    else
      [self logWithFormat:@"ZideStore is not licensed in key !"];
#endif    
  }
  if (!isLicensed) {
    WOResponse *r = [(WOContext *)_ctx response];
    [r setStatus:402 /* Payment Required */];
    [r appendContentHTMLString:@"did not find a valid SKYRiX license key !"];
    return r;
  }
  return nil;
}

- (id)personalFolder:(NSString *)_name inContext:(id)_ctx
  info:(NSDictionary *)_info
{
  Class clazz;
  id tmp, folder;
  
  //[self logWithFormat:@"creating personal folder: %@: %@", _name, _info];
  
  tmp = [_info objectForKey:@"class"];
  clazz = tmp ? NGClassFromString(tmp) : Nil;
  if (clazz == Nil) {
    [self logWithFormat:@"ERROR: got no class for personal folder '%@': %@",
            _name, _info];
    return nil;
  }
  if ((folder = [[clazz alloc] initWithName:_name inContainer:self]) == nil) {
    [self logWithFormat:@"ERROR: could not create personal folder '%@': %@",
            _name, _info];
    return nil;
  }
  folder = [folder autorelease];
  
  if ((tmp = [_info objectForKey:@"config"]))
    [folder takeValuesFromDictionary:tmp];
  
  return folder;
}

- (id)optionsForm:(NSString *)_name inContext:(id)_ctx {
  return [[[NGClassFromString(@"SxOptionsForm") alloc] 
           initWithName:_name inContainer:_ctx] autorelease];
}

- (id)lookupInbox:(NSString *)_key inContext:(id)_ctx {
  Class clazz;
  
  if ((clazz = NGClassFromString(@"ZSOGoMailAccount")) == Nil) {
    static BOOL didWarn = NO;
    if (!didWarn) {
      [self logWithFormat:@"Note: the SOGo mailer is not installed."];
      didWarn = YES;
    }
    return nil;
  }
  
  return [[[clazz alloc] initWithName:_key inContainer:self] autorelease];
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  NSString *ua;
  id tmp;
  
  if ((tmp = [self _checkLicenseInContext:_ctx]))
    return tmp;
  
  if ([_key isEqualToString:@"options"])
    return [self optionsForm:_key inContext:_ctx];
  
  if ((tmp = [personalFolderMap objectForKey:_key]))
    return [self personalFolder:_key inContext:_ctx info:tmp];
  
  ua = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  if ([ua isEqualToString:@"AppleDAVAccess"]) {
    [self logWithFormat:@"UA: %@ - probably iCalendar", ua];
    if ([_key isEqualToString:@".ics"])
      return [self iCalendarForName:@"calendar.ics" inContext:_ctx];
  }
  
  if ([_key isEqualToString:@"IPM"])
    return [self msgRootFolder:_key inContext:_ctx];
  if ([_key isEqualToString:@"H_chste_Ebene_der_Pers_nlichen_Ordner"]) {
    [self logWithFormat:@"catched zidelook 'h-ebene-query' ..."];
    return [self msgRootFolder:_key inContext:_ctx];
  }

  if ([_key isEqualToString:@"NON_IPM_SUBTREE"])
    return [self storeInfoFolder:_key inContext:_ctx];
  
  if ([_key isEqualToString:@"Public"] || [_key isEqualToString:@"public"])
    return [[WOApplication application] publicFolder:_key container:self];
  
  if ([_key isEqualToString:@"calendar.ics"] || [_key isEqualToString:@"ics"])
    return [self iCalendarForName:_key inContext:_ctx];

  if ([_key isEqualToString:@"Mail"])
    return [self lookupInbox:_key inContext:_ctx];
  
  return [super lookupName:_key inContext:_ctx acquire:_flag];
}

- (NSString *)baseURL {
  return [self baseURLInContext:
		 [(WOApplication *)[WOApplication application] context]];
}

/* Exchange/HTTP-Mail properties */

- (NSString *)exchangeTimeZone {
  return @"W. Europe Standard Time";
}

- (BOOL)useSeparateMessageFolderRootInContext:(id)_ctx {
  NSString *ua;

  ua = [[(WOContext *)_ctx request] headerForKey:@"user-agent"];
  if ([ua rangeOfString:@"Evolution"].length == 0)
    return NO;
  
  if ([ua rangeOfString:@"Konqueror"].length == 0)
    // TODO: should check for KPIM or KOrganizer
    return NO;
  
  return YES;
}

- (NSString *)messageFolderRoot {
  NSString *msgroot;
  id ctx;
  
  if (self->msgFolderRoot != nil)
    /* cached */
    return self->msgFolderRoot;
  
  ctx     = [(WOApplication *)[WOApplication application] context];
  msgroot = [self baseURLInContext:ctx];
  
  if ([self useSeparateMessageFolderRootInContext:ctx]) {
    [self logWithFormat:@"using separate message-folder-root (IPM/) .."];
    msgroot = [msgroot stringByAppendingPathComponent:@"IPM/"];
  }
  self->msgFolderRoot = [msgroot copy];
  return self->msgFolderRoot;
}
- (NSString *)publicFolderRoot {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"public/"];
}
- (NSString *)reminderFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"reminder/"];
}

- (NSString *)zlFreeBusyURLs {
  // TODO: find out what this points too ...
  //       it's a 1102, an array of entry-ids
  //       ZideLook will map that to URLs separated by \n
  return [[self messageFolderRoot] 
                stringByAppendingPathComponent:@"zlFreeBusy"];
}

- (NSString *)accountRootURL {
  return [self messageFolderRoot];
}
- (NSString *)contactsFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Contacts/"];
}
- (NSString *)calendarFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Calendar/"];
}
- (NSString *)journalFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Journal/"];
}
- (NSString *)tasksFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Tasks/"];
}
- (NSString *)notesFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Notes/"];
}

- (NSString *)msgSendURL {
  // 2323 - 2323
  return [[self messageFolderRoot]
                stringByAppendingPathComponent:@"DavMailSubmissionURI"];
}

- (NSString *)adbar {
  [self logWithFormat:@"NOTE: delivering advertising bar URL ..."];
  return @"AdPane=On*AdSvr=H*Other=http://dogbert.in.skyrix.com:9000/adbar";
}

- (int)zlRefreshInMinutes {
  return zlRefreshInMinutes;
}

- (NSString *)inboxFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"INBOX/"];
}

- (NSString *)outboxFolderURL {
  return [[self messageFolderRoot] 
                stringByAppendingPathComponent:@"Outgoing/"];
}

- (NSString *)trashFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Trash/"];
}

- (NSString *)sentFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Sent/"];
}

- (NSString *)draftsFolderURL {
  return [[self messageFolderRoot] stringByAppendingPathComponent:@"Drafts/"];
}

- (NSString *)maxpoll {
  return @"30";
}

- (NSString *)sig {
  return @"MySignatureViaHTTPMail";
}

/* DAV things */

- (BOOL)davHasSubFolders {
  /* user folders are there to have child folders */
  return YES;
}

- (id)davCalendarHomeSet {
  /*
    <C:calendar-home-set xmlns:D="DAV:"
        xmlns:C="urn:ietf:params:xml:ns:caldav">
      <D:href>http://cal.example.com/home/bernard/calendars/</D:href>
    </C:calendar-home-set>

    Note: this is the *container* for calendar collections, not the
          collections itself. So for use its the home folder, the
	  public folder and the groups folder.
  */
  WOContext *ctx;
  NSMutableArray *homeSet;
  id tag;
#if 0
  id obj;
#endif

  ctx = [(WOApplication *)[WOApplication application] context];

  homeSet = [NSMutableArray arrayWithCapacity:3];
  
  tag = [[NSArray alloc] initWithObjects:@"href", XMLNS_WEBDAV, @"D",
			   [self baseURLInContext:ctx], nil];
  [homeSet addObject:tag];
  [tag release]; tag = nil;
 
#if 0 /* multiple roots unsupported by iCal */ 
  if ((obj = [self lookupName:@"public" inContext:ctx acquire:NO]) != nil) {
    tag = [[NSArray alloc] initWithObjects:@"href", XMLNS_WEBDAV, @"D",
			     [obj baseURLInContext:ctx], nil];
    [homeSet addObject:tag];
    [tag release]; tag = nil;
  }
  
  if ((obj = [self lookupName:@"Groups" inContext:ctx acquire:NO]) != nil) {
    tag = [[NSArray alloc] initWithObjects:@"href", XMLNS_WEBDAV, @"D",
			     [obj baseURLInContext:ctx], nil];
    [homeSet addObject:tag];
    [tag release]; tag = nil;
  }
#endif
  
  return homeSet;
}

/* messages */

- (int)zlGenerationCount {
  /* trash folders have no messages and therefore never change */
  return 1;
}

- (id)getIDsAndVersionsAction:(id)_ctx {
  WOResponse *response = [(WOContext *)_ctx response];
  [response setStatus:200]; /* OK */
  [response setHeader:@"text/plain" forKey:@"content-type"];
  return response;
}
- (int)cdoContentCount {
  return 0;
}

/* actions */

- (id)GETAction:(id)_ctx {
  return [[WOApplication application] pageWithName:@"SxUserHomePage"];
}

/* transaction */

- (void)_sleepWithContext:(id)_ctx {
  LSCommandContext *cmdctx;
  
  if (_ctx == nil) {
    [self logWithFormat:@"WARNING: called -sleep without context."];
    return;
  }
  if ((cmdctx = [self commandContextInContext:_ctx]) == NULL) {
    [self logWithFormat:@"sleep: no command context to process."];
    return;
  }
  if (![cmdctx isTransactionInProgress]) {
    [self debugWithFormat:@"sleep: no open transactions to close."];
    return;
  }

  if (![cmdctx rollback]) {
    [self logWithFormat:@"sleep: failed to rollback open transaction."];
    return;
  }

  [self debugWithFormat:@"sleep: rolled back open transaction."];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<%p[%@]: login=%@>",
        self, NSStringFromClass([self class]), self->login];
  return ms;
}

@end /* SxUserFolder */
